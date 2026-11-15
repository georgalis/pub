# srt plan

srt: a sort for system operators. One interface on Linux, Darwin and
NetBSD, delivered as C99 source (`srt.c`) and a bash function
(`srt.fn.bash`).

This plan drives the package revisions. It was written before any
code, as the instrument for verifying intent, and it remains the
record. Items marked **V** (section 2) began as ambiguities with a
proposed default; nothing downstream of an unconfirmed V item was
built until it was confirmed. Decisions are recorded in section 12,
the affected sections are revised in place, and section 13 holds the
status of each revision as built.

    revision 6af8a908 20261114 103136 PST Sat --- r0.6: V19 built (-x); V20 last column; V21 -D duplicates; V22 bare -k, -k-N, reverse spellings; key grammar shared with the listing tools
    revision 6af889a5 20261114 081741 PST Sat --- r0.5.1: Darwin r0.5 report; -S with -u test corrected; V19 opened (-x hex numeric); title and header order
    revision 6af87ca7 20261114 072215 PST Sat --- r0.5: key encoding built; radix measured and declined; V18 decided and built; Darwin r0.4.2 verified
    revision 6af871c9 20261114 063553 PST Sat --- r0.4.2: owned IPv6 parser (V09 reversal) after Darwin report; V18 opened (--fn, --bin)
    revision 6af86b89 20261114 060913 PST Sat --- r0.4.1: srt.fn.bash is one enclosing function; nothing else is defined
    revision 6af82211 20261114 005545 PST Sat --- r0.4 built (srt.fn.bash); V01 as built; V17 function gap settled; Darwin r0.3 verified
    revision 6af81dc6 20261114 003726 PST Sat --- r0.3 built (-b outline sort); V03 points settled in build recorded; Darwin r0.2 verified
    revision 6af81a46 20261114 002230 PST Sat --- V04 replace rule confirmed; r0.2 built; section 7 revised (partition, single spill file); Darwin r0.1 verified
    revision 6af802ae 20261113 224150 PST Fri --- V03 derived rules, V09 amendment, V17 confirmed; r0.1 built, section 13 added
    revision 6af7fd44 20261113 221844 PST Fri --- V04-V16 decided; V03 indent identity; --mem suffixes; V09 amended (open); V17 -g -H (open); r0.N sequence
    revision 6af7f0fc 20261113 212620 PST Fri --- V01 V02 V03 V05 V07 decided; -i retained; V14 reopened; V16 added
    original 6af7ebdf 20261113 210431 PST Fri --- initial plan, pre-code

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

<!--contents 2 3 pre="## Contents" post="---"-->

## 1 Purpose and scope

srt replaces the three native sorts with one grammar whose ordinary
case is the operator's ordinary case: column-ordered keys (`-k5,3`
reads "column 5, then column 3, then the rest"), stable by default,
byte-deterministic across hosts, and safe on inputs larger than
memory.

In scope: text records, column keys, the five ordering options, check
mode, unique, shuffle, indentation-block sort, external spill.

Out of scope, by requirement: character-offset sub-keys (`-k2.3`),
key ranges (`-k2,4` as "fields 2 through 4"), and the obsolescent
`+pos -pos` form.

Not a drop-in for `sort(1)`. Several letters keep their name and change
their meaning (section 4); a script written for native sort must not be
pointed at srt unexamined.

## 2 Intent verification

Each item states the ambiguity, the readings, and the proposed default.

**V01 Role of srt.fn.bash.** DECIDED: (a) as proposed. Readings: (a) translator --- the same
grammar executed through native `sort` and POSIX `awk` where the binary
is absent, after the ff precedent; (b) thin wrapper that locates and
calls the binary; (c) independent pure-bash implementation.
Proposed: (a). Mechanism is decorate-sort-undecorate: awk emits the key
columns in key order as a prefix, `LC_ALL=C sort -s` orders it, the
prefix is cut. Consequences to accept: the function inherits native
memory behavior; `-b` under reading V03(B) is binary-only (the function
refuses it with a diagnostic rather than approximating); a function
named `srt` shadows a binary named `srt` in the same shell, so the
function either carries a distinct name or defers to the binary when
one is on PATH. Proposed: defer to the binary when present.

As built at r0.4 (20261114): the awk pass does more than reorder
columns. It encodes every key --- bytes, `d`, `f`, `i`, `n`, `g`, `H`,
`v` with all three refinements --- into a string whose byte order is
srt order, and the native sort is asked only to compare bytes, stably,
field by field (`sort -s -t ... -k N,N[r]`). No native ordering option
is used, so the function owes nothing to which sort a host has; `-u`
and `-c` are done in awk for the same reason. Records are padded to
the widest column count so that a missing column and an empty one are
the same key, as in the binary. Since r0.4.1 the file defines one name:
everything else is inside `srt` (see section 13). `SRT_FN=1` keeps the function when a
binary is on PATH. What the function declines is listed in `--help`,
section BASH FUNCTION, which the binary and the function share.

**V02 -c and -C polarity.** DECIDED: POSIX convention --- `-c` checks
and reports, `-C` checks silently.[^1][^3] This reverses the initial
request (`-c` silent, `-C` verbose) and removes both letters from the
changed-meaning table of section 4. The report's form is V14.

**V03 -b, --respect-blanks.** In every native, `-b` *ignores* leading
blanks.[^1][^3] Here it means the reverse family. Readings:
(A) leading blanks are significant bytes in comparison, nothing more;
(B) outline sort --- a line owns the more-deeply-indented lines that
follow it; siblings at each depth are sorted, each parent travels with
its subtree, recursively;
(C) each contiguous run of equally indented lines is sorted in place,
runs never mix.
DECIDED: (B), outline sort, with indent identity: an indent is the
exact byte string of leading spaces and tabs. Spaces and tabs may be
mixed freely, but they never correlate --- no tab expansion, no width;
two indents are the same only when byte-identical. Blank lines attach
to the preceding block.

Derived from that decision (confirmed 20261113):
- Parentage: a line is the child of the nearest preceding line whose
  indent is a proper prefix of its own. A line with no such
  predecessor is top-level.
- Sibling group: children of one parent that share a byte-identical
  indent. Only a group is sorted. Children of one parent with
  different indents (a tab-indented child and a space-indented child)
  form separate groups, and groups keep their input order.
- Consequence: `<TAB>x` is not a child of `<SP><SP>y`, whatever an
  editor displays.

Settled while building r0.3 (20261114); each is the plan's reading of
a point the decision left open, stated in `--help` and pinned by
tests, and each can be amended:
- "Nearest preceding" is read with block closure: a line closes every
  open block whose indent it does not extend, and a closed block is
  not reopened. In `A`, `  z`, `<TAB>C`, `    D` the line `D` is a
  child of `A`, not of `z`, because `<TAB>C` closed `z`. The literal
  reading would lift `D` above `C` without any sort having asked.
- A group is all children of one parent with the same indent, whether
  or not other-indent siblings lie between them; groups are written in
  order of first appearance.
- Blank lines (empty, or only blanks) are not sorted. Each stays
  directly below the line it follows and moves with it; leading blank
  lines stay first.
- `-u` under `-b` removes an equal sibling only when it is a leaf with
  no blank line after it. A line carrying a block is always kept, so
  `-u` never discards lines it did not compare.
- `-c`/`-C` under `-b` require every group to be in order and report
  the first out-of-order line by input position.
- Several inputs form one outline, in operand order.

**V04 -k grammar.** DECIDED:
- `-k5,3` and `-k5 -k3` are identical; keys accumulate left to right.
- Per-key options are letters appended to a column: `-k5n,3fr`.
  Permitted letters: `d f g H i n r v`.
- Letters on a column replace the global set for that column; they are
  never added to it. `-n -k1r` gives column 1 the set `{r}` alone, so
  it sorts as reversed text, and reversed numeric is `-k1nr`. This is
  the operator's original requirement and the rule of sort(1).
  Confirmed 20261114 after an additive alternative was put forward
  and declined; `--help` section GLOBAL AND KEY OPTIONS carries the
  explanation.
- A column named twice is an error (it is almost always native-sort
  habit, `-k2,2`, and silently accepting it hides the difference).
- Column 0 and non-numeric columns are errors.
- A line with fewer columns than a key names has an empty key there;
  empty sorts before non-empty.
- After the named columns, the remaining columns compare left to right
  in natural order under the global options. With six columns, `-k5,3`
  orders by 5,3,1,2,4,6 (amended by V20: as written this now holds for
  `-k5n,3`; with column 5 as text, 5 and 6 are one key).

**V05 -u scope.** Because the remaining columns always participate,
two lines are "equal" only when every column compares equal under the
options in force. `-u` therefore removes whole-line duplicates (modulo
`-f`, `-d`, `-n` equivalence), keeping the first by input order. The
native ability "one line per distinct key column" is lost. DECIDED:
`-u` removes whole-line duplicates only. No `--unique-key` is planned.

**V06 Default column separation.** Without `-t`: POSIX splits at the
blank-to-non-blank transition and keeps leading blanks inside the
field; awk splits on blank runs and drops them. DECIDED: awk rule
(space and tab only). With `-t char`: every occurrence separates and
empty columns exist. `char` is one byte; `\t` and `\0` are accepted
escapes; multi-byte separators are an error.

**V07 -S and the memory control.** `-S` here follows NetBSD ("don't use
stable sort")[^1]; in the GNU and FreeBSD-derived sorts `-S` is the
memory size.[^2][^3] That leaves the memory budget without a letter.
DECIDED: automatic budget (section 7) with override by environment
variable `SRT_MEM` and long option `--mem size` only. `size` is an
integer N with an optional suffix: `b` bytes (the default), `k`
kibibytes, `m` mebibytes, `g` gibibytes; powers of 1024. Under `-S` the
binary may choose a faster unstable algorithm; output order among
equal lines is then unspecified.

**V08 -R interplay.** `-R` is a uniform shuffle of the output records,
not the native "random hash of keys" that groups equal keys.[^3]
DECIDED: `-R` with any of `-k -d -f -g -H -i -n -r -v -b -c -C` is an
error;
`-R -u` removes byte-identical lines, then shuffles; `-t` is ignored.
Entropy from `/dev/urandom` on all three platforms, one owned path.

**V09 -v definition.** Native version sort (`-V`) carries
special cases for suffixes and `~`.[^3] NetBSD has no version sort at
all.[^1] DECIDED in base: an owned natural order --- maximal digit
runs compare by numeric value at any length (leading zeros ignored,
then shorter run first), all other bytes compare bytewise.

Requirement added 20261113: `-v` must sort IPv4, IPv6, networks, and
versioned archives. Measured against that, the base rule alone:

| shape | base rule | verdict |
|---|---|---|
| IPv4 `9.255.0.1 10.2.0.1 10.10.0.1` | octets numeric | correct |
| CIDR `10.0.0.0 10.0.0.0/8 10.0.0.0/16` | address, then length | correct |
| hosts, interfaces `node2 node10`, `eth2 eth10` | numeric runs | correct |
| archives `foo-1.2.tar.gz foo-1.10.tar.gz` | numeric runs | correct |
| archives `foo-1.2.tar.gz` v `foo-1.2.1.tar.gz` | `1` sorts before `t` | wrong: 1.2.1 lands first |
| pre-release `1.0~rc1` v `1.0` | shorter first | wrong: release lands first |
| IPv6 `2001:db8::9 ::a ::10` | hex groups are not digit runs | wrong: `10` before `a` |
| IPv6 `::` compression, `0db8` v `db8`, `DB8` v `db8` | text differs, value equal | wrong |

Proposed amendment, three owned refinements that repair every "wrong"
row (DECIDED 20261113):
1. Suffix rule: a trailing sequence of `.`-plus-letter-initial
   alphanumeric components (`.tar.gz`, `.tgz`, `.rpm`) is set aside;
   stems compare first, whole keys break the tie.
2. Tilde rule: `~` sorts before everything, including end of key.
3. IPv6 class: a key that parses whole as an IPv6 address, with
   optional `/length`, compares by its 128-bit value, then by length.
   All such keys sort after all other keys. IPv4 stays in the natural
   class, where it is already correct and where a four-part version
   number is indistinguishable from an address.

   Reversed at r0.4.2: "parses" was first implemented with the C
   library's `inet_pton`. The Darwin and Linux libraries do not agree
   on what is an address, so one input got two orders --- the very
   thing section 6 exists to prevent, and a dependency the build
   discipline would have refused had it been sized first. The parser
   is now owned, in `srt.c` and in the function's awk alike: groups of
   1-4 hex digits; `::` at most once, standing for at least one group;
   an optional final dotted quad of decimal octets with no leading
   zero; no zone id; `/length` of 1-3 digits, at most 128. Anything
   else is ordinary text in the natural class.

Shapes that still differ from native `-V` after the amendment,
documented and left alone:
- `1.0a` v `1.0.1`: srt puts `1.0.1` first (`.` before letters);
  native puts `1.0a` first.
- Leading zeros `1.005 1.05 1.5`: srt orders by value then run
  length; native puts more zeros first. Decimal fractions are `-n`
  work in either tool.
- Package-manager grammar (epochs `1:2.0`, release fields) is not
  modeled; hex strings such as commit ids are not numbers.
- Mixed case (`RC1` v `rc1`) is bytewise unless `-f`.
- IPv6: zone ids (`%eth0`) do not parse and fall to the natural class.
  Native `-V` has no IPv6 handling at all; observed on GNU sort 9.4 it
  orders `::10` before `::a` and treats `0db8`, `DB8`, `db8` as
  different. Here srt is the more correct of the two.

**V10 Locale posture.** See section 6. DECIDED: locale environment is
not consulted; order is bytewise.

**V11 Eliminated options.** Section 4 lists them. Proposed: every
eliminated option is a usage error naming the option, with two
exceptions accepted silently as no-ops because they already describe
srt's behavior: `-s` (stable) and `-m` (multi-file input already sorts
to one output). Alternative: reject those too, for a smaller grammar.
DECIDED: as proposed (`-s` and `-m` accepted as no-ops, all other
eliminated options are usage errors); `-i` is retained for POSIX
compatibility and leaves the eliminated list.

**V12 --help.** DECIDED: the manual is compiled into the binary as
text; `srt.1` is generated from it by `make man`, so the two cannot
disagree. `--help` with stdout a terminal pipes that text through
`$PAGER`, else `less`, else `more`, else writes it directly; with
stdout not a terminal it writes directly. It does not call `man(1)`,
so it works before `make install`. `-h` prints the one-screen usage.
Alternative reading: `--help` execs `man srt`; rejected as proposed
because it fails uninstalled.

**V13 -n extent.** DECIDED: optional leading blanks, optional `-`,
digits, optional `.` and digits. No exponent, no thousands separator,
no `+`. A key with no leading number compares as zero. Decimal point
is always `.` (section 6).

**V14 -c report format.** Reopened by V02. The initial request had
the verbose letter report every input on stdout; POSIX has `-c` write
a diagnostic to stderr on disorder and nothing on stdout. DECIDED, to
follow V02 through: `-c` writes to stderr one line per disordered
input, `srt: name:line: disorder`, where `line` is the first record
out of order and standard input is named `-`; sorted inputs produce
nothing; stdout is never written in check mode. All inputs are checked
(no stop at the first disorder), so the report is complete. Under
`-u`, "sorted" means strictly ascending, so a duplicate is a disorder.
Alternative, if the per-file stdout report was the point: keep
`ok<TAB>name` / `disorder<TAB>name<TAB>line` on stdout under `-c`.

**V16 Default spill directory.** New. The first draft defaulted to
`$TMPDIR`, then `/tmp`. On hosts where `/tmp` is memory-backed, spill
there spends the memory the spill exists to save. The Darwin sort
keeps its temporaries in `/var/tmp`. DECIDED: `-T dir`, else
`$TMPDIR`, else `/var/tmp`.

**V17 -g and human-numeric.** New, from the operator's question.
Both are small in the binary --- one parse routine and one comparator
each, no new dependency.
- `-g, --general-numeric`: the key is read by C `strtod`, so
  exponents, `inf`, `nan` and hex floats are accepted. srt never calls
  `setlocale`, so the decimal point is `.` on every host. Order:
  non-numbers, NaN, -inf, finite values, +inf. Cost: values are
  `double`, so integers above 2^53 lose exactness (use `-n`, which is
  exact at any length), and it is the slowest key type.
- `-H, --human-numeric`: sign, digits, optional fraction, optional
  scale letter `K M G T P E Z Y` (either case). Order is by sign, then
  scale letter, then number. As in the natives, the scale is not
  multiplied out: `1023K` sorts before `1M`, and so does `2048K`. Fit
  for `du -h`, `df -h`, `ls -lh` output, where units are normalized.
- Letter choice: `-g` is free in srt and matches the natives. Native
  human-numeric is `-h`, which srt gives to usage. Proposed `-H`: same
  letter, upper case, and its only native claimant is an ignored
  legacy flag on NetBSD.[^1]
- Type letters `d g H n v` are mutually exclusive on one key.
- Function gap, surfaced at r0: NetBSD native sort has neither `-g`
  nor a human-numeric nor a version sort.[^1] Settled at r0.4, and not
  by the refusal last proposed: the function encodes these keys in awk
  on every platform (V01, as built), so there is no per-platform
  behavior to refuse. The one remnant is hexadecimal floats under
  `-g`, which awk cannot read; the function declines them, exit 2.
DECIDED: both adopted.

**V15 Install layout.** DECIDED: `PREFIX` default `/usr/local` for root and
`$HOME` for anyone else (amended in r0.6 by the operator; `make install
PREFIX=dir` overrides);
`bin/srt`, `share/man/man1/srt.1`, `share/srt/srt.fn.bash`. Confirm the
function's destination against the profile's function-file search.

**V18 Choosing the function or the binary by option.** New, from the
operator, 20261114: an option, in place of or beside the `SRT_FN`
environment variable, to force or allow only one form. DECIDED
20261114 as proposed: `--fn` and `--bin`; `SRT_FN` removed. Built at
r0.5.

Proposed:
- `--fn`: the bash function only. Given to the function, it
  translates and never hands over. Given to the binary, it is an
  error, exit 2 --- the binary cannot be the function, and saying so
  is what "only" means.
