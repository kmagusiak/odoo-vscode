#!/bin/bash
set -eu
cd "$(dirname "$(dirname "$0")")"
ODOO_PATH=${ODOO_PATH:-}
ODOO_ADDONS_PATH=${ODOO_ADDONS_PATH:-}
BACKUP_PATH=${BACKUP_PATH:-}

case "$*" in
compose|devcontainer)
	dev_type="$1"
	;;
*)
	echo "Usage: $0 type"
	echo "  type = devcontainer | compose"
	echo
	echo "Env:"
	echo "  ODOO_PATH: optional path to Odoo"
	echo "  ODOO_ADDONS_PATH: optional path to Odoo addons"
	echo "  BACKUP_PATH: optional /mnt/backup"
	exit 1
	;;
esac
if [ "$dev_type" == "compose" ]
then
	launch_type=attach
else
	launch_type=devcontainer
fi
if [ -d "$ODOO_PATH" ]
then
	with_odoo=T
	[ "$launch_type" != "attach" ] || launch_type="$launch_type.odoo"
	echo "* odoo is available"
else
	with_odoo=F
fi

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
echo "- $file"
(
	echo 'version: "3.7"'
	echo
	echo 'services:'
	echo '  odoo:'
	echo '    volumes:'
	echo "    - /tmp/odoo$RANDOM:/tmp"
	[ ! -d "$ODOO_PATH" ] || echo "    - $ODOO_PATH:/opt/odoo:cached"
	[ ! -d "$ODOO_ADDONS_PATH" ] || echo "    - $ODOO_ADDONS_PATH:/opt/odoo-addons:cached"
	[ ! -d "$BACKUP_PATH" ] || echo "    - $BACKUP_PATH:/mnt/backup"
) > "$file"

file=".vscode/launch.json"
echo "- $file"
cp "scripts/launch.${launch_type}.json" "$file"

echo "- done"
