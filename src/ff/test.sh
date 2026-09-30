#!/bin/sh
# test.sh --- regression suite for ff (C binary) and ff.fn.bash (translator)
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6abc5da8 20260929 175400 PDT Tue 05:54 PM 29 Sep 2026
#     -0 -1 (were -true -false), -Z (was -0), -y (was -same), -w sign apart;
#     physical work dir (Darwin /tmp is /private/tmp); bare -execdir names;
#     every behavior case runs twice, through the binary and the function;
#     native find differences probed per host (nd), never by uname
# rev 6abb42b9 20260928 214649 PDT Mon 09:46 PM 28 Sep 2026
#     -w when [+-]([.][.]/file|HEX), -same, -true -false, -i hex, -V, examples;
#     Darwin test fixes; ff.fn.bash -w reference files without -newermt
# rev 6ab89f43 20260926 214451 PDT Sat 09:44 PM 26 Sep 2026
#     -k permission query (at least/at most, has/lacks, X s t), -not, "not" diagnostics
# org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
#     one case per promised behavior, run via make test
#
# POSIX sh. Native find is the reference where ff keeps find semantics.
# cases() holds every behavior case and runs twice: RUN is the binary, then
# a wrapper loading ff.fn.bash in a clean bash. Cases only the binary can
# meet sit behind bo "reason", which skips them once per group in the bash
# pass and names why. The parity section then compares the two byte for
# byte. The bash pass and parity skip when bash is absent; tty cases need
# script(1).

