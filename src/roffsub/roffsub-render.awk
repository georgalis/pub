# roffsub-render.awk --- render roffsub records for a terminal
# roffsub r0.9
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# usage: awk -v W=80 -v S=plain [-v SB=1] [-v SI=4] [-v M=0] \
#            -f roffsub-render.awk FILE.ir
#
#   W   width in columns
#   S   plain | overstrike | sgr | pre
#       (pre writes \fB \fI \fR markup for the emitter)
#   SB  SGR parameters for bold (default 1)
#   SI  SGR parameters for italic (default 4, underline)
#   M   maximum line length, 0 for none
#   H   section heading column offset, 0 by default
#
# Records arrive on stdin or as a file; never pass them with -v.

BEGIN {
	FS = "\t"
	if (W == "" || W + 0 < 1) W = 80
	W = W + 0
	if (S == "") S = "plain"
	if (SB == "") SB = "1"
	if (SI == "") SI = "4"
	HO = H + 0
	WE = (M + 0 > 0 && M + 0 < W) ? M + 0 : W
	U = (WE < 60) ? 4 : 7
	SSI = int(U / 2)
	NB = "\001"; ESC = "\033"; BS = "\b"
	L = 0; PI = U; TI = 0; TL = 0; rsn = 0
	nfm = 0; started = 0; afterhead = 0
	BC = ""; BA = ""; hastag = 0; TC = ""; TA = ""
	intab = 0; collect = 0
}

function sp(n,    s) { s = ""; while (n-- > 0) s = s " "; return s }
function rep(c, n,    s) { s = ""; while (n-- > 0) s = s c; return s }

# split a record text into chars PC and attributes PA
function parse(s,    i, c, d, f) {
	PC = ""; PA = ""; f = "R"
	for (i = 1; i <= length(s); i++) {
		c = substr(s, i, 1)
		if (c == "\\") {
			d = substr(s, i + 1, 1)
			if (d == "f") { f = substr(s, i + 2, 1); i += 2; continue }
			c = (d == "~") ? NB : d
			i++
		}
		PC = PC c; PA = PA f
	}
}

# attributes promoted by a font (heading bold, table b/i)
function promote(a, f) { if (f == "B" || f == "I") gsub(/R/, f, a); return a }

# write one finished line in the selected style
function emit(c, a,    i, ch, at, cur, o) {
	o = ""; cur = "R"
	for (i = 1; i <= length(c); i++) {
		ch = substr(c, i, 1); at = substr(a, i, 1)
		if (ch == NB) ch = " "
		if (S == "overstrike") {
			if (ch != " " && at == "B") o = o ch BS ch
			else if (ch != " " && at == "I") o = o "_" BS ch
			else o = o ch
			continue
		}
		if (S == "sgr" || S == "pre") {
			if (at != cur) {
				if (S == "sgr") {
					if (cur != "R") o = o ESC "[0m"
					if (at == "B") o = o ESC "[" SB "m"
					else if (at == "I") o = o ESC "[" SI "m"
				} else o = o "\\f" at
				cur = at
			}
			if (S == "pre" && ch == "\\") ch = "\\\\"
		}
		o = o ch
	}
	if (cur != "R") o = o ((S == "sgr") ? ESC "[0m" : "\\fR")
	print o
}

# finish a line: trim trailing blanks, then print or collect
function out(c, a) {
	while (c != "" && substr(c, length(c), 1) == " ") {
		c = substr(c, 1, length(c) - 1); a = substr(a, 1, length(a) - 1)
	}
	if (collect) { LN++; LCC[LN] = c; LCA[LN] = a; return }
	emit(c, a); started = 1; afterhead = 0
}

function blank() { if (!collect) { print ""; started = 1 } }

# words of c/a into WC/WA, split at plain spaces
function words(c, a,    i, ch, n, wc, wa) {
	n = 0; wc = ""; wa = ""
	for (i = 1; i <= length(c); i++) {
		ch = substr(c, i, 1)
		if (ch == " ") {
			if (wc != "") { WC[++n] = wc; WA[n] = wa; wc = ""; wa = "" }
			continue
		}
		wc = wc ch; wa = wa substr(a, i, 1)
	}
	if (wc != "") { WC[++n] = wc; WA[n] = wa }
	return n
}

# greedy fill: first line begins with prefix pc/pa, later lines at ci,
# lines end at column lim
function fill(c, a, pc, pa, ci, lim,    n, i, lc, la, empty) {
	n = words(c, a)
	lc = pc; la = pa; empty = 1
	for (i = 1; i <= n; i++) {
		if (empty) { lc = lc WC[i]; la = la WA[i]; empty = 0 }
		else if (length(lc) + 1 + length(WC[i]) <= lim) {
			lc = lc " " WC[i]; la = la "R" WA[i]
		} else {
			out(lc, la)
			lc = sp(ci) WC[i]; la = rep("R", ci) WA[i]
		}
	}
	if (!empty || lc ~ /[^ ]/) out(lc, la)
}

