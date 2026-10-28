# rrcs --- plan of record

<!-- rev 6ae1747d 20261027 210517 PDT Tue 09:05 PM 27 Oct 2026 initial release -->
<!-- org 668d8a0d 20240709 120549 PDT Tue 12:05 PM 09 Jul 2024 _rcs in sub/fn.bash, https://github.com/georgalis/pub/commit/73f56ac9fe309ab6aac250d78079ab9bba2e9531 -->

<!--contents 2 3 pre="## Contents" post="---"-->

## Objective and scope

`rrcs` (re-rcs) records revisions of files without leaving any change
on the files being recorded. Each working file gets its original inode
back after `ci`, and with it the owner, mode, mtime, ACLs, extended
attributes and security label. The only file that keeps a change is
the `,v` file. Its mtime is then set to the working file's mtime, so
that equal mtimes suggest the file and its `,v` are concurrent. This
status check is meant for one person keeping their own account of
their files; it is not an integrity control.

The build has two parts, delivered in one file, `rrcs.fn.bash`:

1. **rrcs** --- the wrapper, running on the installed RCS binaries.
   Two implementations are targeted, both packaged in pkgsrc:
   OpenRCS 4.5, the OpenBSD project's RCS clone (`devel/openrcs`),
   installed on the Darwin host and verified there; and GNU RCS 5.9.4
   (`devel/rcs`), still to be verified.
2. **The emulation** --- bash functions named `ci`, `co`, `rlog` and
   `rcsdiff`, defined only when the binaries are missing. They
   implement the trunk-only subset that `rrcs` needs and write `,v`
   files that real RCS can read.

`rrcs` descends from `_rcs` in `sub/fn.bash` (9 Jul 2024)[^4], later
`mrcs`. Alongside the function file: `test-rrcs.sh` (the regression
suite), `probe-rrcs.sh` (the keep-link probe for a given RCS build),
and a `makefile` (`make`, `make test`, `make probe`,
`make install [PREFIX=dir]`). The makefile installs
`share/rrcs/rrcs.fn.bash` and an `rrcs.1` man page derived from
`rrcs --help`, so the two cannot disagree.

## Interface

```
rrcs [-q] [-m msg]... [-e] [-i] [--] path ...   check in (one path, or -i: also untracked)
rrcs -R [-q] [-m msg]... [--] old new           rename a working file and its ,v together
rrcs -s [--] path ...                           status: mtime first, rcsdiff where they differ
rrcs -S [--] path ...                           status: rcsdiff on every tracked file
rrcs -h                                         brief usage
rrcs --help [ci|co|rlog|rcsdiff|more]           extended usage, paged when stdout is a tty
```

| Option | Effect |
|--------|--------|
| `-m msg` | Message lines added after the log header; may be repeated |
| `-e` | Write the message in `${VISUAL:-${EDITOR:-vi}}`; requires a terminal; any `-m` text starts the message |
| `-i` | Initial check-in: create a `,v` for every untracked path given, however many; an error if one already exists. A single path needs no `-i` |
| `-q` | Suppress the per-file result lines |

With neither `-m` nor `-e`, the log is the header line alone. No
editor ever opens unless `-e` is given.

**Exit status:** `0` when every operation succeeded, `1` when any
check-in, rename or status read failed, `2` for a usage error.
Skipped arguments (see below) produce warnings but do not count as
failures. Result lines go to stdout; warnings and errors go to stderr
through `chkwrn` and `chkerr`, defined inside the function together
with `stderr` and `chkstd`.

The body is a subshell, `rrcs () ( ... )`. The helpers, `OPTIND` and
the temp-cleanup `EXIT` trap are private to each call.

## Resolving arguments

Every argument is turned into a pair: a working file and its `,v`. The
user may name either one, so a status glob such as `rrcs -s * RCS/*,v`
can mix working files, `,v` files and untracked files. All of them
resolve to the same pairs.

1. **A `,v` path names its working file.** `dir/RCS/x,v` means
   `dir/x`, and `dir/x,v` means `dir/x`.
2. **A working-file path finds its `,v`.** That is `dir/RCS/x,v` if
   `dir/RCS` exists, otherwise `dir/x,v`. A suffix set through
   `RCSINIT -x` is not honored.
3. **Duplicates collapse.** `x` and `RCS/x,v` given together are
   handled once, in the order first given.
4. **Each pair is classified:**
   - **tracked** --- the `,v` exists;
   - **untracked** --- a regular file with no `,v`;
   - **orphan** --- a `,v` whose working file is missing;
   - **skipped** --- anything else: directories, symlinks, special
     files, the `.rrcs.*` scratch directories. Each gets a warning,
     except an `RCS` directory, which is skipped quietly so that
     `rrcs *` stays readable.
5. **What a check-in does with each class:**
   - tracked files are checked in;
   - an untracked file named alone (`rrcs newfile`) is checked in:
     a single path is taken as deliberate. With more than one path,
     untracked files are checked in only with `-i`; without it, each
     gets a warning naming `-i`. A shell expands a glob before `rrcs`
     runs, so the argument count is the only signal available: `rrcs *`
     over a mixed directory then commits only what is already tracked;
   - orphans get a warning.

**File names.** A name outside the portable set `[A-Za-z0-9._,+@%:=/-]`
(spaces, quotes, glob characters, non-ASCII) gets a warning and is
still processed, since every expansion is quoted. A name containing a
newline or another control character is refused, because it would
break both the one-line-per-file output and the log header. A name
beginning with `-` is passed to RCS as `./name`.

## Check-in sequence

1. **Resolve and classify every argument** before anything is
   committed. Usage errors and refused names stop the call here.
2. **Skip unchanged files.** If `rcsdiff -q` reports no difference,
   no revision is made and the `,v` mtime is updated to match the
   working file. Content that matches the latest revision counts as
   committed.
3. **Build the message once** for the whole call:
   - the header `rrcs <path as given>[ (sudo:$SUDO_USER)]`, one per
     pair;
   - the `-m` lines;
   - or the `-e` editor text, with `#` lines and everything below
     the scissors line removed. An empty `-e` message aborts the
     call with exit `1` and commits nothing.
4. **Hold the original with a keep link, then check in normally:**
   - `mktemp "$dir/.rrcs.XXXXXX"` in the working file's directory
     serves as the time reference (`touch -r work`), and the mode is
     saved; then `ln -f -- work "$dir/.rrcs.$id.k"` makes the keep
     link, a second name for the original inode in the same directory,
     so it is always on the same filesystem;
   - `( cd "$dir" && ci -l -q [-t-rrcs] -m"$log" ./base ) </dev/null`,
     an ordinary check-in with the ordinary `,v` lookup, so it works
     with `,v` under `RCS/` or beside the file, and with both RCS
     implementations; the `./` prefix keeps a name such as `-x` from
     reading as an option;
   - if the working file now has a different inode, `mv -f` the keep
     link back over it; if it has the same inode (an implementation
     that rewrites in place, or the emulation, which does not touch
     it), remove the keep link and restore mtime and mode from the
     reference. This runs on success, on failure, and from the `EXIT`
     trap on an interrupt.
   The keep link means the original inode never loses its last name.
   `ci` replaces the working file with a new one; the `mv` puts the
   original back. Its owner, mode, mtime, ACLs, extended attributes,
   security label and other hard links return together, because they
   are all properties of that inode. Only its ctime changes, because
   adding and removing a link counts as an inode change. If the
   filesystem refuses hard links, `rrcs` warns and uses the same
   mtime-and-mode restoration, which keeps those two but not the inode.
5. **After the first check-in only**, run `rcs -q -ko` on the new
   `,v`, so that `co` always returns the stored text exactly.
6. **Remove scratch files** by their literal class name:
   `rm -f -- "$dir/.rrcs.$id"`, in the `EXIT` trap as well.
7. **Copy the time:** `touch -c -r work "$vfile"`.[^3] The `-c` flag
   matters: without it, `touch -r` creates an empty `,v` when the
   check-in failed, and RCS later reports that file as corrupt.
8. **Limit who can read the `,v` to who can read the working file.**
   OpenRCS creates `,v` files with mode `0444` whatever the working
   file's mode is: a `0640` file got a world-readable history in the
   probe. And `ci` writes a new `,v` on every check-in, so its group
   is whatever the platform assigns new files: the directory's group
   on BSD and Darwin, or the creator's primary group on Linux unless
   the directory is setgid. After every check-in, `rrcs` does three
   things:
   - **Group.** `chgrp` the `,v` to the working file's numeric gid,
     taken from `ls -ln`.
   - **Mode.** Clear every permission bit on the `,v`, then add back
     read and execute for other exactly where the working file has
     them. The owner always keeps read, which RCS needs, plus execute
     where the working file has it. Execute bits are carried because
     RCS sets a checked-out file's execute bits from its `,v`.
   - **Group bits.** Add group read and execute (as the working file
     has them) only when the `chgrp` succeeded. When `rrcs` cannot set
     the group (the user is not a member of it), the `,v` keeps
     whatever group it got and that group has no permissions at all.
     A warning names the file and both gids.
   The ids and read bits come from `ls -ln`, so no platform-specific
   `stat` is needed. The same rule applies to every file `rrcs` or the
   emulation creates.
