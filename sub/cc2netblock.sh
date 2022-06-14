#!/bin/sh

# (c) 2005-2022 George Georgalis <george@galis.org> unlimited use with this notice
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

[ -t 1 ] && tprintf () { printf "$*" ;} || tprintf () { true ;}

cd /var/tmp
stats=nro-delegated-stats

# only download stats on new revision, retain old stats on download fail,
# rotate versions for diff study

curl -s --head https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/${stats} \
    | grep -E '(^Last-Modified|^Content-Length)' >${stats}-header~
[ "$(cksum <${stats}-header~)" = "$(cksum <${stats}-header)" ] \
    || {
        [ -e "${stats}" ] && mv "${stats}" "${stats}-0"
        curl -s --compressed --remote-name --remote-time \
            https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/${stats} \
            && {
                mv ${stats}-header~ ${stats}-header
                [ -e "${stats}-8" ] && mv "${stats}-8" "${stats}-9"
                [ -e "${stats}-7" ] && mv "${stats}-7" "${stats}-8"
                [ -e "${stats}-6" ] && mv "${stats}-6" "${stats}-7"
                [ -e "${stats}-5" ] && mv "${stats}-5" "${stats}-6"
                [ -e "${stats}-4" ] && mv "${stats}-4" "${stats}-5"
                [ -e "${stats}-3" ] && mv "${stats}-3" "${stats}-4"
                [ -e "${stats}-2" ] && mv "${stats}-2" "${stats}-3"
                [ -e "${stats}-1" ] && mv "${stats}-1" "${stats}-2"
                [ -e "${stats}-0" ] && mv "${stats}-0" "${stats}-1"
                } || mv "${stats}-0" "${stats}"
        }

# identify the parameters, cc table and program generating the file
echo "# ${0} ${@}" >${stats}-cc~
echo "# $(date)"  >>${stats}-cc~
echo "# http://www.iana.org/cctld/cctld-whois.htm"                    >>${stats}-cc~
echo "# https://www.iso.org/obp/ui/"                                  >>${stats}-cc~
echo "# https://en.wikipedia.org/wiki/Country_code_top-level_domain"  >>${stats}-cc~
echo "# https://www.iban.com/country-codes"                           >>${stats}-cc~

[ -e "${stats}-cc-index" ] \
    || w3m -cols 200  https://www.iban.com/country-codes \
        | awk '/Afghanistan/,/Zimbabwe/' \
        | sed  -e 's/[ ]\{11\}[^ ]\{3\}[ ]*[^ ]\{3\}//' \
            | while read a ; do
                echo $a \
                    | sed 's/.* \(..\)$/\1/' \
                    | tr '\n' ' ' \
                    | tr '[:upper:]' '[:lower:]'
                echo $a | sed -E 's/[ ]*..$/ /'
                done | sort >${stats}-cc-index

echo "${countries}" | tr ' ' '\n' | sort -u | sed '/^$/d' \
  | while IFS= read cc ; do
      grep "^${cc} " ${stats}-cc-index | sed -e 's/^/# /' >>${stats}-cc~
      done

# make a country code regex, must be non-null,
# and export for availability after the pipeline
ccre='^#'
countries="$(echo "${countries}" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
for cc in $countries ; do ccre="${ccre}|${cc}" ; done

tprintf "Generating CIDR blocks from ${PWD}/${stats} " 

# generate output, tries to only match data lines
grep -iE "[^\|]*\|($ccre)\|ipv4\|" $stats \
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
			echo $i >>${stats}-cc~
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
			printf %-44s "${o4}.${o3}.${o2}.${o1} - ${n4}.${n3}.${n2}.${n1} ${cc} ${r}" >>${stats}-cc~
			printf "\n" >>${stats}-cc~
			tprintf "."
		;;
		esac
	done
cc_names=$(echo $countries | sed 's/ /-/g')
mv ${stats}-cc~ ${stats}-cc=${cc_names}
[ -t 1 ] && printf "\n$PWD/${stats}-cc=${cc_names}\n" || cat ${stats}-cc=${cc_names}
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

https://www.nro.net/about/rirs/statistics/

 AFRINIC Allocation Statistics ftp://ftp.afrinic.net/pub/stats/
   APNIC Allocation Statistics ftp://ftp.apnic.net/public/stats/apnic/
    ARIN Allocation Statistics ftp://ftp.arin.net/pub/stats/arin/
  LACNIC Allocation Statistics ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest
RIPE NCC Allocation Statistics ftp://ftp.ripe.net/pub/stats/ripencc/


The delegated-extended file contains a daily updated report of the distribution of Internet number resources:

    IPv4 address ranges
    IPv6 address ranges
    Autonomous System Numbers (ASNs) 

    https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/nro-delegated-stats

https://www.nro.net/ripe-ncc-to-publish-nro-extended-allocation-and-assignment-reports/

https://www.nro.net/wp-content/uploads/nro-extended-stats-readme5.txt


    STATISTICS FORMAT
