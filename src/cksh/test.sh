#!/bin/sh
# test.sh --- regression suite for cksh (C binary) and cksh.fn.bash (bash function)
# (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6ab7e734 20260926 083932 PDT Sat 08:39 AM 26 Sep 2026
#     one case per promised behavior, run via make test
# rev 68e9ff40 20251010 235456 PDT Fri 11:54 PM 10 Oct 2025
#     -0..-5, bare -n and -x (getopts :), -n and -x range validation
# rev 68e20bca 20251004 231018 PDT Sat 11:10 PM 04 Oct 2025
#     renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired
# rev 677c9c44 20250106 191516 PST Mon 07:15 PM 06 Jan 2025
#     chksthash, from ckstatsum: shake256 -xoflen 3 hash column
# org 6305e87b 20220824 015939 PDT Wed 01:59 AM 24 Aug 2022 ckstat ckstatsum cks
#
# POSIX sh; bash parity and openssl cases skip when bash or openssl shake256 is absent.

set -u
here=`pwd`
B="$here/cksh"
F="$here/cksh.fn.bash"
[ -x "$B" ] || { echo "test.sh: build ./cksh first" >&2; exit 1; }
w=`mktemp -d "${TMPDIR:-/tmp}/cksh-test.XXXXXX"` || exit 1
trap 'rm -rf "$w/t" "$w/w" "$w/shim" "$w"/o* ; rmdir "$w" 2>/dev/null' 0 1 2 15
pass=0 fail=0 skip=0

ok () { pass=`expr $pass + 1`; }
no () { fail=`expr $fail + 1`; echo "FAIL: $*" >&2; }
sk () { skip=`expr $skip + 1`; echo "skip: $*" >&2; }
eq () { [ "$2" = "$3" ] && ok || { no "$1"; printf '  want: %s\n  got:  %s\n' "$2" "$3" >&2; }; }
# C binary: stdout, then rc on its own line
c () { "$B" "$@" 2>/dev/null; echo "rc=$?"; }
# bash function, same contract
b () { bash -c '. "$0"; cksh "$@"' "$F" "$@" 2>/dev/null; echo "rc=$?"; }

have_bash=; command -v bash >/dev/null 2>&1 && have_bash=1
have_ssl=; ssl=`command -v openssl 2>/dev/null`
[ -n "$ssl" ] && [ "`printf '' | openssl shake256 -xoflen 4 -hex 2>/dev/null | awk '{print $2}'`" = 46b9dd2b ] && have_ssl=1

# fixtures: regular, empty, symlink, dir, dangling, fifo, space, dash, symlink to dir
cd "$w" || exit 1
mkdir -p t/d
printf abc > t/a; : > t/e; ln -s a t/l; ln -s nope t/dang; ln -s d t/ld
printf x > 't/sp ace'; printf q > t/-kr; printf 5 > t/5; mkfifo t/p
touch -t 202001010000 t/a; touch -t 202101010000 t/e; touch -t 201901010000 't/sp ace'

# --- SHAKE256 (FIPS 202 vectors; XOF prefix property) ---
nist_e=46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762fd75dc4ddd8c0f200cb05019d67b592f6fc821c49479ab48640292eacb3b7c4be
nist_a=483366601360a8771c6863080cc4114d8db44530f8f1e1ee4f94ea37e78b5739d5a15bef186a5386c75744c0527e1faa9f8726e462a12a4feb06bd8801e751e4
eq "nist empty 64" $nist_e "`$B -x64 t/e | awk '{print $3}'`"
eq "nist abc 64" $nist_a "`$B -x64 t/a | awk '{print $3}'`"
# -x 3 is the 3 byte prefix of the 64 byte digest (manual HASH section)
eq "xof prefix" `echo $nist_a | cut -c1-6` "`$B t/a | awk '{print $3}'`"
# rate boundary: 135, 136, 137, 272 bytes and a multi-read file vs openssl
if [ -n "$have_ssl" ]; then
  for n in 135 136 137 272 200000; do
    dd if=/dev/urandom of=o$n bs=$n count=1 2>/dev/null
    for x in 1 7 32 33 64; do
      eq "openssl $n x$x" "`openssl shake256 -xoflen $x -hex < o$n | awk '{print $2}'`" \
        "`$B -x $x o$n | awk '{print $3}'`"
    done
  done
else sk "openssl -xoflen cross-check"; fi

# --- output format (aligned hex columns; dir and fifo hash zero filled) ---
eq "dir zeros" "000000" "`$B t/d | awk '{print $3}'`"
eq "fifo zeros" "000000" "`$B t/p 2>/dev/null | awk '{print $3}'`"
eq "indicators" "t/d/ t/l@ t/p| t/-kr" "`$B -5 -- t/d t/l t/p t/-kr | awk '{printf "%s ", $6}' | sed 's/ $//'`"
eq "space name" ". . . . . t/sp ace" "`$B -5 't/sp ace'`"
eq "-x0 dot" "." "`$B -x0 t/a | awk '{print $3}'`"
eq "-3 omits hash" ". . . " "`$B -3 t/a | cut -c1-6`"
eq "-n0 fields" 6 "`$B -n0 t/a | awk '{print NF}'`"

