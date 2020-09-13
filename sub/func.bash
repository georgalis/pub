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
#alias  gmv='git mv'
alias  glog='git log'
alias  gref='git reflog'
alias  grst='git reset HEAD'
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
#
# restore files #  git checkout -- {opt-file-spec}
# undo add      #  git reset       {opt-file-spec}
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
f2rb2mp3 () ( # file to rubberband to mp3, tuning function
    # subshell sets pipefail and ensures PWD on err
    set -e -o pipefail
    # validate env per
    # https://github.com/georgalis/pub/blob/master/skel/.profile
    # https://github.com/georgalis/pub/blob/master/sub/func.bash
    verb=devnul
    while IFS= read fndata ; do
        validfn $fndata || { echo "validfn error : $fndata" 1>&2 ; return 1 ;}
        #$verb "valid : $fndata"
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
    echo "# Formant 'y'/''  CenterFocus 'y'/''  volume '0db'/'' cmp '{ckb|ckb2}'"
    echo "# t='1' p='0' C='' F='' CF='' ss='' to='' cmp='' v='' f2rb2mp3 name.opus"
    return 0
    }
  [ "$1" ] || { f2rb2mp3 help ; return 1 ;}
    verb="chkwrn"
    verb2="devnul"
    verb3="devnul"
    local q='' vn='' vc=''
    local ssec='' tsec=''
    local tc='' tn=''
    local cf='' xcf=''
    local f='' c=''
    local out=''
    local infile="$(basename "$1")"
    local cmpn='' cmpc=''
    local  ckb="compand 0.2,0.9 -70,-70,-60,-55,-50,-45,-35,-35,-20,-25,0,-12 6 -70 0.2"
    local ckb2="compand 0.2,0.9 -70,-99,-50,-60,-50,-45,-30,-30,-20,-25,0,-13 6 -70 0.2"
    local ckb3="compand 0.2,0.8 -60,-99,-50,-56,-38,-32,-23,-18,0,-4         -2 -60 0.2"
    [ "$cmp" = "y" ]    && local cmpn="ckb2" cmpc="$ckb2"
    [ "$cmp" = "ckb" ]  && local cmpn="ckb"  cmpc="$ckb"
    [ "$cmp" = "ckb2" ] && local cmpn="ckb2" cmpc="$ckb2"
    [ "$cmp" = "ckb3" ] && local cmpn="ckb3" cmpc="$ckb3"
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
    [ "$vn" -a -z "$v" ] && v=0db || true
    [ "$vn" -o "$v" ] && { vn="${vn}-v$v" vc="$vc vol $v dither" ;} || true
    [ "$t" = '1' -a "$p" = '0' -a "$ss" = '' -a "$to" = '' ] && { # none or volume only change
        $verb                                "./tmp/${infile}${vn}.mp3" 
        $verb2   sox "./tmp/${infile}.flac"  "./tmp/${infile}${vn}.mp3" $vc
                 sox "./tmp/${infile}.flac"  "./tmp/${infile}${vn}.mp3" $vc \
          &&  mv "./tmp/${infile}${vn}.mp3" "./loss/${infile}${vn}.mp3" \
          && return 0 \
          || { chkerr "XXX no flac? vol: sox $infile ./loss/${infile}${vn}.mp3 $vc" ; return 1 ;} ;} # easy mp3 done
    [ "$ss" -o "$to" ] && { # trim times
        [ "$ss" ] && { ssec=$(hms2sec ${ss}) ;}
        [ "$to" ] && { tsec=$(hms2sec ${to}) ;}
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
              $verb2 $rb --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav"  
                     $rb --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav" || { chkerr \
                     $rb --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav" ; return 1 ;}
              } # final master
            # apply volume and make an mp3 --- some program doesn't respect volume dither so do it last,
            # though maybe too late for clipping
            $verb "./loss/${out}${vn}.mp3"
            $verb2    sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc
                      sox "./tmp/${out}.wav" "./tmp/${out}${vn}.mp3" $vc \
              && mv "./tmp/${out}${vn}.mp3" "./loss/${out}${vn}.mp3" \
       || { chkerr "mp3: sox ./tmp/${out}.wav ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
            } # rb parm
        }  || { # no rb, only time and/or volume
        $verb "./loss/${out}${vn}.mp3"
        $verb2         sox "./tmp/${infile}${tn}.flac" "./tmp/${out}${vn}.mp3" $vc
                       sox "./tmp/${infile}${tn}.flac" "./tmp/${out}${vn}.mp3" $vc \
                        && mv "./tmp/${out}${vn}.mp3" "./loss/${out}${vn}.mp3" \
          || { chkerr "sox ./tmp/${infile}${tn}.flac ./tmp/${out}${vn}.mp3 $vc" ; return 1 ;}
        } # no rb only time and/or volume
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
    #  play -q -n -c2 synth sin %-24.7 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3  01.35 gain $gb
    #  play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2       fade h 0.19 2.3  0.78  gain $g
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
    # play -q -n -c2 synth sin %-24.7 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3  01.35 gain $gb
    #  play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2       fade h 0.19 2.3  0.78  gain $g
     play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.52 01.35 gain $g
     play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.52 0.78  gain $gb
     #sleep $(dc -e "3 k 1 $(($RANDOM %44 + 1)) / 0.50 + p")
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
    # play -q -n -c1 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.42 01.35 gain $g
    # play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.42 0.78  gain $g
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
    # play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.42 01.35 gain $g
    # play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.42 0.78  gain $g
     #sleep $(dc -e "3 k 1 $(($RANDOM %44 + 1)) / 0.50 + p")
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

