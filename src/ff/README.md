# ff: functional find

ff walks file trees and tests each node against an expression, as
find(1) does, with one letter per switch and the same behavior on
Linux, Darwin and NetBSD. It prints names, or one cksh line per node,
and sorts what it prints by column. It is a C99 binary, and a bash
function for hosts without it.

`ff --help` is the manual and documents the current implementation.
On a terminal it is shown as a man page, headings in bold, through
the formatter of the host (mandoc, else nroff and a pager) without the
page being installed; where there is no formatter, through the pager
alone. `ff --man` writes the man page source.
[./plan-ff.md](./plan-ff.md) carries the requirements, the decisions behind them, the
history, and the status of each revision.

    revision 6af927be 20261114 193214 PST Sat --- r0.7
    revision 6ae4ea00 20261030 120328 PDT Fri --- r0.6
    revision 6adcb748 20261024 064856 PDT Sat --- r0.5
    revision 6abc5da8 20260929 175400 PDT Tue --- r0.4
    revision 6abb42b9 20260928 214649 PDT Mon --- r0.3
    revision 6ab89f43 20260926 214451 PDT Sat --- r0.2
    original 6ab7fec8 20260926 102008 PDT Sat --- r0.1

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

<!--contents 2 3 pre="## Contents" post="---"-->

## What it does

```
ff . -t f -n '*.c'               C sources
ff src -r '\.(c|h)$'             the same by ERE (unanchored)
ff . -n .git -z -o -t f -f       files, skipping .git trees
ff -k5 . -t f -m -1              changed within a day, oldest first
ff -k4r,6 . -t f -v              cksh lines, largest first, then by name
ff . -t f -x grep -l TODO {} +   grep per directory, race safe
ff . -n '*.o' -delete            remove objects
```

Two implementations share one grammar, one manual and one exit status
scheme:

- `ff` --- C99 binary, no dependency beyond libc, with its own directory
  walker (not fts).
- `ff.fn.bash` --- bash function that translates the ff grammar into an
  argument array for the host's native find (BSD or GNU dialect, probed per
  call) and never uses `eval`. Where the native find cannot express a
  request it exits 2 and names the binary. Load it with `. ff.fn.bash`; it
  adds the one name `ff` to the calling shell. When a binary named `ff` is
  on `PATH` the function runs it; `--fn` keeps the function and `--bin`
  requires the binary.

`-h` is a one-screen usage:

```
    Usage: ff [-IHLDSXZV] [-k [col[r][,col[r]]...]] [--] [path ...] [expression]
           ff -h | --help | --man | --version   (--fn | --bin: --help)
      options  -I ignore case for -n -p -r  -H/-L follow symlinks
               -D post-order  -S sorted  -X one filesystem  -Z NUL records
               -V show the native find command (ff.fn.bash)
      sort     -k5,4 by column 5, then 4, then the remaining columns in
               order; columns as -v writes them: 1 inode 2 links 3 .
               4 size 5 mdate 6 name; no -v needed.  -k alone: by name
               -k5r  r reverses that column
      tests    -n glob  -p glob  -r ERE  -t fdlpsbc  -d [+-]N  -s [+-]N[ckMGT]
               -m -a -c -b [+-]N[smhdw]  -w [+-][ ]([.][.]/file|HEX)
               -u user  -g group  -l [+-]N  -i [+-]HEX  -y file (same node)  -e
               -mode [+-]bits  -z (prune)  -0 (true)  -1 (false)
      actions  -f print  -v cksh line  -x cmd {} ;|+  (in entry's dir)
               -j cmd {} ;|+  (full path)  -delete  -q quit
      logic    ( )  ! or -not  juxtaposition = and  -o or
      -h this summary, --help the manual
```

The test suite runs its cases through both implementations and checks
them against each other.

ff is one of three tools that share a record and a key grammar: ff
finds files, [cksh](../cksh/) lists them with a hash, [srt](../srt/)
sorts listings. The `-v` line of ff is the cksh line, and `-k` in each
tool reads the same list.

