#!/usr/bin/env bash

set -e 

dep_help_skel () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/skel/.profile)" <><' 1>&2
    echo 'export -f devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue chkexit logexit siff siffx validfn' 1>&2 ;}
dep_help_sub () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/sub/fn.bash)" <><' 1>&2
    echo 'export -f ckstatsum ckstat revargs formfile formfilestats' 1>&2 ;}

test "$(declare -f validfn 2>/dev/null)" || { echo "$0 : validfn not defined" 1>&2 ; dep_help_skel ; exit 1 ;}
while IFS= read a ; do
    validfn $a && true || { echo "$0 : validfn error : $a" 1>&2 ; dep_help_skel ; exit 1 ;}
    done <<EOF
devnul 216e1370 0000001d
stderr 7ccc5704 00000037
chkstd ee4aa465 00000032
chkwrn 18c46093 0000005e
logwrn e5806086 00000061
chkerr 57d3ff82 0000005f
logerr ffddd972 00000062
chktrue 845489dd 00000064
chkexit 8b52b10f 0000005e
logexit e0f87299 00000061
siff f376bdf0 0000010e
siffx 6596996d 00000294
validfn a25e6c28 00000445
EOF

while IFS= read a ; do
    validfn $a && true || { echo "$0 : validfn error : $a" 1>&2 ; dep_help_sub ; exit 1 ;}
    done <<EOF
ckstat ea8f5074 00000379
ckstatsum 94662c65 000003e1
formfile 63bac740 00000e64
formfilestats fdf4e379 00000498
revargs 5db3f9bb 000000a7
EOF

ps | grep -E "^[ ]*$$" | grep -q bash   || chkexit "$0 : Not bash" 
test -d "$link"                         || chkexit "$0 : not a directory link='$link'"

f="$0"
infile="${f##*/}"                                              # infile  == basename f
expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname f
infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f
name="$(sed 's/.[^.]*$//' <<<"$infile")" # infile less any dotted extension

cd "$inpath"

chktrue "${name}.list"
find "$link/" -maxdepth 1 -type f -name \*mp3 \
    | sed -e "s=${link}[/]*==" -e '/^0/d' \
    | sort \
    >"${name}.list"
  # | head -n40 >"${name}.list"

chktrue ${name}.list.html
echo '<nobr><ol>' >${name}.list.html
cat ${name}.list \
    | sed -e '
        s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
        s,^,<li>,
        s,$,</li>,
        ' >>${name}.list.html
echo '</ol></nobr>' >>${name}.list.html

chktrue ${name}.tab
cat ${name}.list | while IFS= read a ; do
    b="$(formfile "$a")"
    {   revargs $(sed 's/.*f2rb2mp3//'  <<<"$b")
        sed "s/f2rb2mp3 '.*//" <<<"$b"
    } | tr '\n' ' '
    echo
    done \
    | sed -e 's/,/%/' -e "s/ '_^/%_^/" -e "s/' /%/" \
    | awk -F% '{printf "%5s %-79s %-19s %s\n",$1,$2,$3,$4}' \
    | sort -f -k2 >${name}.tab

chktrue ${name}.tab.html
echo '<nobr><ol>' >${name}.tab.html
cat ${name}.tab | sed '
    s,^,<li>,
    s,_^\([^.]*\)\.,<a href=http://youtu.be/\1>\1</a>.,
    s,$,</li>,
    ' >>${name}.tab.html
echo '</ol></nobr>' >>${name}.tab.html

chktrue ${name}.stat.time
formfilestats $link >${name}.stat.time
chktrue ${name}.stat.pitch
sort -n -t '=' -k 3 ${name}.stat.time >${name}.stat.pitch

chktrue ${name}.sum
ls $link/*mp3 | sed -e '/\/0/d' \
    | while read a ;do 
        ckstat    $a | awk -v f="${a##*/}" '{printf "%9s %s % 8s %s %s\n",$1,$2,$3,$4,f}'
        done >${name}.sum
      # don't calculate all the cksums, prior to final
      # ckstatsum $a | awk -V f="${a##*/}" '{printf "%9s %s % 8s %s %s\n",$1,$2,$3,$4,f}'

exit 0

chktrue ${name}.sum.html
echo '<pre><ol>' >${name}.sum.html
cat ${name}.sum \
    | sed -e '
        s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
        s,^,<li>,
        s,$,</li>,
        ' >>${name}.sum.html
echo '</ol></pre>' >>${name}.sum.html

