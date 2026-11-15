# ff plan

ff: functional find. A short-switch find with NetBSD find(1) semantics
where they matter, one interface on Linux, Darwin and NetBSD, delivered
as C99 source (`ff.c`) and a bash function (`ff.fn.bash`).

This plan drives the package revisions. It took this shape at r0.7,
when the package took the shape of cksh's and srt's: before that the
plan was PLAN.md, a design record by revision (r1 to r10 there), kept
whole as section 14. Items marked **V** (section 2) began as
ambiguities with a proposed default; nothing downstream of an
unconfirmed V item was built until it was ruled on. Decisions are
recorded in section 12, the affected sections state the decision in
place, and section 13 holds the status of each revision as built.
Where a decision reverses an earlier one, both are stated.

    revision 6af927be 20261114 193214 PST Sat --- r0.7: plan-ff.md opened from PLAN.md; V01-V09 ruled and built, V10 built as proposed and open; key grammar shared with srt and cksh; cksh package model
    original 6ab7fec8 20260926 102008 PDT Sat --- PLAN.md, the design record of r0.1 to r0.6 (section 14)

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

<!--contents 2 3 pre="## Contents" post="---"-->

## 1 Purpose and scope

ff walks file trees and evaluates an expression for every node, as
find does, with one letter per switch. It prints the names for which
the expression holds, or with `-v` one cksh line per node, and with
`-k` sorts what it prints by the columns of that line.

In scope: the walk, with an owned walker that never re-resolves a path
it has checked; the primaries and actions of section 14; `-v`, the
cksh line without a hash; sorting by column with the key grammar of
srt and cksh; NUL-terminated records; a bash function that translates
the same grammar to the native find and writes the same bytes.

Out of scope, by requirement: hashing (that is cksh, which reads the
names ff prints); duplicate detection (that is `srt -D`); a global
reverse option (V01); locale collation; `-ok`, `-fprint`, `-printf`,
`-flags`, `-fstype`.

ff is one of three tools that share a record and a key grammar: ff
finds files, cksh lists them, srt sorts listings. Section 4 holds the
grammar the three agreed.

## 2 Intent verification

Each item states the ambiguity, the readings, and the ruling. V01 to
V09 were ruled on 20261114, before r0.7 was built. V10 was not ruled
on; it is built as proposed and stays open.

**V01 Global reverse.** The grammar model gives `-r` for all columns.
In ff `-r` is the ERE primary and takes an argument. Readings: (a) no
reverse-all in ff, only `-kNr`; (b) an uppercase option `-R` (srt's
`-R` randomizes); (c) move the regex primary to another letter.
DECIDED: (a). Full descent is written out, `-k5r,4r,6r,1r,2r`.

**V02 `-k list` as the next word.** r0.6 read only a joined value, so
in `ff -k 5` the `5` was a path. DECIDED: the cksh rule. The next word
is the list when it reads as one (a column number first, in the widest
sense srt gives a list, so a list ff refuses is reported as a list and
not walked as a path). `ff -k 5` sorts `.` by mdate; a directory named
`5` is written `./5`; `-k 7` is a usage error. `-k` may also end a
group of options, `-Sk5`. As built, one departure from cksh: a word
that begins with `-` is never the list, since `-0` and `-1` are
primaries in ff, so in `-k -1` the `-1` is false; joined, `-k-1` is
refused with the cksh wording.

**V03 Repeated `-k`.** r0.6: the last one wins. DECIDED: the cksh
rule. `-k5 -k4` is `-k5,4`; naming a column twice is an error.

**V04 Column 3 and letters.** r0.6: `-k3` kept walk order and held
nothing. DECIDED: the null column is a no-op sort, so `-k3` orders by
1,2,4,5,6. Letters, as ruled: on columns 1, 2, 4 and 5 `x` is valid
and means what the column already is, a number; columns 3 and 6 are
text; `r` reverses a column of either type; `-k-1` is refused. As
built, following cksh on the two cases the ruling leaves unstated: `x`
on column 3 or 6 is refused (tag 6ab7ff51), since `x` asks for a
number where the column is text, and any letter other than `r` and `x`
is refused (6ab7ff52), since the types are fixed. Letters combine in
either order, `-k5xr` and `-k5rx`.

**V05 Columns without `-v`.** A default print writes the name alone.
DECIDED: `-kN` sorts by columns that are not shown, as `ls -t` sorts
without `-l`. Column numbers always name the `-v` layout and every
record is keyed by its node's stat. The srt equivalence of section 4
item 5 holds for `-v` output.

**V06 `-Z` with `-v`.** r0.6: `-Z` ended only `-f` and default-print
names; `-v` lines kept the newline. DECIDED: `-Z`,
`--zero-terminated`, ends every record with NUL, with `-f` or not;
srt's `-Z` is NUL-terminated records in and out. As built, names are
written raw under `-Z`, to a terminal too, on `-v` lines as on names.

**V07 Hash notation.** ff computes no hash; column 3 is always a dot.
DECIDED: documentation only. Column 3 is described as the place of
cksh's shake256-N, shake256-6 by default, with no slash notation
anywhere. No hashing is added to ff.

**V08 `-V`.** In cksh and srt `-V` is the version; in ff it shows the
native find command. DECIDED: ff keeps `-V` and gains `--version`
only. `--man` and the formatter-driven `--help` follow cksh.

**V09 Function hand-over.** DECIDED: the function runs a binary named
ff on PATH, with `--fn` and `--bin` to allow only one form; `-V`
implies `--fn`, since only the function has a native command to show.
As built: an explicit `--bin` with `-V` reaches the binary, which
notes `-V` and runs; `--fn` with `--bin` is a usage error (6ab7ff55);
`--bin` with no binary is status 2 (6ab7ff56); the binary refuses
`--fn` (6ab7ff54) and accepts `--bin`. The words that choose the form
are options, so they are not seen where an option is not: as the
argument of a primary, among the words of an `-x` or `-j` command, or
after `--`.

**V10 Revision naming.** OPEN, built as proposed. The six dated
revisions are named r0.1 to r0.6 and this one r0.7; the r1 to r10
labels of PLAN.md stay in section 14 as that record's own numbering.
The alternative, r0.6 to match the cksh and srt archives, is a change
of label in the headers, `FF_REV`, the manual REVISION and the test of
`--version`.

## 3 Interface

`ff [-IHLDSXZV] [-k [col[r][,col[r]]...]] [--] [path ...] [expression]`,
`ff -h | --help | --man | --version`, `ff --fn ... | ff --bin ...`.

