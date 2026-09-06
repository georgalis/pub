#!/usr/bin/env bash
set -euo pipefail

# yml2md.sh --- Bash envelope for the embedded YAML-to-Markdown extractor
#
# Validates input, invokes the awk translator, writes output to <input>.md
# (eg data.yml -> data.yml.md), and preserves the source file timestamp on
# the output via touch -r. Chains with markdown.sh, which renders
# <input>.yml.md to <input>.yml.md.html.
#
# Structure is decided here; presentation is not. The extractor emits no
# classes, no colors, and no type annotations -- those belong to the CSS
# applied at the HTML stage. What this stage decides is shape: which YAML
# construct becomes a heading, a definition line, a list item, or a fence.
#
# Usage: yml2md.sh [-d n] [-b n] [-A] [-c] [-q] [-o file] input.yml
#
# rev 6a8d202e 20260824 213500 PDT Mon --- quoted flow scalars collected whole;
#                                      --- values pass through as markdown, YAML
#                                      --- escapes and folds expanded to real
#                                      --- breaks; markdown.sh chained on exit
# rev 6a8d10f2 20260824 205000 PDT Mon --- one pair per list item; a sequence
#                                      --- element holding a collection is an
#                                      --- empty + bullet with the collection
#                                      --- one level deeper; awk quoted inline
# rev 6a8d0212 20260824 194632 PDT Mon --- ported to markdown, validation and cleanup
# rev 69898512 20260208 225618 PST Sun --- inc rev yaml2html.awk structure model
# org 69897a9c 20260208 221140 PST Sun --- initial yaml2html.awk
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.

usage() { printf 'usage: %s [-d n] [-b n] [-A] [-c] [-q] [-o file] input.yml\n' "${0##*/}" ;}

long_help() { cat <<'help'
NAME
	yml2md.sh --- convert YAML block-style documents to Markdown

SYNOPSIS
	yml2md.sh [-d n] [-b n] [-A] [-c] [-q] [-o file] input.yml

DESCRIPTION
	Extracts the data structure of a YAML document into Markdown, deferring
	every presentation decision to the downstream renderer and stylesheet.
	Output is written to <input>.md unless -o names another target.

	Markdown has no generic nesting container, so the mapping from YAML is a
	compromise rather than a translation. Three output shapes carry it:

	headings     A mapping key that opens a nested block, standing on the
	             document spine (no sequence ancestor) and shallower than
	             the promotion depth, becomes a heading. Its children reset
	             to the document margin, which is what keeps deep documents
	             from marching off the right edge.

	definitions  A mapping key with a scalar value becomes **key:** value.
	             The bold key is load-bearing: markdown.sh consumes a
	             leading block of bare key: value lines as front matter,
	             and the emphasis markers are what keep the first mapping
	             of a document from being silently eaten. Values pass
	             through as the markdown they are, unescaped; a value
	             carrying line breaks stands below its key as blocks,
	             since a heading or a list has to begin a line to be one.

	list items   Everything below the promotion depth, and everything under
	             a sequence, becomes a bullet, one pair or one element per
	             line. Sequence elements take the + marker and mapping
	             pairs take the -, so the bullet itself says which is
	             which. An element holding a collection is an empty +
	             bullet with the collection one level deeper: a record is a
	             list of its fields, not a line of them.

	Lossy conversions are reported rather than refused: each is written to
	stderr as it occurs and collected into a terminal HTML comment block.

OPTIONS
	-d n	Heading promotion depth, default 2. 0 renders the whole
		document as nested lists.
	-b n	Base heading level, default 2 (h2). Depth is added to it and
		promotion stops at h6.
	-A	Suppress anchor and alias markup. YAML anchors otherwise emit
		{#y-name} and aliases emit a link to it, a markdown.sh
		extension that degrades to literal text elsewhere.
	-c	Preserve YAML comments as HTML comments where the output is at
		the document margin; report the rest.
	-q	Suppress the terminal note block; stderr still receives it.
	-o f	Write to f, or to stdout when f is -.
	-h	Usage summary.

MAPPING
	key: value              **key:** value
	key:                    heading, or **key:** with the block below it
	- scalar                + scalar
	- key: value            empty + bullet, then - **key:** value under it
	key: [a, b]             **key:** a, b
	key: {a: 1}             **key:** a: 1
	key: |                  fenced code block
	key: >                  folded into the value text
	key: 'runs on...        one value to its closing quote, folding expanded
	key: "a\nb"             escapes resolved, breaks made real
	key: 'it''s'            one quote, as the format means it
	key: &a value           value carrying {#y-a}
	key: *a                 link to #y-a
	? key / : value         **key:** value
	---                     thematic break between documents
	# comment               dropped, or preserved under -c

EXIT
	0 on success, 1 on usage or input error. Conversion compromises are
	notes, not failures, and do not change the exit status.
help
}

# --- Option and input validation ---
[[ "${1:-}" == --help ]] && { long_help ; exit 0 ;}

depth=2 ; base=2 ; anchors=1 ; keepc=0 ; quiet=0 ; outfile=""

while getopts :d:b:o:Acqh opt ;do
	case "$opt" in
	d) depth="$OPTARG" ;;
	b) base="$OPTARG" ;;
	o) outfile="$OPTARG" ;;
	A) anchors=0 ;;
	c) keepc=1 ;;
	q) quiet=1 ;;
	h) usage ; exit 0 ;;
	*) usage >&2 ; exit 1 ;;
	esac
