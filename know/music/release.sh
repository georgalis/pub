#!/usr/bin/env bash

# render potential index changes to each declared volume, or default set
# if first arg is sync, also sync vol(s) to /Volumes/CURATE/kind/ if avail

set -e

dep_help_skel () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/skel/.profile)" <><' 1>&2
    echo 'export -f devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue ' 1>&2 ;}
dep_help_sub () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/sub/fn.bash)" <><' 1>&2
    echo 'export -f cksh vfn formfile formfilestats spin2' 1>&2 ;}

test "$(declare -f vfn 2>/dev/null)" || { echo "$0 : vfn not defined" 1>&2 ; dep_help_sub ; exit 1 ;}
while IFS= read a ; do
    vfn $a && true || { echo "$0 : vfn error : $a (68f02595)" 1>&2 ; dep_help_skel ; exit 1 ;}
    done <<EOF
devnul   0eb7cdd2bfb59cd4e2743c0c8d22db1b6b711dc5f70eafc51d841d67aeb850adb5f24f6561829a1c55d3fe9a62a89ceb
stderr   e010b0e704f67ee4d5fc8227d32030bfa06e60be9a49daf0b4c91c6eee9671bc2a17a3d517b8da4e20b7946ea302c130
chkstd   66c5e827c43c8291eb471d1bb61067f6323b2cf3fc5fd9f56f9b4b8516a9e574f44d4c0d614853512894ca651af9caa8
chkwrn   3acc570671ddfd9b5c0eeca64a2c7541b4559d9c3e1edae841c2317bba84a9a55c90455b86deafaf32d592a8f48c5726
logwrn   1775beeee82daa381b314944b9a1963381c9291bbc9884ef27ce99cb762a80a7bb8f5c0d5e1c9586b6a12f15a919b150
chkerr   50195549cedb329654b8cd279d5e471a536488ebfd3045b4589d05e20c0072faecf4b89566df11144369f437821a27d5
logerr   8420e3638ccde6b2c86820d4460e059edcfcb00e2f3ba065e5270bf57e66abce058c88ea95168f3345539ea536abad79
chktrue  6053b8cfa998834844f9dd687af4753b96d2f2e14cf6c51c22dac7165daaf2405e4637bd82096c81165e54728d1d5d3b
EOF
while IFS= read a ; do
    vfn $a && true || { echo "$0 : vfn error : $a (68f025e2)" 1>&2 ; dep_help_sub ; exit 1 ;}
    done <<EOF
spin2          28662d7740b68992e46be02bd4e8820f78e2963889b8658a32f87cbd78f4574210e74783a369c3ef1b6b4f0a86b5a179
formfile       64e9bbfdcfb593a9f36b2a7bc9c94cd78c98fb52ef8b4850020f9c4196466e4d3b053ab9a0cc86d8701332f3c9323c28
formfilestats  52ca5d599803115ca6570d3e668ce76e56fdba2c7b9f6ede921e739b4475f42915f4fdd5a6523b10f1bb28395af4400c
cksh           41b8f3f40c3f54424276e8611c6b4fce634d3a064c0e9dbb4b96d48eccb8f976fb3c5b4ec38faecfb0856cbfb0e011e4
vfn            3f41bca80c09a17a3f2ee414d56d9ed5306ea525e74e619f0dc000c4adda61cf6abd9118f3c316baf568e35e69aa0a69
EOF

[ -e $HOME/sub/markdown.awk ] || { echo "$0 : markdown.awk not found" 1>&2 ; dep_help_sub ; exit 1 ;}

ps | grep -E "^[ ]*$$" | grep -q bash || { chkerr "$0 : Not bash" ; exit 1 ;}
test -d "$links"                      || { chkerr "$0 : not a directory links='$links'" ; exit 1 ;}
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
EOF
# comma_mp3.sh d7802124 00001513

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

    $verb ${name}/stat.time.list ; $verb2 tmp "$wdp/%/$t/${name}.stat.time"
    formfilestats "$links/$name" >"$wdp/%/$t/${name}.stat.time"
    $verb ${name}.stat.pitch ; $verb2 tmp "$wdp/%/$t/${name}.stat.pitch"
    sort -n -t '=' -k 2 "$wdp/%/$t/${name}.stat.time" >"$wdp/%/$t/${name}.stat.pitch"
    touch -r "$wdp/${name}.list" "$wdp/%/$t/${name}.stat.time" "$wdp/%/$t/${name}.stat.pitch"
    mv "$wdp/%/$t/${name}.stat.time" "$wdp/$name/stat.time.list"
    mv "$wdp/%/$t/${name}.stat.pitch" "$wdp/$name/stat.pitch.list"
    find "$wdp/$name"  -name stat.time.list -empty -exec rm \{\} \;
    find "$wdp/$name"  -name stat.pitch.list -empty -exec rm \{\} \;

    $verb ${name}.cksh ; $verb2 tmp "$wdp/%/$t/${name}.cksh"
    cat "$wdp/${name}.list" | while IFS= read a ; do
        cksh -n2 $links/$name/$a
        spin2
        done | awk -v f="${a##*,}" '{$6=f; printf ". . %s %08s %s %s\n",$3,$4,$5,f}' >"$wdp/%/$t/${name}.cksh~"
    spin2 0
    sort -k 6 -u "$wdp/%/$t/${name}.cksh~" >"$wdp/%/$t/${name}.cksh"
    touch -r "$wdp/${name}.list" "$wdp/%/$t/${name}.cksh"
    mv "$wdp/%/$t/${name}.cksh" "$wdp/$name/"

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
        && expr "$(cksh -n3 "$wdp/${name}.list" | awk '{print $5}' )" '=' "$(cksh -n3 "$links/$name/" | awk '{print $5}' )" >/dev/null \
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
    # --bwlimit="5.2m" seems to stop micro sd overheating...
    # --bwlimit="7.8m" to micro sd overheating...
    rsync -aP --delete --modify-window=1 --bwlimit="6.8m" $links/0/kind/${name}* "/Volumes/CURATE/kind/" \
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

chktrue "$music/{stat.time.list,stat.pitch.list,stats.list}"
formfilestats $( sed "s:^:$links/:" <<<"$vols") >"$wdp/%/$t/vols.stat.time"
sort -n -t '=' -k 3 "$wdp/%/$t/vols.stat.time" >"$wdp/%/$t/vols.stat.pitch"
sort -n <"$wdp/%/$t/vols.stat.time" >"$wdp/%/$t/vols.stats"
mv "$wdp/%/$t/vols.stat.time" "$wdp/stat.time.list"
mv "$wdp/%/$t/vols.stat.pitch" "$wdp/stat.pitch.list"
mv "$wdp/%/$t/vols.stats" "$wdp/stats.list"

# if the first arg is sync, note that for after gen_index
_sync=n
[ "$1" = "sync" ] && { _sync=y ; shift ;} || true # sync args vols (from $links/0/kind) to curate (sd media)
[ "$1" = "all"  ] && { shift ; set $vols ;} || true # shorthand for all vols as args (and gen_index without check)

# always render the readme
readme2html2kind

## always gen_index for args, OR iff no args, check and gen_index as needed
#[ "$*" ] && { for name in $*    ; do gen_index      ; done ;} \
# for $* or $vols, check and gen_index as needed
[ "$*" ] && { for name in $*    ; do check_gen_index ; done ;} \
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
chktrue 'rm -rf /Volumes/CURATE/{.fseventsd,.Spotlight-V100,*.{LIB,PL,BMK}} ; eject /Volumes/CURATE/'
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
                                       $music/${name}/${name}.cksh

release exclude:

