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

# let's make the symlink least pids try and use it ;-)
cat >/etc/socklog/unix/run <<EOF
#!/bin/sh
exec 2>&1
ln -sfh /dev/log /var/run/log
exec chpst -Unobody socklog unix /dev/log
EOF

mkdir -p /etc/sv
ln -s /etc/socklog/* /etc/sv

cd /var/log
mkdir -p old
mv maillog* authlog* cron* messages xferlog old/ || true

# rm -rf /etc/sv /etc/socklog /var/log/socklog* /dev/log

