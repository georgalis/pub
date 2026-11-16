# roffsub-check.awk --- check that a source follows the roffsub form
# roffsub r0.9
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# usage: LC_ALL=C awk [-v strict=1] -f roffsub-check.awk FILE.1 ...
#
# Reports FILE:LINE: ID: message on stderr.  Exit status 1 when any
# error was found (or any warning, with strict=1).  Form only; content
# is not judged.
#
#   E01 byte outside 0x20-0x7E      E07 '\" t line and tables disagree
#   E02 request not in roffsub      E08 table form
#   E03 escape not in roffsub       E09 .TH missing or not first
#   E04 unbalanced pair             E10 request arguments
#   E05 fill-mode text line form    E11 .TP without a tag line
#   E06 font not roman at a boundary
#   W01 option hyphen without \-    W02 abbreviation ends a line
#   W03 table too wide for roff at 80 columns (roff wraps only T{ T} cells)

BEGIN {
	REQ = "^(TH|SH|SS|PP|P|LP|TP|IP|RS|RE|nf|fi|B|I|BR|RB|IR|RI|BI|IB|sp|br|TS|TE)$"
	FONTREQ = "^(B|I|BR|RB|IR|RI|BI|IB)$"
	errs = 0; warns = 0
}

function report(id, msg) {
	printf "%s:%d: %s: %s\n", FILENAME, FNR, id, msg > "/dev/stderr"
	if (id ~ /^E/) errs++; else warns++
}

function reset() {
	tflag = 0; hastable = 0; seenreq = 0; seenth = 0
	nf = 0; rs = 0; intable = 0; inblock = 0; tpwait = 0; font = "R"
}

# check escapes in s; track font; return 0 on error
function escapes(s,    i, c, d, x, ok) {
	ok = 1
	for (i = 1; i <= length(s); i++) {
		if (substr(s, i, 1) != "\\") continue
		d = substr(s, i + 1, 1)
		if (d == "f") {
			x = substr(s, i + 2, 1)
			if (x ~ /^[BIRP]$/) { if (x == "P") x = pfont; pfont = font; font = x }
			else { report("E03", "font escape \\f" x " not in roffsub"); ok = 0 }
			i += 2
		} else if (d == "(") {
			x = substr(s, i + 2, 2)
			if (x !~ /^(em|en|bu|aq|dq)$/) { report("E03", "character \\(" x " not in roffsub"); ok = 0 }
			i += 3
		} else if (d ~ /^[-e& ]$/) i++
		else if (d == "") { report("E03", "backslash at end of line"); ok = 0 }
		else { report("E03", "escape \\" d " not in roffsub"); ok = 0; i++ }
	}
	return ok
}

function args(s, a,    n, i, c, cur, inq, have) {
	split("", a); n = 0; cur = ""; inq = 0; have = 0
	for (i = 1; i <= length(s); i++) {
		c = substr(s, i, 1)
		if (c == "\\") { cur = cur substr(s, i, 2); i++; have = 1; continue }
		if (c == "\"") {
			if (inq && substr(s, i + 1, 1) == "\"") report("E10", "embedded \"\" (write \\(dq)")
			inq = !inq; have = 1; continue
		}
		if (c == " " && !inq) { if (have) { a[++n] = cur; cur = ""; have = 0 }; continue }
		cur = cur c; have = 1
	}
	if (have) a[++n] = cur
	return n
}

function isw(w) { return w ~ /^[0-9]+n?$/ }

