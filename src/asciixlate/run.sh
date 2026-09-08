#!/bin/sh
# asciixlate regression suite. Every case below is a defect found in the
# 1.0.0 proof of concept, or a behaviour promised by --manual.
set -u
AX="${AX:-./asciixlate}"
TD=$(mktemp -d); trap 'rm -rf "$TD"' EXIT
pass=0; fail=0
ok()   { pass=$((pass+1)); }
bad()  { fail=$((fail+1)); printf 'FAIL %s\n  %s\n' "$1" "$2"; }
chk()  { # name expected actual
    if [ "$2" = "$3" ]; then ok; else bad "$1" "expected [$2] got [$3]"; fi
}
u() { printf "$1" > "$TD/in"; }        # write bytes to $TD/in

# --- core transliteration -------------------------------------------------
u 'a\342\200\224b'; chk "em dash -> ---"        'a---b' "$($AX $TD/in)"
u '\342\270\272';   chk "two-em dash -> ----"   '----'  "$($AX $TD/in)"
u 'a\302\255b';     chk "soft hyphen dropped"   'ab'    "$($AX $TD/in)"
u '\342\200\234x\342\200\235'; chk "curly quotes" '"x"' "$($AX $TD/in)"
u '\342\200\246';   chk "ellipsis"              '...'   "$($AX $TD/in)"
u 'a\302\240b';     chk "nbsp -> space"         'a b'   "$($AX $TD/in)"
u 'caf\303\251';    chk "accent folded"         'cafe'  "$($AX $TD/in)"
u '\342\206\222';   chk "arrow -> ->"           '->'    "$($AX $TD/in)"

# --- untranslatable -------------------------------------------------------
u '\343\215\277';   chk "unmapped -> ??"        '??'    "$($AX -q $TD/in)"
u '\357\274\237';   chk "fullwidth ? is mapped" '?'     "$($AX $TD/in)"   # PoC B1
$AX -q -s $TD/in >/dev/null 2>&1; chk "strict on mapped char exits 0" 0 $?
u '\343\215\277'; $AX -q -s $TD/in >/dev/null 2>&1
chk "strict on unmapped exits 2" 2 $?
u '\343\215\277'; chk "-k keeps original bytes" "$(printf '\343\215\277')" "$($AX -q -k $TD/in)"
u '\343\215\277'; chk "-m sets marker"          '<?>'   "$($AX -q -m '<?>' $TD/in)"

# --- data safety (PoC class A) --------------------------------------------
printf 'A\342\200\224Z\n' > "$TD/ip"
$AX -i "$TD/ip" >/dev/null 2>&1
chk "in-place preserves content" 'A---Z' "$(cat $TD/ip)"          # PoC A1
printf 'A\342\200\224Z\n' > "$TD/w"
$AX -o /dev/full "$TD/w" >/dev/null 2>&1
chk "write failure is reported" 1 $?                              # PoC A2
printf 'x' > "$TD/-v"
chk "-- ends options" 'x' "$($AX -- "$TD/-v")"                    # PoC A3
printf 'A\342\200\224Z\n' > "$TD/m"; chmod 0640 "$TD/m"
$AX -i "$TD/m" >/dev/null 2>&1
chk "in-place preserves mode" '640' "$(stat -c %a "$TD/m" 2>/dev/null || stat -f %Lp "$TD/m")"

# --- refusals -------------------------------------------------------------
$AX "$TD" >/dev/null 2>&1;    chk "directory refused"  1 $?
printf 'a\000b' > "$TD/bin"
$AX "$TD/bin" >/dev/null 2>&1; chk "binary refused"    1 $?
chk "binary allowed with -B" 'a' "$($AX -q -B $TD/bin | tr -d '\000b')"
head -c 4096 /dev/zero | tr '\0' 'a' > "$TD/big"
$AX -M 1k "$TD/big" >/dev/null 2>&1; chk "size cap refused" 1 $?
$AX >/dev/null 2>&1;          chk "no stdin, no args"  1 $?

