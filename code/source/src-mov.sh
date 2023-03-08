#!/bin/bash

mov-write_config() {

    : >"$mov_active"

    declare search_query
    declare search_query_year

    function web_scraper {

        local mov_file="$1"

        search_query="$(basename "$mov_file" | sed -E -f "$filter_web")"

        if [ -n "$search_query" ]; then

            #echo "$search_query"
            search_query_year=$(echo $search_query | grep -Eo '\(*[0-9]{4}\)*$' | sed -E 's/\(//g; s/\)//g')

            if [ -n "$search_query_year" ]; then

                #echo "$search_query_year"
                search_query="$(echo "$search_query" | sed -E 's/\(*[0-9]{4}\)*$//g')"
                search_query="$search_query y:$search_query_year"
                search_query="$(echo "$search_query" | sed -E 's/[^A-Za-z][0-9]{4} *.*y:/ y:/')"
                search_query="$(echo "$search_query" | sed -f "$filter_html" | sed s"/%27//g")"
                #echo "Processing search: $search_query"

                #https://www.themoviedb.org/search/movie?query=

                search_query="$(curl -s -S -L "https://www.themoviedb.org/search/movie?query=$search_query" |
                    grep -E 'data-media-type="movie"' |
                    grep -o '<h2>.*</h2>' | sed 's/<[/]*h2>//g' | head -n 1 | tail -n 1)"

                #echo "Final result: $search_query ($search_query_year)"
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

            if [ -n "$(find "$mov_directory" -maxdepth 1 -type f -name '*.mkv')" ]; then

                for mov_file in "$mov_directory"/*.mkv; do

                    mov_file="$(echo "$mov_file" | grep -vi 'Sample')"
                    web_scraper "$mov_file"

                done

            fi

            if [ -n "$(find "$mov_directory" -maxdepth 1 -type f -name '*.mp4')" ]; then

                for mov_file in "$mov_directory"/*.mp4; do

                    mov_file="$(echo "$mov_file" | grep -vi 'Sample.mp4')"
                    web_scraper "$mov_file"

                done

            fi

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
    config_read_lines="$(wc -l < "$mov_active")"
    echo "$config_read_lines"

    for ((i = 1; i <= config_read_lines; i+=2)); do

        echo "loop $i"

        mov_file_directory="$(sed -n "${i}p" "$mov_active")"
        mov_file_tmdb="$(sed -n "$((i+1))p" "$mov_active")"

        echo "Directory: $mov_file_directory"
        echo "TMDB name: $mov_file_tmdb"

        mov_base_directory="$(dirname "$mov_file_directory")"
        mov_base_filename="$(basename "$mov_file_directory" | sed -E 's/\....$//g')"

        if [ -f "$mov_base_directory/$mov_base_filename.mp3" ]; then

            mov_audio_file="$mov_base_filename.mp3"
            echo "External audio found: $mov_audio_file"


        elif [ -f "$mov_base_directory/$mov_base_filename.aac" ]; then

            mov_audio_file="$mov_base_filename.aac"
            echo "External audio found: $mov_audio_file"

        elif [ -f "$mov_base_directory/$mov_base_filename.ac3" ]; then

            mov_audio_file="$mov_base_filename.ac3"
            echo "External audio found: $mov_audio_file"

        elif [ -f "$mov_base_directory/$mov_base_filename.dts" ]; then

            mov_audio_file="$mov_base_filename.dts"
            echo "External audio found: $mov_audio_file"

        elif [ -f "$mov_base_directory/$mov_base_filename.flac" ]; then

            mov_audio_file="$mov_base_filename.flac"
            echo "External audio found: $mov_audio_file"

        else
            :
        fi

        mov_extras="$(find "$mov_base_directory" -type f -name '*.mkv' -o -name '*.mp4' \
        | grep -vF "$(basename "$mov_file_directory")")"

        readarray -t mov_extras_array <<< "$mov_extras"

        for file in "${mov_extras_array[@]}"; do

            echo "Extras for $mov_base_filename:"$file""            

        done



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
