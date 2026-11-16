# roffsub plan

roffsub is a standard for documentation written to be read in a terminal. A roffsub document is a roff man page that every existing roff tool can display. It is also simple enough for small awk and C routines to render from inside a tool's own binary or bash function. Those routines produce headings, paragraphs, definitions, lists, and tables, set to whatever width the terminal has at the moment of reading, with bold and italic shown wherever the terminal can show them.

Status: phases P1 to P6 built and tested (section 13). The standard and its tools exist for the operator to apply wherever and whenever the operator chooses; adopting them in any particular program is the operator's decision and is not a phase of this plan.

Revision: r0.9, 2026-11-15. This revision gives text-block columns in the installed page tbl's `x` (expand) modifier, so roff widens them to fill the line. Left to roff's defaults (r0.8), they kept the width of an 80-column line on a wider terminal (section 7.3).

r0.8 added the `roffsub.7` examples, `template.1`, and `skill/SKILL.md`, and restated table fitting as the solution. r0.7 adopted the Table C layout for installed pages. r0.6 made the binary and the function identical (D7). r0.5 added the heading offset and check W03. r0.4 built phases P1 to P6. r0.3 settled the roff behaviors and decisions D1 to D6. r0.2 added the program interface, the embedding profiles, and the table rules. r0.1 replaced r0 ("mansub").

