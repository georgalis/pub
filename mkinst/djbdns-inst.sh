#!/bin/sh
# 
# $Id: djbdns-inst.sh 319 2007-10-15 15:20:37Z geo $
# $GeorgalisG: mkinst/djbdns-inst.sh,v 1.3 2006/02/13 03:53:44 geo Exp $
#
# LICENSE: <george@galis.org> wrote this file. As long as you retain this
# notice, you can do anything with it or buy beer -- George Georgalis
#

set -e
#set -x

dist=/usr/local/dist
src=/usr/local/src
mkdir -p $dist $src
cd $dist

ftp http://cr.yp.to/djbdns/djbdns-1.05.tar.gz
# http://www.tinydns.org/
# http://homepages.tesco.net/~J.deBoynePollard/Softwares/djbdns/
ftp http://metrg.net/pub/mkinst/patch/djbdns-chpst-socklog.1.patch
ftp http://metrg.net/pub/mkinst/patch/djbdns-dnscache-sigpipe.patch
ftp http://metrg.net/pub/mkinst/patch/djbdns-dnscache-cname.patch
cd $src
# http://cr.yp.to/djbdns/install.html
tar xzf $dist/djbdns-1.05.tar.gz
# use chpst and socklog 
patch <$dist/djbdns-chpst-socklog.1.patch
cd djbdns-1.05
# protects dnscache from SIGPIPEs
patch <$dist/djbdns-dnscache-sigpipe.patch
# handle client-side aliases ("CNAME" records) correctly
patch <$dist/djbdns-dnscache-cname.patch

# djbware patch for GNU C Library (glibc) 2.3.x and later (and earlier)
echo gcc -O2 --include /usr/include/errno.h >|conf-cc
make
make setup check # under /usr/local

#Cc: dns@list.cr.yp.to
#Date: Mon, 10 May 2004 16:24:13 +0200
#Subject: Re: note on tinydns performance
#
#Patch0: djbdns-1.05-errno.patch
#Patch1: compiler-temporary-filename.patch
#Patch2: dnscache-cname-handling.patch
#Patch3: dnscache-strict-forwardonly.patch
#Patch4: dnscacheip-space-separator.patch
#Patch5: tinydns-alias-chain-truncation.patch
#Patch6: tinydns-data-semantic-error.patch
#Patch7: djbdns-1.05-cache-mmap.patch
#Patch8: djbdns-1.05-multiip.diff
#Patch9: dnscache-multiple-ip.patch
#Patch10: dnsroots.global.patch
