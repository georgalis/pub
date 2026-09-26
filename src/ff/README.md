# ff

Functional find: NetBSD find(1) semantics where they matter, one letter per
switch, the same behavior on Linux and Darwin.

```
ff . -t f -n '*.c'               C sources
ff -E src -r '\.(c|h)$'          the same by regex (unanchored)
ff . -n .git -z -o -t f -f       files, skipping .git trees
ff . -t f -m -1 -v | sort -k5    changed today, cksh lines sorted by mtime
ff . -t f -x grep -l TODO {} +   grep per directory, race safe
ff . -n '*.o' -delete            remove objects
```

Two implementations, sharing one grammar, one manual and one exit status
scheme:

- `ff` --- C99 binary, no dependency beyond libc, with its own directory
  walker (not fts).
- `ff.fn.bash` --- bash function that translates the ff grammar into an
  argument array for the host's native find (BSD or GNU dialect, probed per
  call) and never uses `eval`. Where the native find cannot express a
  request it exits 2 and names the binary. Load it with `. ff.fn.bash`; its
  body runs in a subshell, so only `ff` enters the caller's namespace.

The same model as cksh: `-h` and
`--help` are compiled in, the man page is generated from `--help`, and the
test suite checks the two implementations against each other.

## Build

```
make            # ./ff and ./ff.1 (man page generated from --help)
make test       # regression suite, test.sh
make install    # PREFIX defaults to /usr/local for root, else $HOME
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
print. Options are uppercase and global, and may appear anywhere outside a
primary's argument. Primaries are lowercase.

| option | find | |
|--------|------|-|
| `-E` | `-E` | ERE for `-r` (default BRE) |
| `-I` | `-iname` `-ipath` `-iregex` | case-insensitive `-n -p -r` |
| `-H` `-L` | `-H` `-L` | symlink policy |
| `-D` | `-d` / `-depth` | post-order |
| `-S` | `-s` | sorted walk |
| `-X` | `-x` / `-xdev` | one filesystem |
| `-0` | `-print0` | NUL-terminated names |

| primary | find | ff semantics |
|---------|------|--------------|
| `-n glob` | `-name` | |
| `-p glob` | `-path` | |
| `-r re` | `-regex` | **unanchored**; add `^` `$` |
| `-t fdlpsbc` | `-type` | several letters mean or |
| `-d [+-]N` | `-mindepth` `-maxdepth` | global walk bound |
| `-s [+-]N[ckMGT]` | `-size` | bytes, exact, no rounding |
| `-m -a -c -b [+-]N[smhdw]` | `-mtime` ... `-Btime` | age in seconds; default unit d |
| `-w file` | `-newer` | |
| `-k [+-]mode` | `-perm` | `+` any bit |
| `-u` `-g` | `-user` `-group` | |
| `-l` `-i` | `-links` `-inum` | |
| `-e` | `-empty` | |
| `-z` | `-prune` | |
| `-f` | `-print` | |
| `-v` | `-ls` | cksh line, identical to `cksh -n0 -x0` |
| `-x cmd ... ;` / `{} +` | `-execdir` | runs in the node's verified directory |
| `-j cmd ... ;` / `{} +` | `-exec` | full path, race exposed like find |
| `-delete` | `-delete` | the one long switch, by design |
| `-q` | `-quit` / `-exit` | |

Operators: `( )`, `!`, juxtaposition for and, `-o`.

`-x` or `-j`: `-j` passes the full path, and the child looks every
component up again, so a directory swapped for a symlink after ff checked
it redirects the command. That is the classic find `-exec` race. `-x`
changes into the directory ff already opened and verified, then passes
`./name`, so only the last component is resolved again. `-x` refuses to run
when `PATH` holds a relative or empty element, since the working directory
is the walked one. `-delete` removes through the same verified parent
descriptor.

## Output safety

Names go out as raw bytes to a pipe or with `-0`. On a terminal, C0 and C1
control characters, DEL and invalid UTF-8 print as `\ooo`, so a crafted file
name cannot drive the terminal. Diagnostics on a terminal follow the same
rule.

## Diagnostics and exit status

Messages go to stderr in the format of the shell `chkerr` and `chkwrn`
functions, one line each, ending in a hex tag that names the message:

```
>>> ff : cannot stat 't/nope': No such file or directory (6ab7ff32)
>>> ff : -t: types are f d l p s b c 'q' (6ab7ff0a)
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
- Regex: plain POSIX `regcomp`. Darwin's `REG_ENHANCED` is not used, to
  keep Linux and Darwin identical.
- Darwin's native find (FreeBSD-derived) is BSD dialect for the bash
  function. It has `-E`, `-Bmin`, `-quit` and `-s`.

## Bash translator limits

Each of these exits 2 and names the binary:

- `-b` on GNU find (no birth time primary);
- `-m -a -c` counted in seconds that are not whole minutes (the native
  find counts minutes);
- `-r` back-references under `-E` (the translator wraps the pattern in a
  group to make it unanchored);
- `-v` combined with `-f`, `-x`, `-j` or `-delete`;
- `-S` combined with `-x`, `-j`, `-delete` or `-q` on GNU find, which has
  no sorted walk. Plain `-S` output is emulated there by sorting each
  operand's paths with `/` as the lowest byte.

A path operand beginning with `-` also exits 2.

## Verified

- `make test` passes, 219 cases, under GNU make on Linux (glibc 2.39): gcc
  and clang, a gcc build with ASan and UBSan, and as root and non-root.
  Root skips the unreadable-directory case. gcc and clang compile ff.c
  clean under `-Werror`, including a syntax check of the Darwin branch.
- The walk matches GNU find 4.9 on each primary it shares.
- Not yet run under bmake, on NetBSD, or on Darwin. The makefile avoids
  every construct bmake rejects, but it is unverified there, as are the
  BSD branches of `ff.fn.bash`.

See `PLAN.md` for the design record and the decisions log.

## History

```
org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
    owned openat walker with dev/ino verification; one-letter grammar;
    -x execdir, -j exec, -delete through the verified parent; getent ids
    on Linux; tty escaping; status bitmask; chkerr/chkwrn diagnostics;
    bash translator ff.fn.bash for the native find
```
