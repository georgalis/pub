# roffsub-ir.awk --- compile a roffsub source into records
# roffsub r0.9
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# usage: awk [-v date=DATE] [-v version=VERSION] -f roffsub-ir.awk FILE.1
#
# Output: one record per line, an operation name then TAB-separated
# fields.  Text fields carry only \fB \fI \fR \\ \~ and end in roman.
# The source is assumed to pass roffsub-check.awk.

BEGIN {
	TAB = "\t"
	font = "R"; prev = "R"; carry = ""
	nf = 0; tpwait = 0; intable = 0; inblock = 0
	print "v" TAB "1"
}

# argument splitting: double quotes group, backslash pairs never split
function args(s, a,    n, i, c, cur, inq, have) {
	split("", a)
	n = 0; cur = ""; inq = 0; have = 0
	for (i = 1; i <= length(s); i++) {
		c = substr(s, i, 1)
		if (c == "\\") { cur = cur substr(s, i, 2); i++; have = 1; continue }
		if (c == "\"") { inq = !inq; have = 1; continue }
		if (c == " " && !inq) {
			if (have) { a[++n] = cur; cur = ""; have = 0 }
			continue
		}
		cur = cur c; have = 1
	}
	if (have) a[++n] = cur
	return n
}

# resolve character escapes; fonts kept, \fP resolved; uses font/prev
function esc(s,    out, i, c, d, f, x) {
	out = ""
	for (i = 1; i <= length(s); i++) {
		c = substr(s, i, 1)
		if (c != "\\") { out = out c; continue }
		d = substr(s, i + 1, 1); i++
		if (d == "f") {
			f = substr(s, i + 1, 1); i++
			if (f == "P") f = prev
			if (f != "B" && f != "I") f = "R"
			prev = font; font = f
			out = out "\\f" f
		} else if (d == "-") out = out "-"
		else if (d == "e") out = out "\\\\"
		else if (d == "&") out = out
		else if (d == " ") out = out "\\~"
		else if (d == "(") {
			x = substr(s, i + 1, 2); i += 2
			if (x == "em") out = out "--"
			else if (x == "en") out = out "-"
			else if (x == "bu") out = out "o"
			else if (x == "aq") out = out "'"
			else if (x == "dq") out = out "\""
			else out = out "\\\\(" x
		} else out = out "\\\\" d
	}
	return out
}

# drop redundant font changes; begin and end in roman
function norm(s,    out, cur, pend, i, c, tok) {
	out = ""; cur = "R"; pend = ""
	for (i = 1; i <= length(s); ) {
		c = substr(s, i, 1)
		if (c == "\\" && substr(s, i + 1, 1) == "f") {
			pend = substr(s, i + 2, 1); i += 3; continue
		}
		if (c == "\\") { tok = substr(s, i, 2); i += 2 } else { tok = c; i++ }
		if (pend != "" && pend != cur) { out = out "\\f" pend; cur = pend }
		pend = ""
		out = out tok
	}
	if (cur != "R") out = out "\\fR"
	return out
}

# resolve a request argument or cell, starting and ending in roman
function rtext(s) { font = "R"; prev = "R"; return norm(esc(s)) }

function width(w) { sub(/n$/, "", w); return (w ~ /^[0-9]+$/) ? w + 0 : "" }

function join(a, n, sep,    i, s) {
	s = ""
	for (i = 1; i <= n; i++) s = s (i > 1 ? sep : "") a[i]
	return s
}

# font requests (.B .I .BR ...) to resolved text
function fontreq(name, a, n,    f1, f2, i, s) {
	if (name == "B" || name == "I") return rtext("\\f" name join(a, n, " ") "\\fR")
	f1 = substr(name, 1, 1); f2 = substr(name, 2, 1)
	s = ""
	for (i = 1; i <= n; i++) s = s "\\f" ((i % 2) ? f1 : f2) a[i]
	return rtext(s "\\fR")
}

function isfont(name) { return name ~ /^(B|I|BR|RB|IR|RI|BI|IB)$/ }

