#!/usr/bin/env bash
# test-srt.sh --- regression suite for srt
#
# usage: test-srt.sh [path-to-srt]     exit 0 when every case passes
# Covers plan-srt.md section 10, cases 1-13, then the bash function
# (14) and key encoding (15). The count of cases run varies by host:
# those needing a non-root user or an enforced address-space limit
# skip themselves.
#
# revision 6af8a908 20261114 103136 PST Sat --- r0.6: -x, last column, bare -k, -k-N, -D; -kr5 and -k1x cases revised
# revision 6af889a5 20261114 081741 PST Sat --- r0.5.1: -S with -u asserted by key set, not by bytes
# revision 6af87ca7 20261114 072215 PST Sat --- r0.5: --fn replaces SRT_FN; form selection; case 15 (key encoding)
# revision 6af871c9 20261114 063553 PST Sat --- r0.4.2: address rules pinned; one-name case made independent of the caller environment
# revision 6af86b89 20261114 060913 PST Sat --- r0.4.1: function is one name; case 14 checks it
# revision 6af81dc6 20261114 003726 PST Sat --- r0.3: adds case 7 (-b outline)
# revision 6af81678 20261114 000616 PST Sat --- r0.2: adds case 10 (spill)
# revision 6af8010b 20261113 223451 PST Fri --- r0.1
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
set -euo pipefail