## Files

<https://github.com/georgalis/pub/tree/main/src/ff>
- **[ff.c](./ff.c)** --- the program: C99 source for the `ff` binary, including the usage text and the manual source.
- **[ff.fn.bash](./ff.fn.bash)** --- the bash function `ff`: translates the same switches into the host's native `find` argument list; carries the usage and manual text, copied from the binary.
- **[makefile](./makefile)** --- targets `all ff man test install clean uninstall`. `ff.1` is the output of `ff --man`.
- **[test-ff.sh](./test-ff.sh)** --- the full suite, run twice (C binary, then bash function), with a byte-for-byte parity check between the two; host-dependent cases are skipped by named probe.
- **[README.md](./README.md)** --- this file: introduction, grammar, build, translator limits, verified state.
- **[plan-ff.md](./plan-ff.md)** --- requirements, design decisions and their rationale, the history, and the status of each revision.

## Build

```
make            # ./ff and ./ff.1 (the output of ./ff --man)
make test       # regression suite, test-ff.sh
make install    # PREFIX defaults to /usr/local for root, else $HOME
make uninstall  # remove exactly what install placed
make CC=$LOCALBASE/bin/gcc
```

The makefile uses only the constructs shared by GNU make, bmake, and Apple
make. It installs `bin/ff`, `man1/ff.1`, and `share/ff/ff.fn.bash`.

Linking by platform:

- Linux and NetBSD: `-static`, falling back to dynamic linking when no
  static libc is installed. On Linux, `-u` and `-g` names are resolved by
  running the host's `getent` (`/usr/bin/getent` or `/bin/getent`, never
  looked up in `PATH`), not by `getpwnam`, which a static glibc binary
  cannot load NSS modules for. `/etc/passwd` is never read directly: under
  LDAP, sssd or systemd-homed it is not the user database. Without
  `getent`, a name exits 2 and a numeric id still works.
- Darwin: dynamic, against libSystem only. Apple ships no static libSystem,
  so this is as far as linking can go there.

## Grammar

`ff [options] [path ...] [expression]`, default path `.`, default action
print. Options are uppercase, and `-k`, and global, and may appear anywhere
outside a primary's argument. Primaries are lowercase, the digits 0 and 1,
or `-mode` and `-delete`.

| option | find | |
|--------|------|-|
| `-I` | `-iname` `-ipath` `-iregex` | case-insensitive `-n -p -r` |
| `-H` `-L` | `-H` `-L` | symlink policy |
| `-D` | `-d` / `-depth` | post-order |
| `-S` | `-s` | sorted walk |
| `-X` | `-x` / `-xdev` | one filesystem |
| `-Z` | `-print0` | NUL-terminated records, `-v` lines too |
| `-V` | | bash function: print the native find command to stderr |
| `-k [list]` | `\| sort` | sort output by the columns of `-v`; see below |

| primary | find | ff semantics |
|---------|------|--------------|
| `-n glob` | `-name` | |
| `-p glob` | `-path` | |
| `-r ere` | `-E -regex` | **always ERE, unanchored**; add `^` `$` |
| `-t fdlpsbc` | `-type` | several letters mean or |
| `-d [+-]N` | `-mindepth` `-maxdepth` | global walk bound |
| `-s [+-]N[ckMGT]` | `-size` | bytes, exact, no rounding |
| `-m -a -c -b [+-]N[smhdw]` | `-mtime` ... `-Btime` | age in seconds; default unit d |
| `-w [+-][ ]([.][.]/file\|HEX)` | `-newer` | when: after, before or at; see below |
| `-y file` | `-samefile` | same device and inode |
| `-mode [+-]bits` | `-perm` | a query, see below |
| `-u` `-g` | `-user` `-group` | |
| `-l [+-]N` | `-links` | |
| `-i [+-]HEX` | `-inum` | hex, as `-v` prints it |
| `-e` | `-empty` | |
| `-z` | `-prune` | |
| `-0` `-1` | `-true` `-false` | |
| `-f` | `-print` | |
| `-v` | `-ls` | cksh line, identical to `cksh -n0 -x0` |
| `-x cmd ... ;` / `{} +` | `-execdir` | runs in the node's verified directory |
| `-j cmd ... ;` / `{} +` | `-exec` | full path, race exposed like find |
| `-delete` | `-delete` | a long switch to confirm |
| `-q` | `-quit` / `-exit` | |