- `--bin`: the binary only. Given to the function, it hands over to
  the binary on PATH, and if there is none it is an error, exit 2,
  rather than a quiet fall back to translation. Given to the binary,
  it is accepted and does nothing.
- Neither: as now. The function hands over when a binary is on PATH
  and translates otherwise.
- Both: usage error.
- Placement: anywhere among the options, like any other. The function
  must decide before it parses, so it makes one short pass over the
  arguments that knows which options take a value (`-k -t -o -T`,
  `--output --tmp-dir --separator --mem`) and stops at `--`; an
  argument such as `-o --fn` is then a file name, not the option.
- Names: long only. `--fn` matches the file name `srt.fn.bash`; no
  short letter is spent.

Decided: the two names as proposed, and `SRT_FN` removed (reason given:
yes --- an environment variable that silently changes which program
runs is harder to see than an option on the command line; the suite
uses `--fn`).

**V19 Hexadecimal keys.** New, from the operator, 20261114. Decided,
built in r0.6.

The case: a listing whose fourth column is a size in hexadecimal,
right-aligned, and whose fifth is a hexadecimal time,
`srt -k5,4`. Expected: by time, then by size. Got, within one time:
`187c 1c40a 28f5 a3d bdc df4d`.

Cause, reproduced on the build host: srt did what V06 says. Columns
are split on runs of blanks and the blanks are dropped, so column 4
is compared as the text `a3d`, `187c`, `1c40a`, and as text `1c40a`
sorts before `28f5` and `a3d` after both. The native sort gives the
wanted order only by accident of layout: its field keeps the leading
blanks, and right-alignment pads the shorter numbers so that text
order and numeric order coincide. With `-b` the native sort gives
the same order srt does. No srt ordering option reads these keys as
numbers: `-n` and `-g` stop at the first letter, and `-v` treats
letters as text.

Proposed: a hexadecimal numeric type.
- `-x`, `--hex-numeric`, key letter `x`: compare as hexadecimal
  integers. Optional leading blanks, optional `-`, optional `0x` or
  `0X`, then hex digits in either case. Leading zeros do not count;
  comparison is exact at any length; a key with no hex digit is
  zero; what follows the digits is ignored. No fraction.
- The case above becomes `srt -k5x,4x`, or `srt -k5,4x` while the
  times stay the same width.
- One of the type letters, so exclusive with `d g H n v` on a key.
  `x` is unclaimed in all three native sorts.
- Cost: one parse routine in `srt.c` beside `-n`, the same encoding
  as `-n` with sixteen digits instead of ten, and the same in the
  function's awk; cases in sections 3, 14 and 15 of the suite.
- Caution for the manual: under `-x` a word spelled from `a`-`f` is a
  number (`bead`, `face`), so the letter belongs on the columns that
  hold hexadecimal, not given globally over mixed columns.

Considered and not proposed:
- Length-then-text order (shorter key first, equal lengths as text).
  It would serve any right-aligned column in any base, but it reads
  `0a3d` and `a3d` as different numbers and depends on letter case.
- Keeping leading blanks inside columns, as the native sort does. It
  reverses V06, makes order depend on how the producer padded, and
  breaks as soon as a column is left-aligned.


Decided 20261114 and built in r0.6, as proposed. Refinement from the
operator: the hash column of a listing stays text. Within one run its
width is fixed, so text order is value order; across runs with
different digest lengths, text order keeps like prefixes adjacent,
which is what is wanted there. `x` is for the size and time columns.

**V20 The last column.** New, from the operator, 20261114. Decided,
built in r0.6.

The driving use is sorting the columns of file listings, whose last
column is a file name that may hold blanks. Columns are words in the
awk sense (`$1`, `$2` ...) throughout; widths and padding carry no
meaning. Rule, in the operator's words: the last column runs to the
end of the record, unless `-D` is used; then `-k` is tested exactly,
and with no `-k` whole lines are tested.

As built:
- The highest-numbered column named in `-k` is the last one.
- Compared as text (no type letter, `d`, `v`): it runs to the end of
  the record, blanks included. `-k5x,4x,6` sorts by hex time, hex
  size, then the whole name.
- Compared as a number (`n g H x`): it is its word, and the rest of
  the record is one further column, compared last. `-k5x,4x` puts
  the name after every other column.
- Under `-D` (V21), and when any key counts from the end (V22), every
  named column is exactly one word.
- No part of a record is ever outside the comparison.

Consequence, accepted by the operator: the example this plan began
with, `-k5,3` on six columns giving 5,3,1,2,4,6, now holds as written
only when column 5 is numeric (`-k5n,3`). With column 5 as text,
columns 5 and 6 are one key, then 3,1,2,4. For six one-word columns
the two orders differ only where records agree on column 5 and differ
on 6. The suite pins both.

Also accepted: two records that differ only in the blanks inside the
last text column are different records there (`a b  c` and `a b c`
under `-k2`); blank runs between earlier columns still do not count.

**V21 Duplicates.** New, from the operator, 20261114. Decided, built
in r0.6. srt only.

`-D`, `--duplicates`: print every member of each group of two or more
records that are equal on all the named columns; with no `-k`, equal
as whole records. Output is in sorted order, so groups are adjacent.
With `-u`, identical records collapse first, so a group must hold two
distinct records to print. Refused with `-c`, `-C`, `-R`, `-b`.

The conflict with V20 (a hash column extended to the end of the
record would never repeat) is resolved by the operator's rule: under
`-D` the named columns are words and nothing more. The rest of the
record still orders the output, last.

As built: a filter holding one record back at the final writer, in
the in-memory path and in the last merge pass alike; spilled runs and
intermediate passes are unfiltered, so a group split across runs is
still found. In the function, the same filter in the awk stage that
strips the keys.

Limit, stated in the manual: under `-D` a last column holding blanks
is tested by its first word (`My File` and `My Tune` agree on `My`).
For names, split on the separator that cannot be confused: V22.

**V22 Key grammar: bare `-k`, columns from the end, reverse.** New,
from the operator, 20261114. Decided, built in r0.6.

- Bare `-k` names no column: the whole record is the key, which is
  the default. The word after `-k` is a key list only when it reads
  as one (`^-?N[letters](,-?N[letters])*$`); any other word is left
  as an option or a file. A file named like a list is written `./5`
  or placed after `--`.
- `-k-N` counts from the end: `-k-1` is the last column. This is the
  simple resolution for duplicate base names in different paths:
  `srt -t/ -D -k-1`. When any key counts from the end, every word is
  a column and none is extended (the count from the end must not
  depend on V20). A line with no separator is one column, so `-t/
  -k-1` treats a bare name as its own base name.
- Reverse has two spellings and no third: `-kNr` for that column, `-r`
  for every column without letters of its own (`-rk5`). `-kr5` is
  retired; srt refuses it with a message naming `-k5r`.

### Key grammar shared with the listing tools

Recorded here because srt's `-k` was settled first, as the model for
the next revisions of the two tools whose output it sorts. Their own
plans govern; this is what was agreed in this one.

1. Columns are words in the awk sense, counted from 1; widths and
   padding are not significant, and blanks may be squeezed.
2. Sorting is asked for with `-k list`, `col[opts][,col[opts]]...`:
   the named columns in the order given, then the remaining columns
   left to right. Ties follow srt's order.
3. A bare `-k` names no column. In the listing tools that means sort
   by file name; in srt, by whole record.
4. Reverse is `-kNr` for one column or `-r` for all. `-krN` is not
   accepted anywhere.
5. The listing tools know their own column types, so `-k5,4,6` there
   is `srt -k5x,4x,6` on their output: time and size by hexadecimal
   value, the hash as text.
6. The name is the last column and runs to the end of the record.
7. Option letters given up to make room: the checksum tool selects
   columns with `-n[0..5]` in place of `-0`..`-5`; the find tool keeps
   `-0` and `-1` and requires `-k` for sorting.

## 3 Interface

    srt [-cCuDSbRz] [-dfgHinrvx] [-k [col[opts][,col[opts]]...]] [-t char]
        [-o output] [-T dir] [--mem size] [file ...]
    srt -h | --help | -V | --version

| option | long | meaning |
|---|---|---|
| `-c` | `--check` | check; report disorder on stderr (V02, V14) |
| `-C` | | check; exit status only |
| `-o file` | `--output` | write result to file; may name an input |
| `-T dir` | `--tmp-dir` | directory for spill runs |
| `-u` | `--unique` | drop lines equal to an earlier line (V05) |
| `-D` | `--duplicates` | print only records whose named columns repeat (V21) |
| `-S` | | permit unstable sort (V07) |
| `-V` | `--version` | print revision |
| `-h` | | usage |
| | `--help` | manual, paged on a terminal (V12) |
| `-b` | `--respect-blanks` | sort per indentation block (V03) |
| `-R` | `--random` | shuffle output (V08) |
| `-d` | `--dictionary` | only blanks and alphanumerics compare |
| `-f` | `--fold-case` | fold lower to upper |
| `-g` | `--general-numeric` | floating value, exponents (V17) |
| `-H` | `--human-numeric` | number with scale letter (V17) |
| `-i` | `--ignore-nonprinting` | only printable bytes compare |
| `-n` | `--numeric` | numeric value (V13) |
| `-r` | `--reverse` | reverse the comparison |
| `-v` | `--version-sort` | versions, archives, addresses, networks (V09) |
| `-x` | `--hex-numeric` | hexadecimal integer value (V19) |
| `-k` | | column order and per-key options (V04); last column, bare form, `-k-N` (V20, V22) |
| `-t char` | `--separator` | column separator (V06) |
| `-Z` | `--zero-terminated` | records end in NUL, in and out; spelled `-Z` as in the listing tools, `-z` is refused (amended in r0.6) |
| | `--mem N[bkmg]` | memory budget (V07, section 7) |