set -u
# host independence: absolute PATH elements only (a relative or empty one makes -x
# refuse by design), UTC for touch -t fixtures and expected mdates
P=; oifs=$IFS; IFS=:; set -f
for d in $PATH; do case "$d" in /*) P="${P:+$P:}$d" ;; esac; done
IFS=$oifs; set +f; PATH=$P; TZ=UTC0; export PATH TZ
here=`pwd`
B="$here/ff"
F="$here/ff.fn.bash"
[ -x "$B" ] || { echo "test.sh: build ./ff first" >&2; exit 1; }
w=`mktemp -d "${TMPDIR:-/tmp}/ff-test.XXXXXX"` || exit 1
trap 'chmod -R u+rwx "$w" 2>/dev/null; rm -rf "$w/t" "$w/km" "$w/wt" "$w/deep" "$w/del" "$w/race" "$w/o"* ; rmdir "$w" 2>/dev/null' 0 1 2 15
pass=0 fail=0 skip=0 impl=
p0=0 f0=0 s0=0

ok () { pass=`expr $pass + 1`; }
no () { fail=`expr $fail + 1`; echo "FAIL: $*" >&2; }
sk () { skip=`expr $skip + 1`; echo "skip: $*" >&2; }
# a label names the implementation under test
eq () { [ "$2" = "$3" ] && ok || { no "${impl:+$impl: }$1"; printf '  want: %s\n  got:  %s\n' "$2" "$3" >&2; }; }
# a section's tally, then counters for the next
tally () { echo "test.sh: $1: `expr $pass - $p0` passed, `expr $fail - $f0` failed, `expr $skip - $s0` skipped"
  p0=$pass f0=$fail s0=$skip; }

# the implementation under test: RUN is ./ff, or the bash wrapper below
X () { "$RUN" "$@"; }
# stdout, then rc on its own line
r () { "$RUN" "$@" 2>/dev/null; echo "rc=$?"; }
# sorted output, for comparison with native find where only the set matters
cs () { "$RUN" "$@" 2>/dev/null | LC_ALL=C sort; }
fs () { find "$@" 2>/dev/null | LC_ALL=C sort; }
# binary-only group: true for ff; in the bash pass one named skip, false
bo () { [ "$impl" = ff ] && return 0; sk "$impl: binary only: $1"; return 1; }
# native difference: in the bash pass, when probe (the rest of the words) shows
# the host's find behaving otherwise than ff, one named skip, false; probes
# test behavior, never the platform name, so a host that changes runs the case
nd () { nd_=$1; shift; [ "$impl" = bash ] && "$@" >/dev/null 2>&1 && { sk "$impl: native find: $nd_"; return 1; }; return 0; }
# probes: each succeeds when the host's find differs from ff
pr_notempty () { mkdir -p o.pn/d; : > o.pn/d/f; find o.pn -name d -delete >/dev/null 2>&1; pr_=$?; rm -rf o.pn; [ $pr_ -eq 0 ]; }
pr_loop () { find -L t -name up 2>/dev/null | grep -q .; }
pr_unr () { ! find o.unr 2>/dev/null | grep -q .; }

# parity references: c the binary, b the function, same contract as r
c () { "$B" "$@" 2>/dev/null; echo "rc=$?"; }
# bash in a clean environment: no exported functions (such as a prior ff) leak in
be () { env -i PATH="$PATH" HOME="${HOME:-/}" TMPDIR="${TMPDIR:-/tmp}" TZ=UTC0 \
  FF_NO_SAMEFILE="${FF_NO_SAMEFILE:-}" FF_NO_NEWERMT="${FF_NO_NEWERMT:-}" \
  FF_BARE_EXECDIR="${FF_BARE_EXECDIR:-}" bash "$@"; }
b () { be -c '. "$0"; ff "$@"' "$F" "$@" 2>/dev/null; echo "rc=$?"; }

have_bash=; command -v bash >/dev/null 2>&1 && have_bash=1
# a pty for tty cases: util-linux script -qc CMD, or BSD script -q /dev/null CMD
have_script=; script -qc true /dev/null >/dev/null 2>&1 && have_script=u || {
  script -q /dev/null true >/dev/null 2>&1 && have_script=b; }
st () { if [ "$have_script" = u ]; then script -qc "$1" /dev/null; else script -q /dev/null sh -c "$1"; fi; }
root=; [ "`id -u`" = 0 ] && root=1

# fixtures: regular, empty, symlinks, dirs, fifo, space, dotdir, newline, ESC
cd "$w" || exit 1
# the physical path: -x pwd reports it, and Darwin's /tmp is a symlink to /private/tmp
w=`pwd -P`
# the function as a command, for RUN and for script(1); its path comes from
# the environment, so no name is written into the wrapper
FFT_FN=$F; export FFT_FN
cat > o.ffbash <<'eof'
#!/bin/sh
exec env -i PATH="$PATH" HOME="${HOME:-/}" TMPDIR="${TMPDIR:-/tmp}" TZ=UTC0 \
  FF_NO_SAMEFILE="${FF_NO_SAMEFILE:-}" FF_NO_NEWERMT="${FF_NO_NEWERMT:-}" \
  FF_BARE_EXECDIR="${FF_BARE_EXECDIR:-}" bash -c '. "$0"; ff "$@"' "$FFT_FN" "$@"
eof
chmod 755 o.ffbash
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
ino=`ls -id t/a | awk '{print $1}'`

# -k fixtures: setgid needs the file's group among the user's; where it still fails, drop f2755
mkdir -p km; for m in 0755 0644 0600 0666 4755 2755 0000; do
  : > km/f$m; chgrp "`id -g`" km/f$m 2>/dev/null; chmod $m km/f$m 2>/dev/null; done
nosgid=; [ -g km/f2755 ] || { rm -f km/f2755; nosgid=1; sk "setgid on km/f2755 (not permitted here)"; }
mkdir km/d1777 km/d0711 km/d0700; chmod 1777 km/d1777; chmod 0711 km/d0711; chmod 0700 km/d0700

# -w fixtures; R is the mdate of wt/ref as -v prints it
mkdir -p wt; printf a > wt/old; printf b > wt/ref; printf c > wt/new; printf x > wt/cafe; printf y > wt/-x
touch -t 202001010000.00 wt/old wt/-x; touch -t 202101010000.00 wt/ref; touch -t 202201010000.00 wt/new
touch -r wt/ref wt/same wt/cafe; ln wt/new wt/hard
R=`"$B" wt/ref -v | awk '{print $5}'`

# deep tree: more levels than descriptors
p=deep; i=0; while [ $i -lt 90 ]; do p=$p/x; i=`expr $i + 1`; done; mkdir -p $p; : > $p/leaf

cases () {
# --- find semantics kept: same node set as native find ---
for pair in \
  "t|t" "t -t f|t -type f" "t -t d|t -type d" "t -t l|t -type l" "t -t p|t -type p" \
  "t -t fl|t ( -type f -o -type l )" "t -n *.c|t -name *.c" "t -n *|t -name *" \
  "t -p */d/*|t -path */d/*" "t -e|t -empty" "t -l +1|t -links +1" \
  "t -k 755|t -perm 755" "t -k +755|t -perm -755" "t -k u+x -t f|t -perm -u+x -type f" "t -k 0|t -perm 0" \
  "t -k 600|t -perm 600" "t -w +./t/a|t -newer t/a" "t -w + ./t/a|t -newer t/a" "t -0|t -true" "t -1|t -false" "t -y t/a|t -samefile t/a" "t -n .h -z -o -t f -f|t -name .h -prune -o -type f -print" \
  "t ( -n a -o -n em ) -t f|t ( -name a -o -name em ) -type f" "t ! -t d|t ! -type d" \
  "t -d 0|t -maxdepth 0" "t -d -2|t -maxdepth 1" "t -d +0|t -mindepth 1" "t -d 1|t -mindepth 1 -maxdepth 1" \
  "t -d +1 -d -3|t -mindepth 2 -maxdepth 2" "-H t/ld|-H t/ld" "t/ld|t/ld" \
  "-D t|t -depth" "t -u `id -u`|t -uid `id -u`" "t -g `id -g`|t -gid `id -g`" \
  "t -u `id -un`|t -user `id -un`" "t -g `id -gn`|t -group `id -gn`" "/etc -d -2 -u root|/etc -maxdepth 1 -user root"
do
  ff_args=${pair%%|*}; find_args=${pair#*|}
  set -f
  eq "find [$ff_args]" "`fs $find_args`" "`cs $ff_args`"
  set +f
done
# a directory closing a -L loop (t/d/up): GNU find and ff skip it, BSD find tests it
eq "find [-L t -t d] less loop entries" "`fs -L t -type d | grep -v '/up$'`" "`cs -L t -t d | grep -v '/up$'`"
eq "-i inode, hex" "t/a" "`X t -i \`printf %x $ino\``"

# --- deliberate departures (--help DIFFERENCES) ---
eq "-r unanchored" "t/d/e t/d/e/f.c" "`cs t -r 'd/e' | tr '\n' ' ' | sed 's/ $//'`"
eq "-r anchored by ^\$" "t/d/e" "`X t -r '^t/d/e$'`"
eq "-E ERE" "t/d/e/f.c t/d/g.C" "`cs -E t -r '\.(c|C)$' | tr '\n' ' ' | sed 's/ $//'`"
# options are global: one after the primary it changes still applies (--help DESCRIPTION)
eq "-E after -r" "t/d/e/f.c t/d/g.C" "`cs t -r '\.(c|C)$' -E | tr '\n' ' ' | sed 's/ $//'`"
eq "-E after -r, alternation" "t/d/e/f.c t/d/g.C" "`cs t -r 'e/f|g\.C' -E | tr '\n' ' ' | sed 's/ $//'`"
eq "-I after -r" "t/d/e/f.c t/d/g.C" "`cs t -r '\.c$' -I | tr '\n' ' ' | sed 's/ $//'`"
eq "BRE default: ( literal" "" "`X t -r '\.(c|C)$'`"
eq "-I -n" "t/d/e/f.c t/d/g.C" "`cs -I t -n '*.c' | tr '\n' ' ' | sed 's/ $//'`"
eq "-I -r" "t/d/e/f.c t/d/g.C" "`cs -I t -r '\.c$' | tr '\n' ' ' | sed 's/ $//'`"
eq "options anywhere" "`cs -I t -n '*.c'`" "`cs t -n '*.c' -I`"
eq "-s bytes exact" "t/a" "`X t -t f -s 3`"
eq "-s -1 empty" "t/em" "`X t -t f -s -1`"
eq "-s +3" "t/d/big" "`X t -t f -s +3`"
eq "-s 1k exact, no rounding" "" "`X t -t f -s 1k`"
eq "-s -1k" 10 "`X -Z t -t f -s -1k | tr -cd '\000' | wc -c | tr -d ' '`"
eq "-m +365 old" "t/a t/d/g.C t/em" "`cs t -t f -m +365 | tr '\n' ' ' | sed 's/ $//'`"
eq "-m -1h new" 0 "`cs t -t f -m -1h | grep -c -e '^t/a$' -e '^t/em$'`"
eq "-m -1h keeps new" "t/d/big" "`cs t -t f -m -1h -n big`"
eq "-m exact day" "" "`X t -t f -m 1`"
eq "-m 0 today" "t/d/big" "`X t -t f -m 0 -n big`"
eq "-f -q first only" 1 "`X -Z t -t f -f -q | tr -cd '\000' | wc -c | tr -d ' '`"
eq "-q no implicit print" "" "`X t -q`"
eq "-v cksh line" "`printf '%8x %2x . %8x %08x t/a' $ino 1 3 1577836800`" "`TZ=UTC0 X t/a -v`"
eq "-v indicators" "t/d/ t/l@ t/p|" "`X t/d t/l t/p -d 0 -v | awk '{print $6}' | tr '\n' ' ' | sed 's/ $//'`"
eq "-Z NUL" "`find t -name 'n*' -print0 | od -c`" "`X -Z t -n 'n*' | od -c`"
eq "-Z with -f" "`find t -name 'n*' -print0 | od -c`" "`X -Z t -n 'n*' -f | od -c`"

# --- -k: octal exact, +superset, -subset; symbolic query, + has, - lacks (--help -k) ---
kq () { "$RUN" km -d 1 "$@" 2>/dev/null | sed 's,^km/,,' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'; }
for pair in \
  "0755|f0755" "+0755|d1777 f0755 f2755 f4755" "-0755|d0700 d0711 f0000 f0600 f0644 f0755" \
  "u+x|d0700 d0711 d1777 f0755 f2755 f4755" "x|d0700 d0711 d1777 f0755 f2755 f4755" \
  "-x|f0000 f0600 f0644 f0666" "o-X|d0700" "o-r|d0700 d0711 f0000 f0600" \
  "w|d0700 d0711 d1777 f0600 f0644 f0666 f0755 f2755 f4755" "o+w|d1777 f0666" \
  "go-w|d0700 d0711 f0000 f0600 f0644 f0755 f2755 f4755" "u+s|f4755" "g+s|f2755" \
  "+s|f2755 f4755" "+t|d1777" "u+rwx,u-s|d0700 d0711 d1777 f0755 f2755" "-7777|`ls km | tr '\n' ' ' | sed 's/ $//'`"
do
  exp=${pair#*|}; [ -n "$nosgid" ] && exp=`echo "$exp" | sed 's/ *f2755//; s/^ //'`
  eq "-k ${pair%%|*}" "$exp" "`kq -k "${pair%%|*}"`"
done
eq "-not -k go-w" "d1777 f0666" "`kq -not -k go-w`"
# no class: each class tested with the bits it can hold; o holds no s (--help -k)
eq "-k +rs through other" 1 "`kq -k +rs | tr ' ' '\n' | grep -cx f0644`"
eq "-k u+rs one class" "f4755" "`kq -k u+rs`"
eq "-not is !" "`kq ! -k go-w`" "`kq -not -k go-w`"
eq "-k u+r -o -k u+x" "`kq -k u+r`" "`kq -k u+r -o -k u+x`"
eq "-k X never a file" "" "`X km -t f -k X`"
for o in u=rwx o+s u+t g+t u+q u+ , x, 99 -8; do eq "-k reject [$o]" "rc=1" "`r km -k "$o" | tail -1`"; done
eq "-k s/t class tag" ">>> ff : -k: s is for u or g, t is for o, not 'o+s' (6ab7ff46)" "`X km -k o+s 2>&1`"

# --- -w when [+-][ ]([.][.]/file|HEX), -y, -0/-1, -i hex, -V (--help PRIMARIES) ---
wq () { "$RUN" wt -t f "$@" 2>/dev/null | sed 's,^wt/,,' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'; }
eq "-w +file after" "hard new" "`wq -w +./wt/ref`"
eq "-w -file before" "-x old" "`wq -w -./wt/ref`"
eq "-w file at" "cafe ref same" "`wq -w ./wt/ref`"
eq "-w ../file" "cafe ref same" "`cd wt && X . -t f -w ../wt/ref | sed 's,^\./,,' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'`"
eq "-w /file" "cafe ref same" "`wq -w $w/wt/ref`"
eq "-w bare word is an error" ">>> ff : -w: file is [.][.]/file, time is HEX, not 'wt/ref' (6ab7ff4b)" "`X wt -w wt/ref 2>&1`"
eq "-w +HEX after" "hard new" "`wq -w +$R`"
eq "-w -HEX before" "-x old" "`wq -w -$R`"
eq "-w HEX at" "cafe ref same" "`wq -w $R`"
eq "-w ./cafe is a file" "./cafe ./ref ./same" "`cd wt && X . -t f -w ./cafe | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'`"
eq "-w cafe is a time" "" "`wq -w cafe`"
eq "-w +./-x is a file" "./cafe ./hard ./new ./ref ./same" "`cd wt && X . -t f -w +./-x | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'`"
eq "-w HEX overflow" "rc=1" "`r wt -w 8000000000000000 | tail -1`"
# the sign may stand apart as its own word; the word after it takes no sign
eq "-w + file after" "hard new" "`wq -w + ./wt/ref`"
eq "-w - file before" "-x old" "`wq -w - ./wt/ref`"
eq "-w + HEX after" "hard new" "`wq -w + $R`"
eq "-w - HEX before" "-x old" "`wq -w - $R`"
eq "-w + ./-x is a file" "./cafe ./hard ./new ./ref ./same" "`cd wt && X . -t f -w + ./-x | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'`"
# [.][.]/file: exactly the prefixes / ./ ../
eq "-w + /file" "hard new" "`wq -w + $w/wt/ref`"
eq "-w - ../file" "./-x ./old" "`cd wt && X . -t f -w - ../wt/ref | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//'`"
eq "-w .../file is an error" "rc=1" "`r wt -w .../wt/ref | tail -1`"
eq "-w + at the end" "rc=1" "`r wt -w + | tail -1`"
eq "-w + then a sign" ">>> ff : -w: file is [.][.]/file, time is HEX, not '-./wt/ref' (6ab7ff4b)" "`X wt -w + -./wt/ref 2>&1`"
eq "-w + HEX overflow" ">>> ff : time overflows '8000000000000000' (6ab7ff0f)" "`X wt -w + 8000000000000000 2>&1`"
eq "-y hard links" "hard new" "`wq -y wt/new`"
eq "-i hex from -v" "hard new" "`wq -i \`X wt/new -v | awk '{print $1}'\``"
eq "-0 all" "`cs wt`" "`cs wt -0`"
eq "-1 none" "" "`cs wt -1`"
eq "-z -1 prune" "wt/-x wt/cafe wt/hard wt/new wt/old wt/ref wt/same" "`cs wt -n wt -1 -o -t f | tr '\n' ' ' | sed 's/ $//'`"
eq "-0 after -o" "`cs wt`" "`cs wt -1 -o -0`"
# -0 was NUL output: before a path it now starts the expression, and fails loudly
eq "-0 before a path" ">>> ff : unexpected word 'wt' (6ab7ff04)" "`X -0 wt 2>&1`"
eq "-true retired" "rc=1" "`r wt -true | tail -1`"
bo "-V note (ff.fn.bash prints the native command instead; see bash -V)" && {
  eq "-V binary note" "^^^ ff : -V: the native find command is printed by ff.fn.bash (6ab7ff47)" "`X -V wt -d 0 2>&1 >/dev/null`"; }
eq "-V walks" "wt rc=0" "`r -V wt -d 0 | tr '\n' ' ' | sed 's/ $//'`"
eq "prune example" "`cs t -t f ! -n '*,v' ! -n '*~'`" "`cs t \( -n .git -o -n tmp \) -z -t f -o -t f -not -E -r ',v$|~$'`"

# --- walk order: -S bytewise per directory, / sorts lowest; -D post-order ---
exp=`find t/d 2>/dev/null | tr / '\001' | LC_ALL=C sort | tr '\001' /`
eq "-S sorted" "$exp" "`X -S t/d 2>/dev/null`"
eq "-S a before a/b before a.c" "t/d/s/a t/d/s/a/b t/d/s/a-" "`X -S t/d/s -d +0 | head -3 | tr '\n' ' ' | sed 's/ $//'`"
exp=`find t/d 2>/dev/null | tr / '\001' | sed "s/\$/$e2/" | LC_ALL=C sort | sed "s/$e2\$//" | tr '\001' /`
eq "-S -D post-order" "$exp" "`X -SD t/d 2>/dev/null`"

# --- exec: -x in the node's directory with ./name, -j with the path ---
eq "-x ;" "./f.c" "`X t -n f.c -x echo {} \;`"
eq "-j ;" "t/d/e/f.c" "`X t -n f.c -j echo {} \;`"
eq "-x runs in node dir" "$w/t/d/e" "`X t -n f.c -x pwd \;`"
eq "-x + same set as -j +" "`X t -t f -j echo {} + | tr ' ' '\n' | sed 's,.*/,,' | LC_ALL=C sort`" \
  "`X t -t f -x echo {} + | tr ' ' '\n' | sed 's,^\./,,' | LC_ALL=C sort`"
