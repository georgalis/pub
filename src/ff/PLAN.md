# ff --- functional find: plan r2 (approved 20260926)

(c) 2026 George Georgalis <george@iuxta.com>
Unlimited use with attribution.

<!-- org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026; model: cksh (cksh.c + cksh.fn.bash + makefile + test.sh) -->

## Context

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

## Finding that reshapes the shell companion: Lua

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

## Walker: owned, not fts(3)

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

## Grammar (draft letters --- expect revision)

Positional like find: `ff [options] [path...] [expression]`; default path `.`,
default action print. Options are uppercase letters, primaries lowercase
letters or the digits 0 and 1 (r8), so the two sets never collide. The
tables below carry the current letters; the decisions log records each
change.

Options (before paths)

| ff | NetBSD find | note |
|----|-------------|------|
| -E | -E | ERE for `-r`; critical |
| -I | (-iname/-iregex) | case-insensitive for every `-n -p -r` |
| -H / -L | -H / -L | symlink policy; -P default |
| -D | -d | depth-first (post-order) |
| -S | -s | sorted traversal |
| -X | -x / -xdev | stay on one filesystem |
| -Z | -print0 | NUL-terminated output (r8; was -0) |
| -h / --help | | usage / manual |

Primaries (after paths); `!` not, `-o` or, juxtaposition and, `(` `)` group

| ff | find | semantics |
|----|------|-----------|
| -n glob | -name | fnmatch on basename, no FNM_PERIOD |
| -p glob | -path | fnmatch on whole path |
| -r re | -regex | regexec on whole path; **unanchored** (grep-like, add `^$`); decided r1, documented deviation |
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

## Security posture

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

## Exit status bitmask

| bit | meaning |
|----:|---------|
| 1 | invalid option or expression |
| 2 | environment: memory, stdout failure, fd exhaustion |
| 4 | cannot stat or open a node; subtree skipped |
| 8 | exec child failed or returned nonzero |
| 16 | symlink cycle under -L |
| 32 | node changed during walk (dev/ino mismatch) |

## Darwin variations to weigh

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
- **Regex**: Darwin `REG_ENHANCED` avoided for parity; plain POSIX only.
- **Linking**: no static libSystem; stated in README, as cksh does.
- **Native find for the bash companion**: Darwin find is FreeBSD-derived
  (`-E`, `-depth n`, time units, `-Bmin`) while NetBSD lacks some of these;
  translator keys on feature probes, not `uname`.

## Files

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

## Phases

1. `--help` manual text first --- the grammar's source of truth.
2. Walker + `-n -p -r -t -d -z`, `-E -I -H -L -D -S -X -Z`, print.
3. `-s -m -a -c -b -w -k -u -g -e -l -i`.
4. `-x` and `-j` (`;` and `+`), `-delete`, `-q`, `-v`.
5. bash translator + parity section.
6. Darwin extras after first Darwin run.

## Verification

`make && make test` under GNU make (gcc, clang, `-fsanitize=address,undefined`,
root and non-root) on Linux here; `bmake` if installable; Darwin and NetBSD
runs by you --- the README states which were actually exercised, as cksh does.

## Implementation record (r3, first build)

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

## Decisions log

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
