#!/bin/sh
# test.sh --- asciixlate regression suite, POSIX sh against the built binary
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6af37686 20261110 115446 PST Tue 11:54 AM 10 Nov 2026
#     2.1.0: replaces run.sh; isolated from the operator's rule file; cases
#     for the stdin block stream, the deleted-pictograph space, and each
#     defect found in review.
# rev 6a9f4e20 20260907 165200 PDT Mon 04:52 PM 07 Sep 2026
#     2.0.0: 51 cases, one per 1.0 defect or manual promise.
#
# Every case names its origin: PoC (a 1.0 defect), R (a 2.0.0 review
# finding, numbered as in PLAN.md), P (pictographs), S (stdin stream), or
# the manual section it holds to.
# usage: sh ./test.sh        AX=/path/to/asciixlate overrides the binary
set -u
AX="${AX:-./asciixlate}"
[ -x "$AX" ] || { echo "test.sh: no binary at $AX (run make)" >&2 ; exit 1 ;}

# scratch directory: literal class asciixlate-test., kept base and suffix
td=$(mktemp -d "${TMPDIR:-/tmp}/asciixlate-test.XXXXXX") || exit 1
base=${td%/asciixlate-test.*} id=${td##*/asciixlate-test.}
case $id in ''|*[!A-Za-z0-9]*) echo "test.sh: unexpected mktemp name $td" >&2 ; exit 1 ;; esac
trap 'rm -rf "$base/asciixlate-test.$id"' EXIT
trap 'exit 130' INT HUP TERM
TD="$base/asciixlate-test.$id"

# isolation: the operator's ~/.asciixlate and environment must not reach the tests
mkdir "$TD/home" ; HOME="$TD/home" ; export HOME
unset ASCIIXLATE_CONFIG PAGER

pass=0 fail=0 skip=0
bad() { fail=$((fail+1)) ; printf 'FAIL %s\n  %s\n' "$1" "$2" ;}
chk() { [ "$2" = "$3" ] && pass=$((pass+1)) || bad "$1" "expected [$2] got [$3]" ;} # name expected actual
skp() { skip=$((skip+1)) ; printf 'skip: %s\n' "$1" ;}
u()   { printf "$1" > "$TD/in" ;}          # write bytes to $TD/in
perm() { ls -ld "$1" | cut -c1-10 ;}
inode() { ls -i "$1" | awk '{print $1}' ;}
C="$TD/cfg"

# --- core transliteration (manual: DESCRIPTION) ----------------------------
u 'a\342\200\224b'; chk "em dash -> ---"        'a---b' "$("$AX" "$TD/in")"
u '\342\270\272';   chk "two-em dash -> ----"   '----'  "$("$AX" "$TD/in")"
u 'a\302\255b';     chk "soft hyphen dropped"   'ab'    "$("$AX" "$TD/in")"
u '\342\200\234x\342\200\235'; chk "curly quotes" '"x"' "$("$AX" "$TD/in")"
u '\342\200\246';   chk "ellipsis"              '...'   "$("$AX" "$TD/in")"
u 'a\302\240b';     chk "nbsp -> space"         'a b'   "$("$AX" "$TD/in")"
u 'caf\303\251';    chk "accent folded"         'cafe'  "$("$AX" "$TD/in")"
u '\342\206\222';   chk "arrow -> ->"           '->'    "$("$AX" "$TD/in")"

# --- untranslatable --------------------------------------------------------
u '\343\215\277';   chk "unmapped -> ??"        '??'    "$("$AX" -q "$TD/in")"
u '\357\274\237';   chk "fullwidth ? is mapped" '?'     "$("$AX" "$TD/in")"   # PoC B1
"$AX" -q -s "$TD/in" >/dev/null 2>&1; chk "strict on mapped char exits 0" 0 $?
u '\343\215\277'; "$AX" -q -s "$TD/in" >/dev/null 2>&1
chk "strict on unmapped exits 2" 2 $?
chk "-k keeps original bytes" "$(printf '\343\215\277')" "$("$AX" -q -k "$TD/in")"
chk "-m sets marker"          '<?>'   "$("$AX" -q -m '<?>' "$TD/in")"

