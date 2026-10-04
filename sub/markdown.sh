#!/usr/bin/env bash
set -euo pipefail

# markdown.sh --- GitHub-flavored Markdown to standalone HTML, in bash and awk
#
# Renders input.md to input.md.html in the same directory (README.md renders
# to index.html, the directory index a static host serves for a bare request),
# preserves the source timestamp on the output via touch -r, and prints the
# output realpath. Markdown remains the master format: a document reads the
# same on GitHub and, rendered here, on a static host.
#
#   markdown.sh input.md       render to input.md.html, print its realpath
#   markdown.sh -f input.md    print the HTML fragment (no envelope) to stdout
#   markdown.sh -H             print markdown-help.md: usage, features, corpus
#   markdown.sh -c [corpus.md] run the regression corpus (default: built in)
#   markdown.sh -h             print usage
#
# markdown-help.md is the feature reference and the regression corpus at once:
# every case carries its markdown source, its expected HTML, and a live copy
# rendered in place, each traceable by T-number through HTML comments that
# pass into the rendered page. See markdown.sh -H.
#
# Functional source of this rewrite (behavior preserved, code replaced):
#   https://github.com/georgalis/pub/blob/f3839048129555e0a624f3f807cad720ece74dff/sub/markdown.sh
# which descends from knazarov/markdown.awk (BSD License).
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
# rev 6ac1a07f 20261003 174031 PDT Sat --- rev trap form, brace eval vs if/then
# org 6ac19d83 20261003 172747 PDT Sat --- container model rewrite, help corpus
#
# Portability: bash 3.2 or later (Darwin /bin/bash), and a POSIX awk as found
# in mawk 1.3.4, the one true awk (Darwin, NetBSD) and gawk. The awk program
# avoids brace intervals, gawk extensions, and apostrophes (it is quoted
# inline), and runs under LC_ALL=C so bytes compare as bytes on every
# platform; UTF-8 passes through untouched.

