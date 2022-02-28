from odoo:15
env PYTHONUNBUFFERED 1

user root
run ln -s /usr/lib/python3/dist-packages/odoo /opt/odoo
run rm /etc/odoo/odoo.conf && chown odoo:odoo /etc/odoo /var/lib/odoo

# PIP auto-install requirements.txt (change value to "1" to auto-install)
ENV PIP_AUTO_INSTALL=${PIP_AUTO_INSTALL:-"0"}

# Run tests for all the modules in the custom addons
ENV RUN_TESTS=${RUN_TESTS:-"0"}

# Run tests for all installed modules
ENV WITHOUT_TEST_TAGS=${WITHOUT_TEST_TAGS:-"0"}

# Upgrade all databases visible to this Odoo instance
ENV UPGRADE_ODOO=${UPGRADE_ODOO:-"0"}

ENV ODOO_BASEPATH ${ODOO_BASEPATH:-/opt/odoo}

# Odoo Configuration file variables and defaults
ARG ADMIN_PASSWORD
ARG PGHOST
ARG PGUSER
ARG PGPORT
ARG PGPASSWORD
ARG DB_TEMPLATE
ARG HTTP_INTERFACE
ARG HTTP_PORT
ARG DBFILTER
ARG DBNAME
ARG SERVER_WIDE_MODULES

ENV \
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-my-weak-password} \
    ODOO_DATA_DIR=${ODOO_DATA_DIR:-/var/lib/odoo} \
    DB_PORT_5432_TCP_ADDR=${PGHOST:-db} \
    DB_MAXCONN=${DB_MAXCONN:-64} \
    DB_ENV_POSTGRES_PASSWORD=${PGPASSWORD:-odoo} \
    DB_PORT_5432_TCP_PORT=${PGPORT:-5432} \
    DB_SSLMODE=${DB_SSLMODE:-prefer} \
    DB_TEMPLATE=${DB_TEMPLATE:-template1} \
    DB_ENV_POSTGRES_USER=${PGUSER:-odoo} \
    DBFILTER=${DBFILTER:-.*} \
    DBNAME=${DBNAME} \
    HTTP_INTERFACE=${HTTP_INTERFACE:-0.0.0.0} \
    HTTP_PORT=${HTTP_PORT:-8069} \
    LIMIT_REQUEST=${LIMIT_REQUEST:-8196} \
    LIMIT_MEMORY_HARD=${LIMIT_MEMORY_HARD:-2684354560} \
    LIMIT_MEMORY_SOFT=${LIMIT_MEMORY_SOFT:-2147483648} \
    LIMIT_TIME_CPU=${LIMIT_TIME_CPU:-60} \
    LIMIT_TIME_REAL=${LIMIT_TIME_REAL:-120} \
    LIMIT_TIME_REAL_CRON=${LIMIT_TIME_REAL_CRON:-0} \
    LIST_DB=${LIST_DB:-True} \
    LOG_DB=${LOG_DB:-False} \
    LOG_DB_LEVEL=${LOG_DB_LEVEL:-warning} \
    LOGFILE=${LOGFILE:-None} \
    LOG_HANDLER=${LOG_HANDLER:-:INFO} \
    LOG_LEVEL=${LOG_LEVEL:-info} \
    MAX_CRON_THREADS=${MAX_CRON_THREADS:-2} \
    PROXY_MODE=${PROXY_MODE:-False} \
    SERVER_WIDE_MODULES=${SERVER_WIDE_MODULES:-base,web} \
    SMTP_PASSWORD=${SMTP_PASSWORD:-False} \
    SMTP_PORT=${SMTP_PORT:-25} \
    SMTP_SERVER=${SMTP_SERVER:-localhost} \
    SMTP_SSL=${SMTP_SSL:-False} \
    SMTP_USER=${SMTP_USER:-False} \
    TEST_ENABLE=${TEST_ENABLE:-False} \
    UNACCENT=${UNACCENT:-False} \
    WITHOUT_DEMO=${WITHOUT_DEMO:-False} \
    WORKERS=${WORKERS:-0}

# JSON logging
ARG ODOO_LOGGING_JSON
ARG ODOO_STAGE

ENV \
    ODOO_LOGGING_JSON=${ODOO_LOGGING_JSON:-0} \
    ODOO_STAGE=${ODOO_STAGE}

# Define all needed directories
ENV ODOO_EXTRA_ADDONS ${ODOO_EXTRA_ADDONS:-/mnt/extra-addons}
ENV ODOO_ADDONS_BASEPATH ${ODOO_BASEPATH}/addons

ARG EXTRA_ADDONS_PATHS
ENV EXTRA_ADDONS_PATHS ${EXTRA_ADDONS_PATHS}

ARG EXTRA_MODULES
ENV EXTRA_MODULES ${EXTRA_MODULES}

# Healthcheck and entrypoint

healthcheck CMD curl --fail http://127.0.0.1:8069/web_editor/static/src/xml/ace.xml || exit 1
copy --chown=odoo:odoo ./resources/entrypoint.sh /
copy --chown=odoo:odoo ./resources/getaddons.py /
entrypoint ["/entrypoint.sh"]
expose 41234

user odoo
