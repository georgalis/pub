# Music Curation Tooling

This is a complex workflow! If it is ever fully documented,
this is the beginning!


## Environment

these variables should be set and exported
* links= {path to enclosing directory of volumes, where mp3s for release are stored}
* rubberband= {path to https://github.com/breakfastquay/rubberband executable}
* ytdl= {path to https://github.com/yt-dlp/yt-dlp executable}

## Software
* Mac OSX 13.3 (tested) with pkgsrc-2022Q4, yt-dlp, ffmpeg, sox, rubberband, rsync 
* The workflow tools are mostly bash shell functions in
  * [fn.bash](https://github.com/georgalis/pub/blob/master/sub/fn.bash),
  * and, environment setup found in [.profile](https://github.com/georgalis/pub/blob/master/skel/.profile)

## Export
* Create a release in `$links/0/{volume}` with [./release.sh](./release.sh)
  * volume names are hard coded
  * this will invoke `./comma_mp3.sh` to generate _comma_files_ in respective mp3 directories of each volume name, and also the `${name}.view` files (a copy of `0,` summaries), seen here.
* For release to a sd card, use `./release.sh sync`
  * a specific volume name(s) may follow `sync` to force a volume release, otherwise only changed volumes will be released, `all` may follow sync to force release of all hard coded volumes.
  * the destination path is hard coded to `/volumes/CURATE/kind`
* Use [./exclude.sh](./exclude.sh) to purge a genera ([./class/](./class/) list) from a release.

