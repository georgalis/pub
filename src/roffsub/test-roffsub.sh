#!/usr/bin/env bash
# test-roffsub.sh --- tests for the roffsub tools, binary, and function
# roffsub r0.9
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# usage: bash test-roffsub.sh [--gold]
#   --gold  rewrite the reference outputs in t/gold (review them after)

set -u
cd "$(dirname "$0")" || exit 2
AWK=${AWK:-awk}
GOLD=0; [ "${1:-}" = --gold ] && GOLD=1
pass=0 fail=0 skip=0
WIDTHS="40 60 80 120"
STYLES="plain overstrike sgr"
out=t/out
rm -rf "$out"; mkdir -p "$out" t/gold

ok()   { pass=$((pass + 1)); }
bad()  { fail=$((fail + 1)); echo "FAIL: $*"; }
skp()  { skip=$((skip + 1)); echo "skip: $*"; }
same() { if cmp -s "$1" "$2"; then ok; else bad "$3"; fi; }

# keep the function's output off any terminal and pager
unset MANWIDTH ROFFSUB_STYLE ROFFSUB_SGR ROFFSUB_MEASURE ROFFSUB_STRICT ROFFSUB_HEADING
. ./roffsub.fn.bash

# ---- checker ----
for f in roffsub.1 roffsub.7 template.1 t/ok/*.1; do
	if LC_ALL=C $AWK -v strict=1 -f roffsub-check.awk "$f" 2> "$out/chk"; then ok
	else bad "check rejects conforming $f: $(head -1 "$out/chk")"; fi
done
for f in t/bad/*.1; do
	want=$(sed -n 's/^\.\\" expect \([EW][0-9]*\).*/\1/p' "$f")
	LC_ALL=C $AWK -v strict=1 -f roffsub-check.awk "$f" 2> "$out/chk" && { bad "check accepts $f"; continue; }
	got=$(sed 's/^[^:]*:[0-9]*: \([EW][0-9]*\):.*/\1/' "$out/chk" | sort -u | tr '\n' ' ')
	[ "$got" = "$want " ] && ok || bad "$f expected $want, got $got"
done
roffsub -c t/ok/elements.1 2>/dev/null && ok || bad "function -c"
ROFFSUB_HEADING=1 ./roffsub --help > "$out/bho"; ROFFSUB_HEADING=1 roffsub --help > "$out/fho"
$AWK -v W=80 -v H=1 -f roffsub-render.awk roffsub.man.ir > "$out/aho"
same "$out/bho" "$out/aho" "binary ROFFSUB_HEADING"; same "$out/fho" "$out/aho" "function ROFFSUB_HEADING"
grep -q "^ NAME$" "$out/aho" && ok || bad "heading offset not applied"

