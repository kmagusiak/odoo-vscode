# Odoo in docker

Dockerized version of Odoo for development and debugging.
You will need `docker-compose` for this to run or `vscode` to develop inside
a container.

## Starting...

Let's start by generating required files, run:
`scripts/generate.sh` with either *devcontainer* or *compose* argument.
It will generate the *.env* file, *docker-compose.override.yaml* and
launcher configuration.
You should edit the compose override file for the mounts you want.
If you change the configuration, reset your container instance.

```shell
# start up odoo and the database
docker-compose up -d

# connect and run things on the containers
docker-compose exec odoo bash
docker-compose exec db psql -U odoo -l

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
 │   └── odoo.code-workspace    # workspace to use inside the container
 ├── addons/               # Custom modules goes here, put them inside separate directories
 │   ├── OCA/
 │   ├── template/
 │   └── myaddons/
 ├── scripts/              # Scripts for environment automation
 ├── ...                   # Common files (.gitignore, etc.)
 ├── .env                  # Environment definition (generated)
 ├── Dockerfile            # Image definition
 ├── docker-compose.yml    # The default docker-compose (and generated override)
 ├── requirements-dev.txt  # Python requirements for development
 └── README.md             # This file
odoo/                      # Optionally, have odoo sources available
```

## The Dockerfile

Starting from [odoo-docker], add development tools
and a user for development with the same UID as yourself.

## vscode: devcontainer

[Remote Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

Inside the devcontainer, the user is *vscode* with uid=$DEV_UID.
The same image is used for compose and devcontainer.

File locations:
- The workspace is mounted at `/odoo-workspace`
- ODOO_EXTRA_ADDONS=`/odoo-workspace/addons`
- ODOO_BASEPATH=`/opt/odoo`
- ODOO_BASE_ADDONS=`/opt/odoo-addons`

# Development and Testing

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
cd odoo-addons
git clone $ODOO_SOURCE/design-themes.git
git clone $ODOO_SOURCE/enterprise.git
```

Add the path in the *docker-comopse.override.yaml* file.

## Modes

Run `./scripts/generate.sh` when changing modes.
It will adapt the launch configuration, and generate default files which
are `.env` and `docker-compose.override.yaml`.
If you use local odoo sources, mount them in the compose override file.

- *devcontainer* as the name indicates, it is for working inside a container
  - `.devcontainer/vscode.code-workspace` is a workspace with odoo sources
- *compose* supposes that you run `docker-compose` and debug remotely
  - `.vscode/odoo.code-workspace` is to be used when you have local odoo sources

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
dropdb --if-exists "$DB_TEMPLATE" && createdb "$DB_TEMPLATE"
psql "$DB_TEMPLATE" < dump.sql

# create your copy
scripts/reset-db.sh "$DB_NAME" "$DB_TEMPLATE"
```

## Running tests

```shell
# inside the devcontainer
odoo-test -t -a template_module -d test_db_1
# which is similar to
odoo --test-enable --stop-after-init -i template_module -d test_db_1

# or use pytest
pytest --odoo-http addons/template

# using docker-compose
docker-compose -f docker-compose.yaml -f docker-compose.test.yaml run --rm odoo
```

If you want to run integration tests with the browser, you will have to install
a web-browser in the container.
Since the image is based on Ubuntu, chromium requires snap which
is not running in the container.
You can install [google-chrome](https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb).

```shell
curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb --output /tmp/google-chrome.deb
apt-get install /tmp/google-chrome.deb
```

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

# Credits

Based on:

* [dockerdoo]

Bunch of ideas taken from:

* [Odoo] ([odoo-docker](https://github.com/odoo/docker))
* [OCA] ([maintainer-quality-tools](https://github.com/OCA/maintainer-quality-tools))
* [click-odoo-contrib]


[click-odoo-contrib]: https://github.com/acsone/click-odoo-contrib
[dockerdoo]: https://github.com/iterativo-git/dockerdoo
[OCA]: https://github.com/OCA
[Odoo]: https://github.com/odoo
[odoo-docker]: https://github.com/kmagusiak/odoo-docker
