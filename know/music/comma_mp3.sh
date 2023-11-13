#!/usr/bin/env bash
#
# (c) 2023 George Georgalis <george@galis.org> unlimited use with this notice
#
# https://github.com/georgalis/pub/blob/master/know/music/comma_mp3.sh
#
# maintain artist, duration, and meta data of mp3 lists by major sequence, in
# "{dir}/{maj}," (comma files), where dir is ./, or arg1 iff provided, and
# maj is first char of mp3 name, in numlist comma sequence notation, eg
#
# 444,Eva_Cassidy-Autumn_Leaves-Blues_Alley_Jazz_1996_^xXBNlApwh0c.opus-to289.29-ln-parc-v4db.mp3
#

set -e
# exported function requirements from
# https://github.com/georgalis/pub/blob/master/sub/fn.bash
test "$(declare -f base)" # base conversion
test "$(declare -f ts)"   # timestamp generation
[ -d "$1" ] && d="$1"        || true
[ -z "$1" ] && d="$(pwd -P)" || true
cd "$d"

# check for legitimate dir
[ "$(find . -maxdepth 1 -name \*.mp3 | sed -e '/^\.\/[0y]/d')" ] \
  || { chkerr "mp3 files not found in '$PWD'" ;}

# read in or create main header tmpfile ./0,~
[ -e "0," ] && { awk 'NR==1,/^$/ ; {!/^$/}' <"0," >"0,~" ;} \
  || { sed -e '/^0, /!d' -e "s/^/${d##*/}\//" $0 ; printf "$(ts)\n\n" ;} >"0,~" \
      || { chkwrn "unable to create '$PWD/0,~' (637596d5)" ; exit 3 ;}

# probe total mp3 duration data into main header,
# skip on/off ramp (^0|^y) mp3 files
# (filename spaces will havoc)
set $( soxi $(find . -maxdepth 1 -name \*.mp3 | sed -e '/^\.\/[0y]/d') \
    | sed -e '/Duration/!d' -e 's/.*Duration of//' -e 's/Duration[ ]*:/1 file:/' -e 's/ = .*//' -e 's/\...$//' \
    | tail -n1 ) # eg "1 file: 00:06:02" or " 80 files: 05:24:37"
fdur="$*"
{   { printf "$fdur " ; hms2sec "${fdur#*: }" ;} | awk '{printf "%s %s %s sec ","\\\\ "$1,$2,$4}'
      kdb_xs2h $(printf "%x" $(hms2sec "${fdur#*: }")) | sed -e 's/.*(/(/' -e 's/ )/)/'
}  >>"0,~" # human readable

# at each base 32 major character, capture comma header, total duration,
# and per artist sort by duration, to "0,~" and "${maj},~"
for a in {0..31} ; do export n=$(base 32 $a)
  spin2

  [ "$(find . -maxdepth 1 -name ${n}\*.mp3)" ] && \
    { # if there are ${n}\*.mp3 and not on/off ramp, calculate duration, else reset d=''
      expr "$n" : "^[0y]" >/dev/null \
        && d='' \
        || d=$( # major count and duration
              set $(soxi $(find . -maxdepth 1 -name ${n}\*.mp3 ) \
                    | sed -e '/Duration/!d' -e 's/.*Duration of//' -e 's/Duration[ ]*:/1 file:/' -e 's/ = .*//' -e 's/\...$//' \
                    | tail -n1 ) # eg "1 file: 00:06:02" or " 80 files: 05:24:37"
              fdur="$*"
              { printf "${n} $fdur " ; hms2sec "${fdur#*: }" ;} | awk '{printf "%29s %6s %3s %-6s %s sec "," ","  \\"$1"\\",$2,$3,$5}'
              kdb_xs2h $(printf "%x" $(hms2sec "${fdur#*: }")) | sed -e 's/.*(/(/' -e 's/ )/)/'
              )
    # iff there are files (and not on/off ramp), use or create default comma file
    [ "$d" ] && { # init ${n},~ with an existing header
        [ -e "${n}," ] && { awk 'NR==1,/^$/ ; {!/^$/}' <"${n}," >"${n},~" ;} \
          || { # filter default comma header from compost guide 
               { sed -e "/^${n}, /!d" -e "s/^/${PWD##*/}\//" $0 ; printf "$(ts)\n\n" ;} >"${n},~" \
                 || { chkwrn "unable to create '$PWD/${n},~' (643a082d)" ; exit 5 ;} ;}
        echo "$d" >>"${n},~" ;}
    } || d='' # reset, no mp3 begin with n

       #- || { { grep "^${n}, " $0 ; printf "$(ts)\n\n" ;} >"${n},~" \

   find . -maxdepth 1 -name ${n}\*.mp3 | grep -v -- '-' && { chkerr "$0 : missing dash (6510998a)"  ; exit 5;}
   find . -maxdepth 1 -name ${n}\*.mp3 | grep -v , && { chkerr "$0 : missing comma (643b866e)"  ; exit 5;}
   find . -maxdepth 1 -name ${n}\*.mp3 | grep  ',.*,' && { chkerr "$0 : extra comma (643c24eb)"  ; exit 5;}

    [ "$d" ] && { # calculate duration per artist, sort, and write to ${n}
      find . -maxdepth 1 -name ${n}\*.mp3 | while read b ; do spin2
        sed -e 's/.*,//' -e 's/-.*//' <<<"$b"; done | sort -u \
          | while read c; do export c # count and calculate per artist duration
#chkwrn "$PWD/${n}xx,$c"
              spin2
              set $(soxi $(find . -maxdepth 1 -name ${n}\*,${c}\*\.mp3 ) \
                    | sed -e '/Duration/!d' -e 's/.*Duration of//' -e 's/Duration[ ]*:/1 file:/' -e 's/ = .*//' -e 's/\...$//' \
                    | tail -n1 ) # eg "1 file: 00:06:02" or " 80 files: 05:24:37"
              fdur="$*"
              { printf "${c} $fdur " ; hms2sec "${fdur#*: }" ;} | sed -e 's/://' | awk '{printf "%36s %3s %-6s %s sec ",$1,$2,$3,$5}'
              kdb_xs2h $(printf "%x" $(hms2sec "${fdur#*: }")) | sed -e 's/.*(/(/' -e 's/ )/)/'
              done | sort -rnk 4 >>${n},~

        # wrap up and move tmp files to finish
        mv -f "${n},~" "${n},"
        # also write to 0,~
        echo >>"0,~"
        cat   "${n}," >>"0,~"

        } # duration d set per artist c in n from loop a
  done # a (n)
spin2 0

# finish main
mv -f "0,~" "0,"
exit 0

cat >/dev/null <<eof
><> base32 = "0123456789abcdefghjkmnpqrstuvxyz"
><> (sans "ilow")

compost guide, null comma files:

0, prepare
1, hook
2, ingenue
3, bold
4, wisdom
5, orbit
6, reckless
7, pearcing
8, essential
9, next
a, melody
b, run
c, lounge
d, emotion
e, reunion
f, juxtapose
g, reminiscence
h, reverence
i, * gone
j, astonish
k, sustain
l, * late
m, root
n, old
o, * outside
p, spirit
q, ring
r, persue
s, modest
t, simple
u, personal
v, tentative
w, * wide
x, extra
y, exclude
z, end

