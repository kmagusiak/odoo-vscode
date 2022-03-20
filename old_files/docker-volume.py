import os
from pathlib import Path

from invoke import task


def join_cmd(cmd):
    return ' '.join(("'" + a.replace("'", "\\'") + "'" if ' ' in a else a) for a in cmd)


def split_path(path, exists_exception=False):
    p = Path(path)
    if exists_exception and p.exists():
        raise Exception('File already exists: %s' % p)
    return p, str(p.parent.absolute())


def chown_user(c, path, dir=None):
    path = Path(path)
    if not dir:
        dir = str(path.parent.absolute())
    cmd = [
        'docker',
        'run',
        '--rm',
        '-v',
        f'{dir}:/volume',
        'ubuntu',
        'chown',
        f'{os.getuid()}:{os.getgid()}',
        f'/volume/{path.name}',
    ]
    c.run(join_cmd(cmd))


def postgres_connection_args(c):
    opt = []
    for prefix_value in [
        ('-h', c.get('postgres_host')),
        ('-p', c.get('postgres_port')),
        ('-U', c.get('postgres_user', 'odoo')),
    ]:
        if prefix_value[1]:
            opt += prefix_value
    return opt


@task
def backup_volume(c, volume, tar, overwrite=False):
    """Backup a docker volume to a tar file"""
    tar_path, tar_dir = split_path(tar, exists_exception=not overwrite)
    tar_name = tar_path.name
    # mount /volume and /backup, create tar file
    opts = ''
    if c.get('verbose', False):
        opts += 'v'
    if tar_path.suffix == '.tar':
        pass
    elif tar_path.suffix == '.gz':
        opts += 'z'
    elif tar_path.suffix == '.bz2':
        opts += 'j'
    else:
        raise Exception('Invalid extension for a tar file')
    cmd = [
        'docker',
        'run',
        '--rm',
        '-v',
        f'{volume}:/volume:ro',
        '-v',
        f'{tar_dir}:/backup',
        'ubuntu',
        'tar',
        f'c{opts}f',
        f'/backup/{tar_name}',
        '--directory=/volume',
        '.',
    ]
    c.run(join_cmd(cmd))
    chown_user(c, tar_path, tar_dir)


@task
def restore_volume(c, volume, tar, overwrite=False):
    """Restore a docker volume from tar file"""
    tar_path, tar_dir = split_path(tar)
    if not tar_path.exists():
        raise Exception('Tar file does not exist: %s' % tar_path)
    tar_name = tar_path.name
    # check the volume existance
    cmd = [
        'docker',
        'volume',
        'inspect',
        volume,
    ]
    inspect = c.run(join_cmd(cmd), hide=True, warn=True)
    if inspect:
        if overwrite:
            cmd = [
                'docker',
                'volume',
                'rm',
                volume,
            ]
            c.run(join_cmd(cmd), hide=True)
        else:
            raise Exception('Docker volume already exists: %s' % volume)
    elif inspect.exited != 1:
        raise Exception('Invalid inspect exit code: %d' % inspect.exited)
    # mount /volume and /backup, extract tar file
    opts = ''
    if c.get('verbose', False):
        opts += 'v'
    cmd = [
        'docker',
        'run',
        '--rm',
        '-v',
        f'{volume}:/volume',
        '-v',
        f'{tar_dir}:/backup:ro',
        'ubuntu',
        'tar',
        f'x{opts}f',
        f'/backup/{tar_name}',
        '--directory=/volume',
        '--strip',
        '1',
    ]
    c.run(join_cmd(cmd))


@task
def list_databases(c, container, hide=False):
    """Get the list of the databases"""
    cmd = [
        'docker',
        'exec',
        container,
        'psql',
        '-l',
    ] + postgres_connection_args(c)
    databases_run = c.run(join_cmd(cmd), hide=hide)
    databases = [i.lstrip(' ') for i in databases_run.stdout.splitlines() if '|' in i]
    databases = [i.split(' ')[0] for i in databases if i[0] != '|' and not i.startswith('Name ')]
    return databases


@task
def create_database(
    c,
    container,
    database,
    owner=None,
    template=None,
    drop=False,
    raise_if_exists=True,
):
    """Create a database (empty or from template)"""
    if drop:
        drop_database(c, container, database, raise_if_not_found=False)
    elif not raise_if_exists:
        databases = list_databases(c, container, hide=True)
        if database in databases:
            return
    cmd = [
        'docker',
        'exec',
        container,
        'createdb',
    ] + postgres_connection_args(c)
    if owner:
        cmd += ['--owner', owner]
    if template:
        cmd += ['--template', template]
    cmd.append(database)
    c.run(join_cmd(cmd))


@task
def drop_database(c, container, database, raise_if_not_found=False):
    """Drop a database"""
    cmd = [
        'docker',
        'exec',
        container,
        'dropdb',
    ] + postgres_connection_args(c)
    if not raise_if_not_found:
        cmd.append('--if-exists')
    cmd.append(database)
    c.run(join_cmd(cmd))


@task
def psql(c, container, database=None):
    """Run psql on a container"""
    cmd = ['docker', 'exec', '-it', container, 'psql'] + postgres_connection_args(c)
    if database:
        cmd.append(database)
    c.run(join_cmd(cmd), pty=True)


@task
def dump_database(c, container, database, path, overwrite=False, data=True, blobs=False):
    """Dump database to a file"""
    path, _path_dir = split_path(path, exists_exception=not overwrite)
    cmd = [
        'docker',
        'exec',
        container,
        'pg_dump',
        '--format=c',
        '--no-owner',
    ] + postgres_connection_args(c)
    if not data:
        cmd.append('--schema-only')
        blobs = False
    parallelism = c.get('parallelism') or 1
    if parallelism > 1:
        cmd.extend(['-j', str(parallelism)])
    cmd.append('-b' if blobs else '-B')
    cmd.extend(['-d', database])
    try:
        c.run(join_cmd(cmd) + f" > '{path}'")
    except Exception as e:
        # remove file if empty
        try:
            stat = path.stat()
            if stat.st_size > 0:
                path.unlink(missing_ok=True)
        except FileNotFoundError:
            pass
        raise e


@task
def restore_database(c, container, database, path, clean=False, drop=False):
    """Restore database from dump"""
    restore_path = '/var/lib/postgresql/data/restore.dump'
    create_database(c, container, database, drop=drop, raise_if_exists=not clean)
    opt = ['--format=c', '--no-owner']
    opt.extend(postgres_connection_args(c))
    if clean:
        opt.extend(['--clean', '--if-exists'])
    parallelism = c.get('parallelism') or 4
    if parallelism > 1:
        opt.extend(['-j', str(parallelism)])
    opt.extend(['-d', database])
    cmd = (
        [
            'docker',
            'exec',
            container,
            'pg_restore',
        ]
        + opt
        + [restore_path]
    )
    c.run(join_cmd(['docker', 'cp', path, container + ':' + restore_path]))
    c.run(join_cmd(cmd), pty=True)
    c.run(join_cmd(['docker', 'exec', container, 'rm', '-f', restore_path]))
