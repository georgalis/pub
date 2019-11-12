#!/bin/sh
#$Id: rrd-disk.sh 608 2010-10-08 08:43:41Z geo $

# Designed for use on NetBSD.
# First set (below) your:
# Database location:	rr=
# HTML location:	htrr=
# All other params should be ok.
# Then invoke:
# Generate db tables,	rrd-disk.sh gen | sh
# Update the db,	rrd-disk.sh db
# Make graphs from db,	rrd-disk.sh graph
# Both db and graph,	rrd-disk.sh
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

[ -z "$RRD_DISK_MOUNT_POINTS" ] && RRD_DISK_MOUNT_POINTS="$(/sbin/mount -t ffs,mfs | awk '{print $3}')"

mkdir -p $rr $htrr/$alpha

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
# 31536000 1 year
# 47304000 18 months
# 126144000 48
# 157680000 60

#                6 hrs, 18 hrs, 36 hrs, 3 days, 10 days, 6 weeks, 8 months, 18 months, 5 years
rri="            21600  64800   129600  259200  864000   3628800  20995200  47304000   157680000"
rri="            21600          129600          864000   3628800  20995200             157680000"

#          1 hr, 6 hr,          36 hrs,         10 days, 6 weeks, 8 months,            5 years
rri_graph="3600  21600          129600          864000   3628800  20995200             157680000"


step=60		# constant
width=600	# constant

timeframe () { # input $1 seconds, output human time window
years=$(($1 / 31536000)) && [ "$years" -ge 3 ] && echo "$years years" && return
months=$(($1 / 2592000)) && [ "$months" -ge 3 ] && echo "$months months" && return
weeks=$(($1 / 604800)) && [ "$weeks" -ge 3 ] && echo "$weeks weeks" && return
days=$(($1 / 86400)) && [ "$days" -ge 3 ] && echo "$days days" && return
hours=$(($1 / 3600 )) && [ "$hours" -ge 3 ] && echo "$hours hours" && return
minutes=$(($1 / 60 )) && [ "$minutes" -ge 3 ] && echo "$minutes minutes" && return
echo "$1 seconds"
}

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
<body background="../background.png">
EOF-header

#bgcolor='#ffffff'
tdconf="align=center valign=middle cellpadding=10"
echo "<table border=0 cellspacing=5  >" >>${indx}
echo "<tr><td align=left colspan=2><a href='../'>Index</a> / <a href='../disk-bonnie.cgi?refresh'>Refresh</a></td>" >>${indx}
#  for n in $rri_graph ; do
#   echo "<td $tdconf>$(timeframe $n)</td>" >>${indx}
#  done
echo "</tr>" >>${indx}

  for mp in $RRD_DISK_MOUNT_POINTS ; do
#  echo "<tr><td $tdconf>$mp</td>" >>${indx}
  echo "<tr>" >>${indx}
   mn="$(echo ${mp##/}| sed 's}/}-}g')" && [ "$mn" = "" ] && mn="root" # assign name for file creation (ie without any /)
   for n in $rri_graph ; do
   echo "<td align=right>$mp</td><td $tdconf>" >>${indx}
    #bmax=$(df -n $mp | tail -n1 | awk '{print $3,$4,"+ 512 * p"}'| dc) # byte capacity
    bmax=$(df -n $mp | tail -n1 | awk '{print $2," 512 * p"}'| dc) # stated byte capacity
    rrdtool graph ${htrr}/${alpha}/${mn}-${n}.png \
 	--slope-mode \
	--color "BACK#ffffff55" \
 	--vertical-label "Disk Bytes" \
 	--title "$host $(df -ih $mp |tail -n1 | sed 's/ [ ]*/ /g')" \
	--lower-limit 0 --upper-limit $bmax --rigid \
	--watermark "$(echo Generated @ $host on $(date))" \
	--end now --start end-${n}s --width $width \
	\
	DEF:Nfree${mn}=${rr}/${mn}_N.rrd:nfree:MAX \
	DEF:Bfree${mn}=${rr}/${mn}_B.rrd:free:MIN \
	DEF:Icap${mn}=${rr}/${mn}_I.rrd:free:MIN \
	\
	AREA:Bfree${mn}\#ccccff:"Free" \
	AREA:Nfree${mn}\#cc2222:"Used":STACK \
	LINE3:Icap${mn}\#cccc22:"%iCap" \
	#
    echo "$(timeframe $n)<br><img align=middle src=./${mn}-$n.png></nobr>" >>${indx}
    echo "</td>" >>${indx}
   done >/dev/null # n
   echo "</tr>">>${indx}
  done # mp
  echo "</table>">>${indx}
  cat >>${indx} <<EOF-body
