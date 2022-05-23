#!/usr/env bash

# Sundry functions

# more test
# echo "$SHELL"
# echo "$BASH_VERSINFO"      "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"
# echo "${BASH_VERSINFO[3]}" "${BASH_VERSINFO[4]}" "${BASH_VERSINFO[5]}"

validfn () { #:> hash comparison to validate shell functions
    [ "$1" ] || {
      cat 1>&2 <<-'EOF'
		#:: $FUNCNAME {function}        ; returns {function-name} {hash}
		#:: $FUNCNAME {function} {hash} ; return no error, if hash match
		#:: the former is intended to provide data for the latter
		#:: env hashfn= to set the hashing function, "%08x %8x %s\n" cksum program
		EOF
      return 1 ;}
    [ "${SHELL##*/}" = "bash" ] || { echo "> > > ${0} : Not bash < < <" >&2 ; return 1 ;}
    local _hashfn
    [ "$hashfn" ] || { _hashfn () { declare -f "$1" | printf "%s %08x %08x\n" "$1" $(cksum) ;} && _hashfn="_hashfn" ;}
    [ "$_hashfn" ] || _hashfn="$hashfn" # for bugs... use stronger hash for nefarious env
    local fn="$1" ; fn="$(sed '/^[ ]*#/d' <<<"$fn")"
    [ "$fn" ] || return 0 # drop comments
    shift
    local sum="$fn $*"
    local check="$( "$_hashfn" "$fn" )"
    [ "$*" ] || { echo "$check" ; return 0 ;} # provide hash data if none given to check
    [ "$sum" = "$check" ] || { # report hash data discrepancies on failed check
    cat 1>&2 <<-EOF
		>>>---
		$FUNCNAME error :
		 unit:'$sum'
		  env:'$check'
		<<<---
		EOF
    return 1 ;}
    } # validfn
#
# Now that validfn is defined, run the framework on functions expected from .profile
# (an example of syetem environment validation)
#
# eg first, generate hashses of known functions...
#
# while read f; do validfn $f ; done <<EOF
# devnul
# stderr
# chkstd
# chkwrn
# chkerr
# logwrn
# logerr
# siff
# EOF
#
# run validfn to check the operational env vs the generated hashes
verb2="${verb2:-devnul}"
while IFS= read fndata ; do
$verb2 "validfn $fndata"
       validfn $fndata && true || { echo "validfn error : $fndata" 1>&2 ; return 1 ;}
done <<EOF
# pub/skel/.profile 20220104
devnul 216e1370 0000001d
stderr 7ccc5704 00000037
chkstd ee4aa465 00000032
chkwrn 18c46093 0000005e
chkerr 57d3ff82 0000005f
logwrn e5806086 00000061
logerr ffddd972 00000062
siff 1ff96e34 000000fc
EOF

alias   gst='git status --short | sed "s/^\?/ \?/" | sort'
alias   gls='git ls-files'
alias   gdf='git diff --name-only'
alias gdiff='git diff --minimal -U0'
alias  gadd='git add'
alias  gcom='git commit'
alias gpush='git push'
alias gpull='git pull'
alias   gbr='git branch'
alias   gco='git checkout'
alias  grst='git reset'
#alias  gmv='git mv'
alias  glog='git log'
alias  gref='git reflog'
alias  grst='git reset HEAD'
# restore files #  git checkout -- {opt-file-spec}
# undo add      #  git reset       {opt-file-spec}
#=======================================================
# https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified
# Commit hash, at least four characters and unambiguous beginning
#
# Three Trees
#  HEAD    : Last repo commit, next parent
#  Index   : Local proposed, next repo commit
#  Working : Sandbox
#                           HEAD  Index Workdir  Safe?
#==== Repo Commit ===========================================
#  reset --soft [commit]     REF    -      -      YES
#  reset        [commit]     REF   YES     -      YES
#  reset --hard [commit]     REF   YES    YES      -
#  checkout     <commit>     HEAD  YES    YES     YES
#==== File =============================================
#  reset    [commit] <paths>  -    YES     -      YES
#  checkout [commit] <paths>  -    YES    YES      -
#=======================================================
# https://git-scm.com/docs/git-reset#_discussion
# https://git-scm.com/docs/giteveryday
# https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things
#
# all git statuses
agst () {
  local start=$@
  [ "$start" ] || start='.'
  find $start -name .git -type d | sort | while IFS= read a ; do
  ( cd "${a%/*}" ; git status --short ) | awk -v a="${a%/*}" '{printf "%-3s%s%s\n",$1,a"/./",$2,$3}'
  done ;}
agstlt () { lt $(agst ~ | awk '{print $2}' | while IFS= read a ; do find "$a" -type f ; done ) ;} # all repo changed/new files by mod time

## shell script fragments
# main () { # enable local varables
#
#local u h b t s d bak n tf
#u="$USER" # uid running the tests
# filein="${1##*/}" # basename arg1
# expr "$1" : ".*/" >/dev/null && pathin="${1%/*}" || pathin="." # dirname arg1
# filepin="$(cd "${pathin}" ; pwd -P)/${filein}" # full filepath
#h="$(cd $(dirname $0) && pwd -P)" # realpath of this script
#b="$(basename $0 | sed 's/.[^.]*$//')" # this program name less (.sh) extension
#t="$( { date '+%Y%m%d_%H%M%S_' && uuidgen ;} | sed -e 's/-.*//' | tr -d ' \n' )" # time based uniq id
# find . \( -path ./skel -o -path ./mkinst -o -path ./.git \) \! -prune -o -type f
# find -E . -regex '\./(skel|mkinst|\.git)$' -not -prune -o -type f
#[ -n "$1" ] && { cd "$1" && s="$PWD" ;} || chkerr "Expecting dir as arg1" # set src dir
#[ -d "$s" ] || chkerr "$s (arg1) is not a directory"
#[ -n "$2" ] && cd "$2" && d="$(pwd -P)" || d="$HOME" # set dest dir
#[ -d "$d" ] || chkerr "$d target (arg2) is not a directory"
# bak="${d}/${b}-${t}" # backup dir

catfold () { #:> on terminal output, fold long lines on words
    [ -t 1 ] && {
        local cols="$(tput cols)"
        fold -s -w $cols
        } || cat
    } # catfold
cattrunc () { #:> on terminal output, truncate lines to width
    [ -t 1 ] && {
        local cols="$(tput cols)";
        awk -v cols="$((cols-1))" 'length > cols{$0=substr($0,0,cols)"_"}1'
        } || cat
    } # cattrunc

# for comments download: yt-dlp is a youtube-dl fork based on the now inactive youtube-dlc
# https://github.com/yt-dlp/yt-dlp
# also, aparently (?) youtube throttles is you do not run javascript first (youtube-dl vs yt-dlp)
# cf https://github.com/ytdl-org/youtube-dl/issues/29326#issuecomment-894619419

