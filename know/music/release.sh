#!/usr/bin/env bash

# render potential index changes to each declared volume, or default set
# if first arg is sync, also sync vol(s) to /Volumes/CURATE/kind/ if avail

set -e

dep_help_skel () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/skel/.profile)" <><' 1>&2
    echo 'export -f devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue chkexit logexit validfn' 1>&2 ;}
dep_help_sub () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/sub/fn.bash)" <><' 1>&2
    echo 'export -f ckstatsum ckstat formfile formfilestats spin2' 1>&2 ;}

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
chkexit e6d9b430 0000005a
logexit 235b98c9 0000005d
chktrue 28662120 00000060
validfn 8f5ab2a4 0000046c
EOF

while IFS= read a ; do
    validfn $a && true || { echo "$0 : validfn error : $a" 1>&2 ; dep_help_sub ; exit 1 ;}
    done <<EOF
ckstat 36acea2a 000003b2
ckstatsum 9b617c6f 0000040c
formfile 22029e47 00000fda
formfilestats fa92ede0 000004dc
spin2 1263edf2 00000180
EOF

[ -e $HOME/sub/markdown.awk ] || { echo "$0 : markdown.awk not found" 1>&2 ; dep_help_sub ; exit 1 ;}

ps | grep -E "^[ ]*$$" | grep -q bash || chkexit "$0 : Not bash"
test -d "$links"                      || chkexit "$0 : not a directory links='$links'"
export links # we will need it in sub-shells and pipelines

f="$0"
infile="${f##*/}"                                              # infile  == basename f
expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname f
wdp="$(cd "${inpath}" ; pwd -P)"
infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f
mkdir -p "$wdp/%"
t="$(cd "$wdp/%" && mktemp -d "${infile}-XXXXX")"
PATH=$wdp:$PATH
verb="chktrue"
verb2="chkwrn"
verb2="devnul"

while IFS= read a ; do
    validex $a && true || { echo "$0 : validex error : $a (643eb771)" 1>&2 ; exit 2 ;}
    done <<EOF
comma_mp3.sh afb161ed 000013b3
EOF