Operators: `( )`, `!` or `-not`, juxtaposition for and, `-o`. The shell
treats `( ) ; *` and sometimes `!` as its own syntax, so escape or quote
them: `ff . \( -n .git -o -n node_modules \) -z -o -t f -f`.

`-w` is "when": `-w +./ref` modified after file `ref` (find `-newer`),
`-w -./ref` before it, `-w ./ref` at the same time, comparing the full
timestamp. With a hex epoch second, the mdate column of `ff -v`, the
comparison is by whole seconds: `-w -6abb2e78` modified before that
second. A file always begins with `./`, `../` or `/`, and anything else
must be hex, so no word is both: a file named `cafe` or `6abb2e78` is
`./cafe`, `./6abb2e78`. The sign may stand apart as its own word, so
`-w + ./ref` is `-w +./ref` and `-w - 6abb2e78` is `-w -6abb2e78`; the
word after a lone sign takes no sign of its own.

`-r` is always a POSIX extended regular expression (ERE, as `grep -E`),
matched anywhere in the path; `-n` and `-p` are glob; `-I` makes all three
case-insensitive. There is no BRE option, and `-E` is an unknown option.
ERE reads `( ) { } + ? |` as operators and `\( \) \{` as the characters
themselves, the reverse of BRE. The manual's REGULAR EXPRESSIONS section
lists the syntax, the BRE differences, and the portable escapes
(`[[:digit:]]`, not `\d`).

The primaries `-0` and `-1` are read as true and false.

`-mode` asks about permission bits rather than doing chmod arithmetic, and
its `+` and `-` keep ff's sense of more and less:

- Octal: `0755` exactly; `+0755` at least (every bit, maybe more, find
  `-perm -0755`); `-0755` at most (no bit outside it).
- Symbolic: clauses `[ugoa][+-][rwxXst]` joined by commas, all required;
  `+` has, `-` lacks, no sign means `+`. Named classes must each satisfy a
  clause; with no class, `+x` means someone may execute and `-x` no one
  may. `X` is execute that only a directory satisfies, `s` setuid (`u`) or
  setgid (`g`), `t` the sticky bit. With no class, each class is tested
  with only the bits it can hold, so `-mode +rs` holds for a 0644 file
  (other has `r` and can hold no `s`); `-mode u+rs` needs both in one
  class.

```
ff . -t f -mode o+w     world-writable files
ff . -mode +s           setuid or setgid
ff . -not -mode go-w    group or other may write
ff . -mode o-X          directories others may not search
```

`-k [col[r][,col[r]]...]` sorts what ff prints, by the columns of the
`-v` line: 1 inode, 2 links, 3 a dot, 4 size, 5 mdate, 6 name. Columns
are words, as `$1`, `$2` are in awk; widths are not significant, and
the name begins at column 6 and runs to the end of the record. The
named columns are compared in the order given, then the remaining
columns left to right, then walk order: `-k5,4` compares 5,4,1,2,3,6.
`-k` alone names no column and sorts by name. `-k5 -k4` is `-k5,4`.

The columns need not be printed. Every record, from `-f`, `-v` or the
default print, is keyed by its node's stat, so `ff -k5` orders bare
names by time, as `ls -t` orders names without `-l`. ff knows the type
of each column: inode, links, size and mdate compare by value (mdate
signed), the name bytewise as it is printed. Column 3 is where cksh
writes its hash, shake256-6 by default; ff reads no file and writes a
dot there, a null column, so a key on it orders nothing and the next
column decides.

