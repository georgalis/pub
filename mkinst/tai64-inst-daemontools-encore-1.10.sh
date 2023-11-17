#!/usr/bin/env sh
# 
# only using tai64n tai64nlocal from daemontools-encore
#
# (c) 2008-2023 George Georgalis <george@galis.org> unlimited use with this notice


set -e

VER="1.10"

[ "$1" ] && PREFIX="$1" || PREFIX="$HOME"
mkdir -p "$PREFIX" || { echo "$0 : cannot use PREFIX='$PREFIX'" 1>&2 ; exit 1 ;}
cd "$PREFIX"
PREFIX="$(pwd -P)"

     mkdir -p "$PREFIX"/{dist,src,bin}
     cd "${PREFIX}/dist"

[ -x "$(which wget)" ] \
    && wget http://untroubled.org/daemontools-encore/daemontools-encore-${VER}.tar.gz \
    || ftp http://untroubled.org/daemontools-encore/daemontools-encore-${VER}.tar.gz

cd ../src
rm -rf daemontools-encore-${VER}          # purge any prior build
tar xzf ../dist/daemontools-encore-${VER}.tar.gz
cd daemontools-encore-${VER}

######################
# from daemontools-encore-1.10/README

echo "$PREFIX/bin" >conf-bin
echo "$PREFIX/man" >conf-man

######################

#echo cc -O2 --include /usr/include/errno.h >>conf-cc
#echo cc -O2 --include /Library/Developer/CommandLineTools/SDKs/MacOSX11.1.sdk/usr/include/mach/error.h >>conf-cc
make tai64nlocal tai64n
#install -m 755 tai64nlocal tai64n /usr/local/bin
#mkdir -p "${PREFIX}/bin"
install -m 755 tai64nlocal tai64n "${PREFIX}/bin"
mkdir -p "${PREFIX}/man/man.8"
install -m 755 tai64nlocal.8 tai64n.8 "${PREFIX}/man/man.8"

exit
