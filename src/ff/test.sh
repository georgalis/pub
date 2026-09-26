#!/bin/sh
# test.sh --- regression suite for ff (C binary) and ff.fn.bash (translator)
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
#     one case per promised behavior, run via make test
#
# POSIX sh. Native find is the reference where ff keeps find semantics;
# bash parity cases skip when bash is absent; tty cases need script(1).

set -u
here=`pwd`
B="$here/ff"
F="$here/ff.fn.bash"
[ -x "$B" ] || { echo "test.sh: build ./ff first" >&2; exit 1; }
w=`mktemp -d "${TMPDIR:-/tmp}/ff-test.XXXXXX"` || exit 1
trap 'chmod -R u+rwx "$w" 2>/dev/null; rm -rf "$w/t" "$w/deep" "$w/del" "$w/race" "$w/o"* ; rmdir "$w" 2>/dev/null' 0 1 2 15
pass=0 fail=0 skip=0

ok () { pass=`expr $pass + 1`; }
no () { fail=`expr $fail + 1`; echo "FAIL: $*" >&2; }
sk () { skip=`expr $skip + 1`; echo "skip: $*" >&2; }
eq () { [ "$2" = "$3" ] && ok || { no "$1"; printf '  want: %s\n  got:  %s\n' "$2" "$3" >&2; }; }
# C binary: stdout, then rc on its own line
c () { "$B" "$@" 2>/dev/null; echo "rc=$?"; }
# bash translator, same contract
b () { bash -c '. "$0"; ff "$@"' "$F" "$@" 2>/dev/null; echo "rc=$?"; }
# sorted output, for comparison with native find where only the set matters
cs () { "$B" "$@" 2>/dev/null | LC_ALL=C sort; }
fs () { find "$@" 2>/dev/null | LC_ALL=C sort; }

have_bash=; command -v bash >/dev/null 2>&1 && have_bash=1
have_script=; script -qc true /dev/null >/dev/null 2>&1 && have_script=1
root=; [ "`id -u`" = 0 ] && root=1

# fixtures: regular, empty, symlinks, dirs, fifo, space, dotdir, newline, ESC
cd "$w" || exit 1
mkdir -p t/d/e t/.h t/emd
printf abc > t/a; : > t/em; ln -s a t/l; ln -s nope t/dang; ln -s d t/ld
printf x > 't/sp ace'; mkfifo t/p; printf q > t/d/e/f.c; printf qq > t/d/g.C
printf 1234 > t/d/big; chmod 755 t/d/big; chmod 600 t/em
nl='t/n
l'; printf n > "$nl"
esc=`printf 't/x\033[31my'`; printf e > "$esc"
touch -t 202001010000 t/a t/d/g.C; touch -t 202101010000 t/em
ln -s .. t/d/up
# names a, a-, a0, a/b: a bytewise path sort gives a a- a/b a0, the walk a a/b a- a0
mkdir -p t/d/s/a t/d/s/a0; printf z > t/d/s/a/b; printf z > t/d/s/a-
e1=`printf '\001'`; e2=`printf '\002'`

# --- find semantics kept: same node set as native find ---
for pair in \
  "t|t" "t -t f|t -type f" "t -t d|t -type d" "t -t l|t -type l" "t -t p|t -type p" \
  "t -t fl|t ( -type f -o -type l )" "t -n *.c|t -name *.c" "t -n *|t -name *" \
  "t -p */d/*|t -path */d/*" "t -e|t -empty" "t -l +1|t -links +1" \
  "t -k 755|t -perm 755" "t -k -u+x -t f|t -perm -u+x -type f" "t -k +111 -t f|t -perm /111 -type f" \
  "t -k 600|t -perm 600" "t -w t/a|t -newer t/a" "t -n .h -z -o -t f -f|t -name .h -prune -o -type f -print" \
  "t ( -n a -o -n em ) -t f|t ( -name a -o -name em ) -type f" "t ! -t d|t ! -type d" \
  "t -d 0|t -maxdepth 0" "t -d -2|t -maxdepth 1" "t -d +0|t -mindepth 1" "t -d 1|t -mindepth 1 -maxdepth 1" \
  "t -d +1 -d -3|t -mindepth 2 -maxdepth 2" "-L t -t d|-L t -type d" "-H t/ld|-H t/ld" "t/ld|t/ld" \
  "-D t|t -depth" "t -u `id -u`|t -uid `id -u`" "t -g `id -g`|t -gid `id -g`" \
  "t -u `id -un`|t -user `id -un`" "t -g `id -gn`|t -group `id -gn`" "/etc -d -2 -u root|/etc -maxdepth 1 -user root"