# ---- compile, render, profiles ----
for src in t/ok/*.1 roffsub.1 roffsub.7 template.1; do
	b=$(basename "$src"); b=${b%.*}.${src##*.}
	ir=$out/$b.ir
	$AWK -v date=2026-11-15 -v version=r0.9 -f roffsub-ir.awk "$src" > "$ir"
	[ $GOLD = 1 ] && cp "$ir" "t/gold/$b.ir"
	same "$ir" "t/gold/$b.ir" "records $b"
	roffsub -i -d 2026-11-15 -r r0.9 "$src" > "$out/fn.ir"
	same "$out/fn.ir" "$ir" "function -i $b"
	for w in $WIDTHS; do
		for s in $STYLES; do
			g=t/gold/$b.$w.$s
			$AWK -v W=$w -v S=$s -f roffsub-render.awk "$ir" > "$out/awk"
			[ $GOLD = 1 ] && cp "$out/awk" "$g"
			same "$out/awk" "$g" "awk render $b $w $s"
			./roffsub -w $w -s $s "$ir" > "$out/bin"
			same "$out/bin" "$out/awk" "binary = awk $b $w $s"
			roffsub -w $w -s $s "$src" > "$out/fn"
			same "$out/fn" "$out/awk" "function = awk $b $w $s"
		done
	done
	# page for man: binary = function, reference output, tables in roffsub form
	./roffsub -n -d 2026-11-15 -r r0.9 "$src" > "$out/bn"
	roffsub -n -d 2026-11-15 -r r0.9 "$src" > "$out/fn"
	same "$out/bn" "$out/fn" "-n binary = function $b"
	[ $GOLD = 1 ] && cp "$out/bn" "t/gold/$b.n"
	same "$out/bn" "t/gold/$b.n" "-n page $b"
	$AWK '/^\.TS$/ { st = "o"; next }
	     st == "o" { if ($0 ~ /(^| )(all)?box( |;)/) print "box option kept"; st = "f"; next }
	     st == "f" { if (index($0, "|")) print "vertical bar in a format line"; if (/\.$/) st = "" }' "$out/bn" > "$out/nchk"
	[ -s "$out/nchk" ] && bad "-n table form $b: $(head -1 "$out/nchk")" || ok
	# preformatted profile: emit(pre at 80) equals render at 80
	$AWK -v W=80 -v S=pre -f roffsub-render.awk "$ir" > "$out/pre"
	roffsub -p "$src" > "$out/fnpre"
	same "$out/fnpre" "$out/pre" "function -p $b"
	for s in $STYLES; do
		$AWK -v W=80 -v S=$s -f roffsub-render.awk "$ir" > "$out/full"
		$AWK -v S=$s -f roffsub-emit.awk "$out/pre" > "$out/eawk"
		./roffsub -e -s $s "$out/pre" > "$out/ebin"
		same "$out/eawk" "$out/full" "awk emit = render $b $s"
		same "$out/ebin" "$out/full" "binary emit = render $b $s"
	done
	# measure
	$AWK -v W=120 -v M=60 -f roffsub-render.awk "$ir" > "$out/awk"
	./roffsub -w 120 -m 60 -s plain "$ir" > "$out/bin"
	same "$out/bin" "$out/awk" "measure $b"
done

# ---- embedded manual and usage ----
$AWK -v W=80 -v S=plain -f roffsub-render.awk roffsub.man.ir > "$out/man"
./roffsub --help > "$out/binhelp"
same "$out/binhelp" "$out/man" "binary --help (C embedding)"
roffsub --help > "$out/fnhelp"
same "$out/fnhelp" "$out/man" "function --help (bash embedding)"
MANWIDTH=50 ./roffsub --help > "$out/b50"
MANWIDTH=50 roffsub --help > "$out/f50"
$AWK -v W=50 -f roffsub-render.awk roffsub.man.ir > "$out/a50"
same "$out/b50" "$out/a50" "binary MANWIDTH"
same "$out/f50" "$out/a50" "function MANWIDTH"
ROFFSUB_STYLE=sgr ROFFSUB_SGR='b=1;33:i=3' ./roffsub --help > "$out/bsgr"
ROFFSUB_STYLE=sgr ROFFSUB_SGR='b=1;33:i=3' roffsub --help > "$out/fsgr"
$AWK -v W=80 -v S=sgr -v SB='1;33' -v SI=3 -f roffsub-render.awk roffsub.man.ir > "$out/asgr"
same "$out/bsgr" "$out/asgr" "binary ROFFSUB_SGR"
same "$out/fsgr" "$out/asgr" "function ROFFSUB_SGR"
./roffsub -h > "$out/bh"; roffsub -h > "$out/fh"
same "$out/bh" "$out/fh" "usage text binary = function"
[ "$(./roffsub -V)" = "$(roffsub -V)" ] && ok || bad "version binary = function"

# ---- embedding generator ----
printf 'a "quoted" line\twith tab\nback\\slash ??/ trigraph\n' > "$out/emb.txt"
$AWK -v mode=c -v name=emb -f roffsub-gen.awk "$out/emb.txt" > "$out/emb.h"
printf '#include <stdio.h>\n#include "emb.h"\nint main(void){const char*const*p;for(p=emb;*p;p++)puts(*p);return 0;}\n' > "$out/emb.c"
if ${CC:-cc} -std=c99 -Wall -Werror -o "$out/emb" "$out/emb.c" 2> "$out/cc"; then
	"$out/emb" > "$out/emb.out"; same "$out/emb.out" "$out/emb.txt" "C embedding round trip"
else bad "C embedding compile: $(head -1 "$out/cc")"; fi
$AWK -v mode=bash -v name=emb -f roffsub-gen.awk "$out/emb.txt" > "$out/emb.bash"
( . "$out/emb.bash"; printf '%s' "$emb" ) > "$out/emb.bout"
same "$out/emb.bout" "$out/emb.txt" "bash embedding round trip"

# ---- binary and function behave alike ----
for f in t/ok/*.1 t/bad/*.1; do
	./roffsub -c "$f" > "$out/bo" 2> "$out/be"; bs=$?
	roffsub -c "$f" > "$out/fo" 2> "$out/fe"; fs=$?
	[ $bs = $fs ] && cmp -s "$out/be" "$out/fe" && ok || bad "-c binary = function $f"
done
ROFFSUB_STRICT=1 ./roffsub -c t/bad/W01.1 2>/dev/null; bs=$?
ROFFSUB_STRICT=1 roffsub -c t/bad/W01.1 2>/dev/null; fs=$?
[ $bs = 1 ] && [ $fs = 1 ] && ok || bad "ROFFSUB_STRICT binary $bs function $fs"
src=t/ok/elements.1
./roffsub -i -d 2026-11-15 -r r0.9 $src > "$out/bi"; roffsub -i -d 2026-11-15 -r r0.9 $src > "$out/fi"
same "$out/bi" "$out/fi" "-i binary = function"
./roffsub -i < $src > "$out/bi"; roffsub -i < $src > "$out/fi"
same "$out/bi" "$out/fi" "-i stdin binary = function"
./roffsub -i "$out/fi" > "$out/bi2"; same "$out/bi2" "$out/fi" "-i passes records through"
./roffsub -p -w 60 $src > "$out/bp"; roffsub -p -w 60 $src > "$out/fp"
same "$out/bp" "$out/fp" "-p binary = function"
./roffsub -p < $src > "$out/bp"; roffsub -p < $src > "$out/fp"
same "$out/bp" "$out/fp" "-p stdin binary = function"
for l in c bash; do
	./roffsub -g $l nm $src > "$out/bg"; roffsub -g $l nm $src > "$out/fg"
	same "$out/bg" "$out/fg" "-g $l binary = function"
	./roffsub -g $l nm < $src > "$out/bg"; roffsub -g $l nm < $src > "$out/fg"
	same "$out/bg" "$out/fg" "-g $l stdin binary = function"
done
for w in 50 80; do
	./roffsub -w $w -s sgr $src > "$out/br"; roffsub -w $w -s sgr $src > "$out/fr"
	same "$out/br" "$out/fr" "render source binary = function $w"
	./roffsub -w $w < $src > "$out/br"; roffsub -w $w < $src > "$out/fr"
	same "$out/br" "$out/fr" "render stdin binary = function $w"
done
for o in "-w" "-s bold" "-w 0" "-g x y" "-q"; do
	./roffsub $o $src > /dev/null 2>&1; bs=$?
	roffsub $o $src > /dev/null 2>&1; fs=$?
	[ $bs = 2 ] && [ $fs = 2 ] && ok || bad "usage error '$o' binary $bs function $fs"
done

# ---- comparison with roff, where installed ----
# words only: roff's line-end hyphen breaks are joined and hyphens dropped
words() { tr -s ' \n' '\n\n' | grep -v '^[-+|]*$' |
	$AWK '/[A-Za-z]-$/ { hold = hold substr($0, 1, length($0) - 1); next }
	     { print hold $0; hold = "" }' | tr -d '-'; }
if command -v mandoc > /dev/null 2>&1 || command -v groff > /dev/null 2>&1; then
	report=$out/roff-diff.txt; : > "$report"
	for src in t/ok/elements.1 t/ok/tables.1 roffsub.1 roffsub.7; do
		b=$(basename "$src")
		# tables are left out: column wrapping reorders their words
		$AWK '/^\.TS$/ { t = 1; next } /^\.TE$/ { t = 0; next } !t' "$src" > "$out/$b.notbl"
		if command -v mandoc > /dev/null 2>&1; then mandoc -Tascii "$out/$b.notbl"; else groff -man -Tascii -P-c "$out/$b.notbl"; fi 2>/dev/null |
			$AWK '{ gsub(".\b", ""); print }' | sed '1d;$d' | words > "$out/$b.roff.w"
		$AWK -f roffsub-ir.awk "$out/$b.notbl" | $AWK -v W=78 -f roffsub-render.awk | words > "$out/$b.rs.w"
		n=$(diff "$out/$b.roff.w" "$out/$b.rs.w" | grep -c '^[<>]')
		echo "info: $b word differences from roff, tables left out: $n"
		{ echo "== $b: $n (< roff, > roffsub)"; diff "$out/$b.roff.w" "$out/$b.rs.w"; } >> "$report"
	done
	echo "info: all differences are in $report:"
	sed 's/^/  /' "$report"
	ok
else
	skp "roff comparison (neither mandoc nor groff installed)"
fi

echo "$pass passed, $fail failed, $skip skipped"
[ $fail = 0 ]
