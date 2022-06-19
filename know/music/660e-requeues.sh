#!/usr/bin/env bash

# common functions for shell verbose management....
devnul () { return 0 ;}                                                     #:> drop args
stderr () {  [ "$*" ] && echo "$*" 1>&2 || true ;}                          #:> args to stderr, or noop if null
chkstd () {  [ "$*" ] && echo "$*"      || true ;}                          #:> args to stdout, or noop if null
chkwrn () {  [ "$*" ] && { stderr    "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
logwrn () {  [ "$*" ] && { logger -s "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr+log args return 0, noop if null
chkerr () {  [ "$*" ] && { stderr    ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null
logerr () {  [ "$*" ] && { logger -s ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr+log args return 1, noop if null
chkexit () { [ "$*" ] && { stderr    ">>> $* <<<" ; exit 1    ;} || true ;} #:> err stderr args exit 1, noop if null
logexit () { [ "$*" ] && { logger -s ">>> $* <<<" ; exit 1    ;} || true ;} #:> err stderr+log args exit 1, noop if null
siff () { local verb="${verb:-chkwrn}" ; test -e "$1" \
        && { { . "${1}" && ${verb} "<> ${2}: . ${1} <>" ;} || { chkerr "siff: fail in '$1' from '$2'" ; return 1 ;} ;} \
        || ${verb} "${2}: siff: no file $1" ;} #:> source arg1 if exists, on err recall args for backtrace
# verbosity, typically set to devnul, chkwrn, or chkerr
#verb="${verb:=devnul}"
#verb2="${verb2:=devnul}"
#verb3="${verb3:=devnul}"

ps | grep -E "^[ ]*$$" | grep -q bash   || chkexit "$0 : Not bash" 
test -d "$link/"                        || chkexit "$0 : not a directory link='$link'"

f="$0"
infile="${f##*/}"                                              # infile  == basename f
expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname f
infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f
name="$(sed 's/.[^.]*$//' <<<"$infile")" # infile less any dotted extension

cd "$inpath"

ckstatsum () { # return sortable stat data for args (OR stdin file list)
  # ckstatsum /etc/resolv.conf
  # 0127e92c7 39bd42d3       16 62798808    resolv.conf     /etc/resolv.conf
  # links\inode 0x_cksum 0x_size 0x_date    basename        input
  # (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice
  local f fs;
  [ "$1" ] && fs="$1" || fs="$(cat)";
  shift || true;
  [ "$1" ] && $FUNCNAME $@;
  [ "$fs" = "-h" -o "$fs" = "--help" ] && {
    chkwrn "Return sortable stat data for args (OR stdin file list):";
    chkwrn "links\inode 0x_cksum 0x_size 0x_mdate basename input"
    } || { OS="$(uname)"
      [ "$OS" = "Linux" ]                      && _stat () { stat -c %h\ %i\ %s\ %Y "$1" ;} || true
      [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat () { stat -f %l\ %i\ %z\ %m "$1" ;} || true
      echo "$fs" | while IFS= read f; do
        [ -f "$f" ] && {
          { _stat "$f" ; cksum <"$f"
              } | tr '\n' ' ' | awk '{printf "%02x%07x %8x % 8x %08x",$1,$2,$5,$3,$4}'
        # printf "\t%s\t%s\n" "${f##*/}" "$f" # tabs with basename and filepath input
          echo " ${f##*/}"
          } || chkerr "$FUNCNAME : not a regular file : $f";
        done
      }
  } # ckstatsum ()

chkwrn "${name}.list"
find "$link/" -maxdepth 1 -type f -name \*mp3 \
    | sed -e "s=${link}[/]*==" -e '/^0/d' \
    | sort >"${name}.list"

chkwrn ${name}.list.html
echo '<ol>' >${name}.list.html
cat ${name}.list \
    | sed -e '
        s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
        s,^,<li>,
        s,$,</li>,
        ' >>${name}.list.html
echo '</ol>' >>${name}.list.html

chkwrn ${name}.tab
sed -e '
        s/_^/ _^/
        s/,/ /
#       s/_sous_des_Dominos_pourpres_et_feuilles_mortes//
#       s/_And_His_Orchestra_With_Alice_Roberts//
#       s/_Gavotte_garment_et_gracieusement//
#       s/_et_tres_proprement//
#       s/_-_Tendrement_-_Gayment//
#       s/Musette_Rondeau_gracieusement/Musette_Rondeau/
#       s/_sous_le_Domino_gris_de_maure//
#       s/_et_ancienne_Mxnstrxndxsx//
#       s/_Mxnstrxndxsx_1er_acte//
#       s/_couleur_d_invisible//
#       s/_sous_le_Domino_noir//
#       s/_sous_des_Dominos_jaunes//
#       s/_by_Jean-Baptiste_Forqueray/_by_Jean-Baptiste/
#       s/La_sole_ou_Passacaille_Lente/Passacaille_Lente/
#       s/_et_les_tresorieres_suranees/_et_les_suranees/
#       s/_sous_le_Domino_gris_de_lin/_sous_le_Domino/
#       s/Noblement_et_avec_Sentiment/Noblement/
#       s/_And_His_Orchestra_With_/_with/
#       s/La_Parisienne_Tres_legerement/La_Parisienne/
#       s/Gavotte_en_Rondeau_Double/Gavotte_en_Rondeau_2x/
#       s/Non_presto_ma_a_tempo_di_ballo/A_tempo_di_ballo/
#       s/Les_Calotins_et_les_Calotines_ou_la_Piece_a_tretous/Les_Calotins_ou_la_Piece_a_tretous/
#       s/La_Pudeur_sous_le_Domino_couleur_le_roze/La_Pudeur_sous_le_Domino_le_roze/
#       s/Bob_Bobbin_Along-Ralph_Burns_Sessions-1955_58/Bob_Bobbin_Along/
#       s/Back_To_Capistrano-Ralph_Burns_Sessions-1955_58/Back_To_Capistrano/
#       s/And_Feathers_Tomorrow-Ralph_Burns_Sessions-1955_58/And_Feathers_Tomorrow/
#       s/Les_jeunes_Seigneurs_Cy-devant_les_petits_Maitre/Les_jeunes_Seigneurs/
#       s/Gmaj-Presto_quanto_sia_possible-Meyer/Gmaj-Presto-Meyer/
#       s/Cmin-4_La_Boisson-Vivement_les_pinces_bien_soutenus/Cmin-4_La_Boisson-Vivement/
#       s/in_Love-Hammerstein_II-Rodgers-Natural_Soul-1962/in_Love-Natural_Soul-1962/
#       s/Pacifica-03_Suite_Dmaj-08_Fantaisie_Champestre/Pacifica-03_Suite_Dmaj-08_Fantaisie/
#       s/Suitte-3_Sarabande_Tres_proprement/Suitte-3_Sarabande/
#       s/Dmin-1_Sarabande_en_Rondeau/Dmin-1_Sarabande/
#       s/15-Neufieme_Suitte-2_Courante_Affectueusement/15-Neufieme_Suitte-2_Courante/
#       s/Suitte-2_Allemande_Pas_trop_viste/Suitte-2_Allemande/
        ' <${name}.list \
    | sort -f -k2 | column -t | sed -e 's/  / /' -e 's/  / /' >${name}.tab

chkwrn ${name}.tab.html
echo '<ol>' >${name}.tab.html
cat ${name}.tab \
    | sed -e '
        s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
        s,^,<li>,
        s,$,</li>,
        ' >>${name}.tab.html
echo '</ol>' >>${name}.tab.html

chkwrn ${name}.sum
ls $link/*mp3 | sed -e '/\/0/d' | while read a ; do ckstatsum $a ; done >${name}.sum

chkwrn ${name}.sum.html
echo '<pre><ol>' >${name}.sum.html
cat ${name}.sum \
    | sed -e '
        s,_^\([^.]*\)\.,_^<a href=http://youtu.be/\1>\1</a>.,
        s,^,<li>,
        s,$,</li>,
        ' >>${name}.sum.html
echo '</ol></pre>' >>${name}.sum.html
