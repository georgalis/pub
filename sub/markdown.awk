#!/usr/bin/awk -f

# markdown.awk --- Markdown-to-HTML renderer with GitHub-compatible extensions
#
# Converts Markdown input to HTML, supporting: headings (ATX and setext),
# paragraphs, blockquotes, ordered/unordered lists with nesting, fenced and
# indented code blocks, inline code, emphasis/strong/strong-em, links, images,
# horizontal rules, inline HTML passthrough, and backslash escapes.
#
# Extensions beyond upstream:
#
#   Anchor IDs         Headings emit id= attributes via GitHub's slug algorithm
#                      (lowercase, spaces to hyphens, strip non-alphanumeric,
#                      collapse runs, trim). Custom IDs via {#custom-id} suffix.
#
#   Inline anchors     {#id} outside headings emits <a id="id"></a> as a
#                      zero-width anchor point for cross-referencing.
#
#   Local link rewrite ./relative.md links (href and display text) are rewritten
#                      to .md.html, preserving source identity in the rendered
#                      filename. Markdown remains the master format; GitHub
#                      renders .md links correctly, while static HTML output
#                      (file.md.html) links to sibling rendered HTML. Only
#                      ./prefixed paths are rewritten; absolute, bare, and
#                      external URLs are untouched. Code spans and fenced blocks
#                      are immune by virtue of the parse pipeline order.
#
#   HTML comments     <!-- comment --> blocks are preserved verbatim in the
#                      rendered HTML at both block and inline levels. Block
#                      comments (standalone lines) accumulate across newlines
#                      until --> closes the comment; inline comments pass
#                      through within paragraph text.
#
#   Metadata skip      A leading block of "key: value" lines (front matter) is
#                      silently consumed rather than rendered.
#
# (c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
# rev 699baa0b 20260222 171451 PST Sun --- fixup italic hyperlinks etc
# rev 699b97c1 20260222 155649 PST Sun --- HTML envelope with ./default.css, comment passthrough
# rev 699b82d8 20260222 142736 PST Sun --- list corrections, .md.html rewrite, comments
# rev 699a0d4d 20260221 115349 PST Sat --- local .md link rewrite
# rev 6985fbed 20260206 063411 PST Fri --- anchor IDs, {#custom-id} support
#
# Upstream:
#   git@github.com:knazarov/markdown.awk.git
#   commit ac6e5e934a0988c873172fe5ef0614e9dcd689ea
#   Author: Konstantin Nazarov <mail@knazarov.com>
#   Date:   Sun Aug 22 17:21:47 2021 +0100
#   Distributed under the terms of the BSD License
#
# Output wraps content in an HTML document envelope referencing ./default.css
# for typographic presentation via standard HTML element selectors. No custom
# classes or divisions are emitted; all styling hooks are native markup tags.
#
# Usage: awk -f markdown.awk input.md > output.html

# --- Initialization ---
# body accumulates the current block across input lines.
# first_paragraph gates metadata detection to the document's first block.
# Emits the HTML document envelope with a stylesheet reference; all styling
# targets standard HTML element selectors emitted by the parser.
BEGIN {
	body = ""
	first_paragraph = 1
	print "<!DOCTYPE html>"
	print "<html lang=\"en\">"
	print "<head>"
	print "<meta charset=\"utf-8\">"
	print "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
	print "<link rel=\"stylesheet\" href=\"./default.css\">"
	print "</head>"
	print "<body>"
}

