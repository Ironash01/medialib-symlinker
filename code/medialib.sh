#!/bin/bash

# Declare important variables

declare runtime_config="./config/medialibrc"
declare tv_active="./config/tv-list"
declare mov_active="./config/mov-list"
declare config_folder="./config"

# Declare variables for filter files used in sed

declare filter_filename="./filters/filter-filename"
declare filter_html="./filters/filter-html"
declare filter_web="./filters/filter-web"
declare filter_specials="./filters/filter-specials"
declare custom_search="./filters/custom-search"

# Declare list of scripts to source

declare script_help="./source/help.sh"
declare script_tv="./source/src-tv.sh"
declare script_mov="./source/src-mov.sh"

# Sourced scripts

source "$runtime_config"
source "$script_tv"
source "$script_mov"
source "$script_help"

# Config check

if [ -f "$runtime_config" ]; then

	:
else

	mkdir -p "$config_folder"
	touch "$runtime_config"
	{

		echo "current_mode="
		echo "tv_link="
		echo "mov_link="

	} >>"$runtime_config"

	echo "$runtime_config created, set the mode first."
fi

# Checks dependencies

declare -a dependencies=("printf" "sed" "grep" "find" "curl" "read" "touch" "ln")

for dependencies_check in "${dependencies[@]}"; do

	if ! type "$dependencies_check" > dependency-check ; then
		echo "Missing dependency: $dependencies_check"
		exit 1

	fi
done

source "$runtime_config"

global-check_sources() {

	echo "Current mode: $current_mode"

	readarray -t source_array <<<"$(grep "tv_source" "$runtime_config" |
		sed "s|tv_source=||g")"

	for source in "${source_array[@]}"; do
		if [ -d "$source" ]; then
			echo "Success checking TV: $source"
		else
			echo "Source does not exist TV: $source"
		fi
	done

	if [ -d "$tv_link" ]; then
		echo "Success checking link directory TV: $tv_link"
	else
		echo "Link directory does not exist at TV:$tv_link"
	fi

	readarray -t source_array <<<"$(grep "mov_source" "$runtime_config" |
		sed "s|mov_source=||g")"

	for source in "${source_array[@]}"; do
		if [ -d "$source" ]; then
			echo "Success checking MOV: $source"
		else
			echo "Source does not exist MOV: $source"
		fi
	done

	if [ -d "$mov_link" ]; then
		echo "Success checking link directory MOV: $mov_link"
	else
		echo "Link directory does not exist at MOV:$mov_link"
	fi
}

global-select_mode() {

	case "$identify_mode" in
	tv)
		sed -i "s|current_mode=$current_mode|current_mode=$identify_mode|" "$runtime_config"
		;;
	mov)
		sed -i "s|current_mode=$current_mode|current_mode=$identify_mode|" "$runtime_config"
		;;
	*)
		echo 'Invalid mode'
		exit 1
		;;
	esac

}

while getopts 'halwcri:s:S:d:' OPTION; do

	case "$OPTION" in
	h)

		help
		;;

	a)

		case "$current_mode" in
		tv)
			tv-setup_library
			;;
		mov)
			mov-setup_library
			;;
		*)
			echo 'Invalid mode'
			;;
		esac
		;;

	l)
		global-check_sources
		;;
	i)

		identify_mode="$OPTARG"
		global-select_mode
		;;

	s)

		add_source="$OPTARG"
		case "$current_mode" in
		tv)
			tv-add_source
			;;
		mov)
			mov-add_source
			;;
		*)
			echo 'Invalid mode'
			;;
		esac
		;;

	S)

		remove_source="$OPTARG"
		case "$current_mode" in
		tv)
			tv-remove_source
			;;
		mov)
			mov-remove_source
			;;
		*)
			echo 'Invalid mode'
			;;
		esac
		;;

	d)

		directory_link="$OPTARG"
		case "$current_mode" in
		tv)
			tv-setlink_config
			;;
		mov)
			mov-setlink_config
			;;
		*)
			echo 'Invalid mode'
			;;
		esac
		;;

	w)

		case "$current_mode" in
		tv)
			tv-write_config
			;;
		mov)
			mov-write_config
			;;
		*)
			echo 'Invalid mode'
			;;
		esac
		;;

	c)
		case "$current_mode" in
		tv)
			tv-link_config
			;;
		mov)
			mov-link_config
			;;
		*)
			echo 'Invalid mode'
			;;
		esac
		;;
	r)
		case "$current_mode" in
		tv)
			tv-rename_library
			;;
		mov)
			mov-rename_library
			;;
		*)
			echo 'Invalid mode'
			;;
		esac
		;;
	?)
		echo 'Invalid option'
		;;

	esac
done
shift "$((OPTIND - 1))"
