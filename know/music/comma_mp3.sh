#!/usr/bin/env bash

#########
#
# maintain numlist audio duration data in "{dir}/0/{maj}," (comma files)
# where dir is ./, or arg1 iff provided, and maj is first char of mp3s
# named by comma sequence notation, eg
#
# 444,Eva_Cassidy-Autumn_Leaves-Blues_Alley_Jazz_1996_^xXBNlApwh0c.opus-to289.29-ln-parc-v4db.mp3
#

#########
#
# main
#

set -e
test -x $(which base)
[ -d "$1" ] && d="$1"        || true
[ -z "$1" ] && d="$(pwd -P)" || true
cd "$d"

# read in or create main header tmpfile ./0,~
[ -e "0/0," ] && awk 'NR==1,/^$/ ; {!/^$/}' <"0/0," >"0/0,~" \
  || { mkdir -p "0" && echo "original" >"0/0,~" || \
        chkerr "unable to create '$PWD/0/0,~' (637596d5)" ; exit 1 ;}

# probe total mp3 duration data into main header, skip on/off ramp (^0|^y) mp3 files (filename spaces will havoc)
set $(soxi $(find . -maxdepth 1 -name \*.mp3 | sed -e '/^\.\/[0y]/d' | head -n 20000) \
    | sed -e '/Duration/!d' -e 's/.*Duration of//' -e 's/Duration[ ]*:/1 file:/' -e 's/ = .*//' -e 's/\...$//' \
    | tail -n1 ) # eg "Duration of 63 files: 04:32:15" or "Duration : 00:08:58"
a2=$*
{   { printf "$a2 " ; hms2sec "${a2#*: }" ;} | awk '{printf "%s %s %s sec ","\\\\ "$1,$2,$4}'
      kdb_xs2h $(printf "%x" $(hms2sec "${a2#*: }")) | sed -e 's/.*(/(/' -e 's/ )/)/'
}  >>"0/0,~" # human readable
cat "0/0,~" 1>&2
#chkwrn "probe 20000 mp3 duration"

#chkwrn "major"
# at each base 32 major character,
#   capture comma header, total duration, and per artist sort by duration , to "0/0,~" and "0/${maj},~"
for a in {0..31} ; do export n=$(base 32 $a)
#printf " $n" 2>&1

  [ "$(find . -maxdepth 1 -name ${n}\*.mp3)" ] && \
    { # if there are ${n}\*.mp3, if not on/off ramp, calculate duration else set d=''
      expr "$n" : "^[0y]" >/dev/null \
        && d='' \
        || d=$( # major count and duration
              set $(soxi $(find . -maxdepth 1 -name ${n}\*.mp3 ) \
                    | sed -e '/Duration/!d' -e 's/.*Duration of//' -e 's/Duration[ ]*:/1 file:/' -e 's/ = .*//' -e 's/\...$//' \
                    | tail -n1 ) # eg "Duration of 63 files: 04:32:15" or "Duration : 00:08:58"
              a2=$*
              { printf "${n} $a2 " ; hms2sec "${a2#*: }" ;} | awk '{printf "%29s %6s %3s %-6s %s sec "," ","  \\"$1"\\",$2,$3,$5}'
              kdb_xs2h $(printf "%x" $(hms2sec "${a2#*: }")) | sed -e 's/.*(/(/' -e 's/ )/)/'
              )
    } || d='' # reset when some n have no mp3

#chkwrn ddd $d
#^^^ ddd 63 files: 16335 sec (4 h 32 m 15 s)
#^^^ ddd 1 file: 362 sec (6 m 2 s)

    [ "$d" ] && { # init 0/${n},~ with the major duration
        [ -e "0/${n}," ] \
            && { awk 'NR==1,/^$/ ; {!/^$/}' <"0/${n}," >"0/${n},~" ;} \
            || printf "original\n\n" >"0/${n},~" 
        echo "$d" >>"0/${n},~" ;}
#chkwrn "$n comma file duration"

    [ "$d" ] && { # if duration, calculate per artist, and write to 0/${n},~ and 0/0,~
      find . -maxdepth 1 -name ${n}\*.mp3 | while read b ; do
        sed -e 's/.*,//' -e 's/-.*//' <<<"$b"; done | sort -u \
          | while read c; do export c # artist
# printf "$(tput el1)$n $c" 1>&2
              # artist count and duration
              set $(soxi $(find . -maxdepth 1 -name ${n}\*,${c}\*\.mp3 ) \
                    | sed -e '/Duration/!d' -e 's/.*Duration of//' -e 's/Duration[ ]*:/1 file:/' -e 's/ = .*//' -e 's/\...$//' \
                    | tail -n1 ) # eg "Duration of 63 files: 04:32:15" or "Duration : 00:08:58"
              a2=$*
              { printf "${c} $a2 " ; hms2sec "${a2#*: }" ;} | sed -e 's/://' | awk '{printf "%36s %3s %-6s %s sec ",$1,$2,$3,$5}'
              kdb_xs2h $(printf "%x" $(hms2sec "${a2#*: }")) | sed -e 's/.*(/(/' -e 's/ )/)/'
#chkwrn "$a2 = $(hms2sec "${a2#*: }")"

#chkwrn "$d $(hms2sec "${a2#*: }")"
#chkwrn "major $n artist $c duration $d"

#             d=$(soxi $(find . -maxdepth 1 -name ${n}\*,${c}\*\.mp3) \
#                   | sed -e '/Duration/!d' -e 's/.*: //' -e 's/ = .*//' -e 's/\..*//' | tail -n1)
#             echo "     $c $d $(kdb_xs2h $(printf "%x" $(hms2sec "$d")))" # major, artist, human readable time
              done | sort -rnk 4 >>0/${n},~
        mv -f 0/${n},~ 0/${n},
#chkwrn "0/${n},+"

        cat "0/${n},+" >>"0/0,~"
        echo >>"0/0,~"
echo 2>&1
cat "0/${n},+" 2>&1
        } # duration d set per artist c in n from loop a
  done # n
#tput el1 1>&2
mv -f "0/0,~" "0/0,"  
exit 0
