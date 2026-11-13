#!bin/bash
set -eu

psql -v ON_ERROR_STOP=1 \
    --username "${POSTGRES_USER}" \
    --dbname "${POSTGRES_DB}" \
    --set=app_user="${APP_USER}" \
    --set=app_password="${APP_PASSWORD}" <<'SQL'
DROP ROLE IF EXISTS :"app_user";
CREATE ROLE :"app_user"
WITH LOGIN PASSWORD :'app_password'
CREATEDB;

SQL
