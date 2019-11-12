#!/bin/sh
#$Id: rrd-load.sh 607 2010-10-08 08:09:17Z geo $

# Designed for use on NetBSD.
# First set (below) your:
# Database location:	rr=
# HTML location:	htrr=
# All other params should be ok.
# Then invoke:
# Generate db tables,	rrd-cpu.sh gen | sh
# Update the db,	rrd-cpu.sh db
# Make graphs from db,	rrd-cpu.sh graph
# Both db and graph,	rrd-cpu.sh
# The gen function also dumps an example crontab entry

# LICENSE: <george@galis.org> wrote this file. As long as you retain
# this notice, you can do anything with it -- George Georgalis


set -e
b="$(basename $0 | sed 's/.[^.]*$//')" # this program name less (.sh) extension
alpha="$b-$(hostname)"

# Set the location for the db tables and the output html/png
rr=$HOME/var/db/rrd/${alpha}
rr=/var/db/rrd/${alpha}

# Set the location for the HTML output
htrr=$HOME/public_html/monitor
htrr=/usr/local/www/vhost/iuxta.com/htdoc/monitor/
htrr=/var/db/rrd-www/

indx=${htrr}/${alpha}/index.html

#w=$(whoami) # uid running the tests
#t="/var/shm/$(date '+%Y%m%d_%H%M%S')-${b}-$$" # tmp file basename
#rm -f ${t}.2 ${t}

N=$(date +%s)
hz=$(/sbin/sysctl kern.clockrate | awk '{print $10}' | sed 's/,//')
indx=${htrr}/${alpha}/index.html
mkdir -p $rr ${htrr}/${alpha}

# seconds in...
# 3600	1 hour
# 7200	2
# 10800 3
# 14400 4
# 21600 6
# 36000	10
# 64800 18
# 86400 24
# 129600 36
# 259200 3 days
# 604800 7
# 864000 10
# 3628800 6 weeks
# 20995200 8 months
# 47304000 18
# 126144000 48
# 157680000 60

#                6 hrs, 18 hrs, 36 hrs, 3 days, 10 days, 6 weeks, 8 months, 18 months, 5 years
rri="            21600  64800   129600  259200  864000   3628800  20995200  47304000   157680000"
rri="            21600          129600          864000   3628800  20995200             157680000"

#          1 hr, 6 hr,          36 hrs,         10 days, 6 weeks, 8 months,            5 years
rri_graph="3600  21600          129600          864000   3628800  20995200             157680000"

step=60		# constant
width=600	# constant
height=100	# constant

case $1 in

 '')
  sh $0 db
  sh $0 graph
 ;;

 graph)
cat >${indx}<<EOF-header
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
	"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>${alpha}</title>
</head>
<body background="../sunset-bg.png">
<nobr>
<a href="../${alpha}.cgi?refresh">Refresh</a><br>
EOF-header
echo "<table border=0><tr><td align=center valign=middle>CPU %<br>Utilization</td><td>" >>${indx}
   for n in $rri_graph ; do
    rrdtool graph ${htrr}/${alpha}/cpu-${n}.png \
 	--slope-mode \
 	--vertical-label "Sigma CPU %" \
 	--title "$(hostname) $(uptime)" \
	--watermark "seconds=$n hours=$(($n / 3600 )) days=$(($n / 86400)) weeks=$(($n / 604800)) months=$(($n / 2592000))" \
	--end now --start end-${n}s --width $width --height $height \
	--lower-limit 0 --rigid \
	\
	DEF:user=${rr}/user.rrd:user:LAST \
	DEF:nice=${rr}/nice.rrd:nice:LAST \
	DEF:sys=${rr}/sys.rrd:sys:LAST \
	DEF:intr=${rr}/intr.rrd:intr:LAST \
	DEF:idle=${rr}/idle.rrd:idle:LAST \
	\
	AREA:intr\#c43921:"Intr":STACK \
	AREA:sys\#208c85:"Sys":STACK \
	AREA:nice\#fbfaa1:"Nice":STACK \
	AREA:user\#539fc1:"User":STACK \
	#--lower-limit 0 --rigid \
    echo "<img src=./cpu-$n.png>" >>${indx}
   done >/dev/null # n
   echo "</td></tr>" >>${indx}
   #
   echo "<tr><td align=center valign=middle>CPU %<br>Idle time</td><td>" >>${indx}
   for n in $rri_graph ; do
    rrdtool graph ${htrr}/${alpha}/idle-${n}.png \
 	--slope-mode \
 	--vertical-label "Sigma CPU %" \
 	--title "$(hostname) $(uptime)" \
	--watermark "seconds=$n hours=$(($n / 3600 )) days=$(($n / 86400)) weeks=$(($n / 604800)) months=$(($n / 2592000))" \
	--end now --start end-${n}s --width $width --height $height \
	--lower-limit 0 --upper-limit 100 --rigid \
	\
	DEF:idle=${rr}/idle.rrd:idle:LAST \
	\
	AREA:idle\#7bf67e:"Idle" \
	#
    echo "<img src=./idle-$n.png>" >>${indx}
   done >/dev/null # n
   echo "</td></tr>" >>${indx}
   #
   echo "<tr><td align=center valign=middle>CPU Load<br>Average</td><td>" >>${indx}
   for n in $rri_graph ; do
    rrdtool graph ${htrr}/${alpha}/loadave-${n}.png \
 	--slope-mode \
 	--vertical-label "CPU Queue" \
 	--title "$(hostname) $(uptime)" \
	--watermark "seconds=$n hours=$(($n / 3600 )) days=$(($n / 86400)) weeks=$(($n / 604800)) months=$(($n / 2592000))" \
	--end now --start end-${n}s --width $width --height $height \
	--logarithmic \
	--lower-limit 0.09 --rigid \
	\
	DEF:load1=${rr}/load1.rrd:load1:LAST \
	DEF:load5=${rr}/load5.rrd:load5:LAST \
	DEF:load15=${rr}/load15.rrd:load15:LAST \
	\
	AREA:load15\#cccc99:"Load15" \
	AREA:load5\#eeee88:"Load5" \
	AREA:load1\#dddd1d:"Load1" \
	\
	HRULE:1#9999bb \
	# LINE:load\#54007c:"load" \
    echo "<img src=./loadave-$n.png>" >>${indx}
   done >/dev/null # n
   echo "</td></tr></table>" >>${indx}
  cat >>${indx} <<EOF-body
