# Odoo in docker

Dockerized version of Odoo for development and debugging.
You will need `docker-compose` for this to run or `vscode` to develop inside
a container.

## Running

```shell
# start up odoo and the database
docker-compose up

# mount odoo source files hosted locally
git clone --depth=1 -b 15.0 git@github.com:odoo/odoo.git
cat > docker-compose.override.yaml <<EOF
version: "3.7"

services:
odoo:
	volumes:
	- /opt/odoo:/opt/odoo:cached
	- /opt/odoo-addons:/mnt/odoo-addons:cached
	- /mnt:/mnt/host:ro
EOF

# connect and run things on the containers
docker-compose exec odoo bash
docker-compose exec odoo odoo shell
docker-compose exec db psql -U odoo -l

# copy files to and from the container
docker copy myfile.tar dockerodoo-odoo-1:/
```

Since the default configuration is set to connect to odoo, you can run
commands inside the odoo container without specifying most parameters.

``` shell
# run the shell
odoo shell

# connect to the database or list them
psql -U odoo -h db
psql -U odoo -h db -l
```

## Project Structure

```bash
your-project/
 ├── .devcontainer/     # vscode development in container
 │   ├── devconainer.json    # definition of the container
 │   └── docker-vscode.yaml  # docker-compose for the container
 ├── .vscode/           # vscode default configuration
 ├── custom/            # Custom modules goes here, same level hierarchy **REQUIRED**
 │   ├── OCA/
 │   └── myaddons/
 ├── resources/         # Scripts for service automation
 ├── ...                # Common files (.gitignore, etc.)
 ├── .env               # Environment definition
 ├── Dockerfile         # Image definition
 ├── docker-compose.yml # The default docker-compose
 ├── requirements.txt   # Python requirements for development
 ├── vscode.code-workspace # workspace to use inside the container
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
The default database is `odoo`.

The addon's directories are found in the following locations:
- ODOO_BASEPATH where you find Odoo source code
- ODOO_EXTRA_ADDONS where you find your addons
- ODOO_BASE_ADDONS where you find other already available addons
  like *enterprise* (optional)

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
- ODOO_BASEPATH=`/opt/odoo`
- ODOO_BASE_ADDONS=`/mnt/odoo-addons`

# Development and Testing

## Linting

A simple script `pre-commit` is there to lint the code before committing.
You can install it as a hook or run manually with `./pre-commit lint` if you
want the full checks.

## Backup and restore database

You can use [click-odoo-contrib] to backup, restore, copy databases and
related jobs.
It is installed on the odoo container, so you could just mount a
/mnt/backup folder and use it for files.

You can also use `click-odoo-initdb` or `click-odoo-update` to update
installed modules.

## Running tests

	# inside the devcontainer
	odoo --test-enable --stop-after-init -i mymodule -d test_db_1
	# alternatively
	odoo-test -t -a mymodule -d test_db_1

	# using docker-compose
	docker-compose -f docker-compose.yaml -f docker-compose.test.yaml run --rm odoo

# TODO Improvements

Wanted commands:
- store files in database by default (make a module for this)
- unit/integration tests and test with browser

# Credits

Based on:

* [dockerdoo]

Bunch of ideas taken from:

* [Odoo] ([odoo-docker])
* [OCA] ([maintainer-quality-tools](https://github.com/OCA/maintainer-quality-tools))
* [click-odoo-contrib]


[click-odoo-contrib]: https://github.com/acsone/click-odoo-contrib
[dockerdoo]: https://github.com/iterativo-git/dockerdoo
[OCA]: https://github.com/OCA
[Odoo]: https://github.com/odoo
[odoo-docker]: https://github.com/odoo/docker