gen_index () { # in pwd, for "$links/$name/"
    $verb $links/$name ; $verb2 "$links/$name" "$wdp/$name"
    [ -d "$links/$name" ] && mkdir -p "$wdp/$name" || { chkerr "$FUNCNAME : create \$wdp/\$name from $wdp/$name" ; exit 1 ;}

    $verb ${name}.list ; $verb2 tmp "$wdp/%/$t/${name}.list"
    # all mp3 in sequence except beginning with 0 or y
    find "$links/$name/" -maxdepth 1 -type f -name \*mp3 \
        | sed -e "
            s=${links}/${name}[/]*==
            /^y/d
            /^0/d
            " \
        | sort >"$wdp/%/$t/${name}.list"
    touch -r "$links/$name/" "$wdp/%/$t/${name}.list"
    mv "$wdp/%/$t/${name}.list" "$wdp"

    $verb ${name}.view ; $verb2 $(which comma_mp3.sh) "$links/$name/"
    comma_mp3.sh "$links/$name"
    cp -f "$links/$name/0," $wdp/${name}.view
    touch -r "$wdp/${name}.list" $wdp/${name}.view "$links/$name"

#   $verb ${name}.tab ; $verb2 tmp "$wdp/%/$t/${name}.tab"
#   cat "$wdp/${name}.list" | while IFS= read a ; do
#       b="$(formfile "$a" | sed '/^#/d')"
#       sed -e 's/   .*_^/ _^/' -e "s/'//" -e 's/^\(.*\)\( _^.*\)/\2 \1/' -e 's/^\(.*\),\([^ ]*\)/\2 \1 /' <<<"$b" \
#           | awk '{printf "%-85s %-18s",$1,$2;$1="";$2="";$3="";print}'
#       spin2
#       done | sort -f >"$wdp/%/$t/${name}.tab"
#   spin2 0
#   touch -r "$wdp/${name}.list" "$wdp/%/$t/${name}.tab"
#   mv "$wdp/%/$t/${name}.tab" "$wdp/$name"

    $verb ${name}.stat.time ; $verb2 tmp "$wdp/%/$t/${name}.stat.time"
    formfilestats "$links/$name" >"$wdp/%/$t/${name}.stat.time"
    $verb ${name}.stat.pitch ; $verb2 tmp "$wdp/%/$t/${name}.stat.pitch"
    sort -n -t '=' -k 3 "$wdp/%/$t/${name}.stat.time" >"$wdp/%/$t/${name}.stat.pitch"
    touch -r "$wdp/${name}.list" "$wdp/%/$t/${name}.stat.time" "$wdp/%/$t/${name}.stat.pitch"
    mv "$wdp/%/$t/${name}.stat.time" "$wdp/%/$t/${name}.stat.pitch" "$wdp/$name/"
    find . -name "$wdp/$name/${name}.stat.pitch" -empty -exec rm \{\} \;
    find . -name "$wdp/$name/${name}.stat.time"  -empty -exec rm \{\} \;

    $verb ${name}.ckstat ; $verb2 tmp "$wdp/%/$t/${name}.ckstat"
    cat "$wdp/${name}.list" | while IFS= read a ; do
        ckstat    $links/$name/$a | awk -v f="${a##*,}" '{printf ". . % 8s % 8s %s %s\n",$3,$4,$5,f}'
      # ckstatsum $links/$name/$a | awk -v f="${a##*,}" '{printf ". . % 8s % 8s %s %s\n",$3,$4,$5,f}'
        spin2
        done >"$wdp/%/$t/${name}.ckstat~"
    spin2 0
    sort -k 6 -u "$wdp/%/$t/${name}.ckstat~" >"$wdp/%/$t/${name}.ckstat"
    touch -r "$wdp/${name}.list" "$wdp/%/$t/${name}.ckstat"
    mv "$wdp/%/$t/${name}.ckstat" "$wdp/$name/"

   $verb "${name}{.view,.list,.md,/*mp3} $links/0/kind/"
   rm -rf   "$links/0/kind/${name}"*
   mkdir -p "$links/0/kind/${name}"
   ln "$links/$name/"*mp3 "$links/0/kind/$name/"
   # purge staging (0*) and offramp (y*) mp3
   rm -f "$links/0/kind/$name/"0*mp3 "$links/0/kind/$name/"y*mp3
   sed -e 's/$/\r/' "$music/${name}.list" >"$wdp/%/$t/${name}.list.txt"
   sed -e 's/$/\r/' "$music/${name}.view" >"$wdp/%/$t/${name}.view.txt"
   touch -r "$links/$name" "$wdp/%/$t/${name}.list.txt" "$wdp/%/$t/${name}.view.txt"
   mv "$wdp/%/$t/${name}.list.txt" "$wdp/%/$t/${name}.view.txt" "$links/0/kind/"
   touch -r "$links/$name" "$links/0/kind/${name}"*
    } # gen_index

check_gen_index () { # gen_index iff diff
    $verb $FUNCNAME  ; $verb2 "$links/0/kind/$name/ /Volumes/CURATE/kind/$name/"
    [ -d "$links/$name/" ] || { chkerr "$0 $FUNCNAME : not a directory '$links/$name/'" ; exit 1 ;}
    # if listing time is different than dir time, gen_index
    [ -e "$wdp/${name}.list" ] \
        && expr "$(ckstat "$wdp/${name}.list" | awk '{print $5}' )" '=' "$(ckstat "$links/$name/" | awk '{print $5}' )" >/dev/null \
        && { $verb "No change, skipping $name" ; return 0 ;} # ie return if no change or continue
    gen_index
    } # check_gen_index

kind_curate_rsync () { # rsync $links/0/kind/$name/
    $verb $FUNCNAME  ; $verb2 "$links/0/kind/$name/ /Volumes/CURATE/kind/$name/"
    [ -d "$links/0/kind/$name/" ]         || { chkerr "$0 $FUNCNAME : no source $links/0/kind/$name/" ; exit 1 ;}
    mount | grep -q /Volumes/CURATE       || { chkerr "$0 $FUNCNAME : no /Volumes/CURATE for kind/$name" ; exit 1 ;}
    mkdir -p "/Volumes/CURATE/kind/$name" || { chkwrn "$0 $FUNCNAME : cannot create /Volumes/CURATE/kind/$name" ; exit 1 ;}
    # Fixup OSX Ventura rsync problem (sets timestamp to transfer time vs orig file time, to ms-dos filesystems)
    # https://discussions.apple.com/thread/254383328
    # https://github.com/WayneD/rsync/issues/412
    rsync -aP --delete --modify-window=1 $links/0/kind/${name}* "/Volumes/CURATE/kind/" \
        | grep -vE '((^sending|^sent|^total) |^$|^\./$)' || true
#       cd $links/0/kind/ && find . -type f -path "./${name}*" -exec touch -r \{\} "/Volumes/CURATE/kind/"\{\} \;
    } # kind_curate_rsync