9. **Always feed `ci` from `/dev/null`.** If `ci` ever wants input,
   such as a description or a log message, the check-in fails visibly
   instead of hanging.

## Rename

`rrcs -R old new` moves the working file and its `,v` together, and
records the move in the history:

1. **Refusals.**
   - `old` must be tracked, and its status must be `C` or `T` (see the
     next section). Uncommitted changes must be checked in first, so a
     rename never carries edits into history under a rename message.
   - Neither `new` nor `new`'s `,v` may already exist.
   - If `new` is an existing directory, the base name of `old` is
     appended.
2. **Move.** `mv` the working file, then `mv` its `,v` to where `new`
   resolves it (`newdir/RCS/` if that exists, otherwise beside
   `new`). If the second move fails, the first is reversed.
3. **Record.** A forced keep-link check-in (`ci -f`) logs
   `rrcs -R <old> <new>`, plus any `-m` lines, so `rlog` shows the name
   change. Then `touch -c -r new "$newvfile"`.

On one filesystem, `mv` is a rename, so the working file keeps its
inode and mtime: the original is still untouched. Across filesystems
it is a copy, and `rrcs` warns.

## Commit status

`-s` uses mtime as a fast first test and `rcsdiff` to confirm wherever
the times disagree. `-S` runs `rcsdiff` on every tracked file. Output
is one line per pair, a mark followed by the working path, so `grep` and
`awk` can select from it:

| Mark | Meaning | How it is decided |
|------|---------|-------------------|
| `C` | committed | mtimes are equal (`-S`: content also matches) |
| `M` | modified since the last check-in | content differs, and the file is newer |
| `!` | differs, and the file is older than its `,v` | content differs; the file was likely restored or copied in |
| `T` | touched only | mtimes differ, content matches; `rrcs file` syncs the time |
| `?` | untracked | no `,v` |
| `-` | orphan | a `,v` with no working file |
| `E` | error | `rcsdiff` failed; counts toward exit `1` |

`-s` checks content only where the mtimes differ, so its cost grows
with what has changed rather than with the number of files. Its one
blind spot is content that changed while the mtime stayed equal: an
edit in the same second on a filesystem with one-second resolution, or
a copy that preserved an old mtime. `-S` closes that gap at the cost of
one checkout per file. Examples in `--help`:

```
rrcs -s * RCS/*,v          # one line per pair; working files and ,v files both resolve
rrcs -s * | grep -v '^?'   # tracked files only
rrcs -S *                  # full content check
```

## Help

- **`-h`** prints the synopsis and the option table.
- **`--help [topic]`** opens by expanding the name: rrcs stands for
  re-rcs. It explains the untouched-original model, mtime status and
  rename. The topics `ci`, `co`, `rlog` and `rcsdiff` each give
  explanations, usage and examples, and state which options the
  emulation supports; `more` covers the rest of the suite. Output goes
  through `${PAGER:-less}` when stdout is a terminal, falls back to
  `more`, then to `cat`, and is printed directly otherwise.
- **Upstream:** http://www.cs.purdue.edu/homes/trinkle/RCS/ [^2], with
  the GNU RCS manual as the option reference.[^1]
- **Keywords:** RCS keywords (`$Id$`, `$Log$` and the rest) are not
  supported; text is stored and returned exactly as written.
- **Corrections from `mrcs`:** `rlog -l` (who holds a lock) and `-w`
  (author) are described correctly, as is `ci -k` (reads keyword
  values from the working file). `rcsbind`, `rcsinfo`, `rcsparse` and
  `rcsrev` are removed, since they are not part of the suite.
- Each help topic is its own single-quoted here-document with its own
  `__RRCS_HELP_<TOPIC>__` delimiter.

## Emulation of the binaries