eq "-x + runs per dir" "`find t -type f ! -name 'n*' | sed 's,/[^/]*$,,' | LC_ALL=C sort -u | sed "s,^,$w/,"`" \
  "`X t -t f ! -n 'n*' -x sh -c pwd sh {} + | LC_ALL=C sort -u`"
eq "-x + names exist there" "" "`X t -t f -x sh -c 'for f; do [ -e "$f" ] || echo "$f"; done' sh {} +`"
eq "-x ; false is only false" "rc=0" "`r t -n a -x false \;`"
eq "-x ; as predicate" "t/a" "`X t -t f -x test -s {} \; -n a -f`"
eq "operand -x" "./a" "`X t/a -x echo {} \;`"
eq "no shell: words literal" 'x;$(id)' "`X t/a -j printf '%s' 'x;$(id)' \;`"
eq "PATH . refused" "rc=2" "`PATH=.:$PATH r t -x ls \;`"
eq "PATH empty elt refused" "rc=2" "`PATH=$PATH: r t -x ls \;`"
eq "-j ignores PATH guard" "rc=0" "`PATH=.:$PATH r t/a -j true \; | tail -1`"
bo "status bits 8 and 16, and 2 for a full stdout (the native find reports any failure as 1, read as 4)" && {
  eq "-j + nonzero is 8" "rc=8" "`r t -n a -j false {} +`"
  eq "cannot execute is 8" "rc=8" "`r t -n a -j /nonexistent/cmd {} \;`"
  eq "rc -L loop 16" "rc=16" "`r -L t -n nothing | tail -1`"
  eq "rc symlink loop 16" "rc=16" "`mkdir -p o.sl; ln -s x o.sl/x 2>/dev/null; r -L o.sl -n nothing | tail -1; rm -rf o.sl`"
  if [ -w /dev/full ]; then
    X t > /dev/full 2>/dev/null; eq "rc stdout full 2" 2 $?
  else sk "/dev/full"; fi
}
bo "-x with an absolute command under a relative PATH (GNU find refuses -execdir whatever the command)" && {
  eq "-x absolute ok" "rc=0" "`PATH=.:$PATH r t/a -x /bin/sh -c : \; | tail -1`"; }