# --- config grammar -------------------------------------------------------
C="$TD/cfg"
printf 'U+2014\t===\n'                 > $C
u '\342\200\224'; chk "cfg U+ overrides default" '===' "$($AX -c $C $TD/in)"
printf '0x2014\t===\n'                 > $C
u '\342\200\224'; chk "cfg 0x form"              '===' "$($AX -c $C $TD/in)"
printf '\\xE2\\x80\\x94\t===\n'        > $C
u '\342\200\224'; chk "cfg byte form"            '===' "$($AX -c $C $TD/in)"
printf '\342\200\224\t===\n'           > $C
u '\342\200\224'; chk "cfg pasted literal"       '===' "$($AX -c $C $TD/in)"
printf 'U+00A0\t" "\n'                 > $C
u 'a\302\240b'; chk "quoted space value"         'a b' "$($AX -c $C $TD/in)"   # PoC B5
printf 'U+266F\t"#"\n'                 > $C
u '\342\231\257'; chk "quoted hash value"        '#'   "$($AX -c $C $TD/in)"   # PoC B5
printf 'U+2014\t""\n'                  > $C
u 'a\342\200\224b'; chk "quoted empty deletes"   'ab'  "$($AX -c $C $TD/in)"
printf 'U+2014\t--- # trailing comment\n' > $C
u '\342\200\224'; chk "trailing comment stripped" '---' "$($AX -c $C $TD/in)"
printf '# only a comment\n\n'          > $C
u 'a'; chk "comments and blanks ignored"          'a'  "$($AX -c $C $TD/in)"
printf 'U+2014\n'                      > $C
$AX -c $C $TD/in >/dev/null 2>&1; chk "bare empty value is an error" 1 $?
printf '=U+2014\tLIT\n'                > $C
printf 'U+2014' > "$TD/in"; chk "= forces literal key" 'LIT' "$($AX -c $C $TD/in)"
printf '\342\200\234x\342\200\235\t[q]\n' > $C
u '\342\200\234x\342\200\235'; chk "multi-codepoint key" '[q]' "$($AX -c $C $TD/in)"
printf "U+0009\t\"    \"\\n"                > $C
u 'a\tb'; chk "ascii key can be remapped" 'a    b' "$($AX -c $C $TD/in)"
printf 'U+ZZZZ\tx\n'                   > $C
$AX -c $C $TD/in >/dev/null 2>&1; chk "bad code point is an error" 1 $?
$AX -c "$TD/nope" $TD/in >/dev/null 2>&1; chk "missing -c file is an error" 1 $?

# --- report / list --------------------------------------------------------
u '\343\215\277\343\215\277'
chk "--report emits a stub" 'U+337F' "$($AX --report $TD/in | awk '/^U\+/{print $1; exit}')"
$AX --report $TD/in > $C.gen 2>/dev/null
sed -i.bak 's/\t??\t/\tXX\t/' $C.gen 2>/dev/null || sed -i 's/\t??\t/\tXX\t/' $C.gen
chk "--report output is valid config" 'XXXX' "$($AX -q -c $C.gen $TD/in)"
chk "--list is valid config" 0 "$($AX -l > $C.list; $AX -q -c $C.list $TD/in >/dev/null 2>&1; echo $?)"

# --- invalid utf-8 --------------------------------------------------------
u 'A\377B';        chk "invalid byte -> marker" 'A??B' "$($AX -q $TD/in)"
u 'A\377B'; $AX -q -s $TD/in >/dev/null 2>&1
chk "strict rejects invalid utf-8" 2 $?

# --- help split -----------------------------------------------------------
chk "-h is the brief usage" 'usage:' "$($AX -h | awk 'NR==3{print $1}')"
chk "--usage is an alias for -h" 0 "$($AX -h > $TD/a; $AX --usage > $TD/b; cmp -s $TD/a $TD/b; echo $?)"
chk "--help is the manual" 'NAME' "$($AX --help | awk 'NR==1{print $1}')"
chk "--manual is an alias for --help" 0 "$($AX --help > $TD/a; $AX --manual > $TD/b; cmp -s $TD/a $TD/b; echo $?)"
chk "manual is longer than usage" 1 "$([ $($AX --help | wc -l) -gt $($AX -h | wc -l) ] && echo 1)"
$AX --nosuch >/dev/null 2>&1; chk "unknown option exits 1" 1 $?

# --- self-consistency: the tool passes its own filter ---------------------
$AX -h        > "$TD/h";   $AX -q "$TD/h" > "$TD/h2"
chk "-h output is already ascii" 0 "$(cmp -s $TD/h $TD/h2; echo $?)"
$AX --help    > "$TD/m1";  $AX -q "$TD/m1" > "$TD/m2"
chk "--help output is already ascii" 0 "$(cmp -s $TD/m1 $TD/m2; echo $?)"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
