#!/bin/sh

# REQUIRE: 
# BEFORE:
# PROVIDE: runit-conf
# KEYWORD: nbsd

set -e

cat >>/sbin/runsvdir-start <<'EOF'
#!/bin/sh

. /etc/profile

exec env - PATH=$PATH \
runsvdir -P /etc/sv "log: ................................................................................................................................................................................................................................................................................................................................................................................................................"
EOF

mkdir -p /etc/sv
chmod 755 /sbin/runsvdir-start

cat >/etc/rc.d/runsvdir <<'EOF'
#!/bin/sh

# PROVIDE: runsvdir
# REQUIRE: mountcritremote sysdb wscons
# BEFORE:  SERVERS

printf "Starting runsvdir "
exec /bin/csh -cf "/sbin/runsvdir-start &"
EOF

chmod 755 /etc/rc.d/runsvdir

/etc/rc.d/runsvdir

