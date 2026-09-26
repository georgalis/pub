# ff --- functional find: plan r2 (approved 20260926)

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
default action print. Options are uppercase, primaries lowercase, so the two
sets never collide.

Options (before paths)

| ff | NetBSD find | note |
|----|-------------|------|
| -E | -E | ERE for `-r`; critical |
| -I | (-iname/-iregex) | case-insensitive for every `-n -p -r` |
| -H / -L | -H / -L | symlink policy; -P default |
| -D | -d | depth-first (post-order) |
| -S | -s | sorted traversal |
| -X | -x / -xdev | stay on one filesystem |
| -0 | -print0 | NUL-terminated output |
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
| -w file | -newer | mtime newer than file |
| -k mode | -perm | octal or symbolic, `-`/`+` prefixes as find |
| -u -g name/id | -user -group | |
| -e | -empty | |
| -l [+-]N | -links | |
| -i N | -inum | |
| -z | -prune | |
| -x cmd {} ; / + | -execdir | argv exec in the entry's directory, never a shell |
| -j cmd {} ; / + | -exec | plain exec from ff's cwd, full path in `{}`; race-exposed, documented as such (r2) |
| -delete | -delete | the one long primary, by design; see below |
| -q | -exit/-quit | stop walk |
| -v | -ls | cksh-shape line: hex fields, awk-sortable |

`-delete` (r2): spelled in full rather than a single letter so a
one-keystroke typo cannot destroy data.
Implies `-D` post-order, as find does. Removal is `unlinkat(dirfd, name,
0 | AT_REMOVEDIR)` against the already-verified parent dirfd --- the same
race closure as `-x`: no path is re-resolved. Refuses operands `.`, `..`, `/`
and any path ending in `/..`; non-empty dir failure = bit 4, walk continues.
The bash translator maps it to native `-delete` (both dialects have it).

Excluded phase 1: `-ok`, `-fprint`, `-printf` (GNU only anyway), `-flags`,
`-fstype`.

## Security posture

- exec: `fork`+`execvp` on an argv array, `{}` as whole-argument substitution
  only; `+` batches sized against `sysconf(_SC_ARG_MAX)` minus environ;
  execdir semantics (`./name` in the opened dirfd via `fchdir` in the child)
  closes the path-swap race that plain `-exec` has.
- output (decided r1): raw bytes (as find) under `-0` or when stdout is not a
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
2. Walker + `-n -p -r -t -d -z`, `-E -I -H -L -D -S -X -0`, print.
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
