#!/bin/bash

set -eu

if [ -v PASSWORD_FILE ]
then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${PGHOST:=${DB_PORT_5432_TCP_ADDR:-${POSTGRES_HOST:-db}}}
: ${PGPORT:=${DB_PORT_5432_TCP_PORT:-${POSTGRES_PORT:-5432}}}
: ${PGUSER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:-odoo}}}
: ${PGPASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:-odoo}}}

# set all variables
: ${ODOO_BASEPATH:=/opt/odoo}
ODOO_BIN="$ODOO_BASEPATH/odoo-bin"
: ${ODOO_BASE_ADDONS:=/mnt/odoo-addons}
: ${ODOO_EXTRA_ADDONS:=/mnt/extra-addons}
EXTRA_ADDONS_PATHS=$(odoo-getaddons.py ${ODOO_EXTRA_ADDONS} ${ODOO_BASE_ADDONS} ${ODOO_BASEPATH})

if [ ! -f ${ODOO_RC} ]
then
    echo "ENTRY - Generate $ODOO_RC"
    cat > $ODOO_RC <<EOF
[options]
addons_path = ${EXTRA_ADDONS_PATHS}
admin_passwd = ${ADMIN_PASSWORD:-admin}
data_dir = ${ODOO_DATA_DIR:-/var/lib/odoo}
db_host = ${PGHOST}
db_maxconn = ${DB_MAXCONN:-64}
db_password = ${PGPASSWORD}
db_port = ${PGPORT}
db_sslmode = ${DB_SSLMODE:-prefer}
db_template = ${DB_TEMPLATE:-template1}
db_user = ${PGUSER}
dbfilter = ${DB_FILTER:-.*}
db_name = ${DB_NAME:-}
limit_request = ${LIMIT_REQUEST:-8196}
limit_memory_hard = ${LIMIT_MEMORY_HARD:-2684354560}
limit_memory_soft = ${LIMIT_MEMORY_SOFT:-2147483648}
limit_time_cpu = ${LIMIT_TIME_CPU:-60}
limit_time_real = ${LIMIT_TIME_REAL:-120}
limit_time_real_cron = ${LIMIT_TIME_REAL_CRON:-0}
list_db = ${LIST_DB:-True}
log_db = ${LOG_DB:-False}
log_db_level = ${LOG_DB_LEVEL:-warning}
logfile = ${LOG_FILE:-None}
log_handler = ${LOG_HANDLER:-:INFO}
log_level = ${LOG_LEVEL:-info}
max_cron_threads = ${MAX_CRON_THREADS:-2}
proxy_mode = ${PROXY_MODE:-False}
server_wide_modules = ${SERVER_WIDE_MODULES:-base,web}
smtp_password = ${SMTP_PASSWORD:-False}
smtp_port = ${SMTP_PORT:-25}
smtp_server = ${SMTP_SERVER:-localhost}
smtp_ssl = ${SMTP_SSL:-False}
smtp_user = ${SMTP_USER:-False}
test_enable = ${TEST_ENABLE:=False}
unaccent = ${UNACCENT:-False}
without_demo = ${WITHOUT_DEMO:-True}
workers = ${WORKERS:-0}
odoo_stage = ${ODOO_STAGE:-docker}
EOF
fi

if [ -n "$EXTRA_ADDONS_PATHS" ]
then
    echo "ENTRY - Addons paths: $EXTRA_ADDONS_PATHS"
fi
if [ -n "$EXTRA_ADDONS_PATHS" ] && [ "${PIP_AUTO_INSTALL:-0}" -eq "1" ]
then
    for ADDON_PATH in "$ODOO_BASE_ADDONS" "$ODOO_EXTRA_ADDONS"
    do
        [ -d "$ADDON_PATH" ] || continue
        echo "ENTRY - Auto install requirements.txt from $ADDON_PATH"
        find "$ADDON_PATH" -name 'requirements.txt' -exec pip3 install --user -r {} \;
    done
fi

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    DB_ARGS+=("--${param}" "${value}")
}

export PGHOST PGPORT PGUSER PGPASSWORD
check_config "db_host" "$PGHOST"
check_config "db_port" "$PGPORT"
check_config "db_user" "$PGUSER"
check_config "db_password" "$PGPASSWORD"

# if we have an odoo command, just prepend odoo
case "${1:-}" in
    scaffold | shell | -*)
        set -- odoo "$@"
        ;;
esac

case "${1:-}" in
    -- | odoo | odoo-bin | odoo-test | "")
        if [[ "${1:-}" == odoo-test ]]
        then
            ODOO_BIN=$(which odoo-test)
            TEST_MODULE_PATH=$ODOO_EXTRA_ADDONS
            shift
        elif [[ "${2:-}" == "scaffold" ]]
        then
            shift
            exec odoo "$@"
            exit $?
        else
            shift
        fi

        echo "ENTRY - Wait for postgres"
        wait-for-psql.py "${DB_ARGS[@]}" --timeout=30

        if [ -n "${TEST_MODULE_PATH:-}" ]
        then
            echo "ENTRY - Enable testing for path: ${TEST_MODULE_PATH}"
            set -- -d "${DB_NAME_TEST:-${DB_NAME:-odoo_test}}" --get-addons "${TEST_MODULE_PATH}" "$@"
        elif [ "${UPGRADE_ENABLE:-0}" == "1" ]
        then
            ODOO_DB_LIST=$(psql -X -A -d postgres -t -c "SELECT STRING_AGG(datname, ' ') FROM pg_database WHERE datdba=(SELECT usesysid FROM pg_user WHERE usename=current_user) AND NOT datistemplate and datallowconn AND datname <> 'postgres'")
            for db in ${ODOO_DB_LIST}
            do
                echo "ENTRY - Update database: ${db}"
                click-odoo-update --ignore-core-addons -d "$db" -c "${ODOO_RC}" --log-level=error
                echo "ENTRY - Update database finished"
            done
        fi

        if [ "${DEBUGPY_ENABLE:-0}" == "1" ]
        then
            echo "ENTRY - Enable debugpy"
            set -- python3 -m debugpy --listen "0.0.0.0:${DEBUGPY_PORT:-41234}" "$ODOO_BIN" "$@" --workers 0 --limit-time-real 100000
        else
            set -- "$ODOO_BIN" "$@"
        fi
        echo "$@"
        echo "ENTRY - Start odoo..."
        exec "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
