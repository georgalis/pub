#!/bin/sh

# Unlimited use with this notice (c) 2008, 2017 George Georgalis <george@galis.org>

set -e
set -x

cat >/package/admin/keeplogs<<'EOF'
#!/bin/sh
#
# keeplogs : a log saver for multilog
#
# Move ./@* files to ./logs, (symlink of or) a directory for log
# archives. Typically keeplogs is placed in /package/admin/,
# symlinked in /command, called as a multilog processor in
# /service/*/log/run and ./logs is a symlink to a partition for
# logs, eg /var/log/apache/logs/.
#
# #!/bin/sh
# exec setuidgid log multilog t ssize nnum !keeplogs ./main
#
# This routine is called just before a completed log is written
# and a new archive is written immediately after it runs. :-\ A
# short delay in a forked subshell doesn't look clean but moves
# the next log.
#
# In an extreme situation, multilog might rotate logs faster
# than the delay...
#
# http://cr.yp.to/daemontools/multilog.html
#
# Unlimited use with this notice (c) 2008, 2017 George Georgalis <george@galis.org>

[ -d ./logs -o -L ./logs ] || mkdir ./logs
(
	sleep 5
	[ "`ls @* 2>/dev/null`" ] && mv @* ./logs/
) &
exec cat -
EOF

chmod 755 /package/admin/keeplogs
cd /command
ln -sf /package/admin/keeplogs