# --- -delete: post-order, through the parent descriptor ---
rm -rf del; cp -R t del 2>/dev/null; rm -f del/p; mkfifo del/p
X del -n '*.c' -delete; eq "-delete file" "" "`find del -name '*.c'`"
X del/d -delete 2>/dev/null; eq "-delete tree" 1 "`[ -d del/d ] && echo 0 || echo 1`"
# an operand ending in .., or the root directory by identity, is refused whole:
# not walked, status 4. Root cases carry -d 0, so a broken refusal could only
# try rmdir on /, which fails.
eq "-delete .. refused" "rc=4" "`r .. -d 0 -delete`"
rm -rf o.dd; mkdir -p o.dd/a/b; : > o.dd/a/f; : > o.dd/a/b/g
eq "-delete .. refused whole" "rc=4 o.dd/a/b/g o.dd/a/f" "`(cd o.dd/a/b && r .. -delete) | tr '\n' ' '; ls -d o.dd/a/b/g o.dd/a/f | tr '\n' ' ' | sed 's/ $//'`"
eq "-delete ../ refused whole" "rc=4 o.dd/a/b/g o.dd/a/f" "`(cd o.dd/a/b && r ../ -delete) | tr '\n' ' '; ls -d o.dd/a/b/g o.dd/a/f | tr '\n' ' ' | sed 's/ $//'`"
eq "-delete a/b/.. refused whole" "rc=4 o.dd/a/b/g o.dd/a/f" "`r o.dd/a/b/.. -delete | tr '\n' ' '; ls -d o.dd/a/b/g o.dd/a/f | tr '\n' ' ' | sed 's/ $//'`"
eq "-delete .. with others" "rc=4 o.dd/a/b/g" "`r o.dd/a/f o.dd/a/b/.. -delete | tr '\n' ' '; ls -d o.dd/a/b/g o.dd/a/f 2>/dev/null | tr '\n' ' ' | sed 's/ $//'`"
eq "-delete / refused" ">>> ff : refusing to delete '/' (6ab7ff37)" "`X / -d 0 -delete 2>&1 >/dev/null`"
eq "-delete / rc" "rc=4" "`r / -d 0 -delete`"
eq "-delete // refused" "rc=4" "`r // -d 0 -delete`"
eq "-delete /. refused" "rc=4" "`r /. -d 0 -delete`"
eq "-delete . from / refused" "rc=4" "`cd / && r . -d 0 -delete`"
rm -f o.rl; ln -s / o.rl
eq "-delete -H link to / refused" "rc=4 o.rl" "`r -H o.rl -d 0 -delete | tr '\n' ' '; ls -d o.rl`"
eq "-delete link to / is the link" "rc=0 gone" "`r o.rl -d 0 -delete | tr '\n' ' '; [ -h o.rl ] && echo kept || echo gone`"
rm -rf o.dd o.rl
nd "-delete ignores a directory that is not empty, status 0" pr_notempty && \
  eq "-delete not empty is 4" "rc=4" "`mkdir -p o.ne/d; : > o.ne/d/f; r o.ne -n d -delete; rm -rf o.ne`"
