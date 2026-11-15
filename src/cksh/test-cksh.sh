#!/usr/bin/env bash
# test-cksh.sh --- regression suite for cksh
#
# usage: test-cksh.sh [path-to-cksh]     exit 0 when every case passes
# Covers plan-cksh.md section 9, cases 1-13: the binary, then the bash
# function held to the same bytes and status. The count of cases run
# varies by host: those needing a non-root user, openssl shake256,
# /dev/full, a pty through script(1), srt, or a file system that takes
# a name that is not UTF-8 skip themselves and say so.
#
# revision 6af8d530 20261114 134000 PST Sat --- r0.6: bash; key lists, -x in
#          hex characters, bare -n and -x, retired spellings, signed mdate,
#          terminal escapes, d/, form selection, srt equivalence, -Z;
#          after the Darwin report: a name that is not UTF-8 is optional,
#          the namespace cases start from an empty environment, the
#          stand-in for an openssl without -xoflen no longer needs the
#          real one to have a default length, script(1) in either form;
#          -L, -o, -c; --man; --help through a formatter on a terminal
# revision 6ab7e734 20260926 083932 PDT Sat --- r0.5: test.sh, POSIX sh
#
# (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
set -uo pipefail

B=${1:-./cksh}
[[ $B == /* ]] || B=$PWD/$B
[ -x "$B" ] || { printf 'test-cksh.sh: %s: not executable\n' "$B" >&2 ; exit 2 ;}
read -r HERE < <(cd "$(dirname "$0")" && pwd)
F=${CKSH_FN_FILE:-$HERE/cksh.fn.bash}
[[ $F == /* ]] || F=$PWD/$F
SRT=${SRT:-} ; [ -n "$SRT" ] || { read -r SRT < <(type -P srt) || : ;}

# scratch: literal class cksh-test., kept suffix only
tmp_id=
trap '[ -z "$tmp_id" ] || { chmod -R u+rwx "${TMPDIR:-/tmp}/cksh-test.$tmp_id" 2>/dev/null ; rm -rf "${TMPDIR:-/tmp}/cksh-test.$tmp_id" ;}' EXIT
trap 'exit 130' INT HUP TERM
read -r D < <(mktemp -d "${TMPDIR:-/tmp}/cksh-test.XXXXXX")
tmp_id=${D##*/cksh-test.}
[[ $tmp_id =~ ^[A-Za-z0-9]+$ ]] || { tmp_id= ; exit 2 ;}
cd "$D" || exit 2

pass=0 fail=0 skip=0
eq(){ # name want got
  [ "$2" == "$3" ] && { pass=$((pass+1)) ;} || {
    fail=$((fail+1)) ; printf 'FAIL %s\n  want: %q\n  got:  %q\n' "$1" "$2" "$3" ;} ;}
sk(){ skip=$((skip+1)) ; printf 'skip: %s\n' "$*" ;}
# binary: stdout, then the status on its own line; stderr dropped
c(){ "$B" "$@" 2>/dev/null ; echo "rc=$?" ;}
# the function, never handing over: same contract
b(){ bash -c '. "$0" ; cksh --fn "$@"' "$F" "$@" 2>/dev/null ; echo "rc=$?" ;}
# standard error alone, then the status: diagnostics
ce(){ "$B" "$@" 2>&1 >/dev/null ; echo "rc=$?" ;}
be(){ bash -c '. "$0" ; cksh --fn "$@"' "$F" "$@" 2>&1 >/dev/null ; echo "rc=$?" ;}
col(){ awk -v n="$1" '{print $n}' ;}
perm(){ stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1" ;}
names(){ awk '{printf "%s ", substr($0, index($0,$6))}' | sed 's/ $//' ;}
# a clean shell: no exported function or variable of the caller reaches it
clean(){ env -i PATH="$PATH" HOME="$HOME" bash --noprofile --norc "$@" ;}
# run a command line on a pty; script(1) comes in two forms. The form is
# kept only if a probe comes back exact, else the terminal cases skip.
ptyform=
pty(){ case $ptyform in
    l) script -qec "$1" /dev/null </dev/null ;;
    b) script -q /dev/null bash -c "$1" </dev/null ;;
  esac 2>/dev/null | tr -d '\r' | sed $'s/^\\^D\b\b//' ;}
for ptyform in l b '' ; do
  [ -n "$ptyform" ] || break
  [ "$(pty 'printf ok')" != ok ] || break
done

ssl= have_ssl=
read -r ssl < <(type -P openssl) || :
[ -z "$ssl" ] || { read -r _ h < <(openssl shake256 -xoflen 4 -hex </dev/null 2>/dev/null) || :
  [ "${h:-}" != 46b9dd2b ] || have_ssl=1 ;}

# fixtures: regular, empty, symlink, dir, dangling, fifo, space, dash, digit
mkdir -p t/d
printf abc > t/a ; : > t/e ; ln -s a t/l ; ln -s nope t/dang ; ln -s d t/ld
printf x > 't/sp ace' ; printf q > t/-kr ; printf 5 > t/5 ; mkfifo t/p
touch -t 202001010000 t/a ; touch -t 202101010000 t/e ; touch -t 201901010000 't/sp ace'
f=(t/a t/e t/d 't/sp ace')

# ---- 1 SHAKE256: FIPS 202 vectors; a shorter hash begins every longer --
nist_e=46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762fd75dc4ddd8c0f200cb05019d67b592f6fc821c49479ab48640292eacb3b7c4be
nist_a=483366601360a8771c6863080cc4114d8db44530f8f1e1ee4f94ea37e78b5739d5a15bef186a5386c75744c0527e1faa9f8726e462a12a4feb06bd8801e751e4
eq 'nist empty -x128' "$nist_e" "$("$B" -x128 t/e | col 3)"
eq 'nist abc -x128' "$nist_a" "$("$B" -x128 t/a | col 3)"
eq 'default is shake256-6' "${nist_a:0:6}" "$("$B" t/a | col 3)"
for x in 1 5 6 7 63 64 127 ; do
  eq "prefix -x$x" "${nist_a:0:x}" "$("$B" -x$x t/a | col 3)"
