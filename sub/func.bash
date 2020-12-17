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
    [ "$cksum" ] || local cksum=cksum
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
[ "$verb" ] || verb=devnul
while IFS= read fndata ; do
validfn $fndata || { echo "validfn error : $fndata" 1>&2 ; return 1 ;}
$verb "valid : $fndata"
done <<EOF
# pub/skel/.profile 20200208
chkerr 1473511298 95
chkwrn 2268919251 93
stderr 3041441698 35
devnul 2725980892 30
chkecho 3391569120 51
source_iff 2032202597 101
EOF
# validfn run

alias   gst='git status --short'
alias   gls='git ls-files'
alias   gdf='git diff --name-only'
alias gdiff='git diff'
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
# The Three Trees
#  HEAD    : Last commit snapshot, next parent
#  Index   : Proposed next commit snapshot
#  Working : Sandbox
#                           HEAD Index  Workdir   Safe?
# Commit Level =========================================
#  reset --soft [commit]     REF    -      -      YES
#  reset        [commit]     REF   YES     -      YES
#  reset --hard [commit]     REF   YES    YES      -
#  checkout     <commit>     HEAD  YES    YES     YES
# File Level ===========================================
#  reset    [commit] <paths>  -    YES     -      YES
#  checkout [commit] <paths>  -    YES    YES      -
#=======================================================
# https://git-scm.com/docs/git-reset#_discussion
# https://git-scm.com/docs/giteveryday
# https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things


## shell script fragments
# chkerr () { [ -n "$*" ] && echo "ERR >>> $0 : $* <<<" >&2 && exit 1 || true ;}
# main () { # enable local varables
#
#local u h b t s d bak n tf
#u="$USER" # uid running the tests
#h="$(cd $(dirname $0) && pwd -P)" # realpath of this script
#b="$(basename $0 | sed 's/.[^.]*$//')" # this program name less (.sh) extension
#t="$( { date '+%Y%m%d_%H%M%S_' && uuidgen ;} | sed -e 's/-.*//' | tr -d ' \n' )" # time based uniq id
# find . \( -path ./skel -o -path ./mkinst \) \! -prune -o -type f
#[ -n "$1" ] && { cd "$1" && s="$PWD" ;} || chkerr "Expecting skel dir as arg1" # set src dir
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
    -o "$d/%(playlist_index)s-%(title)s_^%(id)s.%(ext)s" $id
} # _youtube_video_list
_youtube_video () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub --no-playlist \
    -o "$d/%(title)s_^%(id)s.%(ext)s" $id
} # _youtube_video
_youtube () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub \
    --no-playlist --extract-audio -o "$d/%(title)s_^%(id)s.%(ext)s" $id
} # _youtube
_youtube_list () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --write-sub \
    --yes-playlist --extract-audio -o "$d/%(playlist_index)s-%(title)s_^%(id)s.%(ext)s" $id
    #--yes-playlist --extract-audio -o "$d/%(playlist_index)s^%(id)s.%(ext)s" $id
} # k4_youtube

# youtube-dl --write-info-json --restrict-filenames --abort-on-error --yes-playlist \
#    --extract-audio -o "$epoch%(playlist_index)s_%(title)s_^%(id)s.%(ext)s" $id
# playlist or individual id
#     id=JBL04BYNR8U
#     id=PLmCLUrrx_kSfrfEJtcerTApDaRUBZZRsZ
#
#        --playlist-start 3
#        --playlist-end 6
#        --playlist-items 3,6,12-16
#        --no-playlist # Download the video, if ambigious
#        --yes-playlist # Download the playlist, if ambigious


