#!/bin/sh

# (C) 2009-2022 George Georgalis <george@galis.org> unlimited use with this notice 

# http://smarden.org/socklog/configuration.html

# REQUIRE: socklog-inst runit-conf
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

cat >/etc/socklog/unix/run <<EOF
#!/bin/sh
exec 2>&1
# let's make the symlink least pids try and use it ;-)
ln -sfh /dev/log /var/run/log
exec chpst -Unobody socklog unix /dev/log
EOF

ln -s /etc/socklog/* /service

cd /var/log
mkdir -p old
mv maillog* authlog* cron* messages xferlog old/ || true