# --- data safety (PoC class A; manual: OUTPUT) -----------------------------
printf 'A\342\200\224Z\n' > "$TD/ip"
"$AX" -i "$TD/ip" >/dev/null 2>&1
chk "in-place preserves content" 'A---Z' "$(cat "$TD/ip")"          # PoC A1
printf 'A\342\200\224Z\n' > "$TD/w"
[ -c /dev/full ] && {                                               # PoC A2
  "$AX" -o /dev/full "$TD/w" >/dev/null 2>&1
  chk "write failure is reported" 1 $?
  "$AX" "$TD/w" >/dev/full 2>/dev/null;       chk "R8 full stdout: conversion" 1 $?
  "$AX" -l >/dev/full 2>/dev/null;            chk "R8 full stdout: --list"     1 $?
  "$AX" --help >/dev/full 2>/dev/null;        chk "R8 full stdout: --help"     1 $?
  "$AX" -h >/dev/full 2>/dev/null;            chk "R8 full stdout: -h"         1 $?
  "$AX" -r "$TD/w" >/dev/full 2>/dev/null;    chk "R8 full stdout: --report"   1 $?
  : ;} || skp "/dev/full absent: 6 write-failure cases"
printf 'x' > "$TD/-v"
chk "-- ends options" 'x' "$("$AX" -- "$TD/-v")"                    # PoC A3
printf 'A\342\200\224Z\n' > "$TD/m"; chmod 0640 "$TD/m"
"$AX" -i "$TD/m" >/dev/null 2>&1
chk "in-place preserves mode" '-rw-r-----' "$(perm "$TD/m")"
chk "no temporary left behind" '' "$(ls -a "$TD" | grep '^\.asciixlate\.' ||:)"

# R6: -i through a symlink rewrites the target; the link stays a link
printf 'a\342\200\224b\n' > "$TD/real"; ln -s real "$TD/link"
"$AX" -i "$TD/link" >/dev/null 2>&1
chk "R6 -i keeps the symlink"     'l'      "$(perm "$TD/link" | cut -c1)"
chk "R6 -i converts the target"   'a---b'  "$(cat "$TD/real")"
ln -s nowhere "$TD/dangle"
"$AX" -i "$TD/dangle" >/dev/null 2>&1; chk "R6 dangling symlink refused" 1 $?

# R7: an unchanged file is not rewritten (inode and hard links survive)
printf 'plain ascii\n' > "$TD/p"; ln "$TD/p" "$TD/p2"; i0=$(inode "$TD/p")
"$AX" -i "$TD/p" >/dev/null 2>&1
chk "R7 unchanged file keeps its inode" "$i0" "$(inode "$TD/p")"
chk "R7 unchanged file keeps its link"  "$i0" "$(inode "$TD/p2")"
printf 'A\342\200\224Z\n' > "$TD/q"; i0=$(inode "$TD/q")
"$AX" -i "$TD/q" >/dev/null 2>&1
chk "R7 changed file is replaced" 1 "$([ "$i0" != "$(inode "$TD/q")" ] && echo 1)"

# R13: -o keeps an existing mode; a new file takes the umask
printf 'old' > "$TD/o1"; chmod 0600 "$TD/o1"
"$AX" -o "$TD/o1" "$TD/w" 2>/dev/null
chk "R13 -o keeps an existing mode" '-rw-------' "$(perm "$TD/o1")"
( umask 027; "$AX" -o "$TD/o2" "$TD/w" 2>/dev/null )
chk "R13 -o new file honors umask" '-rw-r-----' "$(perm "$TD/o2")"
ln -s o1 "$TD/olink"; "$AX" -o "$TD/olink" "$TD/w" 2>/dev/null
chk "R13 -o follows a symlink" 'lA---Z' "$(perm "$TD/olink" | cut -c1)$(cat "$TD/o1")"

# --- refusals (manual: REFUSALS) -------------------------------------------
"$AX" "$TD" >/dev/null 2>&1;    chk "directory refused"  1 $?
printf 'a\000b' > "$TD/bin"
"$AX" "$TD/bin" >/dev/null 2>&1; chk "binary refused"    1 $?
chk "binary allowed with -B" 'a' "$("$AX" -q -B "$TD/bin" | tr -d '\000b')"
head -c 4096 /dev/zero | tr '\0' 'a' > "$TD/big"
"$AX" -M 1k "$TD/big" >/dev/null 2>&1; chk "size cap refused" 1 $?
"$AX" -M 4k "$TD/big" >/dev/null 2>&1; chk "size cap is inclusive" 0 $?
"$AX" - >/dev/null 2>&1 </dev/null; chk "operand - is a file name, not stdin" 1 $?
mkfifo "$TD/fifo" 2>/dev/null && {                                  # R10
  "$AX" "$TD/fifo" >/dev/null 2>&1; chk "R10 fifo refused without waiting" 1 $? ;} ||
  skp "mkfifo unavailable: R10 fifo case"
