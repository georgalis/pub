---
name: roffsub
description: Write, check, and embed command-line manuals in roffsub, a small roff subset that installs as a man page and also renders inside the program's own --help at any terminal width. Use when documenting a CLI program whose users read documentation in a terminal, when a program's help text and man page should come from one source, or when converting fixed-width or markdown help into a man page.
---

# roffsub

roffsub is a subset of the man macros and tbl. A page written in it installs as an ordinary man page, and small awk and C routines can also render it inside the program's own `--help`. The rendering fits the terminal's current width, with bold and italic wherever the terminal can show them. This skill explains when roffsub is worth using, how to write a page, and how a program carries one.

## Why roffsub

Most projects document themselves in markdown. Markdown is easy to write and renders well on code-hosting sites, in browsers, and in print. For a command-line program, though, the reader is usually at a terminal, and that is where markdown falls short:

- **Fixed line breaks.** Help text written for 80 columns stays broken on a wide terminal and overflows a narrow one.
- **No structure for options.** Markdown has nothing to say "this is an option, and this is its description", so a definition can't hang under its tag.
- **No emphasis in the terminal.** It has no way to show an option name in bold and an argument in italic only when the terminal supports it.
- **Copies drift.** The man page, the `--help` text, and the README end up as separate copies that drift apart.

roff has described command-line documentation for decades, through a synopsis, tagged option paragraphs, sections, lists, and tables, and every Unix-like system can display it. Few people write it, because its syntax is unfamiliar. When an LLM is doing the writing, that obstacle disappears. What remains is that a real roff program may not be installed on a minimal host, and that a program cannot easily run roff to produce its own help. roffsub removes those last two problems.

Use roffsub when:
- the program is used mostly from a terminal;
- the same documentation should appear in `man`, in `--help`, and in plain text;
- the program must run on minimal hosts, or as a shell function where binaries cannot run (for example, a home directory mounted noexec).

Stay with markdown for project overviews meant for a browser, such as a README or a contributing guide.

## The Approach

1. **One source.** The manual is `NAME.1`, a roff page restricted to the roffsub subset. It is the man page and the help text alike.
2. **Check the form, not the content.** `roffsub -c` rejects anything outside the subset, so every roffsub renderer can display what passes.
3. **Install for man.** `roffsub -n` writes the page to install: it fills in the date and version and rewrites tables so roff draws them as roffsub does.
4. **Carry it in the program.** The page is compiled once, at build time, into simple records. The program embeds either:
   - the records plus a small renderer (the **full** profile), which reflows to any width; or
   - text set at 80 columns with its fonts kept, plus a tiny emitter (the **preformatted** profile), for programs smaller than the renderer.
5. **Render at the moment of reading.** At `--help`, the program picks the width (from `MANWIDTH`, `COLUMNS`, or the terminal) and the emphasis style:
   - **overstrike**, when the output goes through a pager;
   - **SGR** (terminal control sequences), when it goes straight to a terminal;
   - **plain**, when it goes to a file or pipe.

   The C and awk renderers produce identical bytes.

## Writing a Page

Start from `template.1`, which has the conventional sections in order: NAME, SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES, ENVIRONMENT, EXIT STATUS, SEE ALSO. Write content first, then check it.

| Need | Write |
|---|---|
| section, subsection | `.SH NAME`, `.SS Name` |
| paragraph | `.PP` (never a blank line) |
| option and its description | `.TP`, then the tag line, then the text |
| bullet or numbered item | `.IP \(bu`, `.IP 1. 4` |
| nested block | `.RS` ... `.RE` |
| synopsis, example commands | `.nf` ... `.fi` |
| literal word (typed as is) | `\fBword\fR` or `.B word` |
| replaceable argument | `\fIfile\fR` or `.I file` |
| option hyphen | `\-` (so it copies and pastes as a real minus) |
| table | `.TS` / options with `tab(@);` / format lines / rows / `.TE` |
| table cell that may wrap | `T{` on its own line ... `T}` |

Rules that keep a page renderable everywhere:
- ASCII only, and no tab characters.
- One sentence per line, and no line starting with a space.
- Start a text line that begins with a period as `\&.`.
- Put `'\" t` on line 1 when the page has a table.
- Return the font to roman (`\fR`) by the end of each request line and each table cell.
- Write any table cell longer than a few words as a `T{ ... T}` text block, because roff wraps only text blocks.
- Write `-h` separately from the manual, as a quick reference: a short synopsis, the options in brief, and the one or two details that matter most. It is not an extract of the manual.

## Checking and Viewing

```
roffsub -c mytool.1             # form check; errors E01-E11, warnings W01-W03
roffsub mytool.1                # read it as --help will show it
roffsub -w 50 -s plain mytool.1 # a narrow terminal, plain text
man ./mytool.1.out              # after roffsub -n, read it through man
```

| Message | Usual fix |
|---|---|
| E02 request not in roffsub | use the requests in roffsub(7); for indent, `.RS`/`.RE` instead of `.in` |
| E05 empty or indented text line | use `.PP` or `.sp`; remove the leading space |
| E06 font not roman | close `\fB` or `\fI` with `\fR` before the line ends |
| E08 table form | add `tab(@);`; give every row one cell per column |
| W01 option hyphen | write `\-` in option names |
| W03 table too wide for roff | turn the long cells into `T{ ... T}` blocks |

## Carrying the Manual in a Program

```
roffsub -n -d 2026-11-15 -r 1.0 mytool.1 > mytool.1.out   # page to install
roffsub -i -d 2026-11-15 -r 1.0 mytool.1 > mytool.ir      # records (full profile)
roffsub -g c mytool_man mytool.ir > mytool.man.h           # C array
roffsub -g bash _mytool_man mytool.ir > mytool.man.bash    # bash region
roffsub -p mytool.1 > mytool.pre                           # preformatted profile text
```

- **C.** Include `roffsub.h` (full) or `roffsub-emit.h` (preformatted), along with `roffsub-tty.h`. At `--help`, call `roffsub_tty_open`, render or emit to `t.out`, then call `roffsub_tty_close`.
- **bash.** Read the embedded text into a local variable, then pipe it through `roffsub-render.awk` (full) or `roffsub-emit.awk` (preformatted). Pass the records on stdin, never with `awk -v`.
- **Choosing the profile.** Use full when the renderer, about 12 KB compiled or about 10 KB of awk, is no larger than the program it would live in. Otherwise use preformatted.

## The Reference, the Tool, the Template

- **`roffsub.7`, the reference.** It defines the subset, how a page is rendered, the program interface, and the conformance rules. It is written in roffsub, and its EXAMPLES section shows each table form and layout element as source followed by the result.
- **`roffsub`, the tool.** A C binary and a bash function that behave identically. They check (`-c`), compile (`-i`), render (the default), pre-format (`-p`), emit (`-e`), write the page to install (`-n`), and generate embeddings (`-g`). The function serves systems where binaries in the user's own directories cannot run.
- **`template.1`, the template.** A conforming starting page with the conventional sections.

When asked to document a command-line program, write the manual in roffsub from the template and confirm that `roffsub -c` passes. Show the user how it reads with `roffsub -w 80`. Then offer to wire it into `--help` in the profile that suits the program's size.