function vsp() { if (started && !afterhead) blank() }

function flush(    pc, pa) {
	if (BC == "" && !hastag) return
	if (hastag) {
		if (length(TC) < TI - TL) {
			pc = sp(TL) TC sp(TI - TL - length(TC))
			pa = rep("R", TL) TA rep("R", TI - TL - length(TC))
		} else {
			out(sp(TL) TC, rep("R", TL) TA)
			pc = sp(TI); pa = rep("R", TI)
		}
	} else { pc = sp(TI); pa = rep("R", TI) }
	fill(BC, BA, pc, pa, TI, WE)
	BC = ""; BA = ""; hastag = 0
}

function heading(s, ind) {
	flush()
	if (started) blank()
	parse(s)
	out(sp(ind) PC, rep("R", ind) promote(PA, "B"))
	afterhead = 1
	L = U; PI = U; TI = L; TL = L; rsn = 0
}

# ---- tables ----

function key(k, i, j,    al, m) {
	al = "l"
	if (k ~ /r/) al = "r"
	else if (k ~ /c/) al = "c"
	KAL[j, i] = al
	KF[j, i] = (k ~ /b/) ? "B" : ((k ~ /i/) ? "I" : "R")
	KW[j, i] = 0
	if (match(k, /w\([0-9]+n?\)/)) {
		m = substr(k, RSTART + 2, RLENGTH - 3); sub(/n$/, "", m)
		KW[j, i] = m + 0
	}
}

function aligned(c, a, w, al,    pad, l) {
	pad = w - length(c)
	if (pad <= 0) { AC = c; AA = a; return }
	if (al == "r") { AC = sp(pad) c; AA = rep("R", pad) a }
	else if (al == "c") {
		l = int(pad / 2)
		AC = sp(l) c sp(pad - l); AA = rep("R", l) a rep("R", pad - l)
	} else { AC = c sp(pad); AA = a rep("R", pad) }
}

function rule(x0,    i, s) {
	s = sp(x0)
	for (i = 1; i <= NCOL; i++) s = s (i > 1 ? "+" : "") rep("-", CW[i] + 2)
	out(s, rep("R", length(s)))
}

function table(    r, i, j, d, f, n, k, nat, flo, sumn, sumf, A, G, cap,
                   s, rem, prog, ord, t, x0, h, lc, la, cnt, box, allbox,
                   center, lab, first, lw) {
	box = (TOPT ~ /(^| )box( |$)/); allbox = (TOPT ~ /allbox/)
	center = (TOPT ~ /center/)
	NCOL = 0
	for (j = 1; j <= TFN; j++) if (KN[j] > NCOL) NCOL = KN[j]
	for (i = 1; i <= NCOL; i++) { nat[i] = 0; flo[i] = 0 }
	d = 0
	for (r = 1; r <= TRN; r++) {
		if (RT[r] == "_") continue
		d++; f = (d < TFN) ? d : TFN
		for (i = 1; i <= NCOL; i++) {
			parse(RC[r, i])
			CC[r, i] = PC; CA[r, i] = promote(PA, KF[f, i]); CAL[r, i] = KAL[f, i]
			if (length(PC) > nat[i]) nat[i] = length(PC)
			n = words(PC, PA)
			for (k = 1; k <= n; k++) if (length(WC[k]) > flo[i]) flo[i] = length(WC[k])
		}
	}
	for (j = 1; j <= TFN; j++) for (i = 1; i <= NCOL; i++) {
		if (KW[j, i] > flo[i]) flo[i] = KW[j, i]
		if (KW[j, i] > nat[i]) nat[i] = KW[j, i]
	}
	sumn = 0; sumf = 0
	for (i = 1; i <= NCOL; i++) { sumn += nat[i]; sumf += flo[i] }
	G = 3 * (NCOL - 1) + 2
	A = WE - TI - G
	if (sumn <= A) {
		for (i = 1; i <= NCOL; i++) CW[i] = nat[i]
	} else if (sumf > A) {
		records(); return
	} else {
		for (cap = sumn; cap >= 0; cap--) {
			s = 0
			for (i = 1; i <= NCOL; i++) s += mincap(nat[i], flo[i], cap)
			if (s <= A) break
		}
		for (i = 1; i <= NCOL; i++) { CW[i] = mincap(nat[i], flo[i], cap); ord[i] = i }
		for (i = 1; i <= NCOL; i++) for (j = i + 1; j <= NCOL; j++)
			if (nat[ord[j]] > nat[ord[i]]) { t = ord[i]; ord[i] = ord[j]; ord[j] = t }
		rem = A - s
		while (rem > 0) {
			prog = 0
			for (k = 1; k <= NCOL && rem > 0; k++) {
				i = ord[k]
				if (CW[i] < nat[i]) { CW[i]++; rem--; prog = 1 }
			}
			if (!prog) break
		}
	}
	lw = G; for (i = 1; i <= NCOL; i++) lw += CW[i]
	x0 = TI
	if (center && WE - TI > lw) x0 = TI + int((WE - TI - lw) / 2)
	if (box || allbox) rule(x0)
	for (r = 1; r <= TRN; r++) {
		if (RT[r] == "_") { if (!allbox) rule(x0); continue }
		h = 0
		for (i = 1; i <= NCOL; i++) {
			collect = 1; LN = 0
			fill(CC[r, i], CA[r, i], "", "", 0, CW[i])
			collect = 0
			cnt[i] = LN
			for (k = 1; k <= LN; k++) { TLC[i, k] = LCC[k]; TLA[i, k] = LCA[k] }
			if (LN > h) h = LN
		}
		for (k = 1; k <= h; k++) {
			lc = sp(x0); la = rep("R", x0)
			for (i = 1; i <= NCOL; i++) {
				if (k <= cnt[i]) aligned(TLC[i, k], TLA[i, k], CW[i], CAL[r, i])
				else aligned("", "", CW[i], "l")
				lc = lc (i > 1 ? " " : "") " " AC " "
				la = la (i > 1 ? "R" : "") "R" AA "R"
			}
			out(lc, la)
		}
		if (allbox) rule(x0)
	}
	if (box && !allbox) rule(x0)
}

