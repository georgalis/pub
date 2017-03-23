#!/bin/sh
#
# ./pub/mkinst/skel-inst.sh
#
# install skel files in prefix or $HOME
#
# Usage: sh $0 /usr/local/pub/skel /etc/skel
#
# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

set -e
chkerr () { [ -n "$*" ] && echo "ERR >>-->- $h/$(basename $0) : $* -<--<<" >&2 && exit 1 || true ;}
main () { # enable local varables

local u h b t s d bak n tf
u="$USER" # uid running the tests
h="$(cd $(dirname $0) && pwd -P)" # realpath of this script
b="$(basename $0 | sed 's/.[^.]*$//')" # this program name less (.sh) extension
t="$( { date '+%Y%m%d_%H%M%S_' && uuidgen ;} | sed -e 's/-.*//' | tr -d ' \n' )" # time based uniq id

# set src dir
[ -n "$1" ] && { cd "$1" && s="$PWD" ;} || chkerr "Expecting skel dir as arg1"
[ -d "$s" ] || chkerr "$s (arg1) is not a directory"

# set dest dir
[ -n "$2" ] && cd "$2" && d="$(pwd -P)" || d="$HOME"
[ -d "$d" ] || chkerr "$d target (arg2) is not a directory"

# backup dir
bak="${d}/${b}-${t}"
mkdir $bak

echo installing skel $s to dir $d with backup $bak

find "$s" -mindepth 1 -maxdepth 1 | while read n; do
	tf="$d/$(basename $n)"				# target filename
	[ -e "$tf" ] && mv "$tf" $bak			# backup
	cp -pr $n $tf					# install
done
} # main

main $@
exit

#	[ "$n" = ".Xdefaults" ] && ln -sf "${d}/${n}" "${d}/${n}-$(hostname)"

