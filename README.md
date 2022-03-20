# Odoo in docker

Dockerized version of Odoo for development and debugging.
You will need `docker-compose` for this to run or `vscode` to develop inside
a container.

## Running

```shell
docker-compose up
```

If you want to mount your files, for example odoo sources...

```shell
# With odoo files hosted locally
git clone --depth=1 -b 15.0 git@github.com:odoo/odoo.git
cat > docker-compose.override.yaml <<EOF
version: "3.7"

services:
odoo:
	volumes:
	- /opt/odoo:/opt/odoo:cached
	- /mnt:/mnt/host:ro
EOF
```

## Project Structure

```bash
your-project/
 ├── .devcontainer/     # vscode development in container
 │   ├── devconainer.json    # definition of the container
 │   ├── docker-vscode.yaml  # docker-compose for the container
 │   └── odoo.code-workspace # workspace to use inside the container
 ├── .vscode/           # vscode default configuration
 ├── custom/            # Custom modules goes here, same level hierarchy **REQUIRED**
 │   ├── OCA/
 │   ├── enterprise/
 │   └── myaddons/
 ├── resources/         # Scripts for service automation
 ├── ...                # Common files (.gitignore, etc.)
 ├── .env               # Environment definition
 ├── Dockerfile         # Image definition
 ├── docker-compose.yml # The default docker-compose
 ├── requirements.txt   # Python requirements for development
 └── README.md          # This file
```

## The Dockerfile

We are starting from the [official Odoo docker image](https://github.com/odoo/docker).
We move Odoo sources to `/opt/odoo` (ODOO_BASEPATH) so that you can easily
mount your own sources.
We install `click-odoo-contrib` and `debugpy`;
replace the entrypoint and add a *health check* to the image.

You can set up environment variables in `.env` file.
These are loaded into the odoo container and a configuration file is generated
every time the container starts at `/etc/odoo/odoo.conf`.

The addon's directories are found in the following locations:
- ODOO_BASEPATH where you find Odoo source code
- ODOO_EXTRA_ADDONS where you find your addons
- ODOO_BASE_ADDONS where you find other already available addons (optional)

*Addon paths* are generated dynamically, so you can checkout entire
Odoo addon repositories in the `custom` directory
and it will build all the paths.
ODOO_BASE_ADDONS is there if your docker image already contains some addons.

## vscode: devcontainer

[Remote Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

Inside the Dockerfile, there is a separate stage in the Dockerfile for vscode.
Inside devcontainer, the user is *vscode* (uid=1000 - as probably is your user)
which we create here, beacuse odoo's uid=101.

File locations:
- The workspace is mounted at `/odoo-workspace`
- ODOO_EXTRA_ADDONS=`/odoo-workspace/custom`

# Testing

## Linting

A simple script `pre-commit` is there to lint the code before committing.
You can install it as a hook or run manually with `./pre-commit lint` if you
want the full checks.

# Improvements

TODO database.sh restore database
- drop and recreate new
- reset passwords and configuration
TODO odoo.sh: update modules
TODO test run
TODO shell debug?
TODO test with browser (chrome?)
TODO github actions

Wanted commands:
- backup db
- restore db
- create db template
- reset config (and password)
- list_db
- lint
- test

Store files in database by default
requires to have a module to change this and migrate data

# Credits

Based on:

* [dockerdoo](https://github.com/iterativo-git/dockerdoo)

Bunch of ideas taken from:

* [Odoo](https://github.com/odoo) ([docker](https://github.com/odoo/docker))
* [OCA](https://github.com/OCA) ([maintainer-quality-tools](https://github.com/OCA/maintainer-quality-tools))
* [click-odoo-contrib](https://github.com/acsone/click-odoo-contrib)
