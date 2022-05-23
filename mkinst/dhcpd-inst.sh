#!/bin/sh
# $Id: dhcpd-inst.sh 411 2008-07-06 04:01:37Z geo $
#
# LICENSE: <george@galis.org> wrote this file. As long as you retain this
# notice, you can do anything with it or buy beer -- George Georgalis

set -x
set -e

install -d -m 755 /etc/dhcpd /etc/dhcpd
install -d -m 755 -o log /etc/dhcpd/log

# resonable guess
int="`ifconfig -l | awk '{print $1;}'`"

cat >/etc/dhcpd/run<<EOF-dhcpd-run
#!/bin/sh
exec 2>&1
exec env PATH='/usr/sbin' \
	dhcpd -f -d -cf /etc/dhcpd/dhcpd.conf $int
EOF-dhcpd-run

cat >/etc/dhcpd/log/run<<'EOF-dhcpd-log-run'
#!/bin/sh
exec chpst -u log svlogd -tt /etc/dhcpd/log
EOF-dhcpd-log-run

chmod 755 /etc/dhcpd/run /etc/dhcpd/log/run

[ -e /etc/dhcpd/dhcpd.conf ] && exit 1
cat >/etc/dhcpd/dhcpd.conf<<EOF-dhcpd.conf
option domain-name "local";
option domain-name-servers 192.168.0.1, 192.168.0.1;
default-lease-time 86400;
max-lease-time 604800;
#>>> seconds in 
#>>>  min in hour in day in week in year
#>>>  60  *  60   *  24  *  7    *  52   = 31449600
#>>>  60  *  60   *  24  *  7            = 604800
#>>>  60  *  60   *  24*6                = 518400
#>>>  60  *  60   *  24*5                = 432000
#>>>  60  *  60   *  24*4                = 345600
#>>>  60  *  60   *  24*3                = 259200
#>>>  60  *  60   *  24*2                = 172800
#>>>  60  *  60   *  24                  = 86400
#>>>  60  *  60                          = 3600
#>>>  min in hour in day in week in year
authoritative;
ddns-update-style none;
log-facility local7;

#>>> define all subnets on host
subnet 10.255.255.0 netmask 255.255.255.0 { }

subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.200 192.168.80.249;
  option broadcast-address 192.168.0.255;
  option routers 192.168.0.1; }

#>>> define addresses
#host 192.168.0.100 { hardware ethernet cc:cc:cc:cc:cc:cc; fixed-address 192.168.0.100; }
#>>> use dns if available
#host name { hardware ethernet cc:cc:cc:cc:cc:cc; fixed-address name.domain; }

#>>> setup pxe boot
#include "/usr/share/dhcpd/pxe.defs";
#deny unknown-clients;
#allow bootp;
#host name { fixed-address name.domain;
#	next-server tftp.local;
#	hardware ethernet 00:01:03:c2:82:b9; } # card, run
#	filename "pxeboot";
#	always-reply-rfc1048 true; # or false required by some clients
# extra options for diskless nfs root
#	option root-path "/export/client/root";
#}
EOF-dhcpd.conf


cat <<EOF-note

>>> Edit /etc/dhcpd.conf
>>> for pxe...
>>> ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-3.0/i386/binary/kernel/netbsd-INSTALL.gz
>>> pxeboot is in base.tgz
>>> ftp://ftp.netbsd.org/pub/NetBSD/NetBSD-3.0/i386/binary/sets/base.tgz
>>> ...or build from dist
>>> touch /var/db/dhcpd.leases
>>> then ln -sf /etc/dhcpd /var/service
>>> http://www.netbsd.org/Documentation/network/netboot/dhcpd.html

EOF-note
