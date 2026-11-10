# asciixlate

<!-- (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution. -->
<!-- rev 6af37686 20261110 115446 PST Tue 11:54 AM 10 Nov 2026 2.1.0 introduction; build rationale moved to PLAN.md -->

UTF-8 to ASCII transliteration under a local rule file: `---` for an em
dash, `??` for a character with no mapping, and every other choice
adjustable in `~/.asciixlate`. One binary, libc only; the transliteration
table is compiled in, so the same input yields the same bytes on Darwin,
Linux and NetBSD.

    make                 # GNU make, bmake or Apple make
    make test
    make install         # PREFIX defaults to /usr/local for root, else $HOME

## Use

    asciixlate notes.md > notes.ascii.md
    asciixlate -i *.md                       # in place, atomic
    asciixlate --report archive/*.md >> ~/.asciixlate
    asciixlate -qs -n draft.md               # exit 2 if anything is unmapped

`asciixlate -h` is the one-screen option summary; `asciixlate --help` is
the manual, and the installed man page is derived from it.

With no file named, standard input is filtered in blocks, in bounded
memory, unless it is a terminal:

    some-command | asciixlate | less
    asciixlate -b 4k < big.txt > big.ascii.txt
    :'<,'>!asciixlate                        # vi: filter the selected lines

## The rule file

    U+2014  ---             # em dash
    U+00AD  ""              # soft hyphen: drop
    U+00A0  " "             # no-break space: one plain space
    \xC2\xA9  (c)           # by byte sequence
    U+1F680 ""              # an emoji: deleted, and one space with it
    <paste>  ---            # or paste the character itself as the key

Keys are `U+XXXX`, `0xXXXX`, `\xHH...`, or literal UTF-8; `=` forces a
literal. A key of more than one code point is a longest-match rule.
Values run to end of line, or sit in double quotes to hold spaces, a `#`,
or nothing. `--report` prints an editable stub for every unmapped code
point; `--list` prints the whole active table in the same grammar.

Deleting a pictograph takes the space that set it apart, so
`Launch <rocket> today` becomes `Launch today`; deleting anything else
never touches a space.

## Files

| File | Role |
|---|---|
| `asciixlate.c` | the program, its usage and its manual |
| `translit_table.h` | generated built-in table; the authority |
| `mktable.py` | table generator, for auditing a Unicode upgrade |
| `makefile` | build, test, install |
| `test.sh` | regression suite |
| `PLAN.md` | requirements, decisions, review findings, open questions |
| `example.md`, `example.ascii.md` | a sample and its conversion |
