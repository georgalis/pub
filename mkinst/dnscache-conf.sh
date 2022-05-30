#!/bin/sh

# (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice 

set -e

stderr () { [ "$*" ] && echo "$*" 1>&2 || true ;}                          #:> args to stderr, or noop if null
chkwrn () { [ "$*" ] && { stderr    "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
chkerr () { [ "$*" ] && { stderr    ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null

[ "$(uname)" = "NetBSD" ] || { chkerr "only tested on netbsd, COS, RH, and Debian believed to work..." ; exit 1 ;}

# address to run service on
# $DNSCACHEIP env must be defined or as arg1
[ -z "$DNSCACHEIP" ] && [ -n "$1" ] && DNSCACHEIP="$1"
[ -z "$DNSCACHEIP" ] && chkerr "Usage: $0 127.0.0.1"

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
[ -d "$srv" ] || { chkerr "No service directory" ; exit 1 ;}

[ "$(uname)" = "NetBSD" ] && { # for NetBSD...
grep -qe "^${acct}:" /etc/passwd || useradd -d "" -g =uid -r 1..99 -s /sbin/nologin ${acct}
grep -qe "^${log}:"  /etc/passwd || useradd -d "" -g =uid -r 1..99 -s /sbin/nologin ${log}
} || \
[ "$(uname)" = "Linux" ] && { # for COS, RH, or Debian...
grep -qe "^${group}:" /etc/group || groupadd   ${group}
grep -qe "^${acct}:" /etc/passwd || useradd -g ${group} -d / -s /sbin/nologin $acct
grep -qe "^${log}:"  /etc/passwd || useradd -g ${group} -d / -s /sbin/nologin $log
}

test $(which -a dnscache-conf | wc -l) -eq 1 || chkerr "which -a dnscache-conf"

# create service
mkdir -p /usr/local/etc
/usr/local/bin/dnscache-conf $acct $log "/usr/local/etc/dnscache-${DNSCACHEIP}" "${DNSCACHEIP}"

# populate root servers
/usr/local/bin/dnsqr ns . | awk '/answer:/ {print $5;}' | sort -r \
	| while read ns ; do
        echo "/usr/local/bin/dnsqr a $ns ..." >&2
		/usr/local/bin/dnsqr a $ns
	done | awk '/answer:/ {print $5;}' \
	>"/usr/local/etc/dnscache-${DNSCACHEIP}/root/servers/@"

#for n in a b c d e f g h i j k l m ; do
# echo `dnsip $n.root-servers.net` >>/usr/local/etc/dnscache/root/servers/@
#done

# make way for djbdns-1.05.cache-save.patch.diff
            mkdir -p "/usr/local/etc/dnscache-${DNSCACHEIP}/root/cache"
chown ${acct}:${log} "/usr/local/etc/dnscache-${DNSCACHEIP}/root/cache"

# set perms
chown $acct "/usr/local/etc/dnscache-${DNSCACHEIP}"
chmod 4770  "/usr/local/etc/dnscache-${DNSCACHEIP}"

# start the service
ln -sf "/usr/local/etc/dnscache-${DNSCACHEIP}" $srv

