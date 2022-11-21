#!/bin/bash
set -eu
cd "$(dirname "$(dirname "$0")")"

DB_NAME=$1
DB_TEMPLATE=$2

if [ -d "/odoo-workspace" ]
then
	run() {
		"$@"
	}
	end() {
		true
	}
else
	cont=$(docker-compose run --rm -d odoo /bin/bash -c "for i in {1..30}; do sleep 60; done")
	echo "- container: $cont"
	run() {
		docker exec "$cont" "$@"
	}
	end() {
		docker stop "$cont"
	}
fi

if [ -n "$DB_TEMPLATE" ]
then
	echo "- create $DB_NAME from $DB_TEMPLATE"
	sleep 5  # safety
	run dropdb --if-exists "$DB_NAME"
	run createdb "$DB_NAME" -T "$DB_TEMPLATE"
fi
echo "- reset DB"
run psql "$DB_NAME" < scripts/reset-db.sql
echo "- update"
run click-odoo-update -d "$DB_NAME" --ignore-core-addons
echo "- done"
end
