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
test suite runs its cases through both implementations and checks them
against each other.

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
primary's argument. Primaries are lowercase, or the digits 0 and 1.

| option | find | |
|--------|------|-|
| `-E` | `-E` | ERE for `-r` (default BRE) |
| `-I` | `-iname` `-ipath` `-iregex` | case-insensitive `-n -p -r` |
| `-H` `-L` | `-H` `-L` | symlink policy |
| `-D` | `-d` / `-depth` | post-order |
| `-S` | `-s` | sorted walk |
| `-X` | `-x` / `-xdev` | one filesystem |
| `-Z` | `-print0` | NUL-terminated names |
| `-V` | | bash function: print the native find command to stderr |

| primary | find | ff semantics |
|---------|------|--------------|
| `-n glob` | `-name` | |
| `-p glob` | `-path` | |
| `-r re` | `-regex` | **unanchored**; add `^` `$` |
| `-t fdlpsbc` | `-type` | several letters mean or |
| `-d [+-]N` | `-mindepth` `-maxdepth` | global walk bound |
| `-s [+-]N[ckMGT]` | `-size` | bytes, exact, no rounding |
| `-m -a -c -b [+-]N[smhdw]` | `-mtime` ... `-Btime` | age in seconds; default unit d |
| `-w [+-][ ]([.][.]/file\|HEX)` | `-newer` | when: after, before or at; see below |
| `-y file` | `-samefile` | same device and inode |
| `-k [+-]mode` | `-perm` | a query, see below |
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

The primaries `-0` and `-1` are read as true and false.

`-k` asks about permission bits rather than doing chmod arithmetic, and
its `+` and `-` keep ff's sense of more and less:

- Octal: `0755` exactly; `+0755` at least (every bit, maybe more, find
  `-perm -0755`); `-0755` at most (no bit outside it).
- Symbolic: clauses `[ugoa][+-][rwxXst]` joined by commas, all required;
  `+` has, `-` lacks, no sign means `+`. Named classes must each satisfy a
  clause; with no class, `+x` means someone may execute and `-x` no one
  may. `X` is execute that only a directory satisfies, `s` setuid (`u`) or
  setgid (`g`), `t` the sticky bit. With no class, each class is tested
  with only the bits it can hold, so `-k +rs` holds for a 0644 file
  (other has `r` and can hold no `s`); `-k u+rs` needs both in one class.

```
ff . -t f -k o+w        world-writable files
ff . -k +s              setuid or setgid
ff . -not -k go-w       group or other may write
ff . -k o-X             directories others may not search
```

`-x` or `-j`: `-j` passes the full path, and the child looks every
component up again, so a directory swapped for a symlink after ff checked
it redirects the command. That is the classic find `-exec` race. `-x`
changes into the directory ff already opened and verified, then passes
`./name`, so only the last component is resolved again. `-x` refuses to run
when `PATH` holds a relative or empty element, since the working directory
is the walked one. `-delete` removes through the same verified parent
descriptor.

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
  native find writes its own).
- It passes under GNU make on Linux (glibc 2.39, GNU find 4.9, bash 5.2):
  586 cases non-root, 582 as root, which skips the unreadable-directory
  cases; with gcc and clang, and a gcc build with ASan and UBSan; again
  with `TMPDIR` behind a symlink, as Darwin's `/tmp` is. gcc and clang
  compile ff.c clean under `-Werror -Wpedantic`.
- The walk matches GNU find 4.9 on each primary it shares.
- Darwin (arm64, Apple clang): builds clean. The `make test` of rev
  6abb42b9 failed 4 of 325. Two came from `/tmp` being a symlink to
  `/private/tmp`: `-x pwd` prints the physical path, and test.sh now works
  in `pwd -P`. Two were BSD `-execdir` passing bare names to the bash
  function, which now adds `./` (see Bash translator limits). The first
  was reproduced on Linux with a symlinked `TMPDIR`; the second is
  exercised on Linux only through `FF_BARE_EXECDIR`, since GNU find cannot
  give bare names. The Darwin re-run of rev 6abc5da8 is pending.
- Not yet run under bmake or on NetBSD. The makefile avoids every
  construct bmake rejects, but it is unverified there.

See `PLAN.md` for the design record and the decisions log.

## History

```
rev 6abc5da8 20260929 175400 PDT Tue 05:54 PM 29 Sep 2026
    -0 true and -1 false replace -true -false; -Z NUL output (was -0);
    -y replaces -same; -w [+-][ ]([.][.]/file|HEX): the sign may stand
    apart; -delete is a long switch to confirm; ff.fn.bash gives -x
    ./name where BSD -execdir passes a bare name; test.sh in the
    physical work directory (Darwin /tmp is /private/tmp)
rev 6abb42b9 20260928 214649 PDT Mon 09:46 PM 28 Sep 2026
    -w when [+-]([.][.]/file|HEX): before, after or at a file's mtime or a
    hex epoch second, a file taking ./ ../ or /; -same, -true, -false;
    -i reads hex; -V shows the native find command, reference files where
    find lacks -newermt; grouped examples; Darwin test fixes
rev 6ab89f43 20260926 214451 PDT Sat 09:44 PM 26 Sep 2026
    -k permission query: octal exact, +mode at least, -mode at most;
    symbolic clauses + has, - lacks, with X s t; -not; diagnostics that
    state a rule end in "not" before the rejected value
org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
    owned openat walker with dev/ino verification; one-letter grammar;
    -x execdir, -j exec, -delete through the verified parent; getent ids
    on Linux; tty escaping; status bitmask; chkerr/chkwrn diagnostics;
    bash translator ff.fn.bash for the native find
```

## Copyright

(c) 2026 George Georgalis <george@iuxta.com>
Unlimited use with attribution.