_youtube_list () {
  local id="$1" d="$2"
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "no id?" ; return 1 ;}
  [ "$d" ]  || read -p "directory : " d
  [ -d "$d" ] || d="$(pwd -P)"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "invalid dir" ; return 1 ;}
  youtube-dl --write-info-json --write-thumbnail --restrict-filenames --abort-on-error --write-sub --yes-playlist \
   --audio-quality 0 --audio-format best --extract-audio --playlist-start 1 \
   -o "$d/%(playlist_title)s-%(playlist_id)s/0%(playlist_index)s,%(title)s-%(playlist_title)s-%(playlist_id)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  } # _youtube_list 20220516

_youtube_video_list () {
  local id="$1" d="$2"
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "no id?" ; return 1 ;}
  [ "$d" ]  || read -p "root directory : " d
  [ -d "$d" ] || d="$(pwd -P)"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "invalid dir" ; return 1 ;}
  youtube-dl --write-info-json --write-thumbnail --restrict-filenames --abort-on-error --write-sub --yes-playlist \
   --audio-quality 0 --audio-format best --playlist-start 1 \
   -o "$d/%(playlist_title)s-%(playlist_id)s/0%(playlist_index)s,%(title)s-%(playlist_title)s-%(playlist_id)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --yes-playlist \
   --audio-quality 0 --audio-format best --extract-audio --playlist-start 1 \
   -o "$d/%(playlist_title)s-%(playlist_id)s/0%(playlist_index)s,%(title)s-%(playlist_title)s-%(playlist_id)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  } # _youtube_video_list 20220516

_youtube () {
  local id="$1" d="$2"
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "no id?" ; return 1 ;}
  [ "$d" ]  || read -p "directory : " d
  [ -d "$d" ] || d="$(pwd -P)"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "invalid dir" ; return 1 ;}
  #[ "$ua" ] && uac="--user-agent '$ua'" || uac=''
  youtube-dl --write-info-json --write-thumbnail --restrict-filenames --abort-on-error --write-sub --no-playlist \
   --audio-quality 0 --audio-format best --extract-audio \
   -o "$d/0,%(title)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  } # _youtube 20220516

_youtube_video () {
  local id="$1" d="$2"
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "no id?" ; return 1 ;}
  [ "$d" ]  || read -p "directory : " d
  [ -d "$d" ] || d="$(pwd -P)"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "invalid dir" ; return 1 ;}
  youtube-dl --write-info-json --write-thumbnail --restrict-filenames --abort-on-error --write-sub --no-playlist \
   --audio-quality 0 --audio-format best \
   -o "$d/0,%(title)s-%(uploader_id)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --no-playlist \
   --audio-quality 0 --audio-format best --extract-audio \
   -o "$d/0,%(title)s-%(uploader_id)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  } # _youtube_video 20220516

_youtube_json2txt () {
  [ -f "${1}" ]     || { chkerr "$FUNCNAME : not a file : ${1}" ; return 1 ;}
  [ -f "${1}.txt" ] && { chkerr "$FUNCNAME : ${1}.txt exists" ; return 1 ;}
  jq --compact-output 'del(.formats, .thumbnail, .thumbnails, .downloader_options, .http_headers)' "$1" \
    | yq -P >"${1}.txt"
  echo "${1}.txt"
  } # _youtube_json2txt 20220516

span2ssto () { # start (arg1) span (arg2) and remaining args to f2rb2mp3
    # used to calculate ss= to= f2rb2mp3 parameters, given track legnths
    # eg
     # export offset=1
    # sp2ssto 0   7:14 01,\${a}-Song_For_My_Father-\${_r}
    # sp2ssto $to 6:07 02,\${a}-The_Natives_Are_Restless_Tonight-\${_r}
    # ss=0   to=435 f2rb2mp3 $_f 01,${a}-Song_For_My_Father-${_r}
    # ss=435 to=803 f2rb2mp3 $_f 02,${a}-The_Natives_Are_Restless_Tonight-${_r}
    local ss=$1 span= offc=;
    [ "$offset" ] && offc="$offset +" || offc='';
    span=$(dc -e "$2 $offc p")
    export to=$(dc -e "$(hms2sec $ss) $(hms2sec $span) + $offc p");
    shift 2 || shift || true
    echo ss=$ss to=$to f2rb2mp3 '$_f' $*
    echo "# $to is 0x$(kdb_xs2hu $(printf '%x' $to))"
    } # span2ssto 20220519
hms2sec () { # passthrough seconds or convert hh:mm:ss to seconds
    # must provide ss which may be ss.nn, hh: and hh:mm: are optional
    # a number must proceed every colin
  { # remove trailing 0 from seconds decimal
  [[ $1 == *:*:*:* ]] && { chkerr "too many ':' in $1" ; return 1 ;}
  [[ $1 == *:*:* ]] && { echo $1 | sed -e 's/:/ 0/g' \
        | awk '{print "3 k "$1" 60 60 * * "$2" 60 * "$3" + + p"}' | dc && return 0 ;}
  [[ $1 == *:* ]] && echo $1 | sed -e 's/:/ 0/g' \
        | awk '{print "3 k "$1" 60 * "$2" + p"}' | dc
  [[ $1 == *:* ]] || echo $1
  } | sed -e '/\./s/[0]*$//' -e 's/\.$//' ;} # hms2sec
prependf () {
  local basefp="$1"
  local title="$2"
  [ -z "$basefp" ] && { chkerr "prependf: base filepath (arg1) not set $@" ; return 1 ;}
  [ -f "$basefp" ] || { chkerr "prependf: base filepath (arg1) not a file $@" ; return 1 ;}
  [ "$title" ] || return 0 # no operation
  local basefn="$(basename "$basefp")"
  ( cd $(dirname "$basefp") && mv -f "$basefn" "${title}${basefn}" )
  } # prependf
