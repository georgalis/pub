#!/bin/sh -e

# http://smarden.org/socklog/install.html

# REQUIRE: runit-conf compile
# BEFORE:
# PROVIDE: socklog-inst
# KEYWORD: nbsd

set -e
which gcc || . /etc/profile

version=2.0.3

dir=socklog-${version}
file=socklog-${version}.tar.gz
uri=http://smarden.org/socklog2/socklog-${version}.tar.gz

# dev ver
# version=2.1.0
# uri=http://smarden.org/socklog/socklog-${version}.tar.gz

dist=/usr/local/dist
src=/usr/local/src
mkdir -p $src $dist
cd $dist
ftp "$uri"

mkdir -p /package
cd /package
tar xzpf $dist/$file
cd admin/$dir

package/install
package/install-man

