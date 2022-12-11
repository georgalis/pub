#!/usr/bin/env bash

# render potential index changes to each declared volume, or default set
# if first arg is sync, also sync vol(s) to /Volumes/CURATE/kind/ if avail

set -e

dep_help_skel () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/skel/.profile)" <><' 1>&2
    echo 'export -f devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue chkexit logexit validfn' 1>&2 ;}
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
validfn c268584c 00000441
EOF

while IFS= read a ; do
    validfn $a && true || { echo "$0 : validfn error : $a" 1>&2 ; dep_help_sub ; exit 1 ;}
    done <<EOF
ckstat dbe14a8e 000003ae
ckstatsum ddf65d49 00000413
formfile 68be3ca9 00000f51
formfilestats fa92ede0 000004dc
revargs 5db3f9bb 000000a7
spin2 1263edf2 00000180
EOF

ps | grep -E "^[ ]*$$" | grep -q bash   || chkexit "$0 : Not bash"
test -d "$links/"                       || chkexit "$0 : not a directory links='$links'"

f="$0"
infile="${0##*/}"                                              # infile  == basename 0
expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname 0
infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f

gen_index () { # for "$links/$name/"
    mkdir -p html

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
    touch -r "$links/$name/" "${name}.list"

    chktrue ${name}.tab
    local j="/tmp/${FUNCNAME}-$$/second"
    mkdir -p "$j"
    cat ${name}.list | while IFS= read a ; do
        b="$(cd "$j" ; formfile "$a" | sed '/^#/d')"
        sed -e 's/   .*_^/ _^/' -e "s/'//" -e 's/^\(.*\)\( _^.*\)/\2 \1/' -e 's/^\(.*\),\([^ ]*\)/\2 \1 /' <<<"$b" \
            | awk '{printf "%-85s %-18s",$1,$2;$1="";$2="";$3="";print}'
        spin2
        done | sort -f >${name}.tab
    spin2 0
    rm -rf "/tmp/${FUNCNAME}-$$/"
    touch -r "${name}.list" ${name}.tab

    chktrue ${name}.stat.time
    formfilestats $links/$name >${name}.stat.time
    touch -r "${name}.list" ${name}.stat.time
    chktrue ${name}.stat.pitch
    sort -n -t '=' -k 3 ${name}.stat.time >${name}.stat.pitch
    touch -r "${name}.list" ${name}.stat.pitch
    find . -name ${name}.stat.time  -empty -exec rm \{\} \;
    find . -name ${name}.stat.pitch -empty -exec rm \{\} \;

    chktrue ${name}.ckstat
    cat ${name}.list | while IFS= read a ; do
        ckstat    $links/$name/$a | awk -v f="${a##*,}" '{printf ". % 8s % 8s %s %s\n",$2,$3,$4,f}'
      # ckstatsum $links/$name/$a | awk -v f="${a##*,}" '{printf ". % 8s % 8s %s %s\n",$2,$3,$4,f}'
        spin2
        done >${name}.ckstat
    spin2 0
    touch -r "${name}.list" ${name}.ckstat

    chktrue "$links/0/kind/$name"
    rm -rf   "$links/0/kind/$name"
    mkdir -p "$links/0/kind/$name"
    ln "$links/$name/"*mp3 "$links/0/kind/$name"
    touch -r "$links/$name" "$links/0/kind/$name"

    mkdir -p html

    chktrue html/${name}.list.html
    echo '<nobr><ol>' >html/${name}.list.html
    cat ${name}.list \
        | sed -e '
            s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
            s,^,<li>,
            s,$,</li>,
            ' >>html/${name}.list.html
    echo '</ol></nobr>' >>html/${name}.list.html
    touch -r "${name}.list" html/${name}.list.html

    chktrue html/${name}.tab.html
    echo '<nobr><ol>' >html/${name}.tab.html
    cat ${name}.tab | sed '
        s,^,<li>,
        s,_^\([^.]*\)\.,<a href=http://youtu.be/\1>\1</a>.,
        s,$,</li>,
        ' >>html/${name}.tab.html
    echo '</ol></nobr>' >>html/${name}.tab.html
    touch -r "${name}.list" html/${name}.tab.html

    chktrue html/${name}.ckstat.html
    echo '<pre><ol>' >html/${name}.ckstat.html
    cat ${name}.ckstat \
        | sed -e '
            s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
            s,^,<li>,
            s,$,</li>,
            ' >>html/${name}.ckstat.html
    echo '</ol></pre>' >>html/${name}.ckstat.html
    touch -r "${name}.list" html/${name}.ckstat.html

    } # gen_index

