#!/usr/bin/env bash
# test-rrcs.sh --- test suite for rrcs.fn.bash
# (c) 2024-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6ae1747d 20261027 210517 PDT Tue 09:05 PM 27 Oct 2026
#     initial release
# org 668d8a0d 20240709 120549 PDT Tue 12:05 PM 09 Jul 2024 _rcs in sub/fn.bash
#     https://github.com/georgalis/pub/commit/73f56ac9fe309ab6aac250d78079ab9bba2e9531
#
# usage: bash test-rrcs.sh [path/rrcs.fn.bash]      the ci first on PATH, or the emulation when none
#        RRCS_EMULATE=1 bash test-rrcs.sh           force the emulation even where RCS is installed
#        RCSBIN=/opt/pkg/bin bash test-rrcs.sh      put a specific RCS build first on PATH
# Works in a private mktemp directory, removed on success, kept for inspection on failure.
set -u
[ -z "${RCSBIN:-}" ] || PATH="$RCSBIN:$PATH"
h=. ; [[ $0 == */* ]] && h=${0%/*} ; fn=${1:-$(cd "$h" && pwd)/rrcs.fn.bash} ; [[ $fn == /* ]] || fn=$PWD/$fn ; [ -f "$fn" ] || { echo ">>> no $fn" >&2 ; exit 2 ;}
. "$fn" || exit 2
read -r d < <(mktemp -d "${TMPDIR:-/tmp}/test-rrcs.XXXXXX") || exit 2
cd "$d" || exit 2
pass=0 fails=0
ok () { pass=$((pass + 1)) ; printf 'PASS %s\n' "$*" ;}
no () { fails=$((fails + 1)) ; printf 'FAIL %s\n' "$*" ;}
t () { local name=$1 ; shift ; "$@" >/dev/null 2>&1 && ok "$name" || no "$name" ;}   # t name cmd...
ino () { local i ; read -r i _ < <(ls -id -- "$1") ; printf '%s' "$i" ;}
mstr () { local m ; read -r m _ < <(ls -ld -- "$1") ; printf '%s' "${m:0:10}" ;}
gid () { local g ; read -r _ _ _ g _ < <(ls -ldn -- "$1") ; printf '%s' "$g" ;}
eqt () { [ ! "$1" -nt "$2" ] && [ ! "$2" -nt "$1" ] ;}
fresh () { cd "$d" && rm -rf -- "./case" && mkdir case && cd case ;}
emu=0 ; [ "$(type -t ci)" = function ] && emu=1
printf 'NOTE ci is %s\n' "$([ $emu = 1 ] && echo 'the emulation' || command -v ci)"

# ------------------------------------------------ check-in keeps the original, both layouts
for lay in RCS beside ; do fresh
  [ $lay = RCS ] && mkdir RCS && v=RCS/f,v || v=f,v
  printf 'one\ntwo @at\n' > f ; chmod 640 f ; touch -t 202001010000 f
  i0=$(ino f) m0=$(mstr f)
  out=$(rrcs -i -m 'base' f 2>&1) ; rc=$?
  [ $rc = 0 ] && [ -f "$v" ] && ok "$lay initial check-in" || no "$lay initial check-in rc=$rc: $out"
  [ "$out" = "f 1.1" ] && ok "$lay result line" || no "$lay result line: $out"
  [ "$(ino f)" = "$i0" ] && ok "$lay inode kept" || no "$lay inode $i0 -> $(ino f)"
  [ "$(mstr f)" = "$m0" ] && ok "$lay mode kept" || no "$lay mode $m0 -> $(mstr f)"
  eqt f "$v" && ok "$lay ,v mtime equals file" || no "$lay ,v mtime differs"
  [ "$(ls -l f | awk '{print $6, $7, $8}')" = "Jan 1 2020" ] && ok "$lay file mtime original" || no "$lay file mtime changed"
  [ "$(mstr "$v")" = "-r--r-----" ] && ok "$lay ,v mode follows file" || no "$lay ,v mode $(mstr "$v")"
  [ "$(gid "$v")" = "$(gid f)" ] && ok "$lay ,v group follows file" || no "$lay ,v group $(gid "$v")"
  [ "$(co -p -q f)" = "$(cat f)" ] && ok "$lay co -p returns the text" || no "$lay co -p text"
  rlog -h f 2>/dev/null | grep -q 'keyword substitution: o' && ok "$lay rcs -ko set" || no "$lay rcs -ko not set"
  rlog -r1.1 f 2>/dev/null | grep -q '^rrcs f$' && ok "$lay log header" || no "$lay log header"
  rlog -r1.1 f 2>/dev/null | grep -q '^base$' && ok "$lay log message" || no "$lay log message"
  ls -A . | grep -q '^\.rrcs' && no "$lay scratch left" || ok "$lay no scratch left"
  printf 'three\n' >> f ; touch -t 202001020000 f ; i0=$(ino f)
  out=$(rrcs -m 'line a' -m 'line b' f 2>&1)
  [ "$out" = "f 1.2" ] && ok "$lay second check-in" || no "$lay second check-in: $out"
  [ "$(ino f)" = "$i0" ] && eqt f "$v" && ok "$lay second keeps inode and time" || no "$lay second inode or time"
  rlog -r1.2 f 2>/dev/null | grep -q '^line b$' && ok "$lay repeated -m" || no "$lay repeated -m"
  [ "$(co -p -q -r1.1 f)" = "$(printf 'one\ntwo @at')" ] && ok "$lay revision 1.1 intact" || no "$lay revision 1.1"
  out=$(rrcs f 2>&1) ; [ "$out" = "f unchanged" ] && ok "$lay unchanged" || no "$lay unchanged: $out"
  [ "$(rlog -h f 2>/dev/null | awk '$1 == "head:" {print $2}')" = 1.2 ] && ok "$lay no empty revision" || no "$lay empty revision made"
done

# ------------------------------------------------ execute bits follow the file
fresh ; printf '#!/bin/sh\n' > x ; chmod 750 x ; rrcs -q -i x
[ "$(mstr x,v)" = "-r-xr-x---" ] && ok "exec bits follow file" || no "exec bits: $(mstr x,v)"

# ------------------------------------------------ status marks, globs mixing ,v and untracked
fresh ; mkdir RCS ; for f in c m t b o ; do printf '%s\n' "$f" > "$f" ; done ; printf 'u\n' > u
rrcs -q -i c m t b o
printf 'more\n' >> m ; touch -t 203001010000 m                     # M: newer, differs
touch -t 203001010000 t                                            # T: newer, same content
printf 'more\n' >> b ; touch -t 199001010000 b                     # !: older, differs
rm -f o                                                             # -: orphan
out=$(rrcs -s * RCS/*,v 2>/dev/null)
# order follows first mention: the glob gives b c m t u, then RCS/o,v
exp=$'! b\nC c\nM m\nT t\n? u\n- o'
[ "$out" = "$exp" ] && ok "status marks and dedup" || no "status marks: $(printf '%s' "$out" | tr '\n' ' ')"
printf 'c\n' > c2 ; rrcs -q -i c2 ; printf 'X\n' > c2.new ; touch -r c2 c2.new ; mv c2.new c2 ; touch -c -r c2 RCS/c2,v
[ "$(rrcs -s c2)" = "C c2" ] && ok "-s trusts equal mtimes" || no "-s on equal mtimes"
[ "$(rrcs -S c2)" = "M c2" ] && ok "-S finds same-mtime change" || no "-S same-mtime: $(rrcs -S c2)"
rrcs -q t ; [ "$(rrcs -s t)" = "C t" ] && ok "touched file syncs" || no "touched sync: $(rrcs -s t)"

# ------------------------------------------------ comparison never uses rcsdiff (OpenRCS may call a text file binary)
fresh ; printf 'caf\303\251 \342\200\224 text\n' > u8 ; rrcs -q u8 ; printf 'more\n' >> u8 ; touch -t 203001010000 u8
out=$( rcsdiff () { return 2 ;} ; rrcs -s u8 2>&1 ) ; [ "$out" = "M u8" ] && ok "status independent of rcsdiff" || no "status with failing rcsdiff: $out"
out=$( rcsdiff () { return 2 ;} ; rrcs u8 2>&1 ) ; [ "$out" = "u8 1.2" ] && ok "check-in independent of rcsdiff" || no "check-in with failing rcsdiff: $out"
awk 'BEGIN { for (i = 0 ; i < 40000 ; i++) print "line " i }' > big ; rrcs -q big
{ echo changed ; cat big ;} > big.t ; cat big.t > big ; rm -f big.t ; touch -t 203001010000 big
[ "$(rrcs -s big 2>&1)" = "M big" ] && ok "early difference in a large file is M, not E" || no "large file: $(rrcs -s big 2>&1)"
mkdir -p RCS ; printf 'x\n' > bad ; printf 'junk' > RCS/bad,v
out=$(rrcs -S bad 2>&1) ; printf '%s' "$out" | grep -q '^E bad' && printf '%s' "$out" | grep -q 'cannot compare' && ok "damaged ,v reports E with a reason" || no "damaged ,v: $out"

# ------------------------------------------------ one path is deliberate; several need -i; -i on tracked fails
fresh ; printf 'a\n' > a ; printf 'n\n' > n ; printf 'p\n' > p ; printf 'q\n' > q
out=$(rrcs a 2>&1) ; [ -f a,v ] && [ "$out" = "a 1.1" ] && ok "single untracked path starts tracking" || no "single path: $out"
out=$(rrcs a n 2>&1) ; rc=$?
[ $rc = 0 ] && [ ! -f n,v ] && printf '%s' "$out" | grep -q 'add it with -i' && ok "untracked skipped among several paths" || no "untracked: rc=$rc $out"
rrcs -q -i p q ; [ -f p,v ] && [ -f q,v ] && ok "-i tracks several paths" || no "-i several"
rrcs -q -i a 2>/dev/null ; [ $? = 1 ] && ok "-i on tracked fails" || no "-i on tracked"

# ------------------------------------------------ names
fresh ; printf 's\n' > 'sp ace' ; out=$(rrcs -i 'sp ace' 2>&1)
[ -f 'sp ace,v' ] && printf '%s' "$out" | grep -q 'unusual characters' && ok "spaced name warns and works" || no "spaced name: $out"
printf 'd\n' > ./-dash ; rrcs -q -i -- -dash 2>/dev/null ; [ -f ./-dash,v ] && ok "leading dash name" || no "leading dash"
nl=$'new\nline' ; printf 'z\n' > "$nl" ; rrcs -q -i "$nl" 2>/dev/null ; rc=$?
[ $rc = 2 ] && [ ! -f "$nl,v" ] && ok "control characters refused" || no "control characters rc=$rc"
ln -s a lnk 2>/dev/null ; printf 'a\n' > a ; out=$(rrcs -i lnk 2>&1)
[ ! -f lnk,v ] && printf '%s' "$out" | grep -q symlink && ok "symlink skipped" || no "symlink: $out"

# ------------------------------------------------ group: a group rrcs cannot set gets no bits
fresh ; printf 'g\n' > g ; chmod 640 g ; other=
[ "$(id -u)" = 0 ] && other=65534 || for x in $(id -G) ; do [ "$x" = "$(gid g)" ] || { other=$x ; break ;} ; done
[ -n "$other" ] && chgrp "$other" g 2>/dev/null && {
  chgrp () { return 1 ;}                                            # refuse, as for a non-member
  out=$(rrcs -i g 2>&1) ; unset -f chgrp
  m=$(mstr g,v) ; [ "${m:4:3}" = "---" ] && printf '%s' "$out" | grep -q 'cannot set group' \
    && ok "unsettable group gets no bits" || no "unsettable group: $m $out" ;} \
  || printf 'NOTE skipped group test: no second group to use\n'

# ------------------------------------------------ rename
fresh ; mkdir RCS sub sub/RCS ; printf 'r\n' > r ; rrcs -q -i r ; i0=$(ino r)
printf 'more\n' >> r ; touch -t 203001010000 r
rrcs -R r r2 2>/dev/null ; [ $? = 1 ] && [ -f r ] && ok "rename refused while modified" || no "rename while modified"
rrcs -q r ; out=$(rrcs -R -m 'moved' r sub 2>&1) ; rc=$?
[ $rc = 0 ] && [ -f sub/r ] && [ -f sub/RCS/r,v ] && [ ! -e r ] && [ ! -e RCS/r,v ] && ok "rename moves file and ,v" || no "rename: rc=$rc $out"
[ "$(ino sub/r)" = "$i0" ] && ok "rename keeps inode" || no "rename inode"
rlog sub/r 2>/dev/null | grep -q '^rrcs -R r sub$' && ok "rename recorded" || no "rename record"
eqt sub/r sub/RCS/r,v && ok "rename time synced" || no "rename time"
printf 'x\n' > r3 ; rrcs -q -i r3 ; rrcs -R r3 sub/r 2>/dev/null ; [ $? = 1 ] && [ -f r3 ] && ok "rename onto existing refused" || no "rename onto existing"

# ------------------------------------------------ help and usage
rrcs -h | grep -q '^usage: rrcs' && ok "-h usage" || no "-h usage"
rrcs --help | grep -q 'rrcs stands for re-rcs' && ok "--help names re-rcs" || no "--help re-rcs"
rrcs --help | grep -q 'trinkle/RCS' && ok "--help upstream" || no "--help upstream"
rrcs --help | grep -q 'keywords.*not supported' && ok "--help keywords" || no "--help keywords"
for x in ci co rlog rcsdiff more ; do rrcs --help $x | grep -q 'Emulated' && ok "--help $x" || no "--help $x" ; done
rrcs --help bogus >/dev/null 2>&1 ; [ $? = 2 ] && ok "--help unknown topic" || no "--help unknown topic"
rrcs -Z f >/dev/null 2>&1 ; [ $? = 2 ] && ok "unknown option" || no "unknown option"
rrcs </dev/null >/dev/null 2>&1 ; [ $? = 2 ] && ok "no arguments" || no "no arguments"
fresh ; printf 'e\n' > e ; rrcs -e -i e </dev/null >/dev/null 2>&1 ; [ $? = 2 ] && [ ! -f e,v ] && ok "-e needs a terminal" || no "-e without terminal"

# ------------------------------------------------ editor under a pseudo-terminal
ptyrun () { # run a command line under a pty: util-linux or BSD script(1)
  script -qec "$1" /dev/null >/dev/null 2>&1 && return 0
  script -q /dev/null bash -c "$1" >/dev/null 2>&1 ;}
command -v script >/dev/null 2>&1 && {
  fresh ; printf 'e\n' > e ; printf '#!/bin/sh\nf=$1 ; { echo "edited message" ; cat "$f" ; } > "$f.t" && mv "$f.t" "$f"\n' > ../ed.sh
  printf '#!/bin/sh\nexit 0\n' > ../ed0.sh ; chmod +x ../ed.sh ../ed0.sh
  ptyrun "cd '$PWD' && . '$fn' && EDITOR='$d/ed.sh' VISUAL= rrcs -q -e -i e"
  rlog e 2>/dev/null | grep -q '^edited message$' && ! rlog e 2>/dev/null | grep -q '^#' && ok "-e message, comments dropped" || no "-e message"
  printf 'f\n' > f ; ptyrun "cd '$PWD' && . '$fn' && EDITOR='$d/ed0.sh' VISUAL= rrcs -q -e -i f"
  [ ! -f f,v ] && ok "-e empty message aborts" || no "-e empty message committed" ;} \
  || printf 'NOTE skipped editor tests: no script(1)\n'

# ------------------------------------------------ emulation: format round trip, both delta paths
[ $emu = 1 ] && for full in 0 1 ; do fresh
  RRCS_EMU_FULLDELTA=$full ; export RRCS_EMU_FULLDELTA
  : > h ; rrcs -q -i h ; cp h h.1
  for k in 2 3 4 5 6 ; do { cat h ; printf 'line %s @x\n' "$k" ; } | sed "s/^line 3 @x$/LINE 3 @@y/" > h.t ; cat h.t > h ; rm -f h.t
    rrcs -q -m "r$k" h ; cp h "h.$k" ; done
  x=0 ; for k in 1 2 3 4 5 6 ; do co -p -q -r1.$k h | cmp -s - "h.$k" || x=1 ; done
  [ $x = 0 ] && ok "emulation round trip (full delta $full)" || no "emulation round trip (full delta $full)"
  unset RRCS_EMU_FULLDELTA ; done

# ------------------------------------------------ two-way compatibility with real RCS
real=$(type -P ci) ; [ -n "$real" ] && {
  fresh ; printf 'a\nb\n' > w ; cp w w.1
  ( RRCS_EMULATE=1 ; . "$fn" ; ci -l -q -t-x -m'e1' w ; printf 'c\n' >> w ; ci -l -q -m'e2' w ) ; cp w w.2
  x=0 ; for k in 1 2 ; do command co -p -q -r1.$k w 2>/dev/null | cmp -s - "w.$k" || x=1 ; done
  command rlog w >/dev/null 2>&1 || x=1
  [ $x = 0 ] && ok "real RCS reads emulated ,v" || no "real RCS reads emulated ,v"
  rm -f w,v ; printf 'a\nb\n' > w ; command ci -l -q -t-x -m'r1' w </dev/null ; cp w w.1
  printf 'c\n' >> w ; command ci -l -q -m'r2' w </dev/null ; cp w w.2
  x=0 ; for k in 1 2 ; do ( RRCS_EMULATE=1 ; . "$fn" ; co -p -q -r1.$k w ) | cmp -s - "w.$k" || x=1 ; done
  [ $x = 0 ] && ok "emulation reads real ,v" || no "emulation reads real ,v" ;} \
  || printf 'NOTE skipped two-way compatibility: no RCS binaries\n'

# ------------------------------------------------ summary
cd / && printf '%s passed, %s failed\n' "$pass" "$fails"
[ $fails = 0 ] && { rm -rf -- "${d%/test-rrcs.*}/test-rrcs.${d##*/test-rrcs.}" ; exit 0 ;}
printf 'kept %s\n' "$d" ; exit 1