Options are uppercase letters, and `-k`, global, accepted anywhere
except as the argument of a primary. Primaries are lowercase letters,
the digits 0 and 1, or `-mode` and `-delete`. The option and primary
tables, with their rationale, are in section 14 (Grammar); `--help` is
the statement of the current implementation.

New or changed at r0.7:

| word | meaning |
|---|---|
| `-k [list]` | sort; list joined, the next word, or after a group (`-Sk5`); section 4 |
| `-Z`, `--zero-terminated` | every record ends in NUL; names raw |
| `--help` | on a terminal, a man page through mandoc, else nroff and a pager, else the pager, else plain |
| `--man` | the manual as man page source; `ff.1` |
| `--version` | `ff r0.7 6af927be`; the function adds `(bash function)` |
| `--fn`, `--bin` | allow only the function, only the binary |
| `-V` | unchanged; given to the function it keeps the function |

Retired at r0.7: `-krN` (write `-kNr`); the `--help` pager warning,
tag 6ab7ff4e.

## 4 Key grammar shared with srt and cksh

Settled first in srt (plan-srt.md, section 2), built in cksh
(plan-cksh.md, section 4), and stated for ff as the model of this
revision:

1. Columns are words in the awk sense, counted from 1; widths and
   padding are not significant, and blanks may be squeezed.
2. Sorting is asked for with `-k list`, `col[opts][,col[opts]]...`:
   the named columns in the order given, then the remaining columns
   left to right. Ties follow srt's order.
3. A bare `-k` names no column. That means sort by file name; in srt,
   by whole record.
4. Reverse is `-kNr` for one column or `-r` for all. `-krN` is not
   accepted.
5. ff knows column types, so `-k5,4,6` is `srt -k5x,4x,6,1x,2x,3` on
   their output: node, links, time, and size by hexadecimal value, the
   hash and name as text.
6. The name begins in column 6 with `-v` and runs to the end of the
   record.

As built in ff:

- Item 4 in part. `-kNr` reverses one column. There is no `-r` for
  all: `-r` is a primary (V01).
- Resolution. The comparison order is the named columns, then the
  columns not named, left to right, ascending. With a bare `-k` the
  name leads: 6, then 1 to 5. `-k5,4` is 5,4,1,2,3,6.
- Types. Columns 1, 2 and 4 compare as unsigned numbers and 5 as a
  signed number, by value at any width. Column 6 compares as bytes.
- Null column. Column 3 is a dot in every record and compares equal.
- Column 6 is the name as printed. On a `-v` line that is the path and
  its indicator, on a bare name the path alone. The two differ in
  order where a directory and a longer name share a prefix: `a/`
  sorts after `a b`, `a` before it. Keyed so, `ff -k ... -v` is what
  srt and cksh make of the same lines, and `ff -k` without `-v` is the
  bytewise order of the names shown.
- Stability. Walk order is the last comparison, so the unstable
  library sort cannot reorder equal records.
- Scope. Records from `-f`, `-v` and the default print are held until
  the walk ends; what `-x` and `-j` commands write is not sorted.

The srt equivalent of any ff list: the list, then the remaining
columns, `x` added to 1, 2, 4 and 5. The suite checks three such pairs
when srt is present, and two against `cksh -n0 -x0` when cksh is.

## 5 Output

The default print and `-f` write the path. `-v` writes the cksh line,
`inode links . size mdate name`, numbers in lowercase hexadecimal at
the least widths cksh uses (`%8jx %2jx . %8jx %08jx`), the name with an
indicator in the manner of `ls -F`. It is byte for byte what
`cksh -n0 -x0` writes for the same name. A time before 1970 is written
with a minus sign, `-12cff780` for 1960-01-01 UTC, as cksh writes it
and as `srt -x` reads it; r0.6 wrote the two's complement,
`ffffffffed300880`, which sorted after every later time.

Every record ends in newline, or under `-Z` in NUL. To a terminal,
and not under `-Z`, control bytes and invalid UTF-8 in a name are
written as `\ooo`.

## 6 Hash

ff reads no file and computes no hash. Column 3 is kept, as a dot, so
that the columns of ff and cksh agree: it is the column where cksh
writes shake256-N of the content, N hexadecimal characters,
shake256-6 by default. The name is written with a hyphen and never
with a slash, which is read three ways (bits, bytes, hexadecimal
characters); plan-cksh.md section 6 has the case. To add the hash to
what ff finds, `ff ... | cksh`.

## 7 Exit status and diagnostics

A bitmask: 1 usage, 2 environment, 4 node, 8 exec, 16 loop, 32 node
changed. 1 and 2 are fatal. Diagnostics are one line on standard
error, `>>> ff : what 'name'[: why] (tag)` for errors and `^^^` for
warnings; the tag names the message and is the same in the function.

Tags added at r0.7:

| tag | message |
|---|---|
| 6ab7ff4c | `-k requires columns 1-6, got` (the tag of r0.6's key error) |
| 6ab7ff4f | `-krN is not accepted, write -kNr; got -k` |
| 6ab7ff50 | `-k counts columns 1-6 from the left only, got` |
| 6ab7ff51 | `-k letter x is for the numeric columns 1 2 4 5; columns 3 and 6 are text, got` |
| 6ab7ff52 | `-k accepts the letters r and x only: column types are fixed, got` |
| 6ab7ff53 | `-k names a column twice, got` |
| 6ab7ff54 | `--fn allows only the bash function (ff.fn.bash); this is the binary` |
| 6ab7ff55 | `--fn and --bin cannot be combined` (function) |
| 6ab7ff56 | `--bin allows only the ff binary, and none is on PATH` (function, status 2) |
| 6ab7ff57 | `the function needs process substitution, which this bash lacks in POSIX mode (sh); use bash or the ff binary` (function, status 2) |

Retired: 6ab7ff4e, the pager that cannot run. `--help` now passes
over a formatter or pager that cannot run and tries the next.

## 8 Package files

- `ff.c` --- the binary; the usage and the manual are compiled in, the
  manual as chunks under the C99 literal limit. `--man` writes the man
  page source from the same text.
- `ff.fn.bash` --- one enclosing function `ff`: a pass over the words
  for `--fn`, `--bin` and `-V`, the hand-over, then the translator in
  a subshell. Its usage and manual blocks are copies of `./ff -h` and
  `./ff --help`; the suite fails if they drift.
- `makefile` --- targets `all ff man test install clean uninstall`;
  PREFIX is `/usr/local` for root and `$HOME` otherwise.
- `test-ff.sh` --- POSIX sh; section 9.
- `README.md` --- a general introduction.
- `plan-ff.md` --- this plan.

The manual follows the cksh model: body indented four blanks, a blank
line after each heading, example groups as sub-headings indented two
blanks with a blank line before each; sections NAME to REVISION with
KEYS, BASH FUNCTION, ENVIRONMENT and SEE ALSO `cksh(1), srt(1),
find(1)`; no HISTORY and no COPYRIGHT. The copyright stays in every
other file.

## 9 Verification

`make test` runs `test-ff.sh` beside `./ff`. Every behavior case runs
through the binary and then through the function, which is always
given `--fn`; a parity pass compares the two byte for byte.

Cases added at r0.7:

1. Key lists: named columns then the rest; `-k`, `-k6r`, two and three
   column lists, `r` and `x` in either order.
2. Remaining columns: `-k5` equals `-k5,1,2,4,6`.
3. Null column: `-k3` equals `-k1`; `-k3,5` equals `-k5`.
4. Repeated `-k` accumulates; a bare `-k` beside a list adds nothing.
5. The list as the next word, before paths and inside the expression;
   `-k` before a path, before a primary, before `-1`, and last;
   `-k 5`, `-k ./5`, `-k -- 5`.
6. `-k` ending a group: `-Sk`, `-Sk5,6`, `-Zk`.
7. Column 6 as printed: a directory and a longer name, bare and `-v`.
8. Rejects, each with status 1, and the six tags.
9. `-v`: six columns, the dot; `-Z -v` ends in NUL with no newline;
   `--zero-terminated`.
10. Signed mdate, where touch and the file system take 1960.
11. srt and cksh equivalence, where they are on PATH. Each is run as
    the file found there, never by name, so a function of that name
    exported into the shell is not what is tested.
12. `--help` on a terminal through stand-in formatters, each in a PATH
    of its own: mandoc first, nroff and the pager, the pager alone, a
    pager quit early, no pager at all.
13. Manual: the section list, SEE ALSO, no copyright in `-h`, `--help`
    or `--man`, shake256-6 named, no slash label, ASCII, 80 columns,
    a blank line before each example group; `--man` structure; `ff.1`
    equal to `--man`.
14. Form selection: hand-over, `--fn` first and last, `--bin`, `-V`
    alone and in a group, `--bin -V`, `--fn` as a primary's argument,
    as an `-x` word and after `--`, both together, `--bin` with no
    binary, the binary's `--fn` and `--bin`, `--version`, `--man`;
    the hand-over under bash in POSIX mode, and with and without a
    binary where process substitution is missing (`FF_NO_PROCSUB`
    stands in for a bash before 5.1).
15. Symlink policy in the function's records: `-H` on a link operand
    with `-v` and with `-k`, `-L` and `-H` on a dangling link.

## 10 Dependency posture

The binary needs C99 and libc, and nothing else at run time; the
directory walker is owned rather than fts(3); on Linux, user and group
names resolve through getent(1) at a fixed path. No setlocale() call
is made. Static on Linux and NetBSD; on Darwin the ceiling is dynamic
linkage against libSystem alone.

The function needs bash 4, the native find, stat(1) in the GNU or BSD
form, and for `-k` a sort with `-z` and `-s`. `--help` uses mandoc or
nroff when the host has one and a pager otherwise; none is required.

## 11 Revision sequence

    r0.1 6ab7fec8  r0.2 6ab89f43  r0.3 6abb42b9  r0.4 6abc5da8
    r0.5 6adcb748  r0.6 6ae4ea00  r0.7 6af927be

Named at r0.7 from the dated revisions (V10, open). Corrections to a
released revision fold into it without a new name, as in cksh and srt.
Breaking grammar changes are accepted until a stable release is
declared; from then backward compatibility is maintained.

## 12 Decision log

| item | decision | date |
|---|---|---|
| V01 | no global reverse in ff; `-kNr` only | 20261114 |
| V02 | `-k list` joined or the next word when it reads as a list; `-k` may end a group; a word beginning with `-` is never the list | 20261114 |
| V03 | repeated `-k` accumulate; a column named twice is an error; reverses r0.6, last wins | 20261114 |
| V04 | column 3 is a null column; `x` valid on 1 2 4 5; `r` on any column; `-k-1` refused; as built `x` on 3 or 6 and other letters refused | 20261114 |
| V05 | `-kN` sorts by columns not shown, as `ls -t` without `-l` | 20261114 |
| V06 | `-Z`, `--zero-terminated`: NUL ends every record, `-v` included; reverses r0.6 | 20261114 |
| V07 | hash notation in documentation only: shake256-N, shake256-6, no slash; ff does not hash | 20261114 |
| V08 | ff keeps `-V`; `--version`, `--man`; `--help` through a formatter | 20261114 |
| V09 | function hands over to a binary on PATH; `--fn`, `--bin`; `-V` implies `--fn` | 20261114 |
| V10 | r0.1-r0.6 named, this revision r0.7: built as proposed, not ruled | open |
| -- | uniform key grammar across srt, cksh, ff (section 4); `-krN` retired; duplicate detection is srt only; ff keeps `-0` and `-1` | 20261114 |
| -- | file names plan-ff.md, test-ff.sh, makefile, ff.fn.bash, ff.c, README.md; cksh and srt r0.6 as method reference and templates | 20261114 |
| -- | SEE ALSO srt and cksh in `--help` and the man page; no copyright there, kept in every other file | 20261114 |

## 13 Revision status

### r0.7 (6af927be, 20261114)

Built, against the rulings of section 2:

- `-k` takes a column list; resolution, types, the null column, column
  6 as printed and stability as section 4. The binary holds records
  with their stat keys and sorts once; the function orders them with
  `sort -z -s -t TAB`, one key per column in the resolved order,
  numeric keys `n`, no key for column 3, `r` on its own key.
- `-k` joined, as the next word, and ending a group (V02); repeated
  `-k` accumulate (V03).
- `-Z` on every record; `--zero-terminated` (V06).
- Signed mdate on the `-v` line, in the binary and the function.
- `--help` as a man page on a terminal; `--man`; `ff.1` from it;
  `--version`; `--fn`, `--bin` (V08, V09).
- Manual on the cksh model (section 8); usage rewritten.
- Function: one enclosing function with hand-over; the header moved
  out of the function body.
- makefile: one compile and link step, `man` and `uninstall` targets.

Defects corrected, found in the review of r0.6 and of this revision:

- A negative mdate printed as two's complement (section 5), so `-v`
  was not what `cksh -n0 -x0` writes and missorted under `srt -x`.
- Ties ran from the keyed column rightward only and never reached the
  columns on its left.
- The function sorted with the locale of the caller. Its helpers set
  `local LC_ALL=C`, which a child process does not inherit unless the
  variable is already exported, so under a caller's `LANG` the names
  of `-k` and of the emulated `-S` collated by locale where the binary
  compares bytes. Each `sort` now runs as `LC_ALL=C sort`.
- The function took the stat of `-v` and `-k` records without regard
  to `-H`: for a symlink named as a path operand it wrote the link's
  line where the binary writes the line of the file the link leads to.
  It now follows the link for an operand under `-H`, and under either
  option falls back to the link itself where it leads nowhere.
- `-Sk5`, a group ending in `-k`, was an unknown option.

Verified here (Linux, glibc 2.39, GNU find 4.9, bash 5.2, GNU make):
922 passed, 0 failed, 9 skipped as root; 926 passed, 0 failed, 7
skipped as an unprivileged user; srt r0.6 and cksh r0.6 on PATH for
the equivalence cases. gcc and clang compile without a warning under
`-std=c99 -Wall -Wextra -Wpedantic`. A gcc build under ASan and UBSan
ran the suite clean.

Darwin report (20261114, `make clean man test install`, first r0.7
build): 914 passed, 4 failed, 12 skipped. The binary pass, the bash
pass and parity were otherwise whole, the terminal `--help` cases and
the signed mdate included. The 4 failures were the two cksh
equivalence cases in each pass, and were the suite's, not ff's:

- The suite found cksh with `command -v` and called it by name. The
  operator's shell exports its functions, cksh among them, and
  `make test` runs the suite with sh, which on Darwin is bash 3.2 in
  POSIX mode: it imports exported functions and has no process
  substitution. So the name reached the cksh function, not the
  binary; its hand-over, `read -r b < <(type -P cksh)`, failed (the
  log's `<(type -P cksh): No such file or directory`), it carried on
  as the function, failed again at `<(uname -s)`, and stopped with
  status 2 and no output. The suite now looks srt and cksh up as
  executable files on PATH and runs those.
- The same construct stood in ff.fn.bash's own hand-over. It is now
  a command substitution, which POSIX mode has, so an ff function
  exported to an sh script still reaches the binary; where there is
  no binary and no process substitution the function stops with one
  message (6ab7ff57) and not a run of shell errors.
- Finding for cksh and srt, not changed here: cksh.fn.bash r0.6 has
  that hand-over, as the log shows; srt's passed in the same run.

The corrections were verified on Linux only: the suite under bash in
POSIX mode with functions named cksh and srt exported, 922 passed.
The Darwin rerun is pending.

Not verified here: NetBSD, bmake; mandoc and nroff themselves
(the suite uses stand-ins, and this host has neither); a locale other
than C, for the `LC_ALL=C sort` correction, which rests on the shell's
export rule and not on an observed misorder.

Open:

- V10, the revision name.
- The function's hand-over reaches whatever `ff` is first on PATH. An
  r0.6 binary there does not read the r0.7 list; `make install`
  replaces it, and `--fn` runs the function meanwhile.
- `-k 2024` before a directory named `2024` is a usage error, not a
  walk of that directory: the word reads as a list (V02). `./2024`.

### r0.6 (6ae4ea00, 20261030) and before

The record of r0.1 to r0.6 is section 14. Verified state as it stood:
r0.6 passed under GNU make on Linux, 742 cases as root and 746
non-root, with gcc and clang and under ASan, UBSan and LeakSanitizer.
On Darwin (arm64, Apple clang): r0.3 failed 4 of 325, two from `/tmp`
being a symlink to `/private/tmp` and two from BSD `-execdir` passing
bare names to the function, both answered in r0.4; r0.4 passed the
binary and parity passes, its bash pass failing 3 cases that are BSD
find differences, since probed and skipped; r0.5 passed whole, 694
cases, 12 skipped; a first build of r0.6 passed `make all test
install`, 735 cases, 12 skipped. Never run under bmake or on NetBSD.

## 14 History: PLAN.md, the design record of r0.1 to r0.6

Kept as written. Its revision labels r1 to r10 are its own; its `rev`
stamps are the dated revisions of section 11. Where it says `-k[r][N]`,
"the last one wins", `-k3` "passes walk order through", `-Z` for names
only, `--help` through `$PAGER`, test.sh or PLAN.md, sections 2 to 13
above supersede it.


### Context

`ff` is a short-switch find: NetBSD find(1) semantics where they matter, one
letter per switch, predictable on Linux and Darwin. The cksh project sets the
development model and solution profile, carried forward whole:

- one C99 binary, no dependency beyond libc, `-static` on Linux/NetBSD,
  libSystem-only on Darwin (cksh `makefile` link recipe, reused verbatim);
- one shell companion with byte-identical output and exit status, verified
  by a parity section in `test.sh`;
- `-h` short usage, `--help` full manual compiled in as chunked literals,
  man page derived from `--help` at build time (cksh `cksh.1` rule);
- exit status as an accumulating bitmask; one diagnostic path (`msg`/`die`),
  chkerr/chkwrn format with a hex tag per message;
- makefile restricted to the GNU make / bmake / Apple make intersection.

### Finding that reshapes the shell companion: Lua

Stock Lua (5.1--5.4) has no `readdir`, no `lstat`, no `fnmatch`, and no POSIX
regex; its patterns are not ERE, so `-E` cannot be honored in pure Lua. Every
filesystem call would route through `io.popen`/`os.execute`, which invoke
`sh -c` --- a quoting and injection surface, plus a fork per directory. With
the "no lua modules" rule in force (shell skill), luaposix/lfs are excluded,
and Lua is not installed on this host either. The intuition that Lua offers
better filesystem access holds only with modules.

Recommended companion instead: **`ff.fn.bash` as a translator**. It parses
the ff grammar, emits an argv *array* for the host's native find (never
`eval`, never a string), and runs it with `-print0` piped into a bash
post-filter only where the native dialect lacks a primary. The walk, lstat
and regex engine are then the kernel-adjacent native find, which is exactly
what the Lua walker would have been emulating through popen. Dialect probe
once per call: BSD (`find -E` accepted, NetBSD/Darwin) vs GNU (`-regextype`).

Decided r1: bash-translator. Lua dropped.

### Walker: owned, not fts(3)

fts is the high-frequency choice (every BSD find uses it) --- visibility bias
flagged. Against it here: musl ships no fts (static musl link fails), glibc
fts lacked LFS safety before 2.34, and fts's `FTS_NOCHDIR`/chdir modes give no
per-open race proof. nftw has no subtree prune in POSIX. Owned walker:

- `openat(parent, name, O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC)` then
  `fstat` and compare `st_dev/st_ino` with the `fstatat(...AT_SYMLINK_NOFOLLOW)`
  taken while listing; mismatch = swapped under us, warn, skip (bit 32).
- `fdopendir` + `readdir`; `d_type` as a hint only, `DT_UNKNOWN` (xfs, nfs,
  some fuse) falls back to `fstatat`. `lstat` skipped entirely when no
  predicate needs it and `d_type` suffices (speed parity with find).
- fd budget: keep the dirfd chain open to a cap (64), beyond it reopen from
  the nearest held ancestor component-by-component with `O_NOFOLLOW`; paths
  built in a growable buffer, never `PATH_MAX`.
- `-L`: ancestor `dev/ino` stack for cycle detection (bit 16); `-H` follows
  only command-line operands.
- `-D` post-order, `-S` lexicographic (`strcmp`, bytewise, like `LC_ALL=C`).

### Grammar (draft letters --- expect revision)

Positional like find: `ff [options] [path...] [expression]`; default path `.`,
default action print. Options are uppercase letters, primaries lowercase
letters or the digits 0 and 1 (r8), so the two sets never collide. The
tables below carry the current letters; the decisions log records each
change.

Options (before paths)

| ff | NetBSD find | note |
|----|-------------|------|
| ~~-E~~ | -E | retired r10: `-r` is always ERE; `-E` is an unknown option |
| -I | (-iname/-iregex) | case-insensitive for every `-n -p -r` |
| -H / -L | -H / -L | symlink policy; -P default |
| -D | -d | depth-first (post-order) |
| -S | -s | sorted traversal |
| -X | -x / -xdev | stay on one filesystem |
| -Z | -print0 | NUL-terminated output (r8; was -0) |
| -h / --help | | usage / manual; `--help` through `$PAGER` on a tty (r10) |

Primaries (after paths); `!` not, `-o` or, juxtaposition and, `(` `)` group

| ff | find | semantics |
|----|------|-----------|
| -n glob | -name | fnmatch on basename, no FNM_PERIOD |
| -p glob | -path | fnmatch on whole path |
| -r ere | -E -regex | regexec on whole path; **unanchored** (grep-like, add `^$`); decided r1, documented deviation; always ERE (r10) |
| -t fdlpsbc | -type | multiple letters = or: `-t fl` |
| -d [+-]N | -depth n / min/maxdepth | walker bound: `-d -3` prunes below depth 3 |
| -s [+-]N[ckMG] | -size | bytes default; decided r1 |
| -m -a -c -b [+-]N[smhdw] | -mtime/-atime/-ctime/-Btime | units as Darwin/FreeBSD; days default |
| -w [+-][ ]([.][.]/file\|HEX) | -newer | when: after, before or at (r6); the sign may stand apart (r8) |
| -y file | -samefile | same device and inode (r8; was -same, r6) |
| -0 / -1 | -true / -false | true, false (r8; were -true -false, r6) |
| -k mode | -perm | octal or symbolic, `-`/`+` prefixes as find |
| -u -g name/id | -user -group | |
| -e | -empty | |
| -l [+-]N | -links | |
| -i N | -inum | |
| -z | -prune | |
| -x cmd {} ; / + | -execdir | argv exec in the entry's directory, never a shell |
| -j cmd {} ; / + | -exec | plain exec from ff's cwd, full path in `{}`; race-exposed, documented as such (r2) |
| -delete | -delete | a long switch to confirm; see below |
| -q | -exit/-quit | stop walk |
| -v | -ls | cksh-shape line: hex fields, awk-sortable |

`-delete` (r2): spelled in full rather than a single letter so a
one-keystroke typo cannot destroy data.
Implies `-D` post-order, as find does. Removal is `unlinkat(dirfd, name,
0 | AT_REMOVEDIR)` against the already-verified parent dirfd --- the same
race closure as `-x`: no path is re-resolved. An operand ending in `..`, or
the root directory by device and inode, is refused whole, not walked, bit 4
(r8; before, only the node was refused and its contents were still
deleted); `.` is walked and kept, as find does; non-empty dir failure = bit
4, walk continues. The bash translator maps it to native `-delete` (both
dialects have it) after refusing the same operands itself.

Excluded phase 1: `-ok`, `-fprint`, `-printf` (GNU only anyway), `-flags`,
`-fstype`.

### Security posture

- exec: `fork`+`execvp` on an argv array, `{}` as whole-argument substitution
  only; `+` batches sized against `sysconf(_SC_ARG_MAX)` minus environ;
  execdir semantics (`./name` in the opened dirfd via `fchdir` in the child)
  closes the path-swap race that plain `-exec` has.
- output (decided r1): raw bytes (as find) under `-Z` or when stdout is not a
  tty; on a tty escape control characters (C0, DEL, and C1 as bytes
  0x80-0x9f only when not part of valid UTF-8) as `\ooo` to block terminal
  injection. Test: fixture name with ESC, compare tty (via `script`) vs pipe.
- exec `PATH` guard: `-x` refuses to run when `PATH` holds an empty or
  relative element (as GNU does for `-execdir`), since the child's cwd is
  the walked directory and a planted `./ls` would otherwise execute.
- regex: compiled once; BRE back-references can go exponential in glibc ---
  documented, not guarded. Glob via `fnmatch`; `FNM_CASEFOLD` needs
  `_GNU_SOURCE`/`_DARWIN_C_SOURCE`/`_NETBSD_SOURCE` (all three supply it, musl
  too).
- inputs: every numeric argument range-checked (`num()` pattern from cksh.c
  527), unknown switch = status 1 before any walk.

### Exit status bitmask

| bit | meaning |
|----:|---------|
| 1 | invalid option or expression |
| 2 | environment: memory, stdout failure, fd exhaustion |
| 4 | cannot stat or open a node; subtree skipped |
| 8 | exec child failed or returned nonzero |
| 16 | symlink cycle under -L |
| 32 | node changed during walk (dev/ino mismatch) |

### Darwin variations to weigh

- **Birth time**: `st_birthtimespec` (Darwin, NetBSD); Linux needs `statx`
  (glibc 2.28, musl 1.2.5) and some fs return none --- `-b` fails soft there.
- **Timespec names**: `st_mtim` (Linux, NetBSD alias) vs `st_mtimespec`
  (Darwin); one accessor macro chosen by makefile `uname` case, cksh style.
- **Case-insensitive APFS default**: `-n foo` misses `Foo` the filesystem
  itself would open; `-I` exists for this.
- **Unicode normalization**: HFS+ stores NFD, APFS preserves input form;
  precomposed pattern vs decomposed name fails to match. Documented, not
  normalized (normalizing needs tables --- a candidate owned table later).
- **Firmlinks / sealed system volume**: `/` and `/System/Volumes/Data`
  differ in `st_dev`; `-X` from `/` stops at the data volume.
- **SIP/TCC**: EPERM on `~/Library/Mail` etc. even as root --- bit 4, keep
  walking, one warning per subtree.
- **Dataless files** (iCloud, `SF_DATALESS`): opening triggers download;
  ff never opens regular files (only `-e` on dirs, `-x` children).
- **BSD flags / xattrs / ACLs** (`UF_HIDDEN`, `com.apple.quarantine`): not
  phase 1; candidate `-f flag` later.
- **Regex**: Darwin `REG_ENHANCED` avoided for parity; plain POSIX only,
  `REG_EXTENDED` since r10.
- **Linking**: no static libSystem; stated in README, as cksh does.
- **Native find for the bash companion**: Darwin find is FreeBSD-derived
  (`-E`, `-depth n`, time units, `-Bmin`) while NetBSD lacks some of these;
  translator keys on feature probes, not `uname`.

### Files

- `ff.c` --- walker, expression parser (recursive descent to a node array,
  no recursion in evaluation hot path), predicates, exec, help literals.
- `ff.fn.bash` --- translator companion.
- `makefile` --- cksh makefile with names changed.
- `test.sh` --- POSIX sh; fixture tree (dotfiles, spaces, newline in name,
  fifo, socket, dangling and looping symlinks, deep tree over fd cap,
  unreadable dir when non-root); cases: each primary vs native find output
  (`LC_ALL=C sort`ed), exit bits, grammar rejects, parity C vs bash,
  `--help` sections, race case (dir swapped for symlink mid-walk via a
  `-x` hook).
- `README.md`, `.gitignore`.

### Phases

1. `--help` manual text first --- the grammar's source of truth.
2. Walker + `-n -p -r -t -d -z`, `-E -I -H -L -D -S -X -Z`, print.
3. `-s -m -a -c -b -w -k -u -g -e -l -i`.
4. `-x` and `-j` (`;` and `+`), `-delete`, `-q`, `-v`.
5. bash translator + parity section.
6. Darwin extras after first Darwin run.

### Verification

`make && make test` under GNU make (gcc, clang, `-fsanitize=address,undefined`,
root and non-root) on Linux here; `bmake` if installable; Darwin and NetBSD
runs by you --- the README states which were actually exercised, as cksh does.

### Implementation record (r3, first build)

Where the build departs from or fills a gap in the plan above:

- `-f` added as an explicit print primary. The plan left no print primary,
  so find's `-prune -o -print` idiom had no ff spelling. `-z` keeps find
  semantics (true).
- Timespec access uses `#ifdef __APPLE__` in ff.c, not a makefile branch.
- Evaluation recurses over the expression tree. The plan said it would not,
  but the recursion depth is bounded by the expression, not the tree.
- A directory closing a loop is skipped without being tested, as find does
  (fts `FTS_DC`).
- A `;`-form command that exits nonzero is only false. Bit 8 is set for
  exec failure and for nonzero `+` batches, as in find.
- The descriptor window is `min(64, RLIMIT_NOFILE/2 - 8)`.
- The bash translator exits 2 where the native find cannot express a
  request (see README), and it collapses native failures to 4.
- Options are accepted anywhere, not only before paths; they are global.

### Decisions log

- r1: bash translator; `-r` unanchored; `-s` bytes; tty escaping on;
  letters accepted; delete retained.
- r2: delete spelled `-delete` (not `-rm`); `-j` added as plain `-exec`
  beside `-x` (execdir). `-j` skips the relative-PATH guard (cwd is ff's own,
  as with find `-exec`); `+` batches across directories. Test: `-j` and `-x`
  yield the same file set, `{}` forms differ (`./a/b` vs `./b`).
- r3: `-f` confirmed as print. `-u`/`-g` names on Linux resolve through
  `getent` at a fixed path (passwd/group database as the host configures
  it); `getpwnam` is no longer linked there, so the static-NSS link
  warning is gone. `/etc/passwd` is never parsed: it is not authoritative
  under LDAP, sssd or systemd-homed. No getent: status 2, numeric ids work.
  Darwin and NetBSD keep libc `getpwnam`/`getgrnam`.
- r4: cksh conventions adopted. The `org` revision is reset to 6ab7fec8
  (20260926 102008 PDT) in every header, the manual HISTORY and README
  History; the earlier 6ab77d4a stamps are dropped. Diagnostics use the
  chkerr (`>>> `) and chkwrn (`^^^ `) format, `ff : what 'name'[: why]
  (tag)`, one line, with hex tags 6ab7ff01-6ab7ff45; usage messages and
  tags are identical in ff.fn.bash. The bash function body is a subshell,
  so only `ff` enters the caller's namespace. The manual gains HISTORY and
  COPYRIGHT. `make install` defaults PREFIX to /usr/local for root, else
  $HOME. `warned_btime` is declared only where -b can warn (unused-variable
  warning on Darwin and NetBSD).
- r5: `-k` is a permission query, not find's chmod arithmetic (`-k u+x`
  had meant "mode is exactly 0100"). Octal: bare exact, `+mode` at least
  (superset), `-mode` at most (subset), following ff's +N more / -N less;
  find's any-bit form is dropped. Symbolic: `[ugoa][+-][rwxXst]` clauses
  joined by commas, all required; `+` has, `-` lacks, bare means `+`; no
  `=`. Named classes each satisfy; no class means some class for `+`,
  none for `-`. `s` setuid/setgid, `t` sticky, `X` directory-only
  execute; `o+s`, `u+t`, `g+t` rejected (tag 6ab7ff46). `-not` spells
  `!`. The manual's OPERATORS gains shell-quoting guidance and a
  two-directory prune example. ff.fn.bash writes every clause with plain
  `-perm -BITS`, "lacks" as one `! -perm -BIT` per bit, so no dialect
  split. Review follow-up in the same rev: `-k +rs` holding through the
  other class (which holds no s) is documented; diagnostics that state a
  rule end in ", not" (or "after", "in", "of") before the quoted value,
  and the time rule names its primary (`-m: time is ...`); copyright
  and license added to README and PLAN.
