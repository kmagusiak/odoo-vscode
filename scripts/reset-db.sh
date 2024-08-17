#!/bin/bash
set -eu
cd "$(dirname "$(dirname "$0")")"

if [ $# -eq 0 ] || [[ "$1" == -* ]]
then
	echo "Usage: $0 db_name [ db_template or dump.sql ]"
	echo "Reset the database, a template can be given to create the database."
	echo "If a dump is passed (path), it's restored without resetting."
	exit 1
fi

DB_NAME="$1"
DB_TEMPLATE="${2:-}"
DB_DUMP_FILE=""
DB_RESET=1
SCRIPT_DIR="$(dirname $0)"

if [[ "$DB_TEMPLATE" == */* ]]
then
	DB_DUMP_FILE="$DB_TEMPLATE"
	DB_TEMPLATE="template0"
	DB_RESET=""
fi

if [ -d "/odoo-workspace" ]
then
	run() {
		"$@"
	}
	end() {
		true
	}
else
	echo "- docker compose down"
	docker compose down
	cont=$(docker compose run --rm -d odoo /bin/bash -c "for i in {1..30}; do sleep 60; done")
	echo "- container: $cont"
	run() {
		docker exec -i "$cont" "$@"
	}
	end() {
		docker stop "$cont"
	}
fi

if [ -n "$DB_TEMPLATE" ]
then
	echo "- drop database $DB_NAME (if exists)"
	sleep 5  # delay for safety
	run dropdb --if-exists "$DB_NAME"
	echo "- create $DB_NAME from $DB_TEMPLATE"
	run createdb "$DB_NAME" -T "$DB_TEMPLATE"
fi
if [ -n "$DB_DUMP_FILE" ]
then
	echo "- restore the DB from $DB_DUMP_FILE"
	cat "$DB_DUMP_FILE" | run psql "$DB_NAME"
fi
if [ -n "$DB_RESET" ]
then
	echo "- reset DB"
	run odoo-bin neutralize -d "$DB_NAME"
	run psql "$DB_NAME" < "$SCRIPT_DIR/reset-db.sql"
	echo "- update modules"
	run click-odoo-update -d "$DB_NAME" --ignore-core-addons
fi
echo "- done"
end