# --- exit status bitmask ---
eq "rc ok" "rc=0" "`c t/a t/d | tail -1`"
eq "rc missing 4" "rc=4" "`c t/nope | tail -1`"
eq "rc fifo 16" "rc=16" "`c t/p | tail -1`"
eq "rc dangling 32" "rc=32" "`c t/dang | tail -1`"
eq "rc combined 52" "rc=52" "`c t/nope t/p t/dang t/a | tail -1`"
eq "missing skipped, rest printed" 3 "`c t/nope t/p t/dang t/a | grep -vc rc=`"
eq "-x0 no fifo warning" "rc=0" "`c -x0 t/p t/dang | tail -1`"
# diagnostics: chkerr and chkwrn format with hex tag
eq "err format" ">>> cksh : cannot stat 't/nope'" "`$B t/nope 2>&1 >/dev/null | sed -n 's/^\(>>> cksh : cannot stat .t.nope.\).* (6ab75465)$/\1/p'`"
eq "wrn format" "^^^ cksh : fifo, not hashed 't/p' (6ab75468)" "`$B t/p 2>&1 >/dev/null`"
if [ "`id -u`" != 0 ]; then
  printf s > t/unr; chmod 000 t/unr
  eq "rc unreadable 8" "rc=8" "`c t/unr | tail -1`"
  eq "unreadable skipped" 1 "`c t/unr | wc -l | tr -d ' '`"
  chmod 600 t/unr; rm -f t/unr
else sk "unreadable (running as root)"; fi
if [ -w /dev/full ]; then
  "$B" t/a > /dev/full 2>/dev/null; eq "rc stdout full 2" 2 $?
else sk "/dev/full"; fi

# fifo is never opened: with no writer a blocking open would hang
( "$B" t/p > o.fifo 2>&1; echo $? > o.fiforc ) & pid=$!
i=0; while kill -0 $pid 2>/dev/null && [ $i -lt 5 ]; do sleep 1; i=`expr $i + 1`; done
kill -0 $pid 2>/dev/null && { kill $pid; no "fifo hang"; } || ok

# --- argument grammar: [-k|-rk|-kr][ ][N] ---
eq "usage bad -k r" "rc=1" "`c -k r t/a`"
eq "usage bad -k5r" "rc=1" "`c -k5r t/a`"
eq "usage bad -k 7" "rc=1" "`c -k 7 t/a`"
eq "usage bad -k0" "rc=1" "`c -k0 t/a`"
eq "usage bad -rkr" "rc=1" "`c -rkr t/a`"
eq "usage bad -x 65" "rc=1" "`c -x 65 t/a`"
eq "usage bad -n abc" "rc=1" "`c -n abc t/a`"
eq "usage bad -n 6" "rc=1" "`c -n 6 t/a`"
eq "usage bad -q" "rc=1" "`c -q t/a`"
eq "usage bad --nope" "rc=1" "`c --nope t/a`"
f="t/a t/e t/d t/sp?ace"
r5=`c -r -k5 $f`
for o in -rk5 "-rk 5" -kr5 "-kr 5"; do eq "form $o" "$r5" "`c $o $f`"; done
r6=`c -r -k6 $f`
for o in -rk -kr "-r -k"; do eq "form $o" "$r6" "`c $o $f`"; done
eq "bare -k is 6" "`c -k6 $f`" "`c -k $f`"
eq "-k before files" "`c -k6 t/e t/a`" "`c -k t/e t/a`"
cd t; eq "-k -- file 5" ". . `$B -x3 5 | awk '{print $3}'`" "`$B -k -- 5 | awk '{print $1, $2, $3}'`"; cd ..

# --- sort == LC_ALL=C sort [-r] -k N; -r alone reverses input ---
for k in 1 2 3 4 5 6; do
  eq "sort -k$k" "`$B -n0 $f | LC_ALL=C sort -k $k`" "`$B -n0 -k$k $f`"
  eq "sort -rk$k" "`$B -n0 $f | LC_ALL=C sort -r -k $k`" "`$B -n0 -rk$k $f`"
done
eq "-r reverse input" "`$B $f | awk '{a[NR]=$0} END{for(i=NR;i>0;i--)print a[i]}'`" "`$B -r $f`"
eq "-k5 by date" "t/sp ace t/a t/e" "`$B -k5 t/e t/a 't/sp ace' | awk '{print substr($0, index($0,$6))}' | tr '\n' ' ' | sed 's/ $//'`"

