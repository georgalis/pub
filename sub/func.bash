#!/usr/env bash

# Sundry functions

# more test
# echo "$SHELL"
# echo "$BASH_VERSINFO"      "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"
# echo "${BASH_VERSINFO[3]}" "${BASH_VERSINFO[4]}" "${BASH_VERSINFO[5]}"

validfn () { #:> hash comparison to validate shell functions
    [ "$1" ] || {
      cat <<-EOF
#:: $FUNCNAME {function} ; returns {function-name} {hash}
#:: $FUNCNAME {function} {hash} ; return no error, if hash match
#:: the former is intended to provide data for the latter
#:: env cksum= to set the cksum program
EOF
    return 1 ;}
    [ "$1" = '#' ] && return 0 || true # comment
    [ "${SHELL##*/}" = "bash" ] || { echo "Not bash" >&2 ; return 1 ;}
    [ "$cksum" ] || local cksum=cksum # for bugs... use stronger for nefarious env
    [ -x "$(which $cksum)" ] || { echo "No cksum : $cksum" >&2 ; return 1 ;}
    local f="$1"
    shift
    local s="$*"
    local v="$( { echo "$f" ; declare -f "$f" | "$cksum" ;} | tr -s '\n' ' ' | sed 's/ $//' )"
    [ "$s" ] || { echo $v ; return 0 ;}
    [ "$f $s" = "$v" ] || {
echo ">>>---
$FUNCNAME error :
   in:'$f $s'
local:'$v'
<<<---" 1>&1 ; return 1 ;}
    } # validfn
#
# Now that validfn is defined, run the framework on functions expected from .profile
# (this is less "needed" than an example of syetem environment validation)
#
# eg generate hashses (to /dev/null)...
while read f; do validfn $f >/dev/null; done <<EOF
devnul
stderr
chkstd
chkwrn
chkerr
logwrn
logerr
source_iff
EOF
#
# run validfn
# (to check the generated hashes in new context)
[ "$verb" ] || verb=devnul
while IFS= read fndata ; do
$verb "validfn $fndata"
       validfn $fndata && true || { echo "validfn error : $fndata" 1>&2 ; return 1 ;}
done <<EOF
# pub/skel/.profile 20210628
devnul 2725980892 30
stderr 3041441698 35
chkstd 3997869157 50
chkwrn 2268919251 93
chkerr 1473511298 95
logwrn 3850395782 97
logerr 4292729202 98
source_iff 1251574593 100
EOF
# validfn run

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
youtube-dl --write-info-json --restrict-filenames --abort-on-error --yes-playlist \
    --audio-quality 0 --audio-format best \
    -o "$d/%(playlist_index)s-%(title)s_^%(id)s.%(ext)s" $id
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
    -o "$d/%(title)s_^%(id)s.%(ext)s" $id
} # _youtube_video

_youtube () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --no-playlist \
    --audio-quality 0 --audio-format best --extract-audio \
    -o "$d/%(title)s_^%(id)s.%(ext)s" $id
} # _youtube