- r6 (rev 6abb34a2): `-w` is "when", `[+-](file|HEX)`: after, before or
  at a file's mtime (full timestamp) or a hex epoch second (whole
  seconds, the `-v` mdate); hex digits are a time, else a file, `./`
  for names that look like either; bare `-w file` (was newer) is now
  "at", newer is `-w +file`. `-same file` (find `-samefile`; translator
  falls back to `-inum` from `stat` where missing, e.g. NetBSD). `-true`,
  `-false`. `-i` reads hex, as `-v` prints the inode. `-V`: ff.fn.bash
  prints the native command to stderr; the binary accepts it and notes
  where it lives (tag 6ab7ff47), decided against a second translator in
  C. Manual: `-n`/`-p` in find's words (no code change; semantics
  already match find `-name`/`-path`), `[+-]N`/`[+-]HEX` shown for `-l`
  and `-i`, new prune example, grouped EXAMPLES each run on a scratch
  tree.
- r7 (squashed into rev 6abb42b9 with r6; 6abb34a2 retired): first Darwin
  `make test` showed 26 failures, none in the walker. test.sh now keeps
  only absolute PATH elements (the user's disabled `x/Library/TeX/texbin`
  entry is deliberate; `-x` still refuses it interactively, by design),
  runs in UTC, chgrps the setgid fixture and skips it where still not
  permitted, runs bash under `env -i`, filters loop entries BSD find
  tests but GNU find and ff skip, and drives BSD `script`. Tests use
  whole seconds only. `-w` files must begin with `./ ../ /` (tag
  6ab7ff4b), so no word is both a file and a HEX time. ff.fn.bash writes
  `-w` with reference files (`touch -d ...Z`, `-newer`) where the native
  find lacks `-newermt @` (hook `FF_NO_NEWERMT` tests it on GNU).
