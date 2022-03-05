#!/bin/bash

set -euo pipefail

usage() {
	echo "Usage: $0 action_or_command [ options ]"
}
action=${1:-}
shift

[ ! -f .env ] || source .env
: ${PGUSER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:-odoo}}}
: ${PGPASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD}}}

TTY_OPT=(-T)
case "$action" in
	"list")
		TTY_OPT=()
		action=psql
		set -- -l
		;;
	"dumpall")
		action=pg_dumpall
		;;
	"dump")
		action=pg_dump
		;;
	"psql-restore")
		action=psql
		;;
	"restore")
		action=pg_restore
		;;
	"volume-backup")
		volume="$1"
		file="${2:-backup.tar}"
		docker-compose run -T --rm -v "$volume:/data:ro" -v "$(pwd):/backup" db \
			tar cvf "/backup/$file" /data
		exit $?
		;;
	"volume-restore")
		volume="$1"
		file="${2:-backup.tar}"
		docker-compose run -T --rm -v "$volume:/data" -v "$(pwd):/backup:ro" db \
			bash -c "cd /data && tar xvf '/backup/$file' --strip 1"
		exit $?
		;;
	--help|-h)
		usage
		;;
	-*)
		echo "Unknown arguments: $*"
		usage
		exit 1
		;;
	*)
		TTY_OPT=()
		;;
esac

docker-compose exec \
	-e "PGUSER=$PGUSER" \
	-e "PGPASSWORD=$PGPASSWORD" \
	"${TTY_OPT[@]}" \
	db "$action" "$@"