_youtube_list () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --yes-playlist \
    --audio-quality 0 --audio-format best --extract-audio \
    -o "$d/%(playlist_index)s-%(title)s_^%(id)s.%(ext)s" $id
    #--yes-playlist --extract-audio -o "$d/%(playlist_index)s^%(id)s.%(ext)s" $id
} # k4_youtube

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
f2rb2mp3 () ( # file to rubberband to mp3, tuning function
  # subshell sets pipefail and ensures PWD on err
  set -e -o pipefail
  # validate env per
  # https://github.com/georgalis/pub/blob/master/skel/.profile
  # https://github.com/georgalis/pub/blob/master/sub/func.bash
  while IFS= read fndata ; do
    validfn $fndata || { echo "validfn error : $fndata" 1>&2 ; return 1 ;}
  done <<EOF
# pub/skel/.profile 20210628
devnul 2725980892 30
stderr 3041441698 35
chkwrn 2268919251 93
chkerr 1473511298 95
# pub/sub/func.bash 20210628
hms2sec 3886070923 470
prependf 2889475370 434
EOF
  [ -x "$(which "$rb")"  ] || { chkerr "$FUNCNAME : env rb not set to rubberband executable" ; return 1 ;}
  [ -x "$(which ffmpeg)" ] || { chkerr "$FUNCNAME : ffmpeg not in path" ; return 1 ;}
  [ -x "$(which sox)"    ] || { chkerr "$FUNCNAME : sox not in path" ; return 1 ;}
  # success valid env
  [ "$1" = "help" ] && { # a function to adjust audio file tempo and pitch independantly
    # a work in progress, depends on hms2sec, ffmpeg and rubberband
    # https://hg.sr.ht/~breakfastquay/rubberband
    # https://breakfastquay.com/rubberband/
    echo "# Crisp  0=mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive "
    echo "# Formant y/''  CenterFocus y/'' cmp (ckb|hrn|cps)(1..)/y/'' vol 0db/''"
    echo "# rev y/''"
    echo "# verb=chkwrn t='1' p='0' f='' c='' F='' CF='' ss='' to='' cmp='' v='' f2rb2mp3 {file-in} {prepend-out}"
    return 0
    }
  [ "$1" ] || { f2rb2mp3 help ; return 1 ;}
  [ "$verb" ]  || local verb="devnul"
  [ "$verb2" ] || local verb2="devnul"
  [ "$verb3" ] || local verb3="devnul"
  local infile="$(basename "$1")"
  local indir="$(dirname "$1")"
  [ "$t" -o "$p" ] && { [ "$c" ] || local c=3 ;} || true # Crispness (3=MULTITIMBRAL local default, rb standard = 5)
  local tc='' tn=''
  [ "$t" ] && tc="--time $t"  tn="-t${t}" || true
  local pc='' pn=''
  [ "$p" ] && pc="--pitch $p" pn="-p${p}" || true
  local fhzc='' fhzn=''
  [ "$f" = "bhz" ] && { fhzc="-f 0.98181818181818" ; fhzn="-bhz" ;} || true # baroque 432 hz tuning, additional to come
  local cc='' cn=''
  [ "$c" ] && cc="--crisp $c" cn="-c${c}" || true
  local cfc='' cfn=''
  local Fc='' Fn=''
  local secc='' secn='' ssec='' tsec=''
  local out=''
  local prependt="$2"
  local cmpn='' cmpc=''
  local vn='' vc=''
  local ckb0="compand 0.2,0.9  -70,-70,-60,-55,-50,-45,-35,-35,-20,-25,0,-12 6 -70 0.2"
  local ckb2="compand 0.2,0.9  -70,-99,-50,-60,-50,-45,-30,-30,-20,-25,0,-13 6 -70 0.2"
  local ckb3="compand 0.2,0.8  -60,-99,-50,-56,-38,-32,-23,-18,0,-4         -2 -60 0.2"
  local hrn1="compand 0.08,0.3 -68,-68,-50,-46,-18,-18,-0,-6                 2 -68 0"
  local hrn2="compand 0.08,0.3 -68,-68,-50,-46,-18,-18,-0,-6                -2 -68 0"
  local hrn3="compand 0.08,0.3 -74,-80,-50,-46,-18,-18,-0,-6                -1 -68 0"
  local cps1="compand 0.06,0.3 -70,-84,-50,-45,-32,-33,-0,-21              1.8 -71 0.013";
  [ "$cmp" = "ckb" ]  && local cmpn="$cmp" cmpc="$ckb0"
  [ "$cmp" = "hrn" ]  && local cmpn="$cmp" cmpc="$hrn1"
  [ "$cmp" = "hrn2" ] && local cmpn="$cmp" cmpc="$hrn2"
  [ "$cmp" = "hrn3" ] && local cmpn="$cmp" cmpc="$hrn3"
  [ "$cmp" = "ckb2" ] && local cmpn="$cmp" cmpc="$ckb2"
  [ "$cmp" = "ckb3" ] && local cmpn="$cmp" cmpc="$ckb3"
  [ "$cmp" = "hrn1" ] && local cmpn="$cmp" cmpc="$hrn1"
  [ "$cmp" = "cps1" ] && local cmpn="$cmp" cmpc="$cps1";
  $verb2 "cmpn='$cmpn'"
  $verb2 "cmpc='$cmpc'"
  $verb2 "infile='$indir/$infile'"
  [ -f "$indir/$infile" ] || { f2rb2mp3 help ; chkerr "no input flle $infile" ; return 1 ;}
  cd "$indir"
  mkdir -p ./tmp ./loss
  null=$(mktemp ./tmp/nulltime-XXXXX)
      $verb "./tmp/${infile}.flac"
      $verb2 "...next refactor move sox trim to this ffmpeg step"
  [ -e "./tmp/${infile}.flac" ] || { # make ready the flac for universal read
      $verb2    ffmpeg -hide_banner -loglevel warning -i "$infile" "./tmp/${infile}.flac"
                ffmpeg -hide_banner -loglevel warning -i "$infile" "./tmp/${infile}.flac"   || { chkerr " flack fail ";} ;} # have flack # -loglevel fatal
  [ "$cmpn" ] && local vn="-$cmpn" vc="$cmpc" # sox compand is basically a volume adjustment...
  [ "$vn" -a -z "$v" ] && v=0db || true # set an unset volume (v) param, if we have compand w/o volume
  [ "$vn" -o "$v" ] && { vn="${vn}-v${v}" vc="$vc vol ${v} dither" ;} || true # set vol name (vn) and vol command (vc) if needed
  [ "$to" ] || local to="$(ffprobe "$indir/$infile" | grep DURATION | awk '{print $3}' | sort | tail -n1 )" # if unset, set end to duration of longest stream
  [ "$ss" -o "$to" ] && { # trim times
    [   "$ss" ] && { ssec=$(hms2sec ${ss}) ;}
    [   "$to" ] && { tsec=$(hms2sec ${to}) ;}
    [ ! "$ss" -a   "$to" ] && secc="trim 0 =$tsec"     secn="-to$tsec"
    [   "$ss" -a   "$to" ] && secc="trim $ssec =$tsec" secn="-ss${ssec}-to${tsec}"
    [ -e "./tmp/${infile}${secn}.flac" ] || { # make trimmed flack
      $verb                             "./tmp/${infile}${secn}.flac"
      $verb2 sox "./tmp/${infile}.flac" "./tmp/${infile}${secn}.flac" $secc
             sox "./tmp/${infile}.flac" "./tmp/${infile}${secn}.flac" $secc   \
        || { chkerr "trim: sox ./tmp/${infile}.flac ./tmp/${infile}${secn}.flac $secc"  ; return 1 ;} ;} # made trimmed
    } # have trimmed flac
  ##### begin rb section ######################################
  [ "$t" -o "$p" -o "$f" ] && { # rb parm
    [ "$F" = "y" ] && Fc='--formant' Fn='-F' || Fc='' Fn=''
    [ "$cf" = "y" ] && cfn='-cf' cfc='--centre-focus' || cfn='' cfc=''
    out="${infile}${tn}${pn}${fhzn}${cfn}${Fn}${cfn}${secn}"
    [ -e "./tmp/${out}.wav" ] || { # final master sans volume
      $verb "./tmp/${out}.wav"
      $verb2 $rb -q $tc $pc $fhzc $cc $Fn $cfc "./tmp/${infile}${secn}.flac" "./tmp/${out}.wav"
             $rb -q $tc $pc $fhzc $cc $Fn $cfc "./tmp/${infile}${secn}.flac" "./tmp/${out}.wav" || { chkerr \
             $rb -q $tc $pc $fhzc $cc $Fn $cfc "./tmp/${infile}${secn}.flac" "./tmp/${out}.wav" ; return 1 ;}
      } # final master sans volume
    # apply volume and make an mp3 --- hopefully the input is not clipped already!
    $verb ""./tmp/${out}${vn}.mp3""
    $verb2         sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc
                   sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc \
      || { chkerr "sox ./tmp/${out}.wav ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
    } || { # no rb, only time and/or volume
    $verb "./tmp/${out}${vn}.mp3"
    $verb2         sox "./tmp/${infile}${secn}.flac" "./tmp/${out}${vn}.mp3" $vc
                   sox "./tmp/${infile}${secn}.flac" "./tmp/${out}${vn}.mp3" $vc \
      || { chkerr "sox ./tmp/${infile}${secn}.flac ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
    } # no rb only time and/or volume
    $verb "./loss/${prependt}${out}${vn}.mp3"
              prependf "./tmp/${out}${vn}.mp3" "$prependt" \
                 && mv "./tmp/${prependt}${out}${vn}.mp3" "./loss/"
    find "$PWD" -type f -newer "$null" | xargs ls -lrth
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

formfile () { # frame command procedure to render file
  # filter ^.*
  #   filter ext                  ext="$(echo "^${a##*^}" | sed -e 's/[^.]*.//' -e 's/-.*//')"
  #   filter ^hash               hash="$(echo "^${a##*^}" | sed "s/\.${ext}.*//")"
  #   filter type                type="$(echo "^${a##*^}" | sed "s/.*\.//")"
  #   filter args                args="$(echo "^${a##*^}" | sed -e "s/.*\.${ext}//" -e "s/.${type}$//" -e 's/-\([[:alpha:]]*\)/ \1=/g' -e 's/= /=y /g' -e 's/^/ verb=chkwrn/')"
  # filter .*^
  #   filter maskfix              mfix="$(echo "${a%%^*}" | sed 's/-.*//')"
  #   filter identity         identity="$(echo "${a%%^*}" | sed -e 's/[^-]*-//' -e 's/-.*//' )"
  #   filter subjecti              sub="$(echo "${a%%^*}" | sed "s/.*${idnetity}-//")"
# use case:
#
# for a given rendered file
#     001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
#
# decompose into rendering command line for parameters
#
# formfile 001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
#
# # 001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
# ln /Users/geo/dot4/5/a/8/d/b/^/5f8b-muser/001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3 /Users/geo/dot4/5/a/8/d/b/57a_1d24af8c_/_master
# verb=chkwrn t=0.87 p=1 c=3 F=y ss=4795 to=5790 v=1db f2rb2mp3 /Users/geo/dot4/5/a/8/d/b/57a_1d24af8c_/_master/Jean-Marie_Leclair_Complete_Flute_Sonatas_^fJwnsyEtkK0.opus 001
#
    local f fs;
    [ "$1" ] && fs="$1" || fs="$(cat)";
    shift;
    [ "$1" ] && $FUNCNAME $@;
    [ "$fs" = "-h" -o "$fs" = "--help" ] \
      && {
        chkwrn "Usage, for arg1 (or per line stdin)";
      # chkwrn "return: mfix iden subj ^hash.ext args type"
        chkwrn "decompose into rendering command(s)"
    } || {
      echo "$fs" | while IFS= read a ; do
        #local filepath="${a##/*}"
        a="${a##*/}" # filepath irrevalant
        ext="$(echo "^${a##*^}" | sed -e 's/[^.]*.//' -e 's/-.*//')" # expect ^ to proceed hash, followed by a dot mime, plus parm (.ext[-parm]*)
        local hash="$(echo "^${a##*^}" | sed "s/\.${ext}.*//")"      # hash from between "^ .ext"
        # convert encoded args
        # Crisp  0=Mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive
        # Formant y/''  CenterFocus y/'' cmp (ckb|hrn)(1..)/y/'' vol 0db/''
        # verb=chkwrn t='1' p='0' c='3' F='' cf='' ss='' to='' cmp='' v='' f2rb2mp3 {file-in} {prepend-out}
        local args="$(echo "^${a##*^}" | sed -E -e "s/.*\.${ext}//" -e "s/.mp3$//" \
          -e "s/-t/ t=/" -e 's/-p/ p=/' -e 's/-f/ f=/' \
          -e 's/-c/ c=/' -e 's/-F/ F=y/' -e 's/-cf/ cf=y/' \
          -e 's/-ss/ ss=/' -e 's/-to/ to=/' -e 's/-(kbd|hrn|cps)/ cmp=\1/' -e 's/-v/ v=/' \
          -e 's/^/ verb=chkwrn/')"
        local seq="$(echo "${a%%^*}"  | sed -e 's/[^-]*-.*//')"
        local title="$(echo "${a%%_^*}" | sed -e "s/^${seq}-//")"
        local dir="$links/@" orig=''
        local orig="$(find "${dir}" ./@ ./orig -maxdepth 1 -type f -name \*${hash}\* | head -n1 )"
    #   local orig="$(find  .              -maxdepth 1 -type f -name \*${hash}\* | grep -v '(.vtt$|.json$)' | head -n1 )"
        [ "$orig" ] || { orig=${hash}.${ext} ; masterlink "${hash}.${ext}" "$dir" || chkwrn $FUNCNAME masterlink error ;}
#       f2rb2mp3 help
        echo $args f2rb2mp3 $orig $seq$title
        done
    }
}

masterlink () {
verb2=chkwrn
  [ "$1" ] && local hash="$1" || { chkerr "$FUNCNAME : no hash" ; return 1 ;}
  [ "$2" ] || local dir="$links/_ln" && local dir="$2"
  dot4find "$hash" \
    | grep -vE '(.vtt$|.json$)' | ckstat | sort -k4 | head -n1 \
    | awk -v m="$dir/$hash" '{print "ln",$5,m}'
 }



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
 lacktone1a () { # play background tone, optioal gain (arg1) default -50
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-50"
   while :; do
      play -q -n -c1 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3 01.35 gain $g
      play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.3 0.78  gain $g
      sleep 0.54
      printf "%s" "1a" >>"$tmp/lacktone" &
      done
 }
 lacktone1b () { # play background tone, optioal gain (arg1) default -50
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-50"
   while :; do
      play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3 01.35 gain $g
      play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.3 0.78  gain $g
      sleep $(dc -e "3 k 1 $(($RANDOM %49 + 1)) / 0.50 + p")
      printf "%s" "1b " >>"$tmp/lacktone" &
      done
  }
 lacktone2a () { # play background tone, optioal gain (arg1) default -50
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-50"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.06 "$1" * "$1" + p"}' | dc )"
   while :; do
     play -q -n -c1 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.52 01.35 gain $g
     play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.52 0.78  gain $gb
      sleep 0.54
      printf "%s" "2a" >>"$tmp/lacktone" &
      done
 }
 lacktone2b () { # play background tone, optioal gain (arg1) default -50
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-50"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.06 "$1" * "$1" + p"}' | dc )"
   while :; do
     play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.52 01.35 gain $g
     play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.52 0.78  gain $gb
      sleep $(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 0.50 + p")
      printf "%s" "2b " >>"$tmp/lacktone" &
      done
  }
 lacktone5a () { # play background tone, optioal gain (arg1) default -50
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-50"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.03 "$1" * "$1" + p"}' | dc )"
   while :; do
      play -q -n -c1 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.27 01.35 gain $gb
      play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.33 0.78  gain $g
      sleep 0.54
      printf "%s" "5a" >>"$tmp/lacktone" &
      done
 }
 lacktone5b () { # play background tone, optioal gain (arg1) default -50
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-50"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.22 "$1" * "$1" + p"}' | dc )"
   while :; do
      play -q -n -c2 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.33 01.35 gain $g
      play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.27 0.78  gain $gb
      sleep $(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 0.52 + p")
      printf "%s" "5b " >>"$tmp/lacktone" &
      done
  }

lack1tone () {
    [ "$1" ] && g="$1" || g="-50"
    lacktone1a $g & lacktone1b $g &
    lacktone
    fg;fg
    }
lack2tone () {
    [ "$1" ] && g="$1" || g="-50"
    lacktone2a $g & lacktone2b $g &
    lacktone
    fg;fg
    }
lack5tone () {
    [ "$1" ] && g="$1" || g="-50"
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg
    }

lack15tones () {
    [ "$1" ] && g="$1" || g="-50"
    lacktone1a $g & lacktone1b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg
    }
lack125tones () {
    [ "$1" ] && g="$1" || g="-50"
    lacktone1a $g & lacktone1b $g &
    lacktone2a $g & lacktone2b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg
    }
lack155tones () {
    [ "$1" ] && g="$1" || g="-50"
    lacktone1a $g & lacktone1b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg
    }
lack1255tones () {
    [ "$1" ] && g="$1" || g="-50"
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


# for p in 0 1 2 3 4 7 8 9  ; do ps=$(( 100 * p +10   )) ; seq 1 $((ps +4)) | awk -v ps=$ps 'NR>ps {printf "%3s %03d \n",$1,$1}' ; done
# for p in 0 1 2 3 4 ; do ps=$(( 64 * p   )) ; seq 1 $((ps +4)) | awk -v ps=$ps 'NR>ps {printf "%3s %03o \n",$1,$1}' ; done
numlist () { #:> re-number a list of files, retaining the spectrum (first) character
    # such that when combined with another list, the general spectrum sequence is retained.
    # Only act on files
    # the plan:
    # get file list as arg@ OR stdin (one file per line)
    # prepend "$numlist" if not null; or retain first character of each filename
    # prepend "{spectrum}{sequience}-" string to file basename (sans leadinng "[[:xdigit:]]*-")
    # prepend 000 to unnumbered files, no match ^[[:xdigit:]]*-
    # create mv commands for the above result (pipe to shell to exec)
    local f fs p ps ;
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1" )" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    fs="$(echo "$fs" | sed 's/\.\///' | while IFS= read f ; do [ -f "${f%%/*}" ] && echo "${f%%/*}" ; done)"
        # next plan, incert two \n before each file, make NR gaps
        # and remove extra lines
    for p in 0 1 2 3 4 5 6 7 8 9 ; do
        { echo "$fs" | grep "^$p" ;} \
            | awk -v p=$p 'NR>0 {printf "%s %02d %s\n",$0,NR,$0}' \
            | sed -e 's/\(.\)/& &/' -e 's/ [[:xdigit:]]*-/ /' \
            | awk -v i="$numlist" '{printf "mv %s %s%s%s-%s\n",$4,i,$1,$3,$2}' \
              | while IFS= read a ; do set $a ; [ "$2" = "$3" ] || echo "$a" ; done
        done
    [ "$numlist" ] || local numlist=00
        { echo "$fs" | sed '/^[[:digit:]]/d' ;} \
            | awk 'NR>0 {printf "%s %02d %s\n",$0,NR,$0}' \
            | awk -v i="$numlist" '{printf "mv %s %s%s-%s\n",$3,i,$2,$1}' \
              | while IFS= read a ; do set $a ; [ "$2" = "$3" ] || echo "$a" ; done
    }