(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.

<!--contents 2 3 pre="## Contents" post="---"-->

## 1 Purpose

The terminal is where the operator reads documentation, and the documentation sits next to the tool it describes. Markdown suits a different setting: people write it by hand, it reads well in a terminal as source, and it turns easily into HTML to review in a browser or print to PDF. It falls short where the terminal is the place documentation is read rather than the place it is edited. In a terminal, Markdown has no notion of a tagged option paragraph, a hanging indent, or emphasis that only appears when the terminal supports it. Viewed as raw source it is readable, but it never rewraps to fit the window.

roff has served the terminal for decades. Its man macros already describe the structure of command-line documentation: a synopsis, options, sections, definitions, lists, and tables, set in a monospaced font with emphasis where the device allows. Markdown suits documents meant for hand editing and the browser. roff suits documents meant to be read in a terminal, and roffsub is the part of roff that can still be rendered when no roff program is present: inside a C binary at `--help`, or inside a bash function.

The standard gives every program one well-defined way to make its documentation available from a single source, whether the program is small or large and whether it runs on a minimal host or a workstation:

- **Installed page.** A man page is installed in every case.
- **Built-in help.** The program carries its manual in the richest form its size justifies.

### 1.1 Origin

The tools this standard grew out of kept their manuals as fixed-width text. That text was set once and could not adapt: lines wrapped at 80 columns stayed broken on a wide terminal and overran a narrow one, and an option name could not stand out in bold from the words around it. roffsub keeps the single source and moves the formatting to the moment of reading.

## 2 Requirements

### 2.1 Essential

| Id | Requirement | How roffsub meets it |
|---|---|---|
| E1 | The format can be displayed by existing roff tools, through a pager or as plain text | The document is a valid man page, installed in every case; man, nroff, groff, and mandoc display it unchanged |
| E2 | Presentation suits terminals of any width and monospaced fonts | Text is filled and indented at render time, from the current width; all measurements count character cells |
| E3 | Layout follows the man page conventions for commands, options, sections, definitions, lists, and tables | The standard is built from the man macros and the tbl preprocessor, with their usual meanings |
| E4 | Bold and italic are shown where the terminal can show them, usually as brightness or color | Emphasis is recorded as font changes; the renderer decides at emission whether to use control sequences, backspace overstrike, or nothing |
| E5 | Simple enough to embed in a binary and a bash function and emit at `--help` in the right form | A program carries either the compiled records with a renderer, or (below a size threshold) a manual formatted at build; section 8 sets the rules |
| E6 | The document's form is checked; its content is not | A conformance check accepts or rejects how a document is written; the template for sections is guidance only |

### 2.2 Nice to Have

| Id | Feature | Placement |
|---|---|---|
| N1 | Markdown export | A separate project. A converter from roffsub (or from the compiled form) to Markdown, for HTML review and printing. Its interest in roffsub is that the compiled form is stable and simple. |

## 3 Solution Overview

```
NAME.1 (roffsub source)
  |
  +--check form--------------> accept / reject
  |
  +--install-----------------> man1dir (every program, every profile)
  |
  +--compile (awk)-----------> NAME.ir (records; no widths fixed yet)
                                  |
                 +----------------+-----------------+
                 |                                  |
          profile "full"                   profile "preformatted"
          records + renderer               build renders at fixed width;
                 |                         text with fonts + emitter
                 |                                  |
                 +--- embedded in NAME.c and NAME.fn.bash ---+
                                  |
                 at --help: width, emphasis, pager (section 8)
```

- **One source.** A single source file is the man page, the binary's help, and the function's help.
- **Parse once.** The source is parsed once, at build. The runtimes receive records whose meaning is already settled, so all they do is layout and emission.
- **Two renderers.** awk is the renderer outside the binary and C is the renderer inside it. Identical inputs must produce identical bytes from both, which keeps them interchangeable.
- **Small programs.** A program too small to justify carrying a renderer carries pre-formatted text instead (section 8.4). It loses only the reflow to the terminal's width.

## 4 Document Model

roffsub supports the elements terminal documentation needs. Each is written the way roff writes it (section 5 gives the exact form) and rendered the way roff renders it on a terminal (section 7).

| Element | roff form | Rendering |
|---|---|---|
| Title | `.TH` | identifies the page; header and footer lines are optional in `--help` output |
| Section heading | `.SH` | bold, at the left margin; the section body is indented one unit |
| Subsection heading | `.SS` | bold, at a half-unit indent |
| Paragraph | `.PP` (`.P`, `.LP`) | filled text at the current indent |
| Definition (option, term) | `.TP`, with the tag on the next line | the tag at the current indent and the body hanging at the prevailing indent |
| List item | `.IP` | as a definition, with the tag inline: `\(bu` for bullets, numbers for ordered lists, empty for an indented paragraph |
| Nested block | `.RS`, `.RE` | moves the margin in, then restores it |
| Literal block | `.nf`, `.fi` | lines shown as written; used for synopses and examples |
| Emphasis | font escapes and font requests | bold for text typed literally, italic for arguments the reader replaces |
| Spacing | `.sp`, `.br` | blank lines; a line break |
| Table | `.TS` ... `.TE` | open columns with horizontal rules only, sized to the available width |
| Comment | `.\"` | discarded |

## 5 Source Form

The rules in this section define a roffsub source. Each one states its purpose, so it can be judged by whether it achieves that purpose. The vocabulary in sections 5.2 to 5.5 is the whole of roffsub, and the conformance check (section 9) reports anything outside it.

### 5.1 Lexical Rules

| Rule | Purpose |
|---|---|
| Bytes 0x20 to 0x7E plus LF | byte count equals the number of terminal columns, so awk and C measure width with a plain length |
| No TAB characters | layout is expressed by requests, so every viewer shows the same thing; TAB is free to separate fields in the compiled form |
| Line 1 is `'\" t` exactly when the page contains a table | man-db reads that line to run tbl first; it is the only line that begins with `'` |
| A control line is `.` followed directly by a request from section 5.2; a comment is a whole line starting `.\"` | one recognizable shape for every instruction, easy to classify with a single pattern |
| A text line starts with a word: never a space, never empty, and never `.` or `'` unless written `\&.` | roff treats a leading space or a blank line as a layout instruction; stating breaks with requests gives them one meaning in every renderer |
| One sentence per line (recommended, not checked) | small diffs, and predictable spacing at sentence ends in roff |

### 5.2 Requests

Widths are written as a bare number or with the unit `n`, meaning character cells on a monospaced terminal. That is the unit all three renderers share.

| Request | Arguments | Meaning | Form |
|---|---|---|---|
| `.TH` | `NAME SEC DATE SOURCE MANUAL` | page title | first request; `DATE` may be `@DATE@`, and `SOURCE` may contain `@VERSION@`, filled in at install and compile |
| `.SH` | text | section heading | |
| `.SS` | text | subsection heading | within a section |
| `.PP` `.P` `.LP` | none | new paragraph; resets the prevailing indent | |
| `.TP` | `[width]` | tagged paragraph; the next line is the tag | the tag line is a text line or a font request; a width sets the prevailing indent |
| `.IP` | `[tag [width]]` | indented paragraph, optionally tagged | a width sets the prevailing indent |
| `.RS` | `[width]` | move the margin in by the width, or by the prevailing indent | paired with `.RE` within a section |
| `.RE` | none | restore the margin | |
| `.nf` `.fi` | none | literal (no fill) and fill mode | paired; literal blocks hold text lines only, so every renderer treats them alike |
| `.B` `.I` | words | set the words in bold or italic | words given as arguments, so no font state carries over to the next line |
| `.BR` `.RB` `.IR` `.RI` `.BI` `.IB` | words | alternate two fonts, word by word | at least one argument |
| `.sp` | `[N]` | N blank lines (default 1) | |
| `.br` | none | line break | |
| `.TS` `.TE` | none | table (section 5.5) | paired |
| `.\"` | anything | comment | discarded |

### 5.3 Arguments

- **Quoting.** Double quotes group words into one argument. A literal quote inside is written `\(dq`. This keeps quoting to a single rule that awk and C parse identically.
- **Count.** At most 9 arguments, which is the classic roff limit and is honored everywhere.

### 5.4 Escapes and Fonts

| Escape | Meaning | Compiled form | Terminal output |
|---|---|---|---|
| `\fB` `\fI` `\fR` | select bold, italic, roman | kept | font change |
| `\fP` | return to the previous font | resolved to an explicit `\fX` | |
| `\-` | minus; copies and pastes as a real hyphen, as options need | `-` | `-` |
| `\e` | backslash | `\\` | `\` |
| `\&` | zero-width guard (line-initial `.`, end-of-line abbreviation) | removed | nothing |
| `\ ` (backslash space) | space that never breaks | `\~` | space |
| `\(em` | em dash | `--` | `--` |
| `\(en` | en dash | `-` | `-` |
| `\(bu` | bullet | `o` | `o` |
| `\(aq` | apostrophe | `'` | `'` |
| `\(dq` | double quote | `"` | `"` |

**Font rule.** The font returns to roman by the end of each request line and each table cell, so emphasis never runs on past where it was meant to stop, whichever renderer shows it.

### 5.5 Table Form

```
.TS
box tab(@);
lb lb
l  l.
OPTION@MEANING
_
\fB\-r\fR@reverse the order
\fB\-k\fR \fIKEY\fR@sort on \fIKEY\fR
.TE
```

- **Options line.** Required, ending in `;`. It contains `tab(c)`, where `c` is a printable non-alphanumeric character used in no cell, plus any of `box`, `allbox`, and `center`. An explicit separator keeps TAB out of the source.
- **Format lines.** One or more, the last ending in `.`. Column keys are `l`, `r`, and `c`, with modifiers `b`, `i`, and `w(N)`. `w(N)` is a minimum width. Format line *i* governs data row *i*, and the last format line repeats.
- **Data rows.** Each row has one cell per format column. A row consisting of `_` alone is a horizontal rule.
- **Text blocks.** A cell opens with `T{` and continues with text lines until a line that begins `T}`. The lines are joined and filled. This is how a long description wraps inside its column. roff wraps only text blocks, while the roffsub renderers wrap every cell, so a cell that may need wrapping is written as a text block (check W03).

### 5.6 Content Template (guidance)

NAME as `name \- summary`, then SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES, ENVIRONMENT, FILES, EXIT STATUS, SEE ALSO. This is the familiar order of a man page. whatis and apropos read the NAME line to build their index. Content is the program author's to decide, and the conformance check does not read it.

## 6 Compiled Form

The build compiles the source into records, one per line: an operation name, then fields separated by TABs.

- **Operations** correspond one to one with the elements in section 4: `th sh ss pp tp ip rs re nf fi tx sp br`, plus `ts tf tr t_ te` for tables.
- **Text** carries five escapes and no others: `\fB \fI \fR \\ \~`. The build has already turned each character escape into its ASCII form and resolved every `\fP`.
- **Widths** are not fixed: each record keeps only structure and emphasis, and indentation arguments stay as numbers for the renderer to apply.
- **Version.** The first record is `v 1`. A renderer refuses a major version it does not know.

**Embedding (whichever profile section 8.4 selects):**
- **C.** The text becomes a generated array of strings.
- **bash.** The text sits in a quoted heredoc inside the function's `--help` branch, held in a `local` variable. It is passed to awk on stdin, never with `-v`, because `-v` would rewrite its backslashes.
- **Agreement check.** A build check confirms that both embedded copies decode to exactly the same bytes as their source file.

The compiled form is also the natural input for the Markdown exporter (N1). Its records are simple and say only what each element is.

## 7 Rendering

### 7.1 Width and Margins

- **Width W.** Resolved as section 8.2 describes.
- **Right margin.** Text fills to W, and the right margin is 0 (D1). A maximum line length is applied only when `ROFFSUB_MEASURE` is set.
- **Filling.** Words are packed greedily with ragged right edges. A word too long for the line is kept whole and allowed to run past the margin. A space written `\ ` never breaks.
- **Literal blocks** keep their lines as written. When a terminal is narrower than a line, the line runs past the edge rather than being rewrapped, since an example must stay exactly as typed.
- **Indent unit.** 7 cells, or 4 below 60 columns (D2).
- **Heading offset.** `ROFFSUB_HEADING=1` sets section headings in the second column; nothing else moves. For man pages, newer groff reaches the same layout through its page offset and indent registers, which man-db passes along in `MANROFFOPT`: `-rPO=1n -rIN=6n -rSN=2n`. That moves the header, footer, and headings in by one column and leaves the body at column 7 and subheadings at column 3. The `PO` register is a 2023 addition to groff, so older groff lacks it. mandoc offers a body indent (`-O indent`) but no page offset. Setting both variables in the user's environment therefore applies the layout to every man page and every roffsub help alike.

### 7.2 Indentation and Vertical Space

These rules follow roff's own behavior (section 12):

| Element | Space before | Placement |
|---|---|---|
| `.SH` | 1 blank line (none at the top of the page) | heading at the left margin, bold; body indented one unit; prevailing indent reset |
| `.SS` | 1 blank line | heading at a half-unit indent, bold; prevailing indent reset |
| `.PP` | 1 blank line, except directly after a heading | text at the current indent; prevailing indent reset |
| `.TP`, tagged `.IP` | 1 blank line, except directly after a heading | tag at the current indent. If the tag is shorter than the prevailing indent, the body continues on the same line at that column; otherwise the body starts on the next line, fully indented |
| untagged `.IP` | as above | body at the prevailing indent |
| `.RS` / `.RE` | none | margin moves in by the width given, or by the prevailing indent; `.RE` restores it |
| `.sp N` / `.br` | N blank lines / none | |
| `.nf` ... `.fi` | none | lines at the current indent, as written |
| `.TS` ... `.TE` | none | table at the current indent |

**Prevailing indent.** A width given to `.TP` or `.IP` becomes the prevailing indent for later `.TP` and `.IP` items that give none. It holds until the next `.SH`, `.SS`, or `.PP`. When no width has been given, it is the indent unit.

### 7.3 Tables

**Style.** Tables use open columns and draw no vertical lines.

- **Cells.** Each cell has one space of padding on each side.
- **Separators.** Neighboring columns are joined at a single separator position: a space in data rows and `+` in rule lines. Column text therefore sits three cells apart, which is tbl's default gap.
- **Rules.** Horizontal rules appear only where the source asks for them:
  - a `_` row becomes a dash rule across the table, with `+` at each separator;
  - `box` adds a rule above the first row and below the last;
  - `allbox` adds a rule after every row.

```
 OPTION   MEANING
--------+-------------------
 -r       reverse the order
 -k KEY   sort on KEY
```

**Fitting the width (D4).** Each column takes its natural width when the table fits. When it does not, the longest columns narrow together and their cells wrap, while short columns, such as option names, keep their width. No column narrows below its longest word, and a `w(N)` key sets a minimum. When even the longest words cannot fit, each row is shown as `HEADER: value` lines.

**The `+` join under roff.** roff draws a `_` row as an unbroken dash line, and puts a `+` only where a vertical rule crosses it. The installed page is therefore written by `roffsub -n`, which rewrites each table using only tbl's own features, a layout confirmed on Darwin (probe Table C):
- **Separator columns.** An empty column sits between each pair of columns, with zero column separation on both sides. Data rows leave it empty, which gives the usual three-space gap.
- **Rules.** Each `_` row becomes a row of cell rules, with `\-+\-` in every separator column. `box` and `allbox` become such rows, so no vertical lines are drawn.
- **Widths.** Columns holding text blocks take the `x` modifier, so roff gives them the rest of the line, and the table follows the width of the terminal it is read on. Other columns keep their natural width. Without `x`, roff kept text blocks at the width of an 80-column line (seen on Darwin with r0.8).

The source stays in roffsub form, and the roffsub renderers read the source, not the installed page.

### 7.4 Emphasis

Words and their fonts are laid out first, and control bytes are added only when the text is written out, so the bytes never count toward a line's width. Emphasis is written in one of four ways:

| Mode | When | Bold | Italic |
|---|---|---|---|
| `sgr` | output goes to a terminal | `ESC[1m` | `ESC[4m` (underline, as man shows it on terminals; D3) |
| `overstrike` | output goes to a pager | `c BS c` | `_ BS c` |
| `plain` | file, pipe, or `TERM=dumb` | none | none |
| `sgr` with custom codes | `ROFFSUB_SGR="b=1;33:i=4;36"` | any SGR codes, including color | any SGR codes, including color |

- **Bold and italic as colors.** Custom SGR codes let bold and italic appear as distinct colors or brightness, which is how many terminals show them already.
- **Resets.** Every line that ends with emphasis active is reset before the newline and resumed on the next line, so scrolling in a pager and copying text both stay clean.
- **Same bytes from C and bash.** Both runtimes write these sequences themselves rather than looking them up, which is what lets them produce identical output.

## 8 Program Interface

This section is the guidance a program follows when it adopts roffsub. It is the concrete form of E5.

### 8.1 Inputs

What `--help` writes is fully determined by four inputs:

- the embedded manual (the records, or the pre-formatted text);
- a width W;
- an emphasis mode S (`plain`, `overstrike`, `sgr`);
- a destination D (`pipe`, `tty`, `pager`).

Given the same inputs, the C and bash forms of a program produce identical bytes.

### 8.2 Choosing Destination, Mode, and Width

| Invocation | D | Default S | Default W |
|---|---|---|---|
| `--help`, stdout is a terminal, pager in use | pager | `overstrike` | terminal width |
| `--help`, stdout is a terminal, `PAGER` basename is `cat` | tty | `sgr` | terminal width |
| `--help`, stdout is not a terminal | pipe | `plain` | 80 |

- **Pager.** `PAGER` if set and non-empty; otherwise `less` if installed; otherwise `more`. Both `less` and `more` interpret overstrike on Linux, Darwin, and NetBSD (Q5). A pager by any other name also gets overstrike, unless `ROFFSUB_STYLE` says otherwise.
- **Terminal width (Q4).** `MANWIDTH` if set; otherwise `COLUMNS`; otherwise the terminal itself. The C side asks the terminal driver, trying stdout, then stderr, then `/dev/tty`. The bash side runs `tput cols`. If none of these gives a width, 80 is used.
- **Overrides.**

| Variable | Effect |
|---|---|
| `MANWIDTH` | sets W |
| `ROFFSUB_STYLE` | sets S |
| `ROFFSUB_SGR` | sets the codes used for bold and italic |
| `ROFFSUB_MEASURE` | sets the maximum line length |
| `ROFFSUB_HEADING` | moves section headings in by that many columns (default 0) |
| `TERM=dumb` | forces `plain` unless `ROFFSUB_STYLE` says otherwise |

### 8.3 Usage (`-h`)

`-h` and `--help` serve different purposes. `--help` presents the full manual for a complete review. `-h` is the quick reference: a refresher and a confirmation when a full review is not needed. It holds a short synopsis, a concise breakdown of the options, and the few details too important to leave out. Because its purpose differs, it is composed for that purpose rather than extracted from the manual, and it is kept beside the manual source so the two are revised together.

### 8.4 Embedding Profiles

| Profile | The program carries | What `--help` gives |
|---|---|---|
| `full` | compiled records and the renderer | any width, reflowed text and tables, emphasis to suit the terminal |
| `preformatted` | the manual already formatted at build at 80 columns (D6) with its font changes kept, plus a small emitter (roughly 20 lines of awk or C) | fixed width, emphasis to suit the terminal |
| `plain` | the manual already formatted at build as plain text | fixed width, no emphasis |

**The threshold (D5).** At build time, the build measures how large the renderer is compared with the program, and chooses the profile from that:

- **`full`** when the renderer is no larger than the program it would live in, not counting the manual. For C, compare compiled object sizes. For bash, compare the renderer's text with the function body.
- **Exported bash functions** must also stay within a size budget (`ROFFSUB_FN_BUDGET`), because exported functions are copied into the environment of every process the shell starts. The budget's value is set once the renderer has been measured (phase P4).
- **`preformatted`** when either test fails.
- **`plain`** only when the program explicitly asks for it.

Measured in r0.4:

| Part | Size |
|---|---|
| C renderer, compiled | about 12 KB of text |
| awk renderer source | about 9.7 KB |
| emitter (awk or C) | about 1 KB |
| roffsub function with its own manual embedded | about 40 KB |

A program smaller than the renderer takes the `preformatted` profile.

The setting `ROFFSUB_PROFILE` overrides the build's choice, and `ROFFSUB_PREWIDTH` sets the width used to pre-format. Whatever the profile, the man page is still built from the same source and installed, so the full reflowing manual is always available through man.

## 9 Conformance Check

The check is an awk program run at build time. It verifies the form of section 5:

- the lexical rules;
- the request, escape, and table vocabulary;
- balanced block pairs (`.nf`/`.fi`, `.RS`/`.RE`, `.TS`/`.TE`, `T{`/`T}`);
- fonts returning to roman;
- one cell per format column;
- the `'\" t` line.

It does not judge content. A document that passes renders in roff, in the C renderer, and in the awk renderer. Each rule has an identifier, so test cases can name the rule they expect to trigger. Advisory warnings flag the usual roff slips: option hyphens written without `\-`, abbreviations at the end of a line without `\&`, and tables wider than 71 columns whose wide cells are not text blocks. The last is W03: at 80 columns roff would let such a table overrun the line.

## 10 Tools the Standard Provides

roffsub supplies the tools, each carrying a version stamp. How a program's makefile wires them together, and how it keeps its embedded copies current, is part of developing that program:

- **checker:** the conformance check;
- **compiler:** source to records;
- **pre-formatter:** records to fixed-width text with font changes, for the `preformatted` and `plain` profiles;
- **generators:** text to a C array, and text to a bash heredoc;
- **renderers:** `roffsub.h` and the awk renderer;
- **emitter:** for pre-formatted text;
- **page writer:** `roffsub-man.awk` (`roffsub -n`); fills in the date and version on `.TH` and rewrites tables for roff.

All of them are POSIX awk, C99, and POSIX make. They are copied into each program's package so every package builds on its own.

## 11 Verification

- **Test documents.** A set of conforming documents and a set of non-conforming ones. The non-conforming set must trigger exactly the rules it names.
- **Reference outputs.** For every conforming document, output at widths 40, 60, 80, and 120 in each emphasis mode, reviewed once and then fixed. The tables among them cover natural widths, narrowed columns, and the record form.
- **C and bash agreement.** The same program's binary and function must produce byte-identical output across every width and mode, in every profile, under each awk that is installed.
- **Profile agreement.** The `preformatted` output must match the `full` renderer's output at the pre-format width.
- **Embedding check.** Both embedded copies must decode to exactly the same bytes as their source file.
- **Agreement with roff.** On machines that have mandoc or groff, the sequence of words and fonts each one produces must match roffsub's, along with the tag placement and spacing rules in section 12.
- **Visual check.** The installed page, viewed with man on Darwin, Linux, and NetBSD.

## 12 Settled roff Behaviors

| Id | Behavior | Rule adopted |
|---|---|---|
| Q1 | `.TP` tag placement | the body shares the tag's line when the tag is shorter than the indent; at equal length or longer, the body starts on the next line, fully indented |
| Q2 | Spacing and prevailing indent | one blank line before each `.TP`/`.IP` item, except the first after `.SH` or `.SS`; a width argument becomes the prevailing indent for later items that give none, until `.SH`, `.SS`, or `.PP` |
| Q3 | ASCII characters | `\(bu` as `o`; `\(em` as `--` |
| Q4 | Width source | `MANWIDTH`, then `COLUMNS`, then the terminal |
| Q5 | Pagers and overstrike | `less` and `more` interpret overstrike on Linux, Darwin, and NetBSD |

These behaviors were supplied during planning, and the renderers implement them. The build host for r0.4 had neither mandoc nor groff, so the comparison in `test-roffsub.sh` was skipped there. It runs, and reports word-stream differences, on any host where either is installed.

## 13 Phases

| Phase | Work | Status (r0.4) |
|---|---|---|
| P0 | Requirements and decisions | done (r0.3) |
| P1 | Specification as a man page in roffsub; test documents | done: `roffsub.7`; `t/ok`, plus one `t/bad` case per rule |
| P2 | Conformance check; comparison with roff | check done (`roffsub-check.awk`); comparison written, to be run on a host with mandoc or groff |
| P3 | Compiler, pre-formatter, generators | done: `roffsub-ir.awk`; the renderer's `pre` style; `roffsub-gen.awk` |
| P4 | awk renderer and emitter | done: `roffsub-render.awk`, `roffsub-emit.awk`; reference outputs in `t/gold`; sizes measured |
| P5 | C renderer and emitter | done: `roffsub.h`, `roffsub-emit.h`, `roffsub-tty.h`; byte-identical to awk |
| P6 | Manual for roffsub, produced and embedded | done: `roffsub.1`, embedded in full profile in the `roffsub` binary and function; `template.1` and `skill/SKILL.md` added in r0.8 |

**Verification (r0.4).** `make test` passes 217 checks, with 1 skipped (no roff on the build host). The checks cover:
- each test document at widths 40, 60, 80, and 120, in each style;
- byte agreement between the awk renderer, the binary, and the function;
- the emitter matching the renderer at 80 columns;
- both embeddings of the manual;
- round trips through the generator, including quotes, tabs, backslashes, and `??/`.

The binary also builds cleanly under gcc and clang with `-Wall -Wextra -pedantic`, and runs cleanly under address and undefined-behavior sanitizers. Only mawk was available on the build host, so BWK awk (Darwin, NetBSD) and gawk are still to be exercised with `make test AWK=...`.

**Darwin (r0.4).** `make check test gold` ran 218 checks, all passing, including the roff comparison. It reported word-stream differences from roff of 8 for `elements.1` and 3 for `roffsub.1`; those differences are still to be reviewed. Viewed through man, the r0.4 tables of `roffsub.7` overran 100 columns because roff wraps only text blocks; r0.5 adds W03 and rewrites those tables. The `+` that roffsub draws where a header rule meets a column gap has no equivalent in roff's `_` row. `t/probe/rule-join.1` shows, through man, whether a row of cell rules under a format line with a vertical bar draws one.

**Darwin (r0.5).** `make check test gold` ran 222 checks, all passing. In the `roffsub.1` word comparison, the only difference was roff breaking `pre-formatted` at its hyphen at the end of a line; the comparison now joins such breaks. The `elements.1` result had been overwritten by the next file's, so r0.6 keeps one result per file.

**Darwin (r0.6).** 252 checks, all passing. Probe Table C drew the `+` join with no vertical bars. The roff comparison reported 8, 14, 0, and 8 word differences for `elements.1`, `tables.1`, `roffsub.1`, and `roffsub.7`. Most of those came from tables, where roff and roffsub wrap cells at different widths and so interleave their words differently.

**Darwin (r0.7).** 264 checks, all passing. With tables left out, the roff comparison found no word differences in any of the four pages. Viewed through man on a wide terminal, the Requests table of `roffsub.7` was held at an 80-column share by the text-block widths that r0.7 set; r0.8 removes those widths.

**Darwin (r0.8).** Through man on a wide terminal, the text-block columns in `roffsub.7` and in the FILES table of `roffsub.1` still wrapped as if the line were 80 columns; r0.9 adds `x`.

**r0.8 and r0.9.** 313 checks pass here, with 1 skipped (no roff on the build host). The new checks cover `template.1` and the `roffsub.7` examples.

**r0.6 and r0.7.** r0.6 passed 251 checks here. r0.7 passes 263, with 1 skipped (no roff on the build host). The comparison now leaves tables out, prints every difference it finds, and keeps them in `t/out/roff-diff.txt`. New checks confirm that `-n` gives the same output from binary and function, matches its reference output, and draws no vertical lines. The new checks confirm that the binary and the function produce the same output, status, and messages for check, compile, pre-format, generate, and render, from files and from stdin, and that both reject the same usage errors.

The standard and its tools exist for the operator to apply where needed, at the operator's discretion. Adopting them in any particular program is not a phase of this plan.

## 14 Decisions

| Id | Decision | Ruling |
|---|---|---|
| D1 | Right margin and line measure | margin 0; no measure limit unless `ROFFSUB_MEASURE` is set |
| D2 | Indent unit on narrow terminals | 4 cells below 60 columns, 7 otherwise |
| D3 | Italic on terminals | underline, matching man on terminals; custom codes available |
| D4 | Table narrowing | the longest columns narrow together; short columns keep their width (section 7.3) |
| D5 | Profile threshold | renderer no larger than the program; function budget set after the P4 measurement |
| D6 | Pre-format width | 80 columns |

The budget value for exported functions (part of D5) remains open, to be set with the sizes in section 8.4 in hand.

| Id | Decision | Ruling |
|---|---|---|
| D7 | Scope of the binary | the binary and the function are identical, except where that is impractical and the manual says so; the binary carries the check, compile, and generate awk tools and runs them through awk |

### 14.1 Implementation Choices (r0.4)

These were made while building and need no decision. Any of them can be changed:

- **Two forms, one behavior (D7).** One package serves every system. Where the user's own directories are mounted noexec, the user can compile a binary but cannot run it, so the function must do everything. The binary and the function therefore take the same options and give the same output, status, and messages. The binary renders and emits in C. For checking, compiling, pre-formatting a source, and generating, it runs its embedded awk programs through the system's awk, just as the function does.
- **Command line.** `-w`, `-s`, `-m`, `-e`, `-c`, `-i` (with `-d` date and `-r` revision), `-p`, `-g c|bash name`, `-n` (with `-d` and `-r`), `-h`, `--help`, `-V`. Both forms compile a source on the fly when given one to render, and read stdin when no file is named.
- **Strict check.** `ROFFSUB_STRICT` makes the function's check treat warnings as errors; the makefile checks strictly.
- **Table rows and format lines.** A `_` rule row does not use up a format line.
- **Nested blocks.** `.RS` saves the margin and the prevailing indent, then resets the prevailing indent to the unit; `.RE` restores both.
- **Literal blocks inside definitions.** A literal block that directly follows a `.TP` tag puts the tag on its own line.
- **Install location.** `$HOME` for unprivileged users and `/usr/local` for root, unless `PREFIX` is set.

## 15 One Page, Read by Its Width

One `.TP` entry in an options section:

```
.TP
\fB\-k\fR \fIlist\fR
sort by the columns in \fIlist\fR, then the remaining columns in order.
```

At 80 columns the tag `-k list` is 7 cells. That is not shorter than the 7-cell indent, so the body starts on the next line:

```
OPTIONS
       -k list
              sort by the columns in list, then the remaining columns in
              order.
```

A tag of `-r` would share its line, with the body starting at the indent column. On a terminal, `-k` appears bold and `list` underlined, or in whatever colors `ROFFSUB_SGR` assigns. Through `less` or `more` the same emphasis arrives as overstrike. At 50 columns the indent drops to 4 and the lines re-wrap. Piped to a file, the entry comes out as plain text at 80.

The same source covers every case:

- **Large program, `full` profile.** The page reflows to any width.
- **Small program, `preformatted` profile.** The program carries the page set at 80 columns with its emphasis kept.
- **Any host with man.** roff sets the installed page in its own fonts.

Every one of them follows the same tag rule, so on every terminal an option's description stays attached to its tag. That is the whole point of roffsub: one source page, and a single fixed rule that decides how much formatting each program carries, for small and large programs and for minimal hosts and workstations alike.

[^1]: man macros, `.TP`/`.IP` behavior, and prevailing indent: [groff_man(7)](https://man7.org/linux/man-pages/man7/groff_man.7.html); conventions: [man-pages(7)](https://man7.org/linux/man-pages/man7/man-pages.7.html). URLs recalled, not re-fetched this session.
[^2]: tbl, including `w(N)` as a minimum width and the default column gap: [groff manual](https://www.gnu.org/software/groff/manual/groff.html), [mandoc tbl(7)](https://mandoc.bsd.lv/man/tbl.7.html); mandoc man and roff: [man(7)](https://mandoc.bsd.lv/man/man.7.html), [roff(7)](https://mandoc.bsd.lv/man/roff.7.html).
[^3]: POSIX [tput](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/tput.html) and [awk](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html) (`-v` escape processing); SGR parameters: [ECMA-48](https://ecma-international.org/publications-and-standards/standards/ecma-48/).