**Guard.** `command -v ci` is checked once, when the file is sourced.
If `ci` is missing, or `RRCS_EMULATE=1` is set, the emulation
functions `ci`, `co`, `rlog`, `rcsdiff` and `rcs` are defined, and
every message they print starts with `rrcs-emu:`. `rrcs` itself is
defined after them, so it works the same over either implementation.
`RRCS_EMULATE=1` is how the test suite runs the emulation beside real
RCS for the two-way check. The emulation stores only text it can
reproduce exactly: a working file must be empty or end with a newline,
and must contain no NUL bytes; anything else is refused with an error.
`RRCS_EMU_FULLDELTA=1` forces the full-replacement delta, for testing.

**Subset.**

| Function | Supported | Refused, with an error |
|----------|-----------|------------------------|
| `ci` | `-l` `-u` `-q` `-f` `-i` `-m` `-t-` `-tfile`, trunk only, `RCS/` lookup; never rewrites the working file | branches, `-r`, `-d`, `-k`, `-n`, `-N`, `-s`, `-w` |
| `co` | `-p` `-q` `-r` (trunk) | writing a working file, locking |
| `rlog` | header and revision list, `-h`, `-R`, `-r` | `-d`, `-s`, `-w`, `-l`, branches |
| `rcsdiff` | `[-q] [-r a [-r b]]` plus diff options: `co -p` piped into `diff` | as for `co` |
| `rcs` | `-q -ko` only (the emulation always writes `expand @o@`) | everything else |

**Format contract.** Files are written in the RCS `,v` format:

- the admin header: `head`, `access`, `symbols`, a `locks` entry with
  the user and `strict`, `comment`, and `expand @o@`;
- one delta node per revision, dated `YYYY.MM.DD.HH.MM.SS` in UTC;
- `desc`;
- delta texts, with every `@` inside a string doubled.

The newest revision is stored as full text, and each older revision
as a reverse edit script. The emulation produces that script with
`diff -n`, falling back to a delete-everything, add-everything script.
That fallback is still a valid RCS delta and always correct, just
larger. `co` applies the scripts with a short awk routine. When reading
a `,v` that contains branches or anything outside the subset, the
emulation refuses rather than guessing. `,v` files are written with the
shell skill's temp-file trio, so every write is an atomic rename.

**Why keywords make this tractable.** Without keyword expansion, `co`
only replays edit scripts and never rewrites text. The refusal that
`--help` announces is the same one that keeps the emulation small.

## Decisions and consequences

| Decision | Gains | Costs |
|----------|-------|-------|
| Keep link around an ordinary `ci` | The original inode returns with every attribute; `ci` runs as RCS expects in either layout and either implementation | ctime changes; a filesystem without hard links falls back to restoring only mtime and mode |
| `rcs -ko`, no keywords | Text comes back exactly as stored; the emulation stays tractable | `$Id$` habits stop working, as stated in `--help` |
| `,v` mtime set to the file's | Equal mtimes suggest concurrency; `-s` reads it cheaply | Tools that select by mtime alone miss new revisions (accepted) |
| `-s` checks mtime, then content where they differ | Speed in proportion to what changed; `T` separates touched from edited | Equal mtimes with changed content go unseen without `-S` |
| `,v` arguments resolve to working files | Globs over mixed directories just work | `RCSINIT -x` suffixes are not honored |
| One path is deliberate; several need `-i` for untracked files | `rrcs newfile` just works, as `mrcs` did; `rrcs *` cannot start tracking stray files | A glob that happens to match exactly one untracked file starts tracking it |
| Editor only with `-e` | No surprise editor; scripts never block | Composing a long message takes one extra flag |
| Rename only when status is `C` or `T`, recorded with `ci -f` | History shows each name; edits never ride along with a rename | One extra revision per rename |
| Unsafe names warn, control characters refuse | Real-world names still work; output stays one line per file | Names containing newlines cannot be tracked |
| `touch -c` after every check-in | A failed check-in never leaves an empty `,v` behind | None |
| `,v` group, read and execute bits follow the working file; a group `rrcs` cannot set gets no bits | History is never readable by more people than the file it records; execute survives a later `co` | One `chgrp` and one `chmod` per check-in; a non-member's history is readable only by its owner |
| An emulation subset that fails loudly | Works without RCS installed; `,v` files are readable both ways | Branches, merges and admin options need the real suite |

## Excluded

Branches, symbolic names, states, `rcsmerge`, `merge`, `ident`,
`rcsclean`, `rcsfreeze`, keyword expansion, `RCSINIT -x` suffixes,
creating the `RCS/` directory automatically, and locking among
multiple users.

