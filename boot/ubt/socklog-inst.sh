#!/bin/sh -e

# http://smarden.org/socklog/install.html

# REQUIRE: runit-conf 
# BEFORE:
# PROVIDE: socklog-inst
# KEYWORD: ubt

set -e
#set -x

version=2.0.2
version=2.1.0

dir=socklog-${version}
file=socklog-${version}.tar.gz
uri=http://smarden.org/socklog2/socklog-${version}.tar.gz
uri=http://smarden.org/socklog/socklog-${version}.tar.gz

dist=/usr/local/dist
src=/usr/local/src
mkdir -p $src $dist
cd $dist
wget "$uri"

mkdir -p /package
cd /package
tar xzpf $dist/$file
cd admin/$dir

package/install
package/install-man