done
eq '-x counts hex characters' 64 "$("$B" -x64 t/a | awk '{print length($3)}')"
# rate boundary and a multi-read file against openssl, whose -xoflen is bytes
[ -n "$have_ssl" ] && {
  for n in 135 136 137 272 200000 ; do
    dd if=/dev/urandom of=o$n bs=$n count=1 2>/dev/null
    for x in 2 14 64 66 128 ; do
      read -r _ h < <(openssl shake256 -xoflen $((x/2)) -hex < o$n)
      eq "openssl $n -x$x" "$h" "$("$B" -x $x o$n | col 3)"
    done
  done ;} || sk 'openssl -xoflen cross-check'

# ---- 2 output format ---------------------------------------------------
eq 'dir zeros' 000000 "$("$B" t/d | col 3)"
eq 'fifo zeros' 000000 "$("$B" t/p 2>/dev/null | col 3)"
eq 'indicators' 't/d/ t/l@ t/p| t/-kr' "$("$B" -n5 -- t/d t/l t/p t/-kr | names)"
eq 'space name' '. . . . . t/sp ace' "$("$B" -n5 't/sp ace')"
eq '-x0 dot' . "$("$B" -x0 t/a | col 3)"
eq '-n3 omits hash' '. . . ' "$("$B" -n3 t/a | cut -c1-6)"
eq '-n0 columns' 6 "$("$B" -n0 t/a | awk '{print NF}')"
eq 'default -n2' '. .' "$("$B" t/a | awk '{print $1, $2}')"
# a directory named with a trailing slash keeps the one
eq 'd/ stays d/' 't/d/' "$("$B" -n5 t/d/ | names)"
eq 'ld/ follows, one slash' 't/ld/' "$("$B" -n5 t/ld/ | names)"
eq 'symlink to dir' 't/ld@' "$("$B" -n5 t/ld | names)"

# ---- 3 exit status bitmask and diagnostics --------------------------------
eq 'rc ok' rc=0 "$(c t/a t/d | tail -1)"
eq 'rc missing 4' rc=4 "$(c t/nope | tail -1)"
eq 'rc fifo 16' rc=16 "$(c t/p | tail -1)"
eq 'rc dangling 32' rc=32 "$(c t/dang | tail -1)"
eq 'rc combined 52' rc=52 "$(c t/nope t/p t/dang t/a | tail -1)"
eq 'missing skipped, rest printed' 3 "$(c t/nope t/p t/dang t/a | grep -vc rc=)"
eq '-x0 no fifo warning' rc=0 "$(c -x0 t/p t/dang | tail -1)"
eq 'empty argument skipped' rc=0 "$(c '' | tail -1)"
eq 'err format' ">>> cksh : cannot stat 't/nope'" \
  "$("$B" t/nope 2>&1 >/dev/null | sed -n 's/^\(>>> cksh : cannot stat .t.nope.\).* (6ab75465)$/\1/p')"
eq 'wrn format' "^^^ cksh : fifo, not hashed 't/p' (6ab75468)" "$("$B" t/p 2>&1 >/dev/null)"
[ "$(id -u)" != 0 ] && {
  printf s > t/unr ; chmod 000 t/unr
  eq 'rc unreadable 8' rc=8 "$(c t/unr | tail -1)"
  eq 'unreadable skipped' 1 "$(c t/unr | wc -l | tr -d ' ')"
  chmod 600 t/unr ; rm -f t/unr ;} || sk 'unreadable (running as root)'
[ -w /dev/full ] && {
  "$B" t/a > /dev/full 2>/dev/null ; eq 'rc stdout full 2' 2 $?
  "$B" -k t/a > /dev/full 2>/dev/null ; eq 'rc stdout full 2, sorted' 2 $? ;} || sk '/dev/full'
# a fifo is never opened: with no writer a blocking open would hang
( "$B" t/p > o.fifo 2>&1 ) & pid=$!
i=0 ; while kill -0 $pid 2>/dev/null && [ $i -lt 50 ] ; do sleep 0.1 ; i=$((i+1)) ; done
kill -0 $pid 2>/dev/null && { kill $pid ; eq 'fifo hang' no yes ;} || eq 'fifo never opened' ok ok

# ---- 4 option grammar ----------------------------------------------------
for o in '-k7' '-k0' '-k 7' '-k5n' '-k3x' '-k6x' '-k5,5' '-k5 -k5' '-k-1' '-kr5' '-kr' '-k5,' '-k,5' '-k12' \
    '-x 129' '-x1a' '-n 6' '-n9' '-nr' '-q' '--nope' '-3' '-0' '--fn' ; do
  eq "usage [$o]" rc=1 "$(c $o t/a)"
done
eq 'retired -3 names -n' 1 "$("$B" -3 t/a 2>&1 | grep -c 'write -n0 to -n5')"
eq 'retired -kr5 names -kNr' 1 "$("$B" -kr5 t/a 2>&1 | grep -c 'write -kNr')"
# bare -n and -x: the next word is a value only when it reads as one
eq 'bare -n before a file' "$(c -n0 t/a)" "$(c -n t/a)"
eq 'bare -x before a file' "$(c -x0 t/a)" "$(c -x t/a)"
eq 'bare -n last' "$(printf 't/a\n' | c -n0)" "$(printf 't/a\n' | c -n)"
eq '-n 3 separate' "$(c -n3 t/a)" "$(c -n 3 t/a)"
eq '-x 64 separate' "$(c -x64 t/a)" "$(c -x 64 t/a)"
eq 'cluster -rn0' "$(c -r -n0 t/a t/e)" "$(c -rn0 t/a t/e)"
eq 'cluster -rk5' "$(c -r -k5 "${f[@]}")" "$(c -rk5 "${f[@]}")"
eq '-k 5 separate' "$(c -k5 "${f[@]}")" "$(c -k 5 "${f[@]}")"
eq '-k before files' "$(c -k6 t/e t/a)" "$(c -k t/e t/a)"
eq '-k then a non-list word is a file' rc=4 "$(c -k r | tail -1)"
( cd t && eq '-n -- 5 is the file' ". . $("$B" 5 | col 3)" "$("$B" -n2 -- 5 | awk '{print $1, $2, $3}')" )
( cd t && eq '-k ./5 is the file' rc=0 "$(c -k ./5 | tail -1)" )
eq '--bin accepted by the binary' "$(c t/a)" "$(c --bin t/a)"
eq 'options end at the first file' rc=4 "$(c t/a -n0 | tail -1)"

