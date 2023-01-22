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
chkwrn 2683d3d3 0000005c
logwrn f279f00e 0000005f
chkerr 4f18299d 0000005b
logerr 2db98372 0000005e
chktrue f37189b7 00000060
chkexit e6d9b430 0000005a
logexit 235b98c9 0000005d
validfn c268584c 00000441
EOF

while IFS= read a ; do
    validfn $a && true || { echo "$0 : validfn error : $a" 1>&2 ; dep_help_sub ; exit 1 ;}
    done <<EOF
ckstat 0414a904 000003af
ckstatsum 528c373f 00000409
formfile 25884187 00000fdd
formfilestats fa92ede0 000004dc
revargs 5db3f9bb 000000a7
spin2 1263edf2 00000180
EOF

ps | grep -E "^[ ]*$$" | grep -q bash   || chkexit "$0 : Not bash"
test -d "$links/"                       || chkexit "$0 : not a directory links='$links'"

f="$0"
infile="${f##*/}"                                              # infile  == basename f
expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname f
wdp="$(cd "${inpath}" ; pwd -P)"
infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f
verb="chktrue"
verb2="chkwrn"

gen_index () { # in pwd, for "$links/$name/"
    [ -d "$links/$name" ] && mkdir -p "$wdp/$name" || { chkerr "$FUNCNAME : create \$wdp/\$name from $wdp/$name" ; exit 1 ;}
    t="$(mkdir -p "$wdp/%" && cd "$wdp/%" && mktemp -d "index-XXXX")"

    $verb "$wdp/$name/${name}.list" ; $verb2 tmp "$wdp/%/$t/${name}.list"
    # all mp3 in sequence except beginning with 0 or y
    find "$links/$name/" -maxdepth 1 -type f -name \*mp3 \
        | sed -e "
            s=${links}/${name}[/]*==
            /^y/d
            /^0/d
            " \
        | sort \
        >"$wdp/%/$t/${name}.list"
    touch -r "$links/$name/" "$wdp/%/$t/${name}.list"
    mv "$wdp/%/$t/${name}.list" "$wdp/$name"

    $verb ${name}.tab ; $verb2 tmp "$wdp/%/$t/${name}.tab"
#    local j="/tmp/${FUNCNAME}-$$/2nd/3rd"
#    mkdir -p "$j"
    cat "$wdp/$name/${name}.list" | while IFS= read a ; do
#        b="$(cd "$j" ; formfile "$a" | sed '/^#/d')"
        b="$(formfile "$a" | sed '/^#/d')"
        sed -e 's/   .*_^/ _^/' -e "s/'//" -e 's/^\(.*\)\( _^.*\)/\2 \1/' -e 's/^\(.*\),\([^ ]*\)/\2 \1 /' <<<"$b" \
            | awk '{printf "%-85s %-18s",$1,$2;$1="";$2="";$3="";print}'
        spin2
        done | sort -f >"$wdp/%/$t/${name}.tab"
    spin2 0
    touch -r "$wdp/$name/${name}.list" "$wdp/%/$t/${name}.tab"
    mv "$wdp/%/$t/${name}.tab" "$wdp/$name"
#    rm -rf "/tmp/${FUNCNAME}-$$/"

    $verb ${name}.stat.time ; $verb2 tmp "$wdp/%/$t/${name}.stat.time"
    formfilestats "$links/$name" >"$wdp/%/$t/${name}.stat.time"
    $verb ${name}.stat.pitch ; $verb2 tmp "$wdp/%/$t/${name}.stat.pitch"
    sort -n -t '=' -k 3 "$wdp/%/$t/${name}.stat.time" >"$wdp/%/$t/${name}.stat.pitch"
    touch -r "$wdp/$name/${name}.list" "$wdp/%/$t/${name}.stat.time"

    touch -r "$wdp/$name/${name}.list" "$wdp/%/$t/${name}.stat.pitch"
    mv "$wdp/%/$t/${name}.stat.time" "$wdp/%/$t/${name}.stat.pitch" "$wdp/$name/"
    find . -name "$wdp/$name/${name}.stat.pitch" -empty -exec rm \{\} \;
    find . -name "$wdp/$name/${name}.stat.time"  -empty -exec rm \{\} \;

    $verb ${name}.ckstat ; $verb2 tmp "$wdp/%/$t/${name}.ckstat"
    cat "$wdp/$name/${name}.list" | while IFS= read a ; do
      # ckstat    $links/$name/$a | awk -v f="${a##*,}" '{printf ". . % 8s % 8s %s %s\n",$3,$4,$5,f}'
        ckstatsum $links/$name/$a | awk -v f="${a##*,}" '{printf ". . % 8s % 8s %s %s\n",$3,$4,$5,f}'
        spin2
        done >"$wdp/%/$t/${name}.ckstat~"
    spin2 0
    sort -k 6 "$wdp/%/$t/${name}.ckstat~" >"$wdp/%/$t/${name}.ckstat"
    touch -r "$wdp/$name/${name}.list" "$wdp/%/$t/${name}.ckstat"
    mv "$wdp/%/$t/${name}.ckstat" "$wdp/$name/"

#   mkdir -p html

#   chktrue html/${name}.list.html
#   echo '<nobr><ol>' >html/${name}.list.html
#   cat ${name}.list \
#       | sed -e '
#           s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
#           s,^,<li>,
#           s,$,</li>,
#           ' >>html/${name}.list.html
#   echo '</ol></nobr>' >>html/${name}.list.html
#   touch -r "${name}.list" html/${name}.list.html

#   chktrue html/${name}.tab.html
#   echo '<nobr><ol>' >html/${name}.tab.html
#   cat ${name}.tab | sed '
#       s,^,<li>,
#       s,_^\([^.]*\)\.,<a href=http://youtu.be/\1>\1</a>.,
#       s,$,</li>,
#       ' >>html/${name}.tab.html
#   echo '</ol></nobr>' >>html/${name}.tab.html
#   touch -r "${name}.list" html/${name}.tab.html

#   chktrue html/${name}.ckstat.html
#   echo '<pre><ol>' >html/${name}.ckstat.html
#   cat ${name}.ckstat \
#       | sed -e '
#           s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
#           s,^,<li>,
#           s,$,</li>,
#           ' >>html/${name}.ckstat.html
#   echo '</ol></pre>' >>html/${name}.ckstat.html
#   touch -r "${name}.list" html/${name}.ckstat.html

    chktrue "$links/$name/*mp3 $links/0/kind/$name/"
    rm -rf   "$links/0/kind/$name"
    mkdir -p "$links/0/kind/$name"
    ln "$links/$name/"*mp3 "$links/0/kind/$name"
    # purge staging (0*) and offramp (y*) mp3
    rm -f "$links/0/kind/$name/"0*mp3 "$links/0/kind/$name/"y*mp3
    touch -r "$links/$name" "$links/0/kind/$name"

    rm -rf "$wdp/%/$t/"
    } # gen_index

