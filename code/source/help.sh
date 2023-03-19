#!/bin/bash

help() {

	echo Usage: medialib [OPTIONS]
	echo
	echo Options:
	echo ' -h 		Print this help and exit.'
    echo ' -a 		Create symlinks for each show and then renames them afterwards Equivalent of -rc'
    echo ' -w 		Write config file in ~/.config/medialib/.tv-list'
    echo ' -c 		Create symlinks in specified directory, config file must exists.'
    echo ' -r 		Rename the video files inside the symlinks.'
    echo ' -d <directory>	Define symlink directory'
    echo ' -i <tv|tmov|t>	Set library mode'
	echo ' -s <directory>	Add Parent source'
	echo ' -S <directory>	Remove Parent source'
    echo ' -l 		List information, tests source and previews various variables'
    echo ' -u 		Updates keywords'
    echo
    echo 'Setup 'custom-rename' file in "~/.config/medialib" for custom renaming afterwards'
    echo 'Setup 'custom-special' file in ~/.config/medialib for Special episodes in TV Shows'
    echo ' '

}