[ -r /proc/version ] && {                                           # R9
  chk "R9 size-0 file with content is read" "$(wc -c < /proc/version)" \
      "$("$AX" -q /proc/version | wc -c)" ;} || skp "/proc absent: R9 case"
"$AX" -M -1 "$TD/big" >/dev/null 2>&1;              chk "R11 negative size rejected" 1 $?
"$AX" -M 99999999999999999g "$TD/big" >/dev/null 2>&1; chk "R11 size overflow rejected" 1 $?
"$AX" -M 4kb "$TD/big" >/dev/null 2>&1;             chk "R11 size suffix junk rejected" 1 $?

# --- rule file grammar (manual: RULE FILE) ---------------------------------
printf 'U+2014\t===\n'                 > "$C"
u '\342\200\224'; chk "cfg U+ overrides default" '===' "$("$AX" -c "$C" "$TD/in")"
printf '0x2014\t===\n'                 > "$C"
chk "cfg 0x form"              '===' "$("$AX" -c "$C" "$TD/in")"
printf '\\xE2\\x80\\x94\t===\n'        > "$C"
chk "cfg byte form"            '===' "$("$AX" -c "$C" "$TD/in")"
printf '\342\200\224\t===\n'           > "$C"
chk "cfg pasted literal"       '===' "$("$AX" -c "$C" "$TD/in")"
printf 'U+00A0\t" "\n'                 > "$C"
u 'a\302\240b'; chk "quoted space value"         'a b' "$("$AX" -c "$C" "$TD/in")"   # PoC B5
printf 'U+266F\t"#"\n'                 > "$C"
u '\342\231\257'; chk "quoted hash value"        '#'   "$("$AX" -c "$C" "$TD/in")"   # PoC B5
printf 'U+266F\t"a #b"\n'              > "$C"
chk "R3 quoted value holds space-hash" 'a #b' "$("$AX" -c "$C" "$TD/in")"
printf 'U+266F\t"a \\" #b" # note\n'   > "$C"
chk "R3 escaped quote, then a comment" 'a " #b' "$("$AX" -c "$C" "$TD/in")"
printf 'U+266F\t"a" b\n'               > "$C"
"$AX" -c "$C" "$TD/in" >/dev/null 2>&1; chk "R3 text after closing quote is an error" 1 $?
printf 'U+266F\t"a\n'                  > "$C"
chk "unclosed quote is a literal value" '"a' "$("$AX" -c "$C" "$TD/in")"
printf 'U+2014\t""\n'                  > "$C"
u 'a\342\200\224b'; chk "quoted empty deletes"   'ab'  "$("$AX" -c "$C" "$TD/in")"
u 'a \342\200\224 b'; chk "deleting a dash keeps both spaces" 'a  b' "$("$AX" -c "$C" "$TD/in")"
printf 'U+2014\t--- # trailing comment\n' > "$C"
u '\342\200\224'; chk "trailing comment stripped" '---' "$("$AX" -c "$C" "$TD/in")"
printf '# only a comment\n\n'          > "$C"
u 'a'; chk "comments and blanks ignored"          'a'  "$("$AX" -c "$C" "$TD/in")"
printf 'U+2014\n'                      > "$C"
"$AX" -c "$C" "$TD/in" >/dev/null 2>&1; chk "bare empty value is an error" 1 $?
printf '=U+2014\tLIT\n'                > "$C"
printf 'U+2014' > "$TD/in"; chk "= forces literal key" 'LIT' "$("$AX" -c "$C" "$TD/in")"
printf '\342\200\234x\342\200\235\t[q]\n' > "$C"
u '\342\200\234x\342\200\235'; chk "multi-codepoint key" '[q]' "$("$AX" -c "$C" "$TD/in")"
printf "U+0009\t\"    \"\\n"                > "$C"
u 'a\tb'; chk "ascii key can be remapped" 'a    b' "$("$AX" -c "$C" "$TD/in")"
printf 'U+ZZZZ\tx\n'                   > "$C"
"$AX" -c "$C" "$TD/in" >/dev/null 2>&1; chk "bad code point is an error" 1 $?
"$AX" -c "$TD/nope" "$TD/in" >/dev/null 2>&1; chk "missing -c file is an error" 1 $?
printf '=->\tto\n'                     > "$C"                       # R2
u 'a->b\n->c'; chk "R2 ascii-led multi rule matches mid-run" 'atob toc' \
    "$("$AX" -c "$C" "$TD/in" | tr '\n' ' ' | sed 's/ $//')"
