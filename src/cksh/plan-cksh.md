# cksh plan

cksh: a sortable stat and SHAKE256 listing of files. One interface on
Linux, Darwin and NetBSD, delivered as C99 source (`cksh.c`) and a
bash function (`cksh.fn.bash`).

This plan drives the package revisions. It was opened at r0.6, when
the package took the shape of srt's: before that the requirements
lived in the README and in the file headers, and they are merged here.
Items marked **V** (section 2) began as ambiguities with a proposed
default; nothing downstream of an unconfirmed V item was built until
it was ruled on. Decisions are recorded in section 12, the affected
sections state the decision in place, and section 13 holds the status
of each revision as built. Where a decision reverses an earlier one,
both are stated.

    revision 6af8d530 20261114 134000 PST Sat --- r0.6: plan opened from README and headers; V01-V21 ruled and built; three Darwin reports folded in; PREFIX as r0.5; -Z, -L, -o, -c, --man; key grammar shared with srt and ff; r0.1-r0.5 named
    original 6af8d530 20261114 134000 PST Sat --- initial plan, written with r0.6

_(c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

<!--contents 2 3 pre="## Contents" post="---"-->

## 1 Purpose and scope

cksh writes one line per file: inode, links, hash, size, modification
time, name. The numbers are hexadecimal and the name is last, so the
listing can be sorted by any column, compared between two trees, and
joined. It answers the operator's questions about a set of files ---
which changed, which are the same content, which are newest or largest
--- with one line format that every other tool can read.

In scope: the six columns; column omission; a hash of chosen length;
sorting by column with the key grammar of srt; names from arguments or
standard input; following symlinks; output renamed into place; a saved
listing checked against its files; a bash function with the same bytes.

Out of scope, by requirement: duplicate detection (that is `srt -D`
on cksh output); walking a tree (that is ff); any column beyond the
six; any hash other than SHAKE256; locale collation.

cksh is one of three tools that share a record and a key grammar: ff
finds files, cksh lists them, srt sorts listings. Section 4 holds the
grammar the three agreed.

## 2 Intent verification

Each item states the ambiguity, the readings, and the ruling. All
were ruled on 20261114, before r0.6 was built.

**V01 Unit of `-x`.** The request said cksh "counts hex characters";
r0.5 `-x` counted bytes (`-x 3` gave six digits). Readings: (a) keep
bytes, change only the label; (b) `-x` counts hexadecimal characters.
DECIDED: (b). Range 0-128, default 6, odd lengths allowed. The option,
the label and the width of column 3 are one number. Backward
compatibility is dropped: an r0.5 `-x 32` is now `-x 64`.

**V02 Bare `-n` and `-x` before a file.** r0.5 failed on `cksh -n a`
("requires 0-5, got 'a'"). Readings: (a) the rule srt uses for `-k`:
the next word is the value only when it reads as one; (b) joined
values only. DECIDED: (a). `cksh -n file` is `-n0`, `cksh -x file` is
`-x0`. Consequence, accepted: a first file named with digits is taken
as the value (`cksh -n *` where `5` exists); `./5` or `--` avoids it.

**V03 The srt equivalent of a cksh key.** The request wrote
`srt -k1x,2x,3,5x,4x,6` for `cksh -k5,4,6`, which sorts by inode
first. DECIDED: the intent is `cksh -k5,4,6` = `srt -k5x,4x,6,1x,2x,3`
on the same output: the cksh list, then the remaining columns, with x
on the numeric ones.

**V04 Letters in a cksh key.** DECIDED: `r` acts. `x` is accepted on
columns 1, 2, 4, 5 and changes nothing. Every other letter is refused
with status 1, since a silently ignored `-k4n` would mislead; `x` on
the text columns 3 and 6 is refused for the same reason. `-k5 -k3`
equals `-k5,3`. A column named twice is an error. `-k-1` is refused.

**V05 A key on an omitted column.** Readings: (a) usage error; (b)
sort by the true value though it is not shown; (c) the dot is a null
column. Proposed: (a). DECIDED: (c). An omitted column compares equal
in every record, as its dot would in srt; the key orders nothing and
the next column decides. The srt equivalence of V03 holds exactly.

**V06 `-r` with no `-k`.** Readings: (a) by name, descending, as srt
reverses whole records; (b) reverse input order, as r0.5. Proposed:
(a). DECIDED: (b). `-r` alone writes the lines in reverse input order.
With `-k`, `-r` reverses every column written without a letter.

**V07 Negative mdate.** r0.5 wrote a 1960 time as
`ffffffffed307900`, which `srt -k5x` places after every modern date.
DECIDED: signed hexadecimal, `-12cf8700`, which srt's `-x` orders
before zero.

**V08 Function form.** r0.5 `cksh.fn.bash` was a full implementation
that never handed over. DECIDED: the srt model. The function runs a
binary named cksh when one is on PATH; `--fn` allows only the
function, `--bin` only the binary; `-V` and `--version` print the
revision.

**V09 Packaging and revision names.** DECIDED: the prior revisions
recorded in `cksh.c` become the minor releases r0.1 to r0.5, the
original 6305e87b being r0.1 and 6ab7e734 r0.5; these rounds are r0.6.
The archive is `cksh-r0.6.tgz`. `test.sh` becomes `test-cksh.sh`.
Makefile targets `all cksh man test install clean uninstall`.
`PREFIX`, when not given, is `/usr/local` for root and `$HOME` for
anyone else, as in r0.5. (The first build of r0.6 defaulted to
`/usr/local` for every user, after srt; that was ruled a mistake the
same day, to be corrected in srt as well, and is reversed here.)

**V10 History.** DECIDED: it leaves `--help` and the README and lives
here (section 14). The manual ends with SEE ALSO and a one-line
REVISION, as srt's does.

**V11 Manual layout.** DECIDED: the srt model, with one difference:
a blank line precedes every sub-heading of EXAMPLES, in `--help` and
in `cksh.1`, where srt omits it. The man recipe otherwise follows
srt's: blank lines inside a section are kept, a leading `.` or `'` is
guarded, a backslash is written `\e`.

**V12 Hash label.** DECIDED: `shake256-N`, N in hexadecimal
characters; no slash notation as a label in any file. `--help` sets
out the three readings of a slash once, in HASH: `SHAKE256/24` bits,
`SHAKE256/3` bytes, `SHAKE256/6` hexadecimal characters.

**V13 Copyright.** DECIDED: removed from `--help`, `-h` and the man
page; kept in every other file.

**V14 Names on a terminal.** r0.5 wrote names as they are, where ff
escapes them. DECIDED: escape. When the stream is a terminal, C0 and
C1 control characters, DEL, and bytes that are not valid UTF-8 are
written `\ooo`; to a pipe or file, names are written as they are.
Diagnostics follow the same rule by standard error.

**V15 `cksh d/`.** r0.5 wrote `d//`, as `ls -dF` does. DECIDED: `d/`.
A directory named with a trailing slash keeps the one.

**V16 Defects of r0.5.** DECIDED: corrected as described in section
13: exit status wording; unknown platform in the function; node
identity after open; man recipe; function style. An empty argument
stays skipped, and is documented.

**V17 `-Z`.** Asked for after the first build, in the words of ff:
end names with NUL, not newline. Readings for cksh, which also reads
names: (a) output only; (b) output and the names on standard input,
as `-z` is in srt. DECIDED AS BUILT, open to correction: (b), and,
as in ff, names are written as they are under `-Z` even to a terminal.
The three tools then pass any name: `ff -Z | cksh -Z | srt -z`. The
letter is `-Z` in ff and cksh and `-z` in srt; that difference stands
until one of the plans rules on it.

**V18 `-c listing`.** Proposed by the plan's author when asked what
else belonged, and directed. Read a saved listing back and report the
files that no longer match. Points settled in the build, open to
correction:
- Output is the current line of each file that differs, and status 64;
  a matching file writes nothing. The output is thus a listing, and
  `-k`, `-r`, `-o` apply to it. (`-c` in srt means "check order";
  here it means "check a listing". Both exit nonzero on a finding.)
- Each record is checked as it was made: dots are columns not
  compared; the width of the hash names shake256-N; `-n` and `-x` are
  not consulted.
- The file of a record is its name less the indicator, or the name
  itself where a file of that very name gives the record's name back.
- Exactly one blank is skipped before the name, so a leading blank in
  a name survives; this is the one place where a blank is significant.
- A record of fewer than six words is fatal, status 1. A file that is
  gone is status 4. A listing that cannot be read is status 2.
- No file operand with `-c`; `-` is standard input.

**V19 `-L`.** Directed. Follow symlinks: every column and the
indicator are those of the file a link leads to, under the name given.
A link that leads nowhere is listed as the link, with `@`, and warned
when hashed (status 32), with `-L` as without.

**V20 `-o output`.** Directed. A temporary sibling of the destination
(`.cksh.XXXXXX`), synced, given the destination's mode or the mode a
new file would get, renamed when the run is complete. Every fatal path
and the signals INT, HUP, TERM remove the temporary file. A
destination that exists and is not a regular file is written through,
since a rename would destroy it; a directory is refused (status 1).
A destination that is a symlink to a regular file is replaced by the
file, not written through. The run's accumulated status (4 to 64) does
not prevent the rename: the listing is complete for what could be
listed. `-t`, a choice of time, was proposed and declined.

**V21 `--help` as a man page.** Directed: on a terminal `--help`
should use the man page if available, for bold headings. Readings:
(a) run man(1) on the installed `cksh.1`; (b) format the binary's own
manual. DECIDED AS BUILT, open to correction: (b). The binary writes
its manual as man page source and gives it to the formatter of the
host: mandoc (which pages), else nroff with a pager; else the plain
text through the pager, as before. Reasons: an installed page can be
of another revision than the binary, or absent; and man(1) on a host
stripped of its pages can answer with a notice and status 0, as the
build host's does. `--man` prints the source, and `cksh.1` is that
output, so the makefile no longer holds a second copy of the rule.
EXAMPLES sub-headings become `.SS`, which a formatter sets in bold
with a blank line before each (V11).

## 3 Interface

    cksh [-rLZ] [-n[0-5]] [-x[0-128]] [-k [col[r][,col[r]]...]]
         [-o output] [-c listing | [--] file ...]
    cksh -h | --help | --man | -V | --version
    cksh --fn ... | cksh --bin ...

| option | meaning | default |
|---|---|---|
| `-n[N]` | omit the first N columns, 0-5 | 2; `-n` alone is 0 |
| `-x[N]` | hash length in hexadecimal characters, 0-128; 0 skips hashing | 6; `-x` alone is 0 |
| `-k [list]` | sort; section 4 | no sort: lines stream |
| `-r` | with `-k`, reverse columns without letters; alone, reverse input order | |
| `-Z` | NUL ends each line and each name on standard input; names as they are | newline |
| `-L` | follow symlinks | the link itself |
| `-o output` | write the result to output, renamed into place when complete | standard output |
| `-c listing` | check a saved listing; write the files that differ; status 64 | |
| `--` | end of options | |
| `-h`, `--help` | usage; manual, as a man page on a terminal | |
| `--man` | the manual as man page source | |
| `-V`, `--version` | revision | |
| `--fn`, `--bin` | allow only the function, only the binary | |

Rules:

- A value is joined to its option or is the next word. The next word
  is the value only when it reads as one: digits for `-n` and `-x`; for
  `-k` a column list in the widest sense srt gives it, so a list that
  cksh refuses is still reported as a list and never opened as a file.
  `-o` and `-c` always take a value, joined or the next word.
- Options end at the first file or at `--`.
- From `-n3` up the hash column is omitted and no file is read.
- Names come from the arguments, or one per line from standard input:
  read raw, empty lines skipped, a final line without a newline taken.
  An empty argument is skipped. A NUL in an input line is an error for
  that line (status 4).
- Without `-k` or `-r`, each line is written as its file is read.
- Retired, each refused with a message naming its replacement:
  `-0`..`-5` (write `-n0`..`-n5`); `-krN` (write `-kNr`).

Usage errors are status 1 and nothing is read.

## 4 Key grammar shared with srt and ff

Settled first in srt (plan-srt.md, section 2), as the model for this
tool and for ff. This plan governs cksh; ff will be revised in the
same manner with cksh as its template.

1. Columns are words in the awk sense, counted from 1; widths and
   padding are not significant, and blanks may be squeezed.
2. Sorting is asked for with `-k list`, `col[opts][,col[opts]]...`:
   the named columns in the order given, then the remaining columns
   left to right. Ties follow srt's order: records equal in every
   column keep their input order.
3. A bare `-k` names no column. In cksh that means sort by file name;
   in srt, by whole record.
4. Reverse is `-kNr` for one column or `-r` for all. `-krN` is not
   accepted.
5. cksh knows column types, so `-k5,4,6` is
   `srt -k5x,4x,6,1x,2x,3` on its output: inode, links, time and size
   by hexadecimal value, the hash and the name as text.
6. The name begins in column 6 and runs to the end of the record.
7. cksh selects columns with `-n[0..5]` in place of `-0`..`-5`.

As built in cksh:

- Resolution. The comparison order is the named columns, then the
  columns not named, left to right. With a bare `-k` the name leads:
  6, then 1 to 5. `-k5,4` is 5,4,1,2,3,6.
- Direction. A column written with any letter keeps its own direction
  (`r` or none); `-r` reaches every other column, named or not. This
  is srt's rule that letters on a column replace the global options,
  so `-r -k5x` is column 5 ascending and the rest descending.
- Types. Columns 1, 2, 4 compare as unsigned numbers and 5 as a signed
  number, by value at any width. Columns 3 and 6 compare as bytes.
- Null columns. An omitted column holds zero in every record (V05).
- Stability. Input order is the last comparison.

The srt equivalent of any cksh list: the list, then the remaining
columns, `x` added to 1, 2, 4 and 5; under `-r`, `r` added to every
column that has no letter in the cksh list. The suite checks six such
pairs when srt is present.

## 5 Output

    inode lk hash       size    mdate name
    1cc01d  1 483366        3 5e0bd2c0 t/a

| column | format | content |
|---|---|---|
| 1 inode | `%8x` | inode of the node itself; a symlink is not followed |
| 2 lk | `%2x` | hard link count |
| 3 hash | N characters | shake256-N of the content; zeros for a directory and for a node not hashed; `.` when N is 0 |
| 4 size | `%8x` | bytes; a symlink reports its own size |
| 5 mdate | `%08x`, or `-%07x` | seconds since the epoch; signed (V07) |
| 6 name | text | as given, plus `/` directory, `@` symlink, `\|` fifo, `=` socket |

- An omitted column is written `.`; the name always begins at column 6.
- Widths are least widths. A wider value moves the rest of its line.
- A symlink reports its own inode, links, size and mdate, and the hash
  of the content it leads to. A dangling symlink is warned, hash zeros.
- A directory named with a trailing slash keeps the one (V15).
- Indicators come from `lstat`, so a name ending in `*` or `@` keeps
  its own last character and gains none it should not.
- Terminal: V14. The escape applies to the name and its indicator and
  to names in diagnostics; nothing else cksh writes can hold such a
  byte.

## 6 Hash

SHAKE256 (FIPS 202), built into the binary: rate 136 bytes, padding
0x1f, lanes little-endian whatever the host. The output is cut to N
hexadecimal characters; an odd N is the even length above it less its
last character. A shorter output is the beginning of every longer one,
which is why any N is exact on any host and why the function can cut
a longer output of openssl.

Label: shake256-N (V12). The three readings of a slash are stated
once in `--help` and once in the README, and nowhere used as a label.

Not hashed, with the hash column zero-filled: directories; fifos,
sockets and devices, which are never opened (status 16); dangling
symlinks (status 32); a node that is not the regular file examined
when it is opened (status 16).

Opening: `O_NONBLOCK`, so a node swapped in after the stat cannot
stall the open; then `fstat`, and the node must be a regular file with
the device and inode of the node examined (r0.6); then the flag is
cleared and the content read.

## 7 Exit status and diagnostics

A bitmask. 1 and 2 are fatal and returned alone; the rest accumulate.

| bit | meaning |
|----:|---|
| 1 | invalid option or argument; nothing is read |
| 2 | environment: out of memory; standard input or output failure, which can come in the middle of a run; `--bin` with no binary; in the function, no usable openssl or stat, or a newline in a name under `-k` or `-r` |
| 4 | cannot stat a name; line skipped. Also a NUL in an input line |
| 8 | cannot open or read a regular file; line skipped |
| 16 | fifo, socket or device, never opened; or a node that changed during the scan; warned, hash zeros |
| 32 | dangling symlink; warned, hash zeros |
| 64 | with `-c`, a file differs from its record |

Status 1 also covers a `-c` record that is not a cksh line; status 2 a
`-c` listing or `-o` output that cannot be opened.

Diagnostics go to standard error in the form of the shell `chkerr`
and `chkwrn` functions, `>>> cksh : what 'name': reason (tag)` and
`^^^ cksh : ...`, each ending in a hexadecimal tag that names the
message. One function writes them all, and `exit` is called only from
the fatal path and from `main`.

## 8 Package files

**README.md** --- what cksh is, the hash label, sorting in brief, the
table of changes from r0.5, build and install, the static-link ceiling
(static on Linux and NetBSD; Darwin links the system library alone),
pointer to `--help`.

**makefile** --- written to the intersection of GNU make, bmake and
the Darwin make: no `ifeq`, no `$(shell)`; platform branches inside
recipes via `case` on `uname -s`.

| target | action |
|---|---|
| `all` | `cksh` and `man` |
| `cksh` | compile `cksh.c`, `-std=c99 -Wall -Wextra -Wpedantic` |
| `man` | `cksh.1`, the output of `./cksh --man` |
| `test` | build both, run `test-cksh.sh` against the binary and the function |
| `install` | binary, man page, function file under `PREFIX` (`/usr/local` for root, `$HOME` otherwise; man page under `share/man` where it exists, else `man`); `mkdir -p`, `cp`, `chmod` |
| `clean` | remove `cksh`, `cksh.1` |
| `uninstall` | remove exactly what `install` placed |

**cksh.c** --- single file, C99, no library beyond libc. One
feature-test macro, `_POSIX_C_SOURCE 200809L`, for `lstat`, `getdelim`,
`popen`, `fcntl`, `mkstemp`, `fchmod`, `fsync` and `sigaction`. Manual and usage as string literals, chunked
under the 4095-byte limit.

**cksh.fn.bash** --- per V08. One enclosing function; after the
hand-over everything runs in a subshell, so sourcing defines one name
and a call changes nothing in the calling shell. The same grammar and
the same messages as the binary; `-h` and `--help` carry the binary's
text, held as a copy that the suite compares. Method: stat(1) in the
form of the host, openssl shake256, and for `-k` one key line per
record --- fixed-width decimal numbers, the hash, an index, the name
--- ordered by the native sort in the C locale with one `-k` per
column; the index selects the display line. Differences from the
binary are listed in `--help`, BASH FUNCTION.

**test-cksh.sh** --- section 9.

## 9 Verification

`test-cksh.sh` runs every case against the binary and then holds the
function to the same bytes and status. One case per promise in the
manual or defect found.

1. SHAKE256: the FIPS 202 vectors for empty input and `abc` at 128
   characters; the prefix property at odd and even N; the rate
   boundary (135, 136, 137, 272 bytes) and a multi-read file against
   openssl.
2. Output: zeros for a directory and a fifo; indicators; a name with
   blanks; dots for omitted columns; `d/` and a symlink to a directory
   named with a slash.
3. Status: each bit alone and combined; skipped and kept lines; the
   message format and tags; unreadable file; full standard output,
   streaming and sorted; a fifo is never opened.
4. Grammar: every usage error; the retired spellings and the
   replacement each message names; bare `-n`, `-x`, `-k` before a
   file, last on the line, and with a separate value; clusters; `--`;
   options ending at the first file.
5. Keys: against an oracle (fixed-width decimal keys through the
   native sort) for `-k5,4`, bare `-k`, `-k3`, `-k4r,6`, `-k5r`,
   `-r -k5`, `-r -k5x`; `x` as a no-op; null columns; values wider
   than their columns; times before 1970 and after 2106.
6. The same order from srt, six pairs, on hashed and on wide records.
7. Standard input: as arguments; empty lines; no final newline; a NUL;
   backslashes.
8. Terminal, through a pty (script(1) in either of its two forms,
   kept only if a probe comes back exact): `\ooo` for C0, C1, DEL and
   invalid bytes; valid UTF-8 passes; diagnostics; a pipe is left
   alone. A file name that is not UTF-8 is used where the file system
   takes one; elsewhere the invalid byte is tried in a diagnostic.
   `-Z`: NUL-ended lines; names on standard input, one holding a
   newline; with `-k`; in a cluster; raw to a terminal; into `srt -z`.
9. Help: status; the section list; SEE ALSO; no copyright; the slash
   appears only in the three readings; ASCII; 80 columns; a blank line
   before each of the five example groups, in `--help` and in
   `cksh.1`.
10. Every file but the help and the man page carries the copyright.
11. Function: one name and nothing else set, measured from an empty
    environment so the caller's exported functions do not count; the
    help text is the binary's; hand-over; `--bin` with and without a binary; `--fn`
    with `--bin`.
12. Function parity: forty-odd option sets; diagnostics; wide and
    negative values; odd names; a newline in a name; terminal escapes;
    `-Z`; an openssl without `-xoflen` (a stand-in that refuses the
    option and asks the real one for 32 bytes); one without shake256;
    `LOCALBASE`; an unknown platform.
13. `-L`: names and indicators; the target's columns; a dangling link.
    `-o`: the file is the listing; mode kept and umask honored; a
    usage error and a run stopped midway leave the original and no
    temporary file; directory, missing directory, device; output among
    the files listed. `-c`: unchanged; content, time, inode, kind of
    node, gone; records without hash or inode; mixed hash widths;
    names with a leading blank or a trailing indicator character; a
    link whose target changed; with `-k`, `-r`, `-o`, `-Z`, `-L`;
    every error. `--man`: sections, sub-headings, equal to `cksh.1`
    and to the function's; `--help` on a pty through stand-in
    formatters, and with none.

A revision is complete only when the suite has passed under each make
dialect on each of the three platforms. This session can build and
run on Linux alone; Darwin and NetBSD results are the operator's to
report, and the plan says so rather than implying coverage.

## 10 Dependency posture

- Binary: libc only. No crypto library, whose shake256 and
  output-length option vary by host; no `setlocale()`.
- Function: bash, uname, stat, sort; openssl only for a hash. It
  verifies the openssl it selects against the known hash of empty
  input before trusting it. `$LOCALBASE` is consulted only to find
  that dependency and is never an install target.
- An openssl older than 3.0 has no `-xoflen` and prints 64 characters;
  the function cuts that output, exact for any N to 64, and refuses a
  longer N with status 2. One with no shake256 at all is status 2.

## 11 Revision sequence

- **r0.1** (6305e87b, 20220824) ckstat, ckstatsum, cks: shell functions.
- **r0.2** (677c9c44, 20250106) chksthash, from ckstatsum: the hash column, `shake256 -xoflen 3`.
- **r0.3** (68e20bca, 20251004) renamed cksh; getopts `-n -x -h`; ckstat and ckstatsum retired.
- **r0.4** (68e9ff40, 20251010) `-0`..`-5`; bare `-n` and `-x`; range validation.
- **r0.5** (6ab7e734, 20260926) C port with built-in SHAKE256; value sort `-k`/`-r`; `--help`; status bitmask.
- **r0.6** (6af8d530, 20261114) this plan; the key grammar shared with srt and ff; `-x` in hexadecimal characters; the srt package model.

Next, not begun: ff revised in the same manner, with cksh as its
template.

## 12 Decision log

| item | decision | date |
|---|---|---|
| V01 | `-x` counts hexadecimal characters, 0-128, default 6; r0.5 byte count dropped without compatibility | 20261114 |
| V02 | bare `-n`, `-x` before a file: value only when the next word reads as one | 20261114 |
| V03 | `cksh -k5,4,6` = `srt -k5x,4x,6,1x,2x,3` | 20261114 |
| V04 | key letters: `r` acts, `x` no-op on 1 2 4 5, others refused; no duplicate column; no `-k-N` | 20261114 |
| V05 | a key on an omitted column: the dot is a null column (proposal of a usage error declined) | 20261114 |
| V06 | `-r` with no `-k` reverses input order (proposal of name-descending declined) | 20261114 |
| V07 | negative mdate as signed hexadecimal | 20261114 |
| V08 | function hands over to a binary on PATH; `--fn`, `--bin`; `-V` | 20261114 |
| V09 | r0.1-r0.5 named from the header history; these rounds are r0.6; srt package model | 20261114 |
| V10 | history moves to this plan | 20261114 |
| V11 | srt manual model; a blank line before every example sub-heading | 20261114 |
| V12 | hash label shake256-N; no slash label; three readings stated in `--help` | 20261114 |
| V13 | no copyright in `--help`, `-h`, man page; kept elsewhere | 20261114 |
| V14 | escape control bytes on a terminal | 20261114 |
| V15 | `cksh d/` writes `d/` | 20261114 |
| V16 | r0.5 defects corrected; empty argument stays skipped | 20261114 |
| V17 | `-Z`: NUL ends lines and stdin names; names raw under it (as built, open) | 20261114 |
| V18 | `-c listing`: write the files that differ, status 64; each record checked as made (details as built, open) | 20261114 |
| V19 | `-L`: follow symlinks | 20261114 |
| V20 | `-o output`: temporary sibling, synced, renamed; `-t` declined | 20261114 |
| V21 | `--help` on a terminal: own manual through mandoc or nroff, not man(1) on an installed page (as built, open); `--man` | 20261114 |
| V09 | amended: `PREFIX` as r0.5, `/usr/local` for root and `$HOME` otherwise; the `/usr/local`-for-all default of the first r0.6 build reversed | 20261114 |
| -- | uniform key grammar across srt, cksh, ff (section 4); `-0`..`-5` given up for `-n[0..5]`; `-krN` retired; duplicate detection is srt only | 20261114 |

## 13 Revision status

### r0.6 (6af8d530, 20261114)

Built, against the rulings of section 2:

- `-k` takes a column list; resolution, direction, types and stability
  as section 4. The comparison ends on input order, so the unstable
  library sort cannot reorder equal records.
- `-x` in hexadecimal characters; odd lengths; the hash named
  shake256-N in every text.
- `-n` and `-x` bare before a file; `-0`..`-5` and `-krN` refused with
  the replacement named.
- Signed mdate. `d/` keeps one slash. Names escaped on a terminal,
  in the binary and the function.
- `-Z`, in the binary and the function (V17).
- `-L`, `-o`, `-c` in the binary and the function (V18-V20); status 64.
- `--help` as a man page on a terminal; `--man`; `cksh.1` from it (V21).
- `--help` through a pager on a terminal (PAGER, else less, else
  more); `-V`, `--version`; `--fn`, `--bin`.
- Manual on the srt model: KEYS, HASH, TERMINAL, BASH FUNCTION,
  ENVIRONMENT, SEE ALSO `ff(1), srt(1)`, REVISION; no HISTORY, no
  COPYRIGHT.
- Function rewritten as one enclosing function with hand-over.

Defects of r0.5 corrected:

- The manual said statuses 1 and 2 "stop before any file is read".
  Status 2 can come in the middle of a run; the text now says so.
- The function defined its stat wrapper only for Linux, Darwin and
  NetBSD; elsewhere every file reported "cannot stat" with status 4.
  It is now one status 2 before any file is read.
- After opening, the binary confirmed a regular file but not that it
  was the file examined. It now compares device and inode.
- The man recipe did not guard a leading `'` and kept the blank line
  after each heading. It follows srt's, and keeps the blank line
  before a sub-heading that directly follows a heading (V11).
- Function style: here-document delimiters were a plain `eof`, one
  unquoted; helpers were named `stderr`, `chkerr`, `chkwrn`; a test
  used `-o`; sorted output accumulated in one string. Delimiters are
  now `__CKSH_USAGE__` and `__CKSH_MANUAL__`, quoted; helpers are
  `_cksh_*`; records are held in arrays.
- The function's sort relied on the native sort's last-resort
  comparison; it now gives one key per column and `-s`.

Found while building, and kept:

- In `cksh -n *`, a first file named with digits is the value of `-n`
  (V02). Stated in the README and the manual.
- `-k 5,` does not read as a list (trailing comma), so it is a file
  name; `-k5,` joined is a usage error.
- The function cannot report a NUL in a line of standard input, since
  the shell drops it; listed in BASH FUNCTION.
- The function's key lines end in NUL where the sort of the host has
  `-z`, and then any name sorts. Where it has not, a name containing a
  newline under `-k` is status 2. `-r` alone needs no sort and takes
  any name.

Darwin report, first build of r0.6 (operator, 20261114): 221 passed,
6 failed, 5 skipped. No failure was in the binary or the function;
all are corrected in this archive, under the same revision:

- `pipe: name as it is`. The suite made a file whose name holds a
  byte that is not UTF-8; that file system refuses it ("Illegal byte
  sequence"). The suite now tries the name, falls back to one that is
  valid, says so, and tries the invalid byte in a diagnostic, which
  needs no file.
- `one name defined`. The suite listed every function of the shell,
  and the operator's shell exports its own. The namespace cases now
  start from an empty environment.
- `openssl without -xoflen`, four cases. The stand-in passed plain
  `shake256 -hex` to the real openssl, and a current openssl gives
  shake256 no default length. The stand-in now refuses `-xoflen` and
  asks the real one for 32 bytes, which is what an old one prints.
  The function was right to answer status 2 to what it was shown.
- Skipped there: `/dev/full` (absent); srt (not on PATH; `SRT=path`);
  the terminal cases, since script(1) has another form on that host.
  The suite now tries both forms and keeps one only if a probe comes
  back exact.

Darwin report, second build (operator, 20261114): 244 passed, 0
failed, 5 skipped: `/dev/full` twice, srt twice, and the file name
that is not UTF-8. The terminal cases ran, so the second form of
script(1) is confirmed there. `-L`, `-o`, `-c` and `--man` came after
this report and await the next.

Darwin report, third build (operator, 20261114): 335 passed, 2 failed,
5 skipped. The skips are `/dev/full` twice (binary and function), srt
twice, and the file name that is not UTF-8. So `-L`, `-o`, `-c`,
`--man`, `--help` on a terminal and the function's `-o` and `-c` ran
and passed there, apart from the two cases below. Neither failure was
in the binary or the function; both were in the suite, and both
corrected under the same revision:

- `--man: no line begins with a bare quote or stray dot` counted 62
  where 0 was wanted; the page has 61 lines that begin with a dot. The
  case joined its alternatives with `\|`, which is a GNU extension of
  basic regular expressions, and the Darwin grep did not read them as
  alternatives. The same construct made `-c: a name with a leading
  blank, and one ending in @` count 1 where 2 was wanted. Both now give
  each pattern its own `-e`, which is POSIX.
- Three more cases used the same `\|` and passed on Darwin only
  because a count of 0 was what they wanted: `no copyright in --help`,
  `no copyright in -h` and `cksh.1 has no copyright`. They checked
  nothing there. They now use `-e` too, and the suite holds no `\|`.

The cause on the Darwin grep is inferred from the construct and the
count, not reproduced; the next Darwin run settles it.

Review at the third build, defects found and corrected:

- The function's form-selection pass, which runs in the calling shell,
  matched with `[[ =~ ]]` and so left `BASH_REMATCH` set there after
  any call with a value word; the claim that a call changes nothing in
  the calling shell was false. The pass now matches with patterns, and
  the suite's "nothing else set" case makes calls that would show it.
- The function chose its source of names with a chain `A && {..} ||
  B && {..} || C`; a nonzero status from the first body would have
  fallen through to reading standard input. No path reached it, but
  the form invited it; it is now a `case`.
- The suite's `cksh.1` checks compared the page with an awk copy of
  the makefile rule; with `--man` there is one rule, and the suite
  compares the page with it.
- Reviewed and left: `-o` onto a symlink replaces the link (V20); the
  function does not sync before its rename; a `-c` record whose
  listed file is gone but whose name less a trailing `@` or `/` names
  another file reports that file as differing, not as gone.

Simulated on Linux before release: exported functions in the calling
shell, and an openssl that refuses shake256 without `-xoflen`; the
suite passes under both. The file-system refusal and the second form
of script(1) cannot be simulated here and await the next Darwin run.

Verified on Linux (gcc and clang, GNU make, bash 5.2, GNU sort and stat, OpenSSL
3; srt r0.6 for case 6): the suite passes as root and as an
unprivileged user; the binary is clean under `-fsanitize=address,
undefined` across the suite; no compiler warning under `-std=c99
-Wall -Wextra -Wpedantic`.

Not verified: the two corrected suite cases on Darwin; what a real mandoc
or nroff draws from the source (stand-ins are used, and the build host
has neither); NetBSD; bmake; a real openssl without `-xoflen` (a
stand-in is used).

### r0.5 (6ab7e734, 20260926)

C port. As recorded then, changes from the bash function of r0.4:

- Directories and other nodes that are not hashed show a zero-filled
  hash; previously the column was blank-padded.
- Fifos get a warning and are never opened; previously the run blocked
  on them.
- Per-file errors warn and the run continues; previously the first
  error aborted the run.
- The exit status is a bitmask instead of 0 or 1.
- Indicators come from `lstat`, so a file whose name ends in `*` or
  `%` keeps that character; previously `sed` stripped it.
- Names on standard input are read raw, so backslashes survive.
- Numbers are formatted by `printf` in the shell rather than by `awk`,
  which avoids awk's double-precision limit on large sizes and inodes.
- Sorting (`-k`, `-r`) is built in, replacing `| sort -k5`.
- Helpers of the function isolated in a subshell.

Verified then on Linux under GNU make with gcc and clang, with the
address and undefined-behavior sanitizers, as root and non-root. Not
run under bmake, on NetBSD, or on Darwin.

## 14 History

The header lines of the files, in one place.

    revision 6af8d530 20261114 134000 PST Sat --- r0.6
        key list -k5,4; -x in hexadecimal characters, hash named
        shake256-N; -n and -x bare before a file; -0..-5 and -krN
        retired; signed mdate; names escaped on a terminal; d/ keeps one
        slash; node identity checked after open; -Z NUL records; -L; -o
        output renamed into place; -c check a saved listing; --help as a
        man page on a terminal, --man; -V, --fn and --bin; manual,
        makefile, suite and plan on the srt model; install prefix as r0.5
    revision 6ab7e734 20260926 083932 PDT Sat --- r0.5
        C port with built-in SHAKE256; openssl<3 xoflen fallback in the
        bash function; -k/-r value sort; --help manual; status bitmask;
        chkerr/chkwrn diagnostics; bash helpers isolated in a subshell
    revision 68e9ff40 20251010 235456 PDT Fri --- r0.4
        -0..-5, bare -n and -x (getopts :), -n and -x range validation
    revision 68e20bca 20251004 231018 PDT Sat --- r0.3
        renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired
    revision 677c9c44 20250106 191516 PST Mon --- r0.2
        chksthash, from ckstatsum: shake256 -xoflen 3 hash column
    original 6305e87b 20220824 015939 PDT Wed --- r0.1
        ckstat ckstatsum cks
