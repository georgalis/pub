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