## Verification

1. **Keep-link mechanism.** `probe-rrcs.sh` runs against each RCS
   implementation (OpenRCS 4.5 and GNU RCS 5.9.4). It tests both
   layouts (`,v` under `RCS/`, and `,v` beside the file), and checks:
   - initial, second and forced check-ins;
   - `rcs -ko`;
   - `rcsdiff -q` exit codes;
   - `co -p -r`;
   - `rlog -R`;
   - that the working file keeps its inode, its mode and its mtime,
     and that its mtime equals the `,v` mtime;
   - whether `ci` replaced the working file or rewrote it in place;
   - that no scratch file is left behind.
   **OpenRCS 4.5 passed every check in both layouts**, and `ci`
   replaced the working file each time, as the keep link assumes. GNU
   RCS 5.9.4 is still to be run on a host that has it. If it rewrites
   the working file in place, it takes the restoration fallback.
2. **`rrcs`**, tested by `test-rrcs.sh` over whichever `ci` is
   active. The suite covers:
   - both layouts: inode, mode and mtime kept, `,v` mtime equal, the
     `,v` mode and group following the file, `rcs -ko` set, and the
     log header and messages;
   - execute bits carried to the `,v`;
   - that when `chgrp` is refused, the `,v` group has no bits;
   - every status mark, over a glob mixing working files, `,v` files,
     untracked files and an orphan, with duplicates removed;
   - `-s` trusting equal mtimes, and `-S` finding a same-mtime change;
   - one untracked path tracked without `-i`, several skipped with a
     warning, `-i` tracking several, and `-i` on a tracked file failing;
   - names: spaces warn, a leading `-` works, control characters are
     refused, symlinks are skipped;
   - rename: refused while modified, moves the file and `,v` into a
     directory, keeps the inode, records the move, refuses to
     overwrite;
   - `-h`, every `--help` topic, an unknown topic, an unknown option,
     no arguments;
   - `-e`: refused without a terminal; under a pseudo-terminal, the
     message is kept with `#` lines removed, and an empty message
     aborts.
   **The suite passes on the Darwin host against OpenRCS 4.5, and with
   `RRCS_EMULATE=1` under the host's awk, two-way check included.** In
   the build workspace (no RCS binaries) all 75 checks pass under the
   emulation. The keep link's move-back path was also exercised with a
   `ci` that replaces the working file: inode and mode `0604` were kept.
   GNU RCS 5.9.4 is still to be run where it is available.
3. **The emulation**, tested both ways by `test-rrcs.sh` wherever real
   RCS is installed: `,v` files written by the emulation must read
   correctly with the real `rlog` and `co -p`, and `,v` files written
   by the real `ci` must read correctly with the emulated `co -p`. A
   round trip of six revisions, including `@` characters, passes here
   under both the `diff -n` and the full-replacement delta.
4. **Shell-skill review:**
   - every `rm` names a literal class;
   - every here-document delimiter is unique and quoted;
   - every `touch` of a `,v` uses `-c`;
   - every `ci` reads from `/dev/null`.

## Three abstentions, one clock

The design rests on three things `rrcs` declines to do:

- **It does not let `ci` keep the original.** The keep link holds the
  inode while `ci` works, then puts it back, so no attribute needs
  restoring one by one.
- **It does not expand keywords**, so stored text is returned exactly
  as written, and the emulation only has to replay edits.
- **It does not branch**, so history is a single line that bash can
  write correctly.

The same restraint carries into the new features. A rename moves the
file but does not edit it. The status check reads times and opens
content only where the times disagree. The one thing `rrcs` does write
is the `,v` mtime, and it copies that from the original instead of
inventing a new one. When the two times agree, the file and its
history are concurrent.

[^1]: GNU RCS manual: `ci`, `co`, `rlog`, `rcsdiff`, `rcs -ko`, and the
    `,v` file format. https://www.gnu.org/software/rcs/manual/
[^2]: RCS upstream, Walter F. Tichy, Purdue University. http://www.cs.purdue.edu/homes/trinkle/RCS/
[^3]: POSIX `touch`, options `-c` and `-r`. https://pubs.opengroup.org/onlinepubs/9699919799/utilities/touch.html
[^4]: Origin: `_rcs`, "init _rcs and rev lacktone", sub/fn.bash. https://github.com/georgalis/pub/commit/73f56ac9fe309ab6aac250d78079ab9bba2e9531
