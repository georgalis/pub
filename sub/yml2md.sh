#!/usr/bin/env bash
set -euo pipefail

# yml2md.sh --- Bash envelope for yml2md.awk YAML-to-Markdown extractor
#
# Validates input, invokes the embedded awk translator, writes output to
# <input>.md (eg data.yml -> data.yml.md), and preserves the source file
# timestamp on the output via touch -r. Chains with markdown.sh, which
# renders <input>.yml.md to <input>.yml.md.html.
#
# Structure is decided here; presentation is not. The extractor emits no
# classes, no colors, and no type annotations -- those belong to the CSS
# applied at the HTML stage. What this stage decides is shape: which YAML
# construct becomes a heading, a definition line, a list item, or a fence.
#
# Usage: yml2md.sh [-d n] [-b n] [-A] [-c] [-q] [-o file] input.yml
#
# rev 6a8d0212 20260824 194632 PDT Mon --- ported to markdown, validation and cleanup
# rev 69898512 20260208 225618 PST Sun --- inc rev yaml2html.awk structure model
# org 69897a9c 20260208 221140 PST Sun --- initial yaml2html.awk
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
	             of a document from being silently eaten.

	list items   Everything below the promotion depth, and everything under
	             a sequence, becomes a bullet. A mapping renders as one item
	             carrying one line per pair, so a record in an array of
	             records stays visibly one record.

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
	- item                  - item
	- key: value            - **key:** value, siblings on following lines
	key: [a, b]             **key:** a, b
	key: {a: 1}             **key:** a: 1
	key: |                  fenced code block
	key: >                  folded into the value text
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

# --- Embedded awk translator ---
# Held in a variable rather than inline so the program is one verbatim block,
# extractable to a standalone yml2md.awk without quote surgery.
{ read -r -d '' prog || : ;} <<'eof'
# yml2md.awk --- YAML-to-Markdown extractor
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
# column holds the bullet and column+2 holds the content. A mapping in list
# context is one item whose pairs are successive lines, so the bullet marks
# the record and the lines mark its fields; the marker is therefore pending
# on the frame and claimed by whichever line is emitted first.
#
# One line of lookahead is held in pend, which buys two things: a trailing
# hard break can be added to a line after the next line proves it has a
# sibling, and a folded scalar can be joined onto the key line that
# introduced it rather than orphaning the key.
#
# Compromises are named, not hidden. Each is written to stderr as it occurs
# and deduplicated into a terminal comment block, so a conversion that lost
# something says so in both the operator channel and the artifact.
#
# limitations: nested flow collections flatten, type annotation is dropped
#   as presentation, block scalars inside a list require a CommonMark
#   renderer, chomping indicators are honored only for trailing newlines
# compatibility: posix awk (bsd, darwin, gawk, mawk)

