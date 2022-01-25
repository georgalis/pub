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
siff 651922db 000000d6
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
#h="$(cd $(dirname $0) && pwd -P)" # realpath of this script
#b="$(basename $0 | sed 's/.[^.]*$//')" # this program name less (.sh) extension
#t="$( { date '+%Y%m%d_%H%M%S_' && uuidgen ;} | sed -e 's/-.*//' | tr -d ' \n' )" # time based uniq id
# find . \( -path ./skel -o -path ./mkinst \) \! -prune -o -type f
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


_youtube_video_list () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --yes-playlist \
 --audio-quality 0 --audio-format best --extract-audio --playlist-start 1 \
 -o "$d/%(title)s_^%(id)s.%(ext)s" $id
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --yes-playlist \
 --audio-quality 0 --audio-format best --playlist-start 1 \
 -o "$d/0%(playlist_index)s,-%(title)s_^%(id)s.%(ext)s" $id
} # _youtube_video_list

_youtube_video () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --no-playlist \
 --audio-quality 0 --audio-format best --extract-audio \
 -o "$d/%(title)s_^%(id)s.%(ext)s" $id
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --no-playlist \
 --audio-quality 0 --audio-format best \
 -o "$d/0,%(title)s_^%(id)s.%(ext)s" $id
} # _youtube_video

_youtube () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --no-playlist \
 --audio-quality 0 --audio-format best --extract-audio \
 -o "$d/0,%(title)s_^%(id)s.%(ext)s" $id
} # _youtube

