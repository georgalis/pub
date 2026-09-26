# cksh

Sortable stat and SHAKE256 listing of files: one line per file, numbers in
lowercase hex, fields at fixed positions.

```
inode    links hash   size     mdate    name
  1cc01d  1 483366        3 5e0bd2c0 t/a
```

Two implementations with byte-identical output and exit status:

- `cksh` --- C99 binary, no dependency beyond libc. SHAKE256 (FIPS 202) is
  built in, so every hash length from 1 to 64 works on every host, with or
  without OpenSSL.
- `cksh.fn.bash` --- bash function for hosts that cannot compile or run
  binaries. It uses `openssl shake256` and prefers `$LOCALBASE/bin/openssl`
  (pkgsrc) over the one on `PATH`.

## Build

```
make            # ./cksh and ./cksh.1 (man page generated from --help)
make test       # regression suite, test.sh
make install    # PREFIX defaults to $LOCALBASE (pkgsrc), else /usr/local
make CC=$LOCALBASE/bin/gcc
```

The makefile uses only the constructs shared by GNU make, bmake, and Apple
make. It installs `bin/cksh`, `man1/cksh.1` (under `share/man` when present,
else `man`), and `share/cksh/cksh.fn.bash`.

Linking by platform:

- Linux and NetBSD: `-static`, falling back to dynamic linking when no
  static libc is installed.
- Darwin: dynamic, against libSystem only. Apple ships no static libSystem,
  so this is as far as linking can go there. Nothing from pkgsrc or Homebrew
  is needed at run time.

## Usage

`cksh -h` prints a short summary and `cksh --help` the full manual. The bash
function takes the same options; load it with `. cksh.fn.bash`.

```
cksh -k5 *                   sort by modification time, oldest first
cksh -rk5 *                  newest first
find . -type f | cksh -k3    group identical content by hash
cksh -x 32 -n 0 file         full 256 bit digest, with inode and links
```

Sort grammar: `[-k|-rk|-kr][ ][N]`, where N is 1-6 and a bare `-k` means 6.
Sorting is bytewise, the same as `LC_ALL=C sort [-r] -k N`. `-r` without
`-k` reverses input order. Without `-k` or `-r`, lines stream as they are
produced.

## OpenSSL older than 3.0

`openssl shake256 -xoflen` first appeared in OpenSSL 3.0. Older OpenSSL
(1.1.1, as on RHEL 8) prints a fixed 32 byte digest. SHAKE256 is an
extendable output function, so the first L bytes of a longer digest equal
the L byte digest. The bash function therefore truncates the 32 byte output
and gets exactly what `-xoflen L` would give, for any L up to 32.

- Asking for more than 32 bytes fails with status 2.
- LibreSSL (Darwin's `/usr/bin/openssl`) has no SHAKE256 at all, and also
  fails with status 2.
- Before hashing anything, the function checks the selected openssl against
  the known SHAKE256 digest of empty input.

The C binary needs none of this.

## Exit status

A bitmask. Statuses 1 and 2 are fatal. The others accumulate while the run
continues.

| bit | meaning |
|----:|---------|
| 1 | invalid option or argument |
| 2 | environment: memory, stdin/stdout failure, no usable openssl (bash) |
| 4 | cannot stat a name; line skipped |
| 8 | cannot open or read a regular file; line skipped |
| 16 | fifo, socket or device; warned, never opened, hash zeros |
| 32 | dangling symlink; warned, hash zeros |

## Changes from bash rev 68e9ff40

- Directories and other nodes that are not hashed show a zero-filled hash;
  previously the column was blank-padded.
- Fifos get a warning and are never opened; previously the run blocked on
  them.
- Per-file errors warn and the run continues; previously the first error
  aborted the run.
- The exit status is the bitmask above instead of 0 or 1.
- `ls -F` indicators come from `lstat`, so a file whose name ends in `*` or
  `%` keeps that character; previously `sed` stripped it.
- `stdin` lines are read raw (`read -r`), so backslashes in names survive.
- Numbers are formatted by `printf` in the shell, not by `awk`, which avoids
  `awk` double-precision limits on large sizes and inodes.

## Limits

- Names are read one per line, so a name containing a newline can be passed
  as an argument but not on stdin.
- Hex widths are minimums. A value wider than its column sorts out of order
  under `-k`. mdate fits its column until 2106.
- The test suite passes under GNU make with gcc and clang, with ASan and
  UBSan, and as root and non-root, on Linux. The makefile avoids every
  construct bmake rejects, but it has not yet been run under bmake, on
  NetBSD, or on Darwin.