<P>
The graphing engine automatically chooses the best units for scaling the values.<br>
The scaling factor is displayed alongside the numerical value, with the following meaning:
<ul>
<li>a: 10e-18 Ato</li>
<li>f: 10e-15 Femto</li>
<li>p: 10e-12 Pico</li>
<li>n: 10e-9  Nano</li>
<li>u: 10e-6  Micro</li>
<li>m: 10e-3  Milli</li>
<li>k: 10e+3   Kilo</li>
<li>M: 10e+6   Mega</li>
<li>G: 10e+9   Giga</li>
<li>T: 10e+12  Terra</li>
<li>P: 10e+15  Peta</li>
<li>E: 10e+18  Exa</li>
</ul>
</body>
</html>
EOF-body
 ;;

 db)
  for mp in $RRD_DISK_MOUNT_POINTS ; do
   mn="$(echo ${mp##/}| sed 's}/}-}g')" && [ "$mn" = "" ] && mn="root" # assign name for file creation (ie without any /)
   vN=$(df -n $mp | tail -n1 | awk '{print $3," 512 * p"}'| dc) # stale bytes used
   vB=$(df -n $mp | tail -n1 | awk '{print $4," 512 * p"}'| dc) # stale bytes available
   vI=$(df -in $mp | tail -n1 | awk '{print "4 k",$3,$4,"+ 512 * ",$8," .001 + .01 * * p"}'  | sed -e 's/%//' | dc) # % inode expressed in ratio of Used+Avai (total)l Bytes
   rrdtool update ${rr}/${mn}_N.rrd N:$vN
   rrdtool update ${rr}/${mn}_B.rrd N:$vB
   rrdtool update ${rr}/${mn}_I.rrd N:$vI
  done # mp
 ;;

 gen)
  heartbeat=333	# constant (unknown), updates before unknown min and max
  echo rr=$rr
  for mp in $RRD_DISK_MOUNT_POINTS ; do
   mn="$(echo ${mp##/}| sed 's}/}-}g')" && [ "$mn" = "" ] && mn="root" # assign name for file creation (ie without any /)
   bmax=$(df $mp | tail -n1 | awk '{print $3,$4,"+ 512 * p"}'| dc) # capacity expressed as Used+Avai (total) Bytes
   echo rrd=\${rr}/${mn}_B
   echo rrdtool create \${rrd}.rrd --step $step DS:free:GAUGE:$heartbeat:0:$bmax \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 + 1 ))
    steps=$(( ( $RRA_sec / $step + 1 ) / $rows + 1 ))
    echo RRA:MIN:0.5:$steps:$rows \\
   done # RRA_sec
   echo
   echo rrd=\${rr}/${mn}_I
   echo rrdtool create \${rrd}.rrd --step $step DS:free:GAUGE:$heartbeat:0:$bmax \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 + 1 ))
    steps=$(( ( $RRA_sec / $step + 1 ) / $rows + 1 ))
    echo RRA:MIN:0.5:$steps:$rows \\
   done # RRA_sec
   echo
   echo rrd=\${rr}/${mn}_N
   echo rrdtool create \${rrd}.rrd --step $step DS:nfree:GAUGE:$heartbeat:0:$bmax \\
   for RRA_sec in $rri; do
    rows=$(( $width / 3 + 1 ))
    steps=$(( ( $RRA_sec / $step + 1 ) / $rows + 1 ))
    echo RRA:MAX:0.5:$steps:$rows \\
   done # RRA_sec
  echo
  done # mp
  echo '#*/5 *  * * *   sleep 35 ; nice -n 19 ~/bin/rrd-disk.sh graph ; ~/bin/rrd-load.sh graph'
  echo '#* *    * * *   sleep 15 ; nice -n 19 ~/bin/rrd-disk.sh db    ; ~/bin/rrd-load.sh db'
 ;;

esac # $1
