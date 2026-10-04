### [pub](../)
## [pub/src](../)
# [markdown.sh](./)

One markdown file, read natively on GitHub and rendered by `markdown.sh` as standalone HTML for a static hosts. The script is the renderer; its help document is at once the feature reference, the command reference, and the regression corpus that holds the renderer to GitHub-flavored behavior.

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

The help document is emitted by the script itself (`markdown.sh -H`), so the copy here is a convenience: regenerate it after any change and the two cannot drift.

- [markdown.sh](./markdown.sh) --- bash and POSIX awk renderer: GFM blocks and inline, footnotes in source form, `{#id}` anchors, local `.md` link rewriting, a contents directive, and the built-in corpus.
- [markdown-help.md](./markdown-help.md) --- usage, output conventions, features, divergences from GitHub, and 56 regression cases.

## Quick reference

```
usage: markdown.sh input.md        render to input.md.html, print its realpath
       markdown.sh -f input.md     print the HTML fragment to stdout (- reads stdin)
       markdown.sh -H              print markdown-help.md (usage, features, corpus)
       markdown.sh -c [corpus.md]  run the regression corpus (default: built in)
       markdown.sh -h              print this usage
```

- `markdown.sh README.md` writes `index.html`, the page a static host serves for the bare directory; links to `./README.md` become `./`.
- `markdown.sh -H > markdown-help.md && markdown.sh markdown-help.md` renders the help as its own test output.
- `markdown.sh -c` exits 1 on any failure; a new case starts as a scratch file checked with `-f`, then joins the corpus.
- A table of contents (stays invisible on GitHub): `<!--contents 2 3 pre="## Contents" post="---"-->`.
