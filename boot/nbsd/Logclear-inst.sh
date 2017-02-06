#!/bin/sh
#
# ./Logclear-inst.sh
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
# KEYWORD: nbsd

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
