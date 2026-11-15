# srt: sort for operators

srt is a sort for system operators: one grammar and one byte-for-byte
result on Linux, Darwin and NetBSD, as a C99 binary and as a bash
function for hosts without it.

`srt --help` is the manual and documents the current implementation.
[./plan-srt.md](./plan-srt.md) carries the requirements, the decisions behind them, and
the status of each revision.

    revision 6af8a908 20261114 103136 PST Sat --- r0.6
    revision 6af889a5 20261114 081741 PST Sat --- r0.5.1
    revision 6af87ca7 20261114 072215 PST Sat --- r0.5
    revision 6af871c9 20261114 063553 PST Sat --- r0.4.2
    revision 6af86b89 20261114 060913 PST Sat --- r0.4.1 (srt.fn.bash only)
    revision 6af82211 20261114 005545 PST Sat --- r0.4
    revision 6af81dc6 20261114 003726 PST Sat --- r0.3
    revision 6af81678 20261114 000616 PST Sat --- r0.2
    revision 6af8010b 20261113 223451 PST Fri --- r0.1

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

<!--contents 2 3 pre="## Contents" post="---"-->

## What it does

- `-k5,3` means "column 5, then column 3, then the remaining columns".
- Columns are words, as `$1`, `$2` are in awk: widths, padding and
  squeezed blanks do not matter. `-k-1` is the last column.
- The highest column named runs to the end of the record when it is
  compared as text, so a file name with spaces is one key.
- `-x` orders hexadecimal numbers; `-D` prints only the records whose
  named columns repeat.
- Stable by default.
- Order is by byte value; the locale environment is never consulted.
- `-v` orders versions, versioned archives, host names, and IPv4 and
  IPv6 addresses and networks.
- Input larger than memory is sorted through a spill file, with the
  same result as the in-memory route.
- Keys are encoded once per record and sorted as bytes, so a keyed
  sort costs about what a plain one does.

## Not a drop-in for sort(1)

Several letters keep their name and change their meaning. Do not point
an existing script at srt unexamined.

| option | sort(1) | srt |
|---|---|---|
| `-k a,b` | fields a through b | column a, then column b, then the rest |
| `-k` alone | error | the whole record (the default) |
| `-D` | (none) | only duplicates, by the named columns |
| `-x` | (none) | hexadecimal numeric |
| `-b` | ignore leading blanks | outline sort by indentation |
| `-S` | memory size, or unstable | allow unstable; memory is `--mem` |
| `-R` | hash-random, or record separator | uniform shuffle |
| `-z` | NUL-terminated records | refused: the spelling is `-Z` |
| `-Z` | (none) | NUL-terminated records |
| `-V` | version sort | print revision; version sort is `-v` |
| `-h` | human-numeric | usage; human-numeric is `-H` |

`-c`, `-C`, `-d`, `-f`, `-i`, `-n`, `-r`, `-u`, `-o`, `-t`, `-T`
keep their usual meaning.

## Global options and key letters

One rule is shared with sort(1) and is easy to misread: ordering
letters written on a column in `-k` replace the global options for
that column. They are not added to them.

    srt -n -k1r      # column 1: reversed TEXT; other columns numeric
    srt -k1nr        # column 1: reversed numeric
    srt -r -k5n,3    # column 5 numeric ascending; the rest reversed

`srt --help`, section GLOBAL AND KEY OPTIONS, works through it.

## Listings: hexadecimal columns, names, duplicates

The case srt is built around: a listing of files, one per line, with
columns such as inode, links, hash, size, time, name, the numbers in
hexadecimal and the name last.

    srt -k5x,4x,6 listing     # time, size, then the name, spaces and all
    srt -k5x,4x listing       # time, size; the name compared last
    srt -k4xr listing         # largest first
    srt -D -k3 listing        # files whose hash repeats, grouped
    srt -D -k3,4x listing     # the same hash and the same size
    srt -t/ -D -k-1 paths     # the same base name in different directories
    srt -t/ -k-1 paths        # by base name, then by directory

Three rules make these work, each in `srt --help`:

- The last column. The highest column named in `-k` runs to the end
  of the record when it is text; when it is a number it is one word
  and the rest of the record is compared last. Section THE LAST
  COLUMN.
- `-D` tests exactly the named columns, each one word; with no `-k`,
  whole records. With `-u`, identical records count once.
- `-k-N` counts columns from the end. With any such key every word
  is a column.

One consequence to know: `-k5,3` on six one-word columns compares 5
and 6 together, then 3, 1, 2, 4. Write `-k5n,3` (or any numeric
letter) for column 5 alone, then 3, 1, 2, 4, 6.

To reverse, put `r` after the column (`-k5r`) or give `-r`, which
reaches every column named without letters. `-kr5` is refused.