`r` after a column reverses that column: `-k5r`. `x` is accepted on the
numeric columns and changes nothing, so a list written for srt can be
given to ff; any other letter is refused. `-krN` is retired for `-kNr`,
and `-k-1` is not accepted. ff has no option that reverses every column,
`-r` being the regular expression primary. The list may be joined to
`-k` or be the next word, when that word reads as a list: `ff -k 5,4`
sorts, `ff -k src` sorts `src` by name, and a path named like a list is
written `./5`. `-k` may end a group of options: `-Sk5`.

Records are held until the walk ends and written with their own
terminators; `-x` and `-j` output is not sorted, and after `-q` the
records printed so far are.

```
ff -k5 . -t f -m -1                    changed within a day, oldest first
ff -k4r,6 . -t f -v                    cksh lines, largest first, then name
ff . -t f -v | srt -k5x,4x,6,1x,2x,3   what ff -k5,4,6 . -t f -v writes
ff . -t f | cksh -k5,4                 the same files, with their hashes
ff -Z . -t f | cksh -Z | srt -Z -k5x,4x   NUL records end to end
```

`-Z` (`--zero-terminated`) ends every record with NUL, the names from
`-f` and the default print and the lines of `-v`, and writes names as
they are. It is the `-Z` of cksh and srt.

`-x` or `-j`: `-j` passes the full path, and the child looks every
component up again, so a directory swapped for a symlink after ff checked
it redirects the command. That is the classic find `-exec` race. `-x`
changes into the directory ff already opened and verified, then passes
`./name`, so only the last component is resolved again. `-x` refuses to run
when `PATH` holds a relative or empty element, since the working directory
is the walked one. `-delete` removes through the same verified parent
descriptor. It refuses an operand whole, walking nothing below it, when
the operand ends in `..` or is the root directory itself: `/`, `//`,
`/.`, `/usr/..`, `.` run from `/`, or under `-H` a symlink to `/`. The
root is found by device and inode, not by spelling. find refuses only
the node and still empties it; ff reports status 4 and leaves it whole.
An operand `.` keeps find's meaning: its contents are walked and it is
kept.

## Help and manual

`--help` writes the manual. When stdout is a terminal it is shown as a
man page, with its headings in bold, through the formatter of the host:
mandoc, else nroff with a pager (`PAGER`, else less, else more). Where
neither is found the text goes through the pager alone, and where no
pager runs it is written directly, so `--help` never shows nothing. The
formatter and pager run by `/bin/sh -c`, as `man` runs them: `PAGER` is
the user's own setting, and unlike `-x` and `-j` words it is meant to
be a shell command (`less -R`). A pager quit early is not an error.
`-h`, and `--help` to a pipe or file, are plain. `--man` writes the man
page source, which is `ff.1`; `--version` writes the revision.

## Output safety

Names go out as raw bytes to a pipe or with `-Z`. On a terminal, C0 and C1
control characters, DEL and invalid UTF-8 print as `\ooo`, so a crafted file
name cannot drive the terminal. Diagnostics on a terminal follow the same
rule.

## Diagnostics and exit status

Messages go to stderr in the format of the shell `chkerr` and `chkwrn`
functions, one line each, ending in a hex tag that names the message:

```
>>> ff : cannot stat 't/nope': No such file or directory (6ab7ff32)
>>> ff : -t: types are f d l p s b c, not 'q' (6ab7ff0a)
^^^ ff : filesystem loop, skipped 't/d/up' (6ab7ff3a)
```

Usage errors are identical, message and tag, from the binary and the bash
function. Only the binary adds the system's reason, as after the colon
above.

The exit status is a bitmask. Statuses 1 and 2 are fatal. The others accumulate while the walk
continues.

| bit | meaning |
|----:|---------|
| 1 | invalid option or expression |
| 2 | environment: memory, stdout, fork, unsafe `PATH` for `-x`; bash: request the native find cannot express |
| 4 | cannot stat, open, read or delete a node; subtree skipped |
| 8 | a command could not run, or a `+` batch exited nonzero |
| 16 | filesystem or symlink loop |
| 32 | node changed between listing and opening; skipped |