printf '=\tx\n'                        > "$C"                       # R4
"$AX" -c "$C" "$TD/in" >/dev/null 2>&1; chk "R4 empty literal key is an error" 1 $?
printf 'U+D800\tx\n'                   > "$C"
"$AX" -c "$C" "$TD/in" >/dev/null 2>&1; chk "R4 surrogate key is an error" 1 $?
printf '=ab\t1\n=ab\t2\n'              > "$C"                       # R14
u 'ab'; chk "R14 later multi rule replaces earlier" '2' "$("$AX" -c "$C" "$TD/in")"
awk 'BEGIN { for (i = 0; i < 6000; i++) printf "U+%04X\tx\n", 19968 + i }' > "$C"   # R5
u '\344\270\200\344\270\201'; chk "R5 6000 rules load and apply" 'xx' "$("$AX" -c "$C" "$TD/in")"

# --- deleted pictographs (manual: DELETED PICTOGRAPHS) ---------------------
# rocket U+1F680, check U+2705, hands U+1F64F; ZWJ and VS16 deleted as glue
R='\360\237\232\200' K='\342\234\205' H='\360\237\231\217'
printf 'U+1F680\t""\nU+2705\t""\nU+1F64F\t""\nU+FE0F\t""\nU+2764\t<3\nU+00AD\t""\n' > "$C"
px() { u "$1"; "$AX" -c "$C" "$TD/in" | tr '\n' '|' ;}
chk "P between words: one space left"      'Launch today|'   "$(px "Launch $R today\n")"
chk "P at line start: no leading space"    'Done|'           "$(px "$K Done\n")"
chk "P at line end: no trailing space"     'Done|'           "$(px "Done $K\n")"
chk "P at end of file"                     'Done'            "$(px "Done $K")"
chk "P before CRLF"                        "$(printf 'Done\r|')" "$(px "Done $K\r\n")"
chk "P abutting a word keeps the space"    'Thanks everyone|' "$(px "Thanks$H everyone\n")"
chk "P run of pictographs counts once"     'x y|'            "$(px "x $R$K$R y\n")"
chk "P spaced pictographs each take one"   'y|'              "$(px "$R $K y\n")"
chk "P glue (VS16) stays in the run"       'a b|'            "$(px "a $K\357\270\217 b\n")"
chk "P after indentation"                  '  item|'         "$(px "  $K item\n")"
chk "P in a list item"                     '- item|'         "$(px '\055'" $K item\n")"
chk "P alone on a line"                    '|x|'             "$(px "$R\nx\n")"
chk "P no space either side"               'ab|'             "$(px "a${R}b\n")"
chk "P before punctuation: space kept"     'Great !|'        "$(px "Great $R!\n")"
chk "P replaced, not deleted: untouched"   'I <3 it|'        "$(px 'I \342\235\244 it\n')"
chk "P soft hyphen never takes a space"    'co operate|'     "$(px 'co\302\255 operate\n')"
chk "P two spaces after: one goes"         'a  b|'           "$(px "a $R  b\n")"
printf "$R$K"'\t""\n'                > "$C"
chk "P multi-rule pictograph"              'a b|'            "$(px "a $R$K b\n")"
printf 'U+1F680\t""\nU+0020\t_\n'      > "$C"
chk "P a rule on space is left to act"     'a__b|'           "$(px "a $R b\n")"

