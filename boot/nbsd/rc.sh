#!/bin/sh

set -e
d="$(date) $PWD $0 (exec)"
cd $(dirname $0)
keyword=$(basename $PWD)
echo "$d" >>/var/log/$keyword

/sbin/rcorder -k $keyword * | while read part; do
	#eval _value=\$${part}
	#case $_value in {/etc/rc.subr checkyesno}
	grep -q " ${part} success$" /var/log/$keyword \
		|| { echo "sh ./$part ##############################################################"
			sh ./$part \
			&& echo "$(date) ${part} success" >>/var/log/$keyword \
			|| echo "$(date) ${part} fail" >>/var/log/$keyword ;} # no prior success
done # part
exit 0
