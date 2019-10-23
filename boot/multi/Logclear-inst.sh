#!/bin/sh
#
# clears errors in readproctitle
#
# When you want to clear the service errors, just run this:
# svc -o /service/zclear
#
# From: Rob Mayoff <mayoff () dqd ! com>
# To: log@list.cr.yp.to
# Date:  2001-10-09 19:23:39
# http://marc.theaimsgroup.com/?l=log&m=100265849322872
#

set -e
service=/usr/local/etc/Logclear
mkdir -p $service
touch $service/down
chmod a-w $service/down

cat >$service/run<<"EOF"
#!/bin/sh
exec 1>&2
yes '' | head -4000 | tr '\n' .

# When you want to clear the service errors, just run this:
# svc -o /service/Logclear
# or, if you use runsv,
# sv o Logclear
EOF
chmod +x $service/run

test -d /service && ln -sh $service /service/ || true
test -d /var/service && ln -sh $service /var/service/ || true
test -d /etc/socklog && ln -sh $service /etc/socklog/ || true

