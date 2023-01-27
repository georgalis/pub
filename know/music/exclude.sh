#!/usr/bin/env bash

set -e
verb=chktrue
verb2=chkwrn
verb2=devnul


cd "$(dirname $0)"
listd="$(pwd -P)"
mkdir -p "%"

[ "$*" ] || { chkwrn "Available class files:" $(ls class-*.txt | sed -e 's/^class-//' -e 's/\.txt$//') ; exit 0 ;}
mount | grep -q /Volumes/CURATE || { chkerr "$0 $FUNCNAME : no /Volumes/CURATE for exclude" ; exit 1 ;}

r="$(date "+%Y%m%d %H:%M %a %e %b" | tai64n | sed -e 's/^@4[0]*//' -e 's/........ / /')" # eg "63d2e37a 20230126 12:32 Thu 26 Jan"
b="$( echo $* | tr ' ' '\n' | sort -u | sed '/^$/d' | tr '\n' ',' )"                     # eg "arg1,arg2,arg3,"
n="$(awk '{print $2"_release_exclude-"$7}' <<<"$r ${b%%,}")"                             # eg "63d2e37a_release_exclude-arg1,arg2,arg3"
t="$(cd "$listd/%" && mktemp "${n}-XXXXX")"
$verb2 "$listd/%/$t"

{ echo "# $n" ; echo "# $r" ;} >"$listd/%/$t"
for a in $@ ; do 
    cd "$listd"
    [ -f class-${a}.txt ] \
    && {
      cd /Volumes/CURATE/kind
      echo ; echo "# class-${a}.txt"
      awk '!/^$/ {print $1}' "$listd/class-${a}.txt" | sort -u \
        | while read a ; do
           #spin2
            printf " \033[2K%s\r" "$a" 1>&2
            find . -name \*${a}\*mp3 -exec mv \{\} \{\}~ \; 
            echo "$a"
            done | sort
      } >>"$listd/%/$t" || chkwrn "$0 : no file $listd/class-${a}.txt"
    done
#spin2 0
printf "\033[2K\r" 1>&2
mv "$listd/%/$t" "$listd/$n"
chktrue "$listd/$n"

cd /Volumes/CURATE/kind
find . -name \*mp3~ | sort | sed -e 's/$/\r/' >"release_excluded.txt"
chktrue "/Volumes/CURATE/kind/release_excluded.txt"
sed -e 's/$/\r/' "$listd/$n" >"${n}.txt"
chktrue "/Volumes/CURATE/kind/${n}.txt"

cd /Volumes/CURATE/kind &&
    {
    echo "# $n"
    echo "# $r"
    echo
    find . -type f | sed -e '/~$/d' -e 's/$/\r/' | sort
    } >release_include.txt
chktrue /Volumes/CURATE/kind/release_include.txt

