# Music Curation Tooling

This is a complex workflow! If it is ever fully documented, this is the beginning!

## File Naming Format

The workflow outputs mp3 files named to identify their sequence in a set, the artist or composer,
specific opus or catalog, composition, key, and performance details; while the sequence, composer,
and composition are expected, the other details are optional. Following this info in the
filename is a unique id, and any transcoding parameters used. Typically this information 
is enough to uniquly identify, or search for, the original recording from a collection;
download the original master file, extract the particular excerpt and transcode a new
mp3 with the same parameters.

Output mp3 files are moved to a `./loss` directory when they are complete.
Normally they would be imedately moved to a playlist directory, but
this tends to be a repositary for sub-optimal transcodings which didn't
pass the listening test, or backup for when playlist files are updated
with new parameters.

Intermediate wav, flac, meas, and tmp files are created and stored in @/tmp,
these files only use the id and transcoding parameters in their names.
Files in process are stored with a trailing tildi (~), which is removed when that process is done.
Any file with the correct naming scheme in @/tmp is assumed to be viable cache data, and will be used
to save processing time, these wav and flac files should be purged as needed to save space.

Meta data, including media thumbnail art, json comments and description are stored in @/meta.
A directory called `orig`, stores original master files, which are hard linked to their
equivalent file in @.

Additional section meta data is stored in 'comma files' these files are named by a base 32 character
followed by a comma, `/^[0123456789abcdefghjkmnpqrstuvxyz]*,/` and store section
information about the mp3s beginning with the same character. The section info is terminated
by a blank line, the remainder of the file is periodically refreshed with calculated
a program duration per artist overview.

Artist or recording meta data may be stored as `/^${b32re}00,.*\.txt/` eg p00,set-name.txt

All of these directories and files are enclosed in a project directory in the form `6432-name`
describing the time of creation and name of the collection. Time is represented by the four
most significant characters of unix time in hex. In this scheme the number increments about
every 18 hours. Add 4 zeros, and convert to decimal for an approximation of regular unix time.

A script directory encloses `release.sh`, `exclude.sh` and a directory callled `./class`.
Within the class directory are regex lists of various classifications.

### Transcoding Parameters

* `_^XXXXXXXXXX.opus` the master file, xxxxxx is a unique id, and the file is stored in an `./@` directory.
* `ss=10 to=610` the "start seconds," and "to seconds" from the master
* `t=1.05 p=1.0216 r3` indicate rubberband parameters, the final time is 1.05 longer than the original, and the pitch is 1 and 216/10000 semitoneis higher
* `ln` means the excerpt has been ffmpeg loudness measured and normalized
* `parc`, `par2`, `kbd3`, `hrn3`, etc, are various sox compression envlopes
* 4db, -3db, etc are final volume adjustments applied by sox after compression when encoding the mp3

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

## Workflow

The workflow is highly optimized for rapid itterative curation activities.
All of these commands are extended shell functions.

* `linkdirs` displays the project directories below `$links`
* `_youtube url [dir]` will download the url audio, similar commands get videos and lists of content.
  * `_youtube_json2txt` is called automatically to render needful yaml from json
  * `_youtube_comment_unflatten` renders readable comments from yaml data
* `formfile` will render the commands to create transcoded mp3 from input file
  * `f2rb2mp3` accepts transcoding parameters input file and output file data to process the master to mp3
* `numlist` accepts a file list and returns shell commands to rename the files, preserving their major sequence character and incrementing in base 32, conveniently ignoring comma files `/${b32re},$/` and artist metadata files `/^${b32re}00,.*\.txt/`
* release.sh acts on all of the hard coded releases (each as needed), or specified ones.
  * updates chkstat report of playlist
  * updates pitch and tempo parameter overview
  * creats clean playlist directory in the `$links/0/kind/$name` directory
  * renders curation markdown into html
  * renders comma file data into overview txt with
  * renders a file listing into txt
  * `sync` argument will cause `$links/0/kind` releases to sync to to removable media.
* `comma_mp3.sh` may be run manually durring curation development
* `exclude.sh` may be run manually to remove files matching class regex from release media.

## Export

* Create a release in `$links/0/{volume}` with [./release.sh](./release.sh)
  * volume names are hard coded
  * this will invoke `./comma_mp3.sh` to generate _comma_files_ in respective mp3 directories of each volume name, and also the `${name}.view` files (a copy of `0,` summaries), seen here.
* For release to a sd card, use `./release.sh sync`
  * a specific volume name(s) may follow `sync` to force a volume release, otherwise only changed volumes will be released, `all` may follow sync to force release of all hard coded volumes.
  * the destination path is hard coded to `/volumes/CURATE/kind`
* Use [./exclude.sh](./exclude.sh) to purge a genera ([./class/](./class/) list) from a release.