function mincap(n, f, cap,    w) { w = (f > cap) ? f : cap; return (n < w) ? n : w }

# a table too wide for its floors: one "label: value" line per cell
function records(    r, i, first, lab, c, a, nrow) {
	first = 1
	if (TRN >= 2 && RT[1] != "_" && RT[2] == "_") {
		for (i = 1; i <= NCOL; i++) { LABC[i] = CC[1, i]; LABA[i] = CA[1, i] }
		first = 3
	} else for (i = 1; i <= NCOL; i++) { LABC[i] = i ""; LABA[i] = rep("R", length(i "")) }
	nrow = 0
	for (r = first; r <= TRN; r++) {
		if (RT[r] == "_") continue
		if (nrow++) blank()
		for (i = 1; i <= NCOL; i++) {
			c = LABC[i] ": " CC[r, i]; a = LABA[i] "RR" CA[r, i]
			fill(c, a, sp(TI), rep("R", TI), TI + 2, WE)
		}
	}
}

# ---- records ----

$1 == "v" { if ($2 + 0 != 1) { print "roffsub: unsupported record version " $2 > "/dev/stderr"; exit 2 } next }
$1 == "th" { next }
$1 == "sh" { heading($2, HO); next }
$1 == "ss" { heading($2, SSI); next }
$1 == "pp" { flush(); vsp(); PI = U; TI = L; TL = L; next }
$1 == "tp" || $1 == "ip" {
	flush(); vsp()
	if ($2 != "") PI = $2 + 0
	TL = L; TI = L + PI
	hastag = ($1 == "tp" || $3 != "")
	parse($3); TC = PC; TA = PA
	next
}
$1 == "rs" {
	flush(); rsn++; RSL[rsn] = L; RSP[rsn] = PI
	L += ($2 != "") ? $2 + 0 : PI
	PI = U; TI = L; TL = L
	next
}
$1 == "re" {
	flush()
	if (rsn > 0) { L = RSL[rsn]; PI = RSP[rsn]; rsn-- }
	TI = L; TL = L
	next
}
$1 == "nf" { flush(); nfm = 1; next }
$1 == "fi" { flush(); nfm = 0; next }
$1 == "br" { flush(); next }
$1 == "sp" { flush(); n = $2 + 0; while (n-- > 0) blank(); afterhead = 0; next }
$1 == "ts" { flush(); TOPT = $2; TFN = 0; TRN = 0; next }
$1 == "tf" { TFN++; KN[TFN] = NF - 1; for (i = 2; i <= NF; i++) key($i, i - 1, TFN); next }
$1 == "tr" { TRN++; RT[TRN] = "r"; for (i = 2; i <= NF; i++) RC[TRN, i - 1] = $i
	for (; i - 1 <= KN[1]; i++) RC[TRN, i - 1] = ""; next }
$1 == "t_" { TRN++; RT[TRN] = "_"; next }
$1 == "te" { table(); next }
$1 == "tx" {
	parse($2)
	if (nfm) {
		if (hastag) flush()
		out(sp(TI) PC, rep("R", TI) PA)
		next
	}
	if (BC != "") { BC = BC " "; BA = BA "R" }
	BC = BC PC; BA = BA PA
	next
}
END { flush() }