f2rb2mp3 () ( # subshell function "file to rubberband to mp3", transcoding/tuning function
  # subshell sets pipefail and ensures PWD on err
    set -o errexit   # Exit on command non-zero status
    set -o errtrace  # any trap on ERR is inherited by shell functions
    set -o functrace # traps on DEBUG and RETURN are inherited by shell functions
    set -o pipefail  # exit pipeline on non-zero status (rightmost?)
  # validate env per
  # https://github.com/georgalis/pub/blob/master/skel/.profile
  # https://github.com/georgalis/pub/blob/master/sub/func.bash
  while IFS= read fndata ; do
    validfn $fndata || { echo "validfn error : $fndata" 1>&2 ; return 1 ;}
  done <<EOF
# pub/skel/.profile 20220105
devnul 216e1370 0000001d
stderr 7ccc5704 00000037
chkwrn 18c46093 0000005e
chkerr 57d3ff82 0000005f
# pub/sub/fn.bash 20220105
hms2sec e7a0bc8b 000001d6
prependf ac39e52a 000001b2
EOF
  [ -x "$(which "$rb")"  ] || { chkerr "$FUNCNAME : env rb not set to rubberband executable" ; return 1 ;}
  [ -x "$(which ffmpeg)" ] || { chkerr "$FUNCNAME : ffmpeg not in path" ; return 1 ;}
  [ -x "$(which sox)"    ] || { chkerr "$FUNCNAME : sox not in path" ; return 1 ;}
  # success valid env
  [ "$1" = "help" ] && { # a function to adjust audio file tempo and pitch independantly
    # depends on ffmpeg, rubberband and sox
    # https://hg.sr.ht/~breakfastquay/rubberband
    # https://github.com/breakfastquay/rubberband
    # https://breakfastquay.com/rubberband/
    # "Crispness" levels:
    #   -c 0   equivalent to --no-transients --no-lamination --window-long
    #   -c 1   equivalent to --detector-soft --no-lamination --window-long (for piano)
    #   -c 2   equivalent to --no-transients --no-lamination
    #   -c 3   equivalent to --no-transients
    #   -c 4   equivalent to --bl-transients
    #   -c 5   default processing options (none of below)
    #   -c 6   equivalent to --no-lamination --window-short (may be good for drums)
    #
    #   -L,    --loose          Relax timing in hope of better transient preservation
    #          --no-transients  Disable phase resynchronisation at transients
    #          --bl-transients  Band-limit phase resync to extreme frequencies
    #          --no-lamination  Disable phase lamination
    #          --window-long    Use longer processing window (actual size may vary)
    #          --window-short   Use shorter processing window
    #          --smoothing      Apply window presum and time-domain smoothing
    #          --detector-perc  Use percussive transient detector (as in pre-1.5)
    #          --detector-soft  Use soft transient detector
    #          --centre-focus   Preserve focus of centre material in stereo
    #                           (at a cost in width and individual channel quality)
    echo "# crisp:  0=mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive "
    echo "# Formant y/''  CenterFocus y/'' vol 0db/'' frequency (bhz|chz|N)/'' reverse y/''"
    echo "# cmp= $(declare -f $FUNCNAME | sed -e '/compand/!d' -e '/sed/d' -e 's/=.*//' -e 's/local//' | tr -s ' \n' '|')"
    declare -f $FUNCNAME | sed -e '/compand/!d' -e '/sed/d' | while IFS= read a ; do ${verb2} "$a" ; done
    echo "# ss= to= t= p= f= c= F= CF= off= tp= lra= i= cmp= v= f2rb2mp3 {file-in} {prepend-out}"
    echo "# ss=$ss to=$to t=$t p=$p f=$f c=$c F=$F CF=$CF off=$off tp=$tp lra=$lra i=$i cmp=$cmp v=$v f2rb2mp3 {file-in} {prepend-out}"
    return 0
    } # help
  [    "$1" ] || { f2rb2mp3 help ; return 1 ;}
  [ -f "$1" ] || { f2rb2mp3 help ; chkerr "no input flle $1" ; return 1 ;}
  local  verb="${verb:=chkwrn}"
  local verb2="${verb2:=devnul}"
  local verb3="${verb3:=devnul}"
  local infile="${1##*/}" # basename
  expr "$1" : ".*/" >/dev/null && inpath="${1%/*}" || inpath="." # input dirname
  local infilep="$(cd "${inpath}" ; pwd -P)/${infile}" # full filepath
  local prependt="$2"
  [ "${prependt}" ] || prependt=00,
  [ "$t" -o "$p" ] && { [ "$c" ] || local c=5 ;} || true # "Crispness"
  [ "$t" = 1 ] && local t= || true
  [ "$p" = 0 ] && local p= || true
  [ "$f" = 1 ] && local f= || true
  local tc='' tn='' ; [ "$t" ] && tc="--time $t"  tn="-t${t}" || true
  local pc='' pn='' ; [ "$p" ] && pc="--pitch $p" pn="-p${p}" || true
  local fhzc='' fhzn=''
  [ "$f" = "bhz" ] && { fhzc="-f 0.98181818181818" ; fhzn="-bhz" ;} || true # baroque 432 hz tuning, from classical 440
  [ "$f" = "chz" ] && { fhzc="-f 1.01851851851851" ; fhzn="-chz" ;} || true # classical 440 hz tuning, from baroque 432
  local cmpn='' cmpc=''
  local ckb0="compand 0.2,0.9  -70,-70,-60,-55,-50,-45,-35,-35,-20,-25,0,-12 6 -70 0.2"
  local ckb2="compand 0.2,0.9  -70,-99,-50,-60,-50,-45,-30,-30,-20,-25,0,-13 6 -70 0.2"
  local ckb3="compand 0.2,0.8  -60,-99,-50,-56,-38,-32,-23,-18,0,-4         -2 -60 0.2"
  local hrn1="compand 0.08,0.3 -68,-68,-50,-46,-18,-18,-0,-6                 2 -68 0"
  local hrn2="compand 0.08,0.3 -68,-68,-50,-46,-18,-18,-0,-6                -2 -68 0"
  local hrn3="compand 0.08,0.3 -74,-80,-50,-46,-18,-18,-0,-6                -1 -68 0"
  local cps1="compand 0.06,0.3 -70,-84,-50,-45,-32,-33,-0,-21              1.8 -71 0.013"
  local cps1="compand 0.07,0.25 -70,-84,-50,-45,-32,-33,-0,-21               3 -71 0.07"
  local par2="compand 0.09,0.25 -100,-116,-88,-97,-80,-80,-63,-72,-54,-60,-23,-48,0,-36             24 -95 0.08"
  local parc="compand 0.09,0.25 -97,-106,-85,-89,-73,-73,-57,-61,-40,-49,-21,-37,0,-25              12 -95 0.08"
  local para="compand 0.09,0.25 -95,-111,-85,-94,-75,-79,-65,-65,-51,-55,-36,-45,-19,-35,0,-25      10 -95 0.08"
  local par9="compand 0.09,0.25 -88,-104,-79,-88,-70,-74,-61,-61,-48,-52,-34,-43,-18,-34,0,-25       9 -88 0.08"
  local par8="compand 0.09,0.25 -80,-106,-72,-81,-65,-69,-57,-57,-45,-49,-32,-41,-17,-33,0,-25       8 -80 0.08"
  [ "$cmp" = "ckb" ]  && cmpn="$cmp" cmpc="$ckb0"
  [ "$cmp" = "hrn" ]  && cmpn="$cmp" cmpc="$hrn1"
  [ "$cmp" = "hrn2" ] && cmpn="$cmp" cmpc="$hrn2"
  [ "$cmp" = "hrn3" ] && cmpn="$cmp" cmpc="$hrn3"
  [ "$cmp" = "ckb2" ] && cmpn="$cmp" cmpc="$ckb2"
  [ "$cmp" = "ckb3" ] && cmpn="$cmp" cmpc="$ckb3"
  [ "$cmp" = "hrn1" ] && cmpn="$cmp" cmpc="$hrn1"
  [ "$cmp" = "cps1" ] && cmpn="$cmp" cmpc="$cps1"
  [ "$cmp" = "cps" ]  && cmpn="$cmp" cmpc="$cps1"
  [ "$cmp" = "par2" ] && cmpn="$cmp" cmpc="$par2"
  [ "$cmp" = "parc" ] && cmpn="$cmp" cmpc="$parc"
  [ "$cmp" = "para" ] && cmpn="$cmp" cmpc="$para"
  [ "$cmp" = "par9" ] && cmpn="$cmp" cmpc="$par9"
  [ "$cmp" = "par8" ] && cmpn="$cmp" cmpc="$par8"
  local vn='' vc=''
  $verb2 "cmpn='$cmpn'"
  $verb2 "cmpc='$cmpc'"
  $verb2 "input='$inpath/$infile'"
  mkdir -p "${inpath}/tmp" "./loss"
  null="$(mktemp "${inpath}/tmp/nulltime-XXXXX")"
  null="${null##*/}" # basename
  [ "$cmpn" ] && vn="-$cmpn" vc="$cmpc" || true # sox compand is basically a volume adjustment...
# [ "$cmpn" -a -z "$v" ] && local v=0db || true # set an unset volume (v) param, if we have compand w/o volume
  [ "$v" ] && { vn="${vn}-v${v}" vc="${vc} vol ${v} dither" ;} || true # set vol name (vn) and vol command (vc) if needed
  [ "$rev" = "y" ] && vn="${vn}-rev" vc="$vc reverse"
  local secc='' secn='' ssec='' tsec=''
  # always set duration
  [ "$ss" = 0 ] && local ss= || { ssec=$(hms2sec ${ss}) ;}
  [ "$to" ] || local to="$(ffprobe -hide_banner -loglevel info "$infilep" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')"
  [ "$to" ] && { tsec=$(hms2sec ${to}) ;}
  [ -z "$ss" -a "$to" ] && secc="-to $tsec"           secn="-to$tsec"
  [    "$ss" -a "$to" ] && secc="-ss $ssec -to $tsec" secn="-ss${ssec}-to${tsec}"
  $verb "${inpath}/tmp/${infile}${secn}.meas"
  [ -f "${inpath}/tmp/${infile}${secn}.meas" ] || { # measure
    # XXX check ss -lt to etc
    # echo ffmpeg -hide_banner -loglevel info -benchmark -y $secc -i "$infilep" \
    { echo             "# ${infile}${secn}.meas infile secn meas flac"
      ffmpeg -hide_banner -loglevel info -benchmark -y $secc -i "$infilep" \
        -af "loudnorm=print_format=json" \
        -f flac "${inpath}/tmp/${infile}${secn}.flac~" 2>&1 \
            | awk '/^{/,0' | jq --compact-output '
                                 {measured_I:.input_i,measured_TP:.input_tp,measured_LRA:.input_lra,measured_thresh:.input_thresh},
                                 {out_i_LUFS:.output_i,out_tp_dBTP:.output_tp,out_lra_LU:.output_lra,out_tr_LUFS:.output_thresh,offset_LU:.target_offset},
                                 {linear:.linear}
                                ' | tr -d '"{}' | tr ':' '=' | awk -F, '{printf "% 18s % 18s % 18s % 22s % 15s \n",$1,$2,$3,$4,$5}'
     } >"${inpath}/tmp/${infile}${secn}.meas~"
    mv -f "${inpath}/tmp/${infile}${secn}.flac~" "${inpath}/tmp/${infile}${secn}.flac"
    mv "${inpath}/tmp/${infile}${secn}.meas~" "${inpath}/tmp/${infile}${secn}.meas"
    } # have trimmed measured flac
#     i   Set integrated loudness target.  Range is -70.0 - -5.0. Default value is -24.0.
#     lra Set loudness range target.  Range is 1.0 - 20.0. Default value is 7.0.
#     tp  Set maximum true peak.  Range is -9.0 - +0.0. Default value is -2.0.
  local lnn offn tpn lran in measured_thresh measured_LRA measured_TP measured_I
  [ "$off" ] && offn="-off$off"
  [ "$lra" ] && lran="-lra$lra"
  [ "$tp"  ] &&  tpn="-tp$tp"
  [ "$i"   ] &&   in="-i$i"
  $verb "$(hms2sec $(ffprobe -hide_banner  -loglevel info  "${inpath}/tmp/${infile}${secn}.flac" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //') )"
  [ "${offn}${lran}${tpn}${in}" ] && lnn="-ln${lran}${tpn}${in}${offn}" || lnn="-ln"
  $verb "${inpath}/tmp/${infile}${secn}${lnn}.flac"
  $verb "${inpath}/tmp/${infile}${secn}${lnn}.meas"
  [ -f "${inpath}/tmp/${infile}${secn}${lnn}.flac" ] || { # make loudnorm flac https://en.wikipedia.org/wiki/EBU_R_128
  # local off="${off:=0}" tp="${tp:=-2}"   lra="${lra:=7}" i="${i:=-24}" # assign unset parm to default values
  # local off="${off:=0}" tp="${tp:=-1}"   lra="${lra:=7}" i="${i:=-23}" # https://tech.ebu.ch/docs/r/r128.pdf revision 2020
    local off="${off:=0}" tp="${tp:=-0.5}" lra="${lra:=7}" i="${i:=-23}" # assign unset parm to local defaults
    local $(grep measured "${inpath}/tmp/${infile}${secn}.meas")
    { echo "# ${infile}${secn}${lnn}.flac infile ln flac"
      ffmpeg -hide_banner -loglevel info -benchmark -y $secc -i "$infilep" \
          -af "loudnorm=print_format=json:linear=true
                   :measured_I=${measured_I}:measured_TP=${measured_TP}
                   :measured_LRA=${measured_LRA}:measured_thresh=${measured_thresh}
                   :offset=${off}:i=${i}:tp=${tp}:lra=${lra}" \
          -f flac "${inpath}/tmp/${infile}${secn}${lnn}.flac~" 2>&1 \
            | awk '/^{/,0' | jq --compact-output '
                                   {measured_I:.input_i,measured_TP:.input_tp,measured_LRA:.input_lra,measured_thresh:.input_thresh},
                                   {out_i_LUFS:.output_i,out_tp_dBTP:.output_tp,out_lra_LU:.output_lra,out_tr_LUFS:.output_thresh,offset_LU:.target_offset},
                                   {linear:.linear}
                                  ' | tr -d '"{}' | tr ':' '=' | awk -F, '{printf "% 18s % 18s % 18s % 22s % 15s \n",$1,$2,$3,$4,$5}'
    } >"${inpath}/tmp/${infile}${secn}${lnn}.meas~"
    mv "${inpath}/tmp/${infile}${secn}${lnn}.flac~" "${inpath}/tmp/${infile}${secn}${lnn}.flac"
    mv "${inpath}/tmp/${infile}${secn}${lnn}.meas~" "${inpath}/tmp/${infile}${secn}${lnn}.meas"
    grep -E '(measured|out)' "${inpath}/tmp/${infile}${secn}${lnn}.meas" \
        | while IFS= read a ; do ${verb2} "$a" ; done
  } # make loudnorm flac
  ##### begin rb section ######################################
  local out="${infile}${secn}${lnn}"
  local Fc='' Fn=''
  local cfc='' cfn=''
  local cc='' cn=''
  [ "$c" ] && { expr "$c" : '^[0123456]$' >/dev/null || { chkerr "$FUNCNAME parm invalid : c=$c" ; return 1 ;} ;}
  [ "$c" ] && cc="--crisp $c" cn="-c${c}" || true
  expr "$t" : '^-' >/dev/null && { chkerr "$FUNCNAME parm invalid : t=$t" ; return 1 ;} || true
  expr "$p" : '^-[[:digit:]]*$' >/dev/null && p="${p}.0" || true # fixup negative intergers, least test fail... -bash: [: -3: unary operator expected
  expr "$f" : '^-[[:digit:]]*$' >/dev/null && f="${f}.0" || true # fixup negative intergers, least test fail
  [ "$t" -o "$p" -o "$f" ] && { # rb parm
    [ "$F" = "y" ]  &&  Fc='--formant'       Fn='-F'  || Fc=''   Fn=''
    [ "$cf" = "y" ] && cfc='--centre-focus' cfn='-cf' || cfc='' cfn=''
    local out="${infile}${secn}${tn}${pn}${fhzn}${cn}${Fn}${cfn}${lnn}"
      [ -e "${inpath}/tmp/${out}.wav" ] || { # master sans volume
        $verb "${inpath}/tmp/${out}.wav"
        $verb2 $rb -q $tc $pc $fhzc $cc $Fn $cfc "${inpath}/tmp/${infile}${secn}${lnn}.flac" "${inpath}/tmp/${out}.wav~"
             { $rb -q $tc $pc $fhzc $cc $Fn $cfc "${inpath}/tmp/${infile}${secn}${lnn}.flac" "${inpath}/tmp/${out}.wav~" 2>&1 \
                 | while IFS= read a ; do ${verb} "$a" ; done ;} || { chkerr \
               $rb -q $tc $pc $fhzc $cc $Fn $cfc "${inpath}/tmp/${infile}${secn}${lnn}.flac" "${inpath}/tmp/${out}.wav~" ; return 1 ;}
        mv "${inpath}/tmp/${out}.wav~" "${inpath}/tmp/${out}.wav"
        } # final master, sans sox volume
      # apply volume and make an mp3 --- hopefully the input is not clipped already!
      $verb "$(hms2sec $(ffprobe -hide_banner  -loglevel info  "${inpath}/tmp/${out}.wav" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //') )"
      $verb "${inpath}/tmp/${out}${vn}.mp3"
                    # not seeing sox format specifier for ".mp3~" type files...
      $verb2         sox "${inpath}/tmp/${out}.wav" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc
                 {   sox "${inpath}/tmp/${out}.wav" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc 2>&1 \
                 | while IFS= read a ; do ${verb} "$a" ; done ;} || { chkerr \
                    "sox '${inpath}/tmp/${out}.wav' '${inpath}/tmp/${out}${vn}.tmp.mp3' $vc" ; return 1 ;}
      mv "${inpath}/tmp/${out}${vn}.tmp.mp3" "${inpath}/tmp/${out}${vn}.mp3"
    } || { # no rb input parms (only time, volume or neither)
        $verb "$(hms2sec $(ffprobe -hide_banner  -loglevel info  "${inpath}/tmp/${out}.wav" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //') )"
        $verb "${inpath}/tmp/${out}${vn}.mp3"
        $verb2         sox "${inpath}/tmp/${out}.flac" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc
                 {     sox "${inpath}/tmp/${out}.flac" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc 2>&1 \
                 | while IFS= read a ; do ${verb} "$a" ; done ;} || { chkerr \
                      "sox '${inpath}/tmp/${out}.flac' '${inpath}/tmp/${out}${vn}.tmp.mp3' $vc" ; return 1 ;}
        mv "${inpath}/tmp/${out}${vn}.tmp.mp3" "${inpath}/tmp/${out}${vn}.mp3"
         }
   find "${inpath}" ./loss -type f -newer "${inpath}/tmp/$null" \
       -regex ".*${infile}.*\.ln\.meas" -o \
       -name "\*${out}${vn}.mp3" \
        | xargs ls -rth
    # prepend output filename
    $verb "./loss/${prependt}${out}${vn}.mp3"
             prependf "${inpath}/tmp/${out}${vn}.mp3" "$prependt" \
                 && mv -f "${inpath}/tmp/${prependt}${out}${vn}.mp3" "./loss/" \
                 && rm -f "${inpath}/tmp/$null" \
    && echo "./loss/${prependt}${out}${vn}.mp3"
# extract audio from video
# for a in *Caprices_For_FLUTE*webm ; do ext=$(ffprobe -hide_banner  -loglevel info $a 2>&1 | sed -e '/Audio/!d' -e 's/.*Audio: //' -e 's/,.*//'); name=$(sed "s/[^.]*$/$ext/" <<<$a) ; ffmpeg -i $a -q:a 0 -map a -acodec copy $name ; done

# convert 5.1 channels to 2
# https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg
#ffmpeg -i Mozart-K622-Clarinet-Concerto-A-Maj-Kam-Honeck-2006.m4a \
#  -af "pan=stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR" \
# cf Mozart-K622-Clarinet-Concerto-A-Maj-Kam-Honeck-2006.m4a.flac
# cf chet baker /Users/geo/dot4/5/d/3/a/4/a/^/parm_sox.sh
    # -ss 32:05 -to 39:58.5
    ) # f2rb2mp3

