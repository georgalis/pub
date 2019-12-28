#!/bin/sh

# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

set -e

stderr () { echo ">>> $* <<<" 1>&2 ;} # return args to stderr
chkerr () { [ "$*" ] && { stderr "$*" ; return 1 ;} || true ;}

cd $(dirname "$0")
base="$PWD"
dist=/usr/local/dist
src=/usr/local/src
mkdir -p $dist $src
cd $dist

chkerr "all djbdns-1.05 need patching to not use 'chpst -m' ..."

ftp http://cr.yp.to/djbdns/djbdns-1.05.tar.gz
cp -p \
	$base/patch/djbdns-chpst-socklog.1.patch \
	$base/patch/djbdns-dnscache-cname.patch \
	$base/patch/djbdns-dnscache-sigpipe.patch \
	./
# http://www.tinydns.org/
# http://tinydns.org/
# https://github.com/pjps/ndjbdns/
# http://pjp.dgplug.org/ndjbdns/

# for srv records, see
# https://anders.com/projects/sysadmin/djbdnsRecordBuilder/
# https://anders.com/cms/37/djbdns/tinydns/SRV/NAPTR/record.builder

cd $src
rm -rf djbdns-1.05
# http://cr.yp.to/djbdns/install.html
tar xzf $dist/djbdns-1.05.tar.gz
cd djbdns-1.05

# use chpst and socklog 
patch <$dist/djbdns-chpst-socklog.1.patch

# handle client-side aliases ("CNAME" records) correctly
patch <$dist/djbdns-dnscache-cname.patch

# protects dnscache from SIGPIPEs
patch <$dist/djbdns-dnscache-sigpipe.patch

# Jeremy Kister has an all-in-one patch for djbdns  for various resource record types
#patch <$dist/djbdns-1.05.isp.patch

# djbware patch for GNU C Library (glibc) 2.3.x and later (and earlier)
echo gcc -O2 --include /usr/include/errno.h >conf-cc
make
make setup check # under /usr/local

# Patch resources:

# https://github.com/arduino/linino/tree/master/packages/net/djbdns

# https://jdebp.eu/Softwares/djbwares/djbdns-patches.html
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