Operands: files, `-` for standard input, none meaning standard input.
`--` ends options. Short options cluster (`-nr`); option arguments may
be attached or separate; long options take `--opt value` or
`--opt=value`. The parser is owned; `getopt_long` is not required.

Without `-c` or `-C`, all inputs are sorted together to one output.
With either, each input is checked independently; the exit status is 1
if any input is out of order.

Global and per-key options: an ordering option outside `-k` applies to
every key, named or implicit. Options attached to a column replace the
whole global set for that column, so `-r -k5n,3` sorts column 5
numerically ascending, and column 3 and the remainder reversed.

Mutual exclusions (usage error): more than one of `-d -g -H -n -v -x` on one
key; `-c` or `-C` with `-o`; the `-R` set in V08; `-D` with `-c`, `-C`,
`-R` or `-b`.

Exit status: 0 success or sorted; 1 disorder under `-c`/`-C`; 2 error.

## 4 Standards reconciliation

Sources: NetBSD sort(1)[^1], FreeBSD sort(1)[^2], GNU coreutils
sort(1)[^3], the POSIX sort utility, and the Darwin sort manual as
quoted by the operator on 20261113: POSIX.1-2008 compliant; flags
`-ghRMSsTVz` and all long options are extensions; temporaries at
`/var/tmp/.bsdsort.PID.*`. That extension set and temporary name agree
with the FreeBSD manual, which is used here for Darwin option detail;
the Darwin page itself was not read in this session.

### Letters whose meaning changes

| letter | native meaning | srt meaning | hazard |
|---|---|---|---|
| `-k a,b` | fields a through b | column a, then b, then rest | high: silent reorder |
| `-b` | ignore leading blanks | sort per indentation block | high |
| `-S` | memory size (GNU, FreeBSD); unstable (NetBSD) | unstable | medium |
| `-R` | hash-random (GNU, FreeBSD); record separator (NetBSD) | shuffle | medium |
| `-V` | version sort (GNU, FreeBSD) | print version | medium |
| `-h` | human-numeric (GNU, FreeBSD) | usage; human-numeric moves to `-H` (V17) | low |
| `-T` long | `--temporary-directory` | `--tmp-dir` | none |
| `-t` long | `--field-separator` | `--separator` | none |
| `-f` long | `--ignore-case` | `--fold-case` | none |

`-v` is unassigned in all three natives, so version sort lands there
without collision.

### Eliminated

| option | origin | reason |
|---|---|---|
| `-k f.c`, `+pos -pos` | POSIX, all | requirement: no character offsets |
| `-m` | POSIX, all | multi-file input already sorts to one output (V11) |
| `-s` | all | stable is the default (V11) |
| `-M` | GNU, FreeBSD | absent from NetBSD; outside the stated set |
| `-l`, `-H` | NetBSD | length sort; ignored legacy flag |
| `-R char` | NetBSD | superseded by `-Z` |
| `--parallel`, `--batch-size`, `--compress-program` | GNU, FreeBSD | tuning surface; budget is automatic |
| `--files0-from`, `--debug`, `--random-source`, `--sort=` | GNU, FreeBSD | not operator-frequent |
| `--qsort`, `--mergesort`, `--heapsort` | FreeBSD | algorithm is srt's decision; `--radixsort` discussed in section 8 |

`-c`, `-C` and `-i` keep their POSIX meanings (V02, V11). The
remaining departures from POSIX are `-k` ranges and offsets, `-b`,
and `-m`/`-s` as no-ops.

## 5 Comparison semantics

Record: bytes up to newline (NUL under `-Z`). A final record without a
terminator is accepted and written with one. Embedded NUL bytes are
data, never terminators, outside `-Z`.

Comparison of two records proceeds key by key: named columns in order,
then remaining columns left to right. Per key: select type (`n`, `g`,
`H`, `v`, `d`, or bytes), apply `i` and `f`, compare, apply `r`. The first non-zero
result decides. If every key is equal the records are equal: stable
order (input order, files in operand order) decides, or nothing does
under `-S`.

With no `-k` and no `-t`, the whole record is one key and comparison
is a single `memcmp` --- the fast path the common invocation takes.

`-b` (V03): parentage by proper-prefix indent, sibling groups by
byte-identical indent. Within a group the comparator above orders
siblings by their own line, with the indent removed before column
splitting; each sibling is emitted with its whole subtree directly
after it, and the subtree's own groups are sorted by the same rules.
Groups under one parent keep input order.

`-o`: output is opened only after all input is read, written to a
temporary sibling in the destination directory, synced, given the
original's mode, and renamed. A destination that exists as a
non-regular node is written through, not renamed over.

## 6 Locale

Proposed posture: `LC_*` and `LANG` are not consulted. Order is by
byte value, which for UTF-8 input is code point order.

- `-f` folds ASCII `a-z` only.
- `-d` keeps space, tab, ASCII alphanumerics, and every byte >= 0x80
  (so UTF-8 letters survive as data).
- `-i` keeps ASCII 0x20-0x7E and every byte >= 0x80; ASCII control
  bytes and DEL are skipped.
- Blank is space and tab. Decimal point is `.`.

Why this rather than `strcoll`: collation tables differ between glibc,
Darwin's libc and NetBSD's, so a locale-honoring sort gives one input
three orders, and `sort | comm`, `sort | join`, and `-c` against a file
sorted elsewhere all fail quietly. The GNU manual carries a standing
warning on exactly this and recommends `LC_ALL=C` for the traditional
byte order.[^3] srt makes the recommendation the behavior. It is also
the precondition for `memcmp` keys and for radix (section 8), and it
removes a host-variable library dependency.

The honest cost: no language-correct alphabetical order (accented
letters sort after `z`, case-fold is ASCII). Prevalence note: locale
collation is the documented default everywhere, which reflects the
standard's history more than operator need; operator pipelines
overwhelmingly force C. If language order is wanted, the door is a
later `--locale` option that switches the byte comparator to `strcoll`
and disables radix --- an opt-in, never the default.

## 7 Memory and spill

Aim: when the input fits, pay nothing for the safety; when it does not,
finish anyway.

**Fits (the typical case).** Input is read into large contiguous
chunks (a chunk list, not one reallocating buffer, so growth never
copies). A record index is built: pointer, length, and an 8-byte
big-endian key prefix so most comparisons resolve on an integer
compare without touching the record. One in-memory stable merge sort
over the index; output written from the index. No temporary file is
created, no budget arithmetic beyond one comparison per chunk.

**Budget.** Default: half of physical memory (`sysconf` page count and
page size), reduced to any lower `RLIMIT_AS`/`RLIMIT_DATA`; fallback
1 GiB when the query is unavailable. `SRT_MEM` or `--mem` overrides
(`N[bkmg]`, V07); `--mem` outranks `SRT_MEM`. The budget is the primary mechanism because
allocation failure is not a dependable signal: on hosts that
overcommit, `malloc` succeeds and the process is killed later.
Values below 64k are raised to 64k.

Reversed at r0.2: the first draft said a failed allocation would
trigger the spill path. As built, a failed allocation is a diagnosed
exit 2 naming `--mem`. Recovering mid-structure from a failed `malloc`
bought little once the budget was partitioned (below), since each part
then has a ceiling and allocation failure means the budget itself was
set above what the host allows.

`_SC_PHYS_PAGES` is hidden under strict POSIX on Darwin and NetBSD, so
`srt.c` defines `_DARWIN_C_SOURCE` and `_NETBSD_SOURCE` for that one
call and falls back to 1 GiB where the name is still absent. Whether
the query succeeds on each platform is visible with `SRT_STATS=1` and
is to be confirmed there, not assumed.

**Partition (r0.2).** The budget is divided so each part has a fixed
ceiling: record bytes in chunks, one half; the index, one third; the
scratch half-index of the stable sort, one sixth. Reaching either the
chunk ceiling or the index ceiling with at least one record held
triggers a spill. The test is made after every record, not after every
read. Found by measurement: with short records the index (24 bytes a
record) outweighs the data, and a single test per read let one read
overrun a small budget.

**Encoded keys (r0.5).** For a keyed sort the keys of each batch are
encoded before it is sorted (section 8, and `srt.c`, "key encoding").
The encoded batch takes a quarter of the budget, and the chunk ceiling
drops from a half to a quarter to pay for it, so runs are about half
as long when keys are encoded. A batch whose encoded keys would pass
their quarter is sorted by direct comparison instead. The merge of
runs and `-c` always compare records directly: the widest column
count, which the encoding pads to, is known for a batch but not across
runs. `SRT_STATS` reports batches as `encoded=N compared=N`.