do
  ff_args=${pair%%|*}; find_args=${pair#*|}
  set -f
  eq "find [$ff_args]" "`fs $find_args`" "`cs $ff_args`"
  set +f
done
ino=`ls -id t/a | awk '{print $1}'`
eq "-i inode" "t/a" "`"$B" t -i $ino`"

# --- deliberate departures (--help DIFFERENCES) ---
eq "-r unanchored" "t/d/e t/d/e/f.c" "`cs t -r 'd/e' | tr '\n' ' ' | sed 's/ $//'`"
eq "-r anchored by ^\$" "t/d/e" "`"$B" t -r '^t/d/e$'`"
eq "-E ERE" "t/d/e/f.c t/d/g.C" "`cs -E t -r '\.(c|C)$' | tr '\n' ' ' | sed 's/ $//'`"
eq "BRE default: ( literal" "" "`"$B" t -r '\.(c|C)$'`"
eq "-I -n" "t/d/e/f.c t/d/g.C" "`cs -I t -n '*.c' | tr '\n' ' ' | sed 's/ $//'`"
eq "-I -r" "t/d/e/f.c t/d/g.C" "`cs -I t -r '\.c$' | tr '\n' ' ' | sed 's/ $//'`"
eq "options anywhere" "`cs -I t -n '*.c'`" "`cs t -n '*.c' -I`"
eq "-s bytes exact" "t/a" "`"$B" t -t f -s 3`"
eq "-s -1 empty" "t/em" "`"$B" t -t f -s -1`"
eq "-s +3" "t/d/big" "`"$B" t -t f -s +3`"
eq "-s 1k exact, no rounding" "" "`"$B" t -t f -s 1k`"
eq "-s -1k" 10 "`"$B" -0 t -t f -s -1k | tr -cd '\000' | wc -c | tr -d ' '`"
eq "-m +365 old" "t/a t/d/g.C t/em" "`cs t -t f -m +365 | tr '\n' ' ' | sed 's/ $//'`"
eq "-m -1h new" 0 "`cs t -t f -m -1h | grep -c -e '^t/a$' -e '^t/em$'`"
eq "-m -1h keeps new" "t/d/big" "`cs t -t f -m -1h -n big`"
eq "-m exact day" "" "`"$B" t -t f -m 1`"
eq "-m 0 today" "t/d/big" "`"$B" t -t f -m 0 -n big`"
eq "-f -q first only" 1 "`"$B" -0 t -t f -f -q | tr -cd '\000' | wc -c | tr -d ' '`"
eq "-q no implicit print" "" "`"$B" t -q`"
eq "-v cksh line" "`printf '%8x %2x . %8x %08x t/a' $ino 1 3 1577836800`" "`TZ=UTC0 "$B" t/a -v`"
eq "-v indicators" "t/d/ t/l@ t/p|" "`"$B" t/d t/l t/p -d 0 -v | awk '{print $6}' | tr '\n' ' ' | sed 's/ $//'`"
eq "-0 NUL" "`find t -name 'n*' -print0 | od -c`" "`"$B" -0 t -n 'n*' | od -c`"
eq "-0 with -f" "`find t -name 'n*' -print0 | od -c`" "`"$B" -0 t -n 'n*' -f | od -c`"

# --- walk order: -S bytewise per directory, / sorts lowest; -D post-order ---
exp=`find t/d 2>/dev/null | tr / '\001' | LC_ALL=C sort | tr '\001' /`
eq "-S sorted" "$exp" "`"$B" -S t/d 2>/dev/null`"
eq "-S a before a/b before a.c" "t/d/s/a t/d/s/a/b t/d/s/a-" "`"$B" -S t/d/s -d +0 | head -3 | tr '\n' ' ' | sed 's/ $//'`"
exp=`find t/d 2>/dev/null | tr / '\001' | sed "s/\$/$e2/" | LC_ALL=C sort | sed "s/$e2\$//" | tr '\001' /`
eq "-S -D post-order" "$exp" "`"$B" -SD t/d 2>/dev/null`"

# --- exec: -x in the node's directory with ./name, -j with the path ---
eq "-x ;" "./f.c" "`"$B" t -n f.c -x echo {} \;`"
eq "-j ;" "t/d/e/f.c" "`"$B" t -n f.c -j echo {} \;`"
eq "-x runs in node dir" "$w/t/d/e" "`"$B" t -n f.c -x pwd \;`"
eq "-x + same set as -j +" "`"$B" t -t f -j echo {} + | tr ' ' '\n' | sed 's,.*/,,' | LC_ALL=C sort`" \
  "`"$B" t -t f -x echo {} + | tr ' ' '\n' | sed 's,^\./,,' | LC_ALL=C sort`"
eq "-x + runs per dir" "`find t -type f ! -name 'n*' | sed 's,/[^/]*$,,' | LC_ALL=C sort -u | sed "s,^,$w/,"`" \
  "`"$B" t -t f ! -n 'n*' -x sh -c pwd sh {} + | LC_ALL=C sort -u`"
eq "-x + names exist there" "" "`"$B" t -t f -x sh -c 'for f; do [ -e "$f" ] || echo "$f"; done' sh {} +`"
eq "-x ; false is only false" "rc=0" "`c t -n a -x false \;`"
eq "-x ; as predicate" "t/a" "`"$B" t -t f -x test -s {} \; -n a -f`"
eq "-j + nonzero is 8" "rc=8" "`c t -n a -j false {} +`"
eq "cannot execute is 8" "rc=8" "`c t -n a -j /nonexistent/cmd {} \;`"
eq "operand -x" "./a" "`"$B" t/a -x echo {} \;`"
eq "no shell: words literal" 'x;$(id)' "`"$B" t/a -j printf '%s' 'x;$(id)' \;`"
eq "PATH . refused" "rc=2" "`PATH=.:$PATH c t -x ls \;`"
eq "PATH empty elt refused" "rc=2" "`PATH=$PATH: c t -x ls \;`"
eq "-j ignores PATH guard" "rc=0" "`PATH=.:$PATH c t/a -j true \; | tail -1`"
eq "-x absolute ok" "rc=0" "`PATH=.:$PATH c t/a -x /bin/sh -c : \; | tail -1`"

# --- -delete: post-order, through the parent descriptor ---
cp -R t del 2>/dev/null; rm -f del/p; mkfifo del/p
"$B" del -n '*.c' -delete; eq "-delete file" "" "`find del -name '*.c'`"
"$B" del/d -delete 2>/dev/null; eq "-delete tree" 1 "`[ -d del/d ] && echo 0 || echo 1`"
eq "-delete .. refused" "rc=4" "`c .. -d 0 -delete`"
eq "-delete -L refused" "rc=1" "`c -L del -delete`"
eq "-delete . skipped" 1 "`mkdir -p del/k; (cd del/k && "$B" . -delete); [ -d del/k ] && echo 1`"

# --- exit status bitmask ---
eq "rc ok" "rc=0" "`c t -n a | tail -1`"
eq "rc missing 4" "rc=4" "`c t/nope | tail -1`"
eq "rc missing, rest walked" "t/a" "`"$B" t/nope t/a 2>/dev/null`"
eq "rc -L loop 16" "rc=16" "`c -L t -n nothing | tail -1`"
eq "-L loop entry not tested" "" "`"$B" -L t -n up 2>/dev/null`"
eq "rc symlink loop 16" "rc=16" "`mkdir -p o.sl; ln -s x o.sl/x 2>/dev/null; c -L o.sl -n nothing | tail -1; rm -rf o.sl`"
if [ -z "$root" ]; then
  mkdir -p o.unr/in; chmod 000 o.unr
  eq "rc unreadable dir 4" "rc=4" "`c o.unr | tail -1`"
  eq "unreadable dir still listed" "o.unr" "`"$B" o.unr 2>/dev/null`"
  chmod 755 o.unr; rm -rf o.unr
else sk "unreadable dir (running as root)"; fi
if [ -w /dev/full ]; then
  "$B" t > /dev/full 2>/dev/null; eq "rc stdout full 2" 2 $?
else sk "/dev/full"; fi
# race: a directory swapped for a symlink after listing is refused, not followed
mkdir -p race/r/sub/in
eq "rc race 32" "rc=32" "`c race/r -n sub -j sh -c 'mv \"\$1\" \"\$1.x\" && ln -s /etc \"\$1\"' sh {} \; | tail -1`"
eq "race not followed" "" "`"$B" race/r -t f 2>/dev/null | grep -c passwd | grep -v '^0$'`"

# --- deep tree: more levels than descriptors, reopened by verified path ---
p=deep; i=0; while [ $i -lt 90 ]; do p=$p/x; i=`expr $i + 1`; done; mkdir -p $p; : > $p/leaf
eq "deep count" "`find deep | wc -l`" "`"$B" deep | wc -l`"
eq "deep -x reopen" "./leaf" "`"$B" deep -n leaf -x echo {} \;`"
eq "deep low fd limit" "`find deep | wc -l`" "`(ulimit -n 24; "$B" deep | wc -l)`"
eq "deep -e at bottom" "$p/leaf" "`(ulimit -n 24; "$B" deep -t f -e)`"

# --- terminal: control bytes escaped on a tty, raw to a pipe ---
if [ -n "$have_script" ]; then
  eq "tty escapes ESC" 't/x\033[31my' "`script -qc "'$B' t -n 'x*'" /dev/null | tr -d '\r'`"
  eq "tty escapes newline" 't/n\012l' "`script -qc "'$B' t -n 'n*'" /dev/null | tr -d '\r'`"
  eq "tty -0 raw" 1 "`script -qc "'$B' -0 t -n 'x*'" /dev/null | od -c | grep -c 033`"
else sk "tty escaping (no script)"; fi
eq "pipe raw ESC" "$esc" "`"$B" t -n 'x*'`"

# --- grammar: [options] [path ...] [expression] ---
for o in "-q t" "t -n" "t -t q" "t -t ''" "t -d x" "t -s 1q" "t -s 1kk" "t -m 1y" "t -k 999" \
    "t -k u+q" "t -u nosuchuser_ff" "t -g nosuchgroup_ff" "t -u -root" "t -u a:b" "t -u ''" "t -l x" "t -w t/nope" "t (" "t ( )" \
    "t )" "t -o -f" "t -n a -o" "t !" "t -r [" "t -x echo {}" "t -x {} ;" "t -x ;" \
    "t -x echo a{} ;" "t -j echo {} {} +" "t -x ./x ;" "t -y" "--nope" "t -n a b"
do
  set -f; eq "usage [$o]" "rc=1" "`c $o | tail -1`"; set +f
done
eq "-- path with dash" "-dash rc=0" "`mkdir -p o.dash/-dash; cd o.dash; c -- -dash | tr '\n' ' ' | sed 's/ $//'; cd ..; rm -rf o.dash`"
eq "default path ." "`cd t && find . | LC_ALL=C sort`" "`cd t && "$B" | LC_ALL=C sort`"

# --- help: -h short, --help manual, man page source ---
eq "-h rc" 0 "`$B -h >/dev/null; echo $?`"
eq "--help rc" 0 "`$B --help >/dev/null; echo $?`"
eq "--help sections" 14 "`$B --help | grep -c '^[A-Z][A-Z ]*$'`"

# --- diagnostics: chkerr (>>>) and chkwrn (^^^) format, hex tag naming the message ---
eq "err format" ">>> ff : cannot stat 't/nope': No such file or directory (6ab7ff32)" "`"$B" t/nope 2>&1 >/dev/null`"
eq "usage format" ">>> ff : -t: types are f d l p s b c 'q' (6ab7ff0a)" "`"$B" t -t q 2>&1 >/dev/null`"
eq "wrn format" 1 "`"$B" -L t -n nothing 2>&1 >/dev/null | grep -Fcx "^^^ ff : filesystem loop, skipped 't/d/up' (6ab7ff3a)"`"
eq "one line per usage error" 1 "`"$B" -y 2>&1 >/dev/null | wc -l | tr -d ' '`"

# --- bash translator parity: identical stdout and status on a pipe ---
if [ -n "$have_bash" ]; then
  for o in "t" "t -t f" "t -t fl" "t -n *.c" "t -p */d/*" "t -e" "t -s 3" "t -s -1k" "t -m +365" \
      "t -m -1h -t f" "t -k +111 -t f" "t -k 755" "t -n .h -z -o -t f -f" "t ( -n a -o -n em ) -t f" \
      "t -d -2" "t -d 1" "t -d +1 -d -3" "-D t" "-E t -r \.(c|C)$" "t -r d/e" "t -r ^t/d/e$" \
      "-I t -n *.C" "-I t -r \.c$" "t -n f.c -x echo {} ;" "t -n f.c -j echo {} ;" "-0 t -n n*" \
      "t -q" "t -f -q" "t/a t/em -v" "-S t/d" "-SD t/d" "t -w t/a" "t -l +1" "t/nope" \
      "-q t" "t -n" "t (" "t ( )" "t -o -f" "t -k 999" "t -x ./x ;" "-L t -delete" "t -u nosuchuser_ff"
  do
    set -f; eq "bash parity [$o]" "`c $o | od -c`" "`TZ=UTC0 b $o | od -c`"; set +f
  done
  # the native find reports failure as one bit: status parity only for success and usage
  eq "bash -L loop stdout" "`c -L t -t d | sed '$d'`" "`b -L t -t d | sed '$d'`"
  eq "bash -L loop status nonzero" 1 "`b -L t -t d | tail -1 | grep -vc '^rc=0$'`"
  # usage diagnostics are identical, message and tag
  for o in "-q t" "t -n" "t -t q" "t (" "t ( )" "t )" "t -o -f" "t !" "t -d x" "t -s 1q" "t -m 1y" \
      "t -k 999" "t -l x" "t -i x" "t -w t/nope" "t -u nosuchuser_ff" "t -g nosuchgroup_ff" "t -y" "t -n a b" \
      "t -x echo {}" "t -x {} ;" "t -x ;" "t -x echo a{} ;" "t -j echo {} {} +" "t -x ./x ;" "-L t -delete"
  do
    set -f; eq "bash diagnostics [$o]" "`"$B" $o 2>&1 >/dev/null`" "`bash -c '. "$0"; ff "$@"' "$F" $o 2>&1 >/dev/null`"; set +f
  done
  # namespace: only ff is defined in the caller's shell
  eq "bash namespace" "declare -f ff" "`bash -c '. "$0"; declare -F' "$F"`"
  eq "bash PATH guard" "rc=2" "`PATH=.:$PATH b t -x ls \;`"
  eq "bash + sets" "`"$B" t -t f -x echo {} + | tr ' ' '\n' | LC_ALL=C sort`" \
    "`bash -c '. "$0"; ff t -t f -x echo {} +' "$F" | tr ' ' '\n' | LC_ALL=C sort`"
  eq "bash -h" "`$B -h`" "`bash -c '. "$0"; ff -h' "$F"`"
  eq "bash --help" "`$B --help`" "`bash -c '. "$0"; ff --help' "$F"`"
  if [ -n "$have_script" ]; then
    eq "bash tty escapes" "`script -qc "'$B' t -n 'x*'" /dev/null`" \
      "`script -qc "bash -c '. $F; ff t -n x\*'" /dev/null`"
  fi
else sk "bash parity (no bash)"; fi

echo "test.sh: $pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ]
