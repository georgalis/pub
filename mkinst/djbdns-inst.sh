#!/bin/sh

# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

set -e

chkerr () { [ -n "$*" ] && echo ">>-->- ERR: $0: $* -<--<<" >&2 && exit 1 ;}

cd $(dirname "$0")
base="$PWD"
dist=/usr/local/dist
src=/usr/local/src
mkdir -p $dist $src
cd $dist

chkerr "all djbdns-1.05 need patching to not use 'chpst -m' ..."

ftp http://cr.yp.to/djbdns/djbdns-1.05.tar.gz
#$base/patch/djbdns-dnscache-sigpipe.patch \
cp -p	$base/patch/djbdns-1.05.isp.patch \
	$base/patch/djbdns-chpst-socklog.1.patch \
	$base/patch/djbdns-dnscache-cname.patch \
	$base/patch/djbdns-1.05-srvnaptr.diff \
	./
# http://www.tinydns.org/
# http://homepages.tesco.net/~J.deBoynePollard/Softwares/djbdns/
# http://tinydns.org/
# http://www.jeremykister.com/code/djbdns-1.05.isp.patch

# Guilherme Balena Versiani has added support for SRV+NAPTR
# https://web.archive.org/web/20080924183040/http://mywebpage.netscape.com/guibv/#djb
# https://web.archive.org/web/20080924183040/http://mywebpage.netscape.com/guibv/djbdns-1.05-srvnaptr.diff
# 
# The following patch extends previous Michael Handler's SRV patch to support
# syntactic sugar NAPTR entries.  These two resource records are used by current
# DDDS RFCs (340x).
# 
# a) For SRV records, use the following format in tinydns-data (same as Michael
# Handler's patch):
# 
#     Sfqdn:ip:x:port:weight:priority:ttl:timestamp
# 
# "Standard rules for ip, x, ttl, and timestamp apply. Port, weight, and priority
# all range from 0-65535. Weight and priority are optional; they default to zero
# if not provided."
# 
#     Sconsole.zoinks.example.com:1.2.3.4:rack102-con1:2001:69:7:300:
# 
# b) For NAPTR records, use the following format:
# 
#     Nfqdn:order:pref:flags:service:regexp:replacement:ttl:timestamp
# 
# The same standard rules for ttl and timestamp apply. Order and preference
# (optional) range from 0-65535, and they default to zero if not provided. Flags,
# service and replacement are character-strings.  The replacement is a fqdn that
# defaults to '.' if not provided.
# 
#     Nsomedomain.org:100:90:s:SIP+D2U::_sip._udp.somedomain.org
#     Ncid.urn.arpa:100:10:::!^urn\058cid\058.+@([^\.]+\.)(.*)$!\2!i:
# 
# c) This patch makes axfr-get decompose SRV and PTR records and write them out
# in native format, rather than opaque (see M.H. patch comments). This one makes
# axfr-get convert NAPTR records to the format explained above.
# 
# d) It extends the dnsq and dnsqr to support SRV and NAPTR accordingly.
# Example:
# 
#     # dnsqr naptr somedomain.org
#     35 somedomain.org:
#     x bytes, 1+1+0+0 records, response, noerror
#     query: 35 somedomain.org
#     answer: somedomain.org 78320 NAPTR 100 90 "s" "SIP+D2U" "" _sip._tcp.somedomain.org
# 
#     # dnsqr srv console.zoinks.example.com
#     33 console.zoinks.example.com:
#     85 bytes, 1+1+0+0 records, response, noerror
#     query: 33 console.zoinks.example.com
#     answer: console.zoinks.example.com 300 SRV 7 69 2001 rack102-con1.example.com
# 

cd $src
rm -rf djbdns-1.05
# http://cr.yp.to/djbdns/install.html
tar xzf $dist/djbdns-1.05.tar.gz
cd djbdns-1.05
# use chpst and socklog 
echo "######## $dist/djbdns-chpst-socklog.1.patch"
patch <$dist/djbdns-chpst-socklog.1.patch
# handle client-side aliases ("CNAME" records) correctly
echo "######## $dist/djbdns-dnscache-cname.patch"
patch <$dist/djbdns-dnscache-cname.patch
# protects dnscache from SIGPIPEs
#echo "######## $dist/djbdns-dnscache-sigpipe.patch"
#patch <$dist/djbdns-dnscache-sigpipe.patch
# Jeremy Kister has an all-in-one patch for djbdns  for various resource record types
 # echo "######## $dist/djbdns-1.05.isp.patch"
 # patch <$dist/djbdns-1.05.isp.patch
echo "######## $dist/djbdns-1.05-srvnaptr.diff"
patch <$dist/djbdns-1.05-srvnaptr.diff

# djbware patch for GNU C Library (glibc) 2.3.x and later (and earlier)
echo gcc -O2 --include /usr/include/errno.h >conf-cc
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
