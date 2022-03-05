# Odoo in docker

Dockerized version of Odoo for development and debugging.
We are going to use the official image where the we have replaced the
entrypoint customized for debugging and Odoo management.
You will need `docker-compose` for this to run.

## Running

```shell
docker-compose up
```

```shell
# With odoo files hosted locally
git clone --depth=1 -b 15.0 git@github.com:odoo/odoo.git
docker-compose -f docker-compose.yaml -f docker-hosted-odoo.yaml up
```

You can set up environment variables in `.env` file.
These are loaded into the odoo container and a configuration is generated
every time the container starts.

## Project Structure

```bash
your-project/
 ├── resources/         # Scripts for service automation
 ├── odoo/              # Optional hosted source code of Odoo
 ├── custom/            # Custom modules goes here, same level hierarchy **REQUIRED**
 │   ├── addons/
 │   ├── OCA/
 │   ├── enterprise/
 │   └── /
 ├── ...                # Common files (.gitignore, etc.)
 ├── .env               # Single source of environment definition
 ├── Dockerfile         # Single source of image definition
 ├── docker-compose.yml             # The default docker-compose
 └── docker-compose.override.yml    # Optional custom version
```
TODO Document requirements odoo.sh database.sh

# Improvements

TODO restore database
TODO lint run
TODO test run

TODO store files in database by default
requires to have a module to change this and migrate data

# Dockerized Odoo

Dockerdoo is integrated with **VSCode** for fast development and debugging, just install the [Remote Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

## Credits

Mainly based on:

* [dockerdoo](https://github.com/iterativo-git/dockerdoo)
* [David Arnold](https://github.com/blaggacao) ([XOE Solutions](https://xoe.solutions))

Bunch of ideas taken from:

* [Odoo](https://github.com/odoo) ([docker](https://github.com/odoo/docker))
* [OCA](https://github.com/OCA) ([maintainer-quality-tools](https://github.com/OCA/maintainer-quality-tools))
* [Ingeniería ADHOC](https://github.com/jjscarafia) ([docker-odoo-adhoc](https://github.com/ingadhoc/docker-odoo-adhoc))