S=${1:-./srt}
[[ $S == /* ]] || S=$PWD/$S
[ -x "$S" ] || { printf 'test-srt.sh: %s: not executable\n' "$S" >&2 ; exit 2 ;}
# the bash function, when it sits beside this script or is named
read -r HERE < <(cd "$(dirname "$0")" && pwd)
FN=${SRT_FN_FILE:-$HERE/srt.fn.bash}
[[ $FN == /* ]] || FN=$PWD/$FN

# scratch: literal class srt-test., kept suffix only
tmp_id=
trap '[ -z "$tmp_id" ] || rm -rf "${TMPDIR:-/tmp}/srt-test.$tmp_id"' EXIT
trap 'exit 130' INT HUP TERM
read -r D < <(mktemp -d "${TMPDIR:-/tmp}/srt-test.XXXXXX")
tmp_id=${D##*/srt-test.}
[[ $tmp_id =~ ^[A-Za-z0-9]+$ ]] || { tmp_id= ; exit 2 ;}
cd "$D"

pass=0 fail=0
eq(){ # name want got
  [ "$2" == "$3" ] && { pass=$((pass+1)) ;} || {
    fail=$((fail+1)) ; printf 'FAIL %s\n  want: %q\n  got:  %q\n' "$1" "$2" "$3" ;} ;}
st(){ # name want-status command... (stdin empty, output discarded)
  local n=$1 w=$2 r=0 ; shift 2
  "$@" </dev/null >/dev/null 2>&1 || r=$?
  eq "$n" "$w" "$r" ;}
srt(){ "$S" "$@" ;}
L(){ printf '%s\n' "$@" ;}   # lines

# ---- 1 grammar ------------------------------------------------------
st 'usage -h' 0 srt -h
st 'manual --help' 0 srt --help
st 'version -V' 0 srt -V
st '-z retired for -Z' 2 srt -z
st 'version --version' 0 srt --version
read -r v < <(srt -V) ; eq 'version text' 'srt r0.' "${v:0:7}"
st 'unknown short' 2 srt -Q
st 'unknown long' 2 srt --nonesuch
st 'eliminated -M' 2 srt -M
st 'eliminated -l' 2 srt -l
st 'eliminated --parallel' 2 srt --parallel=2
st 'eliminated --radixsort' 2 srt --radixsort
st 'no-op -s -m' 0 srt -s -m
st 'no-op --stable --merge' 0 srt --stable --merge
st '-k offset refused' 2 srt -k2.3
st '-k duplicate column refused' 2 srt -k2,2
st '-k duplicate across options refused' 2 srt -k2 -k2
st '-k column zero refused' 2 srt -k0
st '-k unknown letter refused' 2 srt -k1q
st 'bare -k accepted' 0 srt -k
st '-kr5 retired' 2 srt -kr5
st '-k-0 refused' 2 srt -k-0
st '-k-1 accepted' 0 srt -k-1
st '-D with -c' 2 srt -D -c
st '-D with -C' 2 srt -D -C
st '-D with -R' 2 srt -D -R
st '-D with -b' 2 srt -D -b
st '-D accepted' 0 srt -D
st 'type conflict -x -n' 2 srt -x -n
st 'type conflict in key -k1xn' 2 srt -k1xn
st 'type conflict global' 2 srt -n -v
st 'type conflict in key' 2 srt -k1nv
st 'type conflict -d -g' 2 srt -dg
st '-c with -o' 2 srt -c -o out
st '-C with -o' 2 srt -C -o out
st '-R with -k' 2 srt -R -k1
st '-R with -n' 2 srt -R -n
st '-R with -c' 2 srt -R -c
st '-t multibyte refused' 2 srt -t ab
st '--mem bad suffix' 2 srt --mem 5x
st '--mem zero' 2 srt --mem 0
st '--mem 64m' 0 srt --mem 64m
st '--mem=1g' 0 srt --mem=1g
st '--mem 4096b' 0 srt --mem 4096b
st 'SRT_MEM bad' 2 env SRT_MEM=bogus "$S"
st 'SRT_MEM ok' 0 env SRT_MEM=8k "$S"
st '-T not a directory' 2 srt -T /nonexistent/dir
st '-T directory' 0 srt -T .
st '-b accepts empty input' 0 srt -b
st '-R with -b' 2 srt -R -b
st 'missing file' 2 srt nonexistent-file
st 'long option stray argument' 2 srt --unique=1
eq 'cluster -nr' $'10\n2\n1' "$(L 2 10 1 | srt -nr)"
eq 'long --numeric --reverse' $'10\n2\n1' "$(L 2 10 1 | srt --numeric --reverse)"
eq 'attached and separate -k' "$(L 'a 2' 'b 1' | srt -k2)" "$(L 'a 2' 'b 1' | srt -k 2)"
eq '--separator=:' $'b:1\na:2' "$(L a:2 b:1 | srt --separator=: -k2)"
L b a > ./-x
eq 'operand after --' $'a\nb' "$(srt -- -x)"
eq 'dash is stdin' $'a\nb' "$(L b a | srt -)"
eq 'options after operands' $'b\na' "$(srt -- -x | srt - -r)"

# ---- 2 keys ---------------------------------------------------------
six=( 'b x 2 q 1 z' 'a x 1 q 2 z' 'a x 2 q 1 z' 'a y 1 q 1 z'
      'a x 1 r 1 z' 'a x 1 q 1 z' 'a x 1 q 1 y' )
want=$'a x 1 q 1 y\na x 1 q 1 z\na x 1 r 1 z\na y 1 q 1 z\na x 2 q 1 z\nb x 2 q 1 z\na x 1 q 2 z'
eq '-k5n,3 is 5,3,1,2,4,6' "$want" "$(L "${six[@]}" | srt -k5n,3)"
eq '-k5 -k3 same as -k5,3' "$(L "${six[@]}" | srt -k5,3)" "$(L "${six[@]}" | srt -k5 -k3)"
eq 'per-key options replace global' $'1 c\n2 a\n10 b\n10 a' \
  "$(L '2 a' '10 b' '10 a' '1 c' | srt -r -k1n,2)"
eq 'key letters replace, not add to, global -n' $'2 a\n10 b\n10 a\n1 c' \
  "$(L '2 a' '10 b' '10 a' '1 c' | srt -n -k1r)"
# the examples of --help, GLOBAL AND KEY OPTIONS, pinned
eq 'manual: -n -k1r is reversed text' $'2\n10\n1' "$(L 2 10 1 | srt -n -k1r)"
eq 'manual: -k1nr is reversed numeric' $'10\n2\n1' "$(L 2 10 1 | srt -k1nr)"
eq 'manual: global option position does not matter' "$(L 2 10 1 | srt -n -k1r)" "$(L 2 10 1 | srt -k1r -n)"
eq 'manual: -r -k5n,3' $'b z x y 1\nb a x y 2\na z x y 2' \
  "$(L 'a z x y 2' 'b a x y 2' 'b z x y 1' | srt -r -k5n,3)"
eq 'manual: -f -k2n' $'B 2\na 10\nA 10' "$(L 'a 10' 'B 2' 'A 10' | srt -f -k2n)"
eq 'manual: letterless keys keep the global set' "$(L '9 x 3' '10 x 3' '2 x 20' | srt -nr -k3,1)" \
  "$(L '9 x 3' '10 x 3' '2 x 20' | srt -k3nr,1nr -nr)"
st 'manual has the key-option section' 0 bash -c "\"$S\" --help | grep -q \"^GLOBAL AND KEY OPTIONS\""
eq 'short record has empty key' $'a\nb\na x' "$(L b 'a x' a | srt -k2)"
eq '-t keeps empty columns' $'a::1\na:b:0' "$(L a:b:0 a::1 | srt -t: -k2,3n)"
eq '-t: the last text column runs on' $'z::0\nx::1\ny:a:2' "$(L x::1 y:a:2 z::0 | srt -t: -k2)"
eq '-t \t' $'b\t1\na\t2' "$(printf 'a\t2\nb\t1\n' | srt -t '\t' -k2)"
eq 'blank runs are one separator' $'a  b 1' "$(L 'a  b 1' 'a b 1' | srt -k1,3n -u)"
eq 'leading blanks ignored in columns' $'  a 1\nb 2' "$(L 'b 2' '  a 1' | srt -k1)"
eq 'whole record keeps leading blanks' $'  a 1\nb 2' "$(L 'b 2' '  a 1' | srt)"

# r0.6: the highest column named runs to the end of the record when it
# is text, and is one word when it is numeric (manual: THE LAST COLUMN)
eq '-k5,3: text column 5 carries column 6' $'a x 2 q 1 y\na x 1 q 1 z' \
  "$(L 'a x 2 q 1 y' 'a x 1 q 1 z' | srt -k5,3)"
eq '-k5n,3: numeric column 5 is one word' $'a x 1 q 1 z\na x 2 q 1 y' \
  "$(L 'a x 2 q 1 y' 'a x 1 q 1 z' | srt -k5n,3)"
cat > lst <<'__TS_LST__'
1a2 1 aa11 187c 6af80010 ./d/My File
1a3 1 bb22 a3d 6af80010 ./d/other
1a4 2 aa11 187c 6af7ff00 ./e/My File
1a5 1 cc33   1c40a 6af80010 ./x
1a6 1 bb22 0A3D 6af80011 ./e/other  two
1a7 1 dd44 a3d 6af80010 ./d/My Album
__TS_LST__
ids(){ cut -c1-3 | tr '\n' ' ' ;}
eq 'last text column is the name, spaces and all' '1a4 1a7 1a3 1a2 1a5 1a6 ' "$(srt -k5x,4x,6 lst | ids)"
eq 'numeric last column: the rest compares last' '1a4 1a3 1a7 1a2 1a5 1a6 ' "$(srt -k5x,4x lst | ids)"
eq 'squeezed and padded columns are the same words' '1a3 1a6 1a7 1a2 1a4 1a5 ' "$(srt -k4x lst | ids)"
eq '-k6 sorts whole names' '1a7 1a2 1a3 1a4 1a6 1a5 ' "$(srt -k6 lst | ids)"
eq 'blanks inside the last text column count' $'a b  c\na b c' "$(L 'a b c' 'a b  c' | srt -k2)"
eq 'blanks before a numeric last column do not' $'a  1' "$(L 'a  1' 'a 1' | srt -k2n -u)"
# bare -k: no column named; the next word is a list only if it reads as one
eq 'bare -k is the whole record' $'a 2\nb 1' "$(L 'b 1' 'a 2' | srt -k)"
L b a > plain ; L 'a 2' 'b 1' > 5
eq 'bare -k leaves a file name alone' $'a\nb' "$(srt -k plain)"
eq 'bare -k leaves an option alone' $'b\na' "$(srt -k -r plain)"
eq '-k 2 takes the list' $'b 1\na 2' "$(srt -k 2 5)"
eq 'a file named like a list needs ./' $'a 2\nb 1' "$(srt -k ./5)"
eq 'a file named like a list after --' $'a 2\nb 1' "$(srt -k -- 5)"
read -r n < <(srt -k 5 </dev/null | wc -c) ; eq '-k 5 is column 5, not the file' 0 "$((n))"
# -k-N: columns counted from the end
eq '-k-1n is the last word as a number' $'z\ny 9\nx 10' "$(L 'x 10' 'y 9' z | srt -k-1n)"
eq '-t. -k-1 sorts by suffix' $'b.c\nd\na.txt\nc.txt' "$(L a.txt b.c c.txt d | srt -t. -k-1)"
eq '-t/ -k-1 sorts by base name' '1a7 1a2 1a4 1a3 1a6 1a5 ' "$(srt -t/ -k-1 lst | ids)"
eq '-k-2r,1 mixes ends' $'c 2 x\na 2 y\nb 1 z' "$(L 'a 2 y' 'b 1 z' 'c 2 x' | srt -k-2nr,-1)"
eq 'a column from the end that is missing is empty' $'a\nb\na b c' "$(L b 'a b c' a | srt -k-3,1)"
# -D: every member of a group that agrees on the named columns
eq '-D whole lines' $'a\na\nb\nb\nb' "$(L b a b c a b | srt -D)"
eq '-u -D: identical records collapse first' '' "$(L b a b c a b | srt -u -D)"
eq '-D -k3 groups a column' '1a2 1a4 1a3 1a6 ' "$(srt -D -k3 lst | ids)"
eq '-D -k3,4x groups two columns, hex by value' '1a2 1a4 1a3 1a6 ' "$(srt -D -k3,4x lst | ids)"
eq '-D -k4x' '1a3 1a6 1a7 1a2 1a4 ' "$(srt -D -k4x lst | ids)"
eq '-t/ -D -k-1 finds repeated base names' '1a2 1a4 ' "$(srt -t/ -D -k-1 lst | ids)"
eq '-D tests the named word, not the tail' $'j My Tune\nk My File' \
  "$(L 'k My File' 'j My Tune' 'i Your File' | srt -D -k2)"
eq '-D ignores blank runs between columns' $'j 1 b\nk 1 a\nk 1  a' "$(L 'k 1 a' 'k 1  a' 'j 1 b' | srt -D -k2)"
eq '-u -D keeps distinct records of a group' '1a2 1a3 1a5 1a6 1a7 ' "$(srt -u -D -k2 lst lst | ids)"
eq '-D with nothing repeated prints nothing' '' "$(L a b c | srt -D)"
eq '-D -o writes the groups' $'a\na' "$(L a b a > dsrc ; srt -D -o dout dsrc ; cat dout)"

# ---- 3 types --------------------------------------------------------
eq '-x' $'-ff\nzz\n 7\n0x10\na3d\n00a3d\n0A3E\n187c\n1c40a' \
  "$(L 1c40a a3d 187c 0A3E 0x10 zz -ff 00a3d ' 7' | srt -x)"
eq '-x exact beyond 64 bits' $'ffffffffffffffffffffffffe\nfffffffffffffffffffffffff\n10000000000000000000000000' \
  "$(L 10000000000000000000000000 fffffffffffffffffffffffff ffffffffffffffffffffffffe | srt -x)"
eq '-x -r' $'1c40a\na3d\n-ff' "$(L a3d -ff 1c40a | srt -xr)"
eq '-x -u: equal values are one' $'b\nA3D' "$(L A3D 0xa3d 00a3d b | srt -xu)"
eq '-x stops at the first other byte' $'1fz\n20' "$(L 20 1fz | srt -x)"
eq '-n' $'-5\n-0.5\nabc\n0\n2.50\n2.5\n3\n10' \
  "$(L -5 3 -0.5 abc 10 2.50 2.5 0 | srt -n)"
eq '-n exact beyond 64 bits' $'100000000000000000000000001\n100000000000000000000000002' \
  "$(L 100000000000000000000000002 100000000000000000000000001 | srt -n)"
eq '-n negative zero equals zero' $'-0\n0\n1' "$(L -0 0 1 | srt -n)"
eq '-g' $'x\nnan\n-inf\n5\n1.5e1\n1e3\ninf' "$(L 1e3 5 nan -inf x 1.5e1 inf | srt -g)"
eq '-H' $'-1K\n512\n1.5K\n2048K\n1M\n3G' "$(L 1M 2048K 512 3G -1K 1.5K | srt -H)"
eq '-d' $'aa\na-b\na.c' "$(L a-b aa a.c | srt -d)"
eq '-f stable' $'A\na\nb\nB' "$(L b A a B | srt -f)"
eq '-i' $'ab\na\001c' "$(L $'a\001c' ab | srt -i)"
eq '-d keeps UTF-8 bytes' $'a\xc3\xa9\nb' "$(L b $'a\xc3\xa9' | srt -d)"
V(){ L "$@" | srt -v ;}
eq '-v IPv4' $'9.255.0.1\n10.2.0.1\n10.10.0.1' "$(V 10.10.0.1 9.255.0.1 10.2.0.1)"
eq '-v CIDR' $'10.0.0.0\n10.0.0.0/8\n10.0.0.0/16' "$(V 10.0.0.0/16 10.0.0.0 10.0.0.0/8)"
eq '-v hosts' $'node1\nnode2\nnode10' "$(V node10 node2 node1)"
eq '-v hosts with domain' $'node2.example.com\nnode10.example.com' \
  "$(V node10.example.com node2.example.com)"
eq '-v archives' $'foo-1.2.tar.gz\nfoo-1.2.1.tar.gz\nfoo-1.10.tar.gz' \
  "$(V foo-1.10.tar.gz foo-1.2.1.tar.gz foo-1.2.tar.gz)"
eq '-v tilde' $'1.0~rc1\n1.0\n1.0-rc1' "$(V 1.0 1.0~rc1 1.0-rc1)"
eq '-v IPv6 by value' $'2001:db8::9\n2001:db8::a\n2001:db8::10' \
  "$(V 2001:db8::10 2001:db8::a 2001:db8::9)"
eq '-v IPv6 forms are equal' '2001:DB8::1' \
  "$(L 2001:DB8::1 2001:0db8::1 2001:db8:0:0:0:0:0:1 | srt -v -u)"
eq '-v IPv6 networks' $'2001:db8::\n2001:db8::/32\n2001:db8::/48' \
  "$(V 2001:db8::/48 2001:db8::/32 2001:db8::)"
eq '-v IPv4 before IPv6' $'10.0.0.1\n192.168.0.1\n::1\nfe80::1' \
  "$(V ::1 10.0.0.1 fe80::1 192.168.0.1)"
# what counts as an IPv6 address is srt's own rule, not the host library's
eq '-v zone id is not an address' $'fe80::1%eth0\nzz\nfe80::1' "$(V fe80::1 zz fe80::1%eth0)"
eq '-v zone id does not equal the bare address' 2 "$(L fe80::1 fe80::1%eth0 | srt -vu | wc -l | tr -d ' ')"
eq '-v dotted quad with a leading zero is not an address' $'::1.2.3.04\nzz\n::1' "$(V ::1 zz ::1.2.3.04)"
eq '-v dotted quad in the last 32 bits' '::ffff:10.0.0.1' "$(L ::ffff:10.0.0.1 ::ffff:a00:1 | srt -vu)"
eq '-v malformed addresses stay text' $'1:2:3:4:5:6:7:8:9\n:::\na::b::c\n::' "$(V :: a::b::c ::: 1:2:3:4:5:6:7:8:9)"
eq '-v documented: fewer zeros first' $'1.5\n1.05' "$(V 1.05 1.5)"
eq '-v documented: 1.0.1 before 1.0a' $'1.0\n1.0.1\n1.0a' "$(V 1.0a 1.0.1 1.0)"
eq '-v in a column' $'h 10.2.0.1\nh 10.10.0.1' "$(L 'h 10.10.0.1' 'h 10.2.0.1' | srt -k2v)"
eq '-vf folds' $'rc1\nRC2' "$(L RC2 rc1 | srt -vf)"

# ---- 4 stability ----------------------------------------------------
L a > f1 ; L A > f2
eq 'stable across files' $'a\nA' "$(srt -f f1 f2)"
eq 'stable across files, other order' $'A\na' "$(srt -f f2 f1)"
eq '-u keeps the first' $'A\nb' "$(L b A a B | srt -f -u)"
eq '-r keeps input order of equals' $'b\na\nA' "$(L a A b | srt -f -r)"
eq '-S gives the same set' $'a\nb\nc' "$(L c a b | srt -S)"

# ---- 5 check --------------------------------------------------------
L a b c > ok ; L a c b > bad ; L a a b > dup
st '-c sorted' 0 srt -c ok
st '-C sorted' 0 srt -C ok
st '-c unsorted' 1 srt -c bad
st '-C unsorted' 1 srt -C bad
e=$(srt -c bad 2>&1 >/dev/null) || : ; eq '-c report' 'srt: bad:3: disorder' "$e"
o=$(srt -c bad 2>/dev/null) || : ; eq '-c stdout empty' '' "$o"
e=$(srt -C bad 2>&1) || : ; eq '-C silent' '' "$e"
e=$(srt -c ok bad ok 2>&1) || : ; eq '-c several inputs, one report' 'srt: bad:3: disorder' "$e"
st '-c several inputs status' 1 srt -c ok bad ok
e=$(srt -c < bad 2>&1) || : ; eq '-c stdin is named -' 'srt: -:3: disorder' "$e"
st '-c duplicates are sorted' 0 srt -c dup
st '-cu duplicates are disorder' 1 srt -cu dup
e=$(srt -cu dup 2>&1) || : ; eq '-cu report line' 'srt: dup:2: disorder' "$e"
L 2 10 > num
st '-c bytewise sees disorder' 1 srt -c num
st '-cn numeric sees order' 0 srt -cn num
st '--check' 1 srt --check bad
st '-c empty input' 0 srt -c /dev/null

# ---- 6 shuffle ------------------------------------------------------
seq 1 300 > seq
eq '-R is a permutation' "$(srt -n seq)" "$(srt -R seq | srt -n)"
a=$(srt -R seq) ; b=$(srt -R seq)
[ "$a" != "$b" ] && r=differ || r=same ; eq '-R runs differ' differ "$r"
[ "$a" != "$(cat seq)" ] && r=moved || r=unmoved ; eq '-R moves records' moved "$r"
read -r n < <(L a b a c b a | srt -R -u | wc -l) ; eq '-R -u dedupes' 3 "$((n))"

# ---- 7 outline (-b) -------------------------------------------------
B(){ printf '%s\n' "$@" | srt -b ;}
T=$'\t'
eq '-b manual example' \
  $'clients:\n  alpha\n  zeta\nservers:\n  web1\n    port 443\n  web2\n    port 80' \
  "$(B servers: '  web2' '    port 80' '  web1' '    port 443' clients: '  zeta' '  alpha')"
eq '-b flat input is an ordinary sort' "$(L c a b | srt)" "$(B c a b)"
eq '-b children sorted, parents in place' $'p\n  a\n  b\nq\n  c' "$(B p '  b' '  a' q '  c')"
eq '-b subtree travels with its line' $'a\n  y\n    1\n  z\n    2\n    3' \
  "$(B a '  z' '    3' '    2' '  y' '    1')"
eq '-b tab and space children are separate groups' "p"$'\n'"${T}a"$'\n'"${T}b"$'\n  c\n  d' \
  "$(B p "${T}b" "${T}a" '  d' '  c')"
eq '-b groups keep first-appearance order' "p"$'\n'"${T}a"$'\n'"${T}b"$'\n  c\n  d' \
  "$(B p "${T}b" '  d' "${T}a" '  c')"
eq '-b tab line under space line is not its child' "x"$'\n  a\n  m\n'"${T}q" \
  "$(B x '  m' "${T}q" '  a')"
eq '-b mixed indent extends its parent' "x"$'\n  a\n  y\n  '"${T}k"$'\n  '"${T}z" \
  "$(B x '  y' "  ${T}z" "  ${T}k" '  a')"
eq '-b a closed block is not reopened' "A"$'\n  b\n  z\n'"${T}C"$'\n    D' \
  "$(B A '  z' "${T}C" '    D' '  b')"
eq '-b top level may be indented' $'  a\n  b\nc' "$(B '  b' '  a' c)"
eq '-b blank line stays with the line above' $'a\nb\n\nc' "$(B b '' c a)"
eq '-b blank line inside a block' $'p\n  a\n  b\n  \n  c' "$(B p '  b' '  ' '  c' '  a')"
eq '-b leading blank lines stay first' $'\na\nb' "$(B '' b a)"
eq '-b -r' $'q\n  c\np\n  b\n  a' "$(printf '%s\n' p '  a' '  b' q '  c' | srt -b -r)"
eq '-b -n on children' $'p\n  9\n  10' "$(printf '%s\n' p '  10' '  9' | srt -b -n)"
eq '-b -k2 columns after the indent' $'p\n  y 1\n  x 2' "$(printf '%s\n' p '  x 2' '  y 1' | srt -b -k2)"
eq '-b -t: indent is not part of column 1' $'p\n  a:2\n  b:1' "$(printf '%s\n' p '  b:1' '  a:2' | srt -b -t: -k1)"
eq '-b -v addresses in a block' $'net\n  10.2.0.1\n  10.10.0.1' "$(printf '%s\n' net '  10.10.0.1' '  10.2.0.1' | srt -b -v)"
eq '-b -u removes an equal leaf' $'p\n  a\n  b' "$(printf '%s\n' p '  b' '  a' '  a' | srt -b -u)"
eq '-b -u keeps an equal line that has a block' $'a\n  1\na\n  2' "$(printf '%s\n' a '  1' a '  2' | srt -b -u)"
read -r n < <(printf '%s\n' a a '' | srt -b -u | wc -l) ; eq '-b -u keeps an equal line followed by a blank' 3 "$((n))"
eq '-b -Z' $'p\n  a\n  b' "$(printf 'p\0  b\0  a\0' | srt -b -Z | tr '\0' '\n')"
printf '%s\n' servers: '  web2' '    port 80' '  web1' '    port 443' clients: '  zeta' '  alpha' > ol
srt -b ol > ol.s
eq '-b is idempotent' "$(cksum < ol.s)" "$(srt -b ol.s | cksum)"
eq '-b keeps every line' "$(srt ol | cksum)" "$(srt ol.s | cksum)"
st '-cb sorted outline' 0 srt -cb ol.s
st '-Cb sorted outline' 0 srt -Cb ol.s
st '-cb unsorted outline' 1 srt -cb ol
e=$(srt -cb ol 2>&1) || : ; eq '-cb reports the first line out of order' 'srt: ol:4: disorder' "$e"
e=$(srt -Cb ol 2>&1) || : ; eq '-Cb silent' '' "$e"
st '-c without -b sees the outline as unsorted' 1 srt -c ol.s
printf '%s\n' p '  a' '  a' > old ; st '-cb duplicates are sorted' 0 srt -cb old
st '-cub duplicate leaf is disorder' 1 srt -cub old
st '-cb several inputs' 1 srt -cb ol.s ol ol.s
srt -b -o ol.o ol ; eq '-b with -o' "$(cksum < ol.s)" "$(cksum < ol.o)"
eq '-b several inputs form one outline' $'a\n  1\nb\n  2' \
  "$(printf '%s\n' b '  2' > o1 ; printf '%s\n' a '  1' > o2 ; srt -b o1 o2)"
awk 'BEGIN { for (i = 0; i < 9000; i++) printf "k%d\n  v%d\n", (i * 7919) % 9000, i }' > olbig
st '-b over budget is exit 2' 2 srt -b --mem 64k olbig
e=$(srt -b --mem 64k olbig 2>&1 >/dev/null) || : ; [[ $e == *--mem* ]] && r=named || r="unnamed ($e)"
eq '-b over budget names --mem' named "$r"
read -r n < <(srt -b --mem 64k olbig 2>/dev/null | wc -c || :) ; eq '-b over budget writes nothing' 0 "$((n))"
eq '-b large outline keeps pairs together' "$(awk 'BEGIN { for (i = 0; i < 9000; i++) printf "k%d %d\n", (i * 7919) % 9000, i }' | srt | cksum)" \
  "$(srt -b olbig | awk 'NR % 2 { k = $1 ; next } { sub(/^v/, "", $1) ; print k, $1 }' | cksum)"

# ---- 8 records ------------------------------------------------------
eq '-Z' $'a\nb' "$(printf 'b\0a\0' | srt -Z | tr '\0' '\n')"
read -r n < <(printf 'b\na' | srt | wc -c) ; eq 'final record gains terminator' 4 "$((n))"
read -r n < <(srt /dev/null | wc -c) ; eq 'empty input, empty output' 0 "$((n))"
eq 'empty lines sort first' $'\n\na\n.' "$(printf 'a\n\n\n' | srt ; echo .)"
eq 'embedded NUL is data' $'a\nb' "$(printf 'b\0x\na\0y\n' | srt | tr -d '\0xy')"
# a record larger than an input chunk stays whole
{ head -c 5000000 /dev/zero | tr '\0' x ; printf '\nabc\n' ;} > big
{ printf 'abc\n' ; head -c 5000000 /dev/zero | tr '\0' x ; printf '\n' ;} > big.want
srt big > big.got ; cmp -s big.got big.want && r=same || r=differ
eq 'record larger than a chunk' same "$r"

# ---- 9 output -------------------------------------------------------
L b a > inplace ; chmod 640 inplace ; srt -o inplace inplace
eq '-o names an input' $'a\nb' "$(cat inplace)"
read -r m _ < <(ls -l inplace) ; eq '-o keeps mode' '-rw-r-----' "${m:0:10}"
srt -o created inplace ; eq '-o creates' $'a\nb' "$(cat created)"
L b a > keep ; st '-o with failing input' 2 srt -o keep nonexistent-file keep
eq 'failed run leaves original' $'b\na' "$(cat keep)"
mkdir adir ; st '-o directory refused' 2 srt -o adir ok
shopt -s nullglob dotglob ; left=( .srt.* adir/.srt.* ) ; shopt -u nullglob dotglob
eq 'no temporary left behind' 0 "${#left[@]}"
st '-o non-regular written through' 0 srt -o /dev/null ok
[ -c /dev/null ] && r=device || r=replaced ; eq '/dev/null survives -o' device "$r"
eq '--output' $'a\nb\nc' "$(srt --output=o2 ok ; cat o2)"

# ---- 10 spill: a small budget must change nothing but the route -----
awk 'BEGIN { s = 11 ; for (i = 0; i < 120000; i++) { s = (s * 1103515245 + 12345) % 2147483648
  printf "%s%d %d %s\n", (s % 3 ? "k" : "K"), s % 5000, s % 977 - 400, (s % 7 ? "x" : "X") } }' > wide