_youtube_list () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --yes-playlist \
 --audio-quality 0 --audio-format best --extract-audio --playlist-start 1 \
 -o "$d/0%(playlist_index)s,-%(title)s_^%(id)s.%(ext)s" $id
} # _youtube_list

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
  }
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
    echo "# crisp:  0=mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive "
    echo "# Formant y/''  CenterFocus y/'' cmp (ckb|hrn|cps)(1..)/y/'' vol 0db/''"
    echo "# frequency (bhz|chz|N)/'' reverse y/''"
    echo "# verb=chkwrn t='1' p='0' f= c= F= CF= ss= to= cmp= v= f2rb2mp3 {file-in} {prepend-out}"
    echo "# ln=-33+-3+6 {i+tp+lra}"
    return 0
    # loudnorm: see $link/lufs/normff.fn.bash
     # -y -i "$1" -af "loudnorm=print_format=json,loudnorm=i=-33,loudnorm=tp=-3,loudnorm=lra=6" -f flac "${1}.1.flac" 2>&1 \
    [ -e "./tmp/${infile}.measure" ] || { ffmpeg -hide_banner -loglevel info -benchmark \
      -y -i "$1" -af "loudnorm=print_format=json" -f null "/dev/null" 2>&1 \
        | awk '/^{/,0' \
        | jq --compact-output '{in__i:.input_i,in__tr:.input_thresh,in__lra:.input_lra,in__tp:.input_tp},{out_i:.output_i,out_tr:.output_thresh,out_lra:.output_lra,out_tp:.output_tp}' \
        | column -t -s,
      } # ./tmp/${infile}.measure
    } # help
  [ "$1" ] || { f2rb2mp3 help ; return 1 ;}
  [ "$verb" ]  || local verb="devnul"
  [ "$verb2" ] || local verb2="devnul"
  [ "$verb3" ] || local verb3="devnul"
  local infile="$(basename "$1")"
  local indir="$(dirname "$1")"
  local prependt="$2"
  [ "$t" -o "$p" ] && { [ "$c" ] || local c=5 ;} || true # "Crispness"
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
  #
  local tc='' tn=''
  [ "$t" ] && tc="--time $t"  tn="-t${t}" || true
  local pc='' pn=''
  [ "$p" ] && pc="--pitch $p" pn="-p${p}" || true
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
  [ "$cmp" = "ckb" ]  && cmpn="$cmp" cmpc="$ckb0"
  [ "$cmp" = "hrn" ]  && cmpn="$cmp" cmpc="$hrn1"
  [ "$cmp" = "hrn2" ] && cmpn="$cmp" cmpc="$hrn2"
  [ "$cmp" = "hrn3" ] && cmpn="$cmp" cmpc="$hrn3"
  [ "$cmp" = "ckb2" ] && cmpn="$cmp" cmpc="$ckb2"
  [ "$cmp" = "ckb3" ] && cmpn="$cmp" cmpc="$ckb3"
  [ "$cmp" = "hrn1" ] && cmpn="$cmp" cmpc="$hrn1"
  [ "$cmp" = "cps1" ] && cmpn="$cmp" cmpc="$cps1"
  local vn='' vc=''
  local out=''
  $verb2 "cmpn='$cmpn'"
  $verb2 "cmpc='$cmpc'"
  $verb2 "input='$indir/$infile'"
  [ -f "$indir/$infile" ] || { f2rb2mp3 help ; chkerr "no input flle $infile" ; return 1 ;}
  cd "$indir"
  mkdir -p ./tmp ./loss
  null=$(mktemp ./tmp/nulltime-XXXXX)
      $verb "./tmp/${infile}.flac"
      $verb2 "...next refactor move sox trim to this ffmpeg step"
  [ -e "./tmp/${infile}.flac" ] || { # make ready the flac for universal read
      $verb2    ffmpeg -hide_banner -loglevel warning -i "$infile" "./tmp/${infile}.flac"
                ffmpeg -hide_banner -loglevel warning -i "$infile" "./tmp/${infile}.flac" \
                  || { chkwrn " flack fail ";}
                } # have flack # -loglevel fatal
  [ "$cmpn" ] && vn="-$cmpn" vc="$cmpc" || true # sox compand is basically a volume adjustment...
  [ "$cmpn" -a -z "$v" ] && local v=0db || true # set an unset volume (v) param, if we have compand w/o volume
  [ "$v" ] && { vn="${vn}-v${v}" vc="$vc vol ${v} dither" ;} || true # set vol name (vn) and vol command (vc) if needed
  [ "$rev" = "y" ] && vn="${vn}-rev" vc="$vc reverse"
  local secc='' secn='' ssec='' tsec=''
  # if unset, set end to duration of longest stream
  [ "$to" ] || local to="$(ffprobe -hide_banner  -loglevel info "$infile" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')"
  [ "$ss" -o "$to" ] && { # trim times
    [   "$ss" ] && { ssec=$(hms2sec ${ss}) ;}
    [   "$to" ] && { tsec=$(hms2sec ${to}) ;}
    [ -z "$ss" -a "$to"    ] && secc="trim 0 =$tsec"     secn="-to$tsec"
    [    "$ss" -a "$to"    ] && secc="trim $ssec =$tsec" secn="-ss${ssec}-to${tsec}"
#   [    "$ss" -a -z "$to" ] && secc="trim $ssec" secn="-ss${ssec}" # when ffprobe fails to detect
    [ -e "./tmp/${infile}${secn}.flac" ] || { # make trimmed flack
      $verb                             "./tmp/${infile}${secn}.flac"
      $verb2 sox "./tmp/${infile}.flac" "./tmp/${infile}${secn}.flac" $secc
             sox "./tmp/${infile}.flac" "./tmp/${infile}${secn}.flac" $secc || { chkerr \
       "trim: sox ./tmp/${infile}.flac ./tmp/${infile}${secn}.flac $secc" ; return 1 ;}
      } # made trimmed
    } # have trimmed flac
  out="${infile}${secn}"
  ##### begin rb section ######################################
  local Fc='' Fn=''
  local cfc='' cfn=''
  local cc='' cn=''
  [ "$c" ] && { expr "$c" : '^[012345]$' >/dev/null || { chkerr "$FUNCNAME parm invalid : c=$c" ; return 1 ;} ;}
  [ "$c" ] && cc="--crisp $c" cn="-c${c}" || true
  expr "$t" : '^-' >/dev/null && { chkerr "$FUNCNAME parm invalid : t=$t" ; return 1 ;}
  expr "$p" : '^-[[:digit:]]*$' >/dev/null && p="${p}.0" # fixup negative intergers, least test fail... -bash: [: -3: unary operator expected
  expr "$f" : '^-[[:digit:]]*$' >/dev/null && f="${f}.0" # fixup negative intergers, least test fail
  [ "$t" -o "$p" -o "$f" ] && { # rb parm
    [ "$F" = "y" ]  &&  Fc='--formant'       Fn='-F'  || Fc=''   Fn=''
    [ "$cf" = "y" ] && cfc='--centre-focus' cfn='-cf' || cfc='' cfn=''
    out="${infile}${tn}${pn}${fhzn}${cn}${Fn}${cfn}${secn}"
    [ -e "./tmp/${out}.wav" ] || { # master sans volume
      $verb "./tmp/${out}.wav"
      $verb2 $rb -q $tc $pc $fhzc $cc $Fn $cfc "./tmp/${infile}${secn}.flac" "./tmp/${out}.wav"
             $rb -q $tc $pc $fhzc $cc $Fn $cfc "./tmp/${infile}${secn}.flac" "./tmp/${out}.wav" || { chkerr \
             $rb -q $tc $pc $fhzc $cc $Fn $cfc "./tmp/${infile}${secn}.flac" "./tmp/${out}.wav" ; return 1 ;}
      } # final master sans volume
    # apply volume and make an mp3 --- hopefully the input is not clipped already!
    $verb "./tmp/${out}${vn}.mp3"
    $verb2         sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc
                   sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc || { chkerr \
                  "sox ./tmp/${out}.wav ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
    } || { # no rb input parms (only time, volume or neither)
         $verb "./tmp/${out}${vn}.mp3"
         $verb2         sox "./tmp/${infile}${secn}.flac" "./tmp/${out}${vn}.mp3" $vc
                        sox "./tmp/${infile}${secn}.flac" "./tmp/${out}${vn}.mp3" $vc \
           || { chkerr "sox ./tmp/${infile}${secn}.flac ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
         }
    # prepend output filename
    $verb "./loss/${prependt}${out}${vn}.mp3"
             prependf "./tmp/${out}${vn}.mp3" "$prependt" \
                 && mv -f "./tmp/${prependt}${out}${vn}.mp3" "./loss/"
    find "$PWD" -type f -name \*"$infile"\* -newer "$null" | xargs ls -lrth
    rm -f "$null"
    cd "$OLDPWD"
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
        chkwrn "Usage, for arg1 (or per line stdin)"
        chkwrn "decompose into rendering command(s)"
    } || { # process the filelist $fs
      echo "$fs" | while IFS= read a ; do
        a="${a##*/}" # basename
        local ext="$(echo "^${a##*^}" | sed -e 's/[^.]*.//' -e 's/-.*//')" # expect ^ to proceed hash, followed by a dot mime, plus parm (.ext[-parm]*)
        local hash="$(echo "^${a##*^}" | sed "s/\.${ext}.*//")"      # hash from between "^ .ext"
        # convert encoded args
        # Crisp  0=Mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive
        # Formant y/''  CenterFocus y/'' cmp (ckb|hrn)(1..)/y/'' vol 0db/''
        # verb=chkwrn t='1' p='0' c='3' F='' cf='' ss='' to='' cmp='' v='' f2rb2mp3 {file-in} {prepend-out}
        local args="$(echo "^${a##*^}" | sed -E -e "s/.*\.${ext}//" -e "s/.mp3$//" \
          -e 's/^/ verb=chkwrn/' \
          -e 's/-ss/ ss=/' -e 's/-to/ to=/' -e 's/-rev/ rev=y/' -e 's/-v/ v=/' \
          -e "s/-t/ t=/" -e 's/-p/ p=/' -e 's/-(bhz|chz)/ f=\1/' \
          -e 's/-(kbd|hrn|cps)/ cmp=\1/' \
          -e 's/-f/ f=/' \
          -e 's/-cf/ cf=y/' -e 's/-c/ c=/' -e 's/-F/ F=y/' \
          )"
    #   local   seq="$(echo "${a%%^*}"  | sed -e 's/[^-]*-.*//')"
    #   local title="$(echo "${a%%_^*}" | sed -e "s/^${seq}-//")"
        local title="${a%%_^*}"
    #   local  dirs=$(find "$link/@" "$links/@" "@" -maxdepth 0 -type d 2>/dev/null)
    #   local files="$(find $(find $links -name \@) -maxdepth 1 -type f -name \*${hash}\* 2>/dev/null )"
        local files="$(find $(find . .. -name \@) -maxdepth 1 -type f -name \*${hash}\* 2>/dev/null )"
    #   local orig=''
        [ "$files" ] && orig="$(echo "${files}" | awk 'NR==1')"
        [ "$orig" ] || orig="'_^${hash}.${ext}'"
        # f2rb2mp3 help
        echo $args f2rb2mp3 $orig $title
        done
    } # { # process the filelist $fs
} # formfile () { # create a f2rb2mp3 command to render the file, given the input filename

formfilestats () { # accept dir(s) as args, report formfile time and pitch stats from @ dir/*mp3
  local dir a b
  for dir in $@ ; do
    [ -d "$dir" ] && {
      for b in "$dir"/*mp3 ; do
        a="${b##*/}"
        ext="$( sed -e 's/[^.]*.//' -e 's/-.*//' <<<"^${a##*^}" )"
        hash="$( sed "s/\.${ext}.*//" <<<"^${a##*^}" )"
        args="$(echo \
          | sed -E -e "
            # start with verbatim block from formfile
            s/.*\.${ext}//
            s/.mp3$//
            s/^/ verb=chkwrn/
            s/-ss/ ss=/
            s/-to/ to=/
            s/-rev/ rev=y/
            s/-v/ v=/
            s/-t/ t=/
            s/-p/ p=/
            s/-(bhz|chz)/ f=\1/
            s/-(kbd|hrn|cps)/ cmp=\1/
            s/-f/ f=/
            s/-cf/ cf=y/
            s/-c/ c=/
            s/-F/ F=y/
            # squash verbatim formfile to time, pitch parameters
            s/ verb=chkwrn//
            s/ ss=.*//
            s/ to=.*//
            s/ c=.*//
            s/ F=.*//
            s/ rev=y//
            s/ v=.*db//
            s/^ p/ t=1 p/
            / t=1 p=0$/d
            " <<<"^${a##*^}" )"
        echo "$args" | awk '{printf "%- 11s %- 11s %s %s %s\n",$1,$2,$3,$4,$5}'
        done # b in "$dir"/*mp3
        } || true # $dir
       done | sort -n -t '=' -k 2 | uniq -c # sort result and count uniq
  } #


# export c=100 ; rm -rf png/* ; for a in *Couperin-kbd*mp3 ; do b=$(sed -e 's/.*,//' <<<$a) ; echo $b ; done | sort | while read b ; do a=$(ls *$b) ; c=$(( ++c )) ; sox $a -n remix - trim 0 =3 -3 spectrogram -o png/${c},${a}.png ; echo -n .  ; done

# verb=chkwrn p=4 c=1 ss=434 to=471.2 cmp=cps1 v=9db f2rb2mp3 @/_^NPk-cE047PU.opus 52r,Couperin-kbd_01-Gmaj-Etcheverry-07_Menuet
formfilespec () { # generate spectrograph for ss-1 to ss+3 and to-3 to to+1
   #local p="${1%/*}" f="${1##*/}"
    local in="$1"
    mkdir -p "./png"
    set $( formfile "${in##*/}" | sed -e 's/.*f2rb2mp3//' )
    local orig=$1 pass=$2
    [ -e "$orig" ] || { chkwrn "$orig not found" ; return 1 ;}
    echo -n "sox $orig -n remix - trim "
    set $(formfile "${in##*/}" | sed -e 's/f2rb2mp3.*//' )
    #dc -e "$ss 1-p $ss 3+p $to 3-p $to 1+p" | tr '\n' ' ' | sed -e 's/^/=/' -e 's/ / =/g' -e  's/=$//'
    dc -e "$ss 1-p $ss 3+p $to 3-p $to 1+p" | sed -e 's/^/=/' | tr '\n' ' '
   #b=$(sed -e 's/,.*//' <<<$in)
    echo "spectrogram -o ./png/${in##*/}.png"
    }

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
    # Bump up the sequence major value by "$numlistb" if set (interger);
    # Prepend output filenames with the "$numlist" string;
    # Initilize base 32 sequence with 0 major for input files that have no sequence;
    # For name changes, without colisions, generate mv commands for evaluation or "| sh".
    local f fs p b a src dst;
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    fs="$(sed 's/^\.\///' <<<"$fs" | while IFS= read f ; do [ -f "${f%%/*}" ] && echo "${f%%/*}" || true ; done)"
    for p in 0 1 2 3 4 5 6 7 8 9 a b c d e f g h j k m n p q r s t u v x y z ; do # iterate on each major base 32
        b="$p"
        [ "$numlistb" -gt 0 ] 2>/dev/null \
          && { for a in $(seq 1 $numlistb ) ; do # bump the major sequence by $numlistb if set
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

playff () { # use ffplay to play files (args OR stdin filename per linebnb)
    local f fs p b a ;
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    echo "$fs" | while read f; do
        [ -f "$f" ] && {
        hms2sec $(ffprobe -hide_banner  -loglevel info  "$f" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')
        ffplay -hide_banner -stats -autoexit -loglevel info -top 64 -x 1088 -y 336 "$f" || return 1
        }
        done
    } # playff