The bash function sees only the native find's 0 or 1, and reports any
native failure as 4.

## The walker

- Every directory is opened with `openat(parent, name, O_DIRECTORY|
  O_NOFOLLOW)` and its `dev/ino` is compared with the `fstatat` taken while
  listing. A mismatch is status 32 and the subtree is skipped, not
  followed.
- At most 64 directory descriptors are held, fewer under a low
  `RLIMIT_NOFILE`. Deeper levels are reopened from the nearest held
  ancestor, one component at a time, with the same verification.
- A directory that is its own ancestor (a `-L` loop or a bind mount) is
  reported and skipped, as fts `FTS_DC` is in find.
- `d_type` avoids a `stat` when the expression needs none. `DT_UNKNOWN`
  (xfs, nfs, some fuse) falls back to `fstatat`.

fts(3) was not used: musl ships none, so a static musl build could not link
it, and it gives no per-open verification.

## Darwin considerations

- Birth time `-b`: `st_birthtime` on Darwin and NetBSD, `statx` on Linux
  (glibc 2.28, musl 1.2.5). Where the filesystem records none, `-b` is
  false with one warning.
- APFS is case-insensitive by default: `-n foo` misses `Foo`, which the
  filesystem itself would open. Use `-I`.
- Unicode normalization: HFS+ stores names decomposed (NFD), while APFS
  keeps the form they were created with. ff compares bytes, so a
  precomposed pattern does not match a decomposed name.
- Sealed system volume and firmlinks: `/` and `/System/Volumes/Data` have
  different `st_dev`, so `-X` from `/` stops at the data volume.
- SIP and TCC deny some directories even to root (e.g. `~/Library/Mail`).
  These give status 4 with one warning, and the walk continues.
- Dataless files (iCloud): ff never opens regular files; only `-e` opens
  directories. Walking does not trigger downloads, but commands run by
  `-x` or `-j` can.
- BSD file flags, xattrs and ACLs (`UF_HIDDEN`, `com.apple.quarantine`) are
  not yet primaries.
- Regex: plain POSIX `regcomp` with `REG_EXTENDED`. Darwin's `REG_ENHANCED`
  is not used, to keep Linux and Darwin identical. Back-references, empty
  alternatives (`(a)\1`, `a||b`) and escapes such as `\d` are outside
  POSIX ERE and vary by C library; portable patterns avoid them.
- Darwin's native find (FreeBSD-derived) is BSD dialect for the bash
  function. It has `-E`, `-Bmin`, `-quit` and `-s`.

## Bash translator limits

Sourcing `ff.fn.bash` defines the function `ff` and nothing else. When
a binary named `ff` is on `PATH` the function runs it with the same
words. `--fn` allows only the function; `-V`, which only the function
can answer, keeps it too. `--bin` allows only the binary: the function
stops with status 2 when there is none, and the binary, given `--fn`,
stops with status 1. The two together are a usage error.

Each of these exits 2 and names the binary:

- `-b` on GNU find (no birth time primary);
- `-m -a -c` counted in seconds that are not whole minutes (the native
  find counts minutes);
- `-r` back-references (the translator wraps the pattern in a group to
  make it unanchored, which renumbers its groups);
- `-v` combined with `-f`, `-x`, `-j` or `-delete`;
- `-k` where `sort` lacks `-z` or `-s` (records are sorted by
  `sort -z -s -t TAB` on decimal stat keys);
- `-S` combined with `-x`, `-j`, `-delete` or `-q` on GNU find, which has
  no sorted walk. Plain `-S` output is emulated there by sorting each
  operand's paths with `/` as the lowest byte.

A path operand beginning with `-` also exits 2.

`-r` runs as BSD `find -E -regex` or GNU `-regextype posix-extended
-regex`, wrapped `.*(re).*`, so `-V` shows the native `-E` even though ff
has no such option.

Where the native find itself differs, the function passes the difference
through rather than emulate a walk it does not own. BSD find (seen on
Darwin):