</nobr>
</body>
</html>
EOF-body

 ;;

 db)
  load1=$(uptime | sed -e 's/.*averages: //' -e 's/,.*//')
  load5=$(uptime | sed -e 's/.*averages: //' -e 's/,//g' | awk '{print $2}')
  load15=$(uptime | sed -e 's/.*averages://' -e 's/.*, //g')
  rrdtool update ${rr}/load1.rrd N:${load1}
  rrdtool update ${rr}/load5.rrd N:${load5}
  rrdtool update ${rr}/load15.rrd N:${load15}
  eval $(/sbin/sysctl -n kern.cp_time | tr "," "\n" |sed -e 's/ //g')
  rrdtool update ${rr}/user.rrd N:${user}
  rrdtool update ${rr}/nice.rrd N:${nice}
  rrdtool update ${rr}/intr.rrd N:${intr}
  rrdtool update ${rr}/idle.rrd N:${idle}
  rrdtool update ${rr}/sys.rrd N:${sys}

 ;;

 gen)
  heartbeat=333	# constant (unknown), updates before unknown min and max
  echo rr=${rr}
  echo mkdir -p \${rr}
  echo
  #
  echo gauge=load1
  echo rrdtool create \${rr}/\${gauge}.rrd --step $step DS:\${gauge}:GAUGE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
   echo
  #
  echo gauge=load5
  echo rrdtool create \${rr}/\${gauge}.rrd --step $step DS:\${gauge}:GAUGE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
   echo
  #
  echo gauge=load15
  echo rrdtool create \${rr}/\${gauge}.rrd --step $step DS:\${gauge}:GAUGE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
   echo
  #
  echo clock=user
  echo rrdtool create \${rr}/\${clock}.rrd --step $step DS:\${clock}:DERIVE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
   echo
  #
  echo clock=nice
  echo rrdtool create \${rr}/\${clock}.rrd --step $step DS:\${clock}:DERIVE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
   echo
  #
  echo clock=sys
  echo rrdtool create \${rr}/\${clock}.rrd --step $step DS:\${clock}:DERIVE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
   echo
  #
  echo clock=intr
  echo rrdtool create \${rr}/\${clock}.rrd --step $step DS:\${clock}:DERIVE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
   echo
  #
  echo clock=idle
  echo rrdtool create \${rr}/\${clock}.rrd --step $step DS:\${clock}:DERIVE:$heartbeat:0:U \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 ))
    steps=$(( ( $RRA_sec / $step ) / $rows ))
    echo RRA:LAST:0.5:$steps:$rows \\
   done # RRA_sec
  #
  echo
  echo "#*/5 *  * * *   sleep 35 ; nice -n 19 rrd-disk.sh graph ; nice -n 19 ${alpha}.sh graph"
  echo "#* *    * * *   sleep 15 ; nice -n 19 rrd-disk.sh db    ; nice -n 19 ${alpha}.sh db"
 ;;

esac # $1

exit

DELAY=1

( sysctl kern.cp_time ; sleep $DELAY ; sysctl kern.cp_time ) | awk '
{
        a = $4 + $7 + $10 + $13
        b = $16

        if (oldtot == 0) {
                oldcpu = a
                oldtot = a + b
        } else {
                newcpu = a
                newtot = a + b
                print "usage = ", (newcpu - oldcpu) / (newtot - oldtot)
        }
}
'

