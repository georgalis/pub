#!/bin/sh

# REQUIRE: etc
# BEFORE: runit-conf
# PROVIDE: runit-inst
# KEYWORD: ubt

set -e

# http://smarden.org/runit/install.html

version=2.1.2

dir=runit-${version}
file=runit-${version}.tar.gz
uri=http://smarden.org/runit/runit-${version}.tar.gz
dist=/usr/local/dist
mkdir -p $dist
cd $dist
wget "$uri"

mkdir -p /package
chmod 1755 /package

cd /package

tar -xzpf $dist/$file
cd admin/$dir

package/install
package/install-man