## Build

    make install    # PREFIX: /usr/local for root, $HOME otherwise; DESTDIR honored
    make test       # regression suite against ./srt
    make install    # PREFIX=/usr/local by default; DESTDIR honored
    make uninstall
    make clean

Requirements: a C99 compiler, POSIX libc, make, and bash for the test
suite. No other library, and nothing whose result varies by host: no
locale, and no library parsing of numbers or addresses in comparisons
other than `strtod` for `-g`.

Linking: static on Linux and NetBSD. Darwin has no static system
library, so there the binary links dynamically against the system
library alone. If a static libc is not installed on Linux, the build
says so and links dynamically.

The [./makefile](./makefile) uses only constructs common to GNU make, bmake and the
Darwin make.

## Outline sort

`-b` sorts an outline: lines that share a parent and a byte-identical
indent are sorted among themselves, and each line keeps the more
deeply indented lines beneath it. Tabs and spaces are never converted.

    srt -b inventory.yml          # sort each block, keep the nesting
    srt -cb inventory.yml         # is every block in order?

`srt --help`, section OUTLINE SORT, has the rules and an example.

## Bash function

[./srt.fn.bash](./srt.fn.bash) gives the same grammar and the same result on a host
where the binary is not installed. Source it:

    . $HOME/share/srt/srt.fn.bash

When a binary named `srt` is on PATH the function runs it. `--fn`
allows only the function and `--bin` only the binary: with `--fn` the
function never hands over (and the binary refuses), with `--bin` the
function runs the binary or stops with an error.
Sourcing the file defines that one name and
nothing else: every helper and variable lives inside `srt`, in a
subshell, so a call leaves the calling shell unchanged. It needs
bash, awk, sort, cat, cp, mktemp and mv,
and uses no ordering option of the native sort: awk encodes each key
so that a plain byte comparison gives srt order.

It declines, with exit 2 and a message naming the binary: `-b`, `-Z`,
a NUL or non-ASCII `-t`, input containing a byte from 0x01 to 0x04,
and hexadecimal floats under `-g`. It stages a copy of the input in
the `-T` directory and is several times slower than the binary.
`srt --help`, section BASH FUNCTION, has the list.

## Memory

Input that fits the budget is sorted in memory with no temporary file.
Beyond it, sorted runs go to one spill file in `-T dir` (default
`$TMPDIR`, then `/var/tmp`) and are merged at the end. The spill file
is unlinked on creation, so nothing is left behind on any exit.

    srt --mem 2g -T /scratch big.log
    SRT_STATS=1 srt --mem 64m big.log >/dev/null   # budget, runs, passes, batches

The default budget is half of physical memory, or half of a lower
address-space or data limit. `--mem N[bkmg]` or `SRT_MEM` sets it.

## Examples

    srt -t: -k3n /etc/passwd          # by uid, then the other fields
    ps aux | srt -k4nr,1              # by memory descending, then user
    srt -v hosts.txt                  # addresses and names in order
    du -h | srt -Hr                   # largest first
    srt -u -o list list               # sort and dedupe in place
    srt -c a.txt b.txt || echo fix    # check several files
    srt -k table                      # no column named: whole records
    srt -t. -k-1 names                # by file suffix

## Status of r0.6

Working: the whole option grammar, column keys from either end, every
ordering option including hexadecimal, duplicates,
check (one pass, two records held), unique, shuffle, NUL records,
atomic `-o`, `--help` with pager, outline sort, memory budget with spill and
multi-pass merge; and the bash function, which the suite holds to the
same output as the binary.

Not yet:
- `-b` and the merge of spilled runs compare records directly; only
  the sort of each batch in memory uses encoded keys.
- `-b` holds the whole input in memory; past the budget it stops with
  an error instead of spilling.

Platforms: r0.6 is built and tested on Linux (gcc, GNU make, bash
5.2, mawk, GNU sort). On Darwin the whole suite, binary and bash function, passes at r0.6
(664 cases). Not yet exercised: anything on NetBSD; bmake; the
rendering of `srt.1`. Reports are
wanted, and the suite names each difference as a failing case.

The number of cases the suite runs varies by host: cases that need a
non-root user or an enforced address-space limit skip themselves. The
last line of `make test` is the result.

## Files

| file | purpose |
|---|---|
| [./srt.c](./srt.c) | the program, single file, C99 |
| [./srt.fn.bash](./srt.fn.bash) | the same grammar as a bash function, for hosts without the binary |
| [./makefile](./makefile) | targets: all srt man test install clean uninstall |
| [./test-srt.sh](./test-srt.sh) | regression suite; `test-srt.sh [path-to-srt]`; compares the function with the binary when [./srt.fn.bash](./srt.fn.bash) is beside it |
| [./plan-srt.md](./plan-srt.md) | requirements, decisions, revision status |
| [./README.md](./README.md) | this file |