# --- standard input as a block stream (manual: STANDARD INPUT) -------------
chk "S stdin is filtered"           'a---b cafe' "$(printf 'a\342\200\224b caf\303\251' | "$AX")"
chk "S empty stdin: empty output"   '0:'  "$("$AX" </dev/null; echo "$?:")"
printf 'x' | "$AX" -i >/dev/null 2>&1;          chk "S -i without a file refused" 1 $?
printf 'x' | "$AX" -o "$TD/so" >/dev/null 2>&1; chk "S -o without a file refused" 1 $?
printf 'a\000b' | "$AX" >/dev/null 2>&1;        chk "S binary stdin refused" 1 $?
chk "S binary stdin emits nothing"  '' "$(printf 'a\000b' | "$AX" 2>/dev/null)"
chk "S binary stdin allowed with -B" 'ab' "$(printf 'a\000b' | "$AX" -B | tr -d '\000')"
printf '\343\215\277' | "$AX" -qs >/dev/null 2>&1; chk "S --strict from stdin exits 2" 2 $?
chk "S --report from stdin" 'U+337F' "$(printf '\343\215\277' | "$AX" -r | awk '/^U\+/{print $1; exit}')"
chk "S -n from stdin writes nothing" '' "$(printf 'abc' | "$AX" -n)"
printf 'x' | "$AX" -b 255 >/dev/null 2>&1; chk "S block below 256 refused" 1 $?
printf 'x' | "$AX" -b 2g  >/dev/null 2>&1; chk "S block above 1G refused"  1 $?
chk "S plain trailing spaces survive" 'a   |b ' "$(printf 'a   \nb ' | "$AX" -b 256 | tr '\n' '|')"
[ -c /dev/full ] && { printf 'abc' | "$AX" >/dev/full 2>/dev/null
  chk "S full stdout from stdin" 1 $? ;} || skp "/dev/full absent: stream write-failure case"

# block edges never change the result: every size must equal the file path.
# The text puts multibyte characters, rule keys, key prefixes and deleted
# pictographs with their spaces at every phase of a block.
printf 'U+1F680\t""\nU+2705\t""\nU+FE0F\t""\n=->\tto\n=ABCDEFGHIJKLMNOPQRST\t<k>\n\342\200\234x\342\200\235\t[q]\n' > "$C"
awk 'BEGIN { for (i = 1; i <= 1500; i++) {
  printf "w%d \360\237\232\200 x Done \342\234\205\357\270\217\n", i
  printf "%*s\342\234\205 item a->b ABCDEFGHIJKLMNOPQRST ABCDEFGHIJ-\n", i % 7, ""
  printf "\342\200\234x\342\200\235 \342\200\234y caf\303\251 \343\215\277 \342\200\224 end   \n"
  if (i % 100 == 0) { for (k = 0; k < 900; k++) printf "\360\237\232\200 \303\251-"; printf "\n" } } }' > "$TD/edge"
"$AX" -q -c "$C" "$TD/edge" > "$TD/edge.file"
for b in 256 257 263 300 1000 4096 65536; do
  "$AX" -q -c "$C" -b "$b" < "$TD/edge" > "$TD/edge.out"
  chk "S block $b equals the file result" 0 "$(cmp -s "$TD/edge.file" "$TD/edge.out"; echo $?)"
done
dd if="$TD/edge" bs=5 2>/dev/null | "$AX" -q -c "$C" -b 256 > "$TD/edge.out"
chk "S short reads equal the file result" 0 "$(cmp -s "$TD/edge.file" "$TD/edge.out"; echo $?)"
chk "S edge text exercises the rules" 1 "$([ "$(grep -c '<k>' "$TD/edge.file")" -eq 1500 ] && ! grep -q '  x Done\|Done $' "$TD/edge.file" && echo 1)"
[ -f example.md ] && [ -f example.ascii.md ] && {
  "$AX" -q -b 256 < example.md > "$TD/exs"
  chk "S example.md through stdin" 0 "$(cmp -s "$TD/exs" example.ascii.md; echo $?)" ;} ||
  skp "example files absent"

# --- report / list (manual: BUILDING A RULE FILE) --------------------------
u '\343\215\277\343\215\277'
chk "--report emits a stub" 'U+337F' "$("$AX" --report "$TD/in" | awk '/^U\+/{print $1; exit}')"
"$AX" --report "$TD/in" 2>/dev/null | sed 's/	??	/	XX	/' > "$C.gen"
chk "--report output is valid config" 'XXXX' "$("$AX" -q -c "$C.gen" "$TD/in")"
chk "--list is valid config" 0 "$("$AX" -l > "$C.list"; "$AX" -q -c "$C.list" "$TD/in" >/dev/null 2>&1; echo $?)"
printf '=->\t"a #\\"\\\\"\nU+2014\t""\n' > "$C"
chk "--list round trips quoting" 0 "$("$AX" -c "$C" -l > "$C.l1"; "$AX" -c "$C.l1" --no-defaults -l > "$C.l2"; cmp -s "$C.l1" "$C.l2"; echo $?)"