function optwarn(s,    t) {
	t = " " s
	gsub(/\\-/, "", t)
	if (t ~ /[ [(|]-[A-Za-z]/) report("W01", "option hyphen written without \\-")
}

# visible width of a cell, escapes resolved roughly
function vis(s,    t) {
	t = s
	gsub(/\\f[BIRP]/, "", t); gsub(/\\\([a-z][a-z]/, "x", t); gsub(/\\&/, "", t); gsub(/\\./, "x", t)
	return length(t)
}

function cell(s, blk) {
	if (!blk && vis(s) > cw[ncell]) cw[ncell] = vis(s)
	pfont = "R"; font = "R"
	escapes(s)
	if (font != "R") report("E06", "font not roman at end of table cell")
	font = "R"
}

function row(s,    p, piece) {
	while (1) {
		p = index(s, tabc)
		piece = p ? substr(s, 1, p - 1) : s
		if (!p && piece == "T{") { inblock = 1; block = ""; return }
		ncell++; cell(piece)
		if (!p) break
		s = substr(s, p + 1)
	}
	endrow()
}

function endrow() {
	if (ncell != ncol) report("E08", "row has " ncell " cells, format has " ncol)
	ncell = 0
}

function finish() {
	if (FNAME == "") return
	if (nf) report("E04", ".nf without .fi")
	if (rs) report("E04", ".RS without .RE")
	if (intable) report("E04", ".TS without .TE")
	if (tpwait) report("E11", ".TP at end of file without a tag line")
	if (!seenth) report("E09", ".TH missing")
	if (hastable && !tflag) report("E07", "table present but line 1 is not '\\\" t")
	if (tflag && !hastable) report("E07", "line 1 is '\\\" t but no table present")
}

FNR == 1 { finish(); FNAME = FILENAME; reset() }

/[^ -~]/ { report("E01", "byte outside printable ASCII (TAB, CR, or non-ASCII)") }

FNR == 1 && $0 == "'\\\" t" { tflag = 1; next }

intable {
	if (inblock) {
		if (substr($0, 1, 2) == "T}") {
			inblock = 0; ncell++; cell(block, 1)
			rest = substr($0, 3)
			if (rest == "") endrow()
			else if (substr(rest, 1, 1) != tabc) report("E08", "text after T} must begin with the tab character")
			else row(substr(rest, 2))
		} else {
			if ($0 ~ /^\./) report("E08", "request inside a text block")
			block = block " " $0
		}
		next
	}
	if ($0 == ".TE") {
		intable = 0; w = 3 * (ncol - 1)
		for (i = 1; i <= ncol; i++) w += cw[i]
		if (w > 71) report("W03", "table is " w " columns wide; roff wraps only T{ T} cells, so make the wide cells text blocks")
		next
	}
	if (tstate == "opts") {
		if ($0 !~ /;[ ]*$/) report("E08", "table options line must end with ;")
		if (match($0, /tab\(.\)/)) {
			tabc = substr($0, RSTART + 4, 1)
			if (tabc ~ /[A-Za-z0-9 ]/) report("E08", "tab character must be printable and not alphanumeric")
		} else { report("E08", "table options line needs tab(c)"); tabc = "\t" }
		line = $0; sub(/tab\(.\)/, "", line); sub(/;[ ]*$/, "", line)
		n = split(line, o, " ")
		for (i = 1; i <= n; i++)
			if (o[i] !~ /^(box|allbox|center)$/) report("E08", "table option " o[i] " not in roffsub")
		tstate = "fmt"; ncol = 0; split("", cw); next
	}
	if (tstate == "fmt") {
		line = $0; last = (line ~ /\.[ ]*$/); sub(/\.[ ]*$/, "", line)
		n = split(line, k, " ")
		if (ncol && n != ncol) report("E08", "format lines differ in column count")
		ncol = n
		for (i = 1; i <= n; i++) {
			x = k[i]; gsub(/w\([0-9]+n?\)/, "", x)
			if (x !~ /^[bi]*[lrc][bi]*$/) report("E08", "format key " k[i] " not in roffsub")
		}
		if (last) tstate = "data"
		next
	}
	if ($0 == "_") next
	if ($0 ~ /^\./) { report("E08", "request inside a table"); next }
	ncell = 0; row($0)
	next
}

/^\.\\"/ { next }

/^'/ { report("E02", "' as a control character"); next }

/^\./ {
	name = $0; sub(/^\./, "", name); sub(/ .*/, "", name)
	rest = substr($0, length(name) + 2); sub(/^ +/, "", rest)
	if (name !~ REQ) { report("E02", "request ." name " not in roffsub"); next }
	if (font != "R") report("E06", "font not roman before ." name)
	if (tpwait && name !~ FONTREQ) report("E11", ".TP followed by ." name ", not a tag line")
	tpwait = 0
	if (!seenreq && name != "TH") report("E09", ".TH must be the first request")
	seenreq = 1
	n = args(rest, a)
	if (n > 9) report("E10", "more than 9 arguments")
	pfont = "R"; font = "R"
	escapes(rest)
	if (font != "R") report("E06", "font not roman at end of ." name " line")
	font = "R"
	if (name == "TH") { seenth = 1; if (n < 2) report("E10", ".TH needs at least NAME and SEC") }
	else if (name ~ /^(SH|SS)$/) {
		if (!n) report("E10", "." name " needs its heading as an argument")
		if (nf) report("E04", "." name " inside .nf")
		if (rs) { report("E04", ".RS not closed before ." name); rs = 0 }
		if (name == "SH") inss = 0
	}
	else if (name == "TP") { if (n > 1 || (n && !isw(a[1]))) report("E10", ".TP takes an optional width in n"); tpwait = 1 }
	else if (name == "IP") { if (n > 2 || (n == 2 && !isw(a[2]))) report("E10", ".IP takes [tag [width]]") }
	else if (name == "RS") { if (n > 1 || (n && !isw(a[1]))) report("E10", ".RS takes an optional width in n"); rs++ }
	else if (name == "RE") { if (!rs) report("E04", ".RE without .RS"); else rs--; if (n) report("E10", ".RE takes no argument") }
	else if (name == "nf") { if (nf) report("E04", ".nf inside .nf"); nf = 1 }
	else if (name == "fi") { if (!nf) report("E04", ".fi without .nf"); nf = 0 }
	else if (name == "sp") { if (n > 1 || (n && a[1] !~ /^[0-9]+$/)) report("E10", ".sp takes an optional line count") }
	else if (name ~ /^(PP|P|LP|br)$/) { if (n) report("E10", "." name " takes no argument") }
	else if (name == "TS") {
		if (nf) report("E04", ".TS inside .nf")
		intable = 1; hastable = 1; tstate = "opts"
	}
	else if (name == "TE") report("E04", ".TE without .TS")
	else if (name ~ FONTREQ) { if (!n) report("E10", "." name " needs its words as arguments"); optwarn(rest) }
	next
}

{
	if (tpwait) tpwait = 0
	if (!nf) {
		if ($0 == "") report("E05", "empty line in fill mode (use .PP or .sp)")
		else if ($0 ~ /^ /) report("E05", "text line begins with a space in fill mode")
		if ($0 ~ /(e\.g\.|i\.e\.|etc\.|vs\.)$/) report("W02", "abbreviation ends the line; add \\&")
	}
	escapes($0)
	optwarn($0)
}

END {
	finish()
	exit (errs || (strict && warns)) ? 1 : 0
}