- r8 (rev 6abc5da8): `-0` and `-1` replace `-true` and `-false`, read
  as true and false; NUL output moves from `-0` to `-Z`, so every
  option is an uppercase letter and primaries are lowercase letters or
  the two digits. `-Z` was chosen over a positional `-0` (NUL before the
  expression, true inside it): options are accepted anywhere, so a
  position-dependent `-0` would change meaning silently when moved,
  while the old `ff -0 . ...` now fails loudly (`-0` starts the
  expression, and the path is an unexpected word). `-y` replaces
  `-same`, so `-delete` is the one long primary left, now described
  as "a long switch to confirm". `-w [+-][ ]([.][.]/file|HEX)`: a lone
  `+` or `-` word takes the next word, kept whole by the pre-pass; that
  word may carry no sign of its own, and diagnostics name it. The first
  Darwin run of rev 6abb42b9 (4 of 325 failed) is answered: test.sh
  works in `pwd -P`, since Darwin's `/tmp` is `/private/tmp` and `-x pwd`
  prints the physical path; BSD `-execdir` passes a bare name where GNU
  and ff.c pass `./name`, so ff.fn.bash probes this once per call and,
  for bare names, runs `-x` through a fixed `/bin/sh -c` script that
  prefixes `./` to `{}` names (a mask argument marks them) and to every
  `+` name, the command words passed as arguments and never evaluated,
  ending in `exec`. `FF_BARE_EXECDIR` forces the wrapper for tests on
  GNU; ff.fn.bash `-h`/`--help` heredocs are generated from the binary.
  Review follow-up in the same rev: the file form is written
  `[.][.]/file`, which names exactly the three accepted prefixes `/`
  `./` `../` (the earlier `[.]./file` missed `/file`), in every header,
  usage, manual and history line; diagnostic 6ab7ff4b states the same
  form. Usage shows `-0 (true)  -1 (false)`.
  Second follow-up in the same rev: `make test` runs every behavior case
  through both implementations (`cases` with `RUN` set to the binary,
  then to a clean-bash wrapper for the function), then the byte-for-byte
  parity pass, each with its own tally; `bo "reason"` marks the groups
  only the binary can meet, one named skip each in the bash pass. Each
  group was confirmed to fail under bash before being marked; three cases
  first assumed binary-only (race not followed, the low descriptor limit,
  `-e` at depth 90) pass under the native find and run in both. The
  doubled pass exposed two function defects, now fixed: options after a
  primary were ignored (`-n '*.c' -I`, `-r 'a|b' -E`), since translation
  was one pass, so ff.fn.bash now sets options first, as ff.c's pre-pass
  does; and a bad `-r` failed at walk time with status 4, so the native
  find now compiles it first and a bad one is usage status 1, tag
  6ab7ff09, without the reason only the binary adds.
  Darwin run of the two-pass suite: the binary and parity passes clean,
  the `./` wrapper confirmed on real BSD `-execdir`. The bash pass failed
  3 cases, each BSD find itself, not the translator: `-delete ..` silent
  with status 0 (ff refuses, 4; nothing deleted either way); `-L` tests a
  directory closing a loop (r7 had filtered this in parity only); an
  unreadable directory operand is not tested. Decided: pass them through,
  not emulate, since each emulation would re-walk or re-evaluate the
  expression beside the native find and none could be verified here. A
  fourth, `-delete` of a non-empty directory (FreeBSD ignores ENOTEMPTY),
  is added as a case. test.sh `nd "reason" probe` skips a case in the
  bash pass only when a probe of the host's find shows the difference;
  probes test behavior, never `uname`, so a host that changes runs the
  case again. Noted, unchanged: refusing `..` or `/` spares only that
  node; its contents are deleted in post-order, as find does.
  Refusal covers the whole operand (same rev, on review): with -delete
  in the expression, an operand whose last component is `..`, or that
  is the root directory by device and inode (`/ // /. /usr/..`, `.`
  run from `/`, under `-H` a symlink to `/`), is refused before any walk
  below it, tag 6ab7ff37, bit 4; other operands proceed. Identity rather
  than spelling, since `/.` and `.` from `/` name the root without
  saying so. find and the earlier ff refused only the node and emptied
  it in post-order. The refusal holds whether or not the expression
  would reach -delete on that operand: the check is on the operand, not
  the node. ff.fn.bash refuses the same operands before the native find
  runs (`-ef /`, skipped for a symlink operand without -H), so the BSD
  `..` difference above no longer reaches the native find and its probe
  is retired. Tests carry `-d 0` on every root case, so a broken refusal
  could only attempt rmdir on `/`.
