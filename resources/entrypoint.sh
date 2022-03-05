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
: ${PGPASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD}}}

# set all variables
: ${ODOO_EXTRA_ADDONS:=/mnt/extra-addons}
EXTRA_ADDONS_PATHS=$(python3 getaddons.py ${ODOO_EXTRA_ADDONS} 2>&1)

if [ ! -f ${ODOO_RC} ]
then
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
dbfilter = ${DBFILTER:-.*}
db_name = ${DBNAME:-}
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

if [ -n "$EXTRA_ADDONS_PATHS" ] && [ "${PIP_AUTO_INSTALL:-}" -eq "1" ]
then
    echo "Auto install requirements.txt from $ODOO_EXTRA_ADDONS"
    find $ODOO_EXTRA_ADDONS -name 'requirements.txt' -exec pip3 install --user -r {} \;
fi

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC"
    then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi
}

check_config "db_host" "$PGHOST"
check_config "db_port" "$PGPORT"
check_config "db_user" "$PGUSER"
check_config "db_password" "$PGPASSWORD"

[ "${1:-}" != -* ] || set -- -- "$@"

case "${1:-}" in
    -- | odoo | odoo-bin | "")
        shift
        if [[ "$1" == "scaffold" ]]
        then
            exec odoo "$@"
            exit $?
        fi
        # TODO handle shell

        wait-for-psql.py "${DB_ARGS[@]}" --timeout=30

        if [ -n "${TEST_ENABLE}" ] && [ "${TEST_ENABLE}" != "False" ]
        then
            if [ -z "${EXTRA_MODULES:-}" ]
            then
                EXTRA_MODULES=$(python3 -c "from getaddons import get_modules; print(','.join(get_modules('${ODOO_EXTRA_ADDONS}', depth=3)))")
            fi
            echo "Enable testing for modules: ${EXTRA_MODULES}"
            set -- "$@" "--test-enable" "--stop-after-init" "-i" "${EXTRA_MODULES}" "-d" "${DBNAME_TEST:-${DBNAME}}"
        elif [ "${UPGRADE_ENABLE:-0}" == "1" ]
        then
            export PGHOST PGPORT PGUSER PGPASSWORD
            ODOO_DB_LIST=$(psql -X -A -d postgres -t -c "SELECT STRING_AGG(datname, ' ') FROM pg_database WHERE datdba=(SELECT usesysid FROM pg_user WHERE usename=current_user) AND NOT datistemplate and datallowconn AND datname <> 'postgres'")
            for db in ${ODOO_DB_LIST}
            do
                # TODO handle separately click-odoo
                echo "Update database: ${db}"
                click-odoo-update --ignore-core-addons -d $db -c ${ODOO_RC} --log-level=error
                echo "Update database finished"
            done
        fi


        if [ "${DEBUGPY_ENABLE:-0}" == "1" ]
        then
            echo "Enable debugpy"
            set -- python3 -m debugpy --listen "${DEBUGPY_PORT:-41234}" "$(which odoo)" "$@" --workers 0 --limit-time-real 100000
        else
            set -- odoo "$@"
        fi
        echo "Start odoo..."
        exec "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