check_do_index () { # bypass unchanged
    [ -d "$links/$name/" ] || { chkerr "$0 : not a directory '$links/$name/'" ; return 1 ;}
    [ -e "${name}.list" ] && expr "$(ckstat "${name}.list" | awk '{print $5}' )" '=' "$(ckstat "$links/$name/" | awk '{print $5}' )" >/dev/null \
        && { chktrue "No change, skipping $name" ; return 0 ;} || true # ie return if no change or continue to gen_index
    gen_index
    } # check_do_index

touch_kind_rsync () {
    mount | grep -q /Volumes/CURATE || { chkwrn "$0 : no /Volumes/CURATE for kind/$name" ; return 1 ;}
    mkdir -p "/Volumes/CURATE/kind/$name" || { chkwrn "$0 : cannot create /Volumes/CURATE/kind/$name" ; return 1 ;}
    # Fixup OSX Ventura rsync problem
    # https://discussions.apple.com/thread/254383328
    # https://github.com/WayneD/rsync/issues/412
    cd "$links/0/kind/$name/" \
      && find . -type f -maxdepth 1 -name \*\.mp3 | while IFS= read a ; do
        touch -r "$a" "/Volumes/CURATE/kind/${name}/$a"
        done
    rsync -aPi --delete --delete-excluded --modify-window=1 --include='*mp3' --exclude='*' ./ "/Volumes/CURATE/kind/$name/"
    }

# main

volumes="
5fb3-deja-muse
660e-requeues
5deb-melody-royal
5d50-kindle-class
6344-Ithica
6350-forte-flute
"

volumes="
5fb3-deja-muse    https://github.com/georgalis/pub/blob/master/know/music/5fb3-deja-muse.md
660e-requeues     https://github.com/georgalis/pub/blob/master/know/music/660e-requeues.list
5deb-melody-royal https://github.com/georgalis/pub/blob/master/know/music/5deb-melody-royal.list
5d50-kindle-class https://github.com/georgalis/pub/blob/master/know/music/5d50-kindle-class.list
6344-Ithica       https://github.com/georgalis/pub/blob/master/know/music/6344-Ithica.list
6350-forte-flute  https://github.com/georgalis/pub/blob/master/know/music/6350-forte-flute.list
"

vols="$(awk '!/^$/ {print $1}' <<<"$volumes")"

echo "Volumes:"
awk '!/^$/' <<<"$volumes" | awk '{print NR,$0}'

cd "$inpath"

# if the first arg is sync, do that after gen_index
[ "$1" = "sync" ] && { _sync=y ; shift ;} || { _sync=n ;;}

# always read args
[ "$*" ] && { for name in $* ; do [ -d "$links/$name/" ] && gen_index ; done ;} \
         || { for name in $vols ; do check_do_index ; done ;}

[ "$_sync" = "y" ] && { # if first arg was sync, touch_kind_rsync remaining args, or all vols
    [ "$*" ] && { for name in $* ; do [ -d "$links/$name/" -a -d "$links/0/kind/$name/" ] && touch_kind_rsync ; done ; exit $? ;} \
             || { for name in $vols ; do touch_kind_rsync ; done ; exit $? ;} ;}

exit 0