formfile () { # create a f2rb2mp3 command to render the file, given the input filename
  # filter ^.*
  #   file type      ext="$(echo "^${a##*^}" | sed -e 's/[^.]*.//' \
  #                                                -e 's/-.*//' )"
  #   id "^hash"    hash="$(echo "^${a##*^}" | sed "s/\.${ext}.*//" )"
  #   transform     args="$(echo "^${a##*^}" | sed -e "s/.*\.${ext}//" \
  #                                                -e "s/.mp3$//" \
  #                                                -e 's/-\([[:alpha:]]*\)/ \1=/g' \
  #                                                -e 's/= /=y /g' \
  #                                                -e 's/^/ verb=chkwrn/' )"
  # filter .*^
  #   filter maskfix      mfix="$(echo "${a%%^*}" | sed 's/-.*//' )"
  #   filter identity identity="$(echo "${a%%^*}" | sed -e 's/[^-]*-//' -e 's/-.*//' )"
  #   filter subjecti      sub="$(echo "${a%%^*}" | sed "s/.*${idnetity}-//" )"
  #
# use case:
#
# for a given rendered file
#     001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
#
# decompose into rendering command line for parameters
#     formfile 001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
#
# # 001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
# ln /Users/geo/dot4/5/a/8/d/b/^/5f8b-muser/001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3 /Users/geo/dot4/5/a/8/d/b/57a_1d24af8c_/_master
# verb=chkwrn t=0.87 p=1 c=3 F=y ss=4795 to=5790 v=1db f2rb2mp3 /Users/geo/dot4/5/a/8/d/b/57a_1d24af8c_/_master/Jean-Marie_Leclair_Complete_Flute_Sonatas_^fJwnsyEtkK0.opus 001
#
    local a f fs;
    [ "$1" ] && fs="$1" || fs="$(cat)";
    shift;
    [ "$1" ] && $FUNCNAME $@;
    [ "$fs" = "-h" -o "$fs" = "--help" ] \
      && {
        chkwrn "Usage, for args (or per line stdin) decompose"
        chkwrn "each filename into a rendering command."
    } || { # process the filelist $fs
      echo "$fs" | while IFS= read a ; do
        a="${a##*/}" # basename
        local ext="$(sed -e 's/_^[^.]*.//' -e 's/-.*//' <<<"_^${a##*_^}")" # expect ^ to proceed hash, followed by a dot mime, plus parm (.ext[-parm]*)
        local hash="$(sed "s/\.${ext}.*//" <<<"${a##*_^}")"      # hash from between "^ .ext"
        # decode f2rb2mp3 arguments
        local args="$(sed -E -e "
            s/.*\.${ext}//
            s/.mp3$//
            s/-(ckb|hrn|cps|par)/ cmp=\1/
            s/-(bhz|chz)/ f=\1/
            s/-rev/ rev=y/
            s/-ss/ ss=/
            s/-to/ to=/
            s/-t/ t=/
            s/-p/ p=/
            s/-f/ f=/
            s/-F/ F=y/
            s/-cf/ cf=y/
            s/-c/ c=/
            s/-v/ v=/
            s/-ln//
            s/-off/ off=/
            s/-tp/ tp=/
            s/-lra/ lra=/
            s/-i/ i=/
            " <<<"_^${a##*_^}")"
    #   local   seq="$(echo "${a%%^*}"  | sed -e 's/[^-]*-.*//')"
        local title="${a%%_^*}"
    #   local  dirs=$(find "$link/@" "$links/@" "@" -maxdepth 0 -type d 2>/dev/null)
        local path ; expr "$a" : ".*/" >/dev/null && path="${a%/*}" || path="." # dirname $a
        local files="$(find $(find "$path" . .. -name \@) -maxdepth 1 -type f -name \*${hash}\* 2>/dev/null )"
        local orig=
        [ "$files" ] && orig="$(awk 'NR==1' <<<"${files}")"
        [ "$orig" ] || orig="'_^${hash}.${ext}'"
        # ss= to= t= p= f= c= F= CF= off= tp= lra= i= cmp= v=
        expr "$args" : ".* v="    >/dev/null && true || args="$args v=$v"
        expr "$args" : ".* cmp="  >/dev/null && true || args="$args cmp=$cmp"
        expr "$args" : ".* F="    >/dev/null && true || args="$args F=$F"
        expr "$args" : ".* c="    >/dev/null && true || args="$args c=$c"
        expr "$args" : ".* f="    >/dev/null && true || args="$args f=$f"
        expr "$args" : ".* p="    >/dev/null && true || args="$args p=$p"
        expr "$args" : ".* t="    >/dev/null && true || args="$args t=$t"
        expr "$args" : ".* to="   >/dev/null && true || args="$args to=$to"
        expr "$args" : ".* ss="   >/dev/null && true || { [ "$ss" ] && args="$args ss=$ss" || args="$args ss=0" ;}
        args="$(tr ' ' '\n' <<<"$args")"
        local sortargs=
        for a in ss= to= t= p= f= c= F= CF= off= tp= lra= i= cmp= v= ; do
            sortargs="$sortargs $(grep "^$a" <<<"$args")"
            done
        # sortargs="$args $(grep -Ev '(^ss=|^to=|^t=|^p=|^f=|^c=|^F=|^CF=|^off=|^tp=|^lra=|^i=|^cmp=|^v=)' <<<"$sortargs")"
        args=$(sed -e 's/^[ ]*//' -e 's/[ ]*/ /' -e 's/[ ]*$//' <<<$sortargs)
        echo $args f2rb2mp3 $orig $title
        done
    } # { # process the filelist $fs
# export _f=0,artist_^30Ug3e46sss.info.json ; jq --compact-output 'del(.formats)' $_f | yq -P  >${_f}.txt
# :e! ++enc=utf8
} # formfile () { # create a f2rb2mp3 command to render the file, given the input filename

formfilestats () { # accept dir(s) as args, report formfile time and pitch stats from @ dir/*mp3
  local dir a b
  for dir in $@ ; do
    [ -d "$dir" ] && {
      for b in "$dir"/*mp3 ; do
        a="${b##*/}"
        ext="$( sed -e 's/[^.]*.//' -e 's/-.*//' <<<"^${a##*^}" )"
        sed -E -e "
            # start with block from formfile
            s/.*\.${ext}//
            s/.mp3$//
            s/-ss/ ss=/
            s/-to/ to=/
            s/-rev/ rev=y/
            s/-v/ v=/
            s/-ln//
            s/-lra/ lra=/
            s/-off/ off=/
            s/-i/ i=/
            s/-t/ t=/
            s/-p/ p=/
            s/-(bhz|chz)/ f=\1/
            s/-(kbd|hrn|cps)/ cmp=\1/
            s/-f/ f=/
            s/-cf/ cf=y/
            s/-c/ c=/
            s/-F/ F=y/
            # squash to tempo and pitch parameters
          # s/[ ](ss|to|cmp|F|v|c|rev)=[^ ]*//g
            s/[ ](ss|to|cmp|v|rev)=[^ ]*//g
            /^$/d
            # fixup odd case
            s/^ p/ t=1 p/
            / t=1 p=0$/d
          " <<<"^${a##*^}" \
          | awk '{printf "%- 11s %- 11s %s %s %s\n",$1,$2,$3,$4,$5}'
        done # b in "$dir"/*mp3
        } || true # $dir
       done | sort -n -t '=' -k 2 | uniq -c # sort result and count uniq
  } #


# export c=100 ; rm -rf png/* ; for a in *Couperin-kbd*mp3 ; do b=$(sed -e 's/.*,//' <<<$a) ; echo $b ; done | sort | while read b ; do a=$(ls *$b) ; c=$(( ++c )) ; sox $a -n remix - trim 0 =3 -3 spectrogram -o png/${c},${a}.png ; echo -n .  ; done

 # # verb=chkwrn p=4 c=1 ss=434 to=471.2 cmp=cps1 v=9db f2rb2mp3 @/_^NPk-cE047PU.opus 52r,Couperin-kbd_01-Gmaj-Etcheverry-07_Menuet
 # formfilespec () { # generate spectrograph for ss-1 to ss+3 and to-3 to to+1
 #    #local p="${1%/*}" f="${1##*/}"
 #     local in="$1"
 #     mkdir -p "./png"
 #     set $( formfile "${in##*/}" | sed -e 's/.*f2rb2mp3//' )
 #     local orig=$1 pass=$2
 #     [ -e "$orig" ] || { chkwrn "$orig not found" ; return 1 ;}
 #     echo -n "sox $orig -n remix - trim "
 #     set $(formfile "${in##*/}" | sed -e 's/f2rb2mp3.*//' )
 #     #dc -e "$ss 1-p $ss 3+p $to 3-p $to 1+p" | tr '\n' ' ' | sed -e 's/^/=/' -e 's/ / =/g' -e  's/=$//'
 #     dc -e "$ss 1-p $ss 3+p $to 3-p $to 1+p" | sed -e 's/^/=/' | tr '\n' ' '
 #    #b=$(sed -e 's/,.*//' <<<$in)
 #     echo "spectrogram -o ./png/${in##*/}.png"
 #     }

masterlink () {
verb2=chkwrn
  [ "$1" ] && local hash="$1" || { chkerr "$FUNCNAME : no hash" ; return 1 ;}
  [ "$2" ] || local dir="$links/_ln" && local dir="$2"
  dot4find "$hash" \
    | grep -vE '(.vtt$|.json$)' | ckstat | sort -k4 | head -n1 \
    | awk -v m="$dir/$hash" '{print "ln",$5,m}'
 }



# The lack tone functions generate a drone intended to add asthetic to a noisy environment.
# Execute one of the following (increasoing complexity) in a new shell. Use ctrl-c repeatedly to stop.
#    lacks1tone
#    lacks2tone
#    lacks5tone
#    lacks15tones
#    lacks125tones
#    lacks155tones
#    lacks1255tones
# The default -45db level can be adjusted with arg1, eg "lacks2tone -30"
# is 10db louder, BE CAREFUL DO NOT FORGET the "-" when specifying db.
lacktone () { # monitor lacktone logfile
   local tail tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   case "$(uname)" in
     Darwin) tail='tail -F' ;;
     Linux)  tail='tail --follow=name' ;;
   esac
   touch "$tmp/lacktone"
   $tail "$tmp/lacktone"
 }
 lacktone1a () { # play background tone, optioal gain (arg1) default -45
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-45"
   while :; do
      play -q -n -c1 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3 01.35 gain $g
      play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.3 0.78  gain $g
      sleep 0.54
      printf "%s" "1a/$g " >>"$tmp/lacktone" &
      done
 }
 lacktone1b () { # play background tone, optioal gain (arg1) default -45
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-45"
   while :; do
      play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3 01.35 gain $g
      play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.3 0.78  gain $g
      sleep $(dc -e "3 k 1 $(($RANDOM %49 + 1)) / 0.50 + p")
      printf "%s" "1b/$g " >>"$tmp/lacktone" &
      done
  }
 lacktone2a () { # play background tone, optioal gain (arg1) default -45
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-45"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.06 "$1" * "$1" + p"}' | dc )"
   while :; do
     play -q -n -c1 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.52 01.35 gain $g
     play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.52 0.78  gain $gb
      sleep 0.54
      printf "%s" "2a/$g " >>"$tmp/lacktone" &
      done
 }
 lacktone2b () { # play background tone, optioal gain (arg1) default -45
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-45"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.06 "$1" * "$1" + p"}' | dc )"
   while :; do
     play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.52 01.35 gain $g
     play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.52 0.78  gain $gb
      sleep $(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 0.50 + p")
      printf "%s" "2b/$g " >>"$tmp/lacktone" &
      done
  }
 lacktone5a () { # play background tone, optioal gain (arg1) default -45
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-45"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.03 "$1" * "$1" + p"}' | dc )"
   while :; do
      play -q -n -c1 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.27 01.35 gain $gb
      play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.33 0.78  gain $g
      sleep 0.54
      printf "%s" "5a/$g " >>"$tmp/lacktone" &
      done
 }
 lacktone5b () { # play background tone, optioal gain (arg1) default -45
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-45"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.22 "$1" * "$1" + p"}' | dc )"
   while :; do
      play -q -n -c2 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.33 01.35 gain $g
      play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.27 0.78  gain $gb
      sleep $(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 0.52 + p")
      printf "%s" "5b/$g " >>"$tmp/lacktone" &
      done
  }