**Does not fit.** When a ceiling is reached: sort what is held, append
it as a run to the spill file in `-T dir` (default per V16), release
the chunks, continue reading. At end of input, k-way merge of the runs
by a min-heap. Details:
- Reversed at r0.2: one spill file holds all runs as (offset, length)
  extents, read with `pread`, instead of one file per run. The file
  comes from `mkstemp` with a literal `srt.` template and is unlinked
  immediately, so no signal or crash leaves residue and no cleanup
  handler is needed. Open descriptors stay at two regardless of run
  count, so `RLIMIT_NOFILE` no longer bounds anything.
- Fan-in is bounded by memory instead: budget / 4096 - 1 runs can be
  buffered at once. More runs than that are merged in passes, groups of
  consecutive runs going to a second unlinked file, the two files
  swapping roles each pass. Disk need: about the input size, twice
  that when a pass is required.
- Stability across runs: equal records resolve to the lower run number,
  which is input order; consecutive grouping preserves this across
  passes.
- `SRT_STATS=1` (added at r0.2, not in the first draft) writes
  `srt: stats: budget=N runs=N passes=N` to stderr. It exists so the
  multi-pass route can be tested and so an operator can see what a
  `--mem` setting did.
- `-u` is applied within each run and again in the merge.
- Every write, flush and close is checked; a full `-T` filesystem is a
  diagnosed exit 2, never truncated output.

**Modes outside the spill path.**
- `-c`/`-C`: streaming, two records in memory, no budget concern.
- `-R`: in memory, a Fisher-Yates shuffle. Over budget, each record
  carries a 64-bit random tag into its run and the tags are merged ---
  a uniform permutation by the same machinery (equal tags, about
  n^2 / 2^64 likely, fall back to input order).
- `-R -u` (r0.2): the tag is a keyed hash of the record, the key drawn
  from `/dev/urandom` per invocation. Identical records get identical
  tags and meet, so the ordinary `-u` removes them; order is by tag,
  then bytes, so only identical records compare equal. One mechanism
  serves memory and spill.
- `-b` over budget: exits 2 with a diagnostic naming
  `--mem`. Subtrees do not partition into independent runs, and an
  external outline sort is a separate design. Surfaced as a known gap,
  not hidden.
- One record larger than the budget: held anyway; the budget governs
  when to spill, not a record size limit.

The bash function has no spill of its own; it relies on native sort's,
and it stages a keyed copy of the input in the `-T` directory first.

## 8 --radixsort

Standing among the natives: the FreeBSD-derived sort offers
`--radixsort` as a request that applies only when the key
specification allows[^2]; NetBSD's implementation descends from the
4.4BSD sort and names radixsort(3) among its references[^1]; GNU has
no such option.[^3]

What radix needs is keys that order correctly as raw bytes. The
section 6 posture supplies that for plain keys at no cost. The other
types need an encoding step that turns each key into a byte string
whose `memcmp` order equals the comparator's order:
- `f`: fold while encoding. `d`: drop excluded bytes.
- `r`: complement every byte of that key's encoding.
- `n`: sign byte, digit-count, digits; negatives complemented.
- `v`: each digit run prefixed by its length; `~` mapped lowest; stem
  before suffix; IPv6 as a class byte plus 16 value bytes and length.
- `g`: the IEEE bit pattern with the sign bit flipped, negatives
  complemented. `H`: sign, scale rank, then the `n` encoding.
- key boundaries: a terminator byte lower than any data byte.

Once encoded keys exist, three things follow together: MSD radix
becomes possible, the 8-byte prefix of section 7 becomes exact for
every key type rather than for plain keys only, and the spill merge
compares encoded bytes. The encoding, not the radix pass, is the
structural investment.

Assessment:
- Gain is real for many short records with low-entropy leading bytes
  (hostnames, paths, timestamps): O(n x key bytes) against
  O(n log n) comparisons that each re-scan a common prefix.
- Gain is small or negative for few records, long distinct keys, or
  numeric keys of wide range; the prefix-cached merge sort already
  takes most of the available win there.
- Stability: MSD radix with an auxiliary array is stable and fits the
  default; the in-place variant is not and belongs under `-S`.
- Memory: encoded keys enlarge the index, pulling the spill threshold
  in.

Proposal: do not ship `--radixsort` before r0.5. Build the
comparator so that the encoding can be introduced behind it without
grammar change; add `--radixsort` in a later revision as an explicit
request, measured against the merge sort on operator-shaped inputs
before any thought of making it automatic. If the option is accepted
at all it follows the FreeBSD wording: used when the specification
allows, silently the default algorithm otherwise.

This recommendation is a design judgment, not a measurement; no
benchmark has been run.

**Evaluated at r0.5 (20261114), by measurement.** Build host, 2,000,000
records of four columns (86 MB), one run each, seconds:

| sort | r0.4.2 | encoded keys | native sort, 2 threads |
|---|---|---|---|
| whole record, plain | 1.04 | 1.07 (not encoded) | 0.66 |
| `-k3n` | 5.30 | 1.86 | 2.25 |
| `-k3n,1` | 5.16 | 1.58 | |
| `-k2v` | 7.12 | 2.18 | 2.12 (`-V`) |
| `-k1v` | 7.82 | 2.14 | |
| `-n -k3` | 6.03 | 1.62 | |
| `-f` | 2.72 | 1.61 | 1.29 |
| `-t. -k3` | 4.22 | 1.82 | |
| `-k4,1` | 5.38 | 1.80 | |

Key encoding: viable, and a significant gain --- keyed sorts run 2.3
to 3.7 times faster, which moves srt from about three times slower
than the native sort to level with it, on one thread against two.
Built at r0.5.

Radix, tried on top of the encoded keys as a stable MSD pass with the
merge sort for small buckets, same host, seconds, merge then radix:
whole record 1.12 / 0.84; `-k3n` 1.79 / 1.88; `-k2v` 2.22 / 2.87;
`-f` 1.47 / 1.10; shuffled integers plain 1.34 / 0.94 and `-n`
2.84 / 1.82; path names plain 1.43 / 1.15 and `-f` 1.74 / 1.59. Output
identical in every case.

Radix: viable, not significant. It gains up to 1.5 times where keys
are short and differ early, loses up to 1.3 times where encoded keys
share long prefixes (a class byte, a length field), and it doubles
the scratch memory, which would shrink every run under a budget. A
gain of that size and sign does not pay for a second sort path and an
option. Not built; `--radixsort` stays a refused option. What would
change the verdict: a workload that is mostly short plain keys, or a
radix pass restricted to the first eight bytes, which the index
already holds.

## 9 Package files

**README.md** --- what srt is, the hazard table of section 4 in brief,
build and install per platform, the static-link ceiling (static on
Linux and NetBSD; Darwin links libSystem only), pointer to `--help`.

**makefile** --- written to the intersection of GNU make, bmake and
the Darwin make: no `ifeq`, no `$(shell)`; platform branches inside
recipes via `case` on `uname -s`. Targets:

| target | action |
|---|---|
| `all` | `srt` and `man` |
| `srt` | compile `srt.c`, `-std=c99 -Wall -Wextra -Wpedantic`, warnings fatal to review |
| `man` | generate `srt.1` from `./srt --help` |
| `test` | run `test-srt.sh` against the built binary and the function |
| `install` | binary, man page, function file under `PREFIX` (V15); `mkdir -p`, `cp`, `chmod` |
| `clean` | remove `srt`, `srt.1`, test scratch |
| `uninstall` | remove exactly what `install` placed |

**srt.c** --- single file, C99, no library beyond libc. Feature-test
macros only as the calls require. One fatal-diagnostic path. Manual
and usage as string literals, chunked under the 4095-byte limit.

**srt.fn.bash** --- per V01, as built. Validates options with the same grammar
and the same errors as the binary; `-h` and `--help` carry the same
text, held as a copy that the suite compares. Sourced, so it sets
nothing in the calling shell; the work is done in a subshell.

**test-srt.sh** --- section 10.

## 10 Verification

`test-srt.sh` runs every case against the binary and, where the
function supports the option, against the function, requiring
identical bytes. One case per promise in the manual, named beside it:

1. Grammar: each option short and long, clustering, `--`, each usage
   error of section 3, each eliminated option of section 4.
2. `-k`: the six-column example as `-k5n,3`, and the text case beside
   it (V20); per-key override against a global option; short lines;
   duplicate column refused; the last column as text and as number;
   bare `-k` before a file, an option and a list; `-k-N`; `-D` by
   whole record, one column, several, with `-u`, across spilled runs.
3. Types: `-n` negatives, decimals, non-numbers; `-d`, `-f`, `-i` over
   ASCII and UTF-8 bytes; `-g` exponents, inf, nan; `-H` scale order.
   `-v`: every row of the V09 table as a case --- IPv4, CIDR, hosts,
   archives with and without a third component, `~`, IPv6 compressed,
   zero-padded and mixed case, IPv4 and IPv6 mixed in one column.
4. Stability: equal keys keep input and operand order; `-u` keeps the
   first.
5. Check: sorted, unsorted, multiple inputs with one unsorted, stdin,
   `-u` strictness, `-c` stderr format, silence of `-C`, empty stdout
   in both.
