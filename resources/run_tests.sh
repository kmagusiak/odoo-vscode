#!/bin/bash
# TODO both here and in entrypoint...

set -eu
DB_NAME_TEST=odoodbtest

if [ -z "${TEST_MODULES:-}" ]
then
	TEST_MODULES=$(cd / && python3 -c "from getaddons import get_modules; print(','.join(get_modules('${ODOO_EXTRA_ADDONS}', depth=3)))")
fi
if [ -n "${DB_NAME_TEST:-}" ]
then
	echo "ENTRY - Drop test database: ${DB_NAME_TEST}"
	click-odoo-dropdb --if-exists "${DB_NAME_TEST}"
fi
echo "ENTRY - Enable testing for modules: ${TEST_MODULES}"
/usr/bin/odoo "--test-enable" "--stop-after-init" "-i" "base,${TEST_MODULES}" "-d" "${DB_NAME_TEST}"
