#!/bin/bash
# Export translations (po files)
set -eu
file="${1:-}"

usage() {
	echo "Usage: $0 module/i18n/file.po[t]"
	echo "       $0 path"
	echo
	echo "Generate a po or pot file from the database."
	echo "With a path, generate pot file for each module in the directory and then"
	echo "merge it into po files."
	echo
	echo "To load a language for multiple modules, use:"
	echo "odoo-update modules --load-language=lang --i18n-overwrite"
}

case "$file" in
*.po)
	# Export a single po file (language and model from odoo)
	lang="$(basename "$file" .po)"
	cd "$(dirname "$file")/.."
	module="$(basename $PWD)"
	echo "Export $lang.po file for $module"
	odoo-bin --i18n-export "i18n/$lang.po" --language "$lang" --modules "$module" -d "${DB_NAME:-odoo}"
	;;
*.pot)
	# Export a single module pot file (just the file)
	cd "$(dirname "$file")/.."
	module="$(basename $PWD)"
	cd ..
	echo "Export pot file for $module"
	click-odoo-makepot --modules "$module"
	;;
--load)
	shift
	for file in "$@"
	do
		if [ ! -f "$file" ]
		then
			echo "Cannot import translation file $file"
			exit 1
		fi
		echo "Import translation $file"
		lang="$(basename "$file" .po)"
		odoo-bin --i18n-import "$file" --language="$lang" --i18n-overwrite -d "${DB_NAME:-odoo}"
	done
	;;
-*|"")
	# Usage
	usage
	exit 1;;
*)
	# Export translations for directories
	if [ -f "$file/__manifest__.py" ]
	then
		cd "$file"
		module="$(basename "$PWD")"
		cd ..
		echo "Generate pot for $module in ($PWD)"
		click-odoo-makepot --msgmerge --purge-old-translations -m "$module"
	else
		paths=($(odoo-getaddons.py "$file" | tr ',' ' '))
		for path in "${paths[@]}"
		do
			echo "Generate pot for modules in $path"
			odoo-getaddons.py -m 1 "$path"
			click-odoo-makepot --msgmerge --purge-old-translations --addons-dir "$path"
		done
	fi
esac
