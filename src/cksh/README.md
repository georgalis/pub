# cksh: sortable stat and hash listing

cksh lists files one per line, with inode, links, a SHAKE256 hash,
size and modification time in hexadecimal and the name last: a listing
made to be sorted, compared and joined. It is a C99 binary, and a bash
function for hosts without it.

`cksh --help` is the manual and documents the current implementation.
On a terminal it is shown as a man page, headings in bold, through
the formatter of the host (mandoc, else nroff and a pager) without the
page being installed; where there is no formatter, through the pager
alone. `cksh --man` writes the man page source.
[./plan-cksh.md](./plan-cksh.md) carries the requirements, the decisions behind them, the
history, and the status of each revision.

    revision 6af8d530 20261114 134000 PST Sat --- r0.6
    revision 6ab7e734 20260926 083932 PDT Sat --- r0.5
    revision 68e9ff40 20251010 235456 PDT Fri --- r0.4
    revision 68e20bca 20251004 231018 PDT Sat --- r0.3
    revision 677c9c44 20250106 191516 PST Mon --- r0.2
    original 6305e87b 20220824 015939 PDT Wed --- r0.1

_(c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

<!--contents 2 3 pre="## Contents" post="---"-->

## What it does

    $ cksh -n t/*
       inode lk hash       size    mdate name
      1cc01d  1 483366        3 5e0bd2c0 t/a
      1cc01c  2 000000     1000 5e0bd2c0 t/d/
      1cc01f  1 483366        1 5e0bd2c0 t/l@
      1cc021  1 c85112        1 5e0bd2c0 t/sp ace

    $ cksh t/*
    . . 483366        3 5e0bd2c0 t/a
    . . 000000     1000 5e0bd2c0 t/d/

The heading is shown for reference; cksh does not write it.

- Six columns, always. A column that is left out is written as a dot,
  so the column numbers never shift and the name is always column 6.
- Columns are words, as `$1`, `$2` are in awk: widths and padding do
  not matter. A value wider than its column moves the rest of that one
  line and nothing else.
- The name is last and runs to the end of the line, blanks included,
  with an indicator in the manner of `ls -F`: `/` directory, `@`
  symlink, `|` fifo, `=` socket.
- By default inode and links are left out (`-n2`), since they differ
  between copies of the same tree; two trees listed this way can be
  compared with diff or join.
- Names come from the arguments, or one per line from standard input.
- Lines are written as the files are read, unless `-k` or `-r` asks
  for an order.
- `-Z` ends each line, and each name on standard input, with NUL in
  place of newline, so any name passes: `ff -Z | cksh -Z | srt -z`.
- `-L` follows symlinks: the line of a link is the line of the file it
  leads to.

## The hash is shake256-6

Column 3 is SHAKE256 of the file content, cut to N hexadecimal
characters, and that hash is named shake256-N. The default is
shake256-6; `-x64` gives shake256-64. N is the width of the column.

SHAKE256 is an extendable-output function: a shorter output is the
beginning of every longer one. The shake256-6 of a file is the first
six characters of its shake256-64.

The name is written with a hyphen and never with a slash, because a
slash after SHAKE256 is read three ways. The default hash would be
24 to a reader who counts bits, 3 to one who counts bytes, as the
`-xoflen` of openssl does, and 6 to one who counts hexadecimal
characters. `cksh -x` counts hexadecimal characters, so the option,
the name and the column are one number. `cksh --help`, section HASH,
sets the three readings side by side.

`-x` alone is `-x0`: no hash, and no file is read.

## Sorting

`-k` takes the key list of srt: `-k5,4` is "column 5, then column 4,
then the remaining columns left to right".

    cksh -k *            # by name
    cksh -k5 *           # by time, oldest first
    cksh -k5r *          # newest first
    cksh -k5,4 *         # by time, then size, then the rest
    cksh -k4r,6 *        # largest first, then by name
    cksh -r *            # the arguments in reverse order

- cksh knows the type of each column: inode, links, size and time
  compare as numbers, by value; the hash and the name compare as
  bytes. No locale is consulted.
- `-k` alone names no column and sorts by name.
- A column that is left out, a dot, is a null column: a key on it
  orders nothing and the next column decides.
- To reverse, put `r` after the column (`-k5r`) or give `-r`, which
  reaches every column written without a letter. `-r` with no `-k`
  reverses input order. `-kr5` is refused.
- `x` is accepted on the numeric columns and changes nothing, so a
  list written for srt can be given to cksh.

The same order from srt: `cksh -k5,4,6` writes what
`cksh | srt -k5x,4x,6,1x,2x,3` writes. `cksh --help`, section KEYS,
has the rule.

## Save and check

`-o output` writes the listing to a file and not to standard output:
beside the destination, synced, given the destination's mode, and
renamed over it when the run is complete. A failed or interrupted run
leaves the original as it was, and the output may be one of the files
listed.

`-c listing` reads a saved listing back and examines each file it
names. A file that matches its record is passed over; a file that
differs is written as it is now, and the exit status carries 64.

    find . -type f | cksh -k -o tree.ck     # save
    cksh -c tree.ck                         # what changed; nothing if none
    cksh -c tree.ck >/dev/null || echo changed

- Each record is checked as it was made: its dots say which columns
  were left out and are not compared, and the width of its hash says
  which shake256-N to compute. `-n` and `-x` are not consulted, and a
  listing may mix records made in different ways.
- The output of a check is itself a listing, so `-k`, `-r` and `-o`
  apply to it, and it can be fed to srt or joined with the original.
- A file that is gone is an error (status 4) and writes no line.
- A listing made with `-L` or `-Z` is checked with the same option.

`cksh --help`, section CHECK, has the rules for names that end in an
indicator character of their own and for names that begin with a blank.

## Changed in r0.6

A script written for r0.5 needs these looked at.

| r0.5 | r0.6 |
|---|---|
| `-x N` counts bytes; default 3 | `-x N` counts hexadecimal characters; default 6 (the same hash) |
| `-0` .. `-5` | `-n0` .. `-n5` |
| `-n` and `-x` before a file: error | `-n` is `-n0`, `-x` is `-x0`, and the word is a file |
| `-k N`: column N, the columns after it, the name | `-k list`: the named columns, then the rest left to right |
| `-kr5`, `-rk5` | `-k5r` or `-rk5`; `-kr5` is refused |
| mdate before 1970: `ffffffffed307900` | `-12cf8700` |
| `cksh d/` writes `d//` | `d/` |
| names written as they are | on a terminal, control bytes are written as `\ooo` |

One consequence of "the next word is a value only when it reads as
one": in `cksh -n *`, a first file named `5` is taken as the value.
Write `cksh -n0 *`, or `cksh -n -- *`.

## Build

    make            # cksh and cksh.1 (the output of cksh --man)
    make test       # regression suite against ./cksh
    make install    # PREFIX: /usr/local for root, $HOME otherwise; DESTDIR honored
    make uninstall
    make clean

Requirements: a C99 compiler, POSIX libc, make, and bash for the test
suite. No other library: SHAKE256 is built in, so every hash length
works on every host.

Linking: static on Linux and NetBSD. Darwin has no static system
library, so there the binary links dynamically against the system
library alone. If a static libc is not installed on Linux, the build
says so and links dynamically.

`make install` with no `PREFIX` installs under `/usr/local` for root
and under `$HOME` for anyone else: `bin/cksh`, `share/cksh/cksh.fn.bash`,
and `cksh.1` in `share/man/man1` where `share/man` exists, else
`man/man1`. `make uninstall` follows the same rule.

The [./makefile](./makefile) uses only constructs common to GNU make, bmake and the
Darwin make.

## Bash function

[./cksh.fn.bash](./cksh.fn.bash) gives the same options and the same bytes on a host
where the binary is not installed. Source it:

    . /usr/local/share/cksh/cksh.fn.bash

When a binary named `cksh` is on PATH the function runs it. `--fn`
allows only the function and `--bin` only the binary. Sourcing the
file defines that one name and nothing else: every helper and variable
lives inside `cksh`, in a subshell, so a call leaves the calling shell
unchanged.

It needs bash, stat, sort, mktemp for `-o` and, for a hash, an openssl
with shake256;
it prefers `$LOCALBASE/bin/openssl` to the one on PATH, and checks it
against the known hash of empty input before use. An openssl without
`-xoflen` limits `-x` to 64; one without shake256 is status 2, and
`-x0` needs none. It runs several programs per file and is much slower
than the binary. `cksh --help`, section BASH FUNCTION, has the list of
differences.

## Diagnostics and exit status

Messages go to standard error, each ending in a hexadecimal tag that
names the message:

    >>> cksh : cannot stat 't/nope': No such file or directory (6ab75465)
    ^^^ cksh : fifo, not hashed 't/p' (6ab75468)

The exit status is a bitmask. 1 and 2 are fatal and are returned
alone; the others accumulate while the run continues.

| bit | meaning |
|----:|---|
| 1 | invalid option or argument |
| 2 | environment: memory, standard input or output; in the function, no usable openssl or stat |
| 4 | cannot stat a name; line skipped |
| 8 | cannot open or read a regular file; line skipped |
| 16 | fifo, socket or device, never opened; or a node that changed during the scan |
| 32 | dangling symlink |
| 64 | with `-c`, a file differs from its record |

## Examples

    cksh *                              # hash, size, mdate, name
    cksh -n *                           # every column
    cksh -n3 -k4 *                      # sizes, smallest first; nothing read
    cksh -x64 file                      # shake256-64
    find . -type f | cksh -k3           # files of the same content together
    ff . -t f | cksh -k5,4              # a tree, by time and size
    find . -type f | cksh | srt -D -k3  # files whose hash repeats
    find a -type f | cksh -k > a.ck     # one tree, ready for diff or join
    ff -Z . -t f | cksh -Z | srt -z -k5x,4x   # NUL records end to end

## Status of r0.6

Working: the whole option grammar, key lists, `-L`, `-Z`, `-o`, `-c`,
both forms, the manual as a man page, terminal escapes, and the suite,
which holds the bash function to the same bytes and status as the
binary and, where srt is present, holds cksh order to srt order.

Platforms: r0.6 is built and tested on Linux (gcc and clang, GNU make,
bash 5.2, GNU sort and stat, OpenSSL 3), as root and as an unprivileged
user, and under the address and undefined-behavior sanitizers. On
Darwin the suite ran whole, binary and function, with `-L`, `-o`, `-c`,
`--man` and `--help` on a terminal included (335 cases passed; the two
that failed were faults of the suite's grep, corrected here and not yet
rerun there). Not yet exercised: anything on NetBSD; bmake; and, on any
host, the rendering of the man page by a real formatter: the suite
checks that the source reaches mandoc or nroff, with stand-ins, not
what they draw. Reports are wanted, and the suite
names each difference as a failing case.

The number of cases the suite runs varies by host: cases that need a
non-root user, openssl shake256, `/dev/full`, a pty through
`script(1)`, srt, or a file system that takes a name that is not UTF-8
skip themselves and say so. The last line of `make test` is the result.

## Files

| file | purpose |
|---|---|
| [./cksh.c](./cksh.c) | the program, single file, C99 |
| [./cksh.fn.bash](./cksh.fn.bash) | the same options as a bash function, for hosts without the binary |
| [./makefile](./makefile) | targets: all cksh man test install clean uninstall |
| [./test-cksh.sh](./test-cksh.sh) | regression suite; `test-cksh.sh [path-to-cksh]`; compares the function with the binary when [./cksh.fn.bash](./cksh.fn.bash) is beside it; `SRT=path` names an srt for the equivalence cases |
| [./plan-cksh.md](./plan-cksh.md) | requirements, decisions, history, revision status |
| [./README.md](./README.md) | this file |
