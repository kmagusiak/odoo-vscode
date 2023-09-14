#!/bin/bash
# Export translations (po files)
set -eu
file="${1:-}"

usage() {
	echo "Usage: $0 module/i18n/file.po[t]"
	echo "       $0 path"
	echo "       $0 --merge path/module ..."
	echo "       $0 --load path/module/i18n/fr.po"
	echo
	echo "Generate a po or pot file from the database."
	echo "With a path, generate pot file for each module in the directory and then"
	echo "merge it into po files."
	echo
	echo "To load a language for multiple modules, use:"
	echo "odoo-update modules --load-language=lang --i18n-overwrite"
	echo
	echo "You can merge (--merge) the pot file for each provided addon directory"
}

merge_lang_files() {
	(_merge_lang_files "$@")
}
_merge_lang_files() {
	path="$1"
	module="$(basename $path)"
	[ -f "$path/i18n/$module.pot" ] || return 0
	cd "$path"
	cd i18n
	for file_lang in *.po
	do
		[ "$file_lang" != '*.po' ] || continue
		echo "Update $module: $file_lang"
		# merge with pot file
		# use either --no-fuzzy-matching otherwise
		# translate all fuzzy text or keep only translated
		msgmerge --quiet --update --backup=none --fuzzy-matching \
			"$file_lang" "$module.pot"
		# remove obsolete and format file
		msgattrib --no-obsolete \
			--sort-by-file --width 300 \
			--output-file "$file_lang" "$file_lang"
	done
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
	click-odoo-makepot --modules "$module" -d "${DB_NAME:-odoo}"
	;;
--merge)
	shift
	merge_lang_files "$@"
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
		click-odoo-makepot -m "$module" -d "${DB_NAME:-odoo}"
		merge_lang_files "$module"
	else
		paths=($(odoo-getaddons.py "$file" | tr ',' ' '))
		for path in "${paths[@]}"
		do
			echo "Generate pot for modules in $path"
			odoo-getaddons.py -m 1 "$path"
			click-odoo-makepot --addons-dir "$path" -d "${DB_NAME:-odoo}"
			for module in $(odoo-getaddons.py -m 1 "$path" | tr ',' ' ')
			do
				merge_lang_files "$path/$module"
			done
		done
	fi
esac