# --- Anchor ID Generation ---
# Implements GitHub's heading slug algorithm: lowercase, retain [a-z0-9],
# convert spaces and hyphens to single hyphens, strip everything else,
# collapse consecutive hyphens, trim leading/trailing hyphens.
# Used as fallback when no {#custom-id} is present on a heading.
function make_anchor_id(str,    id, i, c) {
	id = "";
	str = str;
	for (i=1; i<=length(str); i++) {
		c = substr(str, i, 1);
		# manual tolower: offset into uppercase alphabet, add 96 for ASCII lowercase
		if (c >= "A" && c <= "Z")
			c = sprintf("%c", index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", c) + 96);
		if ((c >= "a" && c <= "z") || (c >= "0" && c <= "9"))
			id = id c;
		else if (c == " " || c == "-")
			id = id "-";
		# all other characters silently dropped
	}
	while (index(id, "--") > 0)
		gsub(/--/, "-", id);   # collapse hyphen runs
	gsub(/^-+/, "", id);      # trim leading
	gsub(/-+$/, "", id);      # trim trailing
	return id;
}

# --- Heading Parser ---
# Handles ATX (# prefix) and setext (underline) heading syntax.
# Extracts an optional {#custom-id} suffix from the heading text; when absent,
# generates an anchor via make_anchor_id(). The anchor is emitted as the id
# attribute on the heading element.
# ATX: strips trailing #-sequences and leading #-sequences to determine level.
# Setext: = underline -> h1, - underline -> h2; detected via body pattern match.
function parse_header(str,    hnum, content, anchor) {
	if (substr(str, 1, 1) == "#") {
		gsub(/ *#* *$/, "", str);       # strip trailing # and whitespace
		match(str, /#+/);
		hnum = RLENGTH;                 # heading level = count of leading #

		gsub(/^#+ */, "", str);         # strip leading # and whitespace
		anchor = "";
		if (match(str, /[[:space:]]*\{#[^}]+\}$/)) {
			# extract explicit {#id} from end of heading text
			anchor = substr(str, RSTART, RLENGTH);
			str = substr(str, 1, RSTART - 1);
			gsub(/^[[:space:]]*\{#/, "", anchor);
			gsub(/\}$/, "", anchor);
		}
		content = parse_line(str);
		if (anchor == "")
			anchor = make_anchor_id(str);
		return "<h" hnum " id=\"" anchor "\">" content "</h" hnum ">";
	}
	# setext h1: text followed by line of ='s
	if (match(body, /^[^\n]+\n=+$/)) {
		gsub(/\n=+$/, "", str);
		anchor = "";
		if (match(str, /[[:space:]]*\{#[^}]+\}$/)) {
			anchor = substr(str, RSTART, RLENGTH);
			str = substr(str, 1, RSTART - 1);
			gsub(/^[[:space:]]*\{#/, "", anchor);
			gsub(/\}$/, "", anchor);
		}
		if (anchor == "")
			anchor = make_anchor_id(str);
		return "<h1 id=\"" anchor "\">" parse_line(str) "</h1>"
	}
	# setext h2: text followed by line of -'s
	if (match(body, /^[^\n]+\n-+$/)) {
		gsub(/\n-+$/, "", str);
		anchor = "";
		if (match(str, /[[:space:]]*\{#[^}]+\}$/)) {
			anchor = substr(str, RSTART, RLENGTH);
			str = substr(str, 1, RSTART - 1);
			gsub(/^[[:space:]]*\{#/, "", anchor);
			gsub(/\}$/, "", anchor);
		}
		if (anchor == "")
			anchor = make_anchor_id(str);
		return "<h2 id=\"" anchor "\">" parse_line(str) "</h2>"
	}
	return "";
}

# --- Line Reader ---
# Extracts a single line from str starting at position pos, stopping at
# newline or end-of-string. Used for positional line access within a block.
function read_line(str, pos, res, i) {
	res = "";
	for (i=pos; i<=length(str); i++) {
		if (substr(str, i, 1) == "\n")
			return res;
		res = res substr(str, i, 1);
	}

	return res;
}

# --- Substring Search ---
# Returns the position of substring s within str starting at index i,
# or 0 if not found. Linear scan; used for delimiter matching in inline parsing.
function find(str, s, i,    sl, j) {
	sl = length(s);
	for (j = i; j <= length(str); j++) {
		if (substr(str, j, sl) == s)
			return j;
	}

	return 0;
}

# --- Prefix Match with Leading Whitespace ---
# Returns the position where s begins within str, skipping leading spaces.
# Returns 0 if a non-space character precedes s. Used for indentation-aware
# block detection.
function startswith(str, s,    sl, j) {
	sl = length(s);	
	for (j = 1; j <= length(str); j++) {
		if (substr(str, j, sl) == s)
			return j;
		if (substr(str, j, 1) != " ")
			return 0;
	}
	return 0;
}

# --- Whitespace Strippers ---
# rstrip: remove trailing spaces and newlines.
# lstrip: remove leading spaces and newlines.
function rstrip(str) {
	gsub(/ *\n*$/, "", str);
	return str;
}

function lstrip(str) {
	gsub(/^ *\n*/, "", str);
	return str;
}

# Placeholder; reserved for future special-character escaping at block level.
function escape_special() {
	
}

# --- Line Joiner ---
# Concatenates two strings with a separator (default space). Returns whichever
# is non-empty, or the joined result. Used throughout for accumulating output
# and merging continuation lines.
function join_lines(first, second, sep) {
	if (sep == "")
		sep = " ";

	if (second == "")
		return first;

	if (first == "")
		return second;

	return first sep second;
}

# --- List Marker Stripper ---
# Removes the leading bullet (-, +, *) or ordered (N.) marker and its trailing
# whitespace from a list item line, leaving the item content.
function strip_list(str) {
	gsub(/^[[:space:]]*[-+*][[:space:]]/, "", str);
	gsub(/^[[:space:]]*[[:digit:]]*\.[[:space:]]/, "", str);
	return str;
}

# --- List Parser ---
# Parses a block of list items into nested <ul>/<ol> structures.
# First pass: merges continuation lines (non-marker lines) onto the preceding
# item via space-join. Second pass: splits on markers, tracks indent depth for
# nesting via recursive parse_list() calls, and detects mid-list transitions
# between bullet and ordered styles.
function parse_list(str,    buf, result, i, ind, line, lines, indent, is_bullet) {
	result = "";
	buf = "";

	split(str, lines, "\n");

	# first pass: fold continuation lines into their parent item
	str = ""
	for (i=1; i<=length(lines); i++) {
		line = lines[i];

		if (match(line, /^[[:space:]]*[-+*][[:space:]]/) || 
			match(line, /^[[:space:]]*[[:digit:]]+\.[[:space:]]/))
			str = join_lines(str, line, "\n");  # new item: newline-separated
		else
			str = join_lines(rstrip(str), lstrip(line), " ");  # continuation: space-joined
	}

	split(str, lines, "\n")

	indent = match(str, /[^ ]/);    # baseline indent of first item
	is_bullet = match(str, /^[[:space:]]*[-+*][[:space:]]/)

	if (is_bullet)
		result = "<ul>\n"
	else
		result = "<ol>\n"

	for (i=1; i<=length(lines); i++) {
		line = lines[i];

		# deeper indent than baseline: accumulate for recursive sub-list
		if (match(line, "[^ ]") > indent) {
			buf = join_lines(buf, line, "\n");
			continue
		}

		indent = match(line, "[^ ]");  # update baseline to current indent

		if (buf != "") {
			result = join_lines(result, parse_list(buf), "\n");  # recurse nested items
			buf = "";
		}
		if (i > 1)
			result = result "</li>\n"

		# detect mid-list type transitions (bullet <-> ordered)
		if (is_bullet && match(line, /[[:space:]]*[[:digit:]]+\.[[:space:]]/)) {
			is_bullet = 0;
			result = result "</ul>\n<ol>\n";
		}
		if (is_bullet == 0 && match(line, /[[:space:]]*[-+*][[:space:]]/)) {
			is_bullet = 1;
			result = result "</ol>\n<ul>\n";
		}

		result = result "<li>" parse_line(strip_list(line))
	}

	if (buf != "") {
		result = join_lines(result, parse_list(buf), "\n")
	}
	result = result "</li>";

	if (is_bullet)
		result = result "\n</ul>";
	else
		result = result "\n</ol>";

	return result;
}

# --- Token Match ---
# Tests whether the substring at position i in str equals tok.
function is_token(str, i, tok) {
	return substr(str, i, length(tok)) == tok;
}

# --- HTML Tag Extraction ---
# Matches a complete HTML tag (opening or closing) at position i in str.
# Opening tags may contain attribute="value" pairs. Returns the full tag
# string, or "" if no valid tag is found. Allows inline HTML passthrough.
function extract_html_tag(str, i,    sstr) {
    sstr=substr(str, i, length(str) - i + 1);

    if (match(sstr, /^<\/[a-zA-Z][a-zA-Z0-9]*>/))        # closing tag
		return substr(str, i, RLENGTH) ;

    if (match(sstr, /^<[a-zA-Z][a-zA-Z0-9]*( *[a-zA-Z][a-zA-Z0-9]* *= *"[^"]*")* *>/))  # opening tag
		return substr(str, i, RLENGTH);

	return "";
}

# --- HTML Tag Predicate ---
# Boolean wrapper for extract_html_tag().
function is_html_tag(str, i,    sstr) {
	if (extract_html_tag(str, i) == "")
		return 0;

	return 1;
}

# --- Escape Sequence Detection ---
# Checks if position i in str begins a Markdown backslash escape (e.g. \*, \[).
# The escaped character is emitted as literal text by the caller.
function is_escape_sequence(str, i,    sstr) {
	sstr=substr(str, i, length(str) - i + 1);

	return match(sstr, /^\\[`\\*_{}\[\]()>#.!+-]/);
}

# --- Link Extraction ---
# Matches a complete Markdown link [text](url "optional title") at position i.
# Returns the full matched string, or "" if the pattern does not match.
function extract_link(str, i,    sstr) {
	sstr=substr(str, i, length(str) - i + 1);

	if (!match(sstr, /^\[([^\[\]]*)\]\( *([^() ]*)( +"([^"]*)")? *\)/))
		return "";

	return substr(str, i, RLENGTH);
}

# Link Parser and Local .md Rewriter ---
# Decomposes a Markdown link into name, url, and optional title, then emits
# an <a> element. Link text (name) is parsed for inline markup (emphasis,
# code, etc.) via parse_line() to support constructs like [_italic_](url).
# After URL extraction but before tag emission, applies the local link
# rewrite: ./relative.md hrefs and display text are converted to .md.html, preserving source identity in the rendered filename. The rewrite
# operates at the parsed-link semantic layer, so code spans and fenced blocks
# are inherently immune (they never reach this function).
#
# URL rewrite guard:
#   url ~ /^\.\//            must be ./-prefixed (local relative)
#   url ~ /\.md($|[?#])/    .md must terminate the filename (before ?, #, or EOL)
#   sub(/\.md/, ".md.html")  appends .html; file.md -> file.md.html
#
# Name rewrite guard:
#   name ~ /^\.\//           display text is itself a ./ path
#   name ~ /\.md$/           ends with .md (no query/fragment in display text)
function parse_link(str,    arr) {
	match(str, /^\[([^\[\]]*)\]/);
	name = substr(str, 2, RLENGTH-2);   # extract text between [ ]
	sub(/^\[([^\[\]]*)\]/, "", str);     # consume [text] from str

	sub(/^ *\( */, "", str);             # strip opening ( and surrounding space
	sub(/ *\) *$/, "", str);             # strip closing ) and surrounding space

	match(str, /^[^() ]*/);
	url = substr(str, 1, RLENGTH);       # url = everything before space or parens

	# local .md -> .md.html rewrite for static HTML browsing;
	# preserves .md identity so rendered filenames trace to their source
	if (url ~ /^\.\// && url ~ /\.md($|[?#])/)
		sub(/\.md/, ".md.html", url);
	if (name ~ /^\.\// && name ~ /\.md$/)
		sub(/\.md$/, ".md.html", name);

	sub(/^[^() ]*/, "", str);            # consume url from remainder
	sub(/^ *"/, "", str);                # strip opening quote of title
	sub(/" *$/, "", str);                # strip closing quote of title
	title = str;                         # whatever remains is the title

	if (title == "") {
		return "<a href=\"" url "\">" parse_line(name) "</a>"
	}
	return "<a href=\"" url "\" title=\"" title "\">" parse_line(name) "</a>"
}

# --- Image Extraction ---
# Matches a Markdown image ![alt](src "optional title") at position i.
# Returns the full matched string, or "" if the pattern does not match.
function extract_image(str, i,    sstr) {
	sstr=substr(str, i, length(str) - i + 1);

	if (!match(sstr, /^!\[([^\[\]]*)\]\( *([^() ]*)( +"([^"]*)")? *\)/))
		return "";

	return substr(str, i, RLENGTH);
}

# --- Image Parser ---
# Decomposes a Markdown image into alt text, src URL, and optional title,
# then emits a self-closing <img> element.
function parse_image(str,    arr) {
	match(str, /^!\[([^\[\]]*)\]/);
	name = substr(str, 3, RLENGTH-3);   # alt text between ![ ]
	sub(/^!\[([^\[\]]*)\]/, "", str);

	sub(/^ *\( */, "", str);
	sub(/ *\) *$/, "", str);

	match(str, /^[^() ]*/);
	url = substr(str, 1, RLENGTH);

	sub(/^[^() ]*/, "", str);
	sub(/^ *"/, "", str);
	sub(/" *$/, "", str);
	title = str;

	if (title == "") {
		return "<img src=\"" url "\" alt=\"" name "\" />"
	}
	return "<img src=\"" url "\" alt=\"" name "\" title=\"" title "\" />"
}

# --- Link/Image Predicates ---
# Boolean wrappers for extract_link() and extract_image().
function is_link(str, i) {
	return extract_link(str, i) != "";
}

function is_image(str, i) {
	return extract_image(str, i) != "";
}

# --- HTML Entity Escaping ---
# Converts &, <, > to their HTML entity equivalents. Applied to literal text
# and to content within inline code spans. Must process & first to avoid
# double-escaping.
function escape_text(str) {
	gsub(/&/, "\\&amp;", str);
	gsub(/</, "\\&lt;", str);
	gsub(/>/, "\\&gt;", str);
	return str;
}

# --- Word Character Test ---
# Returns 1 if c is alphanumeric or underscore (word character per GitHub
# emphasis boundary rules). Used to gate _ emphasis delimiters.
function is_word_char(c) {
	return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || \
	       (c >= "0" && c <= "9") || c == "_";
}

# --- Underscore Emphasis Extraction ---
# Extracts _em_, __strong__, or ___strong-em___ spans with GitHub-compatible
# word-boundary rules: the closing _ delimiter must be followed by a non-word
# character or end of string, and preceded by a non-whitespace character.
# This prevents mid-word/mid-URL underscores from triggering false emphasis.
# Tries longest delimiter first (triple, double, single).
function extract_underscore_emphasis(str, i,    sstr, dlen, j, nc, pc, target) {
	sstr = substr(str, i, length(str) - i + 1);
	# determine opening delimiter length (up to 3)
	dlen = 0;
	for (j = 1; j <= 3 && j <= length(sstr); j++) {
		if (substr(sstr, j, 1) == "_") dlen++;
		else break;
	}
	if (dlen == 0) return "";

	# try longest delimiter first for greedy match
	while (dlen >= 1) {
		target = substr("___", 1, dlen);
		for (j = dlen + 2; j <= length(sstr) - dlen + 1; j++) {
			if (substr(sstr, j, dlen) == target) {
				# closing _ must follow non-whitespace, precede non-word or end
				pc = substr(sstr, j - 1, 1);
				nc = (j + dlen <= length(sstr)) \
					? substr(sstr, j + dlen, 1) : "";
				if (pc != " " && pc != "\n" && \
				    (nc == "" || !is_word_char(nc)))
					return substr(str, i, j + dlen - 1);
			}
		}
		dlen--;
	}
	return "";
}

# --- Emphasis Extraction ---
# Matches * emphasis delimiters (*, **, ***) at position i and returns the
# full delimited span. Tests from triple down to single to capture the
# longest match first. Underscore emphasis is handled separately by
# extract_underscore_emphasis() which enforces GitHub word-boundary rules.
function extract_emphasis(str, i,    sstr) {
	sstr=substr(str, i, length(str) - i + 1);

	if (match(sstr, /^\*[^\*]+\*/) ||
	    match(sstr, /^\*\*[^\*]+\*\*/) ||
	    match(sstr, /^\*\*\*[^\*]+\*\*\*/))
		return substr(str, i, RLENGTH);

	return "";
}

# --- Emphasis Parser ---
# Wraps the inner content in <em>, <strong>, or <strong><em> depending on
# delimiter count. Inner content is recursively parsed for nested inline markup.
function parse_emphasis(str, i) {
	match(str, /^[\*_]{1,3}/);
	num = RLENGTH;                       # 1=em, 2=strong, 3=strong+em

	if (num == 1) {
		return "<em>" parse_line(substr(str, 2, length(str) - 2)) "</em>";
	}
	if (num == 2) {
		return "<strong>" parse_line(substr(str, 3, length(str) - 4)) "</strong>";
	}
	if (num == 3) {
		return "<strong><em>" parse_line(substr(str, 4, length(str) - 6)) "</em></strong>";
	}
	return "";
}

# --- Inline Parser ---
# Character-by-character state machine that converts a line of Markdown text
# into HTML. Processes inline elements in priority order: emphasis, triple
# backtick code, single backtick code, raw HTML tags, backslash escapes,
# inline anchors {#id}, links, images, and literal text with entity escaping.
# Newlines within a block are normalized to spaces.
function parse_line(str,    result, end, i, c) {
	result = ""

	for (i=1; i<=length(str); i++) {
		c = substr(str, i, 1);

		# asterisk emphasis (no word-boundary requirement)
		if (c == "*" && extract_emphasis(str, i) != ""){
			emphasis = extract_emphasis(str, i);
			result = result parse_emphasis(emphasis)
			i = i + length(emphasis) - 1;  # advance past closing delimiter
		}
		# underscore emphasis with GitHub word-boundary rules:
		# opening _ must be preceded by non-word char or start of string
		else if (c == "_") {
			prev = (i > 1) ? substr(str, i-1, 1) : "";
			if ((prev == "" || !is_word_char(prev)) && \
			    extract_underscore_emphasis(str, i) != "") {
				emphasis = extract_underscore_emphasis(str, i);
				result = result parse_emphasis(emphasis);
				i = i + length(emphasis) - 1;
			}
			else {
				result = result escape_text(c);
			}
		}
		# triple backtick inline code (```)
		else if (c == "`" && is_token(str, i, "```")) {
			end = find(str, "```", i+3);
			if (end != 0) {
				result = result "<code>" escape_text(substr(str, i+3, end - i - 3)) "</code>";
				i = end+2;
			}
			else {
				result = result "```";     # unmatched: emit literal
				i=i+2;
			}
		}
		# single backtick inline code
		else if (c == "`" && substr(str, i, 1) == "`") {
			end = find(str, "`", i+1);
			if (end != 0) {
				result = result "<code>" escape_text(substr(str, i+1, end - i - 1)) "</code>";
				i = end;
			}
			else {
				result = result "`";       # unmatched: emit literal
			}
		}
		# inline HTML comment passthrough
		else if (c == "<" && is_token(str, i, "<!--")) {
			end = find(str, "-->", i+4);
			if (end != 0) {
				result = result substr(str, i, end - i + 3);
				i = end + 2;
			}
			else {
				result = result escape_text(c);  # unmatched: escape literal
			}
		}
		# inline HTML passthrough
		else if (c == "<" && is_html_tag(str, i)) {
			tag = extract_html_tag(str, i);
		    result = result tag;
			i = i + length(tag) - 1;
		}
		# backslash escape
		else if (c == "\\" && is_escape_sequence(str, i)) {
			result = result escape_text(substr(str, i+1, 1));
		    i = i + 1;
		}
		# inline anchor {#id} --- emits zero-width <a id=""> outside headings
		else if (c == "{" && match(substr(str, i), /^\{#[A-Za-z][A-Za-z0-9._-]*\}/)) {
			anchor = substr(str, i + 2, RLENGTH - 3);
			result = result "<a id=\"" anchor "\"></a>";
			i = i + RLENGTH - 1;
		}
		# Markdown link [text](url "title")
		else if (c == "[" && is_link(str, i)) {
			link = extract_link(str, i);
			result = result parse_link(link);
		    i = i + length(link) - 1; 
		}
		# Markdown image ![alt](src "title")
		else if (c == "!" && is_image(str, i)) {
			image = extract_image(str, i);
			result = result parse_image(image);
		    i = i + length(image) - 1; 
		}
		# literal text
		else {
			if (c == "\n") {
				if (length(result) > 0)
					result = result " ";   # normalize intra-block newlines to spaces
			}
			else {
				result = result escape_text(c);
			}
		}
	}

	return result;
}

# --- Blockquote Parser ---
# Processes > prefixed lines into a <blockquote> element. Continuation lines
# (lacking >) are joined onto the preceding line. After stripping the >
# prefix, the inner content is recursively parsed as a full document body,
# supporting nested block elements within blockquotes.
function parse_blockquote(str,    i, lines, line, buf, result) {
	split(str, lines, "\n");

	# merge continuation lines onto their > prefixed parent
	str = ""
	for (i=1; i<=length(lines); i++) {
		line = lines[i];

		if (match(line, /^>/))
			str = join_lines(str, line, "\n");
		else
			str = join_lines(rstrip(str), lstrip(line), " ");
	}
	
	split(str, lines, "\n");

	result = "<blockquote>";
	buf = "";
	for (i=1; i<=length(lines); i++) {
		line = lines[i];
		gsub(/^> ?/, "", line);          # strip > marker and optional space

		if (buf != "")
			buf = buf "\n" line;	
		else
			buf = line;
	}

	if (buf != "")
		result = join_lines(result, parse_body(buf), "\n");  # recurse inner content

	result = result "\n</blockquote>"

	return result;
}

# --- Code Block Parser ---
# Handles fenced (``` delimited) and indented (4-space prefix) code blocks.
# Content is entity-escaped but not otherwise parsed for inline markup.
function parse_code(str,    i, lines, result) {
	# fenced code block: ``` ... ```
	if (match(str, /^```.*```$/)) {
		gsub(/^```/, "", str);           # strip opening fence (and optional lang tag)
		gsub(/\n```$/, "", str);         # strip closing fence
		return "<pre><code>" escape_text(str) "</code></pre>";
	}
	# indented code block: 4-space prefix per line
	if (match(str, /^    /)) {
		result = "";
		split(str, lines, "\n");

		for (i=1; i<=length(lines); i++) {
			line = lines[i];
			gsub(/^    /, "", line);     # strip exactly 4 leading spaces
			result = result "\n" line;
		}
		gsub(/^\n/, "", result);         # remove leading newline artifact
		return "<pre><code>" escape_text(result) "</code></pre>";
	}

	return "";
}

# --- Metadata Detection ---
# Tests whether every line in the block matches "key: value" format.
# Used to identify and suppress YAML-like front matter in the first block.
function is_metadata(str,    i, lines, line) {
	split(str, lines, "\n");
	for (i=1; i<=length(lines); i++) {
		line = lines[i];

		if (! match(line, /^[^ ]+: .+$/))
			return 0;
	}
	return 1;
}

# --- Block Dispatcher ---
# Routes a complete block to the appropriate parser based on its leading
# content: HTML comment (passthrough), code (fenced or indented), heading
# (ATX or setext), blockquote, horizontal rule, list (bullet or ordered),
# or paragraph (fallback).
function parse_block(str) {
	if (str == "")
		return "";

	# HTML comment: pass through verbatim to preserve in rendered output
	if (match(str, /^<!--/) && match(str, /-->$/))
		return str;

	if (match(str, /^```\n.*```$/) || match(str, /^    /)) {
		return parse_code(str);
	}
	if (substr(str, 1, 1) == "#" || match(body, /^[^\n]+\n[-=]+$/)) {
		return parse_header(str);
	}
	else if (substr(str, 1, 1) == ">") {
		return parse_blockquote(str);
	}
	else if ( \
		match(str, /^([[:space:]]*\*){3,}[[:space:]]*$/) ||
		match(str, /^([[:space:]]*-){3,}[[:space:]]*$/) ||
		match(str, /^([[:space:]]*_){3,}[[:space:]]*$/)) {
			return "<hr />";
	}
	else if (match(str, /^[-+*][[:space:]]/) || match(str, /^[[:digit:]]\.[[:space:]]/)) {
		return parse_list(str);
	}
	else  {
		return "<p>" parse_line(str) "</p>";
	}
}

# --- Document Body Parser ---
# Splits a multi-block string into individual blocks using line_continues()
# as the boundary predicate, then dispatches each block through parse_block().
# Used both at the top level and recursively within blockquotes.
function parse_body(str,    body, line, lines, result, i) {
	split(str, lines, "\n");
	result = "";
	body = "";

	for (i=1; i<=length(lines); i++) {
		line = lines[i];
		if (line_continues(body, line)) {
			if (body != "")
				body = body "\n" line;
			else
				body = line;
		}
		else if (body != "") {
			result = join_lines(result, parse_block(body), "\n");
			body = "";
		}
	}

	if (body != "")
		result = join_lines(result, parse_block(body), "\n");

	return result;
}

# --- Block Continuation Predicate ---
# Determines whether line belongs to the same block as body.
# Indented code and fenced code blocks absorb blank lines; headings and setext
# underlines terminate immediately; a list marker following a non-list body
# forces a block break (GitHub-compatible tight list attachment); all other
# non-empty lines continue the current block. An empty line ends a paragraph
# or list block.
function line_continues(body, line) {
	# indented code: continues through blanks if body is indented
	if (match(body, /^    /) && (match(line, /^    /) || line == ""))
		return 1;

	# fenced code: absorb everything until closing ```
	if (match(body, /^```\n/) && !match(body, /\n```$/))
		return 1;

	# HTML comment: absorb everything until closing -->
	if (match(body, /^<!--/) && !match(body, /-->$/))
		return 1;

	# ATX heading: single-line block, does not continue
	if (match(body, /^#* /))
		return 0;

	# setext underline: terminates the two-line heading block
	if (match(body, /^[^\n]+\n[-=]+$/))
		return 0;

	# list marker after non-list body: break to start a new list block
	# (permits lists immediately following paragraphs without a blank line)
	if (line != "" \
		&& !match(body, /^[[:space:]]*[-+*][[:space:]]/) \
		&& !match(body, /^[[:space:]]*[[:digit:]]+\.[[:space:]]/) \
		&& (match(line, /^[-+*][[:space:]]/) \
			|| match(line, /^[[:digit:]]+\.[[:space:]]/)))
		return 0;

	# non-empty line: continues the current paragraph/list block
	if (line != "")
		return 1;

	return 0;  # empty line: block boundary
}

# --- Main Input Loop ---
# Accumulates input lines into body using line_continues() to detect block
# boundaries. When a boundary is reached, flushes the completed block through
# parse_block() and begins a new block. The first block is tested for metadata
# and suppressed if it matches.
// {
	if (line_continues(body, $0)) {
		if (body != "")
			body = body "\n" $0;
		else
			body = $0;
		next;
	}

	if (body != "") {
		if (!(first_paragraph && is_metadata(body)))
			print parse_block(body);
		first_paragraph = 0;
	}

	body = $0;

	next;
}

# --- End-of-Input Flush ---
# Emits the final accumulated block, applying the same metadata suppression
# for the edge case of a single-block document. Closes the HTML document
# envelope opened in BEGIN.
END {
	if (body != "") {
		if (!(first_paragraph && is_metadata(body)))
			print parse_block(body);
	}
	print "</body>"
	print "</html>"
}
