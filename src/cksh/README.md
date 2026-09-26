# cksh

Sortable stat and SHAKE256 listing of files: one line per file, numbers in
lowercase hex, padded so the data aligns in columns.

```
$ cksh -n0 t/*
   inode lk hash       size    mdate name
  1cc01d  1 483366        3 5e0bd2c0 t/a
  1cc01c  2 000000     1000 5e0bd2c0 t/d/
  1cc01f  1 483366        1 5e0bd2c0 t/l@
  1cc021  1 c85112        1 5e0bd2c0 t/sp ace

$ cksh t/*                     default -n 2: inode and links omitted
. . 483366        3 5e0bd2c0 t/a
. . 000000     1000 5e0bd2c0 t/d/
```

The header line is shown here for reference; cksh does not print it.

| field | format | content |
|-------|--------|---------|
| 1 inode | `%8x` | inode of the node itself (not followed) |
| 2 lk | `%2x` | hard link count |
| 3 hash | 2*LEN hex | SHAKE256 of the content; zeros for directories and nodes that are not hashed |
| 4 size | `%8x` | bytes (a symlink reports its own size) |
| 5 mdate | `%08x` | modification time, unix seconds |
| 6 name | text | as given, plus `/` dir, `@` symlink, `\|` fifo, `=` socket |

An omitted field prints as `.`, so field numbers never shift. A value wider
than its column (a size of 4 GiB or more, an mdate after 2106) shifts the
rest of that one line. The fields stay space separated, so `awk '{print $4}'`
and `-k 4` still find the right value, and `-k` compares numbers by value.

Two implementations with byte-identical output and exit status:

- `cksh` --- C99 binary, no dependency beyond libc. SHAKE256 (FIPS 202) is
  built in, so every hash length from 1 to 64 works on every host.
- `cksh.fn.bash` --- bash function for hosts that cannot compile or run
  binaries. It uses `openssl shake256` and prefers `$LOCALBASE/bin/openssl`
  (pkgsrc) over the one on `PATH`. Its body runs in a subshell, so its
  helper functions never enter the caller's shell. Sourcing the file defines
  `cksh` and nothing else.

## Build

```
make            # ./cksh and ./cksh.1 (man page generated from --help)
make test       # regression suite, test.sh
make install    # PREFIX: /usr/local for root, $HOME otherwise
make install PREFIX=/opt/cksh DESTDIR=/tmp/stage
```

The makefile uses only the constructs shared by GNU make, bmake, and Apple
make. It installs `bin/cksh`, `man1/cksh.1` (under `share/man` when present,
else `man`), and `share/cksh/cksh.fn.bash`. `$LOCALBASE` is consulted only
to find dependencies, never as an install target.

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
cksh -3 -k4 *                sizes, smallest first
cksh -x 32 -n 0 file         full 256 bit digest, with inode and links
```

Sort grammar: `[-k|-rk|-kr][ ][N]`, where N is 1-6 and a bare `-k` means 6.
Lines are ordered by field N, then by the fields after it, then by name. Hex
numbers compare by value. The hash and the name compare bytewise, as under
`LC_ALL=C`, and an omitted field compares equal. `-r` without `-k` reverses
input order. Without `-k` or `-r`, lines stream as they are produced.

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

## Diagnostics and exit status

Messages go to stderr in the format of the shell `chkerr` and `chkwrn`
functions, each ending in a hex tag that names the message:

```
>>> cksh : cannot stat 't/nope' (6ab75465)
^^^ cksh : fifo, not hashed 't/p' (6ab75468)
```

The C binary also gives the system's reason, for example
`'t/nope': No such file or directory`.

The exit status is a bitmask. Statuses 1 and 2 are fatal. The others
accumulate while the run continues.

| bit | meaning |
|----:|---------|
| 1 | invalid option or argument |
| 2 | environment: memory, stdin/stdout failure, no usable openssl (bash) |
| 4 | cannot stat a name; line skipped |
| 8 | cannot open or read a regular file; line skipped |
| 16 | fifo, socket or device; warned, never opened, hash zeros |
| 32 | dangling symlink; warned, hash zeros |

## Limits

- Names are read one per line, so a name containing a newline can be passed
  as an argument but not on stdin.
- On Linux the test suite passes under GNU make with gcc and clang, with
  ASan and UBSan, and as root and non-root. The makefile avoids every
  construct bmake rejects, but it has not yet been run under bmake, on
  NetBSD, or on Darwin.

## History

```
rev 6ab7e734 20260926 083932 PDT Sat 08:39 AM 26 Sep 2026
    C port with built-in SHAKE256; openssl<3 xoflen fallback in the bash
    function; -k/-r value sort; --help manual; status bitmask;
    chkerr/chkwrn diagnostics; bash helpers isolated in a subshell
rev 68e9ff40 20251010 235456 PDT Fri 11:54 PM 10 Oct 2025
    -0..-5, bare -n and -x (getopts :), -n and -x range validation
rev 68e20bca 20251004 231018 PDT Sat 11:10 PM 04 Oct 2025
    renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired
rev 677c9c44 20250106 191516 PST Mon 07:15 PM 06 Jan 2025
    chksthash, from ckstatsum: shake256 -xoflen 3 hash column
org 6305e87b 20220824 015939 PDT Wed 01:59 AM 24 Aug 2022
    ckstat ckstatsum cks
```

Changes in 6ab7e734 from bash rev 68e9ff40:

- Directories and other nodes that are not hashed show a zero-filled hash;
  previously the column was blank-padded.
- Fifos get a warning and are never opened; previously the run blocked on
  them.
- Per-file errors warn and the run continues; previously the first error
  aborted the run.
- The exit status is a bitmask instead of 0 or 1.
- `ls -F` indicators come from `lstat`, so a file whose name ends in `*` or
  `%` keeps that character; previously `sed` stripped it.
- Names on stdin are read raw (`read -r`), so backslashes survive.
- Numbers are formatted by `printf` in the shell rather than by `awk`, which
  avoids `awk`'s double-precision limit on large sizes and inodes.
- Sorting (`-k`, `-r`) is built in, replacing `| sort -k5`.

## Copyright

(c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with
attribution.
