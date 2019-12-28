#!/bin/sh

# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

chkerr () { [ -n "$*" ] && echo "> > > ERR: $0: $* < < <" >&2 && exit 1 ;}

set -e
#set -x

# $tinydnsip env must be defined
[ -z "$tinydnsip" ] && [ -n "$1" ] && tinydnsip="$1"
[ -z "$tinydnsip" ] && chkerr "Usage: $0 127.0.0.1"

[ "`uname`" = "NetBSD" ] || chkerr "This version only tested on NetBSD."

# Create and start an authoritative tinydns server
# http://cr.yp.to/djbdns.html
# Also see
# http://tinydns.org/

# Make sure they are installed..
#  daemontools
#  ucspi-tcp
#  djbdns
# or because Patch djbdns-1.05 to use
#  chpst of http://smarden.org/runit/
# and
#  svlogd of http://smarden.org/socklog/

# Create accounts and chroot directories for tinydns to run in
acct=dns
log=log

# use -M for redhat...
#useradd -M $acct 
#useradd -M $log

# for deb...
#grep -qe "^nogroup:" /etc/group || groupadd nogroup
#grep -qe "^${acct}:" /etc/passwd || useradd -d / -g nogroup -s /bin/false ${acct}
#grep -qe "^${log}:"  /etc/passwd || useradd -d / -g nogroup -s /bin/false ${log}

# for NetBSD...
grep -qe "^${acct}:" /etc/passwd || useradd -d "" -g =uid -r 1..99 -s /sbin/nologin ${acct}
grep -qe "^${log}:"  /etc/passwd || useradd -d "" -g =uid -r 1..99 -s /sbin/nologin ${log}

mkdir -p /usr/local/etc
tinydns-conf $acct $log /usr/local/etc/tinydns $tinydnsip

# probe the service directory
[ -d /etc/sv ] &&				srv=/etc/sv/ \
	|| { [ -d /service ] &&			srv=/service/ \
		|| { [ -d /var/service ] && 	srv=/var/service/
		} # /var/service
	} # /service
# /etc/sv
[ -z "$srv" ] && chkerr "No service directory"

# Create the authoritave entries.
# The data file format is defined at
# http://cr.yp.to/djbdns/tinydns-data.html

data=/usr/local/etc/tinydns/root/data
[ -s $data ] \
|| cat >$data<<EOF
# a simple example
.ez.com:216.215.214.213
=ez.com:216.215.214.213
@ez.com:65.64.63.62:mail.isp.com
+*.ez.com:216.215.214.213

# a complex example
%lo:192.168.0
%lo:127
%ex

.main.org:216.215.214.213::::ex
.local.org:192.168.0.2::::lo
.0.168.192.in-addr.arpa:192.168.0.2::::lo
^2.0.168.192.in-addr.arpa:new-ptr.local.org
^213.214.215.216.in-addr.arpa:main.org
=beta.local.org:65.64.63.62
=local.org:216.215.214.213
+www.local.org:216.215.214.213
+*.local.org:192.168.0.2
+*.main.org:216.215.214.213

# for srv records, see
# https://anders.com/projects/sysadmin/djbdnsRecordBuilder/
# https://anders.com/cms/37/djbdns/tinydns/SRV/NAPTR/record.builder
# not using djbdns-1.05-srvnaptr.diff
# Ssiem.services.main.org:12.34.56.78:siem.services.main.org:514:::::
# =siem.services.main.org:12.34.56.78:

###

#.fqdn:ip:x:ttl:timestamp:lo      # name server for fqdn,       6 fields
#&fqdn:ip:x:ttl:timestamp:lo      # child name server for fqdn, 6 fields
#@fqdn:ip:x:dist:ttl:timestamp:lo # mail exchanger for fqdn,    6 fields
#^fqdn:p:ttl:timestamp:lo         # fqdn (.in-arpa) PTR to p    5 fields
#=fqdn:ip:ttl:timestamp:lo        # host fqdn with ip address,  5 fields
#+fqdn:ip:ttl:timestamp:lo        # alias fqdn with ip,         5 fields
#%lo:ipprefix                     # ipprefix are in location lo
#
# For SRV records
#
#Sfqdn:ip:x:port:weight:priority:ttl:timestamp
#
# "Standard rules for ip, x, ttl, and timestamp apply. Port, weight, and priority
# all range from 0-65535. Weight and priority are optional; they default to zero
# if not provided."
#
# For NAPTR records
#
#Nfqdn:order:pref:flags:service:regexp:replacement:ttl:timestamp
#
# The same standard rules for ttl and timestamp apply. Order and preference
# (optional) range from 0-65535, and they default to zero if not provided. Flags,
# service and replacement are character-strings.  The replacement is a fqdn that
# defaults to '.' if not provided.
#
# fqdn and ip are the only required fields, under % only lo is required
# The complete data format guide is here
# http://cr.yp.to/djbdns/tinydns-data.html
# http://tinydns.org/
#
# For location based responce (client location conditional expression)
# http://cr.yp.to/djbdns/faq/tinydns.html#differentiation
#
# For zone transfers, use axfrdns
# http://cr.yp.to/djbdns/faq/tinydns.html#tcp
# http://cr.yp.to/djbdns/faq/axfrdns.html#config
#
# To add child dns server 
# http://cr.yp.to/djbdns/faq/tinydns.html#add-childns
# ./add-childns elysium.heaven.af.mil 1.2.3.144
#
# refer lost children back to the roots, better than lame :) 
$(dnsqr ns . | awk '/answer:/ {print $5;}' | cut -b1 \
        | while read n ; do
                echo "#&.:$(dnsqr a ${n}.root-servers.net | awk '/answer:/ {print $5;}'):${n}.root-servers.net."
	done)
EOF

# start the service
ln -sf /usr/local/etc/tinydns $srv

# create the db and let tinydns start using it.
cd `dirname $data`
chgrp dns . $data 
chmod 2770 .
make
exit
# end of tinydns 

# start rbldns
[ -n "$rbldnsip" -a -n "$rbldnsname" ] && $( # deploy rbldns
src=/usr/local/src
cd $src 

acct=Grbldns
log=Grbllog
grep -qe "^${acct}:" /etc/passwd || useradd -d / -g nogroup -s /bin/false ${acct}
grep -qe "^${logacct}:"  /etc/passwd || useradd -d / -g nogroup -s /bin/false ${log}

rbldns-conf $acct $logacct /etc/rbldns $rbldnsip $rbldnsname
)