BEGIN {
	stderr = "cat 1>&2"
	# defaults for the program run standalone, without the envelope
	if (depth == "") depth = 2
	if (anchors == "") anchors = 1
	depth = depth + 0 ; base = base + 0
	if (base < 1 || base > 6) base = 2
	# root frame: document margin, mapping depth zero
	top = 0 ; serial = 1
	f_id[0] = 1 ; f_ind[0] = 0 ; f_key[0] = -1 ; f_col[0] = -1
	f_dep[0] = 0 ; f_seq[0] = 0 ; f_mark[0] = 0 ; f_used[0] = 1
	f_gap[0] = 0 ; f_head[0] = "" ; f_item[0] = 0 ; f_mcol[0] = -1
	f_flush[0] = 0 ; pend_on = 0 ; last_blank = 1 ; wrote = 0 ; cont_min = -1
	in_lit = 0 ; in_fold = 0 ; blk_ind = -1 ; blk_par = 0 ; blk_col = 0
	ckey_on = 0 ; ckey = "" ; ckey_ind = 0 ; docs = 0 ; nnote = 0
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
		else fold = fold "\n\n"
		next
	}
	match($0, /^ */) ; ci = RLENGTH
	if (blk_ind < 0 && ci > blk_par) blk_ind = ci
	if (blk_ind >= 0 && ci >= blk_ind) {
		bline = substr($0, blk_ind + 1)
		if (in_lit) lit = lit bline "\n"
		else if (fold == "" || substr(fold, length(fold)) == "\n") fold = fold bline
		else fold = fold " " bline
		next
	}
	end_block()
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
# sequence item travels with it into pop_to, since a sequence written flush
# with the key that owns it must not close that key frame.
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
# otherwise read as a mapping with an empty key. Sequence items push an item
# frame and re-enter with the remainder, so - key: value, - - nested, and a
# bare - with its content below all travel one path.
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
	# item, since the item text already starts there.
	if (pend_on && !f_mark[top] && cont_min >= 0 && ind >= cont_min) {
		pend = pend " " md(text)
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
function put_pair(key, val, ind,    k, a, v, col, opens) {
	k = md(unquote(trim(key)))
	if (k == "") { k = "&lt;empty&gt;" ; note("empty key labeled &lt;empty&gt;") }
	a = ""
	if (substr(val, 1, 1) == "&") {
		a = val ; sub(/^&/, "", a) ; sub(/[[:space:]].*$/, "", a)
		val = trim(substr(val, length(a) + 2))
	}
	if (val ~ /^[|>][0-9]*[+-]?$/) { start_block(k, a, val, ind) ; return }

	opens = (val == "")
	v = opens ? "" : " " value_text(val)
	if (f_col[top] < 0) {
		if (opens && depth > 0 && f_dep[top] < depth && base + f_dep[top] <= 6) {
			blank()
			set_pend(hashes(base + f_dep[top]) " " k anch(a), -1, "head")
			push_frame(ind, -1, f_dep[top] + 1)
			f_head[top] = "**" k ":**" anch(a)
			cont_min = ind + 1
			return
		}
		blank()
		set_pend("**" k ":**" v anch(a), 0, "pair")
		cont_min = ind + 1
		if (opens) push_frame(ind, 0, f_dep[top] + 1)
		return
	}
	col = f_col[top] + 2
	write_line("**" k ":**" v anch(a), col, "pair")
	cont_min = ind + 1
	if (opens) push_frame(ind, col, f_dep[top] + 1)
}

# --- Scalar Line ---
# A sequence item scalar, or any line the router could not classify.
function put_scalar(text, ind) {
	if (f_col[top] < 0) {
		blank()
		set_pend(guard(value_text(text)), 0, "text")
		cont_min = ind
		return
	}
	write_line(value_text(text), f_col[top] + 2, "text")
	cont_min = ind
}

# --- Block Scalar Start ---
# The key line is emitted as a container key would be, but no frame is
# pushed: a block scalar has content, not children. blk_col records where the
# fence or folded text will be written, which is the margin at document level
# and the pair column inside a list.
function start_block(k, a, val, ind,    col) {
	if (f_col[top] < 0) {
		blank()
		if (depth > 0 && f_dep[top] < depth && base + f_dep[top] <= 6)
			set_pend(hashes(base + f_dep[top]) " " k anch(a), -1, "head")
		else
			set_pend("**" k ":**" anch(a), 0, "pair")
		blk_col = 0
	}
	else {
		col = f_col[top] + 2
		write_line("**" k ":**" anch(a), col, "pair")
		blk_col = col
		note("block scalar inside a list; fence needs a CommonMark renderer")
	}
	cont_min = -1 ; blk_par = ind ; blk_ind = -1
	blk_keep = (index(val, "+") > 0)
	if (substr(val, 1, 1) == "|") { in_lit = 1 ; lit = "" }
	else { in_fold = 1 ; fold = "" }
}

function end_block() {
	if (in_lit) end_lit()
	else if (in_fold) end_fold()
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
# hard-broken lines within the item.
function end_fold(    t, n, i, parts) {
	in_fold = 0 ; t = fold ; fold = "" ; blk_ind = -1
	gsub(/\n\n\n+/, "\n\n", t)
	sub(/^\n+/, "", t) ; sub(/\n+$/, "", t)
	if (t == "") return
	n = split(t, parts, "\n\n")
	for (i = 1; i <= n; i++) {
		if (i == 1 && pend_on && pend_kind == "pair") {
			pend = pend " " md(parts[i])
			continue
		}
		if (blk_col == 0) { blank() ; set_pend(guard(md(parts[i])), 0, "text") }
		else write_line(md(parts[i]), blk_col, "pair")
	}
}

# --- Frame Stack ---
# f_ind   shallowest indent that keeps the frame open
# f_key   indent of the key or bullet that opened it
# f_col   output column of its children; negative is the document margin
# f_mcol  column of the bullet it owes, fixed at push and never moved
# f_dep   mapping depth, spent on heading levels
# f_mark  a bullet owed to the next line emitted within the frame
# f_item  the frame is a sequence item, not a container
# f_flush its sequence may be written flush with its key
# f_gap   a blank line is owed above the list about to open at the margin
# f_head  the definition line to fall back to if no child ever arrives
# f_used  a child line has been emitted; f_seq the children are items
function push_frame(keyind, col, dep,    parent) {
	parent = f_col[top]
	top++ ; serial++
	f_id[top] = serial ; f_ind[top] = keyind + 1 ; f_key[top] = keyind
	f_col[top] = col ; f_dep[top] = dep ; f_seq[top] = 0
	f_used[top] = 0 ; f_head[top] = "" ; f_item[top] = 0 ; f_mcol[top] = col
	f_flush[top] = 1
	# a mapping in list context is one item, so the frame owes a bullet to
	# whichever line lands first; open_seq gives it back when the children
	# turn out to be sequence items, which carry their own
	f_mark[top] = (col >= 0)
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
			pend = f_head[top] ; pend_kind = "pair" ; pend_col = 0
		}
		top--
	}
}