- r9 (rev 6adcb748): `-mode` and `-k[r][N]`. The permission query
  moves from `-k` to `-mode`, a long primary like `-delete`, semantics
  unchanged; messages read `-mode: ...` under the same tags (6ab7ff11,
  6ab7ff46). `-k[r][N]` sorts printed records by cksh field N, as `-v`
  lays it out: 1 inode, 2 links, 3 hash, 4 size, 5 mdate, 6 name; bare
  `-k` is 6, `r` reverses. It is global like the options, the last one
  wins, and N is attached, so in `-k 5` the 5 is a word, not N; `-k0`,
  `-k7`, `-kx` are usage errors (tag 6ab7ff4c). Every record (`-f`,
  `-v`, default print) is keyed by its node's stat, so `-v` is not
  needed to sort by mtime or size. Values compare numerically (mdate
  signed), names bytewise; ties go to the following fields, then walk
  order. Records are held until the walk ends, terminators kept;
  `-x`/`-j` output is not sorted. The hash is always `.`, so `-k3`
  passes walk order through with nothing held. Methods: ff.c passes
  output through one writer that can hold records, each carrying its
  stat keys and walk sequence, sorted and written once the walk ends;
  ff.fn.bash stats each record from the native find into decimal keys
  and orders them with `sort -z -s -t TAB`, each key carrying its own
  `n` and `r`; a sort without `-z -s` exits 2 (tag 6ab7ff4d).
