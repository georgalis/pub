#!/bin/sh

# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

set -e
#set -x

stderr () { [ "$*" ] && echo "$*" 1>&2 || true ;}                          #:> args to stderr, or noop if null
chkwrn () { [ "$*" ] && { stderr    "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
chkerr () { [ "$*" ] && { stderr    ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null

# this version only tested on netbsd
[ "$(uname)" = "NetBSD" ] || exit 1

# address to run service on
# $dnscacheip env must be defined for this script to work
[ -z "$dnscacheip" ] && [ -n "$1" ] && dnscacheip="$1"
[ -z "$dnscacheip" ] && chkerr "Usage: $0 127.0.0.1"

umask 0022

# Start up a dnscache to handle recursive queries.
# http://cr.yp.to/djbdns/dnscache.html
# Also see
# http://tinydns.org/

# Create accounts and chroot directories for dnscache to run in
acct=dns
log=log
group=nofiles

# probe the service directory
[ -d /etc/sv ] &&				srv=/etc/sv/ \
	|| { [ -d /service ] &&			srv=/service/ \
		|| { [ -d /var/service ] && 	srv=/var/service/
		} # /var/service
	} # /service
# /etc/sv
[ -z "$srv" ] && chkerr "No service directory"

[ "$(uname)" = "NetBSD" ] && { # for NetBSD...
grep -qe "^${acct}:" /etc/passwd || useradd -d "" -g =uid -r 1..99 -s /sbin/nologin ${acct}
grep -qe "^${log}:"  /etc/passwd || useradd -d "" -g =uid -r 1..99 -s /sbin/nologin ${log}
} || \
[ "$(uname)" = "Linux" ] && { # for RH or Debian...
grep -qe "^${group}:" /etc/group || groupadd ${group}
grep -qe "^${acct}:" /etc/passwd || useradd -g ${group} -d / -s /sbin/nologin $acct
grep -qe "^${log}:"  /etc/passwd || useradd -g ${group} -d / -s /sbin/nologin $log
}

test $(which -a dnscache-conf | wc -l) -eq 1 || chkerr "which -a dnscache-conf"

# create service
mkdir -p /usr/local/etc
/usr/local/bin/dnscache-conf $acct $log /usr/local/etc/dnscache-$dnscacheip $dnscacheip

# populate root servers
/usr/local/bin/dnsqr ns . | awk '/answer:/ {print $5;}' \
	| while read ns ; do
		/usr/local/bin/dnsqr a $ns
	done | awk '/answer:/ {print $5;}' \
	>/usr/local/etc/dnscache-$dnscacheip/root/servers/@

#for n in a b c d e f g h i j k l m ; do
# echo `dnsip $n.root-servers.net` >>/usr/local/etc/dnscache/root/servers/@
#done

# set perms
chown $acct /usr/local/etc/dnscache-$dnscacheip
chmod 4770 /usr/local/etc/dnscache-$dnscacheip

# start the service
ln -sf /usr/local/etc/dnscache-$dnscacheip $srv

