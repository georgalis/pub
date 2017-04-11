#!/bin/sh
#
# $Id: Logclear-inst.sh 471 2009-07-25 03:25:25Z root $
#
# clears errors in readproctitle
#
# From: Rob Mayoff <mayoff () dqd ! com>
# To: log@list.cr.yp.to
# Date:  2001-10-09 19:23:39
# http://marc.theaimsgroup.com/?l=log&m=100265849322872
#
# REQUIRE: runit-conf
# BEFORE:
# PROVIDE: Logclear
# KEYWORD: cos7-boot

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
# sv o Logclear
EOF
chmod +x $service/run

mkdir -p /etc/sv
ln -s $service /etc/sv/

