# roffsub-man.awk --- write a roffsub source as the page to install for man
# roffsub r0.9
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# usage: awk [-v date=DATE] [-v version=VERSION] -f roffsub-man.awk FILE.1
#
# - fills @DATE@ and @VERSION@ on the .TH line (and only there)
# - rewrites each table so roff draws it as roffsub does: no vertical
#   lines, and a + where a rule meets a column gap.  Between columns goes
#   an empty separator column with no column separation on either side;
#   rule rows become cell rules joined by \-+\- in the separator columns;
#   box and allbox become such rule rows.  Columns holding text blocks
#   take the key modifier x, so roff gives them the rest of the line and
#   tables follow the width of the terminal they are read on.
# The source stays the roffsub form; this output is for man only.

BEGIN { intable = 0 }

# split row text r (lines joined by \n) into CELL[], BLK[]; return count
function splitrow(r,    n, p, q) {
	n = 0
	while (1) {
		n++
		if (substr(r, 1, 3) == "T{\n") {
			q = index(r, "\nT}")
			CELL[n] = substr(r, 4, q - 4); BLK[n] = 1
			r = substr(r, q + 3)
		} else {
			p = index(r, tabc)
			CELL[n] = p ? substr(r, 1, p - 1) : r; BLK[n] = 0
			r = p ? substr(r, p) : ""
		}
		if (r == "") break
		r = substr(r, 2)          # the tab character
	}
	return n
}

function ruleline(    i, s) {
	s = "_"
	for (i = 2; i <= K; i++) s = s tabc "\\-+\\-" tabc "_"
	return s
}

function addrule() { NR_OUT++; RT[NR_OUT] = "_"; RF[NR_OUT] = 0 }

function emit_table(    r, i, j, k, s, d, n, key, fl) {
	K = 0
	for (j = 1; j <= NFMT; j++) if (NK[j] > K) K = NK[j]
	# columns that hold text blocks expand to fill the line (key modifier x)
	for (i = 1; i <= K; i++) HB[i] = 0
	for (r = 1; r <= NROW; r++) {
		if (ROWT[r] == "_") continue
		n = splitrow(ROW[r])
		for (i = 1; i <= n; i++) if (BLK[i]) HB[i] = 1
	}
	# output rows: rules from box/allbox and _ rows, then data
	NR_OUT = 0; d = 0
	if (BOX || ALLBOX) addrule()
	for (r = 1; r <= NROW; r++) {
		if (ROWT[r] == "_") { if (!ALLBOX) addrule(); continue }
		d++; NR_OUT++; RT[NR_OUT] = "r"; RF[NR_OUT] = (d < NFMT) ? d : NFMT; RR[NR_OUT] = r
		if (ALLBOX) addrule()
	}
	if (BOX && !ALLBOX) addrule()
	# options and one format line per output row
	print ".TS"
	print OPTS (OPTS == "" ? "" : " ") "tab(" tabc ");"
	for (k = 1; k <= NR_OUT; k++) {
		fl = ""
		for (i = 1; i <= K; i++) {
			if (RT[k] == "_") key = "l"
			else key = (i <= NK[RF[k]]) ? FK[RF[k], i] : "l"
			if (HB[i] && key !~ /x/) key = key "x"
			fl = fl (i > 1 ? " " : "") key (i < K ? "0 c0" : "")
		}
		print fl (k == NR_OUT ? "." : "")
	}
	for (k = 1; k <= NR_OUT; k++) {
		if (RT[k] == "_") { print ruleline(); continue }
		n = splitrow(ROW[RR[k]])
		s = ""
		for (i = 1; i <= K; i++) {
			if (i > 1) s = s tabc tabc
			if (i <= n) s = s (BLK[i] ? "T{\n" CELL[i] "\nT}" : CELL[i])
		}
		print s
	}
	print ".TE"
}

!intable && /^\.TH / {
	if (date != "") gsub(/@DATE@/, date)
	if (version != "") gsub(/@VERSION@/, version)
	print; next
}

!intable && $0 == ".TS" {
	intable = 1; state = "opts"; NFMT = 0; NROW = 0; inblock = 0; cur = ""
	next
}

!intable { print; next }

state == "opts" {
	line = $0; tabc = "\t"
	if (match(line, /tab\(.\)/)) {
		tabc = substr(line, RSTART + 4, 1)
		line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
	}
	sub(/;[ ]*$/, "", line)
	BOX = (line ~ /(^| )box( |$)/); ALLBOX = (line ~ /allbox/)
	gsub(/(^| )(box|allbox)( |$)/, " ", line)
	gsub(/[ ]+/, " ", line); sub(/^ /, "", line); sub(/ $/, "", line)
	OPTS = line
	state = "fmt"; next
}

state == "fmt" {
	line = $0; last = (line ~ /\.[ ]*$/); sub(/\.[ ]*$/, "", line)
	NFMT++; NK[NFMT] = split(line, kk, " ")
	for (i = 1; i <= NK[NFMT]; i++) FK[NFMT, i] = kk[i]
	if (last) state = "data"
	next
}

state == "data" {
	if (!inblock && $0 == ".TE") { emit_table(); intable = 0; next }
	if (!inblock && cur == "" && $0 == "_") { NROW++; ROWT[NROW] = "_"; ROW[NROW] = ""; next }
	cur = (cur == "") ? $0 : cur "\n" $0
	line = $0
	if (inblock) {
		if (substr(line, 1, 2) == "T}") { inblock = 0; line = substr(line, 3) }
		else next
	}
	if (line == "T{" || substr(line, length(line) - 2) == tabc "T{") { inblock = 1; next }
	NROW++; ROWT[NROW] = "r"; ROW[NROW] = cur; cur = ""
	next
}
