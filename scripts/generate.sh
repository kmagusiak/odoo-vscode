#!/bin/bash
set -eu
cd "$(dirname "$(dirname "$0")")"

case "$*" in
compose)
	dev_type=compose
	launch_type=attach
	;;
compose-odoo)
	dev_type=compose
	launch_type=attach.odoo
	;;
devcontainer)
	dev_type=devcontainer
	launch_type=devcontainer
	;;
*)
	echo "Usage: $0 type"
	echo "  type = devcontainer | compose | compose-odoo"
	exit 1
	;;
esac

echo "* dev: $dev_type"

# Generate files

file=".env"
if [ ! -f "$file" ]
then
	echo "- $file"
	(
		echo "# User uid"
		echo "DEV_UID=$(id -u)"
		echo "# Odoo addon paths"
		if [ "$launch_type" == "devcontainer" ]
		then
			echo "ODOO_EXTRA_ADDONS=/odoo-workspace/custom"
		else
			echo "ODOO_EXTRA_ADDONS=/mnt/extra-addons"
		fi
		if [ -f "custom/module-list" ]
		then
			echo "# Module lists"
			cat "custom/module-list"
		fi
		echo
		cat scripts/env-template
	) > "$file"
fi

file="docker-compose.override.yaml"
if [ ! -f "$file" ]
then
	echo "- $file"
	cp "scripts/docker-compose.volumes.yaml" "$file"
fi

file=".vscode/launch.json"
echo "- $file"
cp "scripts/launch.${launch_type}.json" "$file"

echo "* done"