check_do_index () { # bypass unchanged
    [ -d "$links/$name/" ] || { chkerr "$0 : not a directory '$links/$name/'" ; return 1 ;}
    # if listing time is different than dir time, gen_index
    [ -e "$wdp/$name/${name}.list" ] && expr "$(ckstat "$wdp/$name/${name}.list" | awk '{print $5}' )" '=' "$(ckstat "$links/$name/" | awk '{print $5}' )" >/dev/null \
        && { chktrue "No change, skipping $name" ; return 0 ;} || true # ie return if no change or continue to gen_index
    gen_index
    } # check_do_index

kind_curate_rsync () { # rsync $links/0/kind/$name/ 
chkwrn $FUNCNAME
    [ -d "$links/0/kind/$name/" ] || { chkerr "$0 $FUNCNAME : no source $links/0/kind/$name/" ; exit 1 ;}
    mount | grep -q /Volumes/CURATE || { chkwrn "$0 : no /Volumes/CURATE for kind/$name" ; return 1 ;}
    mkdir -p "/Volumes/CURATE/kind/$name" || { chkwrn "$0 : cannot create /Volumes/CURATE/kind/$name" ; return 1 ;}
    # Fixup OSX Ventura rsync problem (sets timestamp to transfer time vs orig file time, to ms-dos filesystems)
    # https://discussions.apple.com/thread/254383328
    # https://github.com/WayneD/rsync/issues/412
    # touch after to avoid need to create directories for recursive
         # mkdir -p $(dirname "/Volumes/CURATE/kind/${name}/$a"
    cd "$links/0/kind/$name/" \
      && {
chkwrn "$FUNCNAME : $links/0/kind/$name/ /Volumes/CURATE/kind/$name/"
        rsync -aP --delete --delete-excluded --modify-window=1 --include='*mp3' --exclude='*' ./ "/Volumes/CURATE/kind/$name/" \
            | grep -v 'sending incremental'
        find . -type f -maxdepth 1 -name \*\.mp3 -exec touch -r \{\} "/Volumes/CURATE/kind/${name}/"\{\} \;
        }
    } # kind_curate_rsync

