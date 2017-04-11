#!/bin/sh

# REQUIRE: socklog-conf
# BEFORE:
# PROVIDE: ipsvd-inst
# KEYWORD: nbsd-boot

set -e

version=1.0.0

dist=/usr/local/dist
src=/usr/local/src
mkdir -p $dist $src
cd $dist

# http://smarden.org/ipsvd/install.html

  mkdir -p /package
  chmod 1755 /package

wget http://smarden.org/ipsvd/ipsvd-${version}.tar.gz
# see also matrixssl

  cd /package

tar xzpf $dist/ipsvd-${version}.tar.gz

  cd net/ipsvd-${version}

  package/install
  package/install-man

