#!/bin/bash
set -eu
cd "$(dirname "$(dirname "$0")")"

case "$*" in
compose)
	dev_type=compose
	launch_type=attach
	;;
devcontainer)
	dev_type=devcontainer
	launch_type=devcontainer
	;;
*)
	echo "Usage: $0 type"
	echo "  type = devcontainer | compose"
	exit 1
	;;
esac

echo "* dev: $dev_type"

# Generate files

file=".env"
if true
then
	echo "- $file"
	(
		cat scripts/env-template
		echo
		echo "# User uid"
		echo "DEV_UID=$(id -u)"
		echo "# Odoo paths"
		echo "ODOO_DATA_DIR=/var/lib/odoo"
		echo "ODOO_BASEPATH=/opt/odoo"
		if [ "$launch_type" == "devcontainer" ]
		then
			echo "ODOO_EXTRA_ADDONS=/odoo-workspace/addons"
		else
			echo "ODOO_EXTRA_ADDONS=/mnt/extra-addons"
		fi
		if [ -f "addons/module-list" ]
		then
			echo "# Module list"
			cat "addons/module-list"
		fi
	) > "$file"
fi

file="docker-compose.override.yaml"
if [ ! -f "$file" ]
then
	echo "- $file"
	cp "scripts/docker-compose.default.yaml" "$file"
fi

file=".vscode/launch.json"
echo "- $file"
ln -sf "../scripts/launch.${launch_type}.json" "$file"

echo "* done"