numlist () { #:> number a list of files, retaining first digit
    # renumber a list of files such that when combined with another list, # the major sequence is retained.
    # Only act on files with the plan:
    # get file list as args OR stdin (one file per line)
    # retain first numeral of each filename
    # append octal sequience number (starting with 301) to file basename (sans leadinng "digits-")
    # prepend 0- to files without a leading number
    # create mv commands for the above result (pipe to shell)
    local f fs p ;
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1" )" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    fs="$(echo "$fs" | sed 's/\.\///' | while IFS= read f ; do [ -f "${f%%/*}" ] && echo "${f%%/*}" ; done)"
    for p in 0 1 2 3 4 5 6 7 8 9 ; do
        { seq 1 192 ; echo "$fs" | grep "^$p" ;} \
            | awk 'NR>192 {printf "%s %o %s\n",$0,NR,$0}' \
            | sed -e 's/\(.\)/& &/' -e 's/ [[:xdigit:]]*-/ /' \
            | awk -v i="$numlist" '{printf "mv %s %s%s%s-%s\n",$4,i,$1,$3,$2}'
        done
    [ "$numlist" ] || local numlist=0
        { seq 1 192 ; echo "$fs" | sed '/^[[:digit:]]/d' ;} \
            | awk 'NR>192 {printf "%s %o %s\n",$0,NR,$0}' \
            | awk -v i="$numlist" '{printf "mv %s %s%s-%s\n",$3,i,$2,$1}'
    }

# for p in 0 1 2 3 4 7 8 9  ; do ps=$(( 100 * p +10   )) ; seq 1 $((ps +4)) | awk -v ps=$ps 'NR>ps {printf "%3s %03d \n",$1,$1}' ; done
# for p in 0 1 2 3 4 ; do ps=$(( 64 * p   )) ; seq 1 $((ps +4)) | awk -v ps=$ps 'NR>ps {printf "%3s %03o \n",$1,$1}' ; done
numlist () { #:> re-number a list of files, retaining the first digit
    # such that when combined with another list, the major sequence is retained.
    # Only act on files with the plan:
    # get file list as arg@ OR stdin (one file per line)
    # prepend "$numlist" if not null; or
    # retain first numeral of each filename
    # append sequience number to file basename (sans leadinng "[[:xdigit:]]*")
    # prepend 000- to files without a leading number,
    # create mv commands for the above result (pipe to shell)
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
            | awk -v i="$numlist" '{printf "mv %s %s%s%s-%s\n",$4,i,$1,$3,$2}'
        done
    [ "$numlist" ] || local numlist=00
        { echo "$fs" | sed '/^[[:digit:]]/d' ;} \
            | awk 'NR>0 {printf "%s %02d %s\n",$0,NR,$0}' \
            | awk -v i="$numlist" '{printf "mv %s %s%s-%s\n",$3,i,$2,$1}'
    }