# ---- 5 keys: named columns, then the rest left to right -------------------
# oracle: fixed-width decimal keys and the name, then byte 1 and the line,
# through the native sort (no fixture name holds a blank-led sixth word)
dec(){ "$B" -n0 "$@" | awk '
  function hx(s,  i, v, neg) { neg = (substr(s,1,1) == "-") ; if (neg) s = substr(s,2) ; v = 0
    for (i = 1; i <= length(s); i++) v = v * 16 + index("0123456789abcdef", substr(s,i,1)) - 1
    return neg ? -v : v }
  { printf "%020d %020d %s %020d %020d %s\n", hx($1), hx($2), $3, hx($4), hx($5) + 100000000000, substr($0, index($0,$6)) sprintf("%c", 1) $0 }' ;}
ora(){ local ks=$1 ; shift ; dec "$@" | LC_ALL=C sort -s -t ' ' $ks | cut -d $'\001' -f 2 ;}
all=(t/a t/e t/d 't/sp ace' t/l t/5 t/ld)
eq '-k5,4' "$(ora '-k5,5 -k4,4 -k1,1 -k2,2 -k3,3 -k6' "${all[@]}")" "$("$B" -n0 -k5,4 "${all[@]}")"
eq '-k5 -k4 is -k5,4' "$("$B" -n0 -k5,4 "${all[@]}")" "$("$B" -n0 -k5 -k4 "${all[@]}")"
eq 'bare -k: name, then 1-5' "$(ora '-k6' "${all[@]}")" "$("$B" -n0 -k "${all[@]}")"
eq '-k3: hash, then the rest' "$(ora '-k3,3 -k1,1 -k2,2 -k4,4 -k5,5 -k6' "${all[@]}")" "$("$B" -n0 -k3 "${all[@]}")"
eq '-k4r,6' "$(ora '-k4,4r -k6' "${all[@]}")" "$("$B" -n0 -k4r,6 "${all[@]}")"
eq '-k5r: column 5 only' "$(ora '-k5,5r -k1,1 -k2,2 -k3,3 -k4,4 -k6' "${all[@]}")" "$("$B" -n0 -k5r "${all[@]}")"
eq '-r -k5: every column' "$(ora '-k5,5r -k1,1r -k2,2r -k3,3r -k4,4r -k6r' "${all[@]}")" "$("$B" -n0 -r -k5 "${all[@]}")"
eq '-r -k5x: letters replace -r' "$(ora '-k5,5 -k1,1r -k2,2r -k3,3r -k4,4r -k6r' "${all[@]}")" "$("$B" -n0 -r -k5x "${all[@]}")"
eq 'x is a no-op' "$("$B" -n0 -k5,4,6 "${all[@]}")" "$("$B" -n0 -k5x,4x,6 "${all[@]}")"
eq '-k5 by date' 't/sp ace t/a t/e' "$("$B" -k5 t/e t/a 't/sp ace' | names)"
eq '-k5r newest first' 't/e t/a t/sp ace' "$("$B" -k5r t/e t/a 't/sp ace' | names)"
eq '-r alone reverses input' 't/sp ace t/d/ t/e t/a' "$("$B" -r "${f[@]}" | names)"
# an omitted column is a null column: the key orders nothing, the next decides
eq 'key on an omitted column' "$("$B" -k3 "${all[@]}")" "$("$B" -k1,3 "${all[@]}")"
eq 'key on an omitted column, rc' rc=0 "$(c -n5 -k4 t/a | tail -1)"
eq '-n5 -k4 is by name' 't/5 t/a t/e' "$("$B" -n5 -k4 t/e t/a t/5 | names)"
# equal records keep input order (the same name twice is the only such case)
eq 'equal records, both kept' 2 "$("$B" -k4 t/a t/a | wc -l | tr -d ' ')"

# wide values sort by value and move only their own line
mkdir -p w
truncate -s 4294967296 w/big 2>/dev/null || dd if=/dev/null of=w/big bs=1 seek=4294967296 2>/dev/null
truncate -s 4294967295 w/bigm 2>/dev/null || dd if=/dev/null of=w/bigm bs=1 seek=4294967295 2>/dev/null
printf s > w/small
eq 'wide size -k4' 'w/small w/bigm w/big' "$("$B" -n3 -k4 w/big w/small w/bigm | names)"
eq 'wide size -k4r' 'w/big w/bigm w/small' "$("$B" -n3 -k4r w/big w/small w/bigm | names)"
{ touch -t 220001010000 w/future 2>/dev/null && touch -t 196001010000 w/past 2>/dev/null ;} && {
  eq 'mdate -k5 across 1970 and 2106' 'w/past w/small w/future' "$("$B" -n3 -k5 w/future w/small w/past | names)"
  eq 'wide mdate column' 9 "$("$B" -n3 w/future | awk '{print length($5)}')"
  eq 'negative mdate is signed hex' - "$("$B" -n3 w/past | col 5 | cut -c1)"
  read -r _ _ _ _ m _ < <("$B" -n3 w/past)
  eq 'negative mdate round trip' "$(stat -c %Y w/past 2>/dev/null || stat -f %m w/past)" "$(( -(16#${m#-}) ))"
} || sk 'mdate outside 1970-2106 unsupported here'

# ---- 6 the same order from srt ------------------------------------------
[ -n "$SRT" ] && "$SRT" -k4x </dev/null >/dev/null 2>&1 && {
  # t/* hashed; w/* (4 GiB sparse, and times outside 1970-2106) with -x0
  sq(){ eq "srt $1 = $2" "$("$B" -n0 $1 -- t/* 2>/dev/null)" "$("$B" -n0 -- t/* 2>/dev/null | "$SRT" $2)"
    eq "srt $1 = $2, wide" "$("$B" -x0 -n0 $1 w/*)" "$("$B" -x0 -n0 w/* | "$SRT" $2)" ;}
  sq -k5,4,6 -k5x,4x,6,1x,2x,3
  sq -k -k6,1x,2x,3,4x,5x
  sq -k5 -k5x,1x,2x,3,4x,6
  sq -k4r,6 -k4xr,6,1x,2x,3,5x
  sq -k3,1 -k3,1x,2x,4x,5x,6
  sq -rk5 -k5xr,1xr,2xr,3r,4xr,6r
  eq 'srt on the default listing' "$("$B" -k5,4 -- t/* 2>/dev/null)" \
    "$("$B" -- t/* 2>/dev/null | "$SRT" -k5x,4x,1x,2x,3,6)"
} || sk 'srt with -x not found (set SRT=path): equivalence cases'

# ---- 7 standard input ---------------------------------------------------
eq 'stdin as arguments' "$(c t/a t/e)" "$(printf 't/a\n\nt/e' | c)"
eq 'stdin NUL line' rc=4 "$(printf 't/a\nt/\0e\n' | c | tail -1)"
printf 'bs' > 't/b\s'
eq 'stdin keeps backslashes' 't/b\s' "$(printf '%s\n' 't/b\s' | "$B" -n5 | names)"

# ---- 8 terminal: names escaped only when the stream is a terminal --------
# ESC and a C1 control (c2 85) are valid in any file system; a byte that
# is not UTF-8 (ff) is refused by some, and is then tried in a diagnostic
nm=$'t/esc\033[31m\302\205\377e' want='t/esc\033[31m\302\205\377e'
{ printf z > "$nm" ;} 2>/dev/null || { sk 'file system refuses a name that is not UTF-8'
  nm=$'t/esc\033[31m\302\205e' want='t/esc\033[31m\302\205e' ; printf z > "$nm" ;}
eq 'pipe: name as it is' ". . . . . $nm" "$("$B" -n5 "$nm")"
printf u > $'t/\303\251'
printf '%s\n' "'$B' -n5 t/esc*" > p1.sh
printf '%s\n' "'$B' -n5 t/"$'\303\251' > p2.sh
printf '%s\n' "'$B' "'$'"'t/no\\033\\377pe'" > p3.sh
printf '%s\n' "'$B' -Z -n5 t/esc* | tr '\\0' '\\n'" > p4.sh
printf '%s\n' ". '$F' ; cksh --fn -n5 t/esc* t/n*" > p5.sh
printf '%s\n' "'$B' -n5 t/esc* t/n*" > p6.sh
[ -n "$ptyform" ] && {
  eq 'terminal: \ooo escapes' ". . . . . $want" "$(pty "bash $D/p1.sh")"
  eq 'terminal: valid UTF-8 passes' $'. . . . . t/\303\251' "$(pty "bash $D/p2.sh")"
  eq 'terminal: diagnostics escaped' 1 "$(pty "bash $D/p3.sh" | grep -c 'no\\033\\377pe')"
} || sk 'no pty through script(1): terminal cases'

# ---- 8b -Z: NUL ends lines and names on standard input --------------------
eq '-Z lines end in NUL' "$("$B" -n5 t/a t/e)" "$("$B" -Z -n5 t/a t/e | tr '\0' '\n')"
eq '-Z writes no newline' 0 "$("$B" -Z -n5 t/a t/e | tr -cd '\n' | wc -c | tr -d ' ')"
printf n > $'t/n\nl'
eq '-Z names from stdin, one with a newline' 3 "$(printf 't/a\0t/n\nl\0\0t/e' | "$B" -Z -n5 | tr -cd '\0' | wc -c | tr -d ' ')"
eq '-Z stdin status' rc=0 "$(printf 't/a\0t/n\nl\0' | c -Z -n5 | tr '\0' '\n' | tail -1)"
eq '-Z with -k' "$("$B" -k5,4 "${all[@]}")" "$("$B" -Z -k5,4 "${all[@]}" | tr '\0' '\n')"
eq '-Z in a cluster' "$("$B" -Z -r -n5 t/a t/e | od -c)" "$("$B" -rZn5 t/a t/e | od -c)"
[ -n "$ptyform" ] && eq '-Z: names as they are, even to a terminal' ". . . . . $nm" "$(pty "bash $D/p4.sh")" ||
  sk 'no pty through script(1): -Z terminal case'
[ -n "$SRT" ] && "$SRT" -z -k4x </dev/null >/dev/null 2>&1 &&
  eq 'cksh -Z | srt -z' "$("$B" -n0 -k5,4,6 "${all[@]}")" "$("$B" -Z -n0 "${all[@]}" | "$SRT" -z -k5x,4x,6,1x,2x,3 | tr '\0' '\n')" ||
  sk 'srt with -z and -x not found: NUL pipeline case'

# ---- 8c -L: a symlink is listed as the file it leads to --------------------
eq '-L names and indicators' 't/l t/ld/ t/dang@' "$("$B" -L -n5 t/l t/ld t/dang | names)"
eq '-L columns are those of the target' "$("$B" -n0 t/a | awk '{print $1,$2,$3,$4,$5}')" \
  "$("$B" -L -n0 t/l | awk '{print $1,$2,$3,$4,$5}')"
eq 'without -L the link is itself' 1 "$("$B" -n0 t/l | awk '{print $4}')"
eq '-L dangling: the link, warned' rc=32 "$(c -L t/dang | tail -1)"
eq '-L in a cluster' "$("$B" -L -r -n5 t/l t/ld)" "$("$B" -rLn5 t/l t/ld)"

# ---- 8d -o: written beside the destination, renamed when complete ----------
mkdir -p k ; printf abc > k/a ; printf 'hello\n' > k/e ; mkdir k/d
printf sp > 'k/sp ace' ; printf w > 'k/w@' ; printf b > 'k/ lead'
touch -t 202001010000 k/a ; touch -t 202101010000 k/e
kf=(k/a k/e k/d 'k/sp ace' 'k/w@' 'k/ lead')
eq '-o: nothing on standard output' rc=0 "$(c -k -o o1.ck "${kf[@]}")"
eq '-o: the file is the listing' "$("$B" -k "${kf[@]}")" "$(cat o1.ck)"
chmod 640 o1.ck ; "$B" -k -o o1.ck "${kf[@]}"
eq '-o keeps the mode of the destination' 640 "$(perm o1.ck)"
( umask 027 ; "$B" -o o2.ck k/a ) ; eq '-o: a new file takes the umask' 640 "$(perm o2.ck)"
cp o1.ck o1.sav
eq '-o: usage error' rc=1 "$(c -o o1.ck -k7 k/a)"
eq '-o: a failed run leaves the original' "$(cat o1.sav)" "$(cat o1.ck)"
printf 'not a record\n' > bad.ck
eq '-o: a run that stops midway' rc=1 "$(c -c bad.ck -o o1.ck)"
eq '-o: and still the original' "$(cat o1.sav)" "$(cat o1.ck)"
eq '-o: no temporary file is left' 0 "$(ls -A . k | grep -c '^\.cksh\.')"
eq '-o: a directory is refused' rc=1 "$(c -o k k/a)"
eq '-o: no such directory' rc=2 "$(c -o nodir/x.ck k/a)"
eq '-o: no value' rc=1 "$(c -o)"
eq '-o: joined value' "$(cat o2.ck)" "$("$B" -oo3.ck k/a ; cat o3.ck)"
"$B" -o /dev/null k/a ; eq '-o: a device is written through' "0 yes" "$? $([ -c /dev/null ] && echo yes)"
eq '-o: with errors the listing is still placed' "rc=4 1" "$(c -o o4.ck k/a k/nope) $(wc -l < o4.ck | tr -d ' ')"
( cd k && "$B" -k -o list.ck a e && "$B" -k -o list.ck a e list.ck )
eq '-o: output among the files listed' 3 "$(wc -l < k/list.ck | tr -d ' ')" ; rm -f k/list.ck

# ---- 8e -c: a listing read back against its files -----------------------
"$B" -n0 -k -o c0.ck "${kf[@]}" ; "$B" -k -o c2.ck "${kf[@]}" ; "$B" -x -k -o cx.ck "${kf[@]}"
"$B" -x64 -o c64.ck k/a k/e ; cat c2.ck c64.ck > cmix.ck
eq '-c: nothing changed' rc=0 "$(c -c c0.ck)"
eq '-c: default listing' rc=0 "$(c -c c2.ck)"
eq '-c: mixed hash widths in one listing' rc=0 "$(c -c cmix.ck)"
eq '-c: listing on standard input' rc=0 "$(c -c - < c0.ck)"
eq '-c: a name with a leading blank, and one ending in @' 2 "$(grep -c -e 'k/ lead$' -e 'k/w@$' c0.ck)"
eq '-c: -n and -x are not consulted' rc=0 "$(c -n5 -x64 -c c0.ck)"
# content changed, size and time kept: seen by the hash alone
printf abd > k/a ; touch -t 202001010000 k/a
eq '-c: content changed' "$("$B" -n0 k/a ; echo rc=64)" "$(c -c c0.ck)"
eq '-c: the line is in the columns of its record' "$("$B" k/a ; echo rc=64)" "$(c -c c2.ck)"
eq '-c: a record without a hash does not read the file' rc=0 "$(c -c cx.ck)"
eq '-c: shake256-64 record' "$("$B" -x64 k/a ; echo rc=64)" "$(c -c c64.ck)"
printf abc > k/a ; touch -t 202001010000 k/a
eq '-c: restored' rc=0 "$(c -c c0.ck)"
# time alone
touch -t 202201010000 k/e
eq '-c: time changed' "$("$B" k/e ; echo rc=64)" "$(c -c c2.ck)"
touch -t 202101010000 k/e
# inode: compared only where the record holds it
cp -p k/e k/e2 ; mv k/e2 k/e
eq '-c: a new inode, listed' "$("$B" -n0 k/e ; echo rc=64)" "$(c -c c0.ck)"
eq '-c: a new inode, not listed' rc=0 "$(c -c c2.ck)"
"$B" -n0 -k -o c0.ck "${kf[@]}"
# the kind of node
rmdir k/d ; printf f > k/d
eq '-c: a file where a directory was' 'k/d' "$("$B" -c c2.ck | names)"
rm k/d ; mkdir k/d ; "$B" -n0 -k -o c0.ck "${kf[@]}" ; "$B" -k -o c2.ck "${kf[@]}"
# gone
mv k/a k/a.away
eq '-c: a file that is gone' rc=4 "$(c -c c2.ck | tail -1)"
eq '-c: gone and changed together' rc=68 "$(touch -t 202201010000 k/e ; c -c c2.ck | tail -1)"
mv k/a.away k/a ; touch -t 202101010000 k/e
"$B" -n0 -k -o c0.ck "${kf[@]}" ; "$B" -k -o c2.ck "${kf[@]}"
# what is written can be sorted and kept
touch -t 202201010000 k/e ; touch -t 202301010000 k/a
eq '-c with -k5r' 'k/a k/e' "$("$B" -c c2.ck -k5r | names)"
eq '-c with -r' 'k/e k/a' "$("$B" -c c2.ck -r | names)"
eq '-c with -o, onto the listing itself' "$("$B" -k k/a k/e)" "$(cp c2.ck c5.ck ; "$B" -k -c c5.ck -o c5.ck ; cat c5.ck)"
touch -t 202001010000 k/a ; touch -t 202101010000 k/e
"$B" -n0 -k -o c0.ck "${kf[@]}" ; "$B" -k -o c2.ck "${kf[@]}"
# -Z and -L listings are checked with the same option
"$B" -Z -k -o cz.ck "${kf[@]}" ; eq '-c -Z' rc=0 "$(c -Z -c cz.ck | tr '\0' '\n')"
ln -s e k/lk
"$B" -L -k -o cl.ck k/a k/lk ; eq '-c -L' rc=0 "$(c -L -c cl.ck)"
eq '-c: an -L listing without -L differs' 'k/lk@' "$("$B" -c cl.ck | names)"
"$B" -k -o clk.ck k/lk ; printf 'hello!\n' > k/e ; touch -t 202101010000 k/e
eq '-c: a link whose target changed' 'k/lk@' "$("$B" -c clk.ck | names)"
printf 'hello\n' > k/e ; touch -t 202101010000 k/e
# errors
eq '-c: not a cksh line' rc=1 "$(c -c bad.ck)"
eq '-c: five words and no name' rc=1 "$(printf '. . . . .\n' | c -c -)"
eq '-c: no listing' rc=2 "$(c -c nope.ck)"
eq '-c: no value' rc=1 "$(c -c)"
eq '-c: no file may be named' rc=1 "$(c -c c0.ck k/a)"
eq '-c: empty listing' rc=0 "$(: | c -c -)"

# ---- 8f --help on a terminal: a man page through the formatter of the host
# stand-ins that pass their input through, so the source shows; a PATH
# that holds no formatter falls back to the pager alone
mkdir -p fmt/m fmt/n fmt/none
printf '#!/bin/sh\necho "MANDOC $*"\ncat\n' > fmt/m/mandoc
printf '#!/bin/sh\necho "NROFF $*"\ncat\n' > fmt/n/nroff
chmod 755 fmt/m/mandoc fmt/n/nroff
for x in sh cat bash ; do read -r p < <(type -P $x) && for d in m n none ; do ln -s "$p" fmt/$d/$x ; done ; done
eq '--man: sections' 16 "$("$B" --man | grep -c '^\.SH ')"
eq '--man: example groups are sub-headings' 6 "$("$B" --man | grep -c '^\.SS ')"
eq '--man: no line begins with a bare quote or stray dot' 0 "$("$B" --man | grep -vc -e '^\.TH ' -e '^\.SH ' -e '^\.SS ' -e '^\.nf$' -e '^\.fi$' -e '^[^.'"'"']' -e '^$' -e '^\\&')"
eq '--help to a pipe is plain' 0 "$("$B" --help | grep -c '^\.SH')"
[ -n "$ptyform" ] && {
  eq 'terminal --help: mandoc first' 'MANDOC -a' "$(pty "env PATH=$D/fmt/m PAGER=cat '$B' --help" | head -1)"
  eq 'terminal --help: the man page source' 16 "$(pty "env PATH=$D/fmt/m PAGER=cat '$B' --help" | grep -c '^\.SH ')"
  eq 'terminal --help: nroff and the pager' 'NROFF -c -man' "$(pty "env PATH=$D/fmt/n PAGER=cat '$B' --help" | head -1)"
  eq 'terminal --help: no formatter, the pager alone' "$("$B" --help)" "$(pty "env PATH=$D/fmt/none PAGER=cat '$B' --help")"
} || sk 'no pty through script(1): --help cases'