6. `-R`: output is a permutation of input; two runs differ.
7. `-b`: nested outline, parent-child adjacency preserved; tab and
   space children of one parent stay separate groups in input order;
   a tab-indented line under a space-indented line is not its child.
8. `-Z`, `-t` with empty columns, final record without terminator.
9. `-o` naming an input; interrupted run leaves the original.
10. Spill: `--mem` set small enough to force multiple runs and a
    multi-pass merge; output byte-identical to the in-memory result;
    `-T` unwritable is exit 2.
11. Oracle: for the subset where meanings coincide (whole-line,
    `-n`, `-r`, `-f`, `-u`), agreement with `LC_ALL=C sort -s`.
12. Locale independence: identical output under `LC_ALL=C` and a UTF-8
    locale.
13. Self-consistency: `srt --help | srt -c` style round trips; the
    generated `srt.1` equals a fresh generation.

A revision is complete only when the suite has passed under each make
dialect on each of the three platforms. This session can build and run
on Linux alone; Darwin and NetBSD results are the operator's to
report, and the plan says so rather than implying coverage.

## 11 Revision sequence

- **r0** this plan; V items answered; section 12 filled.
- **r0.1** (built 20261113) `srt.c` in-memory path, full grammar, check, unique, `-R`,
  `--help`/`-h`/`-V`; makefile; tests 1-6, 8, 9, 11-13; README.
- **r0.2** spill and merge, `--mem`, `-T`, streaming check; test 10. Built 20261114.
- **r0.3** `-b` outline sort; test 7. Built 20261114.
- **r0.4** `srt.fn.bash` translator and parity tests; V17 function gap settled here. Built 20261114.
- **r0.4.1** `srt.fn.bash` as one enclosing function. Built 20261114.
- **r0.4.2** owned IPv6 parser; one-name test made environment-independent. Built 20261114.
- **r0.5** key encoding, built 20261114; `--radixsort` measured and declined (section 8); `--fn` and `--bin`.
- **r0.5.1** test correction for `-S -u`; manual wording; headers and titles. Built 20261114.
- **r0.6** `-x`; the last column; `-D`; bare `-k`; `-k-N`; `-kr5` retired. Built 20261114.

r0.3 and r0.4 can move ahead of r0.2 if that suits; r0.2 precedes r0.5.
The plan itself stays r0 and is revised in place; its header carries
the dated revision lines.

## 12 Decision log

| item | decision | date |
|---|---|---|
| V01 | fn.bash is a translator to native sort and awk; defers to the binary when on PATH | 20261113 |
| V02 | POSIX polarity: `-c` reports, `-C` silent; reverses the initial request | 20261113 |
| V03 | `-b` is outline sort (reading B) | 20261113 |
| V05 | `-u` removes whole-line duplicates only | 20261113 |
| V07 | `-S` is unstable; memory by `--mem` and `SRT_MEM` | 20261113 |
| V11 (part) | `-i` retained for POSIX compatibility | 20261113 |
| V03 (indent) | indent is the exact byte string; tabs and spaces mix but never correlate | 20261113 |
| V04, V06, V08, V10, V11, V12, V13, V15 | as proposed | 20261113 |
| V07 (suffix) | `--mem N[bkmg]`, bytes default, powers of 1024 | 20261113 |
| V09 (base) | owned natural order; must cover IPv4, IPv6, networks, versioned archives | 20261113 |
| V14 | `-c` reports disordered inputs on stderr; stdout unused in check mode | 20261113 |
| V16 | spill default `-T`, `$TMPDIR`, `/var/tmp` | 20261113 |
| sequence | revisions are r0, r0.1, r0.2, ... | 20261113 |
| V03 (derived) | parentage by proper-prefix indent; sibling groups by identical indent | 20261113 |
| V09 (amendment) | suffix rule, tilde rule, IPv6 class adopted | 20261113 |
| V17 | `-g` and `-H` adopted | 20261113 |
| V04 (override) | confirmed: letters on a key replace the global set; additive rule considered and declined; `--help` explains it | 20261114 |
| section 7 | r0.2: budget partition; one spill file with extents; fan-in by memory; failed allocation exits; `SRT_STATS` | 20261114 |
| V03 (build) | r0.3: block closure; groups by first appearance; blank lines stay with the line above; `-u` removes equal leaves only; `-c` checks every group | 20261114 |
| V03 (closure) | operator: block closure accepted as more correct than the literal reading, though not always what is expected | 20261114 |
| V01 (build) | r0.4: all keys encoded in awk, native sort compares bytes only; one behavior on all platforms; replaces the per-platform refusal proposed for V17 | 20261114 |
| V01 (one name) | operator: `srt.fn.bash` encloses a single `srt` function; all `_srt_*` and `_SRT_*` names are local to it | 20261114 |
| V09 (parser) | r0.4.2: IPv6 recognition is owned; `inet_pton` removed after it gave Darwin and Linux different orders | 20261114 |
| V18 | `--fn` and `--bin` adopted; `SRT_FN` removed | 20261114 |
| r0.5 | key encoding built (2.3-3.7x on keyed sorts, measured); radix measured and not built | 20261114 |
| notice | every file but the manual text carries the copyright and attribution line | 20261114 |
| headers | every file: title, front matter, revision block, copyright; README and plan then the contents marker; titles "srt: sort for operators" and "srt plan" | 20261114 |
| V19 | `-x`, `--hex-numeric`, key letter `x` adopted and built; the hash column stays text | 20261114 |
| V20 | the highest named column runs to the end of the record when text; one word when numeric, the rest compared last; exact words under `-D` and with `-k-N` | 20261114 |
| V20 (consequence) | accepted: `-k5,3` on six columns is 5,3,1,2,4,6 only as `-k5n,3`; as text, 5 and 6 are one key | 20261114 |
| V21 | `-D`, `--duplicates`: every member of a group equal on the named columns; `-u` first; refused with `-c -C -R -b`; srt only | 20261114 |
| V22 | bare `-k` is the whole record; a word after `-k` is a list only if it reads as one; `-k-N` counts from the end; reverse is `-kNr` or `-r`; `-kr5` retired | 20261114 |
| grammar | key grammar shared with the listing tools recorded in section 2 (seven points) | 20261114 |

## 13 Revision status

### r0.1 (6af8010b, 20261113)

Delivered: `srt.c`, `makefile`, `test-srt.sh`, `README.md`.
`srt.fn.bash` is r0.4; `make install` skips it while absent.

Implemented: the full grammar of section 3; column keys with per-key
options; types `d f g H i n r v` including the V09 refinements;
`-c`/`-C`; `-u`; `-S`; `-R`; `-Z`; `-t`; atomic `-o`; `-h`, `--help`
with pager, `-V`; the eliminated-option errors and the `-s`/`-m`
no-ops.

Departures from the plan in this revision, each to be closed by the
revision named:
- `-c`/`-C` load each input whole rather than streaming two records
  (section 7). Closes in r0.2 with the budgeted reader.
- `--mem`, `SRT_MEM` and `-T` are parsed and validated but not
  enforced; input larger than memory fails on allocation. r0.2.
- `-b` is accepted by the parser and refused with exit 2. r0.3.
- Columns are split on every comparison; offsets are not cached. The
  8-byte prefix of section 7 is in place for the plain whole-record
  path only. Keyed sorts are correct but not yet fast. Candidate for
  r0.2 or r0.5 (the key encoding subsumes it).
- `-S` uses the C library `qsort`.
- `-R` seeds a 256-bit generator once from `/dev/urandom` and draws
  indexes from it without modulo bias, rather than reading the device
  per record.

Verified in the build session, Linux x86_64, gcc 13, GNU make 4.3:
- compiles with `-std=c99 -Wall -Wextra -Wpedantic`, no warnings,
  static link;
- `make test`: 168 cases pass; the same 168 pass under address and
  undefined-behavior sanitizers;
- `make install` and `make uninstall` against a scratch `DESTDIR`;
- `--help` through `PAGER` on a pseudo-terminal, and fall-through to
  the next pager when `PAGER` names a missing command;
- 2,000,000 shuffled integers, whole-record sort: 0.44 s against the
  native sort's 0.43 s wall, byte-identical output. One run, one
  machine; an indication, not a benchmark.

Not verified, and not to be read as covered:
- Darwin and NetBSD, in any respect;
- bmake and the Darwin make (the makefile avoids GNU-only constructs
  by construction, untested);
- `srt.1` rendering: the build host has no working `man`; the roff
  source was inspected, not rendered.

Test finding worth keeping: `-n -k1r` sorts column 1 as reversed
*bytes*, not reversed numbers --- letters on a key replace the global
set (V04), they do not add to it. The suite now pins this.

Reported afterwards by the operator, 20261113: on Darwin, `make test`
builds without `-static` as designed and passes 168 of 168. Darwin
and its make therefore leave the not-verified list for r0.1.

### r0.2 (6af81678, 20261114)

Delivered: `srt.c`, `test-srt.sh`, `makefile` (header only),
`README.md`, this plan.