- r10 (rev 6ae4ea00): regular expressions, help paging, hygiene.
  Requirement: `-r` is always ERE; `-n` and `-p` stay glob; `-I` makes
  all three case-insensitive (it already did: `FNM_CASEFOLD`, `REG_ICASE`,
  find `-iname -ipath -iregex`; the usage line now names them). Reverses
  r1, which kept find's BRE default with `-E` to choose ERE. Factors: one
  regex dialect is one thing to learn, and ERE is the dialect of
  `grep -E`, `find -E` and most current tools; a choice between dialects
  served compatibility with find, which ff's one-letter grammar does not
  keep elsewhere. ff.c compiles every `-r` with `REG_EXTENDED`;
  ff.fn.bash always gives BSD find `-E` and GNU find `-regextype
  posix-extended` and wraps the pattern `.*(re).*`, so the BRE path that
  stripped `^` and `$` is gone, and back-references are refused (2, tag
  6ab7ff40) on every `-r`, since the wrapping group renumbers them.
  `-E` fails loudly, as `-0` did at r8: an unknown option (1, tag
  6ab7ff01) before the expression, an unknown primary (6ab7ff03) inside
  it, `-IE` unknown whole. A silent no-op was declined: it would let a
  reader believe `-E` still chose something. No other switch reads
  regex, so `-E` reaches nothing else; the native `-E` that `-V` shows on
  BSD is find's. Factors weighed and accepted: a BRE pattern carried
  over changes meaning without an error (`( ) { } + ? |` operators,
  `\( \) \{` literal), some become errors (`a{`, a leading `*`), and
  ERE leaves back-references, empty alternatives and escapes such as
  `\d` to the C library, so what compiles is less uniform across glibc,
  Darwin and NetBSD than under BRE; documented, not guarded.
  Requirement: the manual describes the current implementation; the
  rationale and the history of a decision live here. So `--help` gains a
  REGULAR EXPRESSIONS section (the ERE syntax, the escapes POSIX
  defines, `.` matching `/`, bracket rules, classes, a BRE difference
  table, glob contrasted, three examples) and its HISTORY lines stay
  one-line summaries. Escapes are documented as POSIX defines them,
  `\` before `. [ ( ) { * + ? | ^ $ \`, with `]` and `}` alone already
  literal; the test that used `\}` now uses `a\{2}`.
  Requirement: `--help` runs through `$PAGER`, `more` when unset or
  empty (POSIX man's default), when stdout is a terminal; `-h` is one
  screen and is not paged. Factors: PAGER is the user's configuration,
  commonly with arguments (`less -R`), which an argv split could not
  honor, so it runs by `/bin/sh -c` (popen in ff.c), as man(1) runs it;
  `-x`/`-j` words still never meet a shell. SIGPIPE is ignored in ff.c,
  so a pager quit early ends quietly with status 0. A pager that cannot
  run (126, 127) is warned of (`^^^`, tag 6ab7ff4e) and the manual
  written directly, so `--help` never shows nothing.
  Hygiene: LeakSanitizer reported one allocation, `main`'s `paths`
  array, whenever `bad()` or `die()` exited from inside the parser with
  the pointer held only in a register: argc words, once per run, freed by
  exit, never proportional to the walk. It moves to file scope beside
  `tok`, so it stays reachable; `make test` under ASan, UBSan and LSan is
  now clean with leak detection on, where before 132 cases failed on the
  sanitizer's exit status. ff.fn.bash follows the shell standard for
  here-documents: `__FF_USAGE__` and `__FF_MANUAL__`, quoted, read with
  `IFS= read -r -d ''` and printed with `printf '%s'`, no `<<-` tabs;
  test.sh's wrapper uses `__FFT_WRAPPER__`, and a parity case checks each
  delimiter is quoted and occurs once as a line. The help blocks are
  copied from the binary's `-h` and `--help`; the makefile does not
  regenerate them, and README no longer says it does.
  Tests: fixtures `rx/` (`aab ab a+b a(b) a{2}b`) separate the ERE and
  BRE readings in both passes and parity, with `-I -p`, `.` across `/`,
  and the `-E` retirements; the pager runs under script(1) with
  `PAGER='wc -l'`, `head -1` and a missing path, and the clean-environment
  wrappers pass `PAGER`. A first build of this rev, before the manual
  section, the leak fix and the delimiters, passed on Darwin (735, 0
  failed, 12 skipped); the final run of this rev is to follow.

### Compatibility

Stated requirement (r10): the grammar is still settling toward a stable
requirement set and build, and incompatible changes are accepted until
then: `-k` to `-mode` (r9), `-0` to `-Z` (r8), BRE to ERE and `-E`
retired (r10). Once the stable release is declared, backward
compatibility is maintained. The changes so far mostly fail loudly: `-E`
and `-0` before a path are usage errors (status 1), and an old `-k`
mode argument is now read as a path that cannot be stat'ed (status 4).
The BRE-to-ERE change is the one that can change meaning without any
error, which is why the manual's REGULAR EXPRESSIONS section carries the
BRE difference table.
