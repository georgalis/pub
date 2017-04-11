#!/bin/sh

# invoke to execute the specified files in current directory

# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

set -e

cd $(dirname $0)
d="$(date) $PWD $0 (exec)"
keyword=$(basename $PWD)
echo "$d" >>/var/log/$keyword

scripts="
=time
=hostroot
etc
runit-inst.sh
runit-conf.sh
socklog-inst.sh
socklog-conf.sh
path
shell
skel
apt-min
apt-main
ipsvd-inst.sh
daemontools-tai-inst.sh
cron
Logclear-inst.sh
"

for part in $scripts ; do
	#eval _value=\$${part}
	#case $_value in {/etc/rc.subr checkyesno}
	grep -q " ${part} success$" /var/log/$keyword \
		|| { echo "sh ./$part ##############################################################"
			sh ./$part \
			&& echo "$(date) ${part} success" >>/var/log/$keyword \
			|| echo "$(date) ${part} fail" >>/var/log/$keyword
		} # no prior success
done # part
exit 0