Implemented: the memory budget with its partition; spill to one
unlinked file and k-way merge, in passes when the runs exceed the
fan-in; `--mem`, `SRT_MEM`, `-T` and the V16 default enforced;
streaming `-c`/`-C` holding two records; `-R` and `-R -u` over
budget; `SRT_STATS`. `--help` gains GLOBAL AND KEY OPTIONS, stating
the V04 replace rule with the `-n -k1r` case worked through, and
MEMORY.

Closed from the r0.1 list: budget enforcement; streaming check.
Still open: `-b` (r0.3); columns split on every comparison; `-S` by
library `qsort`.

Departures from the plan, recorded in section 7 where they apply:
one spill file with extents instead of a file per run; fan-in bound
by memory, not descriptors; failed allocation exits instead of
spilling; `SRT_STATS` added.

Verified in the build session, Linux x86_64, gcc 13, GNU make 4.3:
- no compiler warnings; `make test` passes 213 of 213; 211 pass under
  address and undefined-behavior sanitizers, where the two
  address-space-limit cases skip themselves;
- 4,000,000 records, 30 MB, byte-identical output by four routes:
  default budget (in memory), `--mem 8m` (35 runs, 1 pass),
  `--mem 256k` (1099 runs, 2 passes), `--mem 64k` (4396 runs,
  4 passes), and equal to the native sort;
- the bound is real: under a 40 MB address-space limit the same input
  sorts with `--mem 8m` and with the default budget, which follows the
  limit down to 20 MB, while `--mem 1g` fails with exit 2;
- `-c` on that input runs under a 12 MB limit.

Two defects found and fixed by those measurements before delivery,
kept here because the tests that would have caught them now exist:
the budget was tested once per read, so short records overran it; and
a first correction counted the whole carried read against the budget,
producing runs of five records (772,604 runs, 128 s). The partition in
section 7 is the repair.

Observation, not yet acted on: on this input the spill route
(0.9 s) is faster than the in-memory route (1.2 s), because runs are
sorted while they still fit the processor cache. The in-memory merge
sort over a large index is the place to look for speed; candidate for
r0.5 with the key encoding.

Not verified:
- Darwin and NetBSD for r0.2: `pread`, `ftruncate`, `getrlimit` are
  POSIX, but `_DARWIN_C_SOURCE`/`_NETBSD_SOURCE` and the physical
  memory query are new and unbuilt there; `SRT_STATS=1 srt /dev/null`
  on each will show whether the budget is half of memory or the 1 GiB
  fallback;
- the address-space-limit tests skip where `ulimit -v` is not
  enforced, which is expected on Darwin;
- a full `-T` file system: the write error path is coded and checked
  by inspection, not exercised;
- bmake; `srt.1` rendering.

Reported afterwards by the operator, 20261114: Darwin, `make clean
test` with `SRT_STATS` set, 213 of 213. The default budget printed as
8589934592, so the physical-memory query works there under the added
feature macros and the 1 GiB fallback was not taken. The count of 213
on Darwin is not the same 213 as on the build host: the two
address-space-limit cases skipped there, as predicted, and the two
unwritable `-T` cases, which skip for root on the build host, ran.
The suite's count therefore varies by host and user; its last line,
not a fixed number, is the result.

### r0.3 (6af81dc6, 20261114)

Delivered: `srt.c`, `test-srt.sh`, `makefile` (header only),
`README.md`, this plan.

Implemented: `-b` outline sort per V03, with the points settled under
V03 above; `-b` with every ordering option, `-k`, `-t`, `-u`, `-Z`,
`-o`, `-c`/`-C` and several inputs; refusal with exit 2 naming `--mem`
when the budget is reached, nothing written. `--help` gains OUTLINE
SORT with a worked example.

Still open: columns split on every comparison; `-S` by library
`qsort` (under `-b` the stable sort is always used, which `-S`
permits).

Verified in the build session, Linux x86_64, gcc 13, GNU make 4.3:
- no compiler warnings; `make test` passes 253 of 253 as root, 251
  under the sanitizers;
- `-b` output passes `-cb`, and `-b` applied twice changes nothing;
- an outline nested about 8,000 levels deep is returned unchanged;
- 800,000 lines (200,000 blocks) sort and verify in 0.3 s.

Not verified: Darwin and NetBSD for r0.3 (the outline code uses no
new library call); bmake; `srt.1` rendering; a full `-T` file system.

Reported afterwards by the operator, 20261114: Darwin, `make clean
test`, 253 of 253, `srt r0.3 6af81dc6`. Darwin leaves the
not-verified list for r0.3.

### r0.4 (6af82211, 20261114)

Delivered: `srt.fn.bash` (new), `srt.c` (manual and revision only),
`test-srt.sh`, `makefile` (header only), `README.md`, this plan.

Implemented: the bash function per V01 as built. Sort, `-u`, `-c`/`-C`,
`-R`, `-o` (temporary sibling, mode carried, renamed), `-T`, `-t`, all
ordering options global and per key, several inputs, stdin. Hand-over
to a binary on PATH, and `SRT_FN=1`. The binary's manual gains BASH
FUNCTION; the function carries the same manual and usage text, and the
suite fails if the two differ.