doc2html2curate () { # include a doc file with volume (and make html if it is md)
chkwrn $FUNCNAME
    doc="$(sed -e "/^$name/!d" -e 's=.*/==' <<<"$volumes")"
    [ -f "$wdp/$doc" ] && {
      chkerr "$wdp/$doc /Volumes/CURATE/kind/" 
      expr "$doc" : ".*\.md$" >/dev/null && awk -f $HOME/sub/markdown.awk "$wdp/$doc" >"$wdp/${doc}.html" || true 
      touch -r "$wdp/$doc" "$wdp/${doc}.html"
      rsync -aP --modify-window=1 "$wdp/$doc" "$wdp/${doc}.html" "/Volumes/CURATE/kind/" \
        | grep -v 'sending incremental'
      touch -r "$wdp/$doc" "/Volumes/CURATE/kind/$doc" "/Volumes/CURATE/kind/${doc}.html" ;}
    [ -d "$links/$name/" -a -d "$links/0/kind/$name/" ] && kind_curate_rsync "$name"
    return $? ;} 

readme2html2curate () {
chkwrn $FUNCNAME
chkerr "$wdp/README.md" "/Volumes/CURATE/kind/README.md" "/Volumes/CURATE/kind/README.md.html"

    [ -f "$wdp/README.md" ] && {
      chktrue "$wdp/README.md /Volumes/CURATE/kind/"
      expr "$index" : ".*\.md$" >/dev/null && awk -f $HOME/sub/markdown.awk "$wdp/$index" >"$wdp/${index}.html" || true 
      touch -r "$wdp/$index" "$wdp/${index}.html"
      rsync -aP --modify-window=1 "$wdp/README.md" "$wdp/README.md.html" "/Volumes/CURATE/kind/" \
        | grep -v 'sending incremental'
      touch -r "$wdp/README.md" "/Volumes/CURATE/kind/README.md" "/Volumes/CURATE/kind/README.md.html" ;}
    }


# main

cd "$wdp"
chkwrn "$wdp"

volumes="
5fb3-deja-muse    https://github.com/georgalis/pub/blob/master/know/music/5fb3-deja-muse.md
660e-requeues     https://github.com/georgalis/pub/blob/master/know/music/660e-requeues.list
5deb-melody-royal https://github.com/georgalis/pub/blob/master/know/music/5deb-melody-royal.list
5d50-kindle-class https://github.com/georgalis/pub/blob/master/know/music/5d50-kindle-class.list
6344-Ithica       https://github.com/georgalis/pub/blob/master/know/music/6344-Ithica.list
6350-forte-flute  https://github.com/georgalis/pub/blob/master/know/music/6350-forte-flute.list
63aa-bee-piano    https://github.com/georgalis/pub/blob/master/know/music/63aa-bee-piano.list
"

vols="$(awk '!/^$/ {print $1}' <<<"$volumes")"

chktrue "Volumes:"
awk '!/^$/' <<<"$volumes" | awk '{print " ",NR,$0}'

# if the first arg is sync, do that after gen_index
[ "$1" = "sync" ] && { _sync=y ; shift ;} || { _sync=n ;}

# always gen_index for args, OR iff no args, as needed from vols
[ "$*" ] && { for name in $*    ; do gen_index      ; done ;} \
         || { for name in $vols ; do check_do_index ; done ;}

chkerr "$*"
# if first arg was sync, 
[ "$_sync" = "y" ] && { # kind_curate_rsync remaining args, OR all volumess if null
    [ "$*" ] \
        && { # gen html and rsync @ arg
            for name in $*    ; do doc2html2curate ; done ; readme2html2curate ;} \
        || { # gen html and rsync for all volumes
            for name in $vols ; do doc2html2curate ; done ; readme2html2curate ;}
        }
chktrue "no sync requested"
exit 0

