# roffsub-emit.awk --- emit pre-formatted roffsub text for a terminal
# roffsub r0.9
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# usage: awk -v S=plain [-v SB=1] [-v SI=4] -f roffsub-emit.awk FILE.pre
#
# Input lines carry only \fB \fI \fR and \\ (from roffsub-render.awk -v S=pre).

BEGIN {
	if (S == "") S = "plain"
	if (SB == "") SB = "1"
	if (SI == "") SI = "4"
	ESC = "\033"; BS = "\b"
}

{
	o = ""; cur = "R"; f = "R"; s = $0
	for (i = 1; i <= length(s); i++) {
		ch = substr(s, i, 1)
		if (ch == "\\") {
			if (substr(s, i + 1, 1) == "f") { f = substr(s, i + 2, 1); i += 2; continue }
			ch = substr(s, i + 1, 1); i++
		}
		if (S == "overstrike") {
			if (ch != " " && f == "B") o = o ch BS ch
			else if (ch != " " && f == "I") o = o "_" BS ch
			else o = o ch
			continue
		}
		if (S == "sgr" && f != cur) {
			if (cur != "R") o = o ESC "[0m"
			if (f == "B") o = o ESC "[" SB "m"
			else if (f == "I") o = o ESC "[" SI "m"
			cur = f
		}
		o = o ch
	}
	if (cur != "R") o = o ESC "[0m"
	print o
}
