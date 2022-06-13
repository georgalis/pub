#!/bin/sh
# $Id: cc2netblock.sh 411 2008-07-06 04:01:37Z geo $
#
# LICENSE: <george@galis.org> wrote this file. As long as you retain this
# notice, you can do anything with it or buy beer -- George Georgalis
#
# Update NIC delegations for country codes listed on command line, output CIDR
# entries (when possible) otherwise "start - end range" entries. TLD country
# codes found at http://www.iana.org/cctld/cctld-whois.htm
#
# Run from a terminal to see progress, and the output file location. When no
# terminal is present (eg from cron), the same file is generated but only the cc
# network blocks are sent to stdout.
#
# cc2netblock.sh kr cn
#
# determines the netblocks delegated ro Korea and China. Every third day, or
# once a week, from cron, should be often enough to run.

set -e
countries="$@"
PATH=/bin:/usr/bin

#ftp://ftp.arin.net/pub/stats/arin/delegated-arin-latest
#ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest
#ftp://ftp.ripe.net/ripe/stats/delegated-ripencc-latest
#http://ftp.apnic.net/stats/afrinic/delegated-afrinic-latest
#http://ftp.apnic.net/stats/apnic/delegated-apnic-latest

# apnic mirror and http protocol seem to work best
latestnics="
http://ftp.apnic.net/stats/iana/delegated-iana-latest
http://ftp.apnic.net/stats/afrinic/delegated-afrinic-latest
http://ftp.apnic.net/stats/lacnic/delegated-lacnic-latest
http://ftp.apnic.net/stats/apnic/delegated-apnic-latest
http://ftp.apnic.net/stats/ripe-ncc/delegated-ripencc-latest
http://ftp.apnic.net/stats/arin/delegated-arin-latest
"

[ -t 1 ] && tprintf () { printf "$*" ;} || tprintf () { true ;}

# backup NIC delegated files, make an assignments
# file from latest NIC delegations, the database
# location could be anywhere, tmp seems fine

cd /var/tmp
nics=nic-assignments

# make the output files ready
[ -e "$nics" ] \
	&& mv "$nics" "$nics-`date '+%s'`"
mv -f `mktemp ${0}.XXXX` ${nics}
[ -e "${nics}-cc" ] \
	&& mv "${nics}-cc" "${nics}-cc-`date '+%s'`"
mv -f `mktemp ${0}.XXXX` ${nics}-cc

# identify the parameters, cc table and program generating the file
echo "# ${0} ${@}" >>${nics}-cc
echo "# http://www.iana.org/cctld/cctld-whois.htm" >>${nics}-cc
echo '# $GeorgalisG: script/cc2netblock.sh,v 1.7 2005/09/24 02:59:50 geo Exp $' >>${nics}-cc

# get latest delegated from all nics
for n in $latestnics; do
	f=`basename $n`
	# XXX presume ftp will not allow a symlink attack # [ -e "$f" ] && mv "$f" "{$f}-`date '+%s'`"
	ftp $n 
	cat "$f" >>$nics
done

# remove the $nics-* and delegated-* files not accessed in a while
find ./ -maxdepth 1 -type f \
	\( -atime +9 -a -mtime +9 \) \
	-a \( -name $nics-\* -o \
		-name delegated-\* \) \
	-exec \rm -f \{\} \;

tprintf "Generating non-CDIR netblocks...\n" 

ccex='^#' # must be non-null, make a country code expression
for cc in $countries ; do ccex="${ccex}|${cc}" ; done