doc2html2kind () { # include a doc file with volume (and make html if it is md)
    $verb2 $FUNCNAME  ; $verb2 "$links/0/kind/$name/ /Volumes/CURATE/kind/$name/"
    local doco='' doc="$(sed -e "/^$name/!d" -e 's=.*/==' <<<"$volumes")"
    [ -f "$HOME/sub/markdown.awk" ] || { chkerr "$0 $FUNCNAME : no markdown.awk" ; exit 1 ;}
    [ "${doc##*.}" = "md"   ] && { doco="${doc}.html"
        $verb $links/0/kind/$doco
        awk -f $HOME/sub/markdown.awk <"$wdp/$doc" >"$wdp/%/$t/$doco"
        touch -r "$wdp/$doc" "$wdp/%/$t/$doco"
        $verb2 doco "$wdp/%/$t/$doco" "$links/0/kind/"
        rsync -av   "$wdp/%/$t/$doco" "$links/0/kind/" \
                | grep -vE '((^sending|^sent|^total) |^$|^\./$)' || true ;} \
        || true # doc is not md... view and list files were copied to kind with gen_index
    } # doc2html2kind

readme2html2kind () {
    $verb $FUNCNAME  ; $verb2 "$wdp/README.md" "$links/0/kind/README.md.html" #         "/Volumes/CURATE/kind/README.md.html"
    [ -f "$HOME/sub/markdown.awk" ] || { chkerr "$0 $FUNCNAME : no markdown.awk" ; exit 1 ;}
    [ -f "$wdp/README.md" ]         || { chkerr "$0 $FUNCNAME : no $wdp/README.md" ; exit 1 ;}
    awk -f $HOME/sub/markdown.awk "$wdp/README.md" >"$wdp/%/$t/README.md.html"
    touch -r "$wdp/README.md" "$wdp/%/$t/README.md.html"
    rsync -av "$wdp/%/$t/README.md.html" "$links/0/kind/README.md.html" \
            | grep -vE '((^sending|^sent|^total) |^$|^\./$)' || true
    } # readme2html2kind

kindreadme2curate () {
    mount | grep -q /Volumes/CURATE       || { chkerr "$0 $FUNCNAME : no /Volumes/CURATE for kind/$name" ; exit 1 ;}
    mkdir -p /Volumes/CURATE/kind || { chkerr "$0 $FUNCNAME : cannot create /Volumes/CURATE/kind" ; exit 1 ;}
      rsync -av "$links/0/kind/README.md.html" "/Volumes/CURATE/kind/README.md.html" \
            | grep -vE '((^sending|^sent|^total) |^$|^\./$)' || true
#     touch -r  "$links/0/kind/README.md.html" "/Volumes/CURATE/kind/README.md.html" # https://discussions.apple.com/thread/254383328
    } # kindreadme2curate

# main

# disable mac spolight on usb drives
# [ "$(which mdutil 2>/dev/null)" ] \
#     && { # unspotlight
#         $verb disabling Spolight on removable media
#         for a in '/Volumes/CURATE' '/Volumes/NO NAME' ; do
#           mount | grep " on $a " >/dev/null && mdutil -i off "$a"
#              # mdutil -X "$a" # removing index data requires root
#           done # mac mounted (CURATE|NO NAME) volumes
#        } # is a mac
mount | grep /Volumes/CURATE >/dev/null \
    && {
#      test -f /Volumes/CURATE/.metadata_never_index || touch $_ # doesn't help on ventura
       test -e /Volumes/CURATE/.Spotlight-V100 -o -e /Volumes/CURATE/.fseventsd \
         && chkwrn "turn off and remove spolight: sudo mdutil -i off -dEX /Volumes/CURATE/"
       }

