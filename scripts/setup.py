#!/usr/bin/env python3
import argparse
import logging
import os
import pathlib
import shutil

SCRIPT_DIR = pathlib.Path(__file__).parent
BASE_DIR = SCRIPT_DIR.parent.absolute()

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("setup")


def create_dotenv(container_type):
    dotenv_path = BASE_DIR / ".env"
    if dotenv_path.exists():
        return
    log.info("create %s", dotenv_path)
    extra_addons = "/mnt/extra-addons"
    if container_type == "devcontainer":
        extra_addons = "/odoo-workspace/addons"
    content = [
        (SCRIPT_DIR / "env-template").read_text(),
        "",
        "# User uid",
        f"DEV_UID={os.getuid()}",
        "# Odoo paths",
        "ODOO_DATA_DIR=/var/lib/odoo",
        "ODOO_BASEPATH=/opt/odoo",
        f"ODOO_EXTRA_ADDONS={extra_addons}",
    ]
    module_list_file = BASE_DIR / "addons" / "module-list"
    if module_list_file.exists():
        content.extend(
            [
                "# Module list",
                module_list_file.read_text(),
            ]
        )
    dotenv_path.write_text("\n".join(content))


def create_compose_override():
    path = BASE_DIR / "docker-compose.override.yaml"
    if path.exists():
        return
    log.info("create %s", path)
    shutil.copy(SCRIPT_DIR / "docker-compose.default.yaml", path)


def create_vscode_launch(container_type):
    launch_type = 'attach'
    if container_type == 'devcontainer':
        launch_type = 'devcontainer'
    link = f"../scripts/launch.{launch_type}.json"
    path = BASE_DIR / ".vscode" / "launch.json"
    log.info("symlink %s", path)
    tmp_path = str(path) + '.tmp'
    os.symlink(link, tmp_path)
    os.rename(tmp_path, path)


def main(args=None):
    parser = argparse.ArgumentParser(
        description="Setup the work directory for development of Odoo.",
    )
    parser.add_argument(
        "action",
        choices=["devcontainer", "compose"],
        help="how to set up the envrionment",
    )
    args = parser.parse_args(args)
    action = args.action

    if action in ('devcontainer', 'compose'):
        log.info("setup %s in %s", action, BASE_DIR)
        create_dotenv(action)
        create_compose_override()
        create_vscode_launch(action)


if __name__ == '__main__':
    main()
