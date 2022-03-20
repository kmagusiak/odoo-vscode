# Docker: odoo
# https://hub.docker.com/_/odoo

import logging
from pathlib import Path

from invoke import task

###########################################################
# Database commands


def run_postgres(c, query, hide=False):
    pg_container = config_param(c, 'name', 'postgres', section='postgresql')
    database = config_param(c, 'database', 'odoo', section='postgresql')
    command = "psql %s -c '%s'" % (database, query.replace("'", "'\\''"))
    return c.run(f'docker container exec {pg_container} {command}', hide=hide)


@task
def reset_passwords(c, password='admin'):
    """Reset Odoo password for all users"""
    logging.info('Resetting password for all users')
    from passlib.context import CryptContext

    crypt = CryptContext(schemes=['pbkdf2_sha512'])
    encrypted = crypt.encrypt(password)
    query = "update res_users set password='%s'" % encrypted
    run_postgres(c, query, hide=True)


###########################################################
# Running Odoo


def config_param(c, name, default=None, section='odoo'):
    d = c.get(section) or {}
    return d.get(name, default)


def run_odoo_params(c, load_languages=False, demo=False):
    params = []
    # database
    database = config_param(c, 'database', section='postgresql')
    if database:
        params.extend(['-d', database, '--db-filter', database])
    # languages
    if load_languages:
        languages = config_param(c, 'languages')
        if isinstance(languages, list):
            languages = ','.join(languages)
        params.append('--load-language=' + languages)
    # demo
    if not demo:
        params.append("--without-demo=all")
    return params


def run_odoo(
    c,
    command,
    *,
    pty=False,
    background=False,
    rm=True,
    port=False,
    debug=False,
):
    cmd = ["docker run"]
    if pty:
        cmd.append('-it')
    if rm:
        cmd.append('--rm')
    if background:
        if pty:
            raise Exception('Cannot run pty and background at the same time')
        cmd.append('-d')
    # name
    name = config_param(c, 'name')
    if name:
        cmd.extend(['--name', name])
    # port mapping
    if port is not False:
        if not port or isinstance(port, bool):
            port = config_param(c, 'port', 8069)
        cmd.extend(['-p', str(port) + ':8069'])
    if debug is not False:
        if not debug or isinstance(debug, bool):
            debug = config_param(c, 'port_debug', 41234)
        cmd.extend(['-p', str(debug) + ':41234'])
    # database
    pg_container = config_param(c, 'name', 'postgres', section='postgresql')
    cmd.extend(["--link", pg_container + ':db'])
    pg_username = config_param(c, 'username', 'postgres', section='postgresql')
    pg_password = config_param(c, 'password', section='postgresql')
    if pg_username:
        cmd.extend(['-e', "'POSTGRES_USER=" + pg_username + "'"])
    if pg_password:
        cmd.extend(['-e', "'POSTGRES_PASSWORD=" + pg_password + "'"])
    # configuration
    config_file = config_param(c, 'config')
    if config_file:
        config_file = Path(config_file).absolute()
        cmd.extend(['-v', f"{config_file}:/etc/odoo/odoo.conf:ro"])
    # addons
    addons_paths = config_param(c, 'addons_paths')
    addons_mount = config_param(c, 'addons_mount', '/mnt')
    if isinstance(addons_paths, str):
        addons_paths = [addons_paths]
    for dir in addons_paths or []:
        dir = Path(dir).absolute()
        dir_mount = Path(addons_mount).absolute() / Path(dir.name)
        cmd.extend(['-v', f"{dir}:{dir_mount}:ro"])
    # persisted data
    odoo_data = config_param(c, 'odoo_data')
    if odoo_data:
        cmd.extend(['-v', f"{odoo_data}:/var/lib/odoo"])
    # image
    image = str(config_param(c, 'image', 'odoo:14'))
    cmd.append(image)
    cmd.append(command)
    return c.run(' '.join(cmd), pty=pty)


@task()
def init(c, addons=[], install=False, demo=False, test=False, load_languages=False):
    """Initialize a local database"""
    logging.info('Preparing Odoo')
    command = "odoo"
    command += " --stop-after-init --workers=0 --smtp=nosmtp"
    # test
    if test:
        command += " --test-enable"
        demo = True  # always run tests with demo data
    # parameters
    command += ' ' + ' '.join(run_odoo_params(c, load_languages=load_languages, demo=demo))
    # addons
    if not addons:
        addons = config_param(c, 'addons')
    if isinstance(addons, list):
        addons = ','.join(addons)
    if not addons:
        addons = 'base'
    command += ' ' + ('-i' if install else '-u') + ' ' + addons
    run_odoo(c, command)
    if install and config_param(c, 'contained', False):
        # Set the attachment location to with the database
        run_postgres(
            c,
            """insert into ir_config_parameter
        (key, value, create_uid, create_date, write_uid, write_date)
        select 'ir_attachment.location', 'db', 1, now(), 1, now()
        where not exists(select 1 from ir_config_parameter where key = 'ir_attachment.location')
        """,
        )


@task()
def start(c, shell=False, debug=False, dev=None, background=False):
    """Run an Odoo instance"""
    logging.info('Start Odoo')
    interactive = False
    command = "odoo"
    if shell:
        command += " shell"
        interactive = True
    command += " " + " ".join(run_odoo_params(c))
    if dev:
        command += ' --dev ' + dev
    if shell or debug:
        command += " --workers=0"
    run_odoo(
        c,
        command,
        port=not interactive,
        pty=interactive,
        background=background,
        debug=debug,
    )


###########################################################
# Odoo Development


@task()
def build(c, release='dev'):
    image = str(config_param(c, 'image', '(not set)'))
    if '/' not in image:
        print('Skip build, cannot build: %s' % image)
        return
    dockerfile = 'Dockerfile.' + release
    c.run(f"docker build -t '{image}' -f '{dockerfile}' .")


@task()
def update_repository(c):
    import os

    virtual_dir = Path(os.environ['VIRTUAL_ENV'])
    directory = virtual_dir / 'odoo'
    if directory.exists():
        with c.cd(directory):
            c.run('git pull', pty=True)
    else:
        with c.cd(virtual_dir):
            c.run(
                'git clone --branch 14.0 https://github.com/odoo/odoo.git odoo-community', pty=True
            )