# --- Renderer ---
# render FRAG [file...]: FRAG 1 prints the body fragment only, 0 wraps it in
# the HTML document envelope. Reads the named files or stdin.
render() {
	local frag="$1"; shift
	LC_ALL=C awk -v frag="$frag" '
# =============================================================================
# markdown.awk --- block and inline parser
# =============================================================================
#
# Shape. Input is read whole into L[], then parsed twice over the same line
# array. Pass 1 collects link reference definitions, so a reference used
# before its definition still resolves; pass 2 renders. Side effects that must
# happen once (heading ids, contents slots, footnotes) are guarded by PASS == 2.
#
# Container model. parse_blocks() walks an array of lines and dispatches each
# block. A blockquote or a list item strips its own prefix (the > marker, or
# the item content indent) from its lines and calls parse_blocks() on the
# result, so a fence, table, list or quote nests inside any container through
# the same code that handles the top level. Block boundaries are decided by a
# small set of line predicates (is_blank, indent, is_atx, is_hr, is_quote,
# fence_open, list_marker, html_start, is_fndef, table_start) shared by every
# caller, and interrupts() names the lines that end a paragraph.
#
# Inline model. Each run of inline text is parsed in two passes. pass_a()
# replaces code spans, backslash escapes, autolinks, raw HTML, entities, inline
# anchors and hard breaks with placeholders (\001 n \002) so no later step can
# look inside them. pass_b() turns what remains into a node list of text,
# delimiter runs and brackets, then applies the CommonMark delimiter algorithm
# for emphasis, strong, strikethrough, links and images. restore() substitutes
# the placeholders last.
#
# Markers. \001 and \002 delimit inline placeholders; \003 n \003 marks a
# contents directive slot resolved in END. All three are removed from input.
#
# Output wraps content in an HTML document envelope referencing /default.css
# (site-wide baseline) and ./default.css (local override). No classes or
# divisions are emitted beyond those noted (language-x on fenced code, DPUB
# roles on footnotes); styling hooks are native elements.

# --- Initialization ---
# Regex fragments needing an apostrophe are built from Q, since the program is
# quoted inline by the shell.
BEGIN {
	N = 0; PHN = 0; TOCN = 0; toc_n = 0; fn_count = 0; TASKPFX = ""
	Q = "\047"
	PUNCT = "!\"#$%&" Q "()*+,-./:;<=>?@[\\]^_`{|}~"
	ATTR = "[ \t\n]+[A-Za-z_:][A-Za-z0-9_.:-]*([ \t\n]*=[ \t\n]*([^ \t\n\"" Q "=<>`]+|" Q "[^" Q "]*" Q "|\"[^\"]*\"))?"
	OPENTAG = "<[A-Za-z][A-Za-z0-9-]*(" ATTR ")*[ \t\n]*/?>"
	CLOSETAG = "</[A-Za-z][A-Za-z0-9-]*[ \t\n]*>"
	TAG_RE = "^(" OPENTAG "|" CLOSETAG ")"
	TAGLINE_RE = "^(" OPENTAG "|" CLOSETAG ")[ \t]*$"
	AUTO_RE = "^<[A-Za-z][A-Za-z0-9+.-]+:[^ \t\n<>]*>"
	MAIL_RE = "^<[A-Za-z0-9._%+-]+@[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*>"
	ENT_RE = "^&(#[0-9]+|#[xX][0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]*);"
	nb = split("address article aside base basefont blockquote body caption center col colgroup dd details dialog dir div dl dt fieldset figcaption figure footer form frame frameset h1 h2 h3 h4 h5 h6 head header hr html iframe legend li link main menu menuitem nav noframes ol optgroup option p param search section summary table tbody td tfoot th thead title tr track ul", BT, " ")
	for (i = 1; i <= nb; i++) BLOCKTAG[BT[i]] = 1
}

# --- Input ---
# Lines are stored whole; carriage returns and the private marker bytes are
# removed so they can never collide with placeholders.
{
	sub(/\r$/, "")
	gsub(/[\001\002\003]/, "")
	L[++N] = $0
}

# --- Document ---
# Front matter and a leading metadata block are skipped, the remaining lines
# parsed twice (references, then rendering), contents slots resolved against
# the complete heading record, and the result printed with its footnotes.
END {
	first = skip_metadata(skip_front_matter())
	n = 0
	for (i = first; i <= N; i++) D[++n] = L[i]
	PASS = 1; parse_blocks(D, n, 0)
	PASS = 2; html = resolve_contents(parse_blocks(D, n, 0))
	if (!frag) envelope_head()
	if (html != "") print html
	footnotes_section()
	if (!frag) { print "</body>"; print "</html>" }
}

# --- Front Matter Skip ---
# A --- delimited block at the head of the document is consumed when the line
# after the opening delimiter reads as key: value; it closes at --- or ...,
# or runs to end of input. A document opening on a thematic break is not
# front matter and renders normally.
function skip_front_matter(    i) {
	if (N >= 2 && L[1] ~ /^---[ \t]*$/ && L[2] ~ /^[^ \t]+:([ \t]|$)/) {
		for (i = 3; i <= N; i++)
			if (L[i] ~ /^(---|\.\.\.)[ \t]*$/)
				return i + 1
		return N + 1
	}
	return 1
}

# --- Metadata Skip ---
# A leading block of two or more "Key: value" lines (MultiMarkdown style) is
# consumed. A single line is not enough, so a first paragraph such as
# "Note: read this first." still renders.
function skip_metadata(s,    i, j) {
	i = s
	while (i <= N && is_blank(L[i])) i++
	j = i
	while (j <= N && L[j] ~ /^[A-Za-z][A-Za-z0-9_-]*:[ \t]+[^ \t]/) j++
	if (j - i >= 2 && (j > N || is_blank(L[j])))
		return j
	return s
}

# =============================================================================
# Line predicates
# =============================================================================

function is_blank(s) { return s ~ /^[ \t]*$/ }

# indent: leading whitespace width in columns, tabs to the next multiple of 4.
function indent(s,    i, c, col) {
	col = 0
	for (i = 1; i <= length(s); i++) {
		c = substr(s, i, 1)
		if (c == " ") col++
		else if (c == "\t") col += 4 - col % 4
		else break
	}
	return col
}

# expand_lead: leading tabs become spaces, so columns and characters agree.
function expand_lead(s,    k) {
	match(s, /^[ \t]*/); k = RLENGTH
	if (k == 0 || index(substr(s, 1, k), "\t") == 0) return s
	return spaces(indent(s)) substr(s, k + 1)
}

# strip_cols: remove n columns of indentation, or all of it when there is less.
function strip_cols(s, n,    t, k) {
	t = expand_lead(s)
	match(t, /^ */); k = RLENGTH
	return substr(t, (k >= n ? n : k) + 1)
}

function spaces(n,    r) { r = ""; while (n-- > 0) r = r " "; return r }
function rep(c, n,    r) { r = ""; while (n-- > 0) r = r c; return r }
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function add(out, x) { if (x == "") return out; return (out == "") ? x : out "\n" x }
function join_arr(P, n,    k, r) { r = ""; for (k = 1; k <= n; k++) r = (k == 1) ? P[k] : r "\n" P[k]; return r }

# Thematic break: three or more of one marker (*, -, _), spaces allowed.
function is_hr(s,    t) {
	if (indent(s) > 3) return 0
	t = s; gsub(/[ \t]/, "", t)
	return t ~ /^\*\*\*+$/ || t ~ /^---+$/ || t ~ /^___+$/
}

# ATX heading: one to six # followed by whitespace or end of line.
function is_atx(s,    t) {
	if (indent(s) > 3) return 0
	t = s; sub(/^ +/, "", t)
	if (!match(t, /^#+([ \t]|$)/)) return 0
	match(t, /^#+/)
	return RLENGTH <= 6
}

function is_quote(s) { return indent(s) < 4 && s ~ /^[ \t]*>/ }

# Fence opener: three or more backticks or tildes; sets FCH (char), FLEN
# (run length), FIND (indent) and FINFO (info string). A backtick fence info
# string may not contain a backtick, which would make it an inline code span.
function fence_open(s,    t) {
	if (indent(s) > 3) return 0
	t = expand_lead(s); match(t, /^ */); FIND = RLENGTH; t = substr(t, FIND + 1)
	if (match(t, /^```+/)) FCH = "`"
	else if (match(t, /^~~~+/)) FCH = "~"
	else return 0
	FLEN = RLENGTH; FINFO = trim(substr(t, FLEN + 1))
	if (FCH == "`" && index(FINFO, "`")) return 0
	return 1
}

# Fence closer: the same character, at least as long, trailing space allowed.
function fence_close(s, ch, len,    t, u) {
	if (indent(s) > 3) return 0
	t = trim(s)
	if (length(t) < len || substr(t, 1, 1) != ch) return 0
	u = t; gsub(ch, "", u)
	return u == ""
}

# List item marker: sets LTYPE (ul|ol), LCH (bullet or delimiter), LSTART,
# LW (content column), LREST (content after the marker) and LEMPTY. Content
# column is the marker end plus 1 to 4 spaces; with 5 or more the content is
# indented code and the column is the marker end plus one.
function list_marker(s,    ind, t, m, rest, col, k, c, sp) {
	ind = indent(s)
	if (ind > 3 || is_hr(s)) return 0
	t = substr(expand_lead(s), ind + 1)
	if (t ~ /^[-+*]/) { LTYPE = "ul"; LCH = substr(t, 1, 1); m = 1 }
	else if (match(t, /^[0-9]+[.)]/) && RLENGTH <= 10) {
		LTYPE = "ol"; LCH = substr(t, RLENGTH, 1); LSTART = substr(t, 1, RLENGTH - 1) + 0; m = RLENGTH
	}
	else return 0
	rest = substr(t, m + 1)
	if (rest != "" && rest !~ /^[ \t]/) return 0
	col = ind + m; sp = 0; k = 1
	while (k <= length(rest) && ((c = substr(rest, k, 1)) == " " || c == "\t")) {
		sp += (c == "\t") ? 4 - (col + sp) % 4 : 1; k++
	}
	rest = substr(rest, k)
	LEMPTY = (rest == "")
	if (LEMPTY) { LW = ind + m + 1; LREST = ""; return 1 }
	if (sp > 4) { LW = ind + m + 1; LREST = spaces(sp - 1) rest }
	else { LW = ind + m + sp; LREST = rest }
	return 1
}

# HTML block start, CommonMark types 1, 2, 6 and 7. Type 1 (script, pre,
# style, textarea) runs to its closing tag, type 2 (comment) to -->, types 6
# (block-level tag) and 7 (any complete tag alone on its line) to a blank
# line. Type 7 cannot interrupt a paragraph. Sets HTAG for type 1.
function html_start(s,    t, tl, tag, rest) {
	if (indent(s) > 3) return 0
	t = s; sub(/^ +/, "", t); tl = tolower(t)
	if (match(tl, /^<(script|pre|style|textarea)([ \t>]|$)/)) {
		HTAG = substr(tl, 2, RLENGTH - 1); sub(/[ \t>]$/, "", HTAG); return 1
	}
	if (substr(t, 1, 4) == "<!--") return 2
	if (match(tl, /^<\/?[a-z][a-z0-9-]*/)) {
		tag = substr(tl, 2, RLENGTH - 1); sub(/^\//, "", tag); rest = substr(tl, RLENGTH + 1)
		if ((tag in BLOCKTAG) && (rest == "" || rest ~ /^([ \t>]|\/>)/)) return 6
	}
	if (t ~ TAGLINE_RE) return 7
	return 0
}

# Footnote definition: [^label]: at block level.
function is_fndef(s) { return indent(s) < 4 && s ~ /^ *\[\^[^\] \t\[]+\]:/ }

# Table start: a header line and a delimiter row of matching cell count.
function table_start(h, d,    C, nh, nd, k) {
	if (indent(h) > 3 || indent(d) > 3 || index(d, "|") == 0 || is_blank(h)) return 0
	nd = split_row(d, C)
	for (k = 1; k <= nd; k++) if (C[k] !~ /^:?-+:?$/) return 0
	nh = split_row(h, C)
	return nh == nd
}

# interrupts: lines that end a paragraph (and refuse lazy continuation) without
# a blank line. Only a non-empty bullet or an ordered item numbered 1 may
# interrupt a paragraph, so "1984. A good year." continues the text above it.
# A footnote definition interrupts too, an extension: consecutive definitions
# separate without blank lines.
function interrupts(t,    h) {
	if (indent(t) > 3) return 0
	if (is_atx(t) || is_hr(t) || is_quote(t) || fence_open(t) || is_fndef(t)) return 1
	h = html_start(t); if (h && h != 7) return 1
	if (list_marker(t) && !LEMPTY && (LTYPE == "ul" || LSTART == 1)) return 1
	return 0
}

# =============================================================================
# Block parser
# =============================================================================

# parse_blocks: render A[1..n] as a sequence of blocks. With tight set,
# paragraphs are emitted without <p>, as in a tight list item.
function parse_blocks(A, n, tight,    out, i, s, t, P, np, k, ch, len, fi, info, lang, ht, lvl, txt, qf, qch, qlen) {
	out = ""; i = 1
	while (i <= n) {
		s = A[i]
		if (is_blank(s)) { i++; continue }

		# indented code: four or more columns; never inside a paragraph, since
		# the paragraph loop below absorbs indented continuation lines
		if (indent(s) >= 4) {
			np = 0; split("", P)
			while (i <= n && (indent(A[i]) >= 4 || is_blank(A[i]))) { P[++np] = strip_cols(A[i], 4); i++ }
			while (np > 0 && is_blank(P[np])) np--
			out = add(out, "<pre><code>" esc(join_arr(P, np)) "\n</code></pre>")
			continue
		}

		# fenced code: runs to a closing fence of the same character and at
		# least the same length, or to the end of the container. Content lines
		# lose up to the opening fence indent. The first info word becomes
		# class="language-x" for CSS or JS highlighters.
		if (fence_open(s)) {
			ch = FCH; len = FLEN; fi = FIND; info = FINFO
			np = 0; split("", P); i++
			while (i <= n && !fence_close(A[i], ch, len)) { P[++np] = strip_cols(A[i], fi); i++ }
			if (i <= n) i++
			lang = info; sub(/[ \t].*$/, "", lang)
			txt = esc(join_arr(P, np)); if (np > 0) txt = txt "\n"
			out = add(out, "<pre><code" ((lang != "") ? " class=\"language-" esc_attr(lang) "\"" : "") ">" txt "</code></pre>")
			continue
		}

		if (is_atx(s)) { out = add(out, heading_atx(s)); i++; continue }
		if (is_hr(s)) { out = add(out, "<hr />"); i++; continue }

		# blockquote: > lines lose the marker and one space; a non-blank line
		# without > continues the quote lazily when it would continue a
		# paragraph (not after a blank > line, not inside an open fence)
		if (is_quote(s)) {
			np = 0; split("", P); qf = 0
			while (i <= n) {
				t = A[i]
				if (is_quote(t)) { t = expand_lead(t); sub(/^ *>/, "", t); sub(/^ /, "", t) }
				else if (!(np > 0 && !qf && !is_blank(t) && !is_blank(P[np]) && !interrupts(t))) break
				P[++np] = t; i++
				if (!qf && fence_open(t)) { qf = 1; qch = FCH; qlen = FLEN }
				else if (qf && fence_close(t, qch, qlen)) qf = 0
			}
			out = add(out, "<blockquote>\n" parse_blocks(P, np, 0) "\n</blockquote>")
			continue
		}

		if (list_marker(s)) { out = add(out, parse_list(A, n, i)); i = LIST_END; continue }

		# HTML block: passed through verbatim. A one-line comment that reads as
		# a contents directive claims a slot instead.
		if ((ht = html_start(s))) {
			np = 0; split("", P)
			if (ht <= 2) {
				while (i <= n) {
					P[++np] = A[i]; i++
					if (ht == 2 && index(P[np], "-->")) break
					if (ht == 1 && index(tolower(P[np]), "</" HTAG ">")) break
				}
			}
			else while (i <= n && !is_blank(A[i])) { P[++np] = A[i]; i++ }
			txt = join_arr(P, np)
			if (ht == 2 && np == 1 && contents_parse(trim(txt))) out = add(out, contents_slot())
			else out = add(out, txt)
			continue
		}

		if (is_fndef(s)) { parse_fndef(A, n, i); i = FN_END; continue }
		if (i < n && table_start(s, A[i + 1])) { out = add(out, parse_table(A, n, i)); i = TBL_END; continue }

		# link reference definitions open a paragraph and are consumed; pass 1
		# records them so references anywhere in the document resolve
		if (is_refdef(s)) {
			if (PASS == 1 && !(RD_LABEL in RURL)) { RURL[RD_LABEL] = RD_URL; RTITLE[RD_LABEL] = RD_TITLE }
			i++; continue
		}

		# paragraph: runs to a blank line or an interrupting line. A setext
		# underline (=== or ---) turns every line so far into a heading.
		np = 0; split("", P); lvl = 0
		P[++np] = s; i++
		while (i <= n) {
			t = A[i]
			if (is_blank(t)) break
			if (indent(t) < 4 && (t ~ /^ *=+[ \t]*$/ || t ~ /^ *-+[ \t]*$/)) { lvl = (t ~ /=/) ? 1 : 2; i++; break }
			if (interrupts(t)) break
			if (i < n && table_start(t, A[i + 1])) break
			P[++np] = t; i++
		}
		for (k = 1; k <= np; k++) sub(/^[ \t]+/, "", P[k])
		sub(/[ \t]+$/, "", P[np])
		txt = join_arr(P, np)
		if (lvl) { out = add(out, make_heading(lvl, txt)); continue }
		txt = parse_inline(txt)
		if (TASKPFX != "") { txt = TASKPFX txt; TASKPFX = "" }
		out = add(out, tight ? txt : "<p>" txt "</p>")
	}
	return out
}

# --- Lists ---
# parse_list: one list of same-type items (same bullet character, or same
# ordered delimiter) starting at A[i]; sets LIST_END. Each item collects the
# lines indented to its content column, with blank lines between them, plus
# lazy paragraph continuation lines; the item content is then parsed as a
# document of its own. An ordered list numbered from N > 1 carries start="N".
#
# Loose and tight follow GFM: a list is loose when a blank line separates two
# items, or when an item holds two blocks with a blank line between them.
# Loose items wrap paragraphs in <p>; tight items do not.
#
# A task item ([ ] or [x] then text, GFM extension) gets a disabled checkbox
# before its first paragraph text.
function parse_list(A, n, i,    end, typ, ch, start, loose, it, k, m, W, t, emp, blanks, fq, fch, flen, IL, IN, IA, body, out, tag) {
	list_marker(A[i]); typ = LTYPE; ch = LCH; start = LSTART
	loose = 0; it = 0
	while (i <= n && list_marker(A[i]) && LTYPE == typ && LCH == ch) {
		it++; W = LW; emp = LEMPTY; k = 0; fq = 0; blanks = 0
		if (!emp) {
			IL[it, ++k] = LREST
			if (fence_open(LREST)) { fq = 1; fch = FCH; flen = FLEN }
		}
		i++
		# an item may open with at most one blank line: an empty marker line
		# followed by a blank line is an empty item
		if (emp && i <= n && is_blank(A[i])) {
			while (i <= n && is_blank(A[i])) { i++; blanks++ }
		}
		else while (i <= n) {
			t = A[i]
			if (is_blank(t)) { blanks++; i++; continue }
			if (indent(t) >= W) {
				for (; blanks > 0; blanks--) IL[it, ++k] = ""
				t = strip_cols(t, W); IL[it, ++k] = t; i++
				if (!fq && fence_open(t)) { fq = 1; fch = FCH; flen = FLEN }
				else if (fq && fence_close(t, fch, flen)) fq = 0
				continue
			}
			if (blanks > 0 || k == 0 || fq) break
			if (list_marker(t) || interrupts(t)) break
			IL[it, ++k] = t; i++           # lazy paragraph continuation
		}
		IN[it] = k
		if (blanks > 0 && i <= n && list_marker(A[i]) && LTYPE == typ && LCH == ch) loose = 1
		if (!loose && item_has_gap(IL, it, k)) loose = 1
	}
	end = i     # LIST_END is set last: rendering items recurses into parse_list

	tag = (typ == "ul") ? "ul" : "ol"
	out = "<" tag ((tag == "ol" && start != 1) ? " start=\"" start "\"" : "") ">"
	for (m = 1; m <= it; m++) {
		split("", IA); k = IN[m]
		for (t = 1; t <= k; t++) IA[t] = IL[m, t]
		TASKPFX = ""
		if (k > 0 && IA[1] ~ /^\[[ xX]\][ \t]+[^ \t]/) {
			TASKPFX = "<input type=\"checkbox\"" ((substr(IA[1], 2, 1) == " ") ? "" : " checked=\"\"") " disabled=\"\" /> "
			IA[1] = substr(IA[1], 4); sub(/^[ \t]+/, "", IA[1])
		}
		body = parse_blocks(IA, k, !loose)
		TASKPFX = ""
		if (loose && body != "") out = out "\n<li>\n" body "\n</li>"
		else out = out "\n<li>" body "</li>"
	}
	LIST_END = end
	return out "\n</" tag ">"
}

# item_has_gap: does the item directly hold two blocks separated by a blank
# line? Blank lines inside a fence, or between the items of a nested list,
# belong to those blocks and do not count.
function item_has_gap(IL, it, k,    j, t, inl, lw, pend, seen, fq, fch, flen) {
	inl = 0; pend = 0; seen = 0; fq = 0
	for (j = 1; j <= k; j++) {
		t = IL[it, j]
		if (fq) { if (fence_close(t, fch, flen)) fq = 0; continue }
		if (is_blank(t)) { if (seen) pend = 1; continue }
		if (pend) {
			if (!(inl && (indent(t) >= lw || list_marker(t)))) return 1
			pend = 0
		}
		seen = 1
		if (list_marker(t)) { if (!inl || indent(t) < lw) { inl = 1; lw = LW } }
		else if (!inl && fence_open(t)) { fq = 1; fch = FCH; flen = FLEN }
	}
	return 0
}

# --- Tables ---
# GFM pipe table: header row, delimiter row, then body rows until a blank line
# or a block opener. Leading and trailing pipes are optional. An escaped \|
# is a literal pipe in the cell, including inside a code span; an unescaped
# pipe always divides cells, as on GitHub. Alignment comes from colons in the
# delimiter row and is written as align= on each cell, with no CSS dependency:
#   :---  left    ---:  right    :---:  center    ---  none
function parse_table(A, n, i,    C, AL, na, k, t, out) {
	na = split_row(A[i + 1], C)
	for (k = 1; k <= na; k++) {
		t = C[k]
		AL[k] = (t ~ /^:.*:$/) ? "center" : ((t ~ /:$/) ? "right" : ((t ~ /^:/) ? "left" : ""))
	}
	out = "<table>\n<thead>\n" table_row(A[i], AL, na, "th") "\n</thead>"
	i += 2
	if (i <= n && !is_blank(A[i]) && !interrupts(A[i])) {
		out = out "\n<tbody>"
		while (i <= n && !is_blank(A[i]) && !interrupts(A[i])) { out = out "\n" table_row(A[i], AL, na, "td"); i++ }
		out = out "\n</tbody>"
	}
	TBL_END = i     # cells are inline only, so no recursion can intervene
	return out "\n</table>"
}

function table_row(s, AL, na, tag,    C, nc, k, r) {
	nc = split_row(s, C); r = "<tr>"
	for (k = 1; k <= na; k++)
		r = r "<" tag ((AL[k] != "") ? " align=\"" AL[k] "\"" : "") ">" ((k <= nc) ? parse_inline(C[k]) : "") "</" tag ">"
	return r "</tr>"
}

function split_row(s, C,    t, i, c, n, cell) {
	split("", C)
	t = trim(s)
	if (substr(t, 1, 1) == "|") t = substr(t, 2)
	if (length(t) > 0 && substr(t, length(t), 1) == "|" && substr(t, length(t) - 1, 1) != "\\")
		t = substr(t, 1, length(t) - 1)
	n = 0; cell = ""
	for (i = 1; i <= length(t); i++) {
		c = substr(t, i, 1)
		if (c == "\\" && substr(t, i + 1, 1) == "|") { cell = cell "|"; i++ }
		else if (c == "|") { C[++n] = trim(cell); cell = "" }
		else cell = cell c
	}
	C[++n] = trim(cell)
	return n
}

# --- Link Reference Definitions ---
# [label]: url "optional title" on one line; sets RD_LABEL (normalized),
# RD_URL and RD_TITLE. The title may be quoted with ", an apostrophe, or ().
function is_refdef(s,    t, lab, rest, url, title, c, cl) {
	if (indent(s) > 3) return 0
	t = s; sub(/^ +/, "", t)
	if (!match(t, /^\[[^\]]+\]:/)) return 0
	lab = substr(t, 2, RLENGTH - 3)
	if (substr(lab, 1, 1) == "^" || trim(lab) == "") return 0
	rest = substr(t, RLENGTH + 1); sub(/^[ \t]+/, "", rest)
	if (rest == "") return 0
	if (substr(rest, 1, 1) == "<") {
		if (!match(rest, /^<[^<>]*>/)) return 0
		url = substr(rest, 2, RLENGTH - 2)
	}
	else { match(rest, /^[^ \t]+/); url = substr(rest, 1, RLENGTH) }
	rest = trim(substr(rest, RLENGTH + 1))
	title = ""
	if (rest != "") {
		c = substr(rest, 1, 1); cl = (c == "(") ? ")" : c
		if (!(c == "\"" || c == Q || c == "(") || length(rest) < 2 || substr(rest, length(rest), 1) != cl) return 0
		title = substr(rest, 2, length(rest) - 2)
	}
	RD_LABEL = normlabel(lab); RD_URL = url; RD_TITLE = title
	return 1
}

function normlabel(s) { s = tolower(s); gsub(/[ \t\n]+/, " ", s); return trim(s) }

# --- Footnotes ---
# [^label]: text, continued by lazy lines until a blank line or a block opener,
# and by further blocks indented four columns after a blank line. The body is
# parsed as a document of its own. Definitions are collected in definition
# order and emitted before </body> by footnotes_section(); the first
# definition of a label wins. Sets FN_END.
function parse_fndef(A, n, i,    s, lab, P, np, j, k, body) {
	s = A[i]; sub(/^ +/, "", s)
	match(s, /^\[\^[^\]]+\]:/)
	lab = substr(s, 3, RLENGTH - 4)
	s = substr(s, RLENGTH + 1); sub(/^[ \t]+/, "", s)
	np = 0; split("", P); P[++np] = s; i++
	while (i <= n && !is_blank(A[i]) && !interrupts(A[i])) { P[++np] = A[i]; i++ }
	while (i <= n) {
		j = i; while (j <= n && is_blank(A[j])) j++
		if (j > n || j == i || indent(A[j]) < 4) break
		for (k = i; k < j; k++) P[++np] = ""
		i = j
		while (i <= n && !is_blank(A[i]) && indent(A[i]) >= 4) { P[++np] = strip_cols(A[i], 4); i++ }
	}
	body = parse_blocks(P, np, 0)
	FN_END = i     # set after the body parse, which may recurse
	if (PASS == 2 && !(lab in FN_SEEN)) { FN_SEEN[lab] = 1; fn_ids[++fn_count] = lab; fn_text[lab] = body }
}

# Footnote markup carries its brackets and its [^label]: prefix as literal
# text in a bare <span>, not as generated content, since ::before/::after
# content is excluded from a copy selection in every major browser; a reader
# copying a note gets the markdown source syntax back. No backreference is
# emitted: the reader returns by browser back navigation, which restores the
# scroll position however many times a label is cited, and leaves no
# duplicate ids.
function footnotes_section(    i, id) {
	if (fn_count == 0) return
	print "<section id=\"footnotes\" role=\"doc-endnotes\">"
	print "<hr />"
	print "<ol>"
	for (i = 1; i <= fn_count; i++) {
		id = fn_ids[i]
		print "<li id=\"fn-" esc_attr(id) "\" role=\"doc-endnote\"><span>[^" esc(id) "]: </span>" fn_text[id] "</li>"
	}
	print "</ol>"
	print "</section>"
}

# =============================================================================
# Headings, anchors and contents
# =============================================================================

function heading_atx(s,    t, lvl) {
	t = s; sub(/^ +/, "", t)
	match(t, /^#+/); lvl = RLENGTH
	t = trim(substr(t, lvl + 1))
	if (t ~ /^#+$/) t = ""
	else sub(/[ \t]+#+$/, "", t)
	return make_heading(lvl, trim(t))
}

# make_heading: an explicit {#custom-id} suffix sets the id; otherwise the id
# is the GitHub slug of the rendered heading text, made unique by -1, -2
# suffixes as GitHub does. Every heading is recorded for contents directives.
function make_heading(lvl, t,    id, content) {
	id = ""
	if (match(t, /[ \t]*\{#[^} \t]+\}$/)) {
		id = substr(t, RSTART, RLENGTH); t = substr(t, 1, RSTART - 1)
		sub(/^[ \t]*\{#/, "", id); sub(/\}$/, "", id)
	}
	content = parse_inline(t)
	if (PASS != 2) return ""
	if (id == "") id = unique_id(slugify(content))
	else if (!(id in SEEN)) SEEN[id] = 0
	record_heading(lvl, id, content)
	return "<h" lvl " id=\"" esc_attr(id) "\">" content "</h" lvl ">"
}

# slugify: the GitHub (github-slugger) algorithm over the rendered text: tags
# and entities removed, lowercase, keep letters, digits, - and _, each space
# becomes a hyphen. Hyphen runs are not collapsed. Bytes above 127 are kept,
# so UTF-8 letters survive; UTF-8 punctuation is kept too, a known divergence.
# A line break in a setext heading counts as a space.
function slugify(h,    s, out, i, c) {
	s = h; gsub(/<[^>]*>/, "", s); gsub(/&[A-Za-z0-9#]+;/, "", s); gsub(/\n/, " ", s)
	s = tolower(s); out = ""
	for (i = 1; i <= length(s); i++) {
		c = substr(s, i, 1)
		if (c ~ /[a-z0-9_-]/ || c > "\177") out = out c
		else if (c == " ") out = out "-"
	}
	return out
}

function unique_id(base,    id, k) {
	if (!(base in SEEN)) { SEEN[base] = 0; return base }
	k = SEEN[base]
	do { k++; id = base "-" k } while (id in SEEN)
	SEEN[base] = k; SEEN[id] = 0
	return id
}

function record_heading(lvl, id, content,    t) {
	t = content; gsub(/<a [^>]*>/, "", t); gsub(/<\/a>/, "", t)
	toc_n++; toc_lvl[toc_n] = lvl; toc_id[toc_n] = id; toc_txt[toc_n] = t
}

# --- Contents Directive ---
# <!--contents [lo] [hi] [pre="markdown"] [post="markdown"]--> emits a table
# of contents of the headings that follow it. No level argument indexes
# levels 1 to 3; one sets the deepest level; two set both bounds. pre and post
# are markdown rendered before and after the index (\n in a value separates
# lines), so a "## Contents" heading and a closing --- live inside the comment
# and stay invisible on GitHub, which supplies its own outline:
#   <!--contents 2 3 pre="## Contents" post="---"-->
# Forward scope is what makes the directive self-selecting: the title, any
# foreword, and the pre heading itself (recorded before the scope begins) are
# left out with no exclusion rule. When no heading falls in the window,
# nothing is emitted, pre and post included. Values containing hyphens must be
# quoted so they never touch the closing -->.
function contents_parse(txt,    body, ns, NS) {
	if (txt !~ /^<!--[ \t]*contents([ \t].*)?-->$/) return 0
	body = txt; sub(/^<!--[ \t]*contents/, "", body); sub(/-->$/, "", body)
	CT_PRE = kv(body, "pre"); body = KV_REST
	CT_POST = kv(body, "post"); body = KV_REST
	if (body !~ /^[ \t0-9]*$/) return 0
	ns = split(body, NS)
	CT_LO = 1; CT_HI = 3
	if (ns == 1) CT_HI = NS[1] + 0
	else if (ns == 2) { CT_LO = NS[1] + 0; CT_HI = NS[2] + 0 }
	else if (ns > 2) return 0
	return 1
}

function kv(body, key,    re, v) {
	KV_REST = body
	re = "[ \t]" key "=(\"[^\"]*\"|" Q "[^" Q "]*" Q ")"
	if (!match(body, re)) return ""
	v = substr(body, RSTART + length(key) + 3, RLENGTH - length(key) - 4)
	KV_REST = substr(body, 1, RSTART - 1) " " substr(body, RSTART + RLENGTH)
	return v
}

function contents_slot(    slot, lo, hi, pre, post) {
	if (PASS != 2) return ""
	lo = CT_LO; hi = CT_HI; pre = CT_PRE; post = CT_POST
	slot = ++TOCN
	TLO[slot] = lo; THI[slot] = hi
	TPRE[slot] = render_value(pre)
	TFROM[slot] = toc_n
	TPOST[slot] = render_value(post)
	return "\003" slot "\003"
}

function render_value(v,    X, nx) {
	if (v == "") return ""
	nx = split(v, X, "\\\\n")
	return parse_blocks(X, nx, 0)
}

function resolve_contents(h,    out, slot, nav, r) {
	out = ""
	while (match(h, /\003[0-9]+\003/)) {
		slot = substr(h, RSTART + 1, RLENGTH - 2) + 0
		nav = make_toc(TLO[slot], THI[slot], TFROM[slot])
		r = (nav == "") ? "" : add(add(TPRE[slot], nav), TPOST[slot])
		out = out substr(h, 1, RSTART - 1) r
		h = substr(h, RSTART + RLENGTH)
		if (r == "" && substr(h, 1, 1) == "\n") h = substr(h, 2)     # leave no blank line
	}
	return out h
}

# make_toc: nested <ul> in a bare <nav>. A level outside the window is skipped
# entirely, so its subordinate headings rise a level; nesting is normalized to
# the shallowest level present. Link text is the rendered heading with anchor
# elements removed, so no <a> nests inside an entry link.
function make_toc(lo, hi, from,    i, base, lvl, cur, result) {
	base = 0
	for (i = from + 1; i <= toc_n; i++)
		if (toc_lvl[i] >= lo && toc_lvl[i] <= hi && (base == 0 || toc_lvl[i] < base))
			base = toc_lvl[i]
	if (base == 0) return ""
	result = "<nav>"; cur = 0
	for (i = from + 1; i <= toc_n; i++) {
		if (toc_lvl[i] < lo || toc_lvl[i] > hi) continue
		lvl = toc_lvl[i] - base + 1
		if (cur == 0) { result = result "\n<ul>"; cur = 1 }
		else if (lvl > cur) { while (lvl > cur) { result = result "\n<ul>"; cur++ } }
		else {
			result = result "</li>"
			while (lvl < cur) { result = result "\n</ul></li>"; cur-- }
		}
		result = result "\n<li><a href=\"#" esc_attr(toc_id[i]) "\">" toc_txt[i] "</a>"
	}
	result = result "</li>"
	while (cur > 1) { result = result "\n</ul></li>"; cur-- }
	return result "\n</ul>\n</nav>"
}

# =============================================================================
# Inline parser
# =============================================================================

function esc(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); return s }
function esc_attr(s) { s = esc(s); gsub(/"/, "\\&quot;", s); return s }
function is_ws(c) { return c == " " || c == "\t" || c == "\n" || c == "" }
function is_punct(c) { return c != "" && (index(PUNCT, c) > 0 || c == "\001" || c == "\002") }

function parse_inline(s) {
	if (PASS != 2) return ""
	split("", PH); PHN = 0
	return restore(pass_b(pass_a(s)))
}

function ph(h) { PH[++PHN] = h; return "\001" PHN "\002" }

function restore(s,    out) {
	out = ""
	while (match(s, /\001[0-9]+\002/)) {
		out = out substr(s, 1, RSTART - 1) PH[substr(s, RSTART + 1, RLENGTH - 2) + 0]
		s = substr(s, RSTART + RLENGTH)
	}
	return out s
}

# --- Pass A: protected spans ---
# Left to right, so the leftmost construct wins as CommonMark requires:
#   `code`        a backtick run closes at the next run of the same length;
#                 newlines become spaces, one space trimmed from each side
#   \x            backslash escape of any ASCII punctuation; \ at line end
#                 is a hard break
#   <!-- -->      inline comment passthrough
#   <scheme:x>    autolink;  <a@b.c>  email autolink
#   <tag ...>     raw inline HTML passthrough (quoted, unquoted and boolean
#                 attributes, self-closing, hyphenated names)
#   &name;        entity passthrough (named, decimal, hex); a bare & is escaped
#   {#id}         inline anchor, a zero-width <a id="id"></a>
#   two spaces    before a newline: hard break <br />
function pass_a(s,    out, i, n, c, d, len, j, code, t, k, u) {
	n = length(s); out = ""; i = 1
	while (i <= n) {
		c = substr(s, i, 1)
		if (c == "`") {
			len = 1; while (substr(s, i + len, 1) == "`") len++
			j = find_run(s, i + len, len)
			if (j) {
				code = substr(s, i + len, j - i - len); gsub(/\n/, " ", code)
				if (code ~ /^ .* $/ && code !~ /^ *$/) code = substr(code, 2, length(code) - 2)
				out = out ph("<code>" esc(code) "</code>"); i = j + len
			}
			else { out = out substr(s, i, len); i += len }
			continue
		}
		if (c == "\\") {
			d = substr(s, i + 1, 1)
			if (d == "\n") { out = out ph("<br />") "\n"; i += 2; continue }
			if (d != "" && index(PUNCT, d)) { out = out ph(esc(d)); i += 2; continue }
			out = out c; i++; continue
		}
		if (c == "<") {
			t = substr(s, i)
			if (substr(t, 1, 4) == "<!--" && (k = index(substr(t, 5), "-->"))) {
				out = out ph(substr(t, 1, k + 6)); i += k + 6; continue
			}
			if (match(t, AUTO_RE)) {
				u = substr(t, 2, RLENGTH - 2)
				out = out ph("<a href=\"" esc_attr(u) "\">" esc(u) "</a>"); i += RLENGTH; continue
			}
			if (match(t, MAIL_RE)) {
				u = substr(t, 2, RLENGTH - 2)
				out = out ph("<a href=\"mailto:" esc_attr(u) "\">" esc(u) "</a>"); i += RLENGTH; continue
			}
			if (match(t, TAG_RE)) { out = out ph(substr(t, 1, RLENGTH)); i += RLENGTH; continue }
			out = out c; i++; continue
		}
		if (c == "&" && match(substr(s, i), ENT_RE)) { out = out ph(substr(s, i, RLENGTH)); i += RLENGTH; continue }
		if (c == "{" && match(substr(s, i), /^\{#[A-Za-z][A-Za-z0-9._:-]*\}/)) {
			out = out ph("<a id=\"" substr(s, i + 2, RLENGTH - 3) "\"></a>"); i += RLENGTH; continue
		}
		if (c == "\n") {
			k = 0; while (k < length(out) && substr(out, length(out) - k, 1) == " ") k++
			out = substr(out, 1, length(out) - k) ((k >= 2) ? ph("<br />") : "") "\n"
			i++; continue
		}
		out = out c; i++
	}
	return out
}

function find_run(s, from, len,    i, k, n) {
	n = length(s)
	for (i = from; i <= n; i++) {
		if (substr(s, i, 1) != "`") continue
		k = 0; while (substr(s, i + k, 1) == "`") k++
		if (k == len) return i
		i += k - 1
	}
	return 0
}

# --- Pass B: delimiters and brackets ---
# Node list: NT[k] is txt, delim or none; NV[k] the HTML text. A delimiter run
# of *, _ or ~ records its character NC, remaining count NN, original count
# NO, and whether it can open (DOP) or close (DCL) by the CommonMark flanking
# rules; _ additionally refuses to open or close inside a word, which keeps
# snake_case and URLs intact. Brackets push a [ or ![ text node on the
# bracket stack BRK; a ] tries to close the top bracket as a link or image.
#
# Extensions handled here:
#   [^label]          footnote reference, rendered as source text:
#                     <a href="#fn-label" role="doc-noteref">
#                       <span>[^</span>label<span>]</span></a>
#                     The brackets are literal text in a bare <span>, for the
#                     copy fidelity noted at footnotes_section(); a stylesheet
#                     may hide the spans for a superscript look.
#   ~x~ ~~x~~         strikethrough (GFM), runs of equal length
#   www.x  https://x  bare autolinks (GFM), trailing punctuation trimmed
function pass_b(s,    n, i, c, j, len, b, a, lf, rf, op, cl, k, r, u, run) {
	K = 0; BS = 0; TBUF = ""
	n = length(s); i = 1
	while (i <= n) {
		c = substr(s, i, 1)
		if (c == "\001") { j = index(substr(s, i), "\002"); TBUF = TBUF substr(s, i, j); i += j; continue }
		if (c == "*" || c == "_" || c == "~") {
			len = 1; while (substr(s, i + len, 1) == c) len++
			b = (i > 1) ? substr(s, i - 1, 1) : " "
			a = (i + len <= n) ? substr(s, i + len, 1) : " "
			lf = !is_ws(a) && (!is_punct(a) || is_ws(b) || is_punct(b))
			rf = !is_ws(b) && (!is_punct(b) || is_ws(a) || is_punct(a))
			if (c == "_") { op = lf && (!rf || is_punct(b)); cl = rf && (!lf || is_punct(a)) }
			else { op = lf; cl = rf }
			if (c == "~" && len > 2) op = cl = 0
			run = substr(s, i, len)
			if (op || cl) {
				flush_text(); k = new_node("delim", run)
				NC[k] = c; NN[k] = len; NO[k] = len; DOP[k] = op; DCL[k] = cl; DACT[k] = 1
			}
			else TBUF = TBUF run
			i += len; continue
		}
		if (c == "[" && match(substr(s, i), /^\[\^[^\] \t\n\[]+\]/)) {
			u = substr(s, i + 2, RLENGTH - 3)
			TBUF = TBUF "<a href=\"#fn-" esc_attr(u) "\" role=\"doc-noteref\"><span>[^</span>" esc(u) "<span>]</span></a>"
			i += RLENGTH; continue
		}
		if (c == "[" || (c == "!" && substr(s, i + 1, 1) == "[")) {
			flush_text(); k = new_node("txt", (c == "!") ? "![" : "[")
			BIMG[k] = (c == "!"); BACT[k] = 1; BPOS[k] = i + ((c == "!") ? 2 : 1)
			BRK[++BS] = k
			i += (c == "!") ? 2 : 1; continue
		}
		if (c == "]") {
			flush_text()
			r = close_bracket(s, i)
			if (r) { i = r; continue }
			TBUF = TBUF "]"; i++; continue
		}
		if ((c == "h" || c == "w") && (i == 1 || index(" \t\n*_~(", substr(s, i - 1, 1))) && !in_link() && (u = bare_url(substr(s, i))) != "") {
			TBUF = TBUF "<a href=\"" esc_attr((u ~ /^www\./) ? "http://" u : u) "\">" esc(u) "</a>"
			i += length(u); continue
		}
		TBUF = TBUF (index("&<>", c) ? esc(c) : c); i++
	}
	flush_text()
	process_emphasis(0)
	return render_nodes(1, K)
}

function new_node(type, val) { K++; NT[K] = type; NV[K] = val; NBEF[K] = ""; NAFT[K] = ""; DACT[K] = 0; return K }
function flush_text() { if (TBUF != "") { new_node("txt", TBUF); TBUF = "" } }
function in_link(    k) { for (k = 1; k <= BS; k++) if (BACT[BRK[k]] && !BIMG[BRK[k]]) return 1; return 0 }

function render_nodes(a, b,    k, out) {
	out = ""
	for (k = a; k <= b; k++) {
		if (NT[k] == "txt") out = out NV[k]
		else if (NT[k] == "delim") out = out NBEF[k] rep(NC[k], NN[k]) NAFT[k]
	}
	return out
}

# process_emphasis: the CommonMark algorithm over delimiter nodes above
# bottom. For each closer, look back for the nearest compatible opener (same
# character; the rule of three for runs that can both open and close; equal
# length for ~), pair them as <em> (one), <strong> (two) or <del>, and
# deactivate every delimiter between. Opening tags prepend to the opener
# (later pairs are outer), closing tags append to the closer. OB records the
# lowest opener worth searching per character, can-open and length mod 3.
function process_emphasis(bottom,    c, o, key, ob, found, use, ot, ct, k) {
	split("", OB)
	c = next_delim(bottom)
	while (c) {
		if (!DCL[c]) { c = next_delim(c); continue }
		key = NC[c] DOP[c] (NO[c] % 3)
		ob = (key in OB) ? OB[key] : bottom
		found = 0
		for (o = c - 1; o > bottom && o > ob; o--) {
			if (NT[o] != "delim" || !DACT[o] || !DOP[o] || NC[o] != NC[c] || NN[o] == 0) continue
			if (NC[c] == "~") { if (NN[o] != NN[c]) continue }
			else if ((DCL[o] || DOP[c]) && (NO[o] + NO[c]) % 3 == 0 && !(NO[o] % 3 == 0 && NO[c] % 3 == 0)) continue
			found = 1; break
		}
		if (found) {
			if (NC[c] == "~") { use = NN[c]; ot = "<del>"; ct = "</del>" }
			else if (NN[o] >= 2 && NN[c] >= 2) { use = 2; ot = "<strong>"; ct = "</strong>" }
			else { use = 1; ot = "<em>"; ct = "</em>" }
			NAFT[o] = ot NAFT[o]; NBEF[c] = NBEF[c] ct
			NN[o] -= use; NN[c] -= use
			for (k = o + 1; k < c; k++) if (NT[k] == "delim") DACT[k] = 0
			if (NN[o] == 0) DACT[o] = 0
			if (NN[c] == 0) { DACT[c] = 0; c = next_delim(c) }
		}
		else {
			OB[key] = c - 1
			if (!DOP[c]) DACT[c] = 0
			c = next_delim(c)
		}
	}
	for (k = bottom + 1; k <= K; k++) if (NT[k] == "delim") DACT[k] = 0
}

function next_delim(k) { for (k++; k <= K; k++) if (NT[k] == "delim" && DACT[k]) return k; return 0 }

# close_bracket: at s[i] == "]", try the top bracket as an inline link
# [text](url "title"), a full reference [text][label], a collapsed reference
# [text][] or a shortcut reference [text]. On success the bracket contents are
# processed for emphasis and wrapped; a link deactivates earlier [ brackets,
# since links do not nest. Returns the position after the link, or 0.
#
# Local link rewrite, for static HTML browsing: a ./ or ../ relative href
# ending in .md (before any ? or #) becomes .md.html, so file.md links to its
# rendered sibling file.md.html while GitHub still follows the .md link; a
# README.md target becomes its directory (./ or ../dir/), mirroring the
# README.md -> index.html output naming. Link text that is itself such a path
# is rewritten the same way. Absolute, bare and external URLs are untouched;
# code spans are immune, being placeholders before links are parsed.
function close_bracket(s, i,    o, j, matched, url, title, endp, lab, raw, key, k, alt, all, ok) {
	if (BS == 0) return 0
	o = BRK[BS]
	if (!BACT[o]) { BS--; return 0 }
	raw = substr(s, BPOS[o], i - BPOS[o])
	j = i + 1; matched = 0
	if (substr(s, j, 1) == "(" && link_dest(s, j)) { url = LD_URL; title = LD_TITLE; endp = LD_END; matched = 1 }
	if (!matched) {
		lab = raw; endp = j
		if (substr(s, j, 1) == "[" && match(substr(s, j), /^\[[^\]\[]*\]/)) {
			if (RLENGTH > 2) lab = substr(s, j + 1, RLENGTH - 2)
			endp = j + RLENGTH
		}
		key = normlabel(lab)
		if (key != "" && (key in RURL)) { url = RURL[key]; title = RTITLE[key]; matched = 1 }
	}
	if (!matched) { BS--; return 0 }
	process_emphasis(o)
	if (BIMG[o]) {
		alt = restore(render_nodes(o + 1, K)); gsub(/<[^>]*>/, "", alt); gsub(/"/, "\\&quot;", alt)
		for (k = o + 1; k <= K; k++) NT[k] = "none"
		NV[o] = "<img src=\"" esc_attr(url) "\" alt=\"" alt "\"" ((title != "") ? " title=\"" esc_attr(title) "\"" : "") " />"
	}
	else {
		ok = (K > o); all = ""
		for (k = o + 1; k <= K; k++) { if (NT[k] != "txt") ok = 0; else all = all NV[k] }
		if (ok && all ~ /^\.\.?\/[^ ]*\.md$/) { NV[o + 1] = rewrite_local(all); for (k = o + 2; k <= K; k++) NV[k] = "" }
		NV[o] = "<a href=\"" esc_attr(rewrite_local(url)) "\"" ((title != "") ? " title=\"" esc_attr(title) "\"" : "") ">"
		new_node("txt", "</a>")
		for (k = 1; k < BS; k++) if (!BIMG[BRK[k]]) BACT[BRK[k]] = 0
	}
	BS--
	return endp
}

function rewrite_local(url) {
	if (url ~ /^\.\.?\/([^?#]*\/)?README\.md([?#]|$)/) { sub(/README\.md/, "", url); return url }
	if (url ~ /^\.\.?\// && match(url, /\.md([?#]|$)/))
		url = substr(url, 1, RSTART + 2) ".html" substr(url, RSTART + 3)
	return url
}

# link_dest: at s[j] == "(", parse destination (<...> or a run with balanced
# parentheses), optional title, and the closing ")"; sets LD_URL, LD_TITLE
# and LD_END.
function link_dest(s, j,    n, p, q, c, depth, url, title, cl, sawsp) {
	n = length(s); p = skip_ws(s, j + 1)
	if (substr(s, p, 1) == "<") {
		q = p + 1
		while (q <= n && (c = substr(s, q, 1)) != ">" && c != "\n" && c != "<") q++
		if (substr(s, q, 1) != ">") return 0
		url = substr(s, p + 1, q - p - 1); p = q + 1
	}
	else {
		depth = 0; q = p
		while (q <= n) {
			c = substr(s, q, 1)
			if (c == " " || c == "\t" || c == "\n") break
			if (c == "(") depth++
			else if (c == ")") { if (depth == 0) break; depth-- }
			q++
		}
		if (depth != 0) return 0
		url = substr(s, p, q - p); p = q
	}
	q = skip_ws(s, p); sawsp = (q > p); p = q
	title = ""; c = substr(s, p, 1)
	if (sawsp && (c == "\"" || c == Q || c == "(")) {
		cl = (c == "(") ? ")" : c
		q = p + 1
		while (q <= n && substr(s, q, 1) != cl) q++
		if (q > n) return 0
		title = substr(s, p + 1, q - p - 1); p = skip_ws(s, q + 1)
	}
	if (substr(s, p, 1) != ")") return 0
	LD_URL = url; LD_TITLE = title; LD_END = p + 1
	return 1
}

function skip_ws(s, p,    c) { while ((c = substr(s, p, 1)) != "" && index(" \t\n", c)) p++; return p }

# bare_url: GFM extended autolink at the head of t, or "". Trailing ? ! . , :
# * _ ~ and quotes are trimmed, an unbalanced ) is trimmed, and a trailing
# entity-like &name; is trimmed.
function bare_url(t,    u, prev, c, op, cl) {
	if (!match(t, /^(https?:\/\/[A-Za-z0-9_-]|www\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-])[^ \t\n<\001]*/)) return ""
	u = substr(t, 1, RLENGTH)
	do {
		prev = u; c = substr(u, length(u), 1)
		if (index("?!.,:*_~\"" Q, c)) u = substr(u, 1, length(u) - 1)
		else if (c == ")") { op = gsub(/\(/, "(", u); cl = gsub(/\)/, ")", u); if (cl > op) u = substr(u, 1, length(u) - 1) }
		else if (match(u, /&[A-Za-z0-9]+;$/)) u = substr(u, 1, RSTART - 1)
	} while (u != prev && u != "")
	return u
}

# --- Envelope ---
# Minimal table and footnote defaults sit before the external stylesheets, as
# element selectors of lowest specificity, so /default.css and ./default.css
# override without !important. The footnote rules are structural: ol numbering
# is suppressed so the browser "1." does not sit beside the literal "[^1]:"
# text, and the first definition paragraph is inlined onto its prefix line.
# A stylesheet may trade source fidelity for a superscript look, eg:
#   a[role="doc-noteref"] { vertical-align: super; font-size: 0.75em; }
#   a[role="doc-noteref"] span,
#   li[role="doc-endnote"] > span { display: none; }
#   section[role="doc-endnotes"] ol { list-style: decimal; padding-left: 2em; }
function envelope_head() {
	print "<!DOCTYPE html>"
	print "<html lang=\"en\">"
	print "<head>"
	print "<meta charset=\"utf-8\">"
	print "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
	print "<style>"
	print "table { border-collapse: collapse; }"
	print "th, td { border: 1px solid #999; padding: 0.3em 0.6em; }"
	print "section[role=\"doc-endnotes\"] ol { list-style: none; padding-left: 0; }"
	print "li[role=\"doc-endnote\"] > p:first-of-type { display: inline; margin: 0; }"
	print "</style>"
	print "<link rel=\"stylesheet\" href=\"/default.css\">"
	print "<link rel=\"stylesheet\" href=\"./default.css\">"
	print "</head>"
	print "<body>"
}
' "$@"
}

# --- Help Document ---
# markdown-help.md: usage, features, divergences from GFM, and the regression
# corpus. Every case is rendered live in the document and checked by -c.
help_md() {
cat <<'MARKDOWN_HELP'
# markdown.sh

A GitHub-flavored Markdown renderer in bash and awk. Markdown stays the master format: the same file reads correctly on GitHub and, rendered by `markdown.sh`, as standalone HTML on a static host. This document is the feature reference, the command reference, and the regression corpus at once; every case below is rendered live, so the page you are reading is also its own test output.

<!--contents 2 3 pre="## Contents" post="---"-->

## Usage

```
usage: markdown.sh input.md        render to input.md.html, print its realpath
       markdown.sh -f input.md     print the HTML fragment to stdout (- reads stdin)
       markdown.sh -H              print markdown-help.md (usage, features, corpus)
       markdown.sh -c [corpus.md]  run the regression corpus (default: built in)
       markdown.sh -h              print this usage
```

- `markdown.sh input.md` writes `input.md.html` beside the source and prints its realpath. `README.md` writes `index.html` instead, the directory index a static host serves for a bare request.
- `-f` prints the body fragment with no document envelope, for embedding, pipelines, and authoring corpus cases.
- `-H` prints this document. `markdown.sh -H > markdown-help.md && markdown.sh markdown-help.md` renders it.
- `-c` extracts every case from the corpus, renders its source, and compares the result with its expected HTML; it also confirms the live copy matches the source. Exit status is 1 on any failure.
- Input paths are limited to `[A-Za-z0-9,._/-]` and must end in `.md`.

## Output

- The page is a complete HTML document: `<meta charset="utf-8">`, a viewport line, and stylesheets `/default.css` (site baseline) then `./default.css` (local override). Small table and footnote defaults precede them as element selectors, so either stylesheet overrides without `!important`.
- No classes or divisions are emitted, apart from `class="language-x"` on fenced code with an info string and the DPUB-ARIA roles on footnotes. Style hooks are native elements.
- The output carries the source timestamp (`touch -r`). It is written to a temporary file and moved into place, so a failed render never leaves a truncated page.
- Markdown passes through as bytes; UTF-8 is untouched.

## Features

| Area | Supported |
|---|---|
| Blocks | paragraphs, ATX and setext headings, thematic breaks, blockquotes with lazy continuation, fenced code (backtick or tilde, length tracked, language class), indented code, HTML blocks (raw, comments, block tags, lone tags) |
| Lists | bullets and ordered (`.` or `)`), `start` numbers, tight and loose, any block inside an item, nesting by content column, lazy continuation, task items |
| Tables | GFM pipe tables, optional outer pipes, alignment as `align=`, escaped pipes |
| Inline | emphasis and strong by the CommonMark delimiter rules, strikethrough, code spans of any backtick length, backslash escapes, hard breaks, inline and reference links, images, autolinks and bare URLs, raw HTML, entities |
| Headings | GitHub slug ids with `-1`, `-2` de-duplication, or an explicit `{#custom-id}` |
| Extensions | footnotes in source form, `{#id}` inline anchors, local `.md` link rewriting, contents directive, front matter and metadata skip |

## Divergences from GitHub

Deliberate:

| Feature | GitHub | markdown.sh |
|---|---|---|
| Footnotes | superscript numbers in citation order, back links | `[^label]` source text in definition order, no back links; a definition also interrupts a paragraph, so consecutive definitions need no blank lines |
| `{#id}` | literal text | heading id, or a zero-width anchor in running text |
| `./x.md`, `../x.md` links | followed as written | rewritten to `x.md.html`; a `README.md` target becomes its directory |
| `<!--contents-->` | invisible comment | table of contents, with optional heading and closing rule |
| Front matter | rendered as a table | skipped; a leading block of two or more `Key: value` lines is skipped too |
| Raw HTML | sanitized | passed through unfiltered |

Not implemented: bare email autolinks, multi-line link reference definitions, percent-encoding of spaces in link targets, HTML blocks of CommonMark types 3 to 5 (processing instructions, declarations, CDATA), GitHub alerts (`> [!NOTE]`), math, and emoji shortcodes. Tab expansion inside list items is approximate, and UTF-8 punctuation is kept in heading slugs where GitHub drops it.

## Regression corpus

Each case below has three parts: its markdown source, the HTML fragment `markdown.sh -f` must produce for it, and the same source rendered live in this document. Three HTML comments tie them together and pass into the rendered page, so any piece of the output can be traced to its case by T-number:

- `<!--case T07 name-->` opens a case; `nolive` after the name marks a case that depends on its position in a document (front matter, contents) and is tested but not rendered in place.
- `<!--live T07-->` and `<!--end T07-->` enclose the live copy. In the rendered HTML, everything between them is that case's output.

To add a case, write its source in a scratch file, run `markdown.sh -f scratch.md`, check the result against GitHub's rendering or the GFM spec, and add the three parts under a new number. `markdown.sh -c` then holds every later change to it. A corpus kept outside the script runs with `markdown.sh -c file.md`.

Case T11 and case T37 depend on trailing spaces in their source; an editor that strips trailing whitespace will break them.

### T01 Paragraph with leading indent

<!--case T01 paragraph-indent-->

Up to three leading spaces are ignored, and the paragraph continues across lines.

Source:

```markdown
  indented para
continues here
```

Expected:

```html
<p>indented para
continues here</p>
```

Rendered:

<!--live T01-->

  indented para
continues here

<!--end T01-->


### T02 ATX headings

<!--case T02 atx-headings-->

One to six `#` followed by a space; a closing `#` run is dropped. Seven `#`, or none followed by a space, is paragraph text.

Source:

```markdown
#### Four
##### Five ###
###### Six
####### seven
#hashtag
```

Expected:

```html
<h4 id="four">Four</h4>
<h5 id="five">Five</h5>
<h6 id="six">Six</h6>
<p>####### seven
#hashtag</p>
```

Rendered:

<!--live T02-->

#### Four
##### Five ###
###### Six
####### seven
#hashtag

<!--end T02-->


### T03 Setext headings

<!--case T03 setext-headings nolive-->

An `=` or `-` underline turns every preceding paragraph line into the heading; a line break in the heading slugs as a space.

Source:

```markdown
Title
=====

line one
line two
---
```

Expected:

```html
<h1 id="title">Title</h1>
<h2 id="line-one-line-two">line one
line two</h2>
```

Not rendered live: this case depends on its position in a document.


### T04 Custom heading id

<!--case T04 custom-heading-id-->

A trailing `{#id}` sets the heading id explicitly.

Source:

```markdown
#### Custom anchor {#my-anchor}
```

Expected:

```html
<h4 id="my-anchor">Custom anchor</h4>
```

Rendered:

<!--live T04-->

#### Custom anchor {#my-anchor}

<!--end T04-->


### T05 GitHub heading slugs

<!--case T05 heading-slugs-->

Slugs come from the rendered text: lowercase, letters, digits, `-` and `_` kept, each space a hyphen, no collapsing. Repeated headings get `-1`, `-2`.

Source:

```markdown
#### Foo -- Bar & Baz_q
#### [Link](./x.md) and `code`
#### Dup
#### Dup
```

Expected:

```html
<h4 id="foo----bar--baz_q">Foo -- Bar &amp; Baz_q</h4>
<h4 id="link-and-code"><a href="./x.md.html">Link</a> and <code>code</code></h4>
<h4 id="dup">Dup</h4>
<h4 id="dup-1">Dup</h4>
```

Rendered:

<!--live T05-->

#### Foo -- Bar & Baz_q
#### [Link](./x.md) and `code`
#### Dup
#### Dup

<!--end T05-->


### T06 Thematic breaks

<!--case T06 thematic-breaks-->

Three or more `*`, `-` or `_`, spaces allowed; a spaced rule interrupts a paragraph.

Source:

```markdown
***
- - -
para
* * *
next
```

Expected:

```html
<hr />
<hr />
<p>para</p>
<hr />
<p>next</p>
```

Rendered:

<!--live T06-->

***
- - -
para
* * *
next

<!--end T06-->


### T07 Blockquote with lazy continuation

<!--case T07 blockquote-lazy-->

A line without `>` continues a quoted paragraph; quotes nest.

Source:

```markdown
> quote with **bold**
lazy continuation
>
> > nested

after
```

Expected:

```html
<blockquote>
<p>quote with <strong>bold</strong>
lazy continuation</p>
<blockquote>
<p>nested</p>
</blockquote>
</blockquote>
<p>after</p>
```

Rendered:

<!--live T07-->

> quote with **bold**
lazy continuation
>
> > nested

after

<!--end T07-->


### T08 Blocks inside a blockquote

<!--case T08 blockquote-blocks-->

Headings, lists and fences parse inside a quote by the same rules as the top level.

Source:

```markdown
> #### Quoted heading
> - item
> ```
> code
> ```
```

Expected:

```html
<blockquote>
<h4 id="quoted-heading">Quoted heading</h4>
<ul>
<li>item</li>
</ul>
<pre><code>code
</code></pre>
</blockquote>
```

Rendered:

<!--live T08-->

> #### Quoted heading
> - item
> ```
> code
> ```

<!--end T08-->


### T09 Fenced code with language

<!--case T09 fence-language-->

The first info word becomes `class="language-x"`.

Source:

````markdown
```bash
echo "a < b && c"
```
````

Expected:

```html
<pre><code class="language-bash">echo "a &lt; b &amp;&amp; c"
</code></pre>
```

Rendered:

<!--live T09-->

```bash
echo "a < b && c"
```

<!--end T09-->


### T10 Fence opening on a blank line

<!--case T10 fence-blank-first-line-->

A blank first line belongs to the code; the fence does not break.

Source:

````markdown
```

code
```
after
````

Expected:

```html
<pre><code>
code
</code></pre>
<p>after</p>
```

Rendered:

<!--live T10-->

```

code
```
after

<!--end T10-->


### T11 Closing fence with trailing spaces

<!--case T11 fence-trailing-space-->

Trailing spaces after a closing fence are allowed; the fence still closes.

Source:

````markdown
```
code
```   
para
````

Expected:

```html
<pre><code>code
</code></pre>
<p>para</p>
```

Rendered:

<!--live T11-->

```
code
```   
para

<!--end T11-->


### T12 Fence length and tilde fences

<!--case T12 fence-length-tilde-->

A fence closes only on a run at least as long as its opener, so a longer fence can show a shorter one; tilde fences work the same way.

Source:

`````markdown
````markdown
```
inner
```
````
~~~
tilde
~~~
`````

Expected:

````html
<pre><code class="language-markdown">```
inner
```
</code></pre>
<pre><code>tilde
</code></pre>
````

Rendered:

<!--live T12-->

````markdown
```
inner
```
````
~~~
tilde
~~~

<!--end T12-->


### T13 Indented code

<!--case T13 indented-code-->

Four columns of indent make code; blank lines inside are kept.

Source:

```markdown
    indented
      more

    after blank
```

Expected:

```html
<pre><code>indented
  more

after blank
</code></pre>
```

Rendered:

<!--live T13-->

    indented
      more

    after blank

<!--end T13-->


### T14 HTML block with markdown inside

<!--case T14 html-block-details-->

A block tag starts raw HTML that runs to a blank line; markdown resumes between blank lines, the common GitHub pattern for collapsible sections.

Source:

```markdown
<details>
<summary>Summary</summary>

Hidden **markdown**.

</details>
```

Expected:

```html
<details>
<summary>Summary</summary>
<p>Hidden <strong>markdown</strong>.</p>
</details>
```

Rendered:

<!--live T14-->

<details>
<summary>Summary</summary>

Hidden **markdown**.

</details>

<!--end T14-->


### T15 HTML comments

<!--case T15 html-comments-->

Block comments, across lines, and inline comments pass through.

Source:

```markdown
<!-- block comment
spans lines -->
Text with <!-- inline --> comment.
```

Expected:

```html
<!-- block comment
spans lines -->
<p>Text with <!-- inline --> comment.</p>
```

Rendered:

<!--live T15-->

<!-- block comment
spans lines -->
Text with <!-- inline --> comment.

<!--end T15-->


### T16 Sized image as raw HTML

<!--case T16 html-image-sized-->

A complete tag alone on its line is a raw HTML block, here the 312 by 313 pixel diagram with explicit dimensions.

Source:

```markdown
<img src="../know/Operations-Framework-0.5.png" width="312" height="313" alt="Operations Framework 0.5">
```

Expected:

```html
<img src="../know/Operations-Framework-0.5.png" width="312" height="313" alt="Operations Framework 0.5">
```

Rendered:

<!--live T16-->

<img src="../know/Operations-Framework-0.5.png" width="312" height="313" alt="Operations Framework 0.5">

<!--end T16-->


### T17 Bullet nesting

<!--case T17 bullet-nesting-->

Items nest by content column.

Source:

```markdown
- a
  - b
    - c
- d
```

Expected:

```html
<ul>
<li>a
<ul>
<li>b
<ul>
<li>c</li>
</ul></li>
</ul></li>
<li>d</li>
</ul>
```

Rendered:

<!--live T17-->

- a
  - b
    - c
- d

<!--end T17-->


### T18 Ordered list start

<!--case T18 ordered-start-->

The first number becomes `start`.

Source:

```markdown
3. three
4. four
```

Expected:

```html
<ol start="3">
<li>three</li>
<li>four</li>
</ol>
```

Rendered:

<!--live T18-->

3. three
4. four

<!--end T18-->


### T19 Loose ordered list

<!--case T19 ordered-loose-->

Blank lines between items keep one list and make it loose (paragraphs in each item); numbering continues.

Source:

```markdown
1. one

2. two

3. three
```

Expected:

```html
<ol>
<li>
<p>one</p>
</li>
<li>
<p>two</p>
</li>
<li>
<p>three</p>
</li>
</ol>
```

Rendered:

<!--live T19-->

1. one

2. two

3. three

<!--end T19-->


### T20 Fence inside a list item

<!--case T20 ordered-fence-in-item-->

Content indented to the item column belongs to the item, code included, and the list continues after it.

Source:

```markdown
1. Step one
   ```bash
   make
   ```
2. Step two
```

Expected:

```html
<ol>
<li>Step one
<pre><code class="language-bash">make
</code></pre></li>
<li>Step two</li>
</ol>
```

Rendered:

<!--live T20-->

1. Step one
   ```bash
   make
   ```
2. Step two

<!--end T20-->


### T21 Paragraphs inside a list item

<!--case T21 ordered-multi-paragraph-->

A blank line and indented text add a paragraph to the item, which makes the list loose.

Source:

```markdown
1. First

   continued paragraph
2. Second
```

Expected:

```html
<ol>
<li>
<p>First</p>
<p>continued paragraph</p>
</li>
<li>
<p>Second</p>
</li>
</ol>
```

Rendered:

<!--live T21-->

1. First

   continued paragraph
2. Second

<!--end T21-->


### T22 Delimiter change starts a new list

<!--case T22 ordered-delimiter-change-->

`)` and `.` are both ordered markers; changing the delimiter (or the bullet character) starts a new list, a way to restart numbering.

Source:

```markdown
1) a
2) b
1. c
```

Expected:

```html
<ol>
<li>a</li>
<li>b</li>
</ol>
<ol>
<li>c</li>
</ol>
```

Rendered:

<!--live T22-->

1) a
2) b
1. c

<!--end T22-->


### T23 Only 1 interrupts a paragraph

<!--case T23 ordered-interrupt-->

A number other than 1 cannot start a list inside a paragraph, so prose that wraps onto a year stays prose.

Source:

```markdown
The year was
1984. A good year.

Steps:
1. first
```

Expected:

```html
<p>The year was
1984. A good year.</p>
<p>Steps:</p>
<ol>
<li>first</li>
</ol>
```

Rendered:

<!--live T23-->

The year was
1984. A good year.

Steps:
1. first

<!--end T23-->


### T24 List marker as item text

<!--case T24 marker-in-item-->

Item content is parsed as blocks, so `2. x` inside a bullet is a nested ordered list; escape the dot to keep the number as text.

Source:

```markdown
- 1\. literal
- 2. nested
```

Expected:

```html
<ul>
<li>1. literal</li>
<li><ol start="2">
<li>nested</li>
</ol></li>
</ul>
```

Rendered:

<!--live T24-->

- 1\. literal
- 2. nested

<!--end T24-->


### T25 Nesting needs the content column

<!--case T25 nesting-indent-->

A sublist must be indented to its parent content column (3 for `1. `); one space starts a separate list.

Source:

```markdown
1. a
 - b
```

Expected:

```html
<ol>
<li>a</li>
</ol>
<ul>
<li>b</li>
</ul>
```

Rendered:

<!--live T25-->

1. a
 - b

<!--end T25-->


### T26 Looseness belongs to each list

<!--case T26 tight-outer-loose-inner-->

A blank line between nested items makes the nested list loose and leaves the outer list tight.

Source:

```markdown
- a
  - b

  - c
- d
```

Expected:

```html
<ul>
<li>a
<ul>
<li>
<p>b</p>
</li>
<li>
<p>c</p>
</li>
</ul></li>
<li>d</li>
</ul>
```

Rendered:

<!--live T26-->

- a
  - b

  - c
- d

<!--end T26-->


### T27 Task list items

<!--case T27 task-list-->

`[ ]` and `[x]` before item text become disabled checkboxes.

Source:

```markdown
- [ ] todo
- [x] done
- not a task
```

Expected:

```html
<ul>
<li><input type="checkbox" disabled="" /> todo</li>
<li><input type="checkbox" checked="" disabled="" /> done</li>
<li>not a task</li>
</ul>
```

Rendered:

<!--live T27-->

- [ ] todo
- [x] done
- not a task

<!--end T27-->


### T28 Lazy continuation in a list item

<!--case T28 lazy-item-->

An unindented line continues the item paragraph.

Source:

```markdown
1. a
b
2. c
```

Expected:

```html
<ol>
<li>a
b</li>
<li>c</li>
</ol>
```

Rendered:

<!--live T28-->

1. a
b
2. c

<!--end T28-->


### T29 Table with alignment

<!--case T29 table-align-->

Colons in the delimiter row set `align=` on every cell of the column.

Source:

```markdown
| Left | Center | Right |
|:--|:-:|--:|
| a | b | c |
```

Expected:

```html
<table>
<thead>
<tr><th align="left">Left</th><th align="center">Center</th><th align="right">Right</th></tr>
</thead>
<tbody>
<tr><td align="left">a</td><td align="center">b</td><td align="right">c</td></tr>
</tbody>
</table>
```

Rendered:

<!--live T29-->

| Left | Center | Right |
|:--|:-:|--:|
| a | b | c |

<!--end T29-->


### T30 Table without outer pipes

<!--case T30 table-bare-->

Leading and trailing pipes are optional.

Source:

```markdown
a | b
--|--
1 | 2
```

Expected:

```html
<table>
<thead>
<tr><th>a</th><th>b</th></tr>
</thead>
<tbody>
<tr><td>1</td><td>2</td></tr>
</tbody>
</table>
```

Rendered:

<!--live T30-->

a | b
--|--
1 | 2

<!--end T30-->


### T31 Escaped pipe in a table

<!--case T31 table-escaped-pipe-->

An escaped `\|` is a literal pipe, inside a code span too; an unescaped pipe always divides cells, as on GitHub.

Source:

```markdown
| code | text |
|---|---|
| `x\|y` | a\|b |
```

Expected:

```html
<table>
<thead>
<tr><th>code</th><th>text</th></tr>
</thead>
<tbody>
<tr><td><code>x|y</code></td><td>a|b</td></tr>
</tbody>
</table>
```

Rendered:

<!--live T31-->

| code | text |
|---|---|
| `x\|y` | a\|b |

<!--end T31-->


### T32 Emphasis and strong

<!--case T32 emphasis-->

`*` and `_` by the CommonMark flanking rules: `_` never acts inside a word, and a delimiter beside spaces is literal.

Source:

```markdown
*em* **strong** ***both*** _u_ __uu__
snake_case_word 2 * 3 * 4
```

Expected:

```html
<p><em>em</em> <strong>strong</strong> <em><strong>both</strong></em> <em>u</em> <strong>uu</strong>
snake_case_word 2 * 3 * 4</p>
```

Rendered:

<!--live T32-->

*em* **strong** ***both*** _u_ __uu__
snake_case_word 2 * 3 * 4

<!--end T32-->


### T33 Nested emphasis

<!--case T33 emphasis-nesting-->

Delimiters of either kind nest.

Source:

```markdown
**bold _it_ tail** and *a *b* c*
```

Expected:

```html
<p><strong>bold <em>it</em> tail</strong> and <em>a <em>b</em> c</em></p>
```

Rendered:

<!--live T33-->

**bold _it_ tail** and *a *b* c*

<!--end T33-->


### T34 Strikethrough

<!--case T34 strikethrough-->

One or two tildes, matched by length; three is literal.

Source:

```markdown
~~gone~~ and ~one~ and ~~~three~~~
```

Expected:

```html
<p><del>gone</del> and <del>one</del> and ~~~three~~~</p>
```

Rendered:

<!--live T34-->

~~gone~~ and ~one~ and ~~~three~~~

<!--end T34-->


### T35 Code spans

<!--case T35 code-spans-->

A span closes on a backtick run of its own length, so a longer run can hold a backtick; one space is trimmed from each side.

Source:

```markdown
`a` and ``x`y`` and `` `tick` `` and `unclosed
```

Expected:

```html
<p><code>a</code> and <code>x`y</code> and <code>`tick`</code> and `unclosed</p>
```

Rendered:

<!--live T35-->

`a` and ``x`y`` and `` `tick` `` and `unclosed

<!--end T35-->


### T36 Backslash escapes

<!--case T36 escapes-->

Any ASCII punctuation can be escaped; other backslashes are literal.

Source:

```markdown
\*not em\* \# \[x\] \\ backslash \a
```

Expected:

```html
<p>*not em* # [x] \ backslash \a</p>
```

Rendered:

<!--live T36-->

\*not em\* \# \[x\] \\ backslash \a

<!--end T36-->


### T37 Hard line breaks

<!--case T37 hard-breaks-->

Two trailing spaces, or a trailing backslash, end a line with `<br />`.

Source:

```markdown
two spaces  
backslash\
end
```

Expected:

```html
<p>two spaces<br />
backslash<br />
end</p>
```

Rendered:

<!--live T37-->

two spaces  
backslash\
end

<!--end T37-->


### T38 Inline links

<!--case T38 links-inline-->

Titles in either quote style; balanced parentheses in the target.

Source:

```markdown
[text](https://example.com "Title") [paren](https://example.com/a_(b)) [single](https://example.com 'Single')
```

Expected:

```html
<p><a href="https://example.com" title="Title">text</a> <a href="https://example.com/a_(b)">paren</a> <a href="https://example.com" title="Single">single</a></p>
```

Rendered:

<!--live T38-->

[text](https://example.com "Title") [paren](https://example.com/a_(b)) [single](https://example.com 'Single')

<!--end T38-->


### T39 Local link rewrite

<!--case T39 links-local-rewrite-->

`./` and `../` targets ending in `.md` link to the rendered `.md.html`; a `README.md` target links to its directory; link text that is itself such a path is rewritten too. Bare and external targets are untouched.

Source:

```markdown
[doc](./notes.md) [up](../guide.md#part) [index](./README.md) [dir](../sub/README.md?x=1) [./other.md](./other.md) [ext](https://example.com/x.md) [bare](notes.md)
```

Expected:

```html
<p><a href="./notes.md.html">doc</a> <a href="../guide.md.html#part">up</a> <a href="./">index</a> <a href="../sub/?x=1">dir</a> <a href="./other.md.html">./other.md.html</a> <a href="https://example.com/x.md">ext</a> <a href="notes.md">bare</a></p>
```

Rendered:

<!--live T39-->

[doc](./notes.md) [up](../guide.md#part) [index](./README.md) [dir](../sub/README.md?x=1) [./other.md](./other.md) [ext](https://example.com/x.md) [bare](notes.md)

<!--end T39-->


### T40 Reference links

<!--case T40 links-reference-->

Full, collapsed and shortcut forms; labels match without regard to case, and a definition may follow its use. Local rewriting applies to reference targets.

Source:

```markdown
[full][ref1] [collapsed][] [shortcut] [missing]

[ref1]: https://example.com/one "One"
[collapsed]: ./c.md
[Shortcut]: <../s.md>
```

Expected:

```html
<p><a href="https://example.com/one" title="One">full</a> <a href="./c.md.html">collapsed</a> <a href="../s.md.html">shortcut</a> [missing]</p>
```

Rendered:

<!--live T40-->

[full][ref1] [collapsed][] [shortcut] [missing]

[ref1]: https://example.com/one "One"
[collapsed]: ./c.md
[Shortcut]: <../s.md>

<!--end T40-->


### T41 Autolinks

<!--case T41 autolinks-->

Angle-bracket autolinks and email, plus bare `www.` and `https://` URLs; trailing punctuation and an unbalanced parenthesis stay outside the link.

Source:

```markdown
<https://example.com> <user@example.com> www.example.com
https://example.com/path. (see https://example.com/a_(b)) and http://example.org/foo_bar_baz
```

Expected:

```html
<p><a href="https://example.com">https://example.com</a> <a href="mailto:user@example.com">user@example.com</a> <a href="http://www.example.com">www.example.com</a>
<a href="https://example.com/path">https://example.com/path</a>. (see <a href="https://example.com/a_(b)">https://example.com/a_(b)</a>) and <a href="http://example.org/foo_bar_baz">http://example.org/foo_bar_baz</a></p>
```

Rendered:

<!--live T41-->

<https://example.com> <user@example.com> www.example.com
https://example.com/path. (see https://example.com/a_(b)) and http://example.org/foo_bar_baz

<!--end T41-->


### T42 Image

<!--case T42 image-->

The diagram by markdown image syntax, with a title.

Source:

```markdown
![Operations Framework](../know/Operations-Framework-0.5.png "Operations Framework 0.5")
```

Expected:

```html
<p><img src="../know/Operations-Framework-0.5.png" alt="Operations Framework" title="Operations Framework 0.5" /></p>
```

Rendered:

<!--live T42-->

![Operations Framework](../know/Operations-Framework-0.5.png "Operations Framework 0.5")

<!--end T42-->


### T43 Linked image

<!--case T43 image-linked-->

An image inside link text, the badge pattern; alt text is the plain text of the image description.

Source:

```markdown
[![Operations *Framework*](../know/Operations-Framework-0.5.png)](../know/Operations-Framework-0.5.png)
```

Expected:

```html
<p><a href="../know/Operations-Framework-0.5.png"><img src="../know/Operations-Framework-0.5.png" alt="Operations Framework" /></a></p>
```

Rendered:

<!--live T43-->

[![Operations *Framework*](../know/Operations-Framework-0.5.png)](../know/Operations-Framework-0.5.png)

<!--end T43-->


### T44 Inline HTML

<!--case T44 inline-html-->

Self-closing, boolean, hyphenated, single-quoted and unquoted attributes pass through; a bare `<` is escaped.

Source:

```markdown
line<br />two <kbd>Ctrl</kbd> <span data-x="1" hidden>h</span> <a href='#t44' class=x>q</a> 3 < 4
```

Expected:

```html
<p>line<br />two <kbd>Ctrl</kbd> <span data-x="1" hidden>h</span> <a href='#t44' class=x>q</a> 3 &lt; 4</p>
```

Rendered:

<!--live T44-->

line<br />two <kbd>Ctrl</kbd> <span data-x="1" hidden>h</span> <a href='#t44' class=x>q</a> 3 < 4

<!--end T44-->


### T45 Entities

<!--case T45 entities-->

Named, decimal and hex entities pass through; a bare `&` is escaped.

Source:

```markdown
&copy; &#169; &#xA9; AT&T &amp; &bogus
```

Expected:

```html
<p>&copy; &#169; &#xA9; AT&amp;T &amp; &amp;bogus</p>
```

Rendered:

<!--live T45-->

&copy; &#169; &#xA9; AT&T &amp; &bogus

<!--end T45-->


### T46 Inline anchor

<!--case T46 inline-anchor-->

`{#id}` in running text is a zero-width link target.

Source:

```markdown
Jump target {#t46-target} in text.
```

Expected:

```html
<p>Jump target <a id="t46-target"></a> in text.</p>
```

Rendered:

<!--live T46-->

Jump target {#t46-target} in text.

<!--end T46-->


### T47 Footnotes

<!--case T47 footnotes-->

References render as their source text in a link; definitions collect at the end of the document in definition order. A label may be cited more than once.

Source:

```markdown
Text[^fa] and again[^fa], other[^fb].

[^fa]: First note with *emphasis*.
[^fb]: Second note.
```

Expected:

```html
<p>Text<a href="#fn-fa" role="doc-noteref"><span>[^</span>fa<span>]</span></a> and again<a href="#fn-fa" role="doc-noteref"><span>[^</span>fa<span>]</span></a>, other<a href="#fn-fb" role="doc-noteref"><span>[^</span>fb<span>]</span></a>.</p>
<section id="footnotes" role="doc-endnotes">
<hr />
<ol>
<li id="fn-fa" role="doc-endnote"><span>[^fa]: </span><p>First note with <em>emphasis</em>.</p></li>
<li id="fn-fb" role="doc-endnote"><span>[^fb]: </span><p>Second note.</p></li>
</ol>
</section>
```

Rendered:

<!--live T47-->

Text[^fa] and again[^fa], other[^fb].

[^fa]: First note with *emphasis*.
[^fb]: Second note.

<!--end T47-->


### T48 Footnote with several paragraphs

<!--case T48 footnote-blocks-->

A definition continues lazily, and takes further blocks indented four columns after a blank line.

Source:

```markdown
Ref[^fc].

[^fc]: Para one
continued lazily.

    Para two indented.
```

Expected:

```html
<p>Ref<a href="#fn-fc" role="doc-noteref"><span>[^</span>fc<span>]</span></a>.</p>
<section id="footnotes" role="doc-endnotes">
<hr />
<ol>
<li id="fn-fc" role="doc-endnote"><span>[^fc]: </span><p>Para one
continued lazily.</p>
<p>Para two indented.</p></li>
</ol>
</section>
```

Rendered:

<!--live T48-->

Ref[^fc].

[^fc]: Para one
continued lazily.

    Para two indented.

<!--end T48-->


### T49 Consecutive footnote definitions

<!--case T49 footnotes-consecutive-->

Definitions need no blank lines between them, nor before the first.

Source:

```markdown
X[^fd] Y[^fe]
[^fd]: one
[^fe]: two
```

Expected:

```html
<p>X<a href="#fn-fd" role="doc-noteref"><span>[^</span>fd<span>]</span></a> Y<a href="#fn-fe" role="doc-noteref"><span>[^</span>fe<span>]</span></a></p>
<section id="footnotes" role="doc-endnotes">
<hr />
<ol>
<li id="fn-fd" role="doc-endnote"><span>[^fd]: </span><p>one</p></li>
<li id="fn-fe" role="doc-endnote"><span>[^fe]: </span><p>two</p></li>
</ol>
</section>
```

Rendered:

<!--live T49-->

X[^fd] Y[^fe]
[^fd]: one
[^fe]: two

<!--end T49-->


### T50 Contents with heading and rule

<!--case T50 contents-pre-post nolive-->

`pre` and `post` hold markdown rendered around the index, so the contents heading and closing rule stay inside the comment and out of GitHub's rendering. The heading is recorded before the index scope begins, so it indexes nothing of itself; `# Title` falls outside the 2 to 3 window.

Source:

```markdown
<!--contents 2 3 pre="## Contents" post="---"-->

# Title
## Alpha
### Beta *em*
#### Gamma
## Delta [link](./d.md)
```

Expected:

```html
<h2 id="contents">Contents</h2>
<nav>
<ul>
<li><a href="#alpha">Alpha</a>
<ul>
<li><a href="#beta-em">Beta <em>em</em></a></li>
</ul></li>
<li><a href="#delta-link">Delta link</a></li>
</ul>
</nav>
<hr />
<h1 id="title">Title</h1>
<h2 id="alpha">Alpha</h2>
<h3 id="beta-em">Beta <em>em</em></h3>
<h4 id="gamma">Gamma</h4>
<h2 id="delta-link">Delta <a href="./d.md.html">link</a></h2>
```

Not rendered live: this case depends on its position in a document.


### T51 Contents default window

<!--case T51 contents-default nolive-->

With no arguments the window is levels 1 to 3, and only headings after the directive are indexed.

Source:

```markdown
## Before
<!--contents-->
## After
### Sub
```

Expected:

```html
<h2 id="before">Before</h2>
<nav>
<ul>
<li><a href="#after">After</a>
<ul>
<li><a href="#sub">Sub</a></li>
</ul></li>
</ul>
</nav>
<h2 id="after">After</h2>
<h3 id="sub">Sub</h3>
```

Not rendered live: this case depends on its position in a document.


### T52 Contents with nothing to index

<!--case T52 contents-empty nolive-->

When no heading falls in the window, nothing is emitted, `pre` and `post` included. An unrecognized argument leaves an ordinary comment.

Source:

```markdown
<!--contents 2 3 pre="## Contents" post="---"-->
<!--contents bogus-->
# only h1
```

Expected:

```html
<!--contents bogus-->
<h1 id="only-h1">only h1</h1>
```

Not rendered live: this case depends on its position in a document.


### T53 Front matter

<!--case T53 front-matter nolive-->

A leading `---` block whose first line reads as `key: value` is skipped.

Source:

```markdown
---
title: x
date: y
---
Body.
```

Expected:

```html
<p>Body.</p>
```

Not rendered live: this case depends on its position in a document.


### T54 Metadata block

<!--case T54 metadata-block nolive-->

A leading block of two or more `Key: value` lines is skipped.

Source:

```markdown
Title: Doc
Author: Me

Body.
```

Expected:

```html
<p>Body.</p>
```

Not rendered live: this case depends on its position in a document.


### T55 Single colon line is content

<!--case T55 metadata-single-line nolive-->

One `Key: value` line is not metadata, so a first paragraph such as a note still renders.

Source:

```markdown
Note: this first line is content.

Second para.
```

Expected:

```html
<p>Note: this first line is content.</p>
<p>Second para.</p>
```

Not rendered live: this case depends on its position in a document.


### T56 Opening rule is not front matter

<!--case T56 hr-not-front-matter nolive-->

A document may open on a thematic break when the next line is not `key: value`.

Source:

```markdown
---
Not front matter.
```

Expected:

```html
<hr />
<p>Not front matter.</p>
```

Not rendered live: this case depends on its position in a document.


## Source

Functional source of this rewrite, whose behavior it preserves: [georgalis/pub sub/markdown.sh at f3839048](https://github.com/georgalis/pub/blob/f3839048129555e0a624f3f807cad720ece74dff/sub/markdown.sh), itself descended from knazarov/markdown.awk (BSD License).

markdown.sh revision: org 6ac19d83 20261003 172747 PDT Sat --- container model rewrite, help corpus

<https://github.com/georgalis/pub/tree/main/src/markdown>
MARKDOWN_HELP
}

# --- Usage ---
# Printed from the Usage section of markdown-help.md, the single source.
usage() {
	awk '/^## Usage/ { f = 1; next } f && /^```/ { if (n++) exit; next } f && n == 1' < <(help_md)
}

# --- Corpus Source ---
# The named corpus file, or the built-in help when none is given.
corpus_src() {
	[[ -n "${1:-}" ]] && { cat -- "$1"; return ;}
	help_md
}

# --- Regression Corpus ---
# check [corpus.md]: extract every case from the corpus (built-in help by
# default), render its markdown block as a fragment, and compare with its html
# block. A case marked live must also carry an identical copy of its source
# between its live and end comments, so the rendered help shows what is
# tested. Prints ok or FAIL per case with a unified diff, then a summary;
# exits 1 on any failure.
#
# Case layout in the corpus (see markdown.sh -H, Regression corpus):
#   <!--case T07 short-name-->           (or ... short-name nolive-->)
#   fenced block, info string markdown   source
#   fenced block, info string html       expected fragment
#   <!--live T07-->  source  <!--end T07-->
#
# The work directory is removed by its literal markdown. prefix plus the
# validated mktemp suffix, never by a variable holding the whole path.
check() {
	local src="${1:-}" dir id name live pass=0 fail=0
	[[ -z "$src" || -f "$src" ]] || { printf 'error: corpus not found: %s\n' "$src" >&2; exit 1 ;}
	read -r dir < <(mktemp -d "${TMPDIR:-/tmp}/markdown.XXXXXX")
	CHECK_ID="${dir##*/markdown.}"     # global: the trap runs after return
	[[ "$CHECK_ID" =~ ^[A-Za-z0-9]+$ ]] || { printf 'error: unexpected mktemp result: %s\n' "$dir" >&2; exit 1 ;}
	trap 'rm -rf "${TMPDIR:-/tmp}/markdown.${CHECK_ID}"' EXIT
	dir="${TMPDIR:-/tmp}/markdown.${CHECK_ID}"

	LC_ALL=C awk -v dir="$dir" '
		# case header: id, name, live flag
		/^<!--case T[0-9]+ [^ ]+( nolive)?-->$/ {
			s = $0; sub(/^<!--case /, "", s); sub(/-->$/, "", s)
			nf = split(s, f, " "); id = f[1]
			print id, f[2], (nf > 2) ? "nolive" : "live"
			next
		}
		# fenced markdown or html block belonging to the current case; never
		# inside a live copy, whose source may hold such a fence of its own
		id != "" && !live && fence == "" && $0 ~ /^(```+|~~~+)(markdown|html)[ \t]*$/ {
			fence = $0; sub(/[a-z]+[ \t]*$/, "", fence)
			out = dir "/" id "." (($0 ~ /markdown/) ? "md" : "html")
			printf "" > out
			next
		}
		fence != "" {
			t = $0; sub(/[ \t]+$/, "", t)
			if (t ~ /^(`+|~+)$/ && substr(t, 1, 1) == substr(fence, 1, 1) && length(t) >= length(fence)) {
				close(out); fence = ""; next
			}
			print > out
			next
		}
		# live copy, trimmed of leading and trailing blank lines
		/^<!--live T[0-9]+-->$/ { lid = $0; sub(/^<!--live /, "", lid); sub(/-->$/, "", lid); nl = 0; live = 1; next }
		live && $0 == "<!--end " lid "-->" {
			a = 1; while (a <= nl && LV[a] ~ /^[ \t]*$/) a++
			b = nl; while (b >= a && LV[b] ~ /^[ \t]*$/) b--
			lout = dir "/" lid ".live"; printf "" > lout
			for (k = a; k <= b; k++) print LV[k] > lout
			close(lout); live = 0; next
		}
		live { LV[++nl] = $0 }
	' < <(corpus_src "$src") > "$dir/index"

	# expected output first, then the live copy; each failure reports and
	# moves on, so a later test is never reached through an earlier signal
	while read -r id name live; do
		render 1 "$dir/$id.md" > "$dir/$id.out"
		cmp -s "$dir/$id.html" "$dir/$id.out" 2>/dev/null || {
			printf 'FAIL %s %s\n' "$id" "$name"; fail=$((fail + 1))
			sed 's/^/     /' < <(diff -u "$dir/$id.html" "$dir/$id.out" 2>&1 || :)
			continue ;}
		[[ "$live" == nolive ]] || cmp -s "$dir/$id.md" "$dir/$id.live" 2>/dev/null || {
			printf 'FAIL %s %s (live copy differs from source)\n' "$id" "$name"; fail=$((fail + 1))
			continue ;}
		printf 'ok   %s %s\n' "$id" "$name"; pass=$((pass + 1))
	done < "$dir/index"
	printf '%d passed, %d failed\n' "$pass" "$fail"
	[[ $fail -eq 0 ]] || exit 1
}

# --- Command Line ---
case "${1:-}" in
	-h) usage; exit 0 ;;
	-H) help_md; exit 0 ;;
	-c) check "${2:-}"; exit 0 ;;
	-f) [[ $# -eq 2 ]] || { usage >&2; exit 1 ;}
	    [[ "$2" == - ]] && { render 1; exit 0 ;}
	    [[ -f "$2" ]] || { printf 'error: file not found: %s\n' "$2" >&2; exit 1 ;}
	    render 1 "$2"; exit 0 ;;
	-*) usage >&2; exit 1 ;;
esac

# --- Input Validation ---
[[ $# -eq 1 ]] || { usage >&2; exit 1 ;}

infile="$1"

# safe path characters only
[[ "$infile" =~ ^[A-Za-z0-9,._/-]+$ ]] \
	|| { printf 'error: unsafe characters in path: %s\n' "$infile" >&2; exit 1 ;}

# require .md extension
[[ "$infile" == *.md ]] \
	|| { printf 'error: input must end in .md: %s\n' "$infile" >&2; exit 1 ;}

[[ -f "$infile" ]] \
	|| { printf 'error: file not found: %s\n' "$infile" >&2; exit 1 ;}

# --- Output Naming ---
# input.md -> input.md.html; README.md -> index.html in the same directory,
# since README.md is the directory index by convention and a static host
# serves index.html for a bare directory request.
outfile="${infile}.html"
base="${infile##*/}"          # parameter expansion equivalent of basename
dir="${infile%/*}"            # parameter expansion equivalent of dirname
[[ "$dir" == "$infile" ]] && dir="."   # no / present: dirname would say "."
[[ "$base" == "README.md" ]] && {
	outfile="index.html"
	[[ "$dir" == "." ]] || outfile="${dir}/${outfile}" ;}

# an existing directory at the output path would receive the moved file
[[ -d "$outfile" ]] && { printf 'error: output is a directory: %s\n' "$outfile" >&2; exit 1 ;}

# --- Render ---
# Written beside the output and moved into place, so a failed render never
# leaves a truncated page; the source timestamp is preserved on the output.
# The trap names the class of file it removes: the literal .tmp. suffix.
trap 'rm -f "${outfile}.tmp.$$"' EXIT
render 0 "$infile" > "${outfile}.tmp.$$"
touch -r "$infile" "${outfile}.tmp.$$"
mv -f "${outfile}.tmp.$$" "$outfile"
trap - EXIT

realpath "$outfile"