hms2sec () { # passthrough seconds or convert hh:mm:ss to seconds
    # must provide ss which may be ss.nn, hh: and hh:mm: are optional
    # a number must proceed every colin
  [[ $1 == *:*:*:* ]] && { chkerr "too many ':' in $1" ; return 1 ;}
  [[ $1 == *:*:* ]] && { echo $1 | sed -e 's/:/ 0/g' \
        | awk '{print "3 k "$1" 60 60 * * "$2" 60 * "$3" + + p"}' | dc && return 0 ;}
  [[ $1 == *:* ]] && echo $1 | sed -e 's/:/ 0/g' \
        | awk '{print "3 k "$1" 60 * "$2" + p"}' | dc
  [[ $1 == *:* ]] || echo $1
  } # hms2sec
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
# pub/skel/.profile pub/sub/func.bash 20200208
chkerr 1473511298 95
chkwrn 2268919251 93
stderr 3041441698 35
devnul 2725980892 30
chkecho 3391569120 51
hms2sec 3998860271 383
EOF
  [ -x "$(which "$rb")"  ] || { chkerr "$FUNCNAME : env rb not set to rubberband executable" ; return 1 ;}
  [ -x "$(which ffmpeg)" ] || { chkerr "$FUNCNAME : ffmpeg not in path" ; return 1 ;}
  [ -x "$(which sox)"    ] || { chkerr "$FUNCNAME : sox not in path" ; return 1 ;}
  # success valid env
  [ "$1" = "help" ] && { # a function to adjust audio file tempo and pitch independantly
    # a work in progress, depends on hms2sec, ffmpeg and rubberband
    # https://hg.sr.ht/~breakfastquay/rubberband
    # https://breakfastquay.com/rubberband/
    echo "# Crisp  0=Mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive "
    echo "# Formant y/''  CenterFocus y/'' cmp (ckb|hrn)(1..)/y/'' vol 0db/''"
    echo "# verb=chkwrn t='1' p='0' c='3' F='' CF='' ss='' to='' cmp='' v='' f2rb2mp3 {file-in} {prepend-out}"
    return 0
    }
  [ "$1" ] || { f2rb2mp3 help ; return 1 ;}
  [ "$verb" ]  || local verb="devnul"
  [ "$verb2" ] || local verb2="devnul"
  [ "$verb3" ] || local verb3="devnul"
  [ "$t" ] || t=1 # if unset, set default time coef
  [ "$p" ] || p=0 # if unset, set default pitch coef
  local q='' vn='' vc=''
  local ssec='' tsec=''
  local tc='' tn=''
  local cf='' xcf=''
  local f='' c=''
  local out=''
  local infile="$(basename "$1")"
  local prependt="$2"
  local pt="$2"
  local cmpn='' cmpc=''
  local ckb0="compand 0.2,0.9 -70,-70,-60,-55,-50,-45,-35,-35,-20,-25,0,-12 6 -70 0.2"
  local ckb2="compand 0.2,0.9 -70,-99,-50,-60,-50,-45,-30,-30,-20,-25,0,-13 6 -70 0.2"
  local ckb3="compand 0.2,0.8 -60,-99,-50,-56,-38,-32,-23,-18,0,-4         -2 -60 0.2"
  local hrn1="compand 0.08,0.3 -68,-68,-50,-46,-18,-18,-0,-6                2 -68 0"
  local hrn2="compand 0.08,0.3 -68,-68,-50,-46,-18,-18,-0,-6               -2 -68 0"
  local hrn3="compand 0.08,0.3 -74,-80,-50,-46,-18,-18,-0,-6               -1 -68 0"
  local  too="compand 0.08,0.3 -68,-68,-50,-46,-18,-18,-0,-6                0 -68 0"
  [ "$cmp" = "y" ]    && local cmpn="hrn1" cmpc="$hrn1"
  [ "$cmp" = "ckb" ]  && local cmpn="ckb0" cmpc="$ckb0"
  [ "$cmp" = "hrn" ]  && local cmpn="hrn1" cmpc="$hrn1"
  [ "$cmp" = "hrn2" ] && local cmpn="hrn2" cmpc="$hrn2"
  [ "$cmp" = "hrn3" ] && local cmpn="hrn3" cmpc="$hrn3"
  [ "$cmp" = "ckb2" ] && local cmpn="ckb2" cmpc="$ckb2"
  [ "$cmp" = "ckb3" ] && local cmpn="ckb3" cmpc="$ckb3"
  [ "$cmp" = "hrn1" ] && local cmpn="$cmp" cmpc="$hrn1"
  [ "$cmp" = "too" ]  && local cmpn="$cmp" cmpc="$too"
  cd "$(dirname "$1")"
  touch nulltime
  $verb2 "$infile"
  [ -e "$infile" ] || { f2rb2mp3 help ; chkerr "no input flle $infile" ; return 1 ;}
  mkdir -p ./tmp ./loss
  [ -e "./tmp/${infile}.flac" ] || { # make ready the flac for universal read
      $verb                                      "./tmp/${infile}.flac"     
      $verb2    ffmpeg -loglevel 24 -i "$infile" "./tmp/${infile}.flac"     
                ffmpeg -loglevel 24 -i "$infile" "./tmp/${infile}.flac"   || { chkerr " flack fail ";} ;} # have flack
  [ "$cmpn" ] && local vn="-$cmpn" vc="$cmpc"
  [ "$vn" -a -z "$v" ] && v=0db || true # set an unset volume (v) param if we have compression (cmp sets vn) w/o volume
  [ "$vn" -o "$v" ] && { vn="${vn}-v$v" vc="$vc vol $v dither" ;} || true # set vol name (vn) and vol command (vc) if needed
  [ "$t" = '1' -a "$p" = '0' -a "$ss" = '' -a "$to" = '' ] && { # none or volume only change
      $verb                                "./tmp/${infile}${vn}.mp3" 
      $verb2   sox "./tmp/${infile}.flac"  "./tmp/${infile}${vn}.mp3" $vc
               sox "./tmp/${infile}.flac"  "./tmp/${infile}${vn}.mp3" $vc \
        &&  mv "./tmp/${infile}${vn}.mp3" "./loss/${infile}${vn}.mp3" \
                              && prependf "./loss/${infile}${vn}.mp3" "$prependt" \
                    && { find "$PWD" -type f -newer ./nulltime | xargs ls -lrth ;} \
        && cd "$OLDPWD" \
        && return 0 \
        || { chkerr "XXX no flac? vol: sox $infile ./loss/${infile}${vn}.mp3 $vc" ; return 1 ;} ;} # easy mp3 done
  [ "$ss" -o "$to" ] && { # trim times
    [   "$ss" ] && { ssec=$(hms2sec ${ss}) ;}
    [   "$to" ] && { tsec=$(hms2sec ${to}) ;}
    [   "$ss" -a ! "$to" ] && tc="trim $ssec"        tn="-ss$sec"
    [ ! "$ss" -a   "$to" ] && tc="trim 0 =$tsec"     tn="-to$tsec"
    [   "$ss" -a   "$to" ] && tc="trim $ssec =$tsec" tn="-ss${ssec}-to${tsec}"
    [ ! "$ss" -a ! "$to" ] && tc=''                  tn=''
    [ -e "./tmp/${infile}${tn}.flac" ] || { # make trimmed flack
      $verb                             "./tmp/${infile}${tn}.flac"
      $verb2 sox "./tmp/${infile}.flac" "./tmp/${infile}${tn}.flac" $tc
             sox "./tmp/${infile}.flac" "./tmp/${infile}${tn}.flac" $tc   \
        || { chkerr "trim: sox ./tmp/${infile}.flac ./tmp/${infile}${tn}.flac $tc"  ; return 1 ;} ;} # made trimmed
    } # have trimmed flac
  [ "$t" -o "$p" ] && { # rb parm
    [ "$t" = "" ] && t='1' || true # time factor
    [ "$p" = "" ] && p='0' || true # pitch shift
    [ "$C" = "" ] && c='3' || c="$C" # Crispness (rb default = 5)
    [ "$F" = "y" ] && f='-F' || f='' # Formant
    [ "$CF" = "y" ] && cf='-CF' xcf='--centre-focus' || true
    out="${infile}-t${t}-p${p}-c${c}${f}${cf}${tn}"
    [ -e "./loss/${out}${vn}.mp3" ] || { # make if not exists
      [ -e "./tmp/${out}.wav" ] || { # final master sans volume
        $verb "./tmp/${out}.wav"
        $verb2 $rb -q --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav"  
               $rb -q --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav" || { chkerr \
               $rb -q --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav" ; return 1 ;}
        } # final master sans volume
      # apply volume and make an mp3 --- some program doesn't respect volume dither so do it last,
      # though maybe too late for clipping
      $verb "./loss/${out}${vn}.mp3"
      $verb2    sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc
                sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc \
              && mv "./tmp/${out}${vn}.mp3" "./loss/${out}${vn}.mp3" \
        || { chkerr "mp3: sox ./tmp/${out}.wav ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
      } # rb parm
    } || { # no rb, only time and/or volume
    $verb "./loss/${out}${vn}.mp3"
    $verb2         sox "./tmp/${infile}${tn}.flac" "./tmp/${out}${vn}.mp3" $vc
                   sox "./tmp/${infile}${tn}.flac" "./tmp/${out}${vn}.mp3" $vc \
                    && mv "./tmp/${out}${vn}.mp3" "./loss/${out}${vn}.mp3" \
         || { chkerr "sox ./tmp/${infile}${tn}.flac ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
    } # no rb only time and/or volume
    # support prepend title in the most basic case
    prependf "./loss/${out}${vn}.mp3" "$prependt"
    find "$PWD" -type f -newer ./nulltime | xargs ls -lrth
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
        a="${a##*/}" # filepath irrevalant
        ext="$(echo "^${a##*^}" | sed -e 's/[^.]*.//' -e 's/-.*//')"
        local hash="$(echo "^${a##*^}" | sed "s/\.${ext}.*//")"
      # local type="$(echo "^${a##*^}" | sed "s/.*\.//")"
        local args="$(echo "^${a##*^}" | sed -e "s/.*\.${ext}//" -e "s/.${type}$//" -e 's/-\([[:alpha:]]*\)/ \1=/g' -e 's/= /=y /g' -e 's/=y =/=-/g' -e 's/^/ verb=chkwrn/')"
        local mfix="$(echo "${a%%^*}" | sed 's/-.*//')-"
      # local iden="$(echo "${a%%^*}" | sed -e 's/[^-]*-//' -e 's/-.*//' )"
      # local sub="$(echo "${a%%^*}" | sed "s/.*${idnetity}-//")"
      #echo "# $a"
        local master="$links/_master" orig=''
        [ -f "${master}/"*${hash}* ] && local orig="${master}"/*${hash}* || true
        [ "$orig" ] || { orig=/dev/null ; masterlink "$hash" "$master" || chkwrn $FUNCNAME masterlink error ;} 
        #local orig="$(find "$links/_master" -type f -name "*${hash}*" | head -n1)"
        echo $args f2rb2mp3 $orig $mfix
        done
    }
} 

masterlink () {
chkwrn $FUNCNAME 1=$1 2=$2
verb2=chkwrn
  [ "$1" ] && local hash="$1" || { chkerr "$FUNCNAME : no hash" ; return 1 ;}
  [ "$2" ] || local master="$links/_master" && local master="$2"
  $verb2 "dot4find "$hash" | grep -vE '(.vtt$|.json$)' | ckstat | sort -k4 | head -n1"
  dot4find "$hash" \
    | grep -vE '(.vtt$|.json$)' | ckstat | sort -k4 | head -n1 \
    | awk -v m="$master" '{print "ln",$5,m}'
 } 

a="$(cat <<EOF
001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
002-Beatles-A_Hard_Days_Night_Subtitulada_^fG2evigIJIc.mkv-t0.85-p0-c3.mp3
003-Beatles-Blackbird_Rehearsal_Take_^Mo_DMGc2v5o.mkv-t0.92-p-0.99-c3.mp3
004-Beatles-Deconstructing_Sgt_Pepper_^c-wXZ5-Yxuc.mkv-t0.92-p-0.99-c3.mp3
005-Beatles-Dont_Let_Me_Down_^NCtzkaL2t_Y.webm-t1.08-p0.98-c3.mp3
006-Beatles-Kansas_City_Hey-Hey-Hey_^14ijT4RVERY.mkv-t1.03-p0-c3.mp3
007-Beatles-Magical_Mystery_Tour_^l8WMGBuNaus.webm-t1.06-p-1.99-c3.mp3
008-Beatles-Rain_^cK5G8fPmWeA.mkv-t1.11-p1.99-c3.mp3
009-Beatles-Something_In_The_Way_She_Moves_^X5IVp25InsA.webm-t0.85-p-3-c3.mp3
010-Beatles-Strawberry_Fields_Forever_-_Restored_HD_Video_^8UQK-UcRezE.webm-t1.17-p2.03-c3.mp3
011-Beatles-While_My_Guitar_Gently_Weeps_^bI8P6ZSHSvE.webm-t1.05-p-0.98-c3.mp3
0111-Jimi_Hendrix-Cafe_Au_Go_Go_68_^JDKj0aX9PRg.opus-t0.743-p-1.975-c3-to286.5-ckb-v-4db.mp3
012-Gerry_Mulligan-My_Funny_Valentine_^P8FjuxifErA.m4a-t0.818-p0.05-c3-F-v-6db.mp3
013-Benny_Goodman_Always_1967_^LRd8ZR9jDug.m4a-t0.853-p-0.08-c3-F-v10db.mp3
014-Chaminade_op79_Concertino_Flute_and_Piano_^M1fWXmBW0SE.opus-t0.88-p1.98-c3.mp3
015-Debussy_Syrinx_Amelie_^u2Fd8m2jFWI.m4a-t1.249-p0-c3-v2db.mp3
016-Gordon_Ballads_1-Darn_That_Dream_^geCLMB5N-90.opus-t1.07-p3-c1-ss0-to450-hrn1-v2db.mp3
017-Chet_Baker-Summertime_^v7xktZp3uMQ.opus-t2.29-p0.98-c3-F-ss202.752-to455.338-hrn1-v11db.mp3
018-Gordon_Ballads_2-Dont_Explain_^geCLMB5N-90.opus-t1.09-p3-c1-ss450-to819-hrn1-v0db.mp3
019-Pianoforever_Moonlight_Gymnopedie_^qBAZBl0ooU0.opus-t0.96-p-4-c3-ss333-to762-v2db.mp3
020-Debussy-Prelude_to_the_Afternoon_of_a_Faun_^9_7loz-HWUM.opus-t1.03-p3.01-c3-v2db.mp3
021-Gordon_Ballads_3-I_Am_A_Fool_To_Want_You_^geCLMB5N-90.opus-t1.02-p1.97-c1-ss819-to1225-hrn1-v-5db.mp3
022-Gordon_Ballads_4-Ernies_Tune_^geCLMB5N-90.opus-t1.05-p2.99-c1-ss1225-to1481-hrn1-v1db.mp3
023-Gordon_Ballads_5-You_Have_Changed_^geCLMB5N-90.opus-t1.02-p4-c1-ss1481-to1929-hrn1-v-2db.mp3
024-Gordon_Ballads_6-Willow_Weep_For_Me_^geCLMB5N-90.opus-t1.07-p2-c1-ss1929-to2458-hrn1-v-4db.mp3
025-Gordon_Ballads_7-Guess_I_will_Hang_My_Tears_Out_To_Dry_^geCLMB5N-90.opus-t1.05-p2.01-c1-ss2458-to2781-hrn1-v-5db.mp3
026-Gordon_Ballads_8-Body_And_Soul_^geCLMB5N-90.opus-t1.06-p3-c1-ss2781-to3802-hrn1-v-6db.mp3
101-Hermosin-Tarantella_Napoletana_^TvA7eKG8H0I.opus-t1.13-p-1.99-c3-ss115-to271.mp3
102-The_Who-Love_Reign_O_er_Me_^DhLsC2FpDZk.opus-t1.04-p0-c3.mp3
103-Pilot-Magic_1975_^MzlK0OGpIRs.opus-t1.054-p-6.98-c1-F-ckb-v-0.6.mp3
104-Sweet-Fox_On_The_Run_45_^kRv7EjjwYBI.opus-t1.113-p1.024-c3-v-1.8db.mp3
105-Flock_Of_Seagulls-I_Ran_So_Far_Away_^iIpfWORQWhU.opus-t1.14-p-0.97-c1-F-v-1db.mp3
106-Led_Zeppelin_When_The_Levee_Breaks_by_Zepparella_^xH-_9cwdLug.m4a-t1.04-p-3.98-c3-F-v-3db.mp3
107-Hendrix_Hear-My-Train_Acoustic_^P701paKEMXs.m4a-t1.0412-p-1-c3-ss52-to240.mp3
108-Foreigner-Feels_Like_The_First_Time_^CK6jKL2qWxo.opus-t1.12-p3.02-c3-v-5db.mp3
109-Yaorenmao-Team_155_^fflyPxv1ATw.opus-t1.435-p-1.997-c3-ckb-v-6.6db.mp3
110-Beethoven_Op81a_Piano-Sonata-26_E-flat-maj_Les-Adieux_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss10329-to11230-ckb3-v0db.mp3
111-Beethoven_Op49-1_Piano-Sonata-19_G-min_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss16654-to17111-ckb3-v0db.mp3
112-Beethoven_Op2-1_Piano-Sonata-1_F-min_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss17111-to18141-ckb3-v0db.mp3
113-Tiny_Bubbles_Pearly_Shells_Medley_^TCfgUYuF71s.opus-v-2db.mp3
114-Scarlatti_k380_Sonata_Emaj_Tiffany_Poon_^EcmFCpoTKXc.opus_lowpass_compand.mp3
115-Beethoven_Op2-2_Piano-Sonata-2_A-maj_1-Allegro-vivace_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss27218-to27644-ckb3-v0db.mp3
116-Beethoven_Op2-2_Piano-Sonata-2_A-maj_2-Largo-appassionato_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss27644-to28038-ckb3-v0db.mp3
117-Beethoven_Op2-2_Piano-Sonata-2_A-maj_3-Scherzo-Allegretto_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss28038-to28247-ckb3-v0db.mp3
118-Beethoven_Op2-2_Piano-Sonata-2_A-maj_4-Rondo-Grazioso_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss28247-to28651-ckb3-v0db.mp3
119-Gerry_Mulligan-My_Funny_Valentine_^P8FjuxifErA.m4a-t0.73-p-0.05-F-c3.mp3
120-Benny_Goodman_Always_1967_^LRd8ZR9jDug.m4a-t0.97-p-0.07-c3-v16db.mp3
121-Dizzy_Gillespie_Sextet_I_Can_t_Get_Started_^wE26XWrz-Ds.m4a-t0.93-p0.06-c3-v-6db.mp3
122-Beethoven_Op27-2_Piano-Sonata-14_C-sharp-min_Moonlight_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss23326-to24303-ckb3-v0db.mp3
123-Bob_van_Asperen_plays_Virginals_^GIo4iEu-DNM.m4a.mp3
124-Beethoven_Op78_Piano-Sonata-24_F-sharp-maj_^G7sDg8_26N8.opus-t1.12-p0-c1-F-ss34111-to34697-ckb3-v0db.mp3
125-Schumann-Carnaval_Op._9_-_No._12_Chopin_^kTZPkiTjCvA.mp3
126-Beethoven_Op18-1_Quartet_F-maj_1800_^K2y3lrFKAII.opus-t1-p0-c4-ss0-to1648.mp3
127-Beethoven_Op18-2_Quartet_G-maj_1800_^K2y3lrFKAII.opus-t1-p0-c4-ss1648-to2965.mp3
128-Gerry_Mulligan-My_Funny_Valentine_^P8FjuxifErA.m4a-t0.64-p0.05-c3-F.mp3
129-Beethoven_Op18-3_Quartet_D-maj_1800_^K2y3lrFKAII.opus-t1-p0-c4-ss2965-to4247.mp3
130-Dizzy_Gillespie-I_Can_t_Get_Started_^P9PKoCBLtfs.m4a-t1-p-2-c3-F-ss17-to211.6-v-12db.mp3
131-Beatles-Yellow_Submarine_Remastered_2009_^ztHxu-13UqI.m4a-t0.83-p-0.98-c3.mp3
132-Beatles-Hey_Bulldog_Remastered_2009_^g6DVE305g0s.opus-t0.91-p-2.98-c3.mp3
133-Beethoven_Op18-4_Quartet_C-min_1800_^K2y3lrFKAII.opus-t1-p0-c4-ss4247-to5566.mp3
134-Beethoven_Op18-6_Quartet_B-flat-maj_1800_^K2y3lrFKAII.opus-t1-p0-c4-ss7158-to8687.mp3
135-Beethoven_Op59-1_Quartet_F-maj_Rasumowsky_1806_^oEdaPbu8i4o.opus-t1-p0-c4-ss0-to2313.mp3
136-Beethoven_Op59-2_Quartet_E-min_Rasumowsky_1806_^oEdaPbu8i4o.opus-t1-p0-c4-ss2313-to4282.mp3
137-Beethoven_Op59-3_Quartet_C-maj_Rasumowsky_1806_^oEdaPbu8i4o.opus-t1-p0-c4-ss4282-to6070.mp3
138-Beethoven_Op74___Quartet_E-flat-maj_Harps_1809_^oEdaPbu8i4o.opus-t1-p0-c4-ss6070-to7831.mp3
139-Beethoven_Op127__Quartet_E-flat-maj_1825_^oEdaPbu8i4o.opus-t1-p0-c4-ss9135-to11262.mp3
140-Beethoven_Op130__Quartet_B-flat-maj_1826_^d9rYNUYP_LM.opus-t1-p0-c4-ss0-to2155.mp3
141-Beethoven_Op131__Quartet_C-sharp-min_1826_^d9rYNUYP_LM.opus-t1-p0-c4-ss2155-to4481.mp3
142-Beethoven_Op132__Quartet_A-min_1825_^d9rYNUYP_LM.opus-t1-p0-c4-ss4481-to7109.mp3
143-Beethoven_Op133__Grose_Fuge_B-flat-maj_quartet_1825_^d9rYNUYP_LM.opus-t1-p0-c4-ss8583-to9595.mp3
144-Beethoven_Op134__Grosse_Fugue_For_Piano_Four_Hands_^ZJe5AJpuMvU.opus-t1-p0-c4-ss0-to850.mp3
145-Arabesque_Cookie_Arabian_Dance_^XRaIEazuNtE.opus-t1.02-p-1.98-c3-F-v-9db.mp3
EOF
)"

b="$(cat <<EOF
201-Beethoven_Op135__Quartet_F-maj_1826_^d9rYNUYP_LM.opus-t1-p0-c4-ss7109-to8583.mp3
202-Bach-BWV225_Motet_1-Singet_dem_Herren_ein_neues_Lied_Scroll_^LdloDlUyV_U.mkv-t1-p0-c3-ss52-to919.mp3
203-Bach-BWV226_Motet_2-Der_Geist_hilft_unser_Schwachheit_auf_Scroll_^iZW6YxgagL8.mkv.mp3
204-Bach-BWV227_Motet_3-Jesu_meine_Freude_Scroll_^x8KBprMFq0s.mkv.mp3
205-Bach-BWV228_Motet_4-Furchte_dich_nicht_Scroll_^5AtB1iWLVuQ.mp4.mp3
206-Bach-BWV229_Motet_5-Komm_Jesu_komm_Scroll_^MIv_Lge4X28.mp4.mp3
207-Bach-BWV230_Motet_6-Lobet_den_Herrn_alle_Heiden_Scroll_^cncl4dXZ2PM.webm.mp3
208-Bach-BWV231_Motet_7-Sei_Lob_und_Preis_mit_Ehren_Scroll_^sDJO1jFuKxk.webm.mp3
209-Beethoven_WoO-33_1-Stucke_fur_Flotenuhr_^v0V5GwMNH58.opus-t1-p0-c3-ss0-to410-v5db.mp3
210-Beethoven_WoO-33_2-Stucke_fur_Flotenuhr_^v0V5GwMNH58.opus-t1-p0-c3-ss410-to673-v5db.mp3
211-Beethoven_WoO-33_3-Stucke_fur_Flotenuhr_^v0V5GwMNH58.opus-t1-p0-c3-ss673-to1060-v5db.mp3
212-Beethoven_WoO-33_4-Stucke_fur_Flotenuhr_^v0V5GwMNH58.opus-t1-p0-c3-ss1060-to1184-v5db.mp3
213-Beethoven_WoO-33_5-Stucke_fur_Flotenuhr_^v0V5GwMNH58.opus-t1-p0-c3-ss1184-to1328-v5db.mp3
301-01-Quantz_Vivace_alla_Francese_No._10_in_D_Major_QV_3_1.3_^HJ8SH-_OMuQ.opus.mp3
302-02-Quantz_Fantasia_No._1_in_D_Major_QV_3_1.5_^-DCyTFo9e3Y.opus.mp3
303-05-Quantz_Menuetto_da_capo_in_D_Major_^eWm_9ODrxUE.opus.mp3
304-06-Quantz_Minuetto_da_capo_in_G_Major_^ECPdSvnCfL8.opus.mp3
305-07-Quantz_Fantasia_No._3_in_G_Major_QV_3_1.9_^0YNfEQ5HI8s.opus.mp3
306-09-Quantz_Sarabande_in_G_Major_^W65q-mEcNJ4.opus.mp3
307-23-Quantz_Menuet_in_E_Minor_L_inconu_Variations_1-10_^e3fTUV616m0.opus.mp3
308-11-Quantz_Capricio_I_in_D_Minor_QV_3_1.8_^8wZpqgbtaIg.opus.mp3
309-12-Quantz_Capricio_II_in_E_Minor_QV_3_1.10_^1OBWgeGBGnY.opus.mp3
310-13-Quantz_Capricio_III_in_F_Major_QV_3_1.12_^Uq101uUDwU0.opus.mp3
311-14-Quantz_Capricio_IV_in_G_Major_QV_3_1.15_^WH6_LS2bUmk.opus.mp3
312-15-Quantz_Capricio_V_in_G_Major_QV_3_1.17_^t_FMlAxCgqk.opus.mp3
313-16-Quantz_Capricio_VI_in_G_Major_QV_3_1.14_^GRegie4vU_c.opus.mp3
314-17-Quantz_Capricio_VII_in_A_Minor_QV_3_1.19_^PXq0lj-S4Kg.opus.mp3
315-18-Quantz_Capricio_VIII_in_B_Major_QV_3_1.21_^RJonA0StAUU.opus.mp3
316-Rameau-by-Meyer_1-Minuet-rondeau-1724-Suite-E-min_^nomf2OrFlU8.opus-t1.26-p3.02-c1-F-ss0-to1073-ckb2-v2db.mp3
317-Rameau-by-Meyer_2-Continuation_D-maj_^nomf2OrFlU8.opus-t1.38-p1.97-c1-F-ss1070-to2645-ckb2-v2db.mp3
318-Rameau-by-Meyer_3-Suite_A-min_^nomf2OrFlU8.opus-t1.38-p3.02-c1-F-ss2645-to4132-ckb2-v2db.mp3
319-Rameau-by-Meyer_4-Suite_G-maj_^nomf2OrFlU8.opus-t1.45-p1.98-c1-F-ss4130-to5440-ckb2-v2db.mp3
320-Rameau-by-Meyer_5-Harpsichord-Book-1_^nomf2OrFlU8.opus-t1.43-p0-c1-F-ss5440-to6388-ckb2-v2db.mp3
321-Rameau-by-Meyer_6-Concert-Pieces_^nomf2OrFlU8.opus-t1.64-p2.98-c1-ss6388-to6990-ckb2-v3db.mp3
322-Rameau-by-Meyer_7-Harpsichord-Pieces-1946_^nomf2OrFlU8.opus-t1.56-p3-c1-ss6990-to8913-ckb2-v3db.mp3
323-Bach-bwv1001-Allegro-Bruggen-Sonata-1-G-min-solo-violin-on-recorder^9G0Yh3wg3js.opus-t1.26-p6-c3-F-ss917-to1356-v6db.mp3
324-Bach-bwv1003-Allegro-assai-Bruggen-Sonata-2-A-min-solo-violin-on-recorder^9G0Yh3wg3js.opus-t1.33-p-3-c3-F-ss1356-to1722-v3db.mp3
325-Eurythmics-Sweet_Dreams_Are_Made_Of_This_^qeMFqkcPYcg.opus-t1.13-p0.97-c4-v1db.mp3
401-Chopin-Op58-Piano-Sonata-3-B-min-Pollack-1m^yZXygW54NhY.opus-t1.38-p4-c1-F-ckb3-v3db.mp3
402-Chopin-Op58-Piano-Sonata-3-B-min-Pollack-2m^WwJewEKihHQ.opus-t1.38-p4-c1-F-ckb3-v3db.mp3
403-Chopin-Op58-Piano-Sonata-3-B-min-Pollack-3m^onS3slalH0c.opus-t1.38-p4-c1-F-ckb3-v3db.mp3
404-Chopin-Op58-Piano-Sonata-3-B-min-Pollack-4m^q-SKovDAgLM.opus-t1.38-p4-c1-F-ckb3-v3db.mp3
405-Leclair_Op2-1_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t1.06-p-2-c3-F-ss0-to810-v2db.mp3
406-Leclair_Op2-3_Flute_Sonata-C-Maj^fJwnsyEtkK0.opus-t1.06-p-2-c3-F-ss1620-to2370-v2db.mp3
407-Leclair_Op1-8_Flute_Sonata-G-Maj^fJwnsyEtkK0.opus-t1.03-p-2-c3-F-ss2370-to3005-v1db.mp3
408-Leclair_Op1-6_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t1.06-p-2-c3-F-ss3005-to3813-v1db.mp3
409-Leclair_Op2-11_Flute_Sonata-B-Min^fJwnsyEtkK0.opus-t1.06-p-2-c3-F-ss3813-to4189-v1db.mp3
410-Leclair_Op2-8_Flute_Sonata-D-Maj^fJwnsyEtkK0.opus-t1.06-p-2-c3-F-ss4189-to4795-v2db.mp3
411-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
412-Leclair_Op9-7_Flute_Sonata-G-Maj^fJwnsyEtkK0.opus-t0.84-p3-c3-F-ss5790-to6549-v1db.mp3
413-Leclair_Op9-7_Flute_Sonata-G-Maj^fJwnsyEtkK0.opus-t0.88-p5-c3-F-ss5790-to6549-v1db.mp3
414-Leclair_Op9-7_Flute_Sonata-G-Maj^fJwnsyEtkK0.opus-t0.85-p-2-c3-F-ss5790-to6549-v1db.mp3
415-Leclair_Op1-6_Flute_Sonata-E-Min-xAllergro^fJwnsyEtkK0.opus-t0.83-p1-c3-F-ss3005-to3663-v2db.mp3
416-Leclair_Op2-1_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t1.12-p1-c3-F-ss0-to810-v2db.mp3
417-Leclair_Op9-7_Flute_Sonata-G-Maj_2-Allegro-ma-non-troppo^fJwnsyEtkK0.opus-t1.02-p-2-c3-F-ss6020-to6210-v1db.mp3
418-Haydn-Op51-Quartet-Seven-Last-Words-of-Our-Savior-on-the-Cross_^KkLJqLYYDCw.opus.mp3
419-Brahms_Op120-2_Clarinet_Sonata_E_flat_^w1E77EGpgrk.opus-t0.69-p0-c3-F-ckb.mp3
420-Telemann_12-Fantasia-01_A-maj_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
421-Bach-BWV1001-Sonata-1-G-Min-Violin-Milstein-Scroll^JRt0I1R8zO0.opus-t1.04-p-2.03-F-c3-ss18-to917.mp3
422-Howl_s_Moving_Castle_-_Merry_go_round_of_Life_cover_by_Grissini_Project_^J6qIzKxmW8Y.opus-t1-p0-c3-to342.mp3
423-Telemann_12-Fantasia-02_A-min_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
424-Quantz_Duet_1_QV3_2_Op2-1_Allegro_^Qt-d8P046zk.opus.mp3
425-Dukas_Villanelle_Brain.opus.mp3
426-Quantz_qv2_anh3_Sonata_flute_recorder_continuo_^0G6DOtvfUk4.opus.mp3
501-Telemann_12-Fantasia-03_B-min_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
502-Bach-BWV1033-Flute-Sonata-C-Maj-Scrolling.m4v-t1-p0-c3-ss18-to559.mp3
503-Howls_Moving_Castle_OST_^UwxatzcYf9Q.opus.mp3
504-Mozart_K452_Quintet_for_Piano_and_Winds_E_flat_Brain_^ok_4GYJb2ow.opus-ckb-v2.2db.mp3
505-Bach-BWV1034-Flute-Sonata-E-Min-Scroll_^YpAZrQUvNy4.webm-t1.26-p3-c3-ss16-to898-v8db.mp3
506-Brahms_Op120-2_Clarinet_Sonata_E_flat_^w1E77EGpgrk.opus-t0.73-p-2-c1-F-ckb-v1db.mp3
507-Telemann_12-Fantasia-06_D-min_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
508-Bach-BWV1004-Partita-2-D-Min-Violin-Milstein-Scroll^Oa1dcTVk2PU.opus-t1.04-p-2.03-F-c3-ss18-to1828.mp3
509-Telemann_12-Fantasia-10_F-sharp-min_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
510-Jean-Marie_Leclair_Complete_Flute_Sonatas_^fJwnsyEtkK0.mp3
511-Bach-BWV1002-Partita-1-B-Min-Violin-Milstein-Scroll^-ikXfRbYAsU.opus-t1.04-p-2.03-F-c3-ss18-to1191.mp3
512-Bach-BWV1031-Flute-Sonata-E-Flat-Maj-Scroll_^tglNMNQ1mGw.webm-t1-p0-c3-ss16-to686-ckb.mp3
513-Brahms_Op120-2_Clarinet_Sonata_E_flat_^w1E77EGpgrk.opus-t0.86-p-4.97-c1-F-ckb-v2db.mp3
514-Bach-BWV1003-Sonata-2-A-Min-Violin-Milstein-Scroll^T2llmbA_CCM.opus-t1-p0-c3-ss18-to1361.mp3
515-Telemann_12-Fantasia-11_G-maj_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
516-Telemann_12-Fantasia-12_G-min_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
517-Telemann_12-Fantasia-09_E-maj_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
518-Telemann_12-Fantasia-07_D-maj_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
519-Telemann_12-Fantasia-04_B-flat-maj_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
520-Telemann_12-Fantasia-05_C-maj_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
521-Telemann_12-Fantasia-08_E-min_Jean-Pierre_Rampal_^uE9SjAqPGsc-t1.13.mp3
522-Bach_BWV1055_Flute_Concerto_C_maj_Rampal_^h4uPZzsoACg.opus-t1.18-p2-c3-v-5db.mp3
523-Bach_BWV993_Capriccio_E_Maj_Scroll_^tsQe6JfDznM.webm-t1.08-p0-c3-ss15-to427.mp3
524-Bach-BWV1005-Sonata-3-C-Maj-Violin-Milstein-Scroll^fRq8zCmew28.opus-t1.04-p-2.03-F-c3-ss18-to1294.mp3
525-Bach-BWV1006-Partita-3-E-Maj-Violin-Milstein-Scroll^7ERqr_1Knfk.opus-t1.04-p0.02-c3-ss36-to1155.mp3
601-Gerry_Mulligan-My_Funny_Valentine_^P8FjuxifErA.m4a-v-5db.mp3
602-Tiny_Bubbles_Pearly_Shells_Medley_^TCfgUYuF71s.opus-v-2db.mp3
603-Chet_Baker_Quartet_No_Problem_1980_^E95STK2tnoM.opus-t1.07-p3.07-c3-ss0-to590.mp3
604-Lester_Young_Harry_Sweets_Edison-Going_For_Myself_^_LcRwPpCoEs.m4a-t1.94-p1-c4-ss3626.5-to3709-v-6db.mp3
605-Lester_Young_Harry_Sweets_Edison-Going_For_Myself_^_LcRwPpCoEs.m4a-ss3626.5-to3709.flac-t2.36-p1.07-c4_v-9dB_f4.mp3
606-Lester_Young_Harry_Sweets_Edison-Going_For_Myself_^_LcRwPpCoEs.m4a-t1-p0-c4-ss3293-to3709-v-8db.mp3
607-Mozart_K381_Piano_Sonata_D_Maj_four_hands_Argerich_Economou_^0JOkx7p576o.opus-t1.68-p2-F-c1-ss14-to805.mp3
608-Haydn_string_quartet_op.76_no_2-^yXLbPL0lnus.mp3
609-Quantz_Duet_1_QV3_2_Op2-1_Allegro_^Qt-d8P046zk.opus.mp3
610-Telemann-Flute-Fantasia_07-12_scroll_^tY-HooKBZ3w.mkv-t1.54-p0-c3.mp3
611-Telemann-Flute-Fantasia_09-12_scroll_^8w-uf2tAil4.mkv-t1.54-p0-c3.mp3
612-Telemann-Flute-Fantasia_11-12_scroll_^BrjvWUqh7bw.mp4-t1.54-p0-c3.mp3
613-Dizzy_Gillespie-I_Can_t_Get_Started_^P9PKoCBLtfs.m4a-t1.14-p-1.94-c3-ss17-to211.6-v-12db.mp3
614-Chet_Baker_Trio-Chets_Choice-Philip_Catherine_^eABr97CgTbI.opus-t1-p0-c3-ss619-to1341-v4db.mp3
615-September_1666_Baker_Pudding_Lane_Baker_actions-Al_Start_^8VmtiGLfrlQ.mp3
616-No_Doubt-Dont_Speak_^TR3Vdo5etCQ.opus-t1.08-p0.99-c1-F.mp3
617-Telemann-Flute-Fantasia_08-12_scroll_^ZVO6RvKfFS4.mp4-t1.54-p0-c3.mp3
618-Duke_Ellington_John_Coltrane-In_a_sentimental_mood_^sCQfTNOC5aE.opus.mp3
701-Piers_Adams-Londons-Burning_Interview_wSarah_^nZzwbGO_evs.mkv-t1.43-p-1.96-F-cy-CF-ss542.8-to625.2-v-7db.mp3
702-Haydn_Violin_Concerto_G-maj_Hob.VIIa.4_Allegro_moderato_Leo_Zhu_^xU56I_5zURo.opus-t0.977-p-0.02-c3-F-ss213-to480-v1db.mp3
703-Haydn_Sym38_C_maj_Echo_Solomons-t1.38-p3.01-c5^5zUzO4-ivlA.ogg.mp3
704-Haydn_Piano_Sonata_47_Bmin_Hob.XVI.32_^palsBp8z6pM.mkv-t1.06-p4.03-c1.compkbd.mp3
705-Irish_Reels_TinWhistler_on_Boehm_^O-Xkmu0gfgo.opus-t1.79-p0-c3-v1db.mp3
706-Debussy_Syrinx_Amelie_^u2Fd8m2jFWI.m4a-t1.42-p-1-c3-v-1db.mp3
707-Scarlatti_k380_Sonata_Emaj_Tiffany_Poon_^EcmFCpoTKXc.opus_lowpass_compand.mp3
708-Froberger-JJ_Toccata_3_Livre_de_1649_Massini_^q_0YCx8j4zI.ogg-t1.54-p1.97-F-c3-v-6db.mp3
709-Mozart_k265_Variations_Baczewska_^Lcmmc-_bfGo.mkv-t1-p-4-c3-to721.3-ckb-v0db.mp3
710-Haydn-Niemecz_Mechanical_Organ_^A9Xsi_0ZMPE.opus-t1.04-p0-c5-ckb-v-10db.mp3
711-Triple_Flageolet_1825_^vDwsJx-6rV0.m4a-t1.17-p2.02-F-c1-ss27-to66.mp3
712-Haydn_Skowronek_mechanical_organ_pieces_1772_1792_Ventorum_scroll_^DARsV1-iwmI.m4a-ss5-to722.flac.mp3
713-Benny_Goodman_Always_1967_^LRd8ZR9jDug.m4a-t0.97-p-0.07-c3-v16db.mp3
714-Art_Tatum-In_a_Sentimental_Mood_1955_^SWp5j5YIJIQ.opus-t0.87-p3.07-c3.mp3
715-Jean-Marie_Leclair_Complete_Flute_Sonatas_^fJwnsyEtkK0.mp3
716-Haydn_Sym_38_Cmaj_Echo_Solomons_^5zUzO4-ivlA.ogg-t1.44-p5.03-F-c1.mp3
717-Haydn_string_quartet_op.64_no_5_The_Lark-^4uYxn1M_O-4.opus-t1.21-p1.98-F-c1-CF-v1.03.mp3
718-Quantz_Duet_1_QV3_2_Op2-1_Larghetto_^GgwQ8uhOXMw.opus.mp3
719-Quantz_Duet_1_QV3_2_Op2-1_Presto_^d1zBCb5BkG8.opus.mp3
720-Bach-BWV1004-Partita-2-DMin-Sarabande-Gigue-Violin-Milstein-Scroll^Oa1dcTVk2PU.webm-t1-p-3.02-c3-ss477-to971.mp3
721-Quantz_Duet_2_QV3_2_Op2-2_Allegro_assai_^_fjFdtzGjZE.opus.mp3
722-Quantz_Duet_2_QV3_2_Op2-2_Andantino_^bJ4JDr0imFs.opus.mp3
723-Quantz_Duet_2_QV3_2_Op2-2_Presto_^_hh9x_vvcpg.opus.mp3
724-Quantz_Duet_3_QV3_2_Op2-3_Minuetto_^H4BWW22C6rg.opus.mp3
725-Quantz_Duet_3_QV3_2_Op2-3_Allegro_^SOeIwoPPMng.opus.mp3
726-Quantz_Duet_3_QV3_2_Op2-3_Larghetto_^PKq9wkTtdV8.opus.mp3
727-Lester_Young_Oscar_Peterson_Trio_^PNl63ARx0DM.m4a-t1-p0-c3-ss0-to3560.mp3
728-Lester_Young-Greatest_Hits_^dP-iIgnvM-k.opus.mp3
729-Coltrane-After_the_Rain_^Je2tpX6Z-QA.opus.mp3
730-Bach-BWV1002-Partita-1-B-Min-Violin-Milstein-Scroll.opus-t1.04-p-2-F-c3.mp3
731-Bach-BWV1004-Partita-2-Dmin-Sarabande-Gigue-Scroll^Oa1dcTVk2PU.webm-t0.95-p-3.98-F-c2-ss477-to971.mp3
801-Beethoven-op81b-Sextet-Eb-Major.mp3
802-Bach_Flute_Sonatas_Solo_Nicolet_Richter_^rPmSDmxbztw.opus.mp3
803-Cherubini-String-Quartets-St-Louis-Symphony.mp3
804-SpiritNaturesWay-1.00.mp3
805-Frans_Brggen_plays_Bach_and_Handel_^fs-frS4cqvA.mkv-t1.16-p2.02-F-c4-v1.3.mp3
806-Handel-Il-trionfo-del-Tempo-e-del-Disinganno-Paul-McCreesh-t1.18-p1.05-F-c4.mp3
807-Mozart_k265_Variations_Baczewska_^Lcmmc-_bfGo.mkv-t1.48-p-4.06-F-c3-to721.3.mp3
808-Chopin-OpPosth-Nocturne-C-sharp-min-Pollack-t1.32-p7-c1^285qna2jNl0.mp3
809-Jean-Marie_Leclair_Complete_Flute_Sonatas_^fJwnsyEtkK0.mp3
810-Telemann-twv52f1-F-maj-recorder-bassoon-concerto.32-40^hd9Z8g0JE7s.mp3
811-Eyck-The_Flutes_Garden_of_Delight-Bosgraaf.mp3
812-Haydn_Niemecz_mechanical_organ_^A9Xsi_0ZMPE.mp3
813-Triple_Flageolet_1825-t1.28-p0-c3-cf^vDwsJx-6rV0.mp3
814-Telemann-twv52f1-F-maj-recorder-bassoon-concerto.32-40.t1.13-p2.00^hd9Z8g0JE7s.mp3
815-Chopin-Op35-Piano-Sonata-2-B-flat-min-Pollack-3m^Zu70PHBru5U.opus-t0.93-p5.18-F-c6-to286_rev_compand.mp3
816-Chopin-Op35-Piano-Sonata-2-B-flat-min-Pollack-3m^Zu70PHBru5U.opus-t0.97-p5.15-F-c6-to286.mp3
817-Telemann_recorder_double_concertos_Bosgraaf-t1.125-p-4^hd9Z8g0JE7s.mp3
818-Haydn_Skowronek_mechanical_organ_pieces_Ventorum_^DARsV1-iwmI.mp3
819-Triple_Flageolet_1825-t1.28-p0-c3-cf^vDwsJx-6rV0.mp3
820-Telemann_TWV52e1_traverso_recorder_concerto_E-min_Barockorchester-t1.333^2D-y2kJU0lg.mp3
821-Telemann-twv52f1-F-maj-recorder-bassoon-concerto.32-40.t1.63-p3.87^hd9Z8g0JE7s.mp3
822-Telemann_TWV52f1_recorder_bassoon_Concerto-t1.333^3nFiUFMdiAA.mp3
823-20180808-FrenchMusic.mp3
824-Bach-BWV1013-Partita-A-Min-Solo-Flute-Scroll_^Datoqxx-biw.webm-t1.64-p0-c3-ss17-to796.mp3
825-Bach-BWV1033-Flute-Sonata-C-Maj-Scrolling.mp3
826-Bach-BWV1034-Flute-Sonata-E-Min-Scrolling.mp3
827-Mozart-K622-Clarinet-Concerto-A-Maj-Kam-Honeck-2006_^o_gm0NCabPs.m4a_ss2_to1656.mp3
828-Art_Tatum_In_a_Sentimental_Mood_1955_^SWp5j5YIJIQ.opus-t1.08-p-1.99-F-c1-v1.05.mp3
829-Vivaldi_La_Follia_Two_Violins_^3b5ws3fqA30.opus-t1.12-p0.02-c3-F-ckb2-v-4db.mp3
830-Irae_Dies_Organ_^KoQv8gpWQ7M_rev_vol-8dB.flac-t0.82-p3.08-c3.mp3
831-Bertali_Chiacona_C_violin_continuo_^76phq9-KHi0.opus-t1.12-p0.02-F-c1.mp3
832-Scarlatti_La_Folia_Folies_d_Espagne_Piano_^7xwxthXoDvQ.mkv-t1.12-p0.02-F-c1.mp3
833-Falconieri_Ciaccona_Orazio_Gentileschi_^bbr5NQh4j8M.opus-t1.12-p0.02-F-c1.mp3
834-Alessandro_Scarlatti_-_La_Follia_Synthesia_piano_tutorial_^4A_U-FKpzA0.mkv-t1.17-p2.02-c1-v0.80.mp3
835-Falconieri_Ciaccona_and_Folia_^t5GjCsgc-l4.opus-t1.12-p0.02-F-c1.mp3
836-Falconieri_Ciaccona_by_La_Ritirata_Il_Spiritillo_Brando_^nLK0-N2Eruk.opus-t1.12-p0.02-F-c1.mp3
837-Falconieri_Folias_La_Ritirata_^NYRO31eg67o.opus-t1.12-p0.02-F-c1.mp3
838-Falconieri_Naples_1650_Baroque_^k_gT-YsQeQg.opus-t1.12-p0.02-F-c1.mp3
839-Falconiero_1586-1656_Passacaglia_^Mm6y-rI-7f4.opus-t1.12-p0.02-F-c1.mp3
840-Chopin-Op35-Piano-Sonata-2-B-flat-min-Pollack-3m^Zu70PHBru5U.opus-revcomp-t0.97-p5.15-F-c6-to286.mp3
841-Chopin-Op35-Piano-Sonata-2-B-flat-min-Pollack-3m^Zu70PHBru5U.opus-t0.97-p5.15-F-c6-to286.mp3
842-Corelli_La_Follia_CHAARTS_^7Oy_EcAYbnY.opus-t1.12-p0.02-F-c1.mp3
843-Corelli_La_Follia_^VHRdFILo_Yw.opus-t1.12-p0.02-F-c1.mp3
844-Falconieri_Folias_de_Espana_^Pe7nP4tBRxE.opus-t1.12-p0.02-F-c1.mp3
845-Falconiero_Folia_Two_Violins_and_Continuo_^120hfW34Pkg.opus-t1.12-p0.02-F-c1.mp3
846-Corelli_op5_Geminiani_FiBO_^jEuTZKtOAj0.mkv-t1.12-p0.02-F-c1.mp3
901-Scarlatti-Folia_^ZDBs5fEIPyc.webm-t1.12-p0.02-c1-F-v-5db.mp3
902-Falconieri_Folias_^vx9qR6ovHcA.opus-t1.12-p0.02-F-c1.mp3
903-Caccini_Ciaccona_^ja7ugHH8DtM.opus-t1.12-p0.02-F-c1.mp3
904-Geminiani_Follia_Concerto_Grosso_ONE_Antonini_^7a_Dt8AnGaU.opus-t1.12-p0.02-F-c1.mp3
905-Geminiani_La_Folia_extrait_^vCCuFzT-NxA.opus-t1.12-p0.02-F-c1.mp3
906-Corelli_La_Folia_Sonata_Szeryng_^XS-Nqzprais.opus-t1.12-p0.02-F-c1.mp3
907-September_1666_Baker_Pudding_Lane_Baker_actions-Al_Start_^8VmtiGLfrlQ.mp3
908-Folia_Renaissance_through_Baroque_^q6ObNmzqkEQ.opus-t1.12-p0.02-F-c1.mp3
909-Vivaldi_La_Folia_Apollo_s_Fire_^i4qePY2Wdss.opus-t1.12-p0.02-F-c1.mp3
910-Vivaldi_La_Follia_^7v8zxoEoA_Q.opus-t1.12-p0.02-F-c1.mp3
911-Vivaldi_RV63_La_Follia_D_Min_Trio_Sonata_^9BLfaQ98FbM.opus-t1.12-p0.02-F-c1.mp3
912-Oklahoma_State_^YNLv2exFwqc.opus-t1.19-p-5.98-c4-v0.93.mp3
913-Tartini-Violin-Concerto-D-min-Romana.mp3
914-Klughardt_op79_Wind_Quintet_Philharmonic_Five_^7u_WGwgNeLg.mp3
915-STAIRWAY_TO_HEAVEN_PORTUGUES_INGLES_^iXEsCEOh2yc.mkv.mp3
916-Dexy_Midnight_Runners_Come_On_Eileen_1982_^ASwge9wc-eI.opus-t2-p5-c4-v-4db.mp3
917-SpiritNaturesWay-1.00.mp3
918-B52s_Planet_Claire_FULL_HQ_Restored_best_version_^eOjAzI5zALo.mp3
919-B52s_Rock_Lobster_1980_^2VCCiY17hKw.mkv-t1.08-p-2.04-c3-v-1db.mp3
920-4-Non-Blondes_Whats-Up_^6NXnxTNIWkc.opus-t1.09-p1.03-c4-F-v3db.mp3
921-Simple_Minds-Dont_You_Forget_About_Me_^z8v84520W6s.opus-t0.94-p-0.98-c3.mp3
922-Johnny_Hates_Jazz_-_Shattered_Dreams_^ctwqa3QCwMw.opus-t1.15-p-2.98-F-c6-v0.92.mp3
923-Fanny_Aint_that_Peculiar_LIVE_1972-11-25_^imZUqkPlUaQ.mp3
924-The_Who_-_Eminence_front_^GnHLgxKUsEA.mp3
925-Foreigner_-_Urgent_Official_Music_Video_^Lcb-Fsx_phM.mkv-t2.00-p4.95-F-c4.mp3
926-Blondie_Rapture_^pHCdS7O248g.opus-t1.11-p3.95-c4-F-v4db.mp3
927-Shocking-Blue_Venus_^aPEhQugz-Ew.opus-t1.15-p2.98-c6-v-5db.mp3
928-Depeche_Mode-Never_Let_Me_Down_Again_^snILjFUkk_A.opus-t1.08-p0.02-F-c2.mp3
929-Eurythmics_-_Sweet_Dreams_Are_Made_Of_This_Official_Video_^qeMFqkcPYcg.opus-t1.06-p0.05-F-c4.mp3
930-Dexy_Midnight_Runners_Come_On_Eileen_1982_^ASwge9wc-eI.opus-t1.08-p2.87-F-c4-cf-v0.83.mp3
931-Keep_Em_Separated_-_The_Offspring_LYRICS_^8FWdQVNeTlI.opus-t1.16-p-2.96-c6-cf-v0.93.mp3
932-Pulling_Mussels_From_the_Shell_Squeeze_^3WngGeI9lnA.ogg-t1.13-p1.89-F-c4-cf-v0.74.mp3
933-Beatles-All_You_Need_Is_Love_Remastered_2009_^_7xMfIp-irg.opus-t1.07-p1.98-c3.mp3
934-Beatles-All_Together_Now_Remastered_2009_^73lj5qJbrms.opus-t1.04-p-1.98-c3.mp3
935-Monteverdi_Poppea_coronation_^j650NanGNyk.wav-t0.71-p-2.95-F-c4.mp3
936-Edie_Brickell_New_Bohemians_-_What_I_Am_^tDl3bdE3YQA.opus-t1.04-p1-c4-F-v1db.mp3
937-Mozart-K620-The-Magic-Flute-Sans-dialogue-1.18.mp3
938-Art_Tatum_In_a_Sentimental_Mood_1955_^SWp5j5YIJIQ.opus-t1.08-p-1.99-F-c1-v1.05.mp3
939-Cherubini+1842_Piano_Sonatas_Giammarco^JXNvGdQOZgc.opus-t1.11-p0.04-F-c1-v1.09.mp3
940-Froberger-JJ_Toccata_3_Livre_de_1649_Massini_^q_0YCx8j4zI.ogg-t2.54-p2.09-F-c1-v0.894.mp3
941-George_Gershwin_Rhapsody_in_Blue_^SHCZejQuWmo.opus-t1.08-p0-F-c4-cf.mp3
942-Peter_Gabriel_Games_Without_Frontiers_^3xZmlUV8muY.opus-t1.23-p2.13-F-c4-ss2-to240-v0.61.mp3
943-Art_Tatum_Ben_Webster_-_The_Album_1956_^KJifh-S2Hw4.mp3
944-Bob_van_Asperen_plays_Renaissance_music_on_historical_Virginals_^GIo4iEu-DNM.m4a-t1.53-p1-F-c1.mp3
945-Monteverdi_Orfeo_Savall_^0mD16EVxNOM.mkv-t0.80-p-2.95-F-c4.mp3
946-Tartini-Violin-Sonata-G-Min-Devil-Trill-Vienna_^z7rxl5KsPjs.ogg-t1.41-p5.94-c6-cf.mp3
947-Fugace_^hEU4klRfSGg.m4a-t1.05-p0-F-c4-cf.mp3
948-Bach_bwv846-869_Preludes_Fugues_scroll-t1-p0-c1.mp3
949-Frida-I_Know_There_is_Something_Going_On_ABBA_1982_^372436tJiaM.wav-t1.140-p-3.07-F-c4.mp3-t1.4-p-3.07-c4-F-v-3db.mp3
950-Gabriel-Intruder_^xvAmj3k3Imc.opus-t0.81-p-3.02-c3-F-v4db.mp3
951-Veloce_^yrJ9W5mP5Oc.m4a-t1.18-p0.01-F-c1.mp3
952-Art_Tatum_Friends_^TpmtRvebA4k.opus.mp3
953-Vivaldi_RV443_recorder_concerto_Steger_Gabetta-t1.625-p-4-formant^hggISFswKcw.mp3
954-Paganini_la_carmagnola_^Muf47PVixOk.mp3
955-Coltrane-Giant-Steps_^xr0Tfng9SP0.opus-t1.28-p-5.97-F-c2-v0.83.mp3
The_Best_of_Jelly_Roll_Morton_^Bv4jD1d64Z0.m4a-t0.943-p-0.010-c5-ckb-v2.4db.mp3
y-extra
y-repeated
y-slow
y-soft
y-tune
EOF
)"




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