lacks1tone () {
    [ "$1" ] && g="$1" || g="-45"
    lacktone1a $g & lacktone1b $g &
    lacktone
    fg;fg
    }
lacks2tone () {
    [ "$1" ] && g="$1" || g="-45"
    lacktone2a $g & lacktone2b $g &
    lacktone
    fg;fg
    }
lacks5tone () {
    [ "$1" ] && g="$1" || g="-45"
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg
    }
lacks15tones () {
    [ "$1" ] && g="$1" || g="-45"
    lacktone1a $g & lacktone1b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg
    }
lacks125tones () {
    [ "$1" ] && g="$1" || g="-45"
    lacktone1a $g & lacktone1b $g &
    lacktone2a $g & lacktone2b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg
    }
lacks155tones () {
    [ "$1" ] && g="$1" || g="-45"
    lacktone1a $g & lacktone1b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg
    }
lacks1255tones () {
    [ "$1" ] && g="$1" || g="-45"
    lacktone1a $g & lacktone1b $g &
    lacktone2a $g & lacktone2b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg ; fg;fg
    }

  # {
  #   xargs -P 3 -I {} sh -c 'eval "$1"' - {} <<'EOF'
  # sleep 1; echo 1
  # sleep 2; echo 2
  # sleep 3; echo 3
  # echo 4
  # EOF
  # } &
  #
  # # Script execution continues here while `xargs` is running
  # # in the background.
  # echo "Waiting for commands to finish..."
  #
  # # Wait for `xargs` to finish, via special variable $!, which contains
  # # the PID of the most recently started background process.
  # wait $!