eq "-delete -L refused" "rc=1" "`r -L del -delete`"
eq "-delete . skipped" 1 "`mkdir -p del/k; (cd del/k && X . -delete); [ -d del/k ] && echo 1`"

# --- exit status bitmask ---
eq "rc ok" "rc=0" "`r t -n a | tail -1`"
eq "rc missing 4" "rc=4" "`r t/nope | tail -1`"
eq "rc missing, rest walked" "t/a" "`X t/nope t/a 2>/dev/null`"
nd "-L tests a directory that closes a loop" pr_loop && \
  eq "-L loop entry not tested" "" "`X -L t -n up 2>/dev/null`"
if [ -z "$root" ]; then
  mkdir -p o.unr/in; chmod 000 o.unr
  eq "rc unreadable dir 4" "rc=4" "`r o.unr | tail -1`"
  nd "an unreadable directory named as an operand is not tested" pr_unr && \
    eq "unreadable dir still listed" "o.unr" "`X o.unr 2>/dev/null`"
  chmod 755 o.unr; rm -rf o.unr
else sk "${impl:+$impl: }unreadable dir (running as root)"; fi
# race: a directory swapped for a symlink after listing is refused, not followed;
# the swap runs in both passes, the status bit that reports it only in the binary
rm -rf race; mkdir -p race/r/sub/in
sw=`r race/r -n sub -j sh -c 'mv "$1" "$1.x" && ln -s /etc "$1"' sh {} \; | tail -1`
bo "status bit 32 for a node changed during the walk (the native find walks)" && eq "rc race 32" "rc=32" "$sw"
eq "race not followed" "" "`X race/r -t f 2>/dev/null | grep -c passwd | grep -v '^0$'`"