# ---- 9 help, version, man page ------------------------------------------
eq '-h rc' 0 "$("$B" -h >/dev/null ; echo $?)"
eq '--help rc' 0 "$("$B" --help >/dev/null ; echo $?)"
eq '-V' 'cksh r0.' "$("$B" -V | cut -c1-8)"
eq '--version' "$("$B" -V)" "$("$B" --version)"
eq '--help sections' 'NAME SYNOPSIS DESCRIPTION OPTIONS KEYS CHECK HASH TERMINAL BASH FUNCTION ENVIRONMENT EXIT STATUS DIAGNOSTICS EXAMPLES NOTES SEE ALSO REVISION' \
  "$("$B" --help | grep '^[A-Z][A-Z ]*$' | tr '\n' ' ' | sed 's/ $//')"
eq 'see also' '    ff(1), srt(1)' "$("$B" --help | sed -n '/^SEE ALSO$/{n;n;p;}')"
eq 'no copyright in --help' 0 "$("$B" --help | grep -ci -e copyright -e '(c) ')"
eq 'no copyright in -h' 0 "$("$B" -h | grep -ci -e copyright -e '(c) ')"
eq 'no slash label but the three readings' 3 "$("$B" --help | grep -ci 'shake256/')"
eq 'hash named shake256-6' 1 "$("$B" -h | grep -c 'shake256-6')"
eq 'ASCII only' 0 "$("$B" --help | LC_ALL=C grep -c '[^ -~]')"
eq 'lines within 80' 0 "$("$B" --help | awk 'length($0) > 80' | wc -l | tr -d ' ')"
eq 'blank line before each example group' 6 \
  "$("$B" --help | awk '/^EXAMPLES$/ {e=1} /^NOTES$/ {e=0} e && /^  [A-Z]/ && prev == "" {n++} {prev=$0} END {print n+0}')"
