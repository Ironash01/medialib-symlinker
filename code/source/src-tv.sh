#!/bin/bash

tv-write_config() {

	declare tmdb=
	declare search_query=

	function web_scraper {

		local passed_file=$1

		search_query=$(basename "$passed_file" | sed -E -f "$filter_web")

		# https://www.themoviedb.org/search/tv?query=

		search_query="$(echo "$search_query" | sed -E 's/\([0-9]+\)//g' \
		| sed -f "$filter_html" | sed 's/%27$//; s/%20$//')"

		echo "Processing to search tmdb: $search_query"

		if echo "$search_query" | grep -q -f "$custom_search"; then

			search_query=$(curl -s "https://www.themoviedb.org/search/tv?query=$search_query" \
			| grep -m 4 -e 'data-media-type="tv"' \
			| grep -e '<h2>' \
			| grep -Eo 'href="/tv/[0-9]+' \
			| sed 's|href="||' \
			| head -n 2 \
			| tail -n 1)

		else

			search_query=$(curl -s "https://www.themoviedb.org/search/tv?query=$search_query" \
			| grep -m 4 -e 'data-media-type="tv"' \
			| grep -e '<h2>' | grep -Eo 'href="/tv/[0-9]+' | sed 's|href="||' | head -n 1 | tail -n 1)

		fi

		tmdb=$(curl -s -S -L "https://www.themoviedb.org/$search_query" | grep '<title>' | \
		sed 's|<title>||; s|&#8212\; The Movie Database (TMDB)</title>||g; s|(TV Series |(|' | \
		sed -E 's|-[0-9]+\)|)|; s|\- \)|)|; s|^ *||g; s| *$||g' | sed -f "$filter_filename")

		echo "$tmdb"

		#echo "$tmdb"

	}

	function process_season {

		local file="$1"
		local season_number="$2"

		local file_basename="$file"

		#echo "$file_basename"

		if find "$file" -maxdepth 1 -type d \
		| sort \
		| grep -v -E '(The Movie|Movie)' \
		| sed "s|$file_basename||" \
		| grep -E "S[eason]*[_ ]*[0]*$season_number$" ; then

			web_scraper "$file"

			{

				echo "${file_basename}$(find "$file" -maxdepth 1 -type d \
				| sort \
				| grep -v -E '(The Movie|Movie)' \
				| sed "s|$file_basename||" \
				| grep -E "S[eason]*[_ ]*[0]*$season_number$")"
				echo "$season_number"
				echo "$tmdb"

			} >> "$tv_active"

		elif find "$file" -maxdepth 1 -type f -name '*.mkv' -o -name '*.mp4' -o -name '*.avi' -o -name '*.mov' -o -name '*.wmv' -o -name '*.flv' \
		| grep -E "S[eason]*[_ ]*[0]*$season_number" ; then

			web_scraper "$file"

			{

				echo "$file"
				echo "$season_number"
				echo "$tmdb"

			} >>"$tv_active"

		fi
	}

	function process_file {

		local file="$1"

		for ((season_number = 1; season_number <= 99; season_number=season_number+1)); do

			process_season "$file" "$season_number"

		done

		if [ "$(find "$file" -maxdepth 1 -type f -name '*.mkv' | grep -vE 'S[eason]*[0]*[0-9]' | grep -vE -f "$filter_specials")" ]; then

			web_scraper "$file"

			file_keyword="$(basename "$file" | sed -E -f "$filter_web" | sed 's/^\(\w*\)/\1\.*/g')"
			echo "file keyword : $file_keyword"

			search_season="$(curl -s -S -L "https://themoviedb.org$search_query/seasons" \
			| grep -E '<h2><a href="/tv/[0-9]*/season/[0-9]">.*</a></h2>')"

			search_season_lines="$(echo "$search_season" | wc -l)"

			echo "search_season: $search_season"

			search_season="$(echo "$search_season" \
			| grep -E "$file_keyword" \
			| sed -E 's/<h2><a href="\/tv\/[0-9]+\/season\///g; s/\"//g; s/\>.*<\/a>//g; s/<\/h2>//g; s/^ *//g; s/ *$//g')"

			echo "search_season final : $search_season"

			if [ ! -n "$search_season" ] && [ "$search_season_lines -le 2" ]; then
				search_season=1
			fi

			{

				echo "$file"
				echo "$search_season"
				echo "$tmdb"

			} >> "$tv_active"

		fi
	}

	function process_source {

		local source="$1"

		for file in "$source"/*; do

			process_file "$file"

		done



	}

	: >"$tv_active"

	readarray -t source_array <<<"$(grep "tv_source" "$runtime_config" | sed "s|tv_source=||g")"
	for source in "${source_array[@]}"; do
		process_source "$source"
	done

}

tv-link_config() {

	mkdir "$tv_link"
	local video_formats=("*.mp4" "*.mkv" "*.avi" "*.wmv" "*.flv")

	read_timer=$(wc -l <"$tv_active")

	for ((read_num = 1; read_num <= read_timer; read_num += 3)); do

		dir=$(sed -n "${read_num}p" "$tv_active")
		season=$(sed -n "$((read_num + 1))p" "$tv_active")
		tmdb=$(sed -n "$((read_num + 2))p" "$tv_active")

		mkdir -p "$tv_link/$tmdb/Season $season" "$tv_link/$tmdb/Extras"

		for cfs in "${video_formats[@]}" ; do
			find "$dir" -type f -name "$cfs" \
			| sort \
			| while read -r file; do

				if echo "$file" \
				| sed -E 's|.*[ ]*-[ ]*S[eason]*[0]*[0-9]*E[0]*[0-9]*[ ]*-[ ]*.*||g' \
				| grep -E -f "$filter_specials" ; then
					echo "special: $file"
					ln -s "$file" "$tv_link/$tmdb/Extras"

				else

					ln -s "$file" "$tv_link/$tmdb/Season $season"

				fi

			done
		done

		base_dir="$(dirname "$dir")"

		if ! grep "$base_dir" "$runtime_config" ; then

		echo "Success founding base dir: $base_dir"

			find "$dir/../" -maxdepth 1 -type f -name '*.mkv' | sort | while read -r file; do

				if echo "$file" | grep -E -f "$filter_specials"; then

					ln -s "$file" "$tv_link/$tmdb/Extras"
				fi


			done

			#Check for existing extras folder in source directory

			test_extras="$(find "$base_dir" -maxdepth 1 -type d | grep "Extras")"

			for cfs in "${video_formats[@]}" ; do

				find_extras="$(find "$test_extras" -mindepth 1 -type f -name "$cfs")"
				readarray -t find_extras_arr <<< "$find_extras"

				for file in "${find_extras_arr[@]}" ; do

				ln -s "$file" "$tv_link/$tmdb/Extras"

				done

			done

		fi

		find "$dir" -type f -name '*.ass' -o -name '*.ssa' -o -name '*.srt' -o -name '*.pgs' -o -name '*.sup' \
		| sort | while read -r file ; do

			if echo "$file" | grep -qEf "$filter_specials"; then

				ln -s "$file" "$tv_link/$tmdb/Extras/"

			else

				ln -s "$file" "$tv_link/$tmdb/Season $season"

			fi

		done

	done

}

tv_check_excess() {

	readarray -t tv_link_list <<< "$(ls "tv_link")"

	for item in "${tv_link_list[@]}"; do
		showname="$(echo "$item" | sed 's/(.*)$//')"
		year="$(echo "$item" | grep -Eo '\([0-9]{4}\)$'| sed 's/[()]//g')"
		search_query="$showname y:$year"
		
		
	done

}

tv-rename_library() {

	declare anime_show=

	function process_rename {

		local current_source="$1"

		for episode in "$current_source"/*.mkv; do

			season_number="$(dirname "$episode")"
			season_number="$(basename "$season_number" | sed -E 's/Season//g; s/^ *//g; s/ *$//g;')"
			episode_number_modified="$(printf "%02d" "$episode_number")"
			season_number_modified="$(printf "%02d" "$season_number")"
			mv "$episode" "$current_source/$anime_show S${season_number_modified}E${episode_number_modified}.mkv"
			episode_number=$((episode_number + 1))

		done

		episode_number=1

		for episode in "$current_source"/*.ass; do

			season_number="$(dirname "$episode")"
			season_number="$(basename "$season_number" | sed -E 's/Season//g; s/^ *//g; s/ *$//g;')"
			episode_number_modified="$(printf "%02d" "$episode_number")"
			season_number_modified="$(printf "%02d" "$season_number")"
			mv "$episode" "$current_source/$anime_show S${season_number_modified}E${episode_number_modified}.ass"
			episode_number=$((episode_number + 1))

		done

	}

	readarray -t link_array <<< "$(find "$tv_link" -maxdepth 2 -type d | sort | grep -E 'Season [0-9]+')"
	for anime_directory in "${link_array[@]}"; do

		anime_show="$(dirname "$anime_directory")"
		anime_show="$(basename "$anime_show")"
		episode_number=1
		process_rename "$anime_directory"

	done

}