# generate output, tries to only match data lines
grep -iE "[^\|]*\|($ccex)\|ipv4\|" $nics \
	| awk -F \| '{ print $4 " " $5 " " $2 " " $1 }' \
		| sed -e '
			s/ 4 /\/30 /
			s/ 8 /\/29 /
			s/ 16 /\/28 /
			s/ 32 /\/27 /
			s/ 64 /\/26 /
			s/ 128 /\/25 /
			s/ 256 /\/24 /
			s/ 512 /\/23 /
			s/ 1024 /\/22 /
			s/ 2048 /\/21 /
			s/ 4096 /\/20 /
			s/ 8192 /\/19 /
			s/ 16384 /\/18 /
			s/ 32768 /\/17 /
			s/ 65536 /\/16 /
			s/ 131072 /\/15 /
			s/ 262144 /\/14 /
			s/ 524288 /\/13 /
			s/ 1048576 /\/12 /
			s/ 2097152 /\/11 /
			s/ 4194304 /\/10 /
			s/ 8388608 /\/9 /
			s/ 16777216 /\/8 /
			# nobody seems to have delegated more than a class c
			# s/ 33554432 /\/7 /
			# s/ 67108864 /\/6 /
			# s/ 134217728 /\/5 /
			# s/ 268435456 /\/4 /
			' \
	| while read i; do
		case $i in
		*/*) # already in cidr format
			echo $i >>${nics}-cc
		;;
 		*) # generate octet - octet range
			 # original address
			 o=`echo $i | awk '{print $1 }'`
			 # number of sequential addresses
			 n=`echo $i | awk '{print $2 }'`
			 # country code
			cc=`echo $i | awk '{print $3 }'`
			 # registry
			 r=`echo $i | awk '{print $4 }'`
			 # start octets
			o4=`echo $o | cut -d\. -f1`
			o3=`echo $o | cut -d\. -f2`
			o2=`echo $o | cut -d\. -f3`
			o1=`echo $o | cut -d\. -f4`
			 # octet deltas
			d4=$(( ( $n                                            ) / 16777216 )) # 2^(3*2^3)
			d3=$(( ( $n - $d4 * 16777216                           ) / 65536    )) # 2^(2*2^3)
			d2=$(( ( $n - $d4 * 16777216 - $d3 * 65536             ) / 256      )) # 2^(1*2^3)
			d1=$(( ( $n - $d4 * 16777216 - $d3 * 65536 - $d2 * 256 ) / 1        )) # 2^(0*2^3)
			 # end octets
			n4=$(( $o4 + $d4 ))
			n3=$(( $o3 + $d3 ))
			n2=$(( $o2 + $d2 ))
			n1=$(( $o1 + $d1 ))
			 # output start - end range with comment
			printf %-44s "${o4}.${o3}.${o2}.${o1} - ${n4}.${n3}.${n2}.${n1} ${cc} ${r}" >>${nics}-cc
			printf "\n" >>${nics}-cc
			tprintf "."
		;;
		esac
	done
[ -t 1 ] && printf "\n$PWD/${nics}-cc\n" || cat ${nics}-cc
exit

# doc from various sources
cat >/dev/null<<"NULL"

The Autonomous System (AS) numbers are used by various routing protocols.
AS numbers are allocated to the regional registries by the IANA.
	AfriNIC		<hostmaster@afrinic.net>
	APNIC		<helpdesk@apnic.net>
	ARIN		<hostmaster@arin.net>
	LACNIC		<hostmaster@lacnic.net>
	RIPE-NCC	<ncc@ripe.net>

http://ftp.apnic.net/stats/arin/CAVEATS


    After the defined file header, and excluding any space or
    comments, each line in the file represents a single allocation
    (or assignment) of a specific range of Internet number resources
    (IPv4, IPv6 or ASN), made by the RIR identified in the record.

    In the case of IPv4 the records may represent non-CIDR ranges
    or CIDR blocks, and therefore the record format represents a
    beginning of range, and a count. This can be converted to
    prefix/length using simple algorithms.

    In the case of IPv6 the record format represents the prefix
    and the count of /128 instances under that prefix.

    Format:

         registry|cc|type|start|value|date|status[|extensions...]

    registry  = One value from the set of defined strings:

                        {apnic,arin,iana,lacnic,ripencc};

    cc        = ISO 2-letter country code of the organization to which the
                allocation or assignment was made, and the enumerated
                variances of

                        {AP,EU,UK}

                These values are not defined in ISO 3166 but are widely used.

    type      = Type of Internet number resource represented in this record,
                One value from the set of defined strings:

                        {asn,ipv4,ipv6}

    start     = In the case of records of type 'ipv4' or 'ipv6'
                this is the IPv4 or IPv6 'first address' of the range.

		In the case of an 16 bit AS number  the format is
		the integer value in the range 0 to 65535, in the
		case of a 32 bit ASN the value is in the range 0
		to 4294967296. No distinction is drawn between 16
		and 32 bit ASN values in the range 0 to 65535.

    value     = In the case of IPv4 address the count of hosts for
                this range. This count does not have to represent a
                CIDR range.

                In the case of an IPv6 address the value will be
                the CIDR prefix length from the 'first address'
                value of <start>.
                In the case of records of type 'asn' the number is
                the count of AS from this start value.

    date      = Date on this allocation/assignment was made by the
                RIR in the format YYYYMMDD;

                Where the allocation or assignment has been
                transferred from another registry, this date
                represents the date of first assignment or allocation
                as received in from the original RIR.

                It is noted that where records do not show a date of
                first assignment, this can take the 00000000 value.

    status    = Type of allocation from the set:

                        {allocated, assigned}

                This is the allocation or assignment made by the
                registry producing the file and not any sub-assignment
                by other agencies. 

   extensions = Any extra data on a line is undefined, but should conform
                to use of the field separator used above.


NULL