done
shift $((OPTIND - 1))

[[ $# -eq 1 ]] || { usage >&2 ; exit 1 ;}

infile="$1"

# numeric knobs, bounded to what markdown can express
[[ "$depth" =~ ^[0-9]+$ ]] \
	|| { printf 'error: -d expects a count: %s\n' "$depth" >&2 ; exit 1 ;}
[[ "$base" =~ ^[1-6]$ ]] \
	|| { printf 'error: -b expects 1 to 6: %s\n' "$base" >&2 ; exit 1 ;}

# safe path characters only
[[ "$infile" =~ ^[A-Za-z0-9._/-]+$ ]] \
	|| { printf 'error: unsafe characters in path: %s\n' "$infile" >&2 ; exit 1 ;}

# require a yaml extension
[[ "$infile" == *.yml || "$infile" == *.yaml ]] \
	|| { printf 'error: input must end in .yml or .yaml: %s\n' "$infile" >&2 ; exit 1 ;}

[[ -f "$infile" ]] \
	|| { printf 'error: file not found: %s\n' "$infile" >&2 ; exit 1 ;}

[[ -n "$outfile" ]] || outfile="${infile}.md"

[[ "$outfile" == - || "$outfile" =~ ^[A-Za-z0-9._/-]+$ ]] \
	|| { printf 'error: unsafe characters in path: %s\n' "$outfile" >&2 ; exit 1 ;}

# --- Translation ---
# One invocation, output routed through fd 3, so the stdout target and the
# file target share a single code path.
exec 3>&1
[[ "$outfile" == - ]] || exec 3> "$outfile"

awk -v depth="$depth" -v base="$base" -v anchors="$anchors" \
	-v keepc="$keepc" -v quiet="$quiet" -v src="$infile" '
# YAML-to-Markdown extractor
#
# Converts YAML block-style documents to Markdown carrying structure only.
# The structure model is inherited from yaml2html.awk: an indent-keyed frame
# stack, one frame per open container, closed when a line returns to a
# shallower indent. What changes is the emission target. HTML nests without
# limit through div and li; markdown nests through indentation, which is
# legible for two or three levels and unreadable past that. Heading promotion
# is the answer: a container key on the document spine becomes a heading and
# its children return to the margin, spending heading levels rather than
# columns, until the promotion depth is exhausted and lists take over.
#
# Frames carry the output column at which their children write. A negative
# column is the document margin, where a key becomes a heading or a bold
# definition paragraph. A non-negative column is list context, where the
# column holds the marker and column+2 holds the content.
#
# A value is markdown, not a token to be escaped. Its quoting is resolved --
# a doubled quote is one quote, a backslash escape is the character it names,
# a numeric escape is an entity -- and its folding is expanded as the format
# defines it, so a run of n line breaks in the source carries n-1 breaks into
# the page. What arrives is the text as it was written before anything
# serialized it, and it is emitted as it stands: a value on one line beside
# its key, a value carrying breaks below its key as blocks.
#
# In list context every pair is its own bullet and every sequence element is
# its own bullet, one line each. The two are told apart by marker: + opens a
# sequence element, - opens a mapping pair. An element whose content is a
# collection carries no text of its own; it emits an empty + bullet and its
# collection opens one level deeper, which is what makes a record read as a
# list of its fields. Only a scalar element shares a line with its marker.
#
# The empty marker is + rather than -, and it carries the trailing space its
# reader needs to see a marker at all. A lone dash line invites a thematic
# break reading: markdown.sh matches "- " against its three-or-more-dash rule
# under mawk, whose interval quantifier over a group is unreliable, and the
# record separator would silently become an <hr>. No renderer reads + as a
# rule, so the ambiguity does not arise.
#
# One line of lookahead is held in pend, which buys two things: a folded
# scalar joins the key line that introduced it rather than orphaning the key,
# and a heading promoted for children that never arrive is demoted in place.
#
# Compromises are named, not hidden. Each is written to stderr as it occurs
# and deduplicated into a terminal comment block, so a conversion that lost
# something says so in both the operator channel and the artifact.
#
# limitations: type annotation is dropped as presentation, block scalars
#   inside a list require a CommonMark renderer, chomping indicators are
#   honored only for trailing newlines, a value carrying markdown keeps the
#   heading levels it was written with rather than being shifted under the
#   key that holds it
# compatibility: posix awk (bsd, darwin, gawk, mawk)

BEGIN {
	stderr = "cat 1>&2"
	sq = sprintf("%c", 39)   # the quote character, kept out of the program text
	# defaults, in case the knobs arrive unset
	if (depth == "") depth = 2
	if (anchors == "") anchors = 1
	depth = depth + 0 ; base = base + 0
	if (base < 1 || base > 6) base = 2
	# root frame: document margin, mapping depth zero
	top = 0
	f_ind[0] = 0 ; f_key[0] = -1 ; f_col[0] = -1 ; f_mcol[0] = -1
	f_dep[0] = 0 ; f_seq[0] = 0 ; f_mark[0] = 0 ; f_used[0] = 1
	f_item[0] = 0 ; f_flush[0] = 0 ; f_gap[0] = 0 ; f_head[0] = ""
	pend_on = 0 ; last_blank = 1 ; wrote = 0 ; cont_min = -1
	in_lit = 0 ; in_fold = 0 ; blk_ind = -1 ; blk_par = 0 ; blk_col = 0
	in_quote = 0 ; q_ch = "" ; q_nl = 0 ; q_started = 0 ; blk_bare = 0
	q_hold = 0 ; q_held = 0
	ckey_on = 0 ; ckey = "" ; ckey_ind = 0 ; nnote = 0
}

# --- Normalization ---
{ sub(/[[:space:]]+$/, "") }

# --- Block Scalar Collection ---
# Literal and folded scalars swallow every line indented past the key that
# opened them. The first such line fixes the block indent; a line at or above
# the key indent ends the block and falls through to normal processing.
in_lit || in_fold {
	if ($0 ~ /^[[:space:]]*$/) {
		if (in_lit) lit = lit "\n"
		else q_nl++
		next
	}
	match($0, /^ */) ; ci = RLENGTH
	if (blk_ind < 0 && ci > blk_par) blk_ind = ci
	if (blk_ind >= 0 && ci >= blk_ind) {
		bline = substr($0, blk_ind + 1)
		if (in_lit) lit = lit bline "\n"
		else q_add(bline)
		next
	}
	end_block()
}

# --- Quoted Flow Scalar Collection ---
# A quoted scalar that does not close on its opening line runs until its
# closing quote, and everything between belongs to the value: a # opens no
# comment, a --- separates no document, a : divides no key, and a - opens no
# element. This rule therefore stands ahead of all of them. Line breaks fold
# to spaces and a blank line becomes a paragraph break, which is what the
# format says the string means.
in_quote {
	if ($0 ~ /^[[:space:]]*$/) { q_nl++ ; next }
	qline = ltrim($0)
	qc = quote_end(qline, 1, q_ch)
	if (qc < 1) { q_add(qline) ; next }
	qrest = trim(substr(qline, qc + 1))
	q_add(substr(qline, 1, qc - 1))
	if (qrest != "") note("text after a closing quote dropped")
	end_quote()
	next
}

# --- Comments ---
!in_lit && !in_fold && /^[[:space:]]*#/ { if (keepc) put_comment($0) ; next }

# --- Document Separators ---
/^---([[:space:]].*)?$/ { doc_break() ; next }
/^\.\.\.([[:space:]].*)?$/ { flush_all() ; next }
/^[[:space:]]*$/ { next }

# --- Dispatch ---
# Inline comments are stripped first, then the frame stack is settled against
# this line indent, then the line content is routed. Whether the line opens a
# sequence element travels with it into pop_to, since a sequence written
# flush with the key that owns it must not close that key frame.
{
	$0 = decomment($0)
	if ($0 ~ /^[[:space:]]*$/) next
	if ($0 ~ /^ *\t/) note("tab in indentation; structure may be misread")
	match($0, /^ */) ; ci = RLENGTH
	text = substr($0, ci + 1)
	pop_to(ci, (text == "-" || substr(text, 1, 2) == "- "))
	f_used[top] = 1
	dispatch(text, ci, 0)
}

END {
	flush_all()
	dump_notes()
	close(stderr)
}

# --- Line Router ---
# Complex keys are tested before mappings, since a : value line would
# otherwise read as a mapping with an empty key. Sequence elements push an
# element frame and re-enter with the remainder, so - key: value, - - nested,
# and a bare - with its content below all travel one path.
function dispatch(text, ind, quiet_note,    rest, mi, cp) {
	if (text == "?" || substr(text, 1, 2) == "? ") {
		if (ckey_on) put_pair(ckey, "", ckey_ind)
		note("complex key rendered as a pair")
		ckey_on = 1 ; ckey = trim(substr(text, 2)) ; ckey_ind = ind
		return
	}
	if (ckey_on && (text == ":" || substr(text, 1, 2) == ": ")) {
		put_pair(ckey, trim(substr(text, 2)), ckey_ind)
		ckey_on = 0 ; ckey = ""
		return
	}
	if (ckey_on && ind > ckey_ind) { ckey = ckey " " text ; return }
	if (ckey_on) { put_pair(ckey, "", ckey_ind) ; ckey_on = 0 ; ckey = "" }

	if (text == "-" || substr(text, 1, 2) == "- ") {
		open_seq()
		mi = 1 ; rest = ""
		if (text != "-") {
			mi = 2 ; rest = substr(text, 3)
			while (substr(rest, 1, 1) == " ") { rest = substr(rest, 2) ; mi++ }
		}
		push_frame(ind, f_col[top], f_dep[top])
		f_mark[top] = 1 ; f_item[top] = 1 ; f_flush[top] = 0
		if (rest != "") dispatch(rest, ind + mi, 1)
		return
	}

	cp = key_colon(text)
	if (cp > 0) {
		put_pair(substr(text, 1, cp - 1), trim(substr(text, cp + 1)), ind)
		return
	}

	# a line at or past the continuation floor, with no marker owed, folds
	# into the pending line: this is a multi-line plain scalar, not a new
	# node. The floor is one column past a key, since a value continued
	# under a key must be indented, and the content column of a sequence
	# element, since the element text already starts there.
	if (pend_on && !f_mark[top] && cont_min >= 0 && ind >= cont_min) {
		pend = pend " " text
		return
	}
	if (!quiet_note) note("line carried through as text")
	put_scalar(text, ind)
}

# --- Mapping Pair ---
# An anchor on the value is lifted to markup on the key line; a block scalar
# indicator arms collection and emits the key line alone; an empty value
# opens a container. Placement depends only on the current frame column and
# mapping depth, so the same pair renders as a heading, a definition, or a
# list line according to where it stands.
function put_pair(key, val, ind,    k, a, v, opens, c, qe) {
	k = md(unquote(trim(key)))
	if (k == "") { k = "&lt;empty&gt;" ; note("empty key labeled &lt;empty&gt;") }
	a = ""
	if (substr(val, 1, 1) == "&") {
		a = val ; sub(/^&/, "", a) ; sub(/[[:space:]].*$/, "", a)
		val = trim(substr(val, length(a) + 2))
	}
	if (val ~ /^[|>][0-9]*[+-]?$/) { start_block(k, a, val, ind) ; return }
	c = substr(val, 1, 1)
	if (c == "\"" || c == sq) {
		qe = quote_end(val, 2, c)
		if (qe < 1) { start_quote(k, a, substr(val, 2), ind, c, 0) ; return }
		if (c == "\"" && qe == length(val) && index(val, "\\") > 0) {
			put_dq(k, a, ind, val, 0)
			return
		}
	}

	opens = (val == "")
	v = opens ? "" : value_text(val)
	if (v != "") v = " " v
	place_pair(k, a, v, opens, opens, ind)
}

# --- Key Placement ---
# Every key line arrives here, whatever introduced it. A key that opens
# something -- a nested block, a block scalar, a value carrying line breaks --
# is structural and may be promoted to a heading; a leaf key is a definition
# line. Only a key with children pushes a frame. last_col records where the
# block that follows must be written, which is the margin at document level
# and the content column of the pair inside a list.
function place_pair(k, a, v, structural, push, ind) {
	if (f_col[top] < 0) {
		blank()
		if (structural && depth > 0 && f_dep[top] < depth && base + f_dep[top] <= 6) {
			set_pend(hashes(base + f_dep[top]) " " k anch(a), "head")
			if (push) {
				push_frame(ind, -1, f_dep[top] + 1)
				f_head[top] = "**" k ":**" anch(a)
			}
			last_col = 0 ; cont_min = ind + 1
			return
		}
		set_pend("**" k ":**" v anch(a), "pair")
		if (push) push_frame(ind, 0, f_dep[top] + 1)
		last_col = 0 ; cont_min = ind + 1
		return
	}
	item_open()
	write_line("**" k ":**" v anch(a))
	last_col = f_col[top] + 2 ; cont_min = ind + 1
	if (push) push_frame(ind, f_col[top] + 2, f_dep[top] + 1)
}

# --- Scalar Line ---
# A scalar sequence element, or any line the router could not classify.
function put_scalar(text, ind,    c, qe) {
	c = substr(text, 1, 1)
	if (c == "\"" || c == sq) {
		qe = quote_end(text, 2, c)
		if (qe < 1) { start_quote("", "", substr(text, 2), ind, c, 1) ; return }
		if (c == "\"" && qe == length(text) && index(text, "\\") > 0) {
			put_dq("", "", ind, text, 1)
			return
		}
	}
	if (f_col[top] < 0) {
		blank()
		set_pend(value_text(text), "text")
		cont_min = ind
		return
	}
	write_line(value_text(text))
	cont_min = ind
}

# --- Block Scalar Start ---
# The key line is emitted as a container key would be, but no frame is
# pushed: a block scalar has content, not children. blk_col records where the
# fence or folded text will be written, which is the margin at document level
# and the content column of the pair inside a list.
function start_block(k, a, val, ind) {
	place_pair(k, a, "", 1, 0, ind)
	blk_col = last_col
	if (blk_col > 0 && substr(val, 1, 1) == "|")
		note("block scalar inside a list; fence needs a CommonMark renderer")
	cont_min = -1 ; blk_par = ind ; blk_ind = -1 ; blk_bare = 0
	q_ch = "" ; q_nl = 0 ; q_started = 0 ; q_hold = 0 ; q_held = 0
	blk_keep = (index(val, "+") > 0)
	if (substr(val, 1, 1) == "|") { in_lit = 1 ; lit = "" }
	else { in_fold = 1 ; fold = "" }
}

function end_block() {
	if (in_lit) end_lit()
	else if (in_fold) end_fold()
	else if (in_quote) { note("quoted scalar not closed at end of input") ; end_quote() }
}

# --- Quoted Flow Scalar ---
# The key line is emitted first, exactly as a block scalar key would be, and
# the value accumulates into the same buffer the folded emitter drains, so a
# quoted scalar and a folded scalar reach the page by one path. A sequence
# element carrying a bare quoted scalar has no key line to emit; its marker
# waits for the first paragraph, which claims it in end_fold.
# A quoted value holds its key line back until the value is in hand, since
# whether the key stands beside its value or above a block is a fact about
# the value, not about the quoting.
function start_quote(k, a, seg, ind, ch, bare) {
	q_k = k ; q_a = a ; q_ind = ind ; q_bare = bare
	cont_min = -1 ; in_quote = 1 ; q_ch = ch
	fold = "" ; q_started = 0 ; q_nl = 0 ; q_hold = 0 ; q_held = 0
	if (ltrim(seg) != "") q_add(ltrim(seg))
}

# A double-quoted scalar that closes on its own line can still carry its line
# breaks as escapes. It travels the same path so those breaks become breaks,
# rather than the two literal characters they are written as.
function put_dq(k, a, ind, val, bare) {
	q_k = k ; q_a = a ; q_ind = ind ; q_bare = bare
	q_ch = "\"" ; q_hold = 0 ; q_held = 0
	fold = dq_unescape(substr(val, 2, length(val) - 2))
	cont_min = -1
	end_quote()
}

# --- Quoted Value Emission ---
# One line beside the key, several lines below it. The key of a block is
# structural and promotes like any other container key; a bare element has no
# key at all and its marker is claimed by the first line of the value.
function put_value(k, a, ind, t, bare) {
	if (bare) {
		emit_text(t, (f_col[top] < 0) ? 0 : f_col[top] + 2, 1)
		return
	}
	if (index(t, "\n") == 0) {
		place_pair(k, a, (t == "" ? "" : " " t), 0, 0, ind)
		return
	}
	place_pair(k, a, "", 1, 0, ind)
	if (last_col > 0) note("multi-line value placed inside a list item")
	emit_text(t, last_col, 0)
}

function end_quote(    t) {
	in_quote = 0
	t = fold ; fold = ""
	sub(/[[:space:]]+$/, "", t)
	put_value(q_k, q_a, q_ind, t, q_bare)
}

# Folding, with the quoting style unescaped as it arrives: a doubled quote is
# one quote in the single-quoted style, a backslash pair is one character in
# the double-quoted style.
# Folding as the format defines it: a run of n line breaks carries n-1
# newlines, so a single break is a space and one blank line is one newline.
# That is what returns the original message text, paragraph breaks and list
# breaks intact, rather than a wall of prose. The doubled quote of the
# single-quoted style and the backslash escapes of the double-quoted style
# are resolved as each segment arrives; a segment held open by a trailing
# backslash joins the next one with no break at all.
function q_add(seg,    join) {
	join = " "
	if (q_ch == "") ;                 # a block scalar carries no escapes
	else if (q_ch == sq) gsub(sq sq, sq, seg)
	else {
		if (dq_open(seg)) { seg = substr(seg, 1, length(seg) - 1) ; q_hold = 1 }
		seg = dq_unescape(seg)
	}
	if (!q_started) { fold = seg ; q_started = 1 ; q_nl = 0 ; q_held = q_hold ; q_hold = 0 ; return }
	if (q_nl > 0) join = nl_run(q_nl)
	else if (q_held) join = ""
	fold = fold join seg
	q_nl = 0 ; q_held = q_hold ; q_hold = 0
}

function nl_run(n,    s) { s = "" ; while (n-- > 0) s = s "\n" ; return s }

# A double-quoted line ending in an odd number of backslashes ends in an
# escaped break: the break itself is dropped rather than folded to a space.
function dq_open(seg,    i, n) {
	n = 0
	for (i = length(seg); i > 0; i--) {
		if (substr(seg, i, 1) != "\\") break
		n++
	}
	return (n % 2)
}

# The escapes a JSON-derived document actually carries. A line break becomes
# a paragraph break, since the folded emitter separates on those and a bare
# newline in an emitted line would break the list it sits in.
function dq_unescape(s,    i, n, c, x, r) {
	r = "" ; n = length(s)
	for (i = 1; i <= n; i++) {
		c = substr(s, i, 1)
		if (c != "\\") { r = r c ; continue }
		x = substr(s, ++i, 1)
		if (x == "n" || x == "L" || x == "P") { r = r "\n" ; continue }
		if (x == "t") { r = r "\t" ; continue }
		if (x == "\"" || x == "\\" || x == "/" || x == " " || x == "N" || x == "_") {
			r = r (x == "N" || x == "_" ? " " : x) ; continue
		}
		if (x == "r" || x == "0" || x == "a" || x == "b" || x == "v" \
			|| x == "f" || x == "e") continue
		# a numeric escape becomes an entity, which keeps the output one byte
		# per character while naming the character it stands for
		if (x == "x") { r = r ent(substr(s, i + 1, 2)) ; i += 2 ; continue }
		if (x == "u") { r = r ent(substr(s, i + 1, 4)) ; i += 4 ; continue }
		if (x == "U") { r = r ent(substr(s, i + 1, 8)) ; i += 8 ; continue }
		note("backslash escape carried through: " x)
		r = r "\\" x
	}
	return r
}

function ent(hex,    h) {
	h = hex ; sub(/^0+/, "", h)
	if (h == "" || h !~ /^[0-9A-Fa-f]+$/) return ""
	return "&#x" h ";"
}

# The closing quote of a quoted scalar, or zero if the scalar runs on. A
# doubled quote escapes itself in the single-quoted style; a backslash
# escapes the next character in the double-quoted style.
function quote_end(s, start, ch,    i, n, c) {
	n = length(s)
	for (i = start; i <= n; i++) {
		c = substr(s, i, 1)
		if (ch == "\"" && c == "\\") { i++ ; continue }
		if (c != ch) continue
		if (ch == sq && substr(s, i + 1, 1) == sq) { i++ ; continue }
		return i
	}
	return 0
}

# --- Literal Block ---
# Emitted as a fenced code block, the only markdown construct that preserves
# interior whitespace and line structure without a language dependency. The
# fence lengthens if the content itself carries a fence line.
function end_lit(    s, fence, n, i, lines) {
	in_lit = 0 ; s = lit ; lit = "" ; blk_ind = -1
	if (blk_keep) sub(/\n$/, "", s)
	else sub(/\n+$/, "", s)
	fence = "```"
	while (s ~ ("(^|\n)" fence)) fence = fence "`"
	flush_pend()
	if (blk_col == 0) blank()
	putline(spaces(blk_col) fence)
	n = split(s, lines, "\n")
	for (i = 1; i <= n; i++)
		putline(lines[i] == "" ? "" : spaces(blk_col) lines[i])
	putline(spaces(blk_col) fence)
	last_blank = 0
}

# --- Folded Block ---
# Folded text is prose, so it joins the key line it belongs to rather than
# standing alone. A blank line in the source is a paragraph break: at the
# margin the remainder becomes further paragraphs, inside a list it becomes
# hard-broken lines within the same item, since a second bullet would claim
# the paragraph as a sibling of its own key.
function end_fold(    t) {
	in_fold = 0 ; t = fold ; fold = "" ; blk_ind = -1
	emit_text(t, blk_col, blk_bare)
}

# --- Value Text ---
# The value reaches the page as the markdown it is: nothing escaped, and its
# line breaks are line breaks. A value carrying breaks stands below its key
# rather than beside it, because a heading, a list, or a fence has to begin a
# line to be one. Inside a list the separators carry the item indent, so a
# conforming renderer reads the blocks as content of that item and a folding
# one still sees no empty line and keeps the item whole.
function emit_text(t, col, bare,    n, i, lines) {
	sub(/[[:space:]]+$/, "", t)
	if (t == "") return
	if (index(t, "\n") == 0) {
		if (bare) { write_line(t) ; return }
		if (pend_on && (pend_kind == "pair" || pend_kind == "item")) {
			pend = pend " " t
			return
		}
		if (col > 0) { flush_pend() ; putline(spaces(col) t) ; return }
		blank() ; set_pend(t, "text")
		return
	}
	n = split(t, lines, "\n")
	for (i = 1; i <= n; i++) {
		if (i == 1 && bare) { write_line(lines[1]) ; continue }
		if (i == 1) {
			if (col > 0) { flush_pend() ; putline(spaces(col)) }
			else blank()
		}
		flush_pend()
		putline(spaces(col) lines[i])
	}
}

# --- Frame Stack ---
# f_ind   shallowest indent that keeps the frame open
# f_key   indent of the key or marker that opened it
# f_col   output column of its children; negative is the document margin
# f_mcol  column of the empty marker an element frame still owes
# f_dep   mapping depth, spent on heading levels
# f_mark  an element marker owed to the next line emitted within the frame
# f_item  the frame is a sequence element, not a container
# f_flush its sequence may be written flush with its key
# f_gap   a blank line is owed above the list about to open at the margin
# f_head  the definition line to fall back to if no child ever arrives
# f_used  a child line has been emitted; f_seq the children are elements
function push_frame(keyind, col, dep,    parent) {
	parent = f_col[top]
	top++
	f_ind[top] = keyind + 1 ; f_key[top] = keyind
	f_col[top] = col ; f_mcol[top] = col ; f_dep[top] = dep
	f_seq[top] = 0 ; f_mark[top] = 0 ; f_item[top] = 0
	f_used[top] = 0 ; f_flush[top] = 1 ; f_head[top] = ""
	# a list opening at the margin wants a blank line above it
	f_gap[top] = (col == 0 && parent < 0)
}

# A sequence written flush with the key that owns it keeps that key frame
# open; anything else at the key indent closes it.
function pop_to(ind, seqline) {
	while (top > 0 && f_ind[top] > ind) {
		if (seqline && f_flush[top] && f_key[top] == ind \
			&& (f_seq[top] || !f_used[top])) break
		# a heading promoted for children that never arrived is a null value,
		# not a section; the line is still pending, so demote it in place
		if (!f_used[top] && f_head[top] != "" && pend_on && pend_kind == "head") {
			pend = f_head[top] ; pend_kind = "pair"
		}
		top--
	}
}

# --- Sequence Element ---
# An element whose content is a collection owes an empty marker: the marker
# stands alone and the collection opens at the element content column, so
# every pair of a record is its own line and the record is one list. A scalar
# element never reaches here; its marker is claimed by its own text.
function item_open() {
	if (!f_item[top] || !f_mark[top]) return
	if (f_gap[top]) { blank() ; f_gap[top] = 0 }
	flush_pend()
	putline(spaces(f_mcol[top]) "+ ")
	f_mark[top] = 0 ; f_item[top] = 0
	f_col[top] = f_mcol[top] + 2
}

# A sequence at the margin starts its markers at column zero; inside an
# element it starts at the element content column, which item_open sets.
function open_seq() {
	item_open()
	if (f_col[top] < 0) { f_gap[top] = 1 ; f_col[top] = 0 }
	if (f_gap[top]) { blank() ; f_gap[top] = 0 }
	f_seq[top] = 1
}

# --- Emission ---
# A frame owing an element marker spends it here on the scalar that follows;
# every other line in list context opens its own mapping bullet. Lines pass
# through pend, one line of lookahead, so the line just written stays
# available to a folded scalar or a demotion.
function write_line(text) {
	if (f_gap[top]) { blank() ; f_gap[top] = 0 }
	if (f_mark[top]) {
		f_mark[top] = 0 ; f_item[top] = 0
		set_pend(spaces(f_mcol[top]) "+ " text, "item")
		return
	}
	set_pend(spaces(f_col[top]) "- " text, "pair")
}

function set_pend(text, kind) {
	flush_pend()
	pend = text ; pend_kind = kind ; pend_on = 1
}

function flush_pend() {
	if (pend_on) { putline(pend) ; pend_on = 0 }
}

# blank separates blocks at the document margin only; inside a list an empty
# line would end the list itself.
function blank() {
	flush_pend()
	if (wrote && !last_blank) { print "" ; last_blank = 1 }
}

function putline(s) {
	print s
	last_blank = (s == "") ; wrote = 1
}

# --- Document Separator ---
# A separator opening the file is suppressed; between documents it renders as
# a thematic break, blank-separated so the preceding line is not read as a
# setext heading underlined by it. The root frame resets, since a new
# document restarts the depth count.
function doc_break() {
	flush_all()
	if (wrote) { blank() ; putline("---") ; blank() }
	f_col[0] = -1 ; f_mcol[0] = -1 ; f_dep[0] = 0 ; f_seq[0] = 0
	f_mark[0] = 0 ; f_item[0] = 0 ; f_gap[0] = 0 ; f_head[0] = ""
	cont_min = -1
}

function flush_all() {
	end_block()
	if (ckey_on) { put_pair(ckey, "", ckey_ind) ; ckey_on = 0 ; ckey = "" }
	pop_to(-1, 0)
	flush_pend()
}

# --- Value Rendering ---
# Aliases become links to the anchor their definition emitted, tags are
# dropped with a note, flow collections inline. Type is deliberately not
# encoded: yaml2html.awk marks number, boolean, and null with a class, and a
# class is presentation, which this stage does not own.
function value_text(v,    a, t) {
	if (v == "") return ""
	if (substr(v, 1, 1) == "*") {
		a = v ; sub(/^\*/, "", a) ; sub(/[[:space:]].*$/, "", a)
		if (anchors + 0) return "[\\*" a "](#y-" slug(a) ")"
		return md(v)
	}
	if (substr(v, 1, 1) == "!") {
		t = v ; sub(/[[:space:]].*$/, "", t)
		note("tag " t " dropped")
		v = trim(substr(v, length(t) + 1))
		return v == "" ? "" : value_text(v)
	}
	if (substr(v, 1, 1) == "[" && substr(v, length(v)) == "]") return flow_seq(v, 0)
	if (substr(v, 1, 1) == "{" && substr(v, length(v)) == "}") return flow_map(v, 0)
	v = unquote(v)
	if (substr(v, 1, 1) == "\"" || substr(v, 1, 1) == sq) return v
	return v
}

function flow_seq(v, nest,    n, a, i, r) {
	note(nest ? "nested flow sequence kept in brackets" \
		: "flow sequence inlined as a comma list")
	n = split_flow(substr(v, 2, length(v) - 2), a)
	r = ""
	for (i = 1; i <= n; i++) r = r (i > 1 ? ", " : "") flow_val(trim(a[i]))
	return nest ? "[" r "]" : r
}

function flow_map(v, nest,    n, a, i, r, cp, item) {
	note(nest ? "nested flow mapping kept in braces" \
		: "flow mapping inlined as a comma list")
	n = split_flow(substr(v, 2, length(v) - 2), a)
	r = ""
	for (i = 1; i <= n; i++) {
		item = trim(a[i])
		cp = key_colon(item)
		if (cp < 1) { r = r (i > 1 ? ", " : "") flow_val(item) ; continue }
		r = r (i > 1 ? ", " : "") unquote(trim(substr(item, 1, cp - 1))) \
			": " flow_val(trim(substr(item, cp + 1)))
	}
	return nest ? "{" r "}" : r
}

# An entry of a flow collection that is itself a flow collection keeps its
# brackets: flattening it would leave its commas indistinguishable from the
# commas of the collection holding it.
function flow_val(v) {
	if (substr(v, 1, 1) == "[" && substr(v, length(v)) == "]") return flow_seq(v, 1)
	if (substr(v, 1, 1) == "{" && substr(v, length(v)) == "}") return flow_map(v, 1)
	return value_text(v)
}

# Commas at bracket depth zero, outside quotes, separate flow entries.
function split_flow(s, a,    i, n, c, q, d, cur, cnt) {
	n = length(s) ; q = "" ; d = 0 ; cur = "" ; cnt = 0
	for (i = 1; i <= n; i++) {
		c = substr(s, i, 1)
		if (q != "") {
			cur = cur c
			if (c == q) q = ""
			continue
		}
		if (c == "\"" || c == sq) { q = c ; cur = cur c ; continue }
		if (c == "[" || c == "{") d++
		if (c == "]" || c == "}") d--
		if (c == "," && d == 0) { a[++cnt] = cur ; cur = "" ; continue }
		cur = cur c
	}
	if (trim(cur) != "" || cnt == 0) a[++cnt] = cur
	return cnt
}

# --- Key Separator ---
# The colon that divides key from value is the first one followed by space or
# end of line, which leaves a URL, a timestamp, and a namespaced value intact.
# A quoted key is skipped whole before the search begins.
function key_colon(s,    i, n, c, q) {
	n = length(s)
	if (n == 0) return 0
	c = substr(s, 1, 1)
	if (c == "\"" || c == sq) {
		q = c
		for (i = 2; i <= n; i++) {
			if (q == "\"" && substr(s, i, 1) == "\\") { i++ ; continue }
			if (substr(s, i, 1) == q) break
		}
		for (i++; substr(s, i, 1) == " "; i++) ;
		if (substr(s, i, 1) == ":" && (i == n || substr(s, i + 1, 1) == " ")) return i
		return 0
	}
	for (i = 1; i <= n; i++) {
		if (substr(s, i, 1) != ":") continue
		if (i == n || substr(s, i + 1, 1) == " ") return i
	}
	return 0
}

# --- Inline Comment Removal ---
# A # opens a comment only when preceded by whitespace and standing outside a
# quoted scalar.
function decomment(s,    i, n, c, q, cut) {
	if (index(s, "#") == 0) return s
	n = length(s) ; q = "" ; cut = 0
	for (i = 1; i <= n; i++) {
		c = substr(s, i, 1)
		if (q != "") { if (c == q) q = "" ; continue }
		if (c == "\"" || c == sq) { q = c ; continue }
		if (c == "#" && i > 1 && substr(s, i - 1, 1) == " ") { cut = i - 1 ; break }
	}
	if (cut == 0) return s
	s = substr(s, 1, cut)
	sub(/[[:space:]]+$/, "", s)
	return s
}

function put_comment(s,    t) {
	t = s ; sub(/^[[:space:]]*#[[:space:]]?/, "", t)
	if (t == "") return
	if (f_col[top] >= 0) { note("comment held out of a list: " t) ; return }
	blank()
	putline("<!-- " t " -->")
	last_blank = 0
}

# --- Text Escaping ---
# Characters that would otherwise become markup are neutralized: & and < as
# entities, the emphasis and link markers by backslash. An underscore inside
# a word is left alone, since snake_case is data, not emphasis.
function md(s,    i, n, c, p, x, r) {
	r = "" ; n = length(s)
	for (i = 1; i <= n; i++) {
		c = substr(s, i, 1)
		if (c == "&") { r = r "&amp;" ; continue }
		if (c == "<") { r = r "&lt;" ; continue }
		if (c == "_") {
			p = (i > 1) ? substr(s, i - 1, 1) : ""
			x = (i < n) ? substr(s, i + 1, 1) : ""
			r = r ((word_c(p) && word_c(x)) ? "_" : "\\_")
			continue
		}
		if (index("\\`*[]", c) > 0) { r = r "\\" c ; continue }
		r = r c
	}
	return r
}

function word_c(c) {
	return (c ~ /^[A-Za-z0-9]$/)
}

function unquote(s,    q) {
	q = substr(s, 1, 1)
	if ((q == "\"" || q == sq) && length(s) > 1 && substr(s, length(s)) == q) {
		s = substr(s, 2, length(s) - 2)
		if (q == "\"") gsub(/\\"/, "\"", s)
		else gsub(sq sq, sq, s)
	}
	return s
}

function anch(a) {
	if (a == "" || !(anchors + 0)) return ""
	return " {#y-" slug(a) "}"
}

function slug(s,    i, n, c, r) {
	r = "" ; n = length(s)
	for (i = 1; i <= n; i++) {
		c = substr(s, i, 1)
		r = r ((word_c(c) || c == "-" || c == "_") ? c : "-")
	}
	return r
}

# --- Notes ---
# Every compromise reaches stderr as it happens and the artifact once,
# deduplicated with a count, so a file full of flow collections reports the
# pattern rather than each instance.
function note(msg) {
	print (src == "" ? FILENAME : src) ":" NR ": " msg | stderr
	if (msg in note_cnt) { note_cnt[msg]++ ; return }
	note_cnt[msg] = 1 ; note_line[msg] = NR ; note_ord[++nnote] = msg
}

function dump_notes(    i, m) {
	if (nnote == 0 || quiet + 0) return
	blank()
	putline("<!-- yml2md notes")
	for (i = 1; i <= nnote; i++) {
		m = note_ord[i]
		putline("     line " note_line[m] ": " m \
			(note_cnt[m] > 1 ? " (x" note_cnt[m] ")" : ""))
	}
	putline("-->")
}

# --- Primitives ---
function spaces(n,    s) { s = "" ; while (n-- > 0) s = s " " ; return s }
function hashes(n,    s) { s = "" ; while (n-- > 0) s = s "#" ; return s }
function ltrim(s) { sub(/^[[:space:]]+/, "", s) ; return s }
function rtrim(s) { sub(/[[:space:]]+$/, "", s) ; return s }
function trim(s) { return rtrim(ltrim(s)) }
' "$infile" >&3

exec 3>&-

[[ "$outfile" == - ]] && exit 0

# preserve source timestamp on output
touch -r "$infile" "$outfile"

realpath "$outfile"

command -v markdown.sh >/dev/null && markdown.sh "$outfile" || true
