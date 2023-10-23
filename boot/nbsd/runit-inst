#!/bin/sh

# REQUIRE: etc comp
# BEFORE: runit-conf
# PROVIDE: runit-inst
# KEYWORD: nbsd


# http://smarden.org/runit/install.html

set -e
which gcc || . /etc/profile

version=2.1.2

dir=runit-${version}
file=runit-${version}.tar.gz
uri=http://smarden.org/runit/runit-${version}.tar.gz
dist=/usr/local/dist
mkdir -p $dist
cd $dist
ftp "$uri"

mkdir -p /package
chmod 1755 /package

cd /package

tar -xzpf $dist/$file
cd admin/$dir

package/install
package/install-man