[ -f "$HERE/cksh.1" ] && {
  eq 'cksh.1 has no copyright' 0 "$(grep -ci -e copyright -e '(c) ' "$HERE/cksh.1")"
  eq 'cksh.1 is the output of --man' "$("$B" --man)" "$(cat "$HERE/cksh.1")"
} || sk 'cksh.1 not built beside the suite'

# ---- 10 files carry the copyright; help and man do not -------------------
for x in cksh.c cksh.fn.bash makefile test-cksh.sh README.md plan-cksh.md ; do
  [ -f "$HERE/$x" ] && eq "copyright in $x" 1 "$(grep -c '(c) 2017-2026 George Georgalis' "$HERE/$x" | awk '{print ($1 >= 1)}')" || sk "$x not beside the suite"
done

# ---- 11 bash function: one name, form selection ----------------------------
[ -f "$F" ] && {
  eq 'one name defined' 'declare -f cksh' "$(clean -c '. "$0" ; declare -F' "$F")"
  eq 'nothing else set' '' "$(clean -c 'a=$(compgen -v | sort) ; . "$0" ; cksh --fn -V >/dev/null ; cksh --fn -n 5 -k 6,5r -o /dev/null -x 0 t/a ; cksh --fn -c /dev/null ; comm -13 <(printf "%s\n" "$a") <(compgen -v | sort) | grep -v -x -e a -e PIPESTATUS -e _'  "$F")"
  eq 'function -h is the binary text' "$("$B" -h)" "$(bash -c '. "$0" ; cksh --fn -h' "$F")"
  eq 'function --help is the binary text' "$("$B" --help)" "$(bash -c '. "$0" ; cksh --fn --help' "$F")"
  eq 'function --man is the binary text' "$("$B" --man)" "$(bash -c '. "$0" ; cksh --fn --man' "$F")"
  eq 'function -V' "$("$B" -V) (bash function)" "$(bash -c '. "$0" ; cksh --fn -V' "$F")"
  eq 'hands over to a binary on PATH' "$("$B" -V)" "$(PATH=${B%/*}:$PATH bash -c '. "$0" ; cksh -V' "$F")"
  eq '--bin runs the binary' "$("$B" -V)" "$(PATH=${B%/*}:$PATH bash -c '. "$0" ; cksh --bin -V' "$F")"
  mkdir -p nobin ; for x in bash uname stat sort ; do read -r p < <(type -P $x) && ln -s "$p" nobin/$x ; done
  eq '--bin with no binary is 2' 2 "$(PATH=$D/nobin "$D/nobin/bash" -c '. "$0" ; cksh --bin -V' "$F" >/dev/null 2>&1 ; echo $?)"
  eq 'no binary: the function works' "$("$B" -V) (bash function)" "$(PATH=$D/nobin "$D/nobin/bash" -c '. "$0" ; cksh -V' "$F")"
  eq '--fn and --bin refused' 1 "$(bash -c '. "$0" ; cksh --fn --bin' "$F" >/dev/null 2>&1 ; echo $?)"
  eq '--fn after a file is a file' rc=4 "$(PATH=${B%/*}:$PATH bash -c '. "$0" ; cksh t/a --fn' "$F" 2>/dev/null >/dev/null ; echo rc=$?)"
} || sk 'cksh.fn.bash not found: function cases'