for o in '' -r -u -f -fu -n -Su '-k2n,1' '-k3f,2nr' '-t5 -k2' ; do
  # shellcheck disable=SC2086
  eq "spill equals memory: srt $o" "$(srt $o wide | cksum)" "$(srt --mem 64k $o wide | cksum)"
done
eq 'spill agrees with native sort' "$(LC_ALL=C sort -s wide | cksum)" "$(srt --mem 64k wide | cksum)"
eq 'spill stable across files' "$(srt -f wide wide | cksum)" "$(srt -f --mem 64k wide wide | cksum)"
eq 'SRT_MEM forces spill' "$(srt wide | cksum)" "$(SRT_MEM=64k "$S" wide | cksum)"
e=$(SRT_STATS=1 "$S" --mem 64k wide 2>&1 >/dev/null)
[[ $e =~ runs=([0-9]+)\ passes=([0-9]+) ]] && { nr=${BASH_REMATCH[1]} np=${BASH_REMATCH[2]} ;} || { nr=0 np=0 ;}
[ "$nr" -gt 15 ] && r=many || r="few ($nr)" ; eq 'small budget makes many runs' many "$r"
[ "$np" -ge 2 ] && r=multi || r="single ($np)" ; eq 'runs beyond the fan-in merge in passes' multi "$r"
e=$(SRT_STATS=1 "$S" wide 2>&1 >/dev/null)
[[ $e =~ ^srt:\ stats:\ budget=[0-9]+\ runs=0\ passes=0\ encoded=0\ compared=0$ ]] && r=memory || r="spilled ($e)" ; eq 'default budget: no runs, no passes' memory "$r"
e=$(SRT_STATS=1 "$S" --mem 1 /dev/null 2>&1) ; eq '--mem below 64k is raised' 'srt: stats: budget=65536 runs=0 passes=0 encoded=0 compared=0' "$e"
e=$(SRT_STATS=1 SRT_MEM=1g "$S" --mem 128k /dev/null 2>&1)
eq '--mem outranks SRT_MEM' 'srt: stats: budget=131072 runs=0 passes=0 encoded=0 compared=0' "$e"
cp wide wide.o ; srt --mem 64k -o wide.o wide.o
eq 'spill with -o in place' "$(srt wide | cksum)" "$(cksum < wide.o)"
eq 'spill with -Z' "$(srt wide | cksum)" "$(tr '\n' '\0' < wide | srt -Z --mem 64k | tr '\0' '\n' | cksum)"
srt --mem 64k big > big.got ; cmp -s big.got big.want && r=same || r=differ
eq 'record larger than the budget' same "$r"
eq '-R spill is a permutation' "$(srt wide | cksum)" "$(srt -R --mem 64k wide | srt | cksum)"
[ "$(srt -R --mem 64k wide | cksum)" != "$(cksum < wide)" ] && r=moved || r=unmoved
eq '-R spill moves records' moved "$r"
[ "$(srt -R --mem 64k wide | cksum)" != "$(srt -R --mem 64k wide | cksum)" ] && r=differ || r=same
eq '-R spill runs differ' differ "$r"
eq '-R -u spill dedupes exactly' "$(srt -u wide | cksum)" "$(srt -R -u --mem 64k wide | srt | cksum)"
eq '-R -u in memory dedupes exactly' "$(srt -u wide | cksum)" "$(srt -R -u wide | srt | cksum)"
[ "$(srt -R -u wide | cksum)" != "$(srt -u wide | cksum)" ] && r=moved || r=unmoved
eq '-R -u is not sorted order' moved "$r"
mkdir sp ; eq '-T dir used for spill' "$(srt wide | cksum)" "$(srt -T sp --mem 64k wide | cksum)"
eq 'TMPDIR used for spill' "$(srt wide | cksum)" "$(TMPDIR=$D/sp "$S" --mem 64k wide | cksum)"
shopt -s nullglob dotglob ; left=( sp/* ) ; shopt -u nullglob dotglob
eq 'spill leaves nothing in -T' 0 "${#left[@]}"
read -r uid < <(id -u)
[ "$uid" -eq 0 ] || {      # root ignores directory modes
  mkdir ro ; chmod 555 ro
  st '-T unwritable is exit 2' 2 srt -T ro --mem 64k wide
  st '-T unwritable unused when input fits' 0 srt -T ro ok ;}
# the budget is a real bound: under an address-space limit the spill
# route completes where the in-memory route cannot. Skipped where the
# limit cannot be set or does not bite (control case).
want=$(srt wide wide wide wide | cksum)
r=0 ; ( ulimit -v 6000 2>/dev/null && "$S" --mem 1g wide wide wide wide >/dev/null 2>&1 ) || r=$?
[ "$r" -ne 2 ] || {
  ( ulimit -v 6000 && exec "$S" --mem 1m wide wide wide wide > lim1 ) || :
  eq 'bounded memory: explicit budget under a hard limit' "$want" "$(cksum < lim1)"
  ( ulimit -v 6000 && exec "$S" wide wide wide wide > lim2 ) || :
  eq 'bounded memory: default budget follows the limit' "$want" "$(cksum < lim2)" ;}
# check is one pass with two records held
srt --mem 64k wide > wide.s
st '-c on spilled output' 0 srt -c wide.s
st '-c record larger than its buffer, sorted' 0 srt -c big.want
e=$(srt -c big 2>&1) || : ; eq '-c record larger than its buffer, unsorted' 'srt: big:2: disorder' "$e"
r=0 ; printf 'a\nb' | srt -c || r=$? ; eq '-c final record without terminator' 0 "$r"
e=$(printf 'b\na' | srt -c 2>&1) || : ; eq '-c disorder at unterminated record' 'srt: -:2: disorder' "$e"
e=$(srt -c wide 2>&1) || : ; [[ $e =~ ^srt:\ wide:[0-9]+:\ disorder$ ]] && r=one || r="other ($e)" ; eq '-c reports one line and stops' one "$r"

# ---- 11 oracle: where meanings coincide, agree with native sort -----
awk 'BEGIN { s = 7 ; for (i = 0; i < 3000; i++) { s = (s * 1103515245 + 12345) % 2147483648
  n = s % 9973 ; w = "" ; t = s
  for (j = 0; j < 1 + s % 5; j++) { w = w sprintf("%c", 65 + t % 26 + 32 * (t % 2)) ; t = int(t / 7) }
  print w, n - 4000, n % 13 } }' > data
awk '{ print $2 }' data > nums
O(){ LC_ALL=C sort -s "$@" ;}
eq 'oracle whole record' "$(O data | cksum)" "$(srt data | cksum)"
eq 'oracle -r' "$(O -r data | cksum)" "$(srt -r data | cksum)"
eq 'oracle -u' "$(O -u data | cksum)" "$(srt -u data | cksum)"
eq 'oracle -f' "$(O -f data | cksum)" "$(srt -f data | cksum)"
eq 'oracle -n' "$(O -n nums | cksum)" "$(srt -n nums | cksum)"
eq 'oracle -nr' "$(O -nr nums | cksum)" "$(srt -nr nums | cksum)"
eq 'oracle -S same as stable when no ties' "$(O -u data | cksum)" "$(srt -S -u data | cksum)"

# ---- 12 locale independence ----------------------------------------
L $'\xc3\xa9t\xc3\xa9' Zebra apple $'\xc3\x85ngstr\xc3\xb6m' zebra Apple > utf
eq 'locale ignored' "$(LC_ALL=C "$S" utf | cksum)" "$(LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 "$S" utf | cksum)"
eq 'locale ignored -f' "$(LC_ALL=C "$S" -f utf | cksum)" "$(LC_ALL=en_US.UTF-8 "$S" -f utf | cksum)"
eq 'byte order' $'Apple\nZebra\napple\nzebra\n\xc3\x85ngstr\xc3\xb6m\n\xc3\xa9t\xc3\xa9' "$(srt utf)"

# ---- 13 self-consistency: srt output passes srt -c ------------------
for o in '' -n -f -v -r -g -H -d -i -u '-k2,1' '-k3n,2nr' '-t: -k2' '-fr -k2n' ; do
  r=0 ; # shellcheck disable=SC2086
  srt $o data | srt -c $o || r=$?
  eq "sorted output checks clean: srt $o" 0 "$r"
done
eq '--help is stable' "$(srt --help | cksum)" "$(srt --help | cksum)"
r=0 ; srt --help | srt | srt -c || r=$? ; eq 'manual round trip' 0 "$r"
read -r n < <(srt --help | grep -c "^[.']" || :) ; eq 'manual has no roff control lines' 0 "$((n))"
for w in --check --output --tmp-dir --unique --version --help --respect-blanks \
  --random --dictionary --fold-case --general-numeric --human-numeric --hex-numeric --duplicates \
  --ignore-nonprinting --numeric --reverse --version-sort --separator \
  --zero-terminated --mem ; do
  srt --help | grep -q -e "$w" && r=documented || r=missing
  eq "manual documents $w" documented "$r"
done

# ---- 14 bash function: the same result as the binary ----------------
# Runs when srt.fn.bash is beside this script (or SRT_FN_FILE names it).
# Every case compares the function, forced with --fn, to the binary.
[ ! -r "$FN" ] || {
fn(){ ( . "$FN" ; srt --fn "$@" ) ;}
P(){ # input-file option...: output and exit status must match
  local in=$1 a= b= ra=0 rb=0 ; shift
  a=$(srt "$@" "$in" 2>/dev/null | cksum ; exit "${PIPESTATUS[0]}") || ra=$?
  b=$(fn "$@" "$in" 2>/dev/null | cksum ; exit "${PIPESTATUS[0]}") || rb=$?
  eq "fn parity: srt $* $in" "$ra $a" "$rb $b" ;}
C(){ # option... file...: -c exit status and stderr must match
  local a= b= ra=0 rb=0
  a=$(srt "$@" 2>&1) || ra=$?
  b=$(fn "$@" 2>&1) || rb=$?
  eq "fn check parity: srt $*" "$ra $a" "$rb $b" ;}
E(){ # option...: exit status must match (stdin empty)
  local ra=0 rb=0
  srt "$@" </dev/null >/dev/null 2>&1 || ra=$?
  fn "$@" </dev/null >/dev/null 2>&1 || rb=$?
  eq "fn status parity: srt $*" "$ra" "$rb" ;}

for o in '' -r -u -f -fu -n -d -i -g -H -v -S '-k2n,1' '-k3n,2nr' -k2 '-r -k3n,1' \
  '-n -k1r' '-k1f,3n' -k2g '-k2H,1' -k1v -k9 '-fr -k2n' '-n -k3,2' '-u -k2n' '-t: -k2' ; do
  # shellcheck disable=SC2086
  P data $o
done
L 10.10.0.1 9.255.0.1 10.2.0.1 10.0.0.0/16 10.0.0.0 10.0.0.0/8 node10 node2 node1 \
  node10.example.com node2.example.com foo-1.10.tar.gz foo-1.2.1.tar.gz foo-1.2.tar.gz \
  1.0 1.0~rc1 1.0-rc1 1.0a 1.0.1 1.05 1.5 1.005 2001:db8::10 2001:db8::a 2001:db8::9 \
  2001:DB8::1 2001:0db8::1 2001:db8:0:0:0:0:0:1 2001:db8::/48 2001:db8::/32 2001:db8:: \
  ::1 fe80::1 192.168.0.1 ::ffff:10.0.0.1 ::ffff:a00:1 fe80::1%eth0 1:2:3:4:5:6:7:8 \
  1:2:3:4:5:6:7:8:9 ::1/129 ::1/64 ::1/064 12:30:45 a::b::c : :: ::: 1:: RC2 rc1 eth10 eth2 \
  v1.2.3 v1.10 v1.2 '' '~' 'a~' a 007 7 07 x.tar.gz x.tar x 1.2.3.4 256.1.1.1 ::1.2.3.04 > vdat
for o in -v -vr -vu -vf -vfu -k1v ; do P vdat $o ; done
L -5 3 -0.5 abc 10 2.50 2.5 0 -0 007 1e3 .5 5. '  12' -.5 - 1.50x --5 +5 0.0 -0.0 \
  100000000000000000000000002 100000000000000000000000001 -100000000000000000000000001 \
  0.000001 0.0000010 3.14159 '' ' ' > ndat
for o in -n -nr -nu -g -gr -gu -H -Hr -Hu ; do P ndat $o ; done
L 1e3 5 nan -inf x 1.5e1 inf +5 .5 5. 1e-400 1e400 -1e400 -0 INF NaN 1E2 -nan +inf \
  infinity 1e 1e+ e5 .e5 -1.5e-3 15 1.50e1 2.2250738585072014e-308 1.7976931348623157e308 \
  0.1 0.10000000000000001 0.30000000000000004 0.3 '' > gdat
for o in -g -gr -gu ; do P gdat $o ; done
L 1M 2048K 512 3G -1K 1.5K 1k 0 -5 2.5G 10 x 1Ki 5.K 1.50M 1.5M -2M -1M 9Y 1Z 1E 1P 1T '' > hdat
for o in -H -Hr -Hu ; do P hdat $o ; done
L x::1 y:a:2 z::0 a: a b:: b : :: a:10:x a:9:x 'a b:1' ' a:1' '' > tdat
for o in -t: '-t: -k2' '-t: -k3n,1' '-t: -u' '-t: -k2 -u' '-t: -n' '-t: -r -k2' '-t, -k2' ; do P tdat $o ; done
L 'a 0' a 'a -5' 'a 5' b 'a  0 0' 'a 0 -1' 'b 0' 'a 0 0 0' '' ' ' 'a 5 x' > ragged
for o in '-n -k1' '-n -k1 -u' -k1 -k2n '-k2n -u' '-k3n' '-g -k1' '-H -k2' '-v -k2' '-nr' ; do P ragged $o ; done
for o in '' -f -d -i -fd -di ; do P utf $o ; done
printf 'a\tb\001c\n' > c1 ; printf 'A-b.c\na\tb c\na\005b\nab\na\177b\n' > c2
P c2 -i ; printf 'a-b\naa\na.c\na b\na\tb\n' > c3 ; for o in -d -df -di ; do P c3 $o ; done
head -20000 wide > wide20
for o in '' '-k2n,1' '-k3f,2nr' -u ; do P wide20 $o ; done
# r0.6: hex keys, the last column, columns from the end, duplicates
L 1c40a a3d 187c 0A3E 0x10 zz -ff 00a3d ' 7' 0X1F -0 0 '' x 0x -0xA 'a3d z' 'A3D  z' ffffffffffffffffffffffff \
  1000000000000000000000000 -ffffffffffffffffffffffff 0000 fg g1 > xdat
for o in -x -xr -xu -k1x '-k1x,2' '-k2x' '-D -k1x' '-xf' ; do P xdat $o ; done
for o in '-k5x,4x,6' '-k5x,4x' -k4x -k6 '-k6r,4xr' '-D -k3' '-D -k3,4x' '-D -k4x' '-D' '-u -D -k2' \
  '-t/ -k-1' '-t/ -D -k-1' -k-1 '-k-2r,1' '-k-1x,-2' -k-9 '-k' '-rk5' '-k-1,1' '-t/ -u -D -k-1' \
  '--duplicates --hex-numeric -k4' '-k 4x' '-D -f -k6' '-D -k1,2' ; do P lst $o ; done
for o in '-D' '-D -k1' '-D -k2n' '-u -D -k1' '-k-1' '-k-1n,1' '-k-2' '-D -k-1' '-k2x' '-D -k9' ; do P ragged $o ; done
for o in '-t: -k-1' '-t: -D -k-1' '-t: -k-2,-1n' '-t: -D -k2' '-t: -k2x' ; do P tdat $o ; done
for o in '-D -k2n' '-k-1' '-D' ; do P data $o ; done
# r0.6 defect, found by fuzz: the function tested only the first named column
L 'a b c d' 'q b c e' 'r b c e' 'z y x d' > dk2
for o in '-D -k3,4' '-D -k3r,4' '-D -k4,3,2' '-D -k2,-1' ; do P dk2 $o ; done
eq 'fn -D tests every named column' $'q b c e\nr b c e' "$(fn -D -k3,4 dk2)"
eq 'fn bare -k leaves a file name alone' "$(srt -k ok)" "$(fn -k ok)"
eq 'fn bare -k leaves an option alone' "$(srt -k -r ok)" "$(fn -k -r ok)"
eq 'fn -k 2 takes the list' "$(srt -k 2 data | cksum)" "$(fn -k 2 data | cksum)"
eq 'fn -D -o' "$(srt -D -k3 lst)" "$(fn -D -k3 -o fdup lst ; cat fdup)"
e=$(fn -kr5 ok 2>&1) || : ; eq 'fn -kr5 message' "$(srt -kr5 ok 2>&1 || :)" "$e"
eq 'fn several files, stable' "$(srt -f f1 f2 ; srt -f f2 f1)" "$(fn -f f1 f2 ; fn -f f2 f1)"
eq 'fn stdin' "$(srt -n < nums | cksum)" "$(fn -n < nums | cksum)"
eq 'fn dash operand' "$(srt -n - < nums | cksum)" "$(fn -n - < nums | cksum)"
eq 'fn stdin and file together' "$(L z | srt ok - | cksum)" "$(L z | fn ok - | cksum)"
read -r n < <(printf 'b\na' | fn | wc -c) ; eq 'fn final record gains terminator' 4 "$((n))"
read -r n < <(fn /dev/null | wc -c) ; eq 'fn empty input' 0 "$((n))"
eq 'fn --mem accepted' "$(srt data | cksum)" "$(fn --mem 64k data | cksum)"
eq 'fn SRT_MEM accepted' "$(srt data | cksum)" "$(SRT_MEM=64k fn data | cksum)"

# check mode: status and report
srt data > data.s ; srt -n nums > nums.s ; srt -k2n,1 data > data.k
C -c ok ; C -c bad ; C -C bad ; C -c dup ; C -cu dup ; C -c num ; C -cn num
C -c ok bad ok ; C -c data ; C -cn nums ; C -c -k2n,1 data ; C -cv data
C -c data.s ; C -cn nums.s ; C -c -k2n,1 data.k ; C -cu data.s ; C -c -k2n,1 data.s
C -c /dev/null ; C --check bad
a=$(srt -c < bad 2>&1) || : ; b=$(fn -c < bad 2>&1) || : ; eq 'fn check stdin name' "$a" "$b"
o=$(fn -c bad 2>/dev/null) || : ; eq 'fn -c stdout empty' '' "$o"

# -o
L b a > fo ; chmod 640 fo ; fn -o fo fo ; eq 'fn -o names an input' $'a\nb' "$(cat fo)"
read -r m _ < <(ls -l fo) ; eq 'fn -o keeps mode' '-rw-r-----' "${m:0:10}"
fn -o fnew fo ; eq 'fn -o creates' $'a\nb' "$(cat fnew)"
L b a > fkeep ; r=0 ; fn -o fkeep nonexistent-file fkeep 2>/dev/null || r=$?
eq 'fn -o with failing input: status' 2 "$r" ; eq 'fn failed run leaves original' $'b\na' "$(cat fkeep)"
mkdir fdir ; r=0 ; fn -o fdir ok 2>/dev/null || r=$? ; eq 'fn -o directory refused' 2 "$r"
r=0 ; fn -o /dev/null ok || r=$? ; eq 'fn -o non-regular written through' 0 "$r"
[ -c /dev/null ] && r=device || r=replaced ; eq 'fn /dev/null survives -o' device "$r"
mkdir fsp ; eq 'fn -T dir' "$(srt data | cksum)" "$(fn -T fsp data | cksum)"
eq 'fn TMPDIR' "$(srt data | cksum)" "$(TMPDIR=$D/fsp fn data | cksum)"
shopt -s nullglob dotglob ; left=( fsp/* .srt-fn.* fdir/.srt-fn.* ) ; shopt -u nullglob dotglob
eq 'fn leaves no temporary' 0 "${#left[@]}"

# shuffle
eq 'fn -R is a permutation' "$(srt -n seq)" "$(fn -R seq | srt -n)"
[ "$(fn -R seq)" != "$(fn -R seq)" ] && r=differ || r=same ; eq 'fn -R runs differ' differ "$r"
[ "$(fn -R seq)" != "$(cat seq)" ] && r=moved || r=unmoved ; eq 'fn -R moves records' moved "$r"
read -r n < <(L a b a c b a | fn -R -u | wc -l) ; eq 'fn -R -u dedupes' 3 "$((n))"

# what the function declines, and how
r=0 ; fn -b ok >/dev/null 2>&1 || r=$? ; eq 'fn -b declined' 2 "$r"
r=0 ; fn -Z ok >/dev/null 2>&1 || r=$? ; eq 'fn -Z declined' 2 "$r"
r=0 ; fn -z ok >/dev/null 2>&1 || r=$? ; eq 'fn -z retired' 2 "$r"
eq 'fn -z message' "$(srt -z ok 2>&1 || :)" "$(fn -z ok 2>&1 || :)"
r=0 ; fn -t '\0' ok >/dev/null 2>&1 || r=$? ; eq 'fn -t \0 declined' 2 "$r"
r=0 ; o=$(fn c1 2>/dev/null) || r=$? ; eq 'fn control bytes declined' "2 " "$r $o"
r=0 ; o=$(fn -c c1 2>/dev/null) || r=$? ; eq 'fn -c control bytes declined' "2 " "$r $o"
r=0 ; o=$(L 5 0x1p3 | fn -g 2>/dev/null) || r=$? ; eq 'fn -g hex float declined' "2 " "$r $o"
e=$(fn -b ok 2>&1) || : ; [[ $e == *binary* ]] && r=named || r="unnamed ($e)" ; eq 'fn refusal names the binary' named "$r"

# grammar: same exit status as the binary
for o in -Q --nonesuch -M -l --parallel=2 --radixsort -k2.3 -k2,2 '-k2 -k2' -k0 -k1q -k -kr5 -k-0 -k-1 '-D -c' '-D -C' '-D -R' -D -x '-x -n' -k1xn '-n -v' \
  -k1nv -dg '-c -o x' '-C -o x' '-R -k1' '-R -n' '-R -c' '-t ab' '--mem 5x' '--mem 0' \
  '--unique=1' '-T /nonexistent/dir' nonexistent-file '-s -m' '--stable --merge' '--mem 64m' \
  --mem=1g -h --help -V --version '-T .' -S ; do
  # shellcheck disable=SC2086
  E $o
done
r=0 ; SRT_MEM=bogus fn </dev/null >/dev/null 2>&1 || r=$? ; eq 'fn SRT_MEM bad' 2 "$r"

# one manual
eq 'fn --help is the binary manual' "$(srt --help | cksum)" "$(fn --help | cksum)"
eq 'fn -h is the binary usage' "$(srt -h | cksum)" "$(fn -h | cksum)"
eq 'fn -V names itself' "$(srt -V) (bash function)" "$(fn -V)"

# choosing the form: --fn, --bin, or neither (the binary on PATH wins)
NOBIN=/usr/bin:/bin                    # a PATH with the tools and no srt
st 'binary accepts --bin' 0 srt --bin
st 'binary refuses --fn' 2 srt --fn
eq 'binary --bin changes nothing' "$(srt data | cksum)" "$(srt --bin data | cksum)"
r=0 ; ( . "$FN" ; srt --fn --bin ok ) >/dev/null 2>&1 || r=$? ; eq 'fn --fn with --bin refused' 2 "$r"
r=0 ; ( . "$FN" ; PATH=$NOBIN srt --bin ok ) >/dev/null 2>&1 || r=$? ; eq 'fn --bin without a binary is an error' 2 "$r"
v=$( . "$FN" ; PATH=$NOBIN srt -V ) ; [[ $v == *"(bash function)"* ]] && r=function || r="binary ($v)"
eq 'fn translates when no binary is on PATH' function "$r"
( . "$FN" ; cd "$D" && PATH=$NOBIN srt -o --fn ok ) ; eq 'fn "-o --fn" is a file name' $'a\nb\nc' "$(cat ./--fn)"
( . "$FN" ; PATH=$NOBIN srt -o fn.long --output=fn.long2 --fn ok ) ; eq 'fn --fn after --output=value' $'a\nb\nc' "$(cat fn.long2)"
eq 'fn --fn anywhere among the options' "$(srt -n nums | cksum)" "$( . "$FN" ; srt -n nums --fn | cksum )"
[ "${S##*/}" != srt ] || {
  eq 'fn hands over to the binary on PATH' "$(srt -V)" "$( . "$FN" ; PATH=${S%/*}:$PATH srt -V )"
  eq 'fn --bin runs the binary' "$(srt -V)" "$( . "$FN" ; PATH=${S%/*}:$PATH srt --bin -V )"
  v=$( . "$FN" ; PATH=${S%/*}:$PATH srt --fn -V ) ; [[ $v == *"(bash function)"* ]] && r=function || r="binary ($v)"
  eq 'fn --fn keeps the function when a binary is on PATH' function "$r"
  ( . "$FN" ; PATH=${S%/*}:$PATH srt -o --bin ok ) ; eq 'fn "-o --bin" is a file name' $'a\nb\nc' "$(cat ./--bin)" ;}
# one name: sourcing adds srt and nothing else, and a call leaves the
# calling shell as it found it
{ IFS= read -r -d '' Q || : ;} <<'__TEST_ONE_NAME__'
# What the shell holds before the file is sourced is not the function's
# doing: exported functions arrive from the environment, and bash sets
# COLUMNS and LINES after a command when it has a terminal.
N(){ compgen -v | grep -v -x -e _ -e COLUMNS -e LINES -e PIPESTATUS -e 'BASH_[A-Z_]*' -e '[fv][012]' -e '[otsi]0' -e added ;}
unset -f srt
f0=$(compgen -A function) ; v0=$(N)
. "$1"
f1=$(compgen -A function) ; v1=$(N) ; o0=$- ; t0=$(trap) ; s0=$(shopt) ; i0=$IFS
printf 'b\na\n' | srt --fn -k1 >/dev/null ; srt --fn -Q 2>/dev/null ; srt --fn --bin 2>/dev/null
srt --fn -h >/dev/null ; srt --fn --help >/dev/null
f2=$(compgen -A function) ; v2=$(N)
added=$(comm -13 <(printf '%s\n' "$f0" | LC_ALL=C sort -u) <(printf '%s\n' "$f1" | LC_ALL=C sort -u) | tr '\n' ' ')
[ "$added" = 'srt ' ] && echo functions-ok
[ "$f1" = "$f2" ] && echo functions-after-ok
[ "$v0" = "$v1" ] && [ "$v1" = "$v2" ] && echo variables-ok
[ "$o0" = "$-" ] && echo options-ok
[ "$t0" = "$(trap)" ] && echo traps-ok
[ "$s0" = "$(shopt)" ] && echo shopt-ok
[ "$i0" = "$IFS" ] && echo ifs-ok
:
__TEST_ONE_NAME__
eq 'fn defines one name and leaves the calling shell unchanged' \
  'functions-ok functions-after-ok variables-ok options-ok traps-ok shopt-ok ifs-ok' \
  "$(bash --norc --noprofile -c "$Q" _ "$FN" | tr '\n' ' ' | sed 's/ $//')"
# the same holds in a shell that already carries exported functions
eq 'fn one name, with exported functions in the environment' \
  'functions-ok functions-after-ok variables-ok options-ok traps-ok shopt-ok ifs-ok' \
  "$(zz_other(){ : ;} ; srt_like(){ : ;} ; export -f zz_other srt_like
     bash --norc --noprofile -c "$Q" _ "$FN" | tr '\n' ' ' | sed 's/ $//')"
} # end of section 14

# ---- 15 key encoding: the encoded sort is the compared sort ---------
# A batch is sorted on encoded keys when they fit a quarter of the
# budget, and by direct comparison (reccmp) when they do not. At 64k
# these short records never fit, so --mem 64k is the compared route end
# to end (runs and merge), and the default budget is the encoded route.
# The two must agree byte for byte, equal records included.
awk 'BEGIN { split("0 1 -1 10 9 007 1.5 1.50 -0.5 .5 5. 1e3 -1e-3 1K 2M 512 3G abc ABC a-b a.b a~ ~ 1.0 1.0~rc1 1.0.1 1.0a foo-1.2.tar.gz foo-1.10.tar.gz 10.0.0.1 10.0.0.1/8 9.9.9.9 ::1 2001:db8::a 2001:DB8::A fe80::1/64 nan inf -inf x X zz - -- +5 00 0.0 -0 e5 1e 12:30 node2 node10", P, " ")
  n = 0 ; for (k in P) n++ ; s = 5
  for (i = 0; i < 6000; i++) { line = ""
    s = (s * 1103515245 + 12345) % 2147483648 ; c = s % 5
    for (j = 0; j <= c; j++) { s = (s * 1103515245 + 12345) % 2147483648
      line = line (j ? (s % 11 ? " " : "  ") : "") P[1 + s % n] }
    print line } }' > mix
tr ' ' ':' < mix > mixc
e=$(SRT_STATS=1 "$S" -k2n mix 2>&1 >/dev/null)
eq 'keyed sort uses encoded keys' 'encoded=1 compared=0' "${e##*passes=0 }"
e=$(SRT_STATS=1 "$S" mix 2>&1 >/dev/null)
eq 'plain whole-record sort needs no encoding' 'encoded=0 compared=0' "${e##*passes=0 }"
e=$(SRT_STATS=1 "$S" --mem 64k -k2n mix 2>&1 >/dev/null)
[[ $e =~ encoded=0\ compared=([0-9]+)$ ]] && [ "${BASH_REMATCH[1]}" -gt 1 ] && r=compared || r="other ($e)"
eq 'keys that do not fit are compared directly' compared "$r"
for o in -n -g -H -v -d -f -i -r -u -nr -fu -vr -vu -gu -Hr -df -k1 -k2 -k2n '-k2n,1' '-k3v,1n' \
  '-k1f,2g' '-n -k1r' '-r -k2n' '-v -k3' '-k2H,3nr' '-u -k2n' '-f -k3,1' '-g -k4' -k9 ; do
  # shellcheck disable=SC2086
  eq "encoded equals compared: srt $o" "$(srt --mem 64k $o mix | cksum)" "$(srt $o mix | cksum)"
  r=0 ; # shellcheck disable=SC2086
  srt $o mix | srt -c $o || r=$?
  eq "encoded output checks clean: srt $o" 0 "$r"
done
for o in '-t:' '-t: -k2' '-t: -k2n,1' '-t: -n' '-t: -u' '-t: -k3v' '-t: -r -k2' '-t: -k4g,2H' ; do
  # shellcheck disable=SC2086
  eq "encoded equals compared: srt $o" "$(srt --mem 64k $o mixc | cksum)" "$(srt $o mixc | cksum)"
done
# -S permits any order among equal records, and with -u any one of them
# may be kept: which one is the host qsort's affair (r0.5 compared bytes
# here and failed on Darwin). What must hold is the set of keys.
for m in '' '--mem 64k' ; do
  # shellcheck disable=SC2086
  eq "-S -u keeps one record per key: srt $m -S -u -k2n" "$(srt -u -k2n mix | wc -l | tr -d ' ')" "$(srt $m -S -u -k2n mix | wc -l | tr -d ' ')"
  r=0 ; # shellcheck disable=SC2086
  srt $m -S -u -k2n mix | srt -cu -k2n || r=$?
  eq "-S -u output is strictly ordered: srt $m -S -u -k2n" 0 "$r"
done
# r0.6 option sets, the same two routes
for o in -x -xu '-k2x' '-k2x,1' '-k3' '-k3,1n' '-k-1' '-k-2n,1' '-k-1x,-2' '-D' '-D -k2' '-D -k2n,1' \
  '-u -D -k1' '-D -k-1' '-D -x' '-k' ; do
  # shellcheck disable=SC2086
  eq "encoded equals compared: srt $o" "$(srt --mem 64k $o mix | cksum)" "$(srt $o mix | cksum)"
done
for o in '-t: -k-1' '-t: -D -k-1' '-t: -k2x' '-t: -D -k2,3' '-t: -k3' ; do
  # shellcheck disable=SC2086
  eq "encoded equals compared: srt $o" "$(srt --mem 64k $o mixc | cksum)" "$(srt $o mixc | cksum)"
done
# -D across spilled runs: a group split between runs is still a group
awk 'BEGIN { for (i = 1; i <= 30000; i++) print (i % 7 ? "u" i : "g" (i % 50)), i }' > dbig
awk '{ n[$1]++ ; l[NR] = $1 } END { for (i = 1; i <= NR; i++) if (n[l[i]] > 1) c++ ; print c + 0 }' dbig > dwant
read -r want < dwant ; read -r n < <(srt --mem 64k -D -k1 dbig | wc -l)
eq '-D over spilled runs: every member, nothing else' "$((want))" "$((n))"
eq '-D over spilled runs equals -D in memory' "$(srt -D -k1 dbig | cksum)" "$(srt --mem 64k -D -k1 dbig | cksum)"
e=$(SRT_STATS=1 "$S" --mem 64k -D -k1 dbig 2>&1 >/dev/null)
[[ $e =~ runs=([0-9]+) ]] && [ "${BASH_REMATCH[1]}" -gt 1 ] && r=spilled || r="other ($e)"
eq '-D case did spill' spilled "$r"
eq 'encoded equals compared on wide data' "$(srt --mem 64k -k3f,2nr wide | cksum)" "$(srt -k3f,2nr wide | cksum)"
printf 'a\0b\na\na\0\nab\n\0\n' > nul
eq 'encoded keys keep NUL bytes in order' "$(srt --mem 64k -f nul | cksum)" "$(srt -f nul | cksum)"
eq 'NUL byte order' $'\na\nab' "$(srt -f nul | tr -d '\0' | srt -u)"

printf 'test-srt.sh: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