# if arg1 is cache, only sync the cache and exit
[ "$1" = 'cache' ] \
    && {
       test -d  "$links/0/6400-cache/" || { chkerr "$0 $FUNCNAME : no local $links/0/6400-cache/" ; exit 1 ;}
#      test -f "$links/0/6400-cache/.metadata_never_index" \
#       || {
#           touch -r "$links/0/6400-cache/" "$links/0/6400-cache/.metadata_never_index"
#           touch -r "$links/0/6400-cache/.metadata_never_index" "$links/0/6400-cache/"
#          }
       find "$links/0/6400-cache/" -type f -name \*mp3 \
        | sed -e "s=^${links}/0/6400-cache[/]*==" \
        | sort >"$wdp/%/6400-cache.list"
       sed -e 's/$/\r/' "$wdp/%/6400-cache.list" >"$wdp/%/6400-cache.list.txt"
       touch -r "$links/0/6400-cache/" "$wdp/%/6400-cache.list"
       touch -r "$links/0/6400-cache/" "$wdp/%/6400-cache.list.txt"
       mv "$wdp/%/6400-cache.list" "$wdp"
       mount | grep -q /Volumes/CURATE       || { chkerr "$0 $FUNCNAME : no /Volumes/CURATE for cache" ; exit 1 ;}
#      test -e /Volumes/CURATE/.metadata_never_index || touch $_
       set -x
       rsync -av --delete --modify-window=1 $links/0/6400-cache/ "/Volumes/CURATE/6400-cache/"
       mv -f "$wdp/%/6400-cache.list.txt" "/Volumes/CURATE/"
       #  | grep -vE '((^sending|^sent|^total) |^$)'
       exit $?
       }

$verb $0 $*
$verb "$wdp"
cd "$wdp"

volumes="
5fb3-deja-muse    https://github.com/georgalis/pub/blob/master/know/music/5fb3-deja-muse.md
63d2-requeues     https://github.com/georgalis/pub/blob/master/know/music/63d2-requeues.list
5deb-melody-royal https://github.com/georgalis/pub/blob/master/know/music/5deb-melody-royal.list
5d50-kindle-class https://github.com/georgalis/pub/blob/master/know/music/5d50-kindle-class.list
6344-Ithica       https://github.com/georgalis/pub/blob/master/know/music/6344-Ithica.list
6350-forte-flute  https://github.com/georgalis/pub/blob/master/know/music/6350-forte-flute.list
63aa-bee-piano    https://github.com/georgalis/pub/blob/master/know/music/63aa-bee-piano.list
63e8-jazzmore     https://github.com/georgalis/pub/blob/master/know/music/63e8-jazzmore.list
"
#640e-bside1970    https://github.com/georgalis/pub/blob/master/know/music/640e-bside1970.list
#641a-classencore  https://github.com/georgalis/pub/blob/master/know/music/641a-classencore.list

vols="$(awk '!/^$/ {print $1}' <<<"$volumes")"

chktrue "Volumes:"
awk '!/^$/' <<<"$volumes" | awk '{print " ",NR,$0}'

# if the first arg is sync, note that for after gen_index
_sync=n
[ "$1" = "sync" ] && { _sync=y ; shift ;} || true # sync args vols (from $links/0/kind) to curate (sd media)
[ "$1" = "all"  ] && { shift ; set $vols ;} || true # shorthand for all vols as args (and gen_index without check)

# always render the readme
readme2html2kind

# always gen_index for args, OR iff no args, check and gen_index as needed
[ "$*" ] && { for name in $*    ; do gen_index      ; done ;} \
         || { for name in $vols ; do check_gen_index ; done ;}

# if first arg was sync, kind_curate_rsync remaining args, OR all volumes if null
[ "$_sync" = "y" ] && {
    [ "$*" ] \
        && { # gen html and rsync to /Volumes/CURATE/kind/ @ arg
            $verb curate $*
            kindreadme2curate
            for name in $*    ; do doc2html2kind ; kind_curate_rsync ; done ;} \
        || { # gen html and rsync for all volumes
            $verb curate $vols
            kindreadme2curate
            for name in $vols ; do doc2html2kind ; kind_curate_rsync ; done ;}
        }

rm -rf "$wdp/%/$t/"
$verb2 "eof"
exit 0

cat >/dev/null <<eof
pattern plan for refactor into next release format

mastering_source_by_release.sh:        staged_and_vcs_output:                 released_output:
$links/${name}/[0-z]*,                 $music/${name}.view
$music/${name}.view                    $links/0/kind/${name}.view.txt         /Volumes/CURATE/kind/${name}.view.txt
$music/${name}.md                      $links/0/kind/${name}.md.html          /Volumes/CURATE/kind/${name}.md.html
$links/${name}/[0-z]*,*mp3             $links/0/kind/${name}.list.txt         /Volumes/CURATE/kind/${name}.list.txt
$links/${name}/[0-z]*,*mp3             $links/0/kind/${name}/[0-z]*,*mp3      /Volumes/CURATE/kind/${name}/[0-z]*,*mp3
$links/${name}/[0-z]*,*mp3             $music/${name}/${name}.tab
                                       $music/${name}/${name}.sum
                                       $music/${name}/${name}.stat.time
                                       $music/${name}/${name}.stat.pitch
                                       $music/${name}/${name}.list
                                       $music/${name}/${name}.ckstat

release exclude:

