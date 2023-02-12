# Music Curation Tooling

This is a complex workflow! If it is ever fully documented,
this is the beginning!


## Environment

these variables should be set and exported
links=
rubberband=/opt/homebrew/bin/rubberband
ytdl=/opt/homebrew/bin/yt-dlp

## Software
* Mac OSX 13.2 (tested) with brew: yt-dlp ffmpeg rubberband rsync 
* The workflow tools are mostly bash shell functions in
  * [fn.bash](https://github.com/georgalis/pub/blob/master/sub/fn.bash),
  * and, environment setup found in [.profile](https://github.com/georgalis/pub/blob/master/skel/.profile)

## Export
* Create a release in `$links/0/{volume}` with [./release.sh](./release.sh)
  * volume names are hard coded
* For release to a sd card, use `./release.sh sync`
  * the destination path is hard coded to `/volumes/CURATE/kind`
* Use [./exclude.sh](./exclude.sh) to purge a genera ([./class/](./class/) list) from a release.

