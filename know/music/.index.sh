#!/usr/bin/env bash

# render potential index changes to each declared volume

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
validfn 75f606c4 00000442
EOF

while IFS= read a ; do
    validfn $a && true || { echo "$0 : validfn error : $a" 1>&2 ; dep_help_sub ; exit 1 ;}
    done <<EOF
ckstat cf2d2b8d 000003ab
ckstatsum 0d078cff 00000401
formfile c179f567 00000f48
formfilestats b4d551f2 000004b1
revargs 5db3f9bb 000000a7
spin2 1263edf2 00000180
EOF

ps | grep -E "^[ ]*$$" | grep -q bash   || chkexit "$0 : Not bash"
test -d "$links/"                       || chkexit "$0 : not a directory links='$links'"

cat >/dev/null <<EOF
1. The first volume is [5fb3-deja-muse](https://github.com/georgalis/pub/blob/master/know/music/5fb3-deja-muse.md)
1. The second volume is [660e-requeues](https://github.com/georgalis/pub/blob/master/know/music/660e-requeues.list)
1. The third volume is [5deb-melody-royal](https://github.com/georgalis/pub/blob/master/know/music/5deb-melody-royal.list)
1. The fourth volume is [5d50-kindle-class](https://github.com/georgalis/pub/blob/master/know/music/5d50-kindle-class.list)
1. A fifth volume [6344-Ithica](https://github.com/georgalis/pub/blob/master/know/music/6344-Ithica.list)
EOF

f="$0"
infile="${0##*/}"                                              # infile  == basename 0
expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname 0
infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f

gen_index () {
    chktrue "${name}.list"
    # all mp3 in sequence except beginning with 0 or y
    find "$links/$name/" -maxdepth 1 -type f -name \*mp3 \
        | sed -e "
            s=${links}/${name}[/]*==
            /^y/d
            /^0/d
            " \
        | sort \
        >"${name}.list"

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
        b="$(formfile "$a" | sed '/^#/d')"
        revargs $(sed -e 's/   .*_^/ _^/' -e "s/'//" <<<"$b") \
            | sed 's/,/ /' \
            | awk '{printf "% 3s %-80s %-18s",$1,$2,$3 ; $1="";$2="";$3="" ; print }'
        spin2
        done | sort -f -k2 >${name}.tab
    spin2 0

    chktrue ${name}.tab.html
    echo '<nobr><ol>' >${name}.tab.html
    cat ${name}.tab | sed '
        s,^,<li>,
        s,_^\([^.]*\)\.,<a href=http://youtu.be/\1>\1</a>.,
        s,$,</li>,
        ' >>${name}.tab.html
    echo '</ol></nobr>' >>${name}.tab.html

    chktrue ${name}.stat.time
    formfilestats $links/$name >${name}.stat.time
    chktrue ${name}.stat.pitch
    sort -n -t '=' -k 3 ${name}.stat.time >${name}.stat.pitch

    chktrue ${name}.ckstat
    cat ${name}.list | while IFS= read a ; do
      # ckstat    $links/$name/$a | awk -v f="${a##*/}" '{printf ". . % 8s %s %s\n",$3,$4,f}'
        ckstatsum $links/$name/$a | awk -v f="${a##*/}" '{printf ". . % 8s %s %s\n",$3,$4,f}'
        spin2
        done >${name}.ckstat
    spin2 0

    chktrue ${name}.ckstat.html
    echo '<pre><ol>' >${name}.ckstat.html
    cat ${name}.ckstat \
        | sed -e '
            s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
            s,^,<li>,
            s,$,</li>,
            ' >>${name}.ckstat.html
    echo '</ol></pre>' >>${name}.ckstat.html
    } # gen_index

check_do_index () { # bypass unchanged
    [ -d "$links/$name/" ] || { chkerr "$0 : not a directory '$links/$name/'" ; return 1 ;}
    [ -e "${name}.list" ] && [ "${name}.list" -nt "$links/$name/" ] && { chktrue "Skipping $name" ; return 0 ;}
    gen_index
    } # check_do_index

# main

volumes="
5fb3-deja-muse
660e-requeues
5deb-melody-royal
5d50-kindle-class
6344-Ithica
"

[ "$1" ] && volumes="$1"

cd "$inpath"
for name in $volumes ; do
    check_do_index
    done # name in $volumes

exit 0