# 07/10/21
numlist () { #:> re-sequence (in base32) a list of files, retaining the "major" (first) character
    # so that when combined with another list, the result is interlaced with major sequence retained.
    # Depends: base (python script) converts dec to base 32 (alnum lower sans 'ilow');
    # Plan:
    # Accept args OR stdin (one file per line), only act on regular files, squash any leading "./";
    # Expect filenames to start with sequence characters (three base 32 chars, followed by ",");
    # Retain the major sequence character, regenerate base 32 sequence, in a step of 3;
    # Bump up the sequence major value by "$numlistbump" if set (interger);
    # Prepend output filenames with the "$numlist" string;
    # Initilize base 32 sequence with 0 major for input files that have no sequence;
    # For name changes, without colisions, generate mv commands for evaluation or "| sh".
    local f fs p b a src dst;
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    fs="$(sed 's/^\.\///' <<<"$fs" | while IFS= read f ; do [ -f "${f%%/*}" ] && echo "${f%%/*}" || true ; done)"
    for p in 0 1 2 3 4 5 6 7 8 9 a b c d e f g h j k m n p q r s t u v x y z ; do # iterate on each major base 32
        b="$p"
        [ "$numlistbump" -gt 0 ] 2>/dev/null \
          && { for a in $(seq 1 $numlistbump ) ; do # bump the major sequence by $numlistbump if set
               b="$(tr '0123456789abcdefghjkmnpqrstuvxyz' '123456789abcdefghjkmnpqrstuvxyz0' <<<$b)"
               done
             } || true
        { grep "^$p[0123456789abcdefghjkmnpqrstuvxyz]*," <<<"$fs" || true ;} \
            | while IFS= read f ; do printf "%s\n" "$f" ; done \
            | awk '{printf "%s %d %s\n",$0,NR,$0}' \
            | sed -e '/^ /d' -e 's/^[0123456789abcdefghjkmnpqrstuvxyz]*,//' \
            | while IFS= read a ; do set $a
                printf "%s %s%s%02s,%s\n" "$3" "$numlist" "$b" "$(base 32 $2)" "$1"
                done \
            | while IFS= read a ; do set $a # {orig} {numlist}{p}{seq},{name}
                src="$1"
                grep -q "^[0123456789abcdefghjkmnpqrstuvxyz]*," <<<"$src" && dst="$2" || dst="0,$2"
                [ "$src" = "$dst" ] || [ -e "$dst" ] || echo "mv \"$src\" \"$dst\""
                done
        done # p
    # and give all files that had no sequence a "0" major (no bump) and sequence
    { grep -v "^[0123456789abcdefghjkmnpqrstuvxyz]*," <<<"$fs" || true ;} \
    | while IFS= read f; do printf "%s\n" "$f" ; done \
        | awk '{printf "%s %d %s\n",$0,NR,$0}' \
        | sed -e '/^ /d' \
        | while IFS= read a ; do set $a
            printf "%s %s%s%02s,%s\n" "$3" "$numlist" "0" "$(base 32 $2)" "$1"
            done \
        | while IFS= read a ; do set $a # {orig} {numlist}0{seq},{name}
            dst="$2";
            [ "$1" = "$dst" ] || [ -e "$dst" ] && chkwrn "$FUNCNAME collision : $dst" || echo "mv \"$1\" \"$dst\"";
            done
    } # numlist

# 07/26/21
numlistdst () { # distribute filenames across base 32 major (alnum lower sans 'ilow')
    # in the future accept distribution major range (start/stop for the distribution)
    local f fs fss
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    fs="$(sed 's/^\.\///' <<<"$fs" | while IFS= read f ; do [ -f "${f%%/*}" ] && echo "${f%%/*}" || true ; done)"
    m=$(dc -e "8 k 31 $(awk 'END{print NR}' <<<"$fs") / p") # 0-31 * NR, for major, does not overflow major
    awk '{printf "%s %s\n",$0,NR}' <<<"$fs" \
        | while IFS= read a ; do set $a
            b=$(sed 's/^[0123456789abcdefghjkmnpqrstuvxyz]*,//' <<<"$1") # remove any sequence from the destination base
            # then make sequence in base 32, with distributed major
            printf "%s %s%02s,%s\n" "$1" "$(base 32 $(dc -e "$2 $m * p" | awk '{printf "%.0f\n",$1}') )" "$(base 32 $2)" "$b"
            done \
        | while IFS= read a ; do set $a # {orig} {dist-major}{seq},{name}
            local src="$1" dst="$2"
            [ "$src" = "$dst" ] || [ -e "$dst" ] && chkwrn "$FUNCNAME collision : $dst" || echo "mv \"$src\" \"$dst\"";
            done
    } # numlistdst

mp3range () { # mp3 listing limiter
    # of regex arg1 start pass through,
    # to regex arg2 stop (or null) end
    # from within each remaining args
    # or current dir if no remaining args.
    local start="$1" stop="$2" dirs= a=
    #local verb="chkwrn"
    #$verb for expr "${stop}" : "${start}"
    [ "$stop" ] && { expr "${stop}" : "${start}" >/dev/null \
            && chkwrn "$FUNCNAME : unintended consequences : $start $stop"
        stop="/^${stop}/" ;} \
        || stop="0"
    start="/^${start}/"
    #chkwrn for awk \"${start},${stop}\"
    shift 2 || shift || true # shift 2 fails if $# = 1, so "shift 2 without err signal" in all cases...
    #chkwrn "#$# @=$@"
    [ $# -gt 0 ] && dirs="$1" ; shift
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do dirs="$(printf "%s\n%s\n" "$dirs" "$1")" ; shift ; done
    [ "$dirs" ] || dirs="./"
    #$verb pwd=$PWD dirs=$dirs
    #echo "$dirs"     | sed '/^$/d' | while IFS= read a; do ${verb} "ead $a" ; done
    echo "$dirs" | sed '/^$/d' | while IFS= read a; do
        ( [ -d "$a" ] && {
            cd "$a"
            ls *.mp3 | awk ${start},${stop} | sed "s=^=$PWD/="
            } || chkwrn "not a dir with mp3 files : '$a'" ) # subshell to preserve $OLDPWD after cd
        done
    } # mp3range 20220516

playffr () { # use ffplayr to continiously repeat invocations of ffplay
    local fs
    [ $# -gt 0 ] && fs="$1" ; shift
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    while :; do playff <<<"$fs" || return 1 ; done
   #while :; do echo "$fs" | playff || return 1 ; done
    }

playff () { # use ffplay to play files (args OR stdin filename per line)
    local f fs
    [ $# -gt 0 ] && fs="$1" ; shift
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    echo "$fs" | while IFS= read f; do
        chkwrn "$f"
        [ -f "$f" ] && {
        hms2sec $(ffprobe -hide_banner  -loglevel info  "$f" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')
        ffplay -hide_banner -stats -autoexit -loglevel info -top 52 -x 1088 -y 280 "$f" || return 1
        } || chkwrn "$0 : not a file : '$f'"
        done
    } # playff

probeff () { # use ffprobe to extract duration of files (args OR stdin filename per line)
    local f fs
    [ $# -gt 0 ] && fs="$1" ; shift
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    echo "$fs" | while IFS= read f; do
        local inpath infile="${f##*/}" # basename
        expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # input dirname
        local infilep="$(cd "${inpath}" ; pwd -P)/${infile}" # full filepath
        [ -f "$infilep" ] && {
            d="$(ffprobe -hide_banner -loglevel info "$infilep" 2>&1 | sed -e '/Duration: N\/A, /d' -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')"
            [ "$d" ] && echo "$d $infilep" || true
        }
        done
    }