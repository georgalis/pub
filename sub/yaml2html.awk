#!/usr/bin/awk -f
# yaml to html converter
# revn: 69898512 20260208 225618 PST Sun 10:56 PM 8 Feb 2026
# orig: 69897a9c 20260208 221140 PST Sun 10:11 PM 8 Feb 2026
# (c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
# converts yaml block-style documents to semantic html
# presentation-optimized: keys and scalar values on same line
# mappings: div.kv with bold key, inline span value
# sequences: ul/li (block layout preserved)
# block scalars: pre (literal |), p (folded >)
# anchors: duplicated (single-pass), custom tags stripped
# flow collections: inline ul or nested div (comments stripped) 
# type annotation: css class on value span (yn/yb/yi/ys)
# limitations: nested flow collections, full chomp, complex keys
# compatibility: posix awk (bsd, darwin, gawk)

BEGIN {
    in_literal = 0; in_folded = 0
    block_indent = -1; scalar_parent_indent = 0
    folded_buf = ""; lit_buf = ""
    doc_open = 0; stack_top = 0
    print "<!DOCTYPE html>"
    print "<html><head>"
    print "<meta charset=\"ascii\">"
    print "<style>"
    print "body{font-family:sans-serif;font-size:14px;line-height:1.5;"
    print "     max-width:60em;margin:1em auto;color:#222}"
    print ".kv{margin:0.15em 0}"
    print ".k{font-weight:bold}"
    print ".nest{margin-left:1.5em}"
    print "ul{margin:0.2em 0 0.2em 1.5em;padding-left:1em}"
    print "li{margin:0.1em 0}"
    print "pre{background:#f4f4f4;padding:0.5em;margin:0.2em 0 0.2em 1.5em;"
    print "    white-space:pre-wrap;font-size:13px}"
    print ".yn{color:#999;font-style:italic}"
    print ".yb{color:#c44}"
    print ".yi{color:#36d}"
    print ".ys{color:#333}"
    print ".ya{font-size:0.8em;color:#888}"
    print "article{border-top:1px solid #ccc;margin-top:1em;"
    print "        padding-top:0.5em}"
    print "</style>"
    print "</head><body>"
}

# normalize
{ sub(/[[:space:]]+$/, "") }

# full-line comments
!in_literal && !in_folded && /^[[:space:]]*#/ { next }

# empty lines
/^[[:space:]]*$/ {
    if (in_literal) { lit_buf = lit_buf "\n"; next }
    if (in_folded)  { end_folded(); next }
    next
}

# document separator ---
/^---([[:space:]].*)?$/ {
    flush_all()
    if (doc_open) print "</article>"
    print "<article>"; doc_open = 1; next
}

# document end ...
/^\.\.\.([[:space:]].*)?$/ {
    flush_all()
    if (doc_open) { print "</article>"; doc_open = 0 }
    next
}

# strip inline comments respecting quotes
!in_literal && !in_folded && index($0, " #") > 0 {
    inquote = 0; cpos = 0
    for (ci = 1; ci <= length($0); ci++) {
        ch = substr($0, ci, 1)
        if (ch == "\"" || ch == "'") inquote = !inquote
        if (!inquote && ch == "#" && ci > 1 && substr($0, ci-1, 1) == " ") {
            cpos = ci - 1; break
        }
    }
    if (cpos > 0) { $0 = substr($0, 1, cpos); sub(/[[:space:]]+$/, "") }
}

# indentation and block scalar collection
{
    match($0, /^[[:space:]]*/); cur_indent = RLENGTH

    if (in_literal) {
        if (block_indent < 0 && cur_indent > scalar_parent_indent)
            block_indent = cur_indent
        if (block_indent >= 0 && cur_indent >= block_indent) {
            lit_buf = lit_buf substr($0, block_indent + 1) "\n"
            next
        }
        end_literal()
    }
    if (in_folded) {
        if (block_indent < 0 && cur_indent > scalar_parent_indent)
            block_indent = cur_indent
        if (block_indent >= 0 && cur_indent >= block_indent) {
            line = substr($0, block_indent + 1)
            if (line == "") {
                folded_buf = folded_buf "\n"
            } else {
                if (folded_buf != "" && \
                    substr(folded_buf, length(folded_buf)) != "\n")
                    folded_buf = folded_buf " "
                folded_buf = folded_buf line
            }
            next
        }
        end_folded()
    }
}

# close deeper structures
{ close_deeper(cur_indent) }

# --- sequence item ---
/^[[:space:]]*-[[:space:]]/ || /^[[:space:]]*-$/ {
    open_doc()
    line = $0; sub(/^[[:space:]]*/, "", line)
    sub(/^-[[:space:]]?/, "", line)
    sub(/^[[:space:]]*/, "", line)

    need_container(cur_indent, "ul")

    if (line == "") {
        # bare dash: nested content follows
        print "<li>"
        push(cur_indent + 1, "li")
    } else if (has_mapping(line)) {
        # list item with key:val -- leave li open for sibling keys
        print "<li>"
        push(cur_indent + 1, "li")
        split_kv(line)
        printf "<div class=\"kv\"><span class=\"k\">%s:</span> ", escape(g_key)
        if (g_val != "")
            printf "<span class=\"%s\">%s</span>", \
                ytype(g_val), escape(unquote(g_val))
        print "</div>"
    } else {
        printf "<li class=\"%s\">%s</li>\n", \
            ytype(line), escape(unquote(line))
    }
    next
}

# --- mapping key: value ---
/^[[:space:]]*[A-Za-z0-9_"'~.\/][^:]*:[[:space:]]/ || \
/^[[:space:]]*[A-Za-z0-9_"'~.\/][^:]*:[[:space:]]*$/ {
    open_doc()
    line = $0; sub(/^[[:space:]]*/, "", line)
    split_kv(line)
    key = g_key; val = g_val

    # anchor extraction
    anchor = ""
    if (match(key, /[[:space:]]*&[A-Za-z0-9_-]+/)) {
        anchor = substr(key, RSTART, RLENGTH)
        key = substr(key, 1, RSTART - 1) substr(key, RSTART + RLENGTH)
        sub(/^[[:space:]]*&/, "", anchor)
    }

    # block scalar indicators
    if (val == "|" || val == "|+" || val == "|-") {
        printf "<div class=\"kv\"><span class=\"k\">"
        emit_anchor(anchor)
        printf "%s:</span></div>\n", escape(key)
        in_literal = 1; lit_buf = ""; block_indent = -1
        scalar_parent_indent = cur_indent; next
    }
    if (val == ">" || val == ">+" || val == ">-") {
        printf "<div class=\"kv\"><span class=\"k\">"
        emit_anchor(anchor)
        printf "%s:</span></div>\n", escape(key)
        in_folded = 1; folded_buf = ""; block_indent = -1
        scalar_parent_indent = cur_indent; next
    }

    # inline value present
    if (val != "") {
        printf "<div class=\"kv\"><span class=\"k\">"
        emit_anchor(anchor)
        printf "%s:</span> ", escape(key)

        if (substr(val, 1, 1) == "*") { # alias
            a = substr(val, 2)
            printf "<a href=\"#y-%s\">*%s</a>", a, escape(a)
        } else if (is_fseq(val)) {
            printf "</div>\n"
            emit_fseq(val)
            next
        } else if (is_fmap(val)) {
            printf "</div>\n"
            emit_fmap(val)
            next
        } else {
            printf "<span class=\"%s\">%s</span>", \
                ytype(val), escape(unquote(val))
        }
        print "</div>"
    } else {
        # no value: nested structure follows
        printf "<div class=\"kv\"><span class=\"k\">"
        emit_anchor(anchor)
        printf "%s:</span></div>\n", escape(key)
        printf "<div class=\"nest\">\n"
        push(cur_indent + 1, "nest")
    }
    next
}

# fallback
{
    open_doc()
    line = $0; sub(/^[[:space:]]*/, "", line)
    if (line != "") printf "<p>%s</p>\n", escape(line)
}

END {
    flush_all()
    if (doc_open) print "</article>"
    print "</body></html>"
}

# --- utility functions ---

function escape(s) {
    gsub(/&/, "\\&amp;", s)
    gsub(/</, "\\&lt;", s)
    gsub(/>/, "\\&gt;", s)
    gsub(/"/, "\\&quot;", s)
    return s
}

function unquote(s) {
    if ((substr(s, 1, 1) == "\"" && substr(s, length(s)) == "\"") || \
        (substr(s, 1, 1) == "'" && substr(s, length(s)) == "'"))
        s = substr(s, 2, length(s) - 2)
    return s
}

function ytype(v,    t) {
    t = v; sub(/^[[:space:]]*/, "", t); sub(/[[:space:]]*$/, "", t)
    if ((substr(t, 1, 1) == "\"" && substr(t, length(t)) == "\"") || \
        (substr(t, 1, 1) == "'" && substr(t, length(t)) == "'"))
        return "ys"
    if (t == "null" || t == "~" || t == "") return "yn"
    if (t == "true" || t == "false" || t == "yes" || t == "no" || \
        t == "True" || t == "False" || t == "Yes" || t == "No" || \
        t == "TRUE" || t == "FALSE" || t == "YES" || t == "NO")
        return "yb"
    if (t ~ /^-?[0-9]+\.?[0-9]*([eE][+-]?[0-9]+)?$/) return "yi"
    if (t ~ /^0x[0-9a-fA-F]+$/) return "yi"
    if (t ~ /^0o[0-7]+$/) return "yi"
    return "ys"
}

function has_mapping(s) {
    return (index(s, ": ") > 0 || \
           (index(s, ":") > 0 && index(s, ":") == length(s)))
}

function split_kv(s) {
    g_key = ""; g_val = ""
    cp = index(s, ":")
    if (cp > 0) {
        g_key = substr(s, 1, cp - 1)
        g_val = substr(s, cp + 1)
        sub(/^[[:space:]]*/, "", g_val)
        sub(/[[:space:]]*$/, "", g_val)
    }
}

function emit_anchor(a) {
    if (a != "")
        printf "<span class=\"ya\" id=\"y-%s\">&amp;%s</span> ", a, a
}

function open_doc() {
    if (!doc_open) { print "<article>"; doc_open = 1 }
}

# --- stack ---

function push(indent, type) {
    stack_top++
    stack_indent[stack_top] = indent
    stack_type[stack_top] = type
}

function close_deeper(indent,    t) {
    while (stack_top > 0 && stack_indent[stack_top] > indent) {
        t = stack_type[stack_top]
        if (t == "ul") print "</ul>"
        else if (t == "li") print "</li>"
        else if (t == "nest") print "</div>"
        stack_top--
    }
}

function need_container(indent, type,    t) {
    if (stack_top > 0 && \
        stack_indent[stack_top] == indent && \
        stack_type[stack_top] == type)
        return
    if (stack_top > 0 && stack_indent[stack_top] == indent) {
        t = stack_type[stack_top]
        if (t == "ul") print "</ul>"
        else if (t == "li") print "</li>"
        else if (t == "nest") print "</div>"
        stack_top--
    }
    if (type == "ul") printf "<ul>\n"
    push(indent, type)
}

function flush_all() {
    if (in_literal) end_literal()
    if (in_folded) end_folded()
    close_deeper(-1)
}

function end_literal() {
    sub(/\n$/, "", lit_buf)
    printf "<pre>%s</pre>\n", escape(lit_buf)
    in_literal = 0; lit_buf = ""; block_indent = -1
}

function end_folded() {
    if (folded_buf != "") {
        sub(/[[:space:]]+$/, "", folded_buf)
        printf "<p class=\"ys\">%s</p>\n", escape(folded_buf)
        folded_buf = ""
    }
    in_folded = 0; block_indent = -1
}

# --- flow collections ---

function is_fseq(s) {
    return (substr(s, 1, 1) == "[" && substr(s, length(s)) == "]")
}

function is_fmap(s) {
    return (substr(s, 1, 1) == "{" && substr(s, length(s)) == "}")
}

function emit_fseq(s,    inner, n, items, i) {
    inner = substr(s, 2, length(s) - 2)
    n = split(inner, items, ",")
    print "<ul>"
    for (i = 1; i <= n; i++) {
        sub(/^[[:space:]]*/, "", items[i])
        sub(/[[:space:]]*$/, "", items[i])
        printf "<li class=\"%s\">%s</li>\n", \
            ytype(items[i]), escape(unquote(items[i]))
    }
    print "</ul>"
}

function emit_fmap(s,    inner, n, pairs, i, cp2, fk, fv) {
    inner = substr(s, 2, length(s) - 2)
    n = split(inner, pairs, ",")
    printf "<div class=\"nest\">\n"
    for (i = 1; i <= n; i++) {
        sub(/^[[:space:]]*/, "", pairs[i])
        cp2 = index(pairs[i], ":")
        if (cp2 > 0) {
            fk = substr(pairs[i], 1, cp2 - 1)
            fv = substr(pairs[i], cp2 + 1)
            sub(/^[[:space:]]*/, "", fk); sub(/^[[:space:]]*/, "", fv)
            sub(/[[:space:]]*$/, "", fv)
            printf "<div class=\"kv\"><span class=\"k\">%s:</span> " \
                "<span class=\"%s\">%s</span></div>\n", \
                escape(unquote(fk)), ytype(fv), escape(unquote(fv))
        }
    }
    print "</div>"
}
