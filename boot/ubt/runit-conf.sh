#!/bin/sh

# REQUIRE: 
# BEFORE:
# PROVIDE: runit-conf
# KEYWORD: ubt

set -e

cat >>/sbin/runsvdir-start <<'EOF'
#!/bin/sh

export PATH=/sbin:/usr/sbin:/bin:/usr/bin
export PATH=$PATH:/usr/local/sbin:/usr/local/bin
export PATH=$PATH:/usr/local/sub

exec env - PATH=$PATH \
runsvdir -P /etc/sv "log: ................................................................................................................................................................................................................................................................................................................................................................................................................"
EOF

mkdir -p /etc/sv
chmod 755 /sbin/runsvdir-start

echo ''
cat >/etc/init.d/runsvdir <<'EOF'
#!/bin/sh

# Provides:          runsvdir
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: runsvdir initscript
# Description:       The runit init service.

printf "Starting runsvdir "
exec /bin/sh -c "/sbin/runsvdir-start &"
EOF

chmod 755 /etc/init.d/runsvdir
ln -s etc/sv /service

/etc/init.d/runsvdir

# create a systemd service XXX
chmod +x /etc/init.d/rc.local
echo /etc/init.d/runsvdir >>/etc/init.d/rc.local

