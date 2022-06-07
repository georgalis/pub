#!/bin/sh
#
# ...we only need tai64 tools from daemontools
#
# (c) 2008-2022 George Georgalis <george@galis.org> unlimited use with this notice
#

# REQUIRE: comp
# BEFORE:
# PROVIDE: tai64
# KEYWORD: nbsd

set -e
which gcc || . /etc/profile

     mkdir -p /usr/local/dist /usr/local/src /usr/local/bin
     cd /usr/local/dist

ftp http://cr.yp.to/daemontools/daemontools-0.76.tar.gz

     cd /usr/local/src
     tar xzpf ../dist/daemontools-0.76.tar.gz

rm -rf daemontools-0.76         # purge any prior build
mv admin/daemontools-0.76/ ./
rm -rf admin
cd daemontools-0.76             # the filtered surce

######################
# from daemontools-0.76/compile
umask 022
test -d package || ( echo 'Wrong working directory.'; exit 1 )
test -d src || ( echo 'Wrong working directory.'; exit 1 )

here=`env - PATH=$PATH pwd`

mkdir -p compile command
test -r compile/home || echo $here > compile/home
test -h compile/src || ln -s $here/src compile/src

echo 'Linking ./src/* into ./compile...'
for i in `ls src`
do
  test -h compile/$i || ln -s src/$i compile/$i
done
######################

cd compile
echo gcc -O2 --include /usr/include/errno.h >>conf-cc
make tai64nlocal tai64n
install -m 755 tai64nlocal tai64n /usr/local/bin

exit