# table rows: split on the tab character, open text blocks
function row(s,    i, p, n, piece) {
	while (1) {
		p = index(s, tabc)
		piece = p ? substr(s, 1, p - 1) : s
		if (!p && piece == "T{") { inblock = 1; block = ""; return }
		cells[++nc] = rtext(piece)
		if (!p) break
		s = substr(s, p + 1)
	}
	emitrow()
}

function emitrow(    i, s) {
	s = "tr"
	for (i = 1; i <= nc; i++) s = s TAB cells[i]
	print s
	nc = 0
}

NR == 1 && /^'\\" t/ { next }

intable {
	if (inblock) {
		if (substr($0, 1, 2) == "T}") {
			inblock = 0
			cells[++nc] = rtext(block)
			rest = substr($0, 3)
			if (rest == "") emitrow()
			else row(substr(rest, 2))
		} else block = block (block == "" ? "" : " ") $0
		next
	}
	if ($0 == ".TE") { intable = 0; print "te"; next }
	if (tstate == "opts") {
		line = $0
		tabc = "\t"
		if (match(line, /tab\(.\)/)) {
			tabc = substr(line, RSTART + 4, 1)
			line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
		}
		sub(/;[ ]*$/, "", line)
		gsub(/[ ]+/, " ", line); sub(/^ /, "", line); sub(/ $/, "", line)
		print "ts" TAB line
		tstate = "fmt"; next
	}
	if (tstate == "fmt") {
		line = $0; last = (line ~ /\.[ ]*$/)
		sub(/\.[ ]*$/, "", line)
		n = split(line, k, " ")
		print "tf" TAB join(k, n, TAB)
		if (last) tstate = "data"
		next
	}
	if ($0 == "_") { print "t_"; next }
	nc = 0
	row($0)
	next
}

/^\.\\"/ { next }

/^\./ {
	name = $0; sub(/^\./, "", name); sub(/ .*/, "", name)
	rest = substr($0, length(name) + 2); sub(/^ +/, "", rest)
	n = args(rest, a)
	if (tpwait && isfont(name)) {
		tpwait = 0
		print "tp" TAB tpw TAB fontreq(name, a, n); next
	}
	if (tpwait) { tpwait = 0; print "tp" TAB tpw TAB "" }
	if (name == "TH") {
		for (i = 1; i <= 5; i++) {
			f[i] = (i <= n) ? a[i] : ""
			if (date != "") gsub(/@DATE@/, date, f[i])
			if (version != "") gsub(/@VERSION@/, version, f[i])
			f[i] = rtext(f[i])
		}
		print "th" TAB f[1] TAB f[2] TAB f[3] TAB f[4] TAB f[5]
	}
	else if (name == "SH") print "sh" TAB rtext(join(a, n, " "))
	else if (name == "SS") print "ss" TAB rtext(join(a, n, " "))
	else if (name == "PP" || name == "P" || name == "LP") print "pp"
	else if (name == "TP") { tpwait = 1; tpw = width(a[1]) }
	else if (name == "IP") print "ip" TAB width(a[2]) TAB (n ? rtext(a[1]) : "")
	else if (name == "RS") print "rs" TAB width(a[1])
	else if (name == "RE") print "re"
	else if (name == "nf") { nf = 1; print "nf" }
	else if (name == "fi") { nf = 0; print "fi" }
	else if (name == "sp") print "sp" TAB ((n && a[1] ~ /^[0-9]+$/) ? a[1] + 0 : 1)
	else if (name == "br") print "br"
	else if (name == "TS") { intable = 1; tstate = "opts"; nc = 0 }
	else if (isfont(name)) print "tx" TAB fontreq(name, a, n)
	next
}

{
	if (tpwait) { tpwait = 0; print "tp" TAB tpw TAB rtext($0); next }
	if (!nf && $0 == "") next
	font = "R"
	s = esc((carry != "" ? "\\f" carry : "") $0)
	carry = (font != "R") ? font : ""
	print "tx" TAB norm(s)
}
