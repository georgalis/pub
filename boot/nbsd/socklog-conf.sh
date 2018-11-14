#!/bin/sh

# Unlimited use with this notice. (C) George Georgalis <george@galis.org>

# http://smarden.org/socklog/configuration.html

# REQUIRE: socklog-inst
# BEFORE:
# PROVIDE: socklog-conf
# KEYWORD: nbsd

set -e

grep -e "^log:" /etc/passwd >/dev/null || /usr/sbin/useradd -d "" -g =uid -r 1..99 -s /sbin/nologin log

/etc/rc.d/syslogd stop
grep 'syslogd=no' /etc/rc.conf >/dev/null || echo 'syslogd=no' >>/etc/rc.conf
sed '/^0.*newsyslog$/s/^/#/' /var/cron/tabs/root >/var/cron/tabs/root~ &&
	mv /var/cron/tabs/root~ /var/cron/tabs/root

socklog-conf klog nobody log
socklog-conf inet nobody log
socklog-conf unix nobody log

cat >/etc/sv/socklog-unix/log/run<<'EOF'
#!/bin/sh
# $Id: socklog-conf.sh 465 2009-07-25 03:03:03Z root $
exec chpst -ulog svlogd -tt \
  main/main main/auth main/cron main/daemon main/debug main/ftp \
  main/kern main/local main/mail main/news main/syslog main/user
EOF

cat >/etc/sv/socklog-unix/run<<'EOF'
#!/bin/sh
# $Id: socklog-conf.sh 465 2009-07-25 03:03:03Z root $
exec 2>&1
ln -shf /dev/log /var/run/log
exec chpst -Unobody socklog unix /var/run/log
EOF

chmod 755 /etc/sv/socklog-unix/run
chmod 755 /etc/sv/socklog-unix/log/run

cd /var/log
mkdir old
mv maillog* authlog* cron* messages xferlog old/

