#!/bin/sh
#
# ./pub/mkinst/skel-inst.sh
#
# install skel files from dir (arg1) to dest dir (arg2, default $HOME)
#
# Usage: sh $0 /usr/local/pub/skel /etc/skel
#
# (c) 2006-2022 George Georgalis <george@galis.org> unlimited use with this notice

set -e

devnul () { return 0 ;}                                                    #:> drop args
stderr () { [ "$*" ] && echo "$*" 1>&2 || true ;}                          #:> args to stderr, or noop if null
chkwrn () { [ "$*" ] && { stderr    "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
chkerr () { [ "$*" ] && { stderr    ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null

verb="${verb:=chkwrn}"

main () { local b t s d bak n pathn

  t="$(date '+%Y%m%d_%H%M%S')" # timestamp
  b="$(echo "${0##*/}" | sed 's/.[^.]*$//')" # this program name less extension

  # src dir
  [ -n "$1" ] && { cd "$1" && s="$(pwd -P)" ;} || { chkerr "Expecting skel dir as arg1" ; exit 1 ;}
  [ -d "$s" ] || { chkerr "$s (arg1) is not a directory" ; exit 1 ;}

  # dest dir
  [ "$2" ] || d="$HOME"
  [ -n "$2" ] && { cd "$2" 2>/dev/null 2>/dev/null && d="$(pwd -P)" ;} || { chkerr "invalid dest (arg2) : $2" ; exit 1 ;}

  # backup dir
  bak="${d}/.${b}-${t}"
  mkdir "$bak"

  # complex algo only makes dest backup for differences installed, no depend on rsync
  cd "$s"
  find . -depth -mindepth 1 | while IFS= read n; do # backup and replace every diff from src skel
    # 1) on not a directory, 2) compare src and dest cksum, 3) on diff, make dest and bak dirs,
    # 4) cp backup, 5) cp src
    [ -d "$n" ] || { # 1) not a directory
        [ "$(cksum <"$n")" = "$(cksum  2>/dev/null <"$d/$n")" ] || { # 2) compare src and dest cksum
            expr "$n" : ".*/" >/dev/null && pathn="${n%/*}" || pathn="." # derive dirname of n
            mkdir -p "$d/$pathn" "$bak/$pathn" # 3) make dest and bak dirs
            [ -e "$d/$n" ] && cp -p    "$d/$n"     "$bak/$pathn" # 4) cp backup if exists
                              cp -p    "$n"        "$d/$pathn"   # 5) always cp new file
            $verb "${PWD}/${n##./}"
            } # 2) compare src and dest cksum
        } # 1) on not a directory
    done # backup and replace every diff from src skel
    find "$bak" -depth -type d -empty -exec rm -rf \{\} \;
    [ -d "$bak" ] && $verb "installed '$s' to '$d' backup '$bak'"
    [ -d "$bak" ] || $verb "installed '$s' to '$d' (no replacements)"
    } # main

main $@
exit $?

#	[ "$n" = ".Xdefaults" ] && ln -sf "${d}/${n}" "${d}/${n}-$(hostname)"