# wide values: a value wider than its column offsets only its line and still
# sorts by value (4 GiB after 4 GiB - 1; mdate 1960 < now < 2200)
mkdir -p w
truncate -s 4294967296 w/big 2>/dev/null || dd if=/dev/null of=w/big bs=1 seek=4294967296 2>/dev/null
truncate -s 4294967295 w/bigm 2>/dev/null || dd if=/dev/null of=w/bigm bs=1 seek=4294967295 2>/dev/null
printf s > w/small
eq "wide size -k4" "w/small w/bigm w/big" "`$B -3 -k4 w/big w/small w/bigm | awk '{printf "%s ", $6}' | sed 's/ $//'`"
eq "wide size -rk4" "w/big w/bigm w/small" "`$B -3 -rk4 w/big w/small w/bigm | awk '{printf "%s ", $6}' | sed 's/ $//'`"
if touch -t 220001010000 w/future 2>/dev/null && touch -t 196001010000 w/past 2>/dev/null; then
  eq "wide mdate -k5" "w/past w/small w/future" "`$B -3 -k5 w/future w/small w/past | awk '{printf "%s ", $6}' | sed 's/ $//'`"
  eq "wide mdate column" 9 "`$B -3 w/future | awk '{print length($5)}'`"
else sk "mdate outside 1970-2106 unsupported here"; fi

# --- stdin list: same as args; empty lines ignored; final line without newline ---
eq "stdin" "`c t/a t/e`" "`printf 't/a\n\nt/e' | c`"

# --- help: -h short, --help manual, C and bash identical ---
eq "-h rc" 0 "`$B -h >/dev/null; echo $?`"
eq "--help rc" 0 "`$B --help >/dev/null; echo $?`"
eq "--help sections" 11 "`$B --help | grep -c '^[A-Z][A-Z ]*$'`"

# --- bash function parity: byte-identical output and status ---
if [ -n "$have_bash" ] && [ -n "$have_ssl" ]; then
  for o in "" -n0 -n1 -n2 -3 -4 -5 -x0 "-x 1" "-x 64 -n0" -k1 -k2 -k3 -k4 -k5 -k6 \
      "-k 3" -rk5 "-rk 5" -kr "-kr 2" -kr5 -r -k -rk "-k r" -k5r "-k 7" "-x 65" --nope; do
    eq "bash parity [$o]" "`c $o t/*`" "`b $o t/*`"
  done
  eq "bash parity stdin" "`printf 't/a\n\nt/e' | c -n0`" "`printf 't/a\n\nt/e' | b -n0`"
  eq "bash -k before files" "`c -k t/e t/a`" "`b -k t/e t/a`"
  eq "bash -h" "`$B -h`" "`bash -c '. "$0"; cksh -h' "$F"`"
  eq "bash --help" "`$B --help`" "`bash -c '. "$0"; cksh --help' "$F"`"
  eq "bash wide values" "`c -x0 -n0 -k4 w/*`" "`b -x0 -n0 -k4 w/*`"
  eq "bash wide mdate" "`c -3 -rk5 w/*`" "`b -3 -rk5 w/*`"
  for o in -q "-k 7" "-n abc" --nope "t/p t/dang"; do
    eq "bash diagnostics [$o]" "`$B $o 2>&1 >/dev/null`" "`bash -c '. "$0"; cksh "$@"' "$F" $o 2>&1 >/dev/null`"
  done
  # namespace: only cksh is defined in the caller's shell
  eq "bash namespace" "declare -f cksh" "`bash -c '. "$0"; declare -F' "$F"`"

  # openssl < 3 (no -xoflen): 32 byte default digest truncated, exact for x <= 32
  mkdir -p shim/old shim/libre
  printf '#!/bin/sh\ncase " $* " in *" -xoflen "*) echo "shake256: Unknown option: -xoflen" >&2; exit 1;; esac\nexec "%s" "$@"\n' "$ssl" > shim/old/openssl
  printf '#!/bin/sh\necho "Invalid command '\''$1'\''" >&2; exit 1\n' > shim/libre/openssl
  chmod 755 shim/old/openssl shim/libre/openssl
  bo () { PATH="$w/shim/$1:$PATH"; shift; LOCALBASE= b "$@"; }
  for x in 1 3 32; do eq "old openssl x$x" "`c -x $x -n0 t/*`" "`( bo old -x $x -n0 t/* )`"; done
  eq "old openssl x40" "rc=2" "`( bo old -x 40 t/a )`"
  eq "libressl" "rc=2" "`( bo libre t/a )`"
  eq "libressl -x0" "`c -x0 t/a`" "`( bo libre -x0 t/a )`"
  # pkgsrc openssl preferred over PATH
  mkdir -p shim/lb/bin; cp shim/libre/openssl shim/lb/bin/openssl
  eq "LOCALBASE preferred" "rc=2" "`( LOCALBASE=$w/shim/lb; export LOCALBASE; b t/a )`"
else sk "bash parity (bash or openssl shake256 missing)"; fi

echo "test.sh: $pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ]