# A sequence at the margin starts its bullets at column zero. A sequence
# inside a sequence item indents past the bullet the item still owes, which
# is why the owed column is recorded at push time and not read back from the
# frame column being moved here. A mapping container that turns out to hold a
# sequence gives back its own bullet; the items carry their own.
function open_seq() {
	if (f_col[top] < 0 && !f_item[top]) f_gap[top] = 1
	if (f_item[top]) { f_col[top] = f_col[top] + 2 ; f_item[top] = 0 }
	else {
		if (f_col[top] < 0) f_col[top] = 0
		if (f_gap[top]) { blank() ; f_gap[top] = 0 }
		f_mark[top] = 0
	}
	f_seq[top] = 1
}

# --- Emission ---
# Every line passes through pend, one line of lookahead. A pair following a
# pair of the same frame at the same column proves the earlier line has a
# sibling, so a hard break is appended to it; renderers that fold the pair
# into one line lose the break, not the data.
function write_line(text, col, kind,    i, pre, mcol) {
	if (f_gap[top]) { blank() ; f_gap[top] = 0 }
	pre = "" ; mcol = col
	for (i = 0; i <= top; i++)
		if (f_mark[i]) {
			if (pre == "") mcol = f_mcol[i]
			pre = pre "- " ; f_mark[i] = 0
		}
	if (pend_on && kind == "pair" && pend_kind == "pair" \
		&& pend_col == col && pend_fid == f_id[top] && col > 0)
		pend = pend "  "
	set_pend(spaces(mcol) pre text, col, kind)
}

function set_pend(text, col, kind) {
	flush_pend()
	pend = text ; pend_col = col ; pend_kind = kind
	pend_fid = f_id[top] ; pend_on = 1
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
	docs++
	f_col[0] = -1 ; f_dep[0] = 0 ; f_seq[0] = 0 ; f_mark[0] = 0
	f_gap[0] = 0 ; f_head[0] = "" ; cont_min = -1
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
		if (anchors + 0) return "[\\*" md(a) "](#y-" slug(a) ")"
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
	return md(unquote(v))
}

function flow_seq(v, nest,    n, a, i, r) {
	note(nest ? "nested flow sequence kept in brackets" \
		: "flow sequence inlined as a comma list")
	n = split_flow(substr(v, 2, length(v) - 2), a)
	r = ""
	for (i = 1; i <= n; i++) r = r (i > 1 ? ", " : "") flow_val(trim(a[i]))
	return nest ? "[" r "]" : r
}

# An entry of a flow collection that is itself a flow collection keeps its
# brackets: flattening it would leave its commas indistinguishable from the
# commas of the collection holding it.
function flow_val(v) {
	if (substr(v, 1, 1) == "[" && substr(v, length(v)) == "]") return flow_seq(v, 1)
	if (substr(v, 1, 1) == "{" && substr(v, length(v)) == "}") return flow_map(v, 1)
	return value_text(v)
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
		r = r (i > 1 ? ", " : "") md(unquote(trim(substr(item, 1, cp - 1)))) \
			": " flow_val(trim(substr(item, cp + 1)))
	}
	return nest ? "{" r "}" : r
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
		if (c == "\"" || c == "'") { q = c ; cur = cur c ; continue }
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
	if (c == "\"" || c == "'") {
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
		if (c == "\"" || c == "'") { q = c ; continue }
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

# A line standing at the margin must not open a block by accident.
function guard(s) {
	if (s ~ /^[#>|+=-]/ || s ~ /^[0-9]+\./) return "\\" s
	return s
}

function unquote(s,    q) {
	q = substr(s, 1, 1)
	if ((q == "\"" || q == "'") && length(s) > 1 && substr(s, length(s)) == q) {
		s = substr(s, 2, length(s) - 2)
		if (q == "\"") gsub(/\\"/, "\"", s)
		else gsub(/''/, "'", s)
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
eof

# --- Translation ---
# One invocation, output routed through fd 3, so the stdout target and the
# file target share a single code path.
exec 3>&1
[[ "$outfile" == - ]] || exec 3> "$outfile"

awk -v depth="$depth" -v base="$base" -v anchors="$anchors" \
	-v keepc="$keepc" -v quiet="$quiet" -v src="$infile" \
	"$prog" "$infile" >&3

exec 3>&-

[[ "$outfile" == - ]] && exit 0

# preserve source timestamp on output
touch -r "$infile" "$outfile"

realpath "$outfile"