____________________________________________________________________



1.1   File name
------------------


Each file is named using the format:

    delegated-extended

1.2   File format
-------------------

The file consists of: 

    - comments
    - file header lines
    - records

Header and record lines are structured as 'comma separated fields'
(CSV). Leading and trailing blank text in fields not meaningful.

The vertical line character '|' (ASCII code 0x7c) is used as the
CSV field separator.

After the header lines, records are not sorted.



1.2.1 Comments
----------------


Comments are denoted by # at the beginning of a line. No
line-embedded comments are permitted. Comments may occur at
any place in the file.

Example:

    #optional comments.
    #   any number of lines.

    #another optional comment.

Blank lines are permitted, and may occur at any place in the file.



1.2.2 File header
-------------------


The file header consists of the version line and the summary
lines for each type of record. 


Version line
------------

Format:

    version|registry|serial|records|startdate|enddate|UTCoffset

Where:

    version    format version number of this file, 
               currently 2.3;

    registry   as for records and filename (see below);

    serial     serial number of this file (within the
               creating RIR series);

    records    number of records in file, excluding blank
               lines, summary lines, the version line and 
               comments;

    startdate  start date of time period, in yyyymmdd 
               format;

    enddate    end date of period in yyyymmdd format;

    UTCoffset  offset from UTC (+/- hours) of local RIR
               producing file.



Summary line
------------

The summary lines count the number of record lines of each type in 
the file.

Format:

    registry|*|type|*|count|summary

Where:

    registry   as for records (see below);

    *          an ASCII '*' (unused field, retained for
               spreadsheet purposes);

    type       as for records (defined below);

    count      sum of the number of record lines of this 
               type in the file.

    summary    the ASCII string 'summary' (to distinguish 
               the record line);


Note that the count does not equate to the total amount of resources
for each class of record. This is to be computed from the records
themselves.



1.2.3 Records
---------------

After the defined file header, and excluding any space or comments,
each line in the file represents a single allocation (or assignment)
of a specific range of Internet number resources (IPv4, IPv6 or
ASN), made by the RIR identified in the record.

IPv4  records may represent non-CIDR ranges or CIDR blocks, and 
therefore the record format represents the beginning of range, and a
count. This can be converted to prefix/length using simple algorithms.

IPv6 records represent the prefix and the count of /128 instances 
under that prefix.

Format:

    registry|cc|type|start|value|date|status|opaque-id[|extensions...]

Where:

    registry   The registry from which the data is taken.

    cc         ISO 3166 2-letter code of the organisation to
               which the allocation or assignment was made. 
               May also include the following non-ISO 3166
               code: 

    type       Type of Internet number resource represented
               in this record. One value from the set of 
               defined strings:

                   {asn,ipv4,ipv6}

    start      In the case of records of type 'ipv4' or
               'ipv6' this is the IPv4 or IPv6 'first
               address' of the  range.

               In the case of an 16 bit AS number, the
               format is the integer value in the range:

                   0 - 65535

               In the case of a 32 bit ASN,  the value is
               in the range:

                   0 - 4294967296
  
               No distinction is drawn between 16 and 32
               bit ASN values in the range 0 to 65535.

    value      In the case of IPv4 address the count of
               hosts for this range. This count does not 
               have to represent a CIDR range.

               In the case of an IPv6 address the value 
               will be the CIDR prefix length from the 
               'first address'  value of <start>.

               In the case of records of type 'asn' the 
               number is the count of AS from this start 
               value.

    date       Date on this allocation/assignment was made
               by the RIR in the format:

                   YYYYMMDD

               Where the allocation or assignment has been
               transferred from another registry, this date
               represents the date of first assignment or
               allocation as received in from the original
               RIR.

               It is noted that where records do not show a 
               date of first assignment, this can take the 
               0000/00/00 value.

    status     Type of record from the set:

                   {available, allocated, assigned, reserved}

                   available    The resource has not been allocated
                                or assigned to any entity.

                   allocated    An allocation made by the registry 
                                producing the file.

                   assigned     An assignment made by the registry
                                producing the file.

                   reserved     The resource has not been allocated
                                or assigned to any entity, and is
                                not available for allocation or
                                assignment.

    opaque-id  This is an in-series identifier which uniquely
               identifies a single organisation, an Internet
               number resource holder.

               All records in the file with the same opaque-id
               are registered to the same resource holder.

               The opaque-id is not guaranteed to be constant
               between versions of the file.

               If the records are collated by type, opaque-id and
               date, records of the same type for the same opaque-id
               for the same date can be held to be a single
               assignment or allocation

    extensions In future, this may include extra data that
               is yet to be defined.



1.3   Historical resources
----------------------------


Early Registration Transfers (ERX) and legacy records do not
have any special tagging in the statistics reports. 


____________________________________________________________________


If you any questions or comments about these reports, please contact
<exec-secretary@nro.net>

____________________________________________________________________

NULL
