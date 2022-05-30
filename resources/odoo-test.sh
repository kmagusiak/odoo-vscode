#!/bin/bash
set -eu

if [[ $# -lt 2 ]]
then
	echo "Usage: odoo-test DBNAME MODULE_PATH [ args ]"
	echo "Runs odoo tests for all modules found in a path"
	exit 2
fi

DB_NAME_TEST=$1
MODULE_PATH=$2
shift 2

TEST_MODULES=$(odoo-getaddons.py -m 3 "${MODULE_PATH}")
if [ -z "${TEST_MODULES:-}" ]
then
	echo "TEST - No modules to test"
	exit 1
fi

echo "$(date -u +"%Y-%m-%d %H:%M:%S")  odoo-test"
if [ -n "${DB_NAME_TEST:-}" ]
then
	echo "TEST - Drop test database: ${DB_NAME_TEST}"
	click-odoo-dropdb --if-exists "${DB_NAME_TEST}"
	echo "TEST - Initialize database: ${DB_NAME_TEST}"
	[ -z "${BASE_MODULES:-}" ] || echo "TEST - Pre-install module: ${BASE_MODULES}"
	click-odoo-initdb --new-database "${DB_NAME_TEST}" --demo --no-cache -m "${BASE_MODULES:-base}"
fi

echo "TEST - Testing modules: ${TEST_MODULES}"
exec odoo --test-enable --stop-after-init "$@" -i "${TEST_MODULES}" -d "${DB_NAME_TEST}"
