#!/bin/sh

# REQUIRE: 
# BEFORE:
# PROVIDE: runit-conf
# KEYWORD: nbsd

set -e

cat >>/sbin/runsvdir-start <<'EOF'
#!/bin/sh

export PATH=/sbin:/usr/sbin:/bin:/usr/bin
export PATH=$PATH:/usr/pkg/sbin:/usr/pkg/bin
export PATH=$PATH:/usr/X11R7/bin
export PATH=$PATH:/usr/local/sbin:/usr/local/bin
export PATH=$PATH:/usr/local/sub

exec env - PATH=$PATH \
runsvdir -P /etc/sv "log: ................................................................................................................................................................................................................................................................................................................................................................................................................"
EOF

mkdir -p /etc/sv
chmod 755 /sbin/runsvdir-start

echo ''
cat >/etc/rc.d/runsvdir <<'EOF'
#!/bin/sh

# PROVIDE: runsvdir
# REQUIRE: mountcritremote sysdb wscons
# BEFORE:  SERVERS

printf "Starting runsvdir "
exec /bin/csh -cf "/sbin/runsvdir-start &"
EOF

chmod 755 /etc/rc.d/runsvdir
ln -s etc/sv /service

/etc/rc.d/runsvdir