# ---- 12 bash function parity: the same bytes and status --------------------
{ [ -f "$F" ] && [ -n "$have_ssl" ] ;} && {
  for o in '' -n -n0 -n1 -n2 -n3 -n4 -n5 -x -x0 '-x 1' -x5 '-x 128 -n0' -k -k1 -k2 -k3 -k4 -k5 -k6 \
      '-k 3' -k5,4 -k5,4,6 -k5x,4x,6 -k4r,6 -k5r -rk5 '-r -k5x' -rk -r '-n0 -k1r,2' '-k5 -k4' '-n5 -k4' \
      -kr5 -k7 -k5n -k3x -k5,5 -k-1 '-k 7' '-x 129' '-n 9' -3 -q --nope ; do
    eq "function [$o]" "$(c $o -- t/*)" "$(b $o -- t/*)"
  done
  eq 'function stdin' "$(printf 't/a\n\nt/e' | c -n0)" "$(printf 't/a\n\nt/e' | b -n0)"
  eq 'function bare -n before a file' "$(c -n t/a)" "$(b -n t/a)"
  eq 'function -k before files' "$(c -k t/e t/a)" "$(b -k t/e t/a)"
  eq 'function wide values' "$(c -x0 -n0 -k4 w/*)" "$(b -x0 -n0 -k4 w/*)"
  eq 'function wide and negative mdate' "$(c -n3 -k5r w/*)" "$(b -n3 -k5r w/*)"
  eq 'function d/' "$(c -n5 t/d/ t/ld/)" "$(b -n5 t/d/ t/ld/)"
  eq 'function odd names' "$(c -k -- t/-kr 't/b\s' "$nm")" "$(b -k -- t/-kr 't/b\s' "$nm")"
  for o in -q '-k 7' '-n 9' --nope -kr5 -k5n -3 't/p t/dang' ; do
    eq "function diagnostics [$o]" "$(ce $o)" "$(be $o)"
  done
  [ -w /dev/full ] && { bash -c '. "$0" ; cksh --fn t/a' "$F" >/dev/full 2>/dev/null
    eq 'function stdout full 2' 2 $? ;} || sk '/dev/full (function)'
  printf n > $'t/n\nl'
  sort -z </dev/null >/dev/null 2>&1 &&
    eq 'function newline name under -k' "$(c -k $'t/n\nl' t/a)" "$(b -k $'t/n\nl' t/a)" ||
    eq 'function newline name under -k, no sort -z, is 2' rc=2 "$(b -k $'t/n\nl' | tail -1)"
  eq 'function newline name streams' "$(c -n5 $'t/n\nl')" "$(b -n5 $'t/n\nl')"
  [ -n "$ptyform" ] &&
    eq 'function terminal escapes' "$(pty "bash $D/p6.sh")" "$(pty "bash $D/p5.sh")" ||
    sk 'no pty through script(1): function terminal case'
  for o in '-Z -n5' '-Z -k' -rZ -Zk5r '-Z -x0 -n0 -k4r' ; do
    eq "function [$o]" "$(c $o -- t/* | od -c)" "$(b $o -- t/* | od -c)"
  done
  for o in '-L -n0' '-L -n5 -k' '-c c0.ck' '-c c2.ck -k5r' '-c cmix.ck' '-L -c cl.ck' '-c cl.ck' '-c bad.ck' '-c nope.ck' \
      '-c c0.ck k/a' -c -o '-o k k/a' '-o nodir/x k/a' '-n5 -x64 -c c0.ck' ; do
    eq "function [$o]" "$(c $o -- k/* t/l t/ld t/dang 2>/dev/null)" "$(b $o -- k/* t/l t/ld t/dang 2>/dev/null)"
  done
  touch -t 202201010000 k/e ; printf abd > k/a
  for o in '-c c0.ck' '-c c2.ck -k5r' '-c cx.ck' '-c c64.ck' '-Z -c cz.ck' ; do
    eq "function, changed [$o]" "$(c $o | od -c)" "$(b $o | od -c)"
  done
  eq 'function -c on standard input' "$(c -c - < c2.ck)" "$(b -c - < c2.ck)"
  mv k/d k/d.away ; eq 'function -c gone' "$(c -c c2.ck)" "$(b -c c2.ck)" ; mv k/d.away k/d
  eq 'function -o' "$("$B" -k -o fo1.ck "${kf[@]}" ; cat fo1.ck)" "$(b -k -o fo2.ck "${kf[@]}" >/dev/null ; cat fo2.ck)"
  chmod 604 fo2.ck ; b -k -o fo2.ck k/a >/dev/null
  eq 'function -o keeps the mode' 604 "$(perm fo2.ck)"
  eq 'function -o: a new file takes the umask' 640 "$( ( umask 027 ; b -o fo3.ck k/a >/dev/null ) ; perm fo3.ck)"
  cp fo2.ck fo2.sav
  eq 'function -o: a run that stops midway' "rc=1 same" "$(b -c bad.ck -o fo2.ck) $(cmp -s fo2.ck fo2.sav && echo same)"
  eq 'function -o: no temporary file is left' 0 "$(ls -A . k | grep -c '^\.cksh\.')"
  eq 'function -c -o onto the listing' "$(cp c2.ck fa.ck ; "$B" -c fa.ck -o fa.ck ; cat fa.ck)" "$(cp c2.ck fb.ck ; b -c fb.ck -o fb.ck >/dev/null ; cat fb.ck)"
  b -o /dev/null k/a >/dev/null ; eq 'function -o: a device is written through' yes "$([ -c /dev/null ] && echo yes)"
  [ -n "$ptyform" ] && {
    fh(){ pty "env PATH=$D/fmt/$1 PAGER=cat bash -c '. \"$F\" ; cksh --fn --help'" ;}
    eq 'function terminal --help: mandoc first' 'MANDOC -a' "$(fh m | head -1)"
    eq 'function terminal --help: nroff and the pager' 'NROFF -c -man' "$(fh n | head -1)"
    eq 'function terminal --help: the same source' "$(pty "env PATH=$D/fmt/m PAGER=cat '$B' --help")" "$(fh m)"
    eq 'function terminal --help: no formatter' "$("$B" --help)" "$(fh none)"
  } || sk 'no pty through script(1): function --help cases'
  eq 'function -Z stdin' "$(printf 't/a\0t/n\nl\0t/e' | c -Z -k | od -c)" "$(printf 't/a\0t/n\nl\0t/e' | b -Z -k | od -c)"

  # openssl without -xoflen: the 64 character default is cut, exact to -x64.
  # The stand-in refuses -xoflen and asks the real one for 32 bytes, since
  # a current openssl gives shake256 no default length of its own.
  mkdir -p shim/old shim/libre shim/lb/bin
  printf '#!/bin/sh\ncase " $* " in *" -xoflen "*) echo "shake256: Unknown option: -xoflen" >&2; exit 1;; esac\nexec "%s" "$@" -xoflen 32\n' "$ssl" > shim/old/openssl
  printf '#!/bin/sh\necho "Invalid command" >&2; exit 1\n' > shim/libre/openssl
  cp shim/libre/openssl shim/lb/bin/openssl ; chmod 755 shim/old/openssl shim/libre/openssl shim/lb/bin/openssl
  bo(){ local d=$1 ; shift ; ( PATH="$D/shim/$d:$PATH" ; LOCALBASE= ; b "$@" ) ;}
  for x in 1 5 6 64 ; do eq "openssl without -xoflen, -x$x" "$(c -x $x -n0 t/a t/e)" "$(bo old -x $x -n0 t/a t/e)" ; done
  eq 'openssl without -xoflen, -x65' rc=2 "$(bo old -x 65 t/a)"
  eq 'openssl without shake256' rc=2 "$(bo libre t/a)"
  eq 'openssl without shake256, -x0' "$(c -x0 t/a)" "$(bo libre -x0 t/a)"
  eq 'LOCALBASE openssl preferred' rc=2 "$( ( export LOCALBASE=$D/shim/lb ; b t/a ) )"
  # a host whose stat(1) form is not known: one status 2, not a 4 per file
  mkdir -p shim/os ; printf '#!/bin/sh\necho Plan9\n' > shim/os/uname ; chmod 755 shim/os/uname
  eq 'unknown platform is 2' rc=2 "$( ( PATH="$D/shim/os:$PATH" ; b t/a t/e ) )"
} || sk 'function parity (cksh.fn.bash or openssl shake256 missing)'

printf 'test-cksh.sh: %d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"
[ "$fail" -eq 0 ]