# --- deep tree: more levels than descriptors, reopened by verified path ---
eq "deep count" "`find deep | wc -l`" "`X deep | wc -l`"
eq "deep -x reopen" "./leaf" "`X deep -n leaf -x echo {} \;`"
eq "deep low fd limit" "`find deep | wc -l`" "`(ulimit -n 24; X deep | wc -l)`"
eq "deep -e at bottom" "$p/leaf" "`(ulimit -n 24; X deep -t f -e)`"

# --- terminal: control bytes escaped on a tty, raw to a pipe ---
if [ -n "$have_script" ]; then
  eq "tty escapes ESC" 't/x\033[31my' "`st "'$RUN' t -n 'x*'" | tr -d '\r'`"
  eq "tty escapes newline" 't/n\012l' "`st "'$RUN' t -n 'n*'" | tr -d '\r'`"
  eq "tty -Z raw" 1 "`st "'$RUN' -Z t -n 'x*'" | od -c | grep -c 033`"
else sk "${impl:+$impl: }tty escaping (no script)"; fi
eq "pipe raw ESC" "$esc" "`X t -n 'x*'`"

# --- grammar: [options] [path ...] [expression] ---
for o in "-q t" "t -n" "t -t q" "t -t ''" "t -d x" "t -s 1q" "t -s 1kk" "t -m 1y" "t -k 999" \
    "t -k u+q" "t -u nosuchuser_ff" "t -g nosuchgroup_ff" "t -u -root" "t -u a:b" "t -u ''" "t -l x" "t -w t/nope" "t -w ./nope" "t (" "t ( )" \
    "t )" "t -o -f" "t -n a -o" "t !" "t -r [" "t -x echo {}" "t -x {} ;" "t -x ;" \
    "t -x echo a{} ;" "t -j echo {} {} +" "t -x ./x ;" "t -y" "t -yy" "t -true" "-0 t" "t -w +" "t -w + -./t/a" "--nope" "t -n a b"
