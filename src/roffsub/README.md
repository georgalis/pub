# roffsub: easy terminal manuals

roffsub is a small subset of the man macros and tbl for manuals read in a terminal. Every roff program displays a roffsub page, and small awk and C routines render it too. A program can therefore carry its own manual and show it at `--help`: reflowed to the terminal's width, with bold and italic where the terminal supports them, and tables fitted to the space. The same file is installed as the man page.

Revision: r0.9, 2026-11-15

(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.

<!--contents 2 3 pre="## Contents" post="---"-->

## Why roffsub

Markdown suits documentation read in a browser. A command-line program is read in a terminal, where markdown's line breaks are fixed and it has nothing to show an option in bold or hang a description under it. roff has always done this well, and every man page is roff, but few people write it by hand. `skill/SKILL.md` explains the problem, the approach, and how to write and embed a roffsub page; it is written to guide an LLM writing the page and serves a person equally well. Start there, then copy `template.1`.

## Quick Start

```
make                      # binary, function regions, installable pages
make test                 # all checks
. ./roffsub.fn.bash       # define the roffsub function
roffsub roffsub.7         # read the standard in this terminal
roffsub --help            # read the tool's manual
roffsub -c mypage.1       # check a page's form
```

`make install` installs under `$HOME`, or under `/usr/local` when run as root. Set `PREFIX` to install somewhere else.

## Files

| File | Purpose |
|---|---|
| `roffsub.7` | the standard, written in roffsub |
| `roffsub.1` | the tool's manual, embedded in the binary and the function |
| `template.1` | a starting page with the conventional sections |
| `skill/SKILL.md` | why and how to use roffsub, for an LLM or a person |
| `roffsub.fn.bash` | the `roffsub` function, for systems where the user's own directories are mounted noexec |
| `roffsub.c` | the binary; it behaves as the function does, and both check, compile, and generate through awk |
| `roffsub-check.awk` | form check, rules E01 to E11 and W01 to W03 |
| `roffsub-ir.awk` | compiler, source to records |
| `roffsub-render.awk` | renderer, records to terminal text |
| `roffsub-emit.awk` | emitter, pre-formatted text to terminal text |
| `roffsub-gen.awk` | embedding as a C array or a marked bash region |
| `roffsub-man.awk` | the page to install for man (`roffsub -n`), with tables rewritten for roff |
| `roffsub.h`, `roffsub-emit.h`, `roffsub-tty.h` | the renderer, the emitter, and the width, style, and pager choice, in C |
| `test-roffsub.sh`, `t/` | tests, test documents, reference outputs |
| `plan-roffsub.md` | requirements, decisions, and revision record |

## Using roffsub in a Program

1. Write the manual as `NAME.1` in roffsub, then check it with `roffsub -c NAME.1`.
2. Install the page written by `roffsub -n -d DATE -r REV NAME.1`. It fills in `.TH` and rewrites the tables so that roff draws them as roffsub does.
3. Choose a profile:
   - **full:** compile the records (`roffsub -i`) and embed them, along with `roffsub.h` or `roffsub-render.awk`. The help then reflows to any width.
   - **preformatted:** for a program smaller than the renderer, embed the text from `roffsub -p` along with `roffsub-emit.h` or `roffsub-emit.awk`. The help is then fixed at 80 columns, with emphasis kept.
4. Embed with `roffsub -g c NAME_man FILE > NAME.man.h`, or with `roffsub -g bash _name_man FILE`, splicing the region into the function.
5. At `--help`, call `roffsub_tty_open`, then render or emit to `t.out`, then call `roffsub_tty_close`. The bash side follows the same choices; see `roffsub.fn.bash`.

`-h` stays the program's own quick reference, written for a different purpose from the manual: a refresher and a confirmation when a full review is not needed.

## Measured Sizes (r0.9)

| Part | Size |
|---|---|
| C renderer (`roffsub.h`), compiled | about 12 KB of text |
| awk renderer source | about 9.7 KB |
| emitter (awk or C) | about 1 KB |
| `roffsub` function with its own manual embedded | about 41 KB |
| `roffsub` binary with its manual and the awk tools embedded | about 64 KB of text |

A program whose own size is under these figures is a candidate for the preformatted profile.