Declined by the function, each with exit 2 and a message naming the
binary: `-b`; `-Z`; `-t '\0'` and non-ASCII separators; input holding
a byte from 0x01 to 0x04 (the encoding's own separators); hexadecimal
floats under `-g`. `--mem` is passed to the native sort on Linux and
Darwin and ignored elsewhere. `-S` and `SRT_STATS` have no effect.

Departure from what was last proposed: the operator was told the
function would refuse `-g`, `-H` and `-v` where the native sort lacks
them. It was built instead to encode those keys itself everywhere.
That removed the per-platform difference, and it is the r0.5 key
encoding written once already, in awk, with the binary as its oracle.

Verified in the build session, Linux x86_64, bash 5.2, mawk 1.3.4,
GNU sort:
- `make test`: 426 of 426, of which 173 compare the function with the
  binary (output and exit status for sort, exit status and report for
  check, exit status for grammar);
- a separate differential run, not part of the suite: 400 random
  inputs drawn from numbers, versions, addresses and words, each under
  a random option set, in sort mode and in check mode, 800 comparisons,
  no difference;
- the function defines no name outside `srt` and `_srt_*`, and leaves
  nothing in the `-T` directory or beside `-o`.

Not verified, and these matter more for the function than for the
binary because it leans on host tools:
- any awk other than mawk. The program keeps to POSIX awk and avoids
  extensions, but it has not been run under gawk or under the awk
  shipped with Darwin and NetBSD. Points of risk: POSIX character
  classes in regular expressions, `%c` for bytes 1-4, string comparison
  in the C locale, and an awk that treats input as UTF-8 regardless of
  locale;
- any sort other than GNU sort, in particular `-t` with a control
  byte and `-s` with `-k N,Nr`;
- bash older than 5.2;
- speed. On the build host the function took about 0.1 s for 20,000
  records keyed `-k2n,1`, against 0.02 s for the binary; it also
  stages a copy of the input, so it is not meant for large inputs.
The suite's section 14 is the instrument: run on Darwin and NetBSD it
reports each of the above as a named failing case rather than a
silent difference.

### r0.4.1 (6af86b89, 20261114)

Delivered: `srt.fn.bash`, `test-srt.sh`, `README.md`, this plan. The
binary and the makefile are unchanged from r0.4.

Requirement, from the operator: the file is to enclose a single `srt`
function, with every `_srt_*` name local to it. r0.4 had defined
eleven helper functions and four variables at file level, which a
profile that exports what it sources would have carried into every
child shell.

As built: `srt` does the hand-over to a binary, then opens a subshell
inside its own body. The helper functions, the awk program, the usage
and manual text and every variable are defined in that subshell, so
they end with it. The usage and manual blocks moved into the helpers
that print them and are read only for `-h` and `--help`; the awk
program is read on each call that reaches the translator.

`-V` in the function prints the binary's revision with the function
file's own stamp: `srt r0.4 6af82211 (bash function 6af86b89)`.

Verified, Linux, bash 5.2: `make test` 426 of 426. One case replaces
the earlier name check and holds the requirement: after sourcing, the
only function is `srt` and no variable is added; after calls that
sort, fail on usage, print usage and print the manual, the function
list, variable list, shell options, traps, `shopt` state and `IFS` of
the calling shell are unchanged.

Not verified: the same as for r0.4.

Reported by the operator, 20261114, Darwin, r0.4.1: 419 passed, 7
failed. Both groups of failure are diagnosed below; neither was a
fault in the function's translation.

### r0.4.2 (6af871c9, 20261114)

Delivered: `srt.c`, `srt.fn.bash` (manual copy and revision only),
`test-srt.sh`, `README.md`, this plan. The makefile is unchanged.

Finding 1, six cases, `-v` on the address data: the function and the
binary disagreed on Darwin. The function's Darwin output has the
checksum of the Linux binary's output, so the function was right on
both hosts and the Darwin *binary* was the one that differed. Cause:
`srt.c` decided "is this an IPv6 address" with the C library's
`inet_pton`, and the two libraries do not accept the same strings.
The Darwin `-vu` result was 13 bytes shorter, which is the length of
`fe80::1%eth0` and its newline: the inference, not confirmed on
Darwin, is that its library accepts a zone id, so that key became
equal to `fe80::1` and was dropped. Whatever the exact string, the
defect is the dependency. Repair: an owned parser (V09, reversal
note); `arpa/inet.h` and `sys/socket.h` are gone from `srt.c`.

This is the case the function-parity tests were written for, though
not in the direction expected: the second implementation caught a
host dependency in the first.

Finding 2, one case, "defines one name": the case assumed a shell
with no functions and a fixed variable list. A shell whose
environment carries exported functions starts with them, and bash
sets `COLUMNS` and `LINES` after a command when it has a terminal.
The function file was not at fault; the case was. It now measures
what sourcing adds and what calls change, against the shell as it
found it, and a second case runs it with exported functions present.

Verified, Linux x86_64: `make test` 432 of 432 (428 under the
sanitizers); the owned parser reproduces, byte for byte, the output
the library version gave on Linux for the address data; a separate
run of 300 inputs of 40 random address-like keys each (hex digits,
colons, dots, slashes, percent signs) shows no difference between
the binary and the function under `-v` and `-vu`.

Not verified: Darwin and NetBSD for r0.4.2. The six `-v` cases and
the one-name case are expected to pass on Darwin now; that is a
prediction from the diagnosis, to be confirmed by `make clean test`
there. The rest as for r0.4.

Reported afterwards by the operator, 20261114: Darwin, `make clean
test`, 432 of 432, `srt r0.4.2 6af871c9`. Both predictions held. With
this the bash function is verified on Darwin's awk and sort as well as
on mawk and GNU sort.

### r0.5 (6af87ca7, 20261114)

Delivered as one archive, `srt-r0.5.tgz`: `srt.c`, `srt.fn.bash`,
`test-srt.sh`, `makefile`, `README.md`, this plan.

The operator asked for an evaluation of r0.5 --- viability, benefit,
consequence --- and to proceed only on a significant gain. Section 8
holds the measurements. Verdict: key encoding built; radix measured
and not built.

Implemented:
- Key encoding in the binary. For any sort other than the plain
  whole-record one, each record's keys are encoded once per batch and
  the batch is sorted on bytes. `reccmp` is unchanged and remains the
  definition of the order; `-c`, the merge and `-b` still use it.
- `--fn` and `--bin` (V18) in both forms; `SRT_FN` removed. The
  function finds the option with one pass over its arguments that
  knows which options take a value.
- `SRT_STATS` gains `encoded=N compared=N`.
- The copyright and attribution line in every file. It is not in the
  `--help` text or the generated man page, as instructed; `srt.fn.bash`
  carries it in its header and holds the manual text without it.

Consequences accepted with the encoding:
- Memory: the encoded batch is a quarter of the budget and the chunk
  ceiling is halved to make room, so a keyed sort that spills makes
  about twice as many runs as before. A sort that fits is unaffected
  apart from the encoded copy itself, roughly the size of the keys
  plus 16 bytes a record.
- Two routes to one order. The risk is that they differ; the controls
  are below.
- `-g` now assumes IEEE 754 doubles of 8 bytes; the source refuses to
  compile otherwise.

Verified in the build session, Linux x86_64:
- `make test`: 519 of 519 (513 under the sanitizers);
- section 15 of the suite, new: for 39 option sets on mixed data of
  numbers, versions, addresses and words, the encoded route (default
  budget) and the compared route (`--mem 64k`, where these keys never
  fit, confirmed by `SRT_STATS`) give identical bytes, equal records
  included; and every encoded result passes `-c`, which compares
  directly;
- outside the suite: 1,500 random inputs under random option sets,
  r0.5 against the r0.4.2 binary kept as reference, no difference;
- the timings in section 8, with identical output in every row.

Not verified: Darwin and NetBSD for r0.5. The encoder is plain C on
bytes and uses no new library call, and `--fn`/`--bin` use no new
shell feature, but neither has run there. Speed on other hosts will
differ; the ratios in section 8 are one machine's.

Reported afterwards by the operator, 20261114: Darwin, r0.5, 518
passed, 1 failed; both `-V` lines read `srt r0.5 6af87ca7`. The key
encoding, `--fn`/`--bin` and the function all pass there.

### r0.5.1 (6af889a5, 20261114)

Delivered as one archive, `srt-r0.5.1.tgz`. The program is unchanged
from r0.5; the manual gains four lines, and with it the revision.

The Darwin failure, one case, `encoded equals compared: srt -S -u
-k2n`: not a defect in the encoding. `-S` permits any order among
records that compare equal, and the binary then uses the C library's
`qsort`. With `-u` one of several equal records is kept, and which
one depends on where `qsort` left them. The two routes sort batches
of different sizes, so on a host whose `qsort` is not stable they can
keep different records, each a correct answer. The build host's
`qsort` happens to be stable, which is why the case passed there and
why it was written wrongly: it asserted bytes where only the set of
keys is promised. The case now asserts that `-S -u` keeps exactly one
record per key and that its output is strictly ordered, on both
routes. `--help` states under `-S` that with `-u` any one of the
equal records may be kept and that the choice can differ between
hosts.

Worth keeping from this: three times now a Darwin run has caught an
assumption that held only on the build host --- the address library,
the calling shell's contents, the library sort. Each was a place
where the build host's behavior stood in for a rule.

Also in r0.5.1, at the operator's direction: titles `srt: sort for
operators` (README) and `srt plan`; in every file the order title,
front matter, revision block, copyright, and in the README and the
plan the contents marker after that. The plan's opening no longer
says that no code exists.

Opened: V19, hexadecimal keys, from a case the operator met; proposed,
not built.

Verified, Linux x86_64: `make test` 521 of 521; the archive extracts,
builds and passes from a fresh directory.

Not verified: Darwin and NetBSD for r0.5.1. The corrected case is
expected to pass on Darwin, since it no longer depends on the library
sort; a prediction until run there.

### r0.6 (6af8a908, 20261114)

Delivered as one archive, `srt-r0.6.tgz`. Built: V19 (`-x`), V20 (the
last column), V21 (`-D`), V22 (bare `-k`, `-k-N`, reverse spellings).

Program. One routine, `layout`, now decides what a record's named
keys and remaining columns are, and the comparison (`reccmp`), the
key encoder and the `-D` test all read its answer; before r0.6 each
split the record for itself. The split takes a limit: the words up
to the highest named column, then the residue as one column. Hex
keys parse like `-n` with sixteen digits and no fraction, and encode
as sign, digit count, digits. `-D` is a one-record hold at the final
writer. The function's awk program carries the same layout, encoder
and hold.

Manual. KEYS rewritten for words, `-k-N`, bare `-k` and the reverse
spellings; new section THE LAST COLUMN; `-D` and `-x` entries;
EXAMPLES regrouped to show each addition and the range of use:
columns, kinds of key, the last column, columns from the end,
duplicates, whole files, resources and forms. The six-column sentence
now reads `-k5n,3`, with the text case beside it (V20).

Defect found before delivery, by differential fuzz and not by the
suite: the function tested only the first named column under `-D`
with several keys (the key list was consumed while the native sort's
arguments were built, before the filter read it). Fixed; four cases
pin it. Worth keeping: the parity cases written by hand all happened
to agree on their first column.

Changed cases, each a decided change of meaning and not a regression:
`-k1x` is now valid (the unknown-letter case uses `q`); `-k` alone is
valid; `-t: -k2` extends column 2 to the end of the record; the
blank-run case uses a numeric last column.

Verified, Linux x86_64: `make test` 664 of 664 plain, 658 under
address and undefined-behavior sanitizers (six cases need an
address-space limit the sanitizer runtime cannot run under); 3000
random trials of the new options, function against binary against the
compared route (`--mem 64k`), no difference apart from the function's
documented refusal of hexadecimal floats under `-g`; timing against
r0.5.1 on one million records unchanged or better (`-k2n` 0.88 s
both; whole records 0.36 s against 0.41 s).

Darwin (operator report, 20261114): `make clean test` 664 of 664, binary
and function, both reporting `r0.6 6af8a908`. That also covers the
r0.5.1 changes it contains. Corrections made after that run, under
the same revision: the manual gains a blank line after each section
heading and a SEE ALSO section; the generated man page uses real
section headings; the README links its files; NUL termination is `-Z`
(`-z` is refused, in the binary and the function); the manual has a
blank line before each EXAMPLES group; `make install` defaults to
`/usr/local` for root and `$HOME` for anyone else (V15).

Not verified: NetBSD; bmake; the rendering of `srt.1` by a man
renderer (this host has none).


---

## One order on three hosts

Read from the end, the numbered questions are one question. The key
grammar, the byte locale, the default stability, the owned version
order and the fixed decimal point each remove a place where the same
line could land differently on a different machine; the spill path
removes the place where it could fail to land at all. What an operator
wants from a sort is less a faster ordering than a repeatable one ---
the file sorted on the build host must pass `-c` on the workstation.
Every proposed default above was chosen by that test, and any V item
answered the other way should be answered knowing which host-to-host
agreement it gives back.

[^1]: NetBSD sort(1) manual. <https://man.netbsd.org/sort.1>
[^2]: FreeBSD sort(1) manual. <https://man.freebsd.org/sort>
[^3]: GNU coreutils sort(1) manual. <https://www.man7.org/linux/man-pages/man1/sort.1.html>