do
  set -f; eq "usage [$o]" "rc=1" "`r $o | tail -1`"; set +f
done
bo "a path operand beginning with - (the native find would read it as a primary; exits 2)" && {
  eq "-- path with dash" "-dash rc=0" "`mkdir -p o.dash/-dash; cd o.dash; r -- -dash | tr '\n' ' ' | sed 's/ $//'; cd ..; rm -rf o.dash`"; }
eq "default path ." "`cd t && find . | LC_ALL=C sort`" "`cd t && X | LC_ALL=C sort`"

# --- help: -h short, --help manual, man page source ---
eq "-h rc" 0 "`X -h >/dev/null; echo $?`"
eq "--help rc" 0 "`X --help >/dev/null; echo $?`"
eq "--help sections" 14 "`X --help | grep -c '^[A-Z][A-Z ]*$'`"

# --- diagnostics: chkerr (>>>) and chkwrn (^^^) format, hex tag naming the message ---
eq "usage format" ">>> ff : -t: types are f d l p s b c, not 'q' (6ab7ff0a)" "`X t -t q 2>&1 >/dev/null`"
eq "one line per usage error" 1 "`X -y 2>&1 >/dev/null | wc -l | tr -d ' '`"
bo "walk diagnostics in chkerr form (the native find writes its own)" && {
  eq "err format" ">>> ff : cannot stat 't/nope': No such file or directory (6ab7ff32)" "`X t/nope 2>&1 >/dev/null`"
  eq "wrn format" 1 "`X -L t -n nothing 2>&1 >/dev/null | grep -Fcx "^^^ ff : filesystem loop, skipped 't/d/up' (6ab7ff3a)"`"
}
}

# --- the binary ---
impl=ff RUN=$B; cases; tally ff

# --- the function, the same cases ---
if [ -n "$have_bash" ]; then
  impl=bash RUN=$w/o.ffbash; cases
else sk "ff.fn.bash cases (no bash)"; fi
tally ff.fn.bash