# --- invalid utf-8 ---------------------------------------------------------
u 'A\377B';        chk "invalid byte -> marker" 'A??B' "$("$AX" -q "$TD/in")"
"$AX" -q -s "$TD/in" >/dev/null 2>&1
chk "strict rejects invalid utf-8" 2 $?
u 'A\355\240\200B'; chk "encoded surrogate is invalid" 'A??????B' "$("$AX" -q "$TD/in")"
u 'A\300\257B';     chk "overlong form is invalid"     'A????B'   "$("$AX" -q "$TD/in")"
u 'A\342\200';      chk "truncated sequence at EOF"    'A????'    "$("$AX" -q "$TD/in")"

# --- options (R12; manual: SYNOPSIS) ---------------------------------------
u '\343\215\277'
chk "R12 short options cluster"   "$(printf '\343\215\277')" "$("$AX" -qk "$TD/in")"
chk "R12 -mSTR attached value"    '!'  "$("$AX" -qm! "$TD/in")"
chk "R12 --marker=STR"            '!'  "$("$AX" -q --marker=! "$TD/in")"
chk "R12 --marker STR"            '!'  "$("$AX" -q --marker ! "$TD/in")"
chk "R12 --marker= sets empty"    ''   "$("$AX" -q --marker= "$TD/in")"
"$AX" --quiet=1 "$TD/in" >/dev/null 2>&1; chk "R12 flag with a value is an error" 1 $?
"$AX" -qZ "$TD/in" >/dev/null 2>&1;       chk "R12 unknown letter in a cluster" 1 $?
"$AX" -c >/dev/null 2>&1;                 chk "missing option value" 1 $?
"$AX" -i -o "$TD/x" "$TD/in" >/dev/null 2>&1; chk "-i with -o refused" 1 $?
"$AX" -o "$TD/x" "$TD/in" "$TD/in" >/dev/null 2>&1; chk "-o with two inputs refused" 1 $?

# --- help split (manual: HELP) ---------------------------------------------
chk "-h is the brief usage" 'usage:' "$("$AX" -h | awk 'NR==3{print $1}')"
chk "--usage is an alias for -h" 0 "$("$AX" -h > "$TD/a"; "$AX" --usage > "$TD/b"; cmp -s "$TD/a" "$TD/b"; echo $?)"
chk "--help is the manual" 'NAME' "$("$AX" --help | awk 'NR==1{print $1}')"
chk "--manual is an alias for --help" 0 "$("$AX" --help > "$TD/a"; "$AX" --manual > "$TD/b"; cmp -s "$TD/a" "$TD/b"; echo $?)"
chk "manual is longer than usage" 1 "$([ "$("$AX" --help | wc -l)" -gt "$("$AX" -h | wc -l)" ] && echo 1)"
chk "usage fits one screen" 1 "$([ "$("$AX" -h | wc -l)" -le 30 ] && echo 1)"
chk "--version carries the revision" 'rev' "$("$AX" --version | awk '{print $3}')"
"$AX" --nosuch >/dev/null 2>&1; chk "unknown option exits 1" 1 $?

# --- self-consistency: the tool passes its own filter ----------------------
"$AX" -h        > "$TD/h";   "$AX" -q "$TD/h" > "$TD/h2"
chk "-h output is already ascii" 0 "$(cmp -s "$TD/h" "$TD/h2"; echo $?)"
"$AX" --help    > "$TD/m1";  "$AX" -q "$TD/m1" > "$TD/m2"
chk "--help output is already ascii" 0 "$(cmp -s "$TD/m1" "$TD/m2"; echo $?)"
[ -f example.md ] && [ -f example.ascii.md ] && {
  "$AX" -q example.md > "$TD/ex"
  chk "example.md converts to example.ascii.md" 0 "$(cmp -s "$TD/ex" example.ascii.md; echo $?)" ;} ||
  skp "example files absent"

printf 'test.sh: %d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"
[ "$fail" -eq 0 ]