tv-setup_library() {

	tv-link_config
	sleep 1
	tv-rename_library

}

tv-setlink_config() {

	directory_link=$(echo "$directory_link" | sed "s|~|$HOME|g")
	echo "$directory_link"
	if [ -d "$directory_link" ]; then

		sed -i "s|tv_link=$tv_link|tv_link=$directory_link|" "$runtime_config"

	else

		read -p 'Directory does not exist, create? y or n: ' prompt

		case "$prompt" in

		y)
			mkdir -p "$directory_link"
			sed -i "s|tv_link=$tv_link|tv_link=$directory_link|" "$runtime_config"
			;;
		n)
			echo 'Directory not created'
			echo 'tv-setlink failed'
			exit 1
			;;
		*)
			echo 'Invalid option'
			;;

		esac
	fi

}

tv-add_source() {

	add_source="$(echo "$add_source" | sed 's/\/$//g')"

	if [ -d "$add_source" ] && [ "$(grep -c -o "$add_source" "$runtime_config")" == 0 ]; then

		echo "tv_source=$add_source" >> "$runtime_config"

	else

		echo 'Directory does not exist or source already added'
		exit 1

	fi

}

tv_remove_source() {

	sed -i "/${remove_source//\//\\/}/d" "$runtime_config"

}

tv-exclude_config() {

	count_config=$(wc -l <"$tv_active")
	for ((i = 1; i <= count_config; i += 3)); do

		current_dir=$(head -n "$i" "$tv_active" | tail -n 1)

		if [ "$current_dir" == "$(grep -e "$current_dir" "$exclude_dirs")" ]; then

			:
		else

			echo "$current_dir" >>"$exclude_dirs"

		fi

	done

}