# --- bash translator parity: identical stdout and status on a pipe ---
impl=parity
if [ -n "$have_bash" ]; then
  for o in "t" "t -t f" "t -t fl" "t -n *.c" "t -p */d/*" "t -e" "t -s 3" "t -s -1k" "t -m +365" \
      "t -m -1h -t f" "t -k +755" "t -k 755" "km -k -0755" "km -k x" "km -k -x" "km -k o-X" \
      "km -k go-w" "km -not -k go-w" "km -k +s" "km -k +t" "km -k u+rwx,u-s" "km -k w" "km -k -7777" "km -k u+r -o -k u+x" "km -k +rs" "km -k u+rs" \
      "t -n .h -z -o -t f -f" "t ( -n a -o -n em ) -t f" \
      "t -d -2" "t -d 1" "t -d +1 -d -3" "-D t" "-E t -r \.(c|C)$" "t -r d/e" "t -r ^t/d/e$" \
      "-I t -n *.C" "-I t -r \.c$" "t -n f.c -x echo {} ;" "t -n f.c -j echo {} ;" "-Z t -n n*" \
      "t -q" "t -f -q" "t/a t/em -v" "-S t/d" "-SD t/d" "t -w +./t/a" "t -l +1" "t/nope" \
      "wt -t f -w +./wt/ref" "wt -t f -w -./wt/ref" "wt -t f -w ./wt/ref" "wt -t f -w +$R" "wt -t f -w -$R" "wt -t f -w $R" \
      "wt -t f -w + ./wt/ref" "wt -t f -w - $R" "wt -t f -w - $w/wt/ref" "wt -w .../wt/ref" \
      "wt -y wt/new" "wt -0" "wt -1" "wt -n wt -1 -o -t f" "wt -i 0" "t/a -x echo {} ;" "t -n f.c -x echo a {} b ;" \
      "-q t" "t -n" "t (" "t ( )" "t -o -f" "t -k 999" "t -x ./x ;" "-L t -delete" "t -u nosuchuser_ff"
  do
    set -f; eq "bash parity [$o]" "`c $o | od -c`" "`TZ=UTC0 b $o | od -c`"; set +f
  done
  # the native find reports failure as one bit: status parity only for success and usage
  eq "bash -L loop stdout" "`c -L t -t d | sed '$d' | grep -v '/up$'`" "`b -L t -t d | sed '$d' | grep -v '/up$'`"
  if ! find -L t >/dev/null 2>&1; then
    eq "bash -L loop status nonzero" 1 "`b -L t -t d | tail -1 | grep -vc '^rc=0$'`"
  else sk "bash -L loop status (native find does not report the loop)"; fi
  # usage diagnostics are identical, message and tag
  for o in "-q t" "t -n" "t -t q" "t (" "t ( )" "t )" "t -o -f" "t !" "t -d x" "t -s 1q" "t -m 1y" \
      "t -k 999" "t -k u=rwx" "t -k o+s" "t -k u+t" "t -l x" "t -i x" "t -i 12g" "t -y nope" "t -w ./nope" "t -w -nope" "t -w cafe/x" "t -a 1y" "t -b x" "t -x {} ;" "t -w t/nope" "t -u nosuchuser_ff" "t -g nosuchgroup_ff" "t -y" "t -yy" "t -true" "-0 t" "t -w +" "t -w + -./wt/ref" "t -w - cafe/x" "t -w + 8000000000000000" "t -w .../x" "t -n a b" \
      "t -x echo {}" "t -x {} ;" "t -x ;" "t -x echo a{} ;" "t -j echo {} {} +" "t -x ./x ;" "-L t -delete" \
      "/ -d 0 -delete" ".. -d 0 -delete" "/. -d 0 -delete"
  do
    set -f; eq "bash diagnostics [$o]" "`"$B" $o 2>&1 >/dev/null`" "`be -c '. "$0"; ff "$@"' "$F" $o 2>&1 >/dev/null`"; set +f
  done
  # a bad -r is the same usage error; only the binary adds the regcomp reason
  eq "bash -r bad regex" "`"$B" t -r '[' 2>&1 >/dev/null | sed "s/': .* (/' (/"`" \
    "`be -c '. "$0"; ff t -r "[" -E' "$F" 2>&1 >/dev/null`"
  eq "bash -y inum fallback" "`c wt -y wt/new | sort`" "`FF_NO_SAMEFILE=1 b wt -y wt/new | sort`"
  eq "bash -V stderr" "find wt -maxdepth 0 -print" "`be -c '. "$0"; ff -V wt -d 0' "$F" 2>&1 >/dev/null`"
  eq "bash -V stdout unchanged" "`c wt -t f -w +./wt/ref`" "`b -V wt -t f -w +./wt/ref 2>/dev/null`"
  # reference-file path, as on finds without -newermt @ (Darwin)
  for o in "+./wt/ref" "+ ./wt/ref" "- $R" "-./wt/ref" "./wt/ref" "+$R" "-$R" "$R"; do
    eq "bash -w refs [$o]" "`c wt -t f -w $o`" "`FF_NO_NEWERMT=1 b wt -t f -w $o`"
  done
  eq "bash -w refs removed" "" "`FF_NO_NEWERMT=1 be -c '. "$0"; ff -V wt -w +$1 2>&1 >/dev/null | sed -n "s/^# reference files under \(.*\) are removed.*/\1/p" | while read d; do ls -d "$d" 2>/dev/null; done' "$F" $R`"
  # namespace: only ff is defined in the caller's shell
  eq "bash namespace" "declare -f ff" "`be -c '. "$0"; declare -F' "$F"`"
  eq "bash + sets" "`"$B" t -t f -x echo {} + | tr ' ' '\n' | LC_ALL=C sort`" \
    "`be -c '. "$0"; ff t -t f -x echo {} +' "$F" | tr ' ' '\n' | LC_ALL=C sort`"
  # BSD -execdir passes a bare name, and ff.fn.bash adds ./ through a fixed
  # /bin/sh; FF_BARE_EXECDIR forces that path on GNU, where ./name stays as is
  for o in "t -n f.c -x echo {} ;" "t -n f.c -x echo a {} b ;" "t/a -x echo {} ;" \
      "t -n a -x false ;" "t -t f -x test -s {} ; -n a -f" "t -n a -x echo {} +"; do
    set -f; eq "bash bare execdir [$o]" "`c $o | od -c`" "`FF_BARE_EXECDIR=1 b $o | od -c`"; set +f
  done
  eq "bash bare execdir + sets" "`"$B" t -t f -x echo {} + | tr ' ' '\n' | LC_ALL=C sort`" \
    "`FF_BARE_EXECDIR=1 be -c '. "$0"; ff t -t f -x echo {} +' "$F" | tr ' ' '\n' | LC_ALL=C sort`"
  eq "bash bare execdir -V" 1 "`FF_BARE_EXECDIR=1 be -c '. "$0"; ff -V t -n f.c -x echo {} \;' "$F" 2>&1 >/dev/null | grep -c '^find t .*-execdir /bin/sh -c '`"
  eq "bash -h" "`$B -h`" "`be -c '. "$0"; ff -h' "$F"`"
  eq "bash --help" "`$B --help`" "`be -c '. "$0"; ff --help' "$F"`"
  if [ -n "$have_script" ]; then
    eq "bash tty escapes" "`st "'$B' t -n 'x*'"`" "`st "'$w/o.ffbash' t -n 'x*'"`"
  fi
else sk "bash parity (no bash)"; fi
tally parity

echo "test.sh: $pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ]
