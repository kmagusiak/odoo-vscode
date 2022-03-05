#!/bin/bash

set -euo pipefail

usage() {
	echo "Usage: $0 action_or_command [ options ]"
	echo
	echo " list           List databases"
	echo " status         Container status"
	echo " dump[all] | restore"
	echo "                Aliases for pg_* commands"
	echo " restore-sql    Restore using psql"
	echo " volume-backup | volume-restore volume_name [file_name]"
	echo "                Tar or untar files in a volume"
}
action=${1:-}
[ $# -eq 0 ] || shift

[ ! -f .env ] || source .env
: ${PGUSER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:-odoo}}}
: ${PGPASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD}}}

param_volume_and_file() {
	volume="${1:-}"
	file="${2:-backup.tar}"
	if [ -z "$volume" ]
	then
		echo "Missing volume name"
		exit 1
	fi
}

TTY_OPT=(-T)
case "$action" in
	"list")
		TTY_OPT=()
		action=psql
		set -- -l
		;;
	"status")
		docker-compose ps db
		exit $?
		;;
	"dumpall")
		action=pg_dumpall
		;;
	"dump")
		action=pg_dump
		;;
	"restore-sql")
		action=psql
		;;
	"restore")
		action=pg_restore
		;;
	"volume-backup")
		param_volume_and_file "$@"
		docker-compose run -T --rm -v "$volume:/data:ro" -v "$(pwd):/backup" db \
			bash -c "tar cvf '/backup/$file' /data && chown $UID:$GID '/backup/$file'"
		exit $?
		;;
	"volume-restore")
		param_volume_and_file "$@"
		docker-compose run -T --rm -v "$volume:/data" -v "$(pwd):/backup:ro" db \
			bash -c "cd /data && tar xvf '/backup/$file' --strip 1"
		exit $?
		;;
	--help|-h)
		usage
		;;
	"")
		echo "No action specified"
		usage
		exit 1
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