- `-delete` of a directory that is not empty is expected to be silent,
  status 0, where ff reports status 4 (FreeBSD ignores `ENOTEMPTY`; the
  test probes the host);
- under `-L`, a directory that closes a loop is tested, where ff and GNU
  find skip it;
- an unreadable directory named as an operand is not tested, where ff
  lists it, with status 4.

test-ff.sh probes the host's find for each and skips that case in the bash
pass only where the host behaves so.

`-w` uses `-newermt @S.N` where the native find takes it (GNU). Elsewhere
(Darwin, BSD) it writes reference files at the needed instants with
`touch -d YYYY-MM-DDThh:mm:ss.nnnnnnnnnZ` and compares with `-newer`,
which every find has; they live in one temporary directory removed after
the run, and `-V` names it. Sub-second file comparisons then depend on
the native `-newer`; HEX forms are whole seconds either way. Where `date`,
`touch -d` or a nanosecond `stat` is missing, those forms exit 2.

Where the native find has no `-samefile` (NetBSD), `-y` uses the
reference's inode number from `stat` as `-inum`. find has no primary for
the device, so that is exact unless the walk crosses into another
filesystem holding the same inode number; `-V` shows which form ran.

`-x` must hand each command `./name`, as the binary does, so a name such
as `-rf` is never read as an option. GNU `-execdir` gives `./name`; BSD
`-execdir` gives the bare name (seen on Darwin). The function probes which
once per call. For bare names it runs the command through a fixed
`/bin/sh -c` script that prefixes `./` to each `{}` name and every `+`
name: the command and its words reach the script as arguments and are
never evaluated, and the script ends in `exec`, so the status is the
command's own. `-V` shows the wrapped form. `FF_BARE_EXECDIR=1` forces it,
for testing on GNU.

`-V` prints the native command before running it, quoted to paste back
into a shell, as a starting point for an OS-specific find command:

```
$ ff -V . -n '*.h' -w +./Makefile
find . \( -name \*.h -newer ./Makefile \) -print
```

## Verified

- `make test` runs every behavior case twice, once through the binary
  and once through the bash function, then a parity pass comparing the
  two byte for byte, with a tally for each. The function skips only the
  cases it cannot meet, in named groups: status bits 8, 16 and 32 and
  status 2 for a full stdout (the native find reports any failure as 1,
  read as 4); the binary's `-V` note; `-x` with an absolute command under
  a relative `PATH` (GNU find refuses `-execdir` whatever the command); a
  path operand beginning with `-`; walk diagnostics in chkerr form (the
  native find writes its own). The function is always run with `--fn`, so
  an `ff` installed on `PATH` is never the one tested.
- r0.7 passes under GNU make on Linux (glibc 2.39, GNU find 4.9, bash
  5.2): 922 passed, 0 failed, 9 skipped as root, which skips the
  unreadable-directory cases, and 926 passed, 7 skipped as an
  unprivileged user; with srt r0.6 and cksh r0.6 on `PATH` for the
  equivalence cases; with gcc and clang; and with a gcc build under ASan
  and UBSan, clean. gcc and clang compile ff.c without a warning under
  `-std=c99 -Wall -Wextra -Wpedantic`.
- The walk matches GNU find 4.9 on each primary it shares.
- Darwin (Apple clang, bash 3.2 as `/bin/sh`): the first r0.7 build
  passed 914 of 918 with 12 skipped, the terminal `--help` and signed
  mdate cases among those passed. The 4 failures were the suite's own:
  it called `cksh` by name, and found a cksh function exported into the
  shell before the binary. The suite now runs srt and cksh as files on
  `PATH`; that correction has been run on Linux only, under bash in
  POSIX mode with functions of both names exported.
- Not run on NetBSD or under bmake. The cases that depend on the host
  are the terminal `--help` cases (script(1) in either form), the
  signed mdate (a `touch` and file system that take 1960), and the srt
  and cksh equivalence (both on `PATH`); each skips itself and says so
  where the host cannot run it.

See [plan-ff.md](./plan-ff.md) for the design record, the decisions and
the history.
