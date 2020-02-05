#!/usr/env bash

# Sundry functions

# more test
# echo "$SHELL"
# echo "$BASH_VERSINFO"      "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"
# echo "${BASH_VERSINFO[3]}" "${BASH_VERSINFO[4]}" "${BASH_VERSINFO[5]}" x "${BASH_VERSINFO[6]}"


_youtube_video_playlist () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --yes-playlist \
    -o "$d/%(playlist_index)s-%(title)s_^%(id)s.%(ext)s" $id
} # k4_youtube_video
_youtube_video () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error --no-playlist \
    -o "$d/%(title)s_^%(id)s.%(ext)s" $id
} # k4_youtube_video
_youtube () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error \
    --no-playlist --extract-audio -o "$d/%(title)s_^%(id)s.%(ext)s" $id
} # k4_youtube
_youtube_playlist () {
local id="$1"
[ "$id" ] || read -p "youtube id: " id
             read -p "directory : " d
[ "$id" ] || chkerr "no id?"
[ "$d" ] || d="$(pwd -P)"
youtube-dl --write-info-json --restrict-filenames --abort-on-error \
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



chkerr () { [ "$*" ] && { stderr ">>> $* <<<" ; return 1 ;} || true ;} #:> if args not null, err stderr args return 1
chkwrn () { [ "$*" ] && { stderr "^^ $* ^^" ; return 0 ;} || true ;} #:> if args not null, wrn stderr args return 0
stderr () { echo "$*" 1>&2 ;} # return args to stderr
devnul () { return $? ;} # expect nothing in return

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
f2rb2mp3 () { #set -x
  [ "$1" = "help" ] && { # a function to adjust audio file tempo and pitch independantly
    # a work in progress, depends on hms2sec, ffmpeg and rubberband
    # https://hg.sr.ht/~breakfastquay/rubberband
    # https://breakfastquay.com/rubberband/
    echo "# Crisp  0=Mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive "
    echo "# Formant 'y'/''  CenterFocus 'y'/''  volume '0db'/''"
    echo "# t='1' p='0' C='' F='' CF='' ss='' to='' v='' f2rb2mp3 name.opus"
    }
  [ "$1" ] || { f2rb2mp3 help ; return 1 ;}
    verb="chkwrn"
    verb2="chkwrn"
    verb3="chkwrn"
    local q='' vn='' vc=''
    local ssec='' tsec=''
    local tc='' tn=''
    local cf='' xcf=''
    local f='' c=''
    local out=''
    local infile="$(basename "$1")"
    cd "$(dirname "$1")"
    touch nulltime
    $verb "$infile"
    [ -e "$infile" ] || { chkerr "no input flle $f" ; return 1 ;}
    mkdir -p ./tmp ./loss
    [ -e "./tmp/${infile}.flac" ] || { # make ready the flac for universal read
        $verb                                      "./tmp/${infile}.flac"     
        $verb2    ffmpeg -loglevel 24 -i "$infile" "./tmp/${infile}.flac"     
                  ffmpeg -loglevel 24 -i "$infile" "./tmp/${infile}.flac"   || { chkerr " flack fail ";} ;} # have flack
    [ "$v" ] && { vc="vol $v dither" vn="-v$v" ;} || true
    [ "$t" = '1' -a "$p" = '0' -a "$ss" = '' -a "$to" = '' ] && { # none or volume only change
        $verb                                "./loss/${infile}${vn}.mp3"
        $verb2   sox "./tmp/${infile}.flac"  "./loss/${infile}${vn}.mp3" $vc
                 sox "./tmp/${infile}.flac"  "./loss/${infile}${vn}.mp3" $vc    && return 0 \
          || { chkerr "XXX no flac? vol: sox $infile ./loss/${infile}${vn}.mp3 $vc" ; return 1 ;} ;} # easy mp3 done
    [ "$ss" -o "$to" ] && { # trim
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
        out="${infile}-t${t}-p${p}${f}-c${c}${cf}${tn}"
        [ -e "./loss/${out}${vn}.mp3" ] || { # make if not exists
            [ -e "./tmp/${out}.wav" ] || { # final master sans volume
              $verb "./tmp/${out}.wav"
              $verb2 $rb --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav"  
                     $rb --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav" || { chkerr \
                     $rb --time $t --pitch $p $f --crisp $c $xcf "./tmp/${infile}${tn}.flac" "./tmp/${out}.wav" ; return 1 ;}
              } # final master
            # apply volume and make an mp3 --- some program doesn't respect volume dither so do it last,
            # though maybe to late for clipping
            $verb "./loss/${out}${vn}.mp3"
            $verb2    sox "./tmp/${out}.wav" "./loss/${out}${vn}.mp3" $vc
                      sox "./tmp/${out}.wav" "./loss/${out}${vn}.mp3" $vc \
       || { chkerr "mp3: sox ./tmp/${out}.wav ./loss/${out}${vn}.mp3 $vc" ; return 1 ;}
            } # rb parm
        }  || { # no rb, only time and/or volume
        $verb "./loss/${out}${vn}.mp3"
        $verb2         sox "./tmp/${infile}${tn}.flac" "./loss/${out}${vn}.mp3" $vc
                       sox "./tmp/${infile}${tn}.flac" "./loss/${out}${vn}.mp3" $vc \
          || { chkerr "sox ./tmp/${infile}${tn}.flac ./loss/${out}${vn}.mp3 $vc" ; return 1 ;}
        } # no rb only time and/or volume
    find $PWD -type f -newer ./nulltime | xargs ls -lrth
# convert 5.1 channels to 2
# https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg
#ffmpeg -i Mozart-K622-Clarinet-Concerto-A-Maj-Kam-Honeck-2006.m4a \
#  -af "pan=stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR" \
# cf Mozart-K622-Clarinet-Concerto-A-Maj-Kam-Honeck-2006.m4a.flac
# cf chet baker /Users/geo/dot4/5/d/3/a/4/a/^/parm_sox.sh
    # -ss 32:05 -to 39:58.5
    } # f2rb2mp3





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


