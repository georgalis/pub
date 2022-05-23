#!/bin/sh

# REQUIRE: socklog-conf compile
# BEFORE:
# PROVIDE: ipsvd-inst
# KEYWORD: nbsd

set -e
which gcc || . /etc/profile

version=1.0.0

dist=/usr/local/dist
src=/usr/local/src
mkdir -p $dist $src
cd $dist

# http://smarden.org/ipsvd/install.html

  mkdir -p /package
  chmod 1755 /package

ftp http://smarden.org/ipsvd/ipsvd-${version}.tar.gz
# see also matrixssl

  cd /package

tar xzpf $dist/ipsvd-${version}.tar.gz

  cd net/ipsvd-${version}

  package/install
  package/install-man

