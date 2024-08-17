# Odoo in docker

[![Docker Image](https://img.shields.io/badge/docker-repository-blue)][odoo-docker]

Dockerized version of Odoo for development and debugging.
You will need `docker-compose` for to run this project.
You can either just use docker or `vscode` to develop inside a container.

Starting from [odoo-docker] (development version), add required tools
and a user for development with the same UID as yourself.

## Starting...

Fork or clone this repository and...
Using the *devcontainer*, you are working inside the odoo container.
Using *docker-compose*, you work on your machine and run Odoo inside a
container, you can attach to debugger remotely.

```shell
# Clone other repositories (optional, see later)
# Generate additional files
scripts/setup.py devcontainer  # or compose
# Edit the generated files
vim .env
vim docker-compose.override.yaml
# Go...
docker compose up -d  # or reopen in devcontainer
```

Sample commands:

```shell
# connect and run things on the containers
docker compose exec odoo bash
docker compose exec db psql -U odoo -l
docker compose exec odoo psql  # it's also available there

# copy files to and from the container
docker copy myfile.tar dockerodoo-odoo-1:/
```

Since the default configuration is set to connect to odoo, you can run
commands inside the odoo container without specifying most parameters.

``` shell
# install addons
odoo-update base --install

# run the shell
odoo-bin shell

# connect to the database
psql
```

## Project Structure

```bash
your-project/
 ├── .devcontainer/        # vscode development in container
 │   ├── devconainer.json       # definition of the container
 │   ├── docker-vscode.yaml     # docker-compose for the container
 │   └── vscode.code-workspace  # workspace to use inside the container
 ├── .vscode/              # vscode default configuration
 │   ├── settings.json          # settings for your project folder
 │   └── odoo.code-workspace    # workspace to add ../odoo and ../odoo-addons
 ├── addons/               # Your custom modules, put them inside separate directories
 │   ├── OCA/
 │   ├── template/
 │   └── myaddons/
 ├── scripts/              # Scripts for environment automation
 ├── ...                   # Common files (.gitignore, etc.)
 ├── .env                  # Environment definition (generated)
 ├── Dockerfile            # Docker image definition
 ├── docker-compose.yml    # The default docker-compose (and generated override)
 ├── requirements-dev.txt  # Python requirements for development
 └── README.md             # This file
odoo/                      # Odoo sources (optional) and mount them
odoo-addons/               # Optional, other addons
```

## vscode: devcontainer

[Remote Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
Install the extension and reopen after generating the default configuration.
Inside the devcontainer, the user is *vscode* with uid=$DEV_UID.
The same image is used for compose and devcontainer.

File locations:
- The workspace is mounted at `/odoo-workspace`
- ODOO_EXTRA_ADDONS=`/odoo-workspace/addons`
- ODOO_BASEPATH=`/opt/odoo`
- ODOO_BASE_ADDONS=`/opt/odoo-addons`

# Development and Testing

## Selecting the version

The repository is configured for a specific version of Odoo, if you want to run
another version, you'll have to update a few files:
- `.env` change ODOO_VERSION, POSTGRES_VERSION
  (see scripts/env-template file too)
- `.pylintrc`: valid-odoo-versions (if you use it)

You may want to checkout the sources or rebuild the container after this
operation.

## Cloning odoo

If you want to use your own odoo sources, you must clone the `odoo`
repository to a folder of your choosing outside of this repository.
That repository is quite big and can be shared among projects.
By default, we expect the odoo directory next to your project directory;
if not check the configuration files.

```shell
ODOO_SOURCE=git@github.com:odoo
git clone $ODOO_SOURCE/odoo.git
mkdir odoo-addons
# optionally clone what you need (example)
pushd odoo-addons
git clone $ODOO_SOURCE/design-themes.git
git clone $ODOO_SOURCE/enterprise.git
popd
git clone $ODOO_SOURCE/documentation.git
```

Add the path in the *docker-comopse.override.yaml* file.

## Linting

A simple script `pre-commit` is there to lint the code before committing.
You can install it as a hook or run manually with `./pre-commit lint` if you
want the full checks.

## Backup and restore database

You can restore the database from a dump.
After restoring the database, you might want to run the *reset* command
to set the password and check system properties.
The password is set to "admin" for all users.

```shell
# env
source .env
DB_TEMPLATE=dump

# load the dump
# dropdb --if-exists "$DB_TEMPLATE" && createdb "$DB_TEMPLATE"
# psql "$DB_TEMPLATE" < dump.sql
scripts/reset-db.sh "$DB_TEMPLATE" dump.sql

# create your copy
scripts/reset-db.sh "$DB_NAME" "$DB_TEMPLATE"
```

## Running tests

```shell
# inside the devcontainer
odoo-test -t -a template_module -d test_db_1
# which is similar to
odoo --test-enable --stop-after-init -i template_module -d test_db_1

# or use pytest (on existing database)
pytest --odoo-http --odoo-database test_db_1 addons/template

# using docker compose
docker compose -f docker-compose.yaml -f docker-compose.test.yaml run --rm odoo
```

A version of chrome is installed in the devcontainer if you want to run
integration tests.
Source: [google-chrome](https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb).

## Translations

If you want to load a new translations into odoo, run a command below.

```shell
odoo-update template_module --install --load-language=fr_BE
odoo-update template_module --i18n-overwrite --load-language=fr_BE
```

To export translation files, you can use one of the following methods.
`click-odoo-makepot` creates pot files for each module in the current working
directory that is installed and merges it into existing language files.
If you have translations in the database, you can use odoo directly.
To ease exporting, we provide a script for this.

```shell
scripts/translations-export.sh addons/template/template_module/
scripts/translations-export.sh addons/template/template_module/
```

[OCA]: https://github.com/OCA
[Odoo]: https://github.com/odoo
[odoo-docker]: https://github.com/kmagusiak/odoo-docker
