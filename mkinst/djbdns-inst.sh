#!/bin/sh

# (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice 

set -e

stderr () { echo ">>> $* <<<" 1>&2 ;} # return args to stderr
chkerr () { [ "$*" ] && { stderr "$*" ; return 1 ;} || true ;}

cd $(dirname "$0")
base="$PWD"
dist=/usr/local/dist
src=/usr/local/src
mkdir -p $dist $src

ftp http://cr.yp.to/djbdns/djbdns-1.05.tar.gz
cp -p \
	$base/patch/djbdns-runit-socklog.2.patch \
	$base/patch/djbdns-dnscache-cname.patch \
	$base/patch/djbdns-dnscache-sigpipe.patch \
	$base/patch/djbdns-1.05.cache-save.patch.diff \
	"${dist}"

# https://web.archive.org/web/20161203224414/http://tinydns.org/
#
# Felix von Leitner:
#  An ipv6 patch for djbdns.             http://www.fefe.de/dns/      http://www.fefe.de/dns/djbdns-1.05-test28.diff.xz
#  libowfat packages up Dan's libraries. http://www.fefe.de/libowfat/ http://www.fefe.de/libowfat/libowfat-0.32.tar.xz
#
# for srv records, see
# https://anders.com/projects/sysadmin/djbdnsRecordBuilder/
# https://anders.com/cms/37/djbdns/tinydns/SRV/NAPTR/record.builder

# html rfc
# DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION
# https://web.archive.org/web/20170305000254/http://crynwr.com/rfc1035/rfc1035.html

cd $src
rm -rf djbdns-1.05
# http://cr.yp.to/djbdns/install.html
tar xzf $dist/djbdns-1.05.tar.gz
cd djbdns-1.05

# use runit and socklog 
patch <$dist/djbdns-runit-socklog.2.patch

# handle client-side aliases ("CNAME" records) correctly
patch <$dist/djbdns-dnscache-cname.patch

# protects dnscache from SIGPIPEs
patch <$dist/djbdns-dnscache-sigpipe.patch

# save cache on sigterm, restore on start, mkdir -p $ROOT/cache
patch <$dist/djbdns-1.05.cache-save.patch.diff

# support for AAAA records http://www.fefe.de/dns/
patch <$dist/djbdns-1.05-test28.diff

# Jeremy Kister has an all-in-one patch for djbdns  for various resource record types
#patch <$dist/djbdns-1.05.isp.patch

# djbware patch for GNU C Library (glibc) 2.3.x and later (and earlier)
echo gcc -O2 --include /usr/include/errno.h >conf-cc
make
make setup check # under /usr/local

# Patch resources:

# port of djbdns for OpenWRT https://github.com/arduino/linino/tree/master/packages/net/djbdns

# https://web.archive.org/web/20170514223220/https://jdebp.eu/Softwares/djbwares/djbdns-patches.html
#  These are some minor softwares for use with Dan Bernstein's djbdns.
# 
#     Summarising configuration information
#     Making tinydns-data abort on semantic errors
#     Making dnscache handle client-side aliases
#     Making tinydns and axfrdns publish complete client-side alias chains
#     Printing all of the domain names that an IP address maps to
#     Making dnscache ignore referral responses in "forwardonly" mode
#     Making the database compilers use a non-conflicting temporary filename
#     Making the tools recognise a space character as the address separator in ${DNSCACHEIP}
#     Querying non-default proxy DNS servers 


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

# not using djbdns-1.05-srvnaptr.diff
# Guilherme Balena Versiani has added support for SRV+NAPTR
# https://web.archive.org/web/20080924183040/http://mywebpage.netscape.com/guibv/#djb
# https://web.archive.org/web/20080924183040/http://mywebpage.netscape.com/guibv/djbdns-1.05-srvnaptr.diff
