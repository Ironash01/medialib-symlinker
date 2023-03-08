# Media Library Symlinker

The purpose of this bash script is to create symlinks for media files.

The filenaming convention used in symlinked files follow the kodi standard.

***https://kodi.wiki/view/Naming_video_files***

You can then use softwares likes tinyMediaManager to create metadata for your library or directly add the source to kodi and use the built-in scrapers.

**Specials are not supported yet, they will be placed in the "Extras" folder**

**Main episodes works fine**

# Overview of usage

```bash
Usage: medialib [OPTIONS]

Options:
        -h                      Print this help and exit.
        -a                      Equivalent of -c and -r
        -w                      Write list in ~/.config/medialib/.tv-list.
        -c                      Create symlinks in specified directory.
        -r                      Rename the video files inside the symlinks.
        -d <directory>          Define symlink directory.
        -e                      Edit various configs.
        -i <tv|mov>             Set library mode.
        -s <directory>          Add Parent source.
        -S <directory>          Remove Parent source.
        -l                      List infortmations: directories and sources.
        -u                      Updates keywords (no overwrite)

Setup custom-rename file in "~/.config/medialib" for custom renaming afterwards
Setup custom-special file in ~/.config/medialib for Special episodes in TV Shows
 ```

# File naming conventions

Edit the filenaming-rule, as basis I created a file called **_releases-convention.txt_** which describes directory structure and file naming used by several anime releasers.

For TV Shows the original structure and file naming is pretty simple among all releasers to not warrant a list.

Movies are also pretty simple. Search for the mkv file then search for audio file with matching name with main mkv file and put everything else inside the **Extras** folder.

# Extras folder

By default kodi searches for every sub-folders inside your parent source.
But if we set-up an advancedsettings.xml file kodi will ignore the Extras folder

```html
<advancedsettings version="1.0">
   <video>
      <excludefromscan>
          <regexp>[-\._ ](extrafanart|sample|trailer|extrathumbs)[-\._ ]</regexp>
      </excludefromscan>
      <excludefromlisting>
          <regexp>[-._ \\/](extrafanart|sample|trailer|extrathumbs)[-._ \\/]</regexp>
      </excludefromlisting>
      <!-- Extras: Section Start -->
      <excludefromscan action="append">
          <regexp>/extras/</regexp>
          <regexp>[\\/]extras[\\/]</regexp>
      </excludefromscan>
      <excludetvshowsfromscan action="append">
          <regexp>/extras/</regexp>
          <regexp>[\\/]extras[\\/]</regexp>
      </excludetvshowsfromscan>
      <!-- Extras: Section End -->
   </video>
 </advancedsettings>
 
 
```

Furthermore, by downloading the **"Extras"** addon users will be given a context-menu option to browse the contents of the Extras folder.

For information about the addon and instruction on how to create advancedsettings.xml
Refer to:

***https://kodi.wiki/view/Add-on:Extras***

# Why create a symlink instead?

Simple answer: Torrenting.

Some torrent clients have built-in file renamers but they are tedious to use when batch renaming, some do support scripting but requires setting up.

I wanted a solution to automatically rename the files, but still be able to seed them. At that point I stumbled upon "Symbolink Links"

# Mode of the script

You can set the mode using

```bash
medialib -i \<mode>
```
e.g.:

```bash
medialib -i tv

#OR

medialib -i mov
```

There are only two modes. please check your current mode before running options like -w and -c

To check your mode:

```bash
medialib -l
```

# Process of the script, simplified

1.Set mode

2.Set Symlink parent directory

3.Add sources

4.Write a list of the shows including their season numbers available, use a web scraper to determine the name of the show in TMDB

5.Create symlinks using the list

6.Rename the video files using the scraped information from TMDB

There are more details petertaining to the process, it is not magic. The script needs to be provided with strings to check and compare it with results from a tmdb search.

tv mode and mov mode are different