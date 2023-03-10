#!/bin/bash

mov-write_config() {

    : >"$mov_active"

    declare search_query
    declare search_query_year

    function web_scraper {

        local mov_file="$1"

        search_query="$(basename "$mov_file" | sed -E -f "$filter_web_mov")"

        if [ -n "$search_query" ]; then

            search_query_year=$(echo "$search_query" | grep -Eo '\(*[0-9]{4}\)*$' |
                sed -E 's/\(//g; s/\)//g')

            if [ -n "$search_query_year" ]; then

                #echo "$search_query_year"
                search_query="$(echo "$search_query" | sed -E 's/\(*[0-9]{4}\)*$//g')"
                search_query="$search_query y:$search_query_year"
                search_query="$(echo "$search_query" | sed -E 's/[^A-Za-z][0-9]{4} *.*y:/ y:/')"

                echo "Processing search: $search_query"

                search_query="$(echo "$search_query" | sed -f "$filter_html" | sed s"/%27//g")"

                #https://www.themoviedb.org/search/movie?query=

                search_query="$(curl -s -S -L "https://www.themoviedb.org/search/movie?query=$search_query" |
                    grep -E 'data-media-type="movie"' |
                    grep -o '<h2>.*</h2>' | sed 's/<[/]*h2>//g' | head -n 1 | tail -n 1)"

                echo "Final result: $search_query ($search_query_year)"

                {

                    echo "$mov_file"
                    echo "$search_query ($search_query_year)"

                } >>"$mov_active"

            fi

        fi

    }

    function process_source {

        local source="$1"

        for mov_directory in "$source"/*; do

            declare video_formats
            video_formats=(".mkv" ".mp4" ".avi" ".mov" ".wmv" ".flv")

            for item_vformat in "${video_formats[@]}"; do

                if [ -n "$(find "$mov_directory" -maxdepth 1 -type f -name "*$item_vformat")" ]; then

                    for mov_file in "$mov_directory"/*"$item_vformat"; do

                        mov_file="$(echo "$mov_file" | grep -vi 'Sample')"
                        web_scraper "$mov_file"

                    done

                fi

            done

        done

    }

    readarray -t source_array <<<"$(grep 'mov_source' "$runtime_config" | sed 's/mov_source=//')"

    for source in "${source_array[@]}"; do

        process_source "$source"

    done

}

mov-link_config() {

    if [ ! -d "$mov_link" ]; then
        mkdir "$mov_link"
    fi

    declare config_read_lines
    config_read_lines="$(wc -l <"$mov_active")"
    echo "$config_read_lines"

    for ((i = 1; i <= config_read_lines; i += 2)); do

        #echo "loop $i"

        mov_file_directory="$(sed -n "${i}p" "$mov_active")"
        mov_file_tmdb="$(sed -n "$((i + 1))p" "$mov_active")"

        #echo "Directory: $mov_file_directory"
        #echo "TMDB name: $mov_file_tmdb"

        if [ ! -d "$mov_link/$mov_file_tmdb" ]; then

            mkdir "$mov_link/$mov_file_tmdb"

        fi

        ln -s "$mov_file_directory" "$mov_link/$mov_file_tmdb/"

        mov_base_directory="$(dirname "$mov_file_directory")"
        mov_base_filename="$(basename "$mov_file_directory" | sed -E 's/\....$//g')"

        declare extaudio_formats
        extaudio_formats=(".aac" ".ac3" ".dts" ".wma" ".mp3" ".flac")

        for item_audio in "${extaudio_formats[@]}"; do

            if [ -f "$mov_base_directory/${mov_base_filename}$item_audio" ]; then

                echo "External audio found."
                ln -s "$mov_base_directory/${mov_base_filename}$item_audio" "$mov_link/$mov_file_tmdb"

            fi

        done

        declare subtitle_formats
        subtitle_formats=(".ass" ".ssa" ".srt" ".pgs" ".sup")

        for item_sub in "${subtitle_formats[@]}"; do

            if [ -f "$mov_base_directory/${mov_base_filename}$item_sub" ]; then

                echo "External subtitle found"
                ln -s "$mov_base_directory/${mov_base_filename}$item_sub" "$mov_link/$mov_file_tmdb"

            fi

        done

        mov_extras="$(find "$mov_base_directory" -type f -name '*.mkv' -o -name '*.mp4' -o -name '*.avi' -o -name '*.mov' |
            grep -vF "$(basename "$mov_file_directory")")"

        readarray -t mov_extras_array <<<"$mov_extras"

        for file in "${mov_extras_array[@]}"; do

            #echo "Extras for $mov_base_filename:$file"

            if [ ! -d "$mov_link/$mov_file_tmdb/Extras" ]; then

                mkdir "$mov_link/$mov_file_tmdb/Extras"

            fi

            ln -s "$file" "$mov_link/$mov_file_tmdb/Extras"

        done

    done

}

mov-rename_library() {

    if [ ! -d "$mov_link" ]; then
        echo "Directory link does not exist"
        exit 1
    fi

    readarray -t current_movie <<<"$(find "$mov_link" -maxdepth 2 -type l -name '*.mkv' | sort)"

    for item in "${current_movie[@]}"; do
        echo "$item"
        movie_basedir="$(dirname "$item")"
        movie_basename="$(basename "$movie_basedir")"
    done

}

mov-setlink_config() {

    directory_link=$(echo "$directory_link" | sed "s|~|$HOME|g")
    echo "$directory_link"
    if [ -d "$directory_link" ]; then

        sed -i "s|mov_link=$mov_link|mov_link=$directory_link|" "$runtime_config"

    else

        read -p 'Directory does not exist, create? y or n: ' prompt

        case "$prompt" in

        y)
            mkdir -p "$directory_link"
            sed -i "s|mov_link=$mov_link|mov_link=$directory_link|" "$runtime_config"
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

mov-add_source() {

    if [ -d "$add_source" ] && [ "$(grep -c -o "$add_source" "$runtime_config")" == 0 ]; then

        echo "mov_source=$add_source" >>"$runtime_config"

    else

        echo 'Directory does not exist or source already added'
        exit 1

    fi

}

mov-remove_source() {

    sed -i "/${remove_source//\//\\/}/d" "$runtime_config"

}
