#!/bin/bash

set -euo pipefail

usage() {
	echo "Usage: $0 command [ options ]"
}
action=${1:-}
shift

TTY_OPT=(-T)
# TODO use click-odoo-contrib?
case "$action" in
	"restore")
		action=pg_restore
		# TODO reset database for testing
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
	"${TTY_OPT[@]}" \
	odoo "$action" "$@"
