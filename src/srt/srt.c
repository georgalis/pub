/* srt.c --- sort for system operators
 *
 * One sort grammar for Linux, Darwin and NetBSD. Column-ordered keys
 * (-k5,3 is "column 5, then column 3, then the rest"), stable by
 * default, bytewise order independent of the locale environment.
 * Requirements and decision record: plan-srt.md.
 *
 * Dependency posture: C99 and POSIX.1-2008 libc only. No setlocale()
 * call is made, so strtod() and every byte test stay in the C locale.
 * _DARWIN_C_SOURCE and _NETBSD_SOURCE are defined for one call only:
 * sysconf(_SC_PHYS_PAGES), which those platforms hide under strict
 * POSIX. Where it is still absent the budget falls back to 1 GiB.
 *
 * Memory: input that fits the budget is sorted in memory and no
 * temporary file is made. Past the budget, sorted runs are appended to
 * one unlinked spill file and merged; when the runs outnumber what the
 * budget can buffer, they are merged in passes through a second file.
 *
 * r0.5 limits, stated rather than hidden:
 *   - -b holds the whole input in memory; over budget it exits 2
 *   - the merge of spilled runs and -c compare records directly
 *     (reccmp); only the sort of each batch uses encoded keys
 *
 * revision 6af8a908 20261114 103136 PST Sat --- r0.6 -x hex keys; -D
 *          duplicates; the last named column runs to end of record;
 *          bare -k; -k-N from the end; -kr5 retired for -k5r
 * revision 6af889a5 20261114 081741 PST Sat --- r0.5.1 manual: -S with -u
 *          (no change to the program)
 * revision 6af87ca7 20261114 072215 PST Sat --- r0.5 key encoding: keys
 *          encoded once per record, sorted as bytes; --fn and --bin
 * revision 6af871c9 20261114 063553 PST Sat --- r0.4.2 owned IPv6 parser
 *          replaces inet_pton(), whose result differed between hosts
 * revision 6af82211 20261114 005545 PST Sat --- r0.4 manual: BASH FUNCTION
 * revision 6af81dc6 20261114 003726 PST Sat --- r0.3 -b outline sort
 * revision 6af81678 20261114 000616 PST Sat --- r0.2 memory budget,
 *          spill and merge, streaming check; key-option rule in --help
 * revision 6af8010b 20261113 223451 PST Fri --- r0.1 in-memory path
 *
 * (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 */
#define _XOPEN_SOURCE 700
#define _DARWIN_C_SOURCE 1
#define _NETBSD_SOURCE 1

#include <sys/types.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SRT_REV "srt r0.6 6af8a908"
#define CHUNK ((size_t)4 << 20)     /* largest input chunk, bytes */
#define CHUNK_MIN ((size_t)8 << 10)
#define MEM_MIN ((size_t)64 << 10)  /* smallest effective budget */
#define RD_MIN ((size_t)4096)       /* smallest read / merge buffer */
#define OPT_HELP 256                /* long-only option codes */
#define OPT_MEM 257
#define OPT_FN 258
#define OPT_BIN 259

typedef unsigned char uc;
typedef unsigned long long u64;

struct kopt { int type; int f, i, r; };     /* type: 0 bytes, or d g H n v x */
struct key { long col; struct kopt o; int own; };   /* col < 0: from the end */
struct rec { const uc *p; size_t n; u64 pre; };   /* pre: prefix or -R tag */
struct fld { const uc *p; size_t n; };
struct run { off_t off, len; };

static struct kopt G;               /* global ordering options */
static int gset;                    /* any global ordering option given */
static struct key *K;               /* named keys, in order */
static size_t nK, maxcol;
static uc *iskey;                   /* iskey[col] for col <= maxcol */
static int o_check, o_uniq, o_unstable, o_blocks, o_rand, o_dups, have_t;
static uc sep, term = '\n';
static const char *o_out, *o_tmp;
static size_t o_mem, budget;
static int whole, fast;             /* comparator shape, set once */
static char tmp_path[4096];         /* live -o temporary, or "" */

/* ---- diagnostics: the one fatal path -------------------------------- */

static void cleanup(void) {
    if (tmp_path[0] && strstr(tmp_path, "/.srt.")) unlink(tmp_path);
    tmp_path[0] = 0;
}

static void die(const char *fmt, ...) {
    va_list ap;
    fputs("srt: ", stderr);
    va_start(ap, fmt); vfprintf(stderr, fmt, ap); va_end(ap);
    fputc('\n', stderr);
    cleanup();
    exit(2);
}

static void bad(const char *fmt, ...) {      /* usage error */
    va_list ap;
    fputs("srt: ", stderr);
    va_start(ap, fmt); vfprintf(stderr, fmt, ap); va_end(ap);
    fputs("\nsrt: -h for usage, --help for the manual\n", stderr);
    exit(2);
}

static void on_signal(int s) {
    (void)s;
    if (tmp_path[0]) unlink(tmp_path);
    _exit(130);
}

static void *xmalloc(size_t n) {
    void *p = malloc(n ? n : 1);
    if (!p) die("out of memory (%lu bytes); see --mem", (unsigned long)n);
    return p;
}

static void *xrealloc(void *o, size_t n) {
    void *p = realloc(o, n ? n : 1);
    if (!p) die("out of memory (%lu bytes); see --mem", (unsigned long)n);
    return p;
}

/* ---- text ----------------------------------------------------------- */

static const char USAGE[] =
"usage: srt [-cCuDSbRZ] [-dfgHinrvx] [-k [col[opts][,col[opts]]...]]\n"
"           [-t char] [-o output] [-T dir] [--mem N[bkmg]] [file ...]\n"
"       srt -h | --help | -V | --version      (--fn | --bin: see --help)\n"
"  -c  check, report disorder on stderr   -C  check, exit status only\n"
"  -u  unique   -D  only duplicates   -S  allow unstable   -R  shuffle\n"
"  -b  outline sort: sort each block of equally indented lines\n"
"  -Z  NUL-terminated records\n"
"  -d dictionary  -f fold case  -g general numeric  -H human numeric\n"
"  -i ignore nonprinting  -n numeric  -r reverse  -v version  -x hex\n"
"  -k5,3  sort by column 5, then 3, then the remaining columns in order.\n"
"         Columns are words; -k-1 is the last. The highest column named\n"
"         runs to the end of the record when it is compared as text.\n"
"  -k5n,3r  letters on a column REPLACE the global options for that\n"
"           column: -n -k1r is reversed text; write -k1nr for numbers\n"
"  -t char  column separator (default: runs of blanks)\n"
"  --help  full manual\n";

/* The manual. Each element stays under the C99 4095-byte literal limit.
 * srt.1 is generated from this text by "make man". */
static const char *const MANUAL[] = {
"NAME\n"
"\n"
"    srt - sort for system operators\n"
"\n"
"SYNOPSIS\n"
"\n"
"    srt [-cCuDSbRZ] [-dfgHinrvx] [-k [col[opts][,col[opts]]...]]\n"
"        [-t char] [-o output] [-T dir] [--mem N[bkmg]] [file ...]\n"
"    srt -h | --help | -V | --version\n"
"    srt --fn ... | srt --bin ...\n"
"\n"
"DESCRIPTION\n"
"\n"
"    srt sorts the records of all input files together and writes one\n"
"    result. With no file, or for the file name -, it reads standard\n"
"    input. The same input gives the same output on Linux, Darwin and\n"
"    NetBSD: order is by byte value and the locale environment is not\n"
"    consulted.\n"
"\n"
"    The sort is stable: records that compare equal keep their input\n"
"    order, files in operand order.\n"
"\n"
"    srt is not a drop-in for sort(1). Read DIFFERENCES before pointing\n"
"    an existing script at it.\n"
"\n"
"OPTIONS\n"
"\n"
"    -c, --check\n"
"        Check each input independently instead of sorting. For each\n"
"        input out of order, write one line to standard error:\n"
"            srt: name:line: disorder\n"
"        where line is the first record found out of order and standard\n"
"        input is named -. Nothing is written to standard output. Exit 1\n"
"        if any input is out of order. With -u, equal neighbours are a\n"
"        disorder too. Checking reads each input once and holds two\n"
"        records at a time.\n"
"    -C  As -c, with no report: exit status only.\n"
"    -o output, --output output\n"
"        Write the result to output. It may name an input file. The\n"
"        result is written beside the destination, synced, and renamed\n"
"        over it, so a failed run leaves the original intact.\n"
"    -T dir, --tmp-dir dir\n"
"        Directory for the spill file. Default: TMPDIR, then /var/tmp.\n"
"    --mem N[bkmg]\n"
"        Memory budget: bytes (b, the default), or k, m, g in powers\n"
"        of 1024. Overrides SRT_MEM. See MEMORY.\n",
"    -D, --duplicates\n"
"        Write only records whose named columns occur more than once:\n"
"        every member of every group of two or more records that\n"
"        compare equal on all the columns named in -k, each column\n"
"        under its own options. Groups come out together, in sorted\n"
"        order. With no -k the test is the whole record, so repeated\n"
"        lines are written. Under -D a named column is exactly its\n"
"        word (see THE LAST COLUMN). With -u, identical records are\n"
"        reduced to one first. Not combinable with -c, -C, -R or -b.\n"
"    -u, --unique\n"
"        Write only the first of each set of records that compare equal.\n"
"        Because every column takes part in comparison (see KEYS), this\n"
"        removes whole-record duplicates, as the ordering options see\n"
"        them.\n"
"    -S  Do not require a stable sort. Records that compare equal may\n"
"        come out in any order, and with -u any one of them may be the\n"
"        one kept; the choice can differ between hosts. Without -S the\n"
"        first in input order is kept, everywhere.\n"
"    -R, --random\n"
"        Shuffle: write the records in uniformly random order. This is\n"
"        not the hash-of-keys order of other sorts; equal records are\n"
"        not grouped. With -u, byte-identical records are removed.\n"
"        Not combinable with ordering options, -k, -b, -c or -C.\n"
"    -b, --respect-blanks\n"
"        Outline sort: lines that share a parent and an indent are\n"
"        sorted among themselves, and each line keeps the more deeply\n"
"        indented lines beneath it. See OUTLINE SORT.\n"
"    -Z, --zero-terminated\n"
"        Records end in NUL instead of newline, on input and output.\n"
"    -h  Print a usage summary.\n"
"    --help\n"
"        Print this manual, through a pager when standard output is a\n"
"        terminal (PAGER, else less, else more).\n"
"    -V, --version\n"
"        Print the revision.\n"
"    --fn, --bin\n"
"        Choose between the two forms of srt, the binary and the bash\n"
"        function. --fn allows only the function: the function then\n"
"        never hands over to a binary, and the binary, given --fn,\n"
"        stops with an error. --bin allows only the binary: the\n"
"        function hands over to the binary on PATH and stops with an\n"
"        error if there is none; the binary accepts --bin and does\n"
"        nothing. With neither, the function hands over when a binary\n"
"        named srt is on PATH and does the work itself otherwise.\n"
"        See BASH FUNCTION.\n"
"    -s, -m\n"
"        Accepted and ignored: stable order and multi-file input are\n"
"        already how srt behaves.\n"
"\n",
"ORDERING OPTIONS\n"
"\n"
"    -d, --dictionary\n"
"        Compare only blanks and alphanumerics. Bytes 0x80 and above\n"
"        are kept, so UTF-8 letters take part.\n"
"    -f, --fold-case\n"
"        Fold ASCII a-z to A-Z before comparing.\n"
"    -g, --general-numeric\n"
"        Compare as floating point, read by strtod: exponents, inf and\n"
"        nan are understood. Order: non-numbers, nan, then by value.\n"
"        Values are doubles; integers above 2^53 lose exactness. Use -n\n"
"        for exact comparison at any length.\n"
"    -H, --human-numeric\n"
"        Compare a number with an optional scale letter K M G T P E Z Y\n"
"        (either case): by sign, then scale, then number. The scale is\n"
"        not multiplied out, so 2048K sorts before 1M. Suited to the\n"
"        output of du -h and df -h.\n"
"    -i, --ignore-nonprinting\n"
"        Skip ASCII control bytes and DEL when comparing.\n"
"    -n, --numeric\n"
"        Compare by numeric value: optional blanks, optional -, digits,\n"
"        optional . and digits. No exponent, no thousands separator.\n"
"        A key with no leading number is zero. Exact at any length.\n"
"    -r, --reverse\n"
"        Reverse the comparison. Equal records still keep input order.\n"
"    -v, --version-sort\n"
"        See VERSION SORT.\n"
"    -x, --hex-numeric\n"
"        Compare as hexadecimal integers: optional blanks, optional -,\n"
"        optional 0x, then digits 0-9 and a-f in either case. Leading\n"
"        zeros do not count. Exact at any length. A key with no\n"
"        hexadecimal digit is zero. Under -x a word spelled from a-f\n"
"        is a number, so put the letter on the columns that hold\n"
"        hexadecimal (-k4x) rather than giving -x over mixed columns.\n"
"\n"
"    At most one of -d -g -H -n -v -x applies to a column. See GLOBAL\n"
"    AND KEY OPTIONS for how these combine with -k.\n"
"\n",
"KEYS\n"
"\n"
"    -k [col[opts][,col[opts]]...]\n"
"        Sort by the named columns in the order given, then by the\n"
"        remaining columns left to right. For six columns, -k5n,3\n"
"        sorts in column order 5,3,1,2,4,6; -k5,3, where column 5 is\n"
"        text, sorts 5 and 6 as one column, then 3,1,2,4 (see THE\n"
"        LAST COLUMN). -k5 -k3 is the same as -k5,3.\n"
"        opts are ordering letters from dfgHinrvx. Naming a column\n"
"        twice is an error. Character offsets within a column are not\n"
"        supported.\n"
"\n"
"        A column is a word, as $1, $2 ... are in awk: without -t,\n"
"        columns are separated by runs of spaces and tabs and leading\n"
"        blanks are ignored, so the widths and alignment of the input\n"
"        do not matter. Columns count from 1.\n"
"\n"
"        A negative number counts from the end of the record: -k-1 is\n"
"        the last column, -k-2 the one before it. With -t/ the last\n"
"        column of a path is its base name.\n"
"\n"
"        -k with no list names no column: the whole record is the key,\n"
"        which is what srt does with no -k at all. The word after -k\n"
"        is taken as the list only when it reads as one (5, or\n"
"        5x,4x,6, or -1); any other word is left as an option or a\n"
"        file. For a file named like a list, write ./5 or put --\n"
"        before it. To reverse, write the r after the column (-k5r)\n"
"        or give -r; -kr5 is not accepted.\n"
"    -t char, --separator char\n"
"        Columns are separated by each occurrence of char, so empty\n"
"        columns exist. char is one byte; \\t and \\0 are accepted.\n"
"\n"
"    Two records that differ only in the amount of blank space between\n"
"    columns compare equal on those columns. A record with fewer\n"
"    columns than a key names has an empty key there. With neither -k\n"
"    nor -t the whole record is one key.\n"
"\n"
"THE LAST COLUMN\n"
"\n"
"    srt reads a record as far as -k names it. The highest column\n"
"    named is the last one; what follows its word is the rest of the\n"
"    record.\n"
"      - When that column is compared as text (no type letter, or d\n"
"        or v), it runs to the end of the record, blanks and all. In\n"
"        -k5x,4x,6 column 6 is a whole file name, spaces included.\n"
"      - When it is compared as a number (n g H x), it is its word\n"
"        alone, and the rest of the record is one further column,\n"
"        compared last. In -k5x,4x the name is that further column.\n"
"    Either way no part of a record is ignored. To sort on a later\n"
"    word in its own right, name its column.\n"
"\n"
"    Two cases read every named column as exactly one word. Under -D\n"
"    the test is the named columns and nothing more, so the highest\n"
"    one is not extended; the rest of the record is still one further\n"
"    column, compared last. And when any column is counted from the\n"
"    end, every word of the record is a column and none is extended.\n"
"\n",
"GLOBAL AND KEY OPTIONS\n"
"\n"
"    An ordering option can be given in two places, and the place\n"
"    decides which columns it reaches.\n"
"\n"
"    Global: an ordering option given on its own, as in -n or -fr,\n"
"    wherever it appears on the command line. The global options form\n"
"    one set.\n"
"\n"
"    Key: ordering letters written directly after a column number\n"
"    inside -k, as in -k1r or -k5n,3fr. Each such column has its own\n"
"    set, made of exactly the letters written on it.\n"
"\n"
"    Every column is compared with exactly one set:\n"
"      - a column named in -k WITH letters uses its own set, and the\n"
"        global set does not reach it at all;\n"
"      - a column named in -k with NO letters uses the global set;\n"
"      - the remaining columns, not named in -k, use the global set.\n"
"\n"
"    Key letters replace the global set for their column. They are\n"
"    never added to it. This is the rule most often misread:\n"
"\n"
"        srt -n -k1r\n"
"\n"
"    Here column 1 carries a letter, so its set is {r} and nothing\n"
"    else. The global -n no longer reaches column 1. Column 1 is\n"
"    compared as text, reversed; the other columns are compared\n"
"    numerically. Given the records 2, 10 and 1 the result is\n"
"    2, 10, 1: reversed text order, because as text 2 sorts after 10.\n"
"\n"
"    To compare column 1 numerically and reversed, write both letters\n"
"    on the column:\n"
"\n"
"        srt -k1nr           column 1 numeric reversed, rest as text\n"
"        srt -n -k1nr        column 1 numeric reversed, rest numeric\n"
"\n"
"    The same rule read the other way lets one column opt out of a\n"
"    global option:\n"
"\n"
"        srt -r -k5n,3       column 5 numeric ascending (set {n});\n"
"                            column 3 and the rest reversed text\n"
"        srt -f -k2n         column 2 numeric (set {n}, not folded);\n"
"                            the other columns case-folded\n"
"\n"
"    A column with no letters keeps the global set, so these two are\n"
"    the same, with every column numeric and reversed:\n"
"\n"
"        srt -nr -k3,1\n"
"        srt -k3nr,1nr -nr\n"
"\n"
"    The position of a global option on the command line does not\n"
"    matter: -n -k1r and -k1r -n are identical. This is also the rule\n"
"    of sort(1), where sort -n -k1,1r compares field 1 as reversed\n"
"    text.\n"
"\n",
"OUTLINE SORT\n"
"\n"
"    -b treats the input as an outline. The indent of a line is the\n"
"    exact run of spaces and tabs it begins with. Spaces and tabs may\n"
"    be mixed, but they are never converted or measured: two indents\n"
"    are the same only when they are the same bytes, and a tab is not\n"
"    equal to any number of spaces.\n"
"\n"
"    Parent. A line belongs to the nearest line above it whose indent\n"
"    is a proper beginning of its own, provided no line in between has\n"
"    closed that block. A block is closed by the first following line\n"
"    whose indent does not begin with the block's indent. A line with\n"
"    no such parent is at the top level.\n"
"\n"
"    Group. The children of one parent that have byte-identical\n"
"    indents form a group. Only a group is sorted; the ordering\n"
"    options, -k and -t apply to the line with its indent removed.\n"
"    Each line moves together with everything beneath it, and the\n"
"    lines beneath it are sorted in turn by the same rules. Children\n"
"    of one parent with different indents form separate groups, which\n"
"    stay in the order in which each group first appears.\n"
"\n"
"    Blank lines (empty, or only spaces and tabs) are not sorted. Each\n"
"    stays directly below the line it follows and moves with it.\n"
"\n"
"    Example. Given\n"
"        servers:\n"
"          web2\n"
"            port 80\n"
"          web1\n"
"            port 443\n"
"        clients:\n"
"          zeta\n"
"          alpha\n"
"    srt -b writes\n"
"        clients:\n"
"          alpha\n"
"          zeta\n"
"        servers:\n"
"          web1\n"
"            port 443\n"
"          web2\n"
"            port 80\n"
"\n"
"    With -u, a line equal to the one kept before it in its group is\n"
"    removed only if nothing is beneath it and no blank line follows\n"
"    it; a line that carries a block is always kept, so -u never\n"
"    discards lines it did not compare.\n"
"\n"
"    With -c or -C, every group must be in order.\n"
"\n"
"    -b holds the whole input in memory. If the memory budget is\n"
"    reached srt stops with an error naming --mem, and writes nothing.\n"
"    -b cannot be combined with -R.\n"
"\n",
"VERSION SORT\n"
"\n"
"    -v orders version numbers, versioned archive names, host and\n"
"    interface names, and IPv4 and IPv6 addresses and networks.\n"
"\n"
"    Runs of digits compare by numeric value at any length; all other\n"
"    bytes compare by value. So 9.255.0.1 < 10.2.0.1 < 10.10.0.1,\n"
"    10.0.0.0 < 10.0.0.0/8 < 10.0.0.0/16, and node2 < node10.\n"
"\n"
"    Three refinements:\n"
"    1. A trailing run of suffixes such as .tar.gz (a dot, a letter,\n"
"       then letters and digits) is set aside. Stems compare first,\n"
"       whole keys break the tie: foo-1.2.tar.gz < foo-1.2.1.tar.gz.\n"
"    2. ~ sorts before everything, including the end of the key:\n"
"       1.0~rc1 < 1.0.\n"
"    3. A key that is an IPv6 address, with optional /length, compares\n"
"       by its 128-bit value, then by length; compression, leading\n"
"       zeros and letter case do not matter. IPv6 keys sort after all\n"
"       other keys, so a mixed column lists IPv4 first.\n"
"\n"
"    Known differences from the version sort of other tools: 1.0.1\n"
"    sorts before 1.0a; numerically equal runs order by fewer leading\n"
"    zeros first (1.5 < 1.05); package epochs and release fields are\n"
"    not modelled. An address with a zone id (fe80::1%eth0), or with\n"
"    a leading zero in a dotted-quad octet (::1.2.3.04), is not taken\n"
"    as IPv6 and sorts as ordinary text; this is the same on every\n"
"    host and does not depend on the system library.\n"
"\n"
"MEMORY\n"
"\n"
"    Input that fits the memory budget is sorted in memory and no\n"
"    temporary file is created. When input exceeds the budget, srt\n"
"    sorts what it holds, appends it as a run to a spill file in the\n"
"    -T directory, and continues; at the end the runs are merged. The\n"
"    result is identical either way, including the order of equal\n"
"    records.\n"
"\n"
"    The default budget is half of physical memory, lowered to half of\n"
"    any address-space or data resource limit; 1 GiB where physical\n"
"    memory cannot be queried. --mem or SRT_MEM sets it explicitly;\n"
"    values below 64k are raised to 64k. One record larger than the\n"
"    budget is still sorted; the budget decides when to spill, not how\n"
"    long a record may be.\n"
"\n"
"    The spill file is unlinked as soon as it is created, so it never\n"
"    appears in a listing and is released on any exit. The -T file\n"
"    system needs free space about equal to the input, twice that when\n"
"    the runs must be merged in more than one pass. A full file system\n"
"    is an error, exit 2, and no partial result is written to -o.\n"
"\n"
"    For a keyed sort, the keys of each batch held in memory are\n"
"    encoded once into byte strings that compare in srt order, within\n"
"    a quarter of the budget. A batch whose keys would need more is\n"
"    compared record by record instead; the result is the same.\n"
"\n"
"    SRT_STATS=1 reports on standard error the budget, the number of\n"
"    runs and merge passes, and how many batches were sorted on\n"
"    encoded keys and how many by direct comparison.\n"
"\n",
"BASH FUNCTION\n"
"\n"
"    srt.fn.bash defines a shell function named srt, for hosts where\n"
"    the binary is not installed. When a binary named srt is on PATH\n"
"    the function runs it, unless --fn is given; with --bin it runs\n"
"    the binary or nothing.\n"
"\n"
"    The function gives the same result as the binary. It encodes\n"
"    every key with awk so that the native sort(1), run in the C\n"
"    locale and comparing bytes only, puts the records in srt order;\n"
"    no ordering option of the native sort is relied on. It needs\n"
"    bash, awk, sort, cat, cp, mktemp and mv.\n"
"\n"
"    Where the function differs from the binary:\n"
"      -b and -Z are not available; the function says so, exit 2.\n"
"      -t takes one ASCII character; \\0 is not available.\n"
"      Input containing a byte from 0x01 to 0x04 is refused, exit 2.\n"
"      -g does not read hexadecimal floating point; refused, exit 2.\n"
"      -R draws from the awk generator, seeded by the shell per run.\n"
"      -S has no effect; the result is always stable.\n"
"      --mem and SRT_MEM are passed to the native sort where it has\n"
"          a memory option and are otherwise ignored; SRT_STATS is\n"
"          not available.\n"
"      The input is copied to the -T directory before it is sorted,\n"
"          and the function is much slower than the binary.\n"
"\n",
"DIFFERENCES\n"
"\n"
"    From the sort(1) of Linux, Darwin and NetBSD:\n"
"    -k a,b  is column a then column b, not fields a through b.\n"
"    -b      is outline sort, not ignore-leading-blanks.\n"
"    -S      is allow-unstable, not a memory size (use --mem).\n"
"    -R      is a true shuffle.\n"
"    -V      prints the revision; version sort is -v.\n"
"    -h      prints usage; human-numeric is -H.\n"
"    -k      with no list is accepted and names no column.\n"
"    -kN     reads column N as a word with its blanks dropped, where\n"
"            sort(1) keeps leading blanks in the field; and the highest\n"
"            column named takes the rest of the record.\n"
"    -x, -D and -k-N have no counterpart in sort(1).\n"
"    Not supported: character offsets in keys, +pos -pos, -M, -l,\n"
"    --parallel, --batch-size, --compress-program, --files0-from,\n"
"    --debug, --random-source, --sort, and algorithm selection.\n"
"    Locale collation is never applied.\n"
"\n"
"ENVIRONMENT\n"
"\n"
"    SRT_MEM    memory budget, as --mem.\n"
"    SRT_STATS  when set and not empty, report spill statistics.\n"
"    TMPDIR     spill directory when -T is not given.\n"
"    PAGER      pager for --help.\n"
"    LANG and LC_* are not consulted.\n"
"\n"
"EXIT STATUS\n"
"\n"
"    0  success; with -c or -C, every input is in order\n"
"    1  with -c or -C, some input is out of order\n"
"    2  error\n"
"\n"
"\n",
"EXAMPLES\n"
"\n"
"  Columns\n"
"    srt -k5,3 table                    by column 5, then 3, then the rest\n"
"    srt -t: -k3n /etc/passwd           by uid, then the other fields\n"
"    ps aux | srt -k4nr,1               by memory descending, then user\n"
"    srt -n -k1r table                  column 1 as reversed TEXT, the rest\n"
"                                       numeric: letters on a column\n"
"                                       replace the global options\n"
"    srt -k1nr table                    column 1 numeric, descending\n"
"    srt -r -k5 table                   -r reaches a column named without\n"
"                                       letters: column 5 descending, and\n"
"                                       the rest; with letters write -k5xr\n"
"    srt -k table                       no column named: whole records\n"
"\n"
"  Kinds of key\n"
"    srt -v hosts                       addresses, networks, host names\n"
"    ls | srt -v                        foo-1.2.tar.gz, then foo-1.10.tar.gz\n"
"    du -h | srt -Hr                    largest first\n"
"    srt -k2g readings                  1e-3, 0.5, 2.5e3 by value\n"
"    srt -k4x listing                   column 4 as hexadecimal: a3d, 187c,\n"
"                                       1c40a in that order, however the\n"
"                                       column is padded\n"
"    srt -f -k2n names                  column 2 numeric, the rest folded\n"
"\n"
"  The last column\n"
"    srt -k5x,4x,6 listing              hex time, hex size, then the name:\n"
"                                       column 6 runs to the end of the\n"
"                                       record, so 'My File' is one key\n"
"    srt -k5x,4x listing                the same, with the name compared\n"
"                                       last, after the other columns\n"
"    ps aux | srt -k11                  by command line, arguments included\n"
"\n"
"  Columns counted from the end\n"
"    srt -t/ -k-1 paths                 by base name, then by directory\n"
"    srt -t. -k-1 names                 by file suffix\n"
"    srt -k-1n table                    by the last column, as a number\n"
"\n"
"  Duplicates\n"
"    srt -D lines                       lines that occur more than once\n"
"    srt -D -k3 listing                 records sharing column 3: files\n"
"                                       with the same hash, grouped\n"
"    srt -D -k3,4x listing              the same hash and the same size\n"
"    srt -t/ -D -k-1 paths              the same base name in different\n"
"                                       directories\n"
"    srt -u -D -k1 table                distinct records sharing column 1\n"
"\n"
"  Whole files\n"
"    srt -u -o list list                sort and remove repeats, in place\n"
"    srt -c a.txt b.txt || echo fix     check several files; -C is silent\n"
"    srt -cu table                      sorted, and no record repeated?\n"
"    srt -R lines                       shuffle\n"
"    srt -b outline.yml                 sort each block, keep the nesting\n"
"    find . -print0 | srt -Z            names that contain newlines\n"
"\n"
"  Resources and forms\n"
"    srt --mem 2g -T /scratch big.log   bound memory, spill to /scratch\n"
"    SRT_STATS=1 srt -k2n big >/dev/null   what the budget did\n"
"    srt --bin -k2n table               the binary, or an error\n"
"    srt --fn -k2n table                the bash function, even where the\n"
"                                       binary is installed\n"
"\n"
"SEE ALSO\n"
"\n"
"    cksh(1), ff(1)\n"
"\n"
"REVISION\n"
"\n"
"    r0.6.\n"
};

static void manual(FILE *f) {
    size_t i;
    for (i = 0; i < sizeof MANUAL / sizeof MANUAL[0]; i++) fputs(MANUAL[i], f);
}

/* --help: pager on a terminal, plain otherwise. Does not need man(1). */
static void help(void) {
    const char *try[3];
    size_t i;
    try[0] = getenv("PAGER"); try[1] = "less"; try[2] = "more";
    if (isatty(STDOUT_FILENO)) {
        signal(SIGPIPE, SIG_IGN);            /* reader may quit early */
        for (i = 0; i < 3; i++) {
            FILE *p;
            int st;
            if (!try[i] || !try[i][0]) continue;
            fflush(stdout);
            if (!(p = popen(try[i], "w"))) continue;
            manual(p);
            st = pclose(p);
            if (st != -1 && WIFEXITED(st) && WEXITSTATUS(st) != 127
                && WEXITSTATUS(st) != 126) exit(0);
        }
    }
    manual(stdout);
    if (fflush(stdout) || ferror(stdout)) die("write error: %s", strerror(errno));
    exit(0);
}

/* ---- byte classes (C locale, owned) --------------------------------- */

static int isdig(int c) { return c >= '0' && c <= '9'; }
static int isalph(int c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'); }
static int isblnk(int c) { return c == ' ' || c == '\t'; }
static int fold(int c) { return (c >= 'a' && c <= 'z') ? c - 32 : c; }

/* ---- comparators ---------------------------------------------------- */

static int plain(const uc *a, size_t la, const uc *b, size_t lb) {
    size_t m = la < lb ? la : lb;
    int c = m ? memcmp(a, b, m) : 0;
    if (c) return c < 0 ? -1 : 1;
    return la < lb ? -1 : la > lb;
}

/* bytes with -d, -i, -f filters */
static int textcmp(const uc *a, size_t la, const uc *b, size_t lb,
                   const struct kopt *o) {
    size_t i = 0, j = 0;
    int d = o->type == 'd';
    if (!d && !o->i && !o->f) return plain(a, la, b, lb);
    for (;;) {
        int ca, cb;
#define SKIP(s, k, n) \
        while (k < n && ((d && !(isblnk(s[k]) || isdig(s[k]) || isalph(s[k]) \
                                 || s[k] >= 0x80)) \
                      || (o->i && (s[k] < 0x20 || s[k] == 0x7f)))) k++
        SKIP(a, i, la);
        SKIP(b, j, lb);
#undef SKIP
        if (i >= la || j >= lb) return i < la ? 1 : j < lb ? -1 : 0;
        ca = o->f ? fold(a[i]) : a[i];
        cb = o->f ? fold(b[j]) : b[j];
        if (ca != cb) return ca < cb ? -1 : 1;
        i++; j++;
    }
}

/* -n: exact decimal comparison without conversion */
struct num { int neg; const uc *ip, *fp; size_t il, fl, end; };

static void pnum(const uc *s, size_t n, struct num *x) {
    size_t i = 0, k;
    while (i < n && isblnk(s[i])) i++;
    x->neg = 0;
    if (i < n && s[i] == '-') { x->neg = 1; i++; }
    while (i < n && s[i] == '0') i++;
    for (k = i; k < n && isdig(s[k]); k++) ;
    x->ip = s + i; x->il = k - i;
    x->fp = s + k; x->fl = 0; x->end = k;
    if (k < n && s[k] == '.') {
        size_t f = k + 1, e = f;
        while (e < n && isdig(s[e])) e++;
        x->end = e;
        while (e > f && s[e - 1] == '0') e--;
        x->fp = s + f; x->fl = e - f;
    }
    if (!x->il && !x->fl) x->neg = 0;        /* -0 is 0 */
}

static int magcmp(const struct num *x, const struct num *y) {
    int c;
    if (x->il != y->il) return x->il < y->il ? -1 : 1;
    if (x->il && (c = memcmp(x->ip, y->ip, x->il))) return c < 0 ? -1 : 1;
    return plain(x->fp, x->fl, y->fp, y->fl);   /* trailing zeros trimmed */
}

static int numcmp(const uc *a, size_t la, const uc *b, size_t lb) {
    struct num x, y;
    int c;
    pnum(a, la, &x); pnum(b, lb, &y);
    if (x.neg != y.neg) return x.neg ? -1 : 1;
    c = magcmp(&x, &y);
    return x.neg ? -c : c;
}

/* -H: sign, then scale letter, then number */
static int hrank(const uc *s, size_t n, size_t end) {
    static const char sc[] = "KMGTPEZY";
    const char *p;
    if (end >= n) return 0;
    p = strchr(sc, fold(s[end]));
    return (p && *p) ? (int)(p - sc) + 1 : 0;
}

static int humcmp(const uc *a, size_t la, const uc *b, size_t lb) {
    struct num x, y;
    int rx, ry, c;
    pnum(a, la, &x); pnum(b, lb, &y);
    if (x.neg != y.neg) return x.neg ? -1 : 1;
    rx = hrank(a, la, x.end); ry = hrank(b, lb, y.end);
    c = rx != ry ? (rx < ry ? -1 : 1) : magcmp(&x, &y);
    return x.neg ? -c : c;
}

/* -g: strtod; class 0 non-number, 1 nan, 2 value */
static int gparse(const uc *s, size_t n, double *v) {
    char b[128], *e;
    if (n >= sizeof b) n = sizeof b - 1;
    memcpy(b, s, n); b[n] = 0;
    *v = strtod(b, &e);
    if (e == b) return 0;
    return *v != *v ? 1 : 2;
}

static int gencmp(const uc *a, size_t la, const uc *b, size_t lb) {
    double x, y;
    int cx = gparse(a, la, &x), cy = gparse(b, lb, &y);
    if (cx != cy) return cx < cy ? -1 : 1;
    if (cx != 2) return 0;
    return x < y ? -1 : x > y;
}

/* -v: natural order; ~ lowest, then end of key, then bytes */
static int vord(int c, int f) { return c == '~' ? -1 : 1 + (f ? fold(c) : c); }

static int natcmp(const uc *a, size_t la, const uc *b, size_t lb, int f) {
    size_t i = 0, j = 0;
    int tie = 0;
    for (;;) {
        int ca, cb;
        if (i < la && j < lb && isdig(a[i]) && isdig(b[j])) {
            size_t si = i, sj = j, zi, zj, na, nb;
            int c;
            while (i < la && a[i] == '0') i++;
            while (j < lb && b[j] == '0') j++;
            zi = i; zj = j;
            while (i < la && isdig(a[i])) i++;
            while (j < lb && isdig(b[j])) j++;
            na = i - zi; nb = j - zj;
            if (na != nb) return na < nb ? -1 : 1;
            if (na && (c = memcmp(a + zi, b + zj, na))) return c < 0 ? -1 : 1;
            if (!tie && zi - si != zj - sj) tie = zi - si < zj - sj ? -1 : 1;
            continue;
        }
        ca = i < la ? vord(a[i], f) : 0;
        cb = j < lb ? vord(b[j], f) : 0;
        if (ca != cb) return ca < cb ? -1 : 1;
        if (i >= la) return tie;             /* both ended */
        i++; j++;
    }
}

/* length of key with trailing (.[A-Za-z~][A-Za-z0-9~]*)* set aside */
static size_t stemlen(const uc *s, size_t n) {
    size_t i = n;
    for (;;) {
        size_t j = i;
        while (j > 0 && (isdig(s[j - 1]) || isalph(s[j - 1]) || s[j - 1] == '~')) j--;
        if (j == 0 || j == i || s[j - 1] != '.') break;
        if (!(isalph(s[j]) || s[j] == '~')) break;
        i = j - 1;
    }
    return i;
}

static int hexval(int c) {
    if (isdig(c)) return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* Whole key is an IPv6 address with optional /length. The parser is
 * owned, not inet_pton(): r0.4 used the library call and the Darwin
 * and Linux libraries disagreed on what is an address (found by the
 * function-parity tests on Darwin), which gave one input two orders.
 * Rules: groups of 1-4 hex digits; "::" at most once, standing for at
 * least one group; a final dotted quad of four decimal octets, each 0
 * or without a leading zero; no zone id; /length of 1-3 digits, at
 * most 128. srt.fn.bash implements the same rules in awk. */
static int ip6(const uc *s, size_t n, uc out[16], int *plen) {
    const uc *sl;
    uc b[16];
    size_t m = n, i = 0, j, k;
    int ng = 0, dc = -1;                     /* bytes so far; "::" position */
    if (n < 2 || n >= 64 || !memchr(s, ':', n)) return 0;
    *plen = -1;
    if ((sl = memchr(s, '/', n))) {
        int v = 0, d = 0;
        m = (size_t)(sl - s);
        for (k = m + 1; k < n; k++, d++) {
            if (!isdig(s[k]) || d >= 3) return 0;
            v = v * 10 + (s[k] - '0');
        }
        if (!d || v > 128) return 0;
        *plen = v;
    }
    if (m && s[0] == ':') {                  /* a leading colon must be "::" */
        if (m < 2 || s[1] != ':') return 0;
        dc = 0; i = 2;
    }
    while (i < m) {
        for (j = i; j < m && s[j] != ':'; j++) ;
        if (j == i) return 0;                /* empty group */
        if (memchr(s + i, '.', j - i)) {     /* dotted quad, last 32 bits */
            int part = 0;
            if (j != m || ng > 12) return 0;
            for (k = i; ; part++) {
                int v = 0, d = 0;
                size_t z = k;
                for (; k < m && isdig(s[k]) && d < 3; k++, d++) v = v * 10 + (s[k] - '0');
                if (!d || v > 255 || (d > 1 && s[z] == '0') || part > 3) return 0;
                b[ng++] = (uc)v;
                if (k == m) break;
                if (s[k] != '.') return 0;
                k++;
            }
            if (part != 3) return 0;
        } else {
            int v = 0;
            if (j - i > 4 || ng > 14) return 0;
            for (k = i; k < j; k++) {
                int h = hexval(s[k]);
                if (h < 0) return 0;
                v = v << 4 | h;
            }
            b[ng++] = (uc)(v >> 8); b[ng++] = (uc)(v & 0xff);
        }
        i = j;
        if (i < m) {                         /* at a colon */
            if (i + 1 < m && s[i + 1] == ':') {
                if (dc >= 0) return 0;
                dc = ng; i += 2;
            } else if (++i == m) return 0;   /* trailing single colon */
        }
    }
    if (dc < 0) {
        if (ng != 16) return 0;
        memcpy(out, b, 16);
    } else {
        if (ng > 14) return 0;
        memset(out, 0, 16);
        memcpy(out, b, (size_t)dc);
        memcpy(out + 16 - (ng - dc), b + dc, (size_t)(ng - dc));
    }
    return 1;
}

static int vercmp(const uc *a, size_t la, const uc *b, size_t lb, int f) {
    uc xa[16], xb[16];
    int pa = 0, pb = 0, c;
    int va = ip6(a, la, xa, &pa), vb = ip6(b, lb, xb, &pb);
    if (va != vb) return va ? 1 : -1;        /* IPv6 class sorts last */
    if (va) {
        if ((c = memcmp(xa, xb, 16))) return c < 0 ? -1 : 1;
        return pa < pb ? -1 : pa > pb;
    }
    c = natcmp(a, stemlen(a, la), b, stemlen(b, lb), f);
    return c ? c : natcmp(a, la, b, lb, f);
}

/* -x: hexadecimal integers, exact at any length. Optional blanks, -,
 * and 0x; leading zeros do not count; letter case does not count. */
struct hx { int neg; const uc *p; size_t n; };

static void phex(const uc *s, size_t n, struct hx *x) {
    size_t i = 0, k;
    while (i < n && isblnk(s[i])) i++;
    x->neg = 0;
    if (i < n && s[i] == '-') { x->neg = 1; i++; }
    if (i + 2 < n && s[i] == '0' && (s[i + 1] | 32) == 'x' && hexval(s[i + 2]) >= 0)
        i += 2;
    while (i < n && s[i] == '0') i++;
    for (k = i; k < n && hexval(s[k]) >= 0; k++) ;
    x->p = s + i; x->n = k - i;
    if (!x->n) x->neg = 0;                   /* -0 is 0 */
}

static int hexcmp(const uc *a, size_t la, const uc *b, size_t lb) {
    struct hx x, y;
    size_t k;
    int c = 0;
    phex(a, la, &x); phex(b, lb, &y);
    if (x.neg != y.neg) return x.neg ? -1 : 1;
    if (x.n != y.n) c = x.n < y.n ? -1 : 1;
    else
        for (k = 0; k < x.n && !c; k++) {
            int u = hexval(x.p[k]), v = hexval(y.p[k]);
            if (u != v) c = u < v ? -1 : 1;
        }
    return x.neg ? -c : c;
}

static int keycmp(const uc *a, size_t la, const uc *b, size_t lb,
                  const struct kopt *o) {
    int c;
    switch (o->type) {
    case 'n': c = numcmp(a, la, b, lb); break;
    case 'g': c = gencmp(a, la, b, lb); break;
    case 'H': c = humcmp(a, la, b, lb); break;
    case 'x': c = hexcmp(a, la, b, lb); break;
    case 'v': c = vercmp(a, la, b, lb, o->f); break;
    default:  c = textcmp(a, la, b, lb, o); break;
    }
    return o->r ? -c : c;
}

/* ---- columns -------------------------------------------------------- */

static const uc nil[1] = { 0 };
static long maxpos;                 /* highest column named, 0 if none */
static int anyneg;                  /* some key counts from the end */
static int attach;                  /* the highest named column takes the tail */

/* Split a record into columns. limit 0: every word, or every field
 * under -t, is a column. limit M: columns 1..M are words and whatever
 * follows word M is one further column, the residue. */
static size_t split(const struct rec *r, struct fld **fp, size_t *cap,
                    size_t limit) {
    const uc *s = r->p, *e = r->p + r->n;
    struct fld *f = *fp;
    size_t n = 0;
#define PUSH(P, N) do { \
        if (n == *cap) { *cap = *cap ? *cap * 2 : 32; \
            f = *fp = xrealloc(f, *cap * sizeof *f); } \
        f[n].p = (P); f[n].n = (N); n++; } while (0)
    if (have_t) {
        for (;;) {
            const uc *q = s < e ? memchr(s, sep, (size_t)(e - s)) : NULL;
            if (!q) { PUSH(s, (size_t)(e - s)); break; }
            PUSH(s, (size_t)(q - s));
            s = q + 1;
            if (limit && n == limit) { PUSH(s, (size_t)(e - s)); break; }
        }
    } else {
        for (;;) {
            const uc *q;
            while (s < e && isblnk(*s)) s++;
            if (s >= e) break;
            if (limit && n == limit) { PUSH(s, (size_t)(e - s)); break; }
            for (q = s; q < e && !isblnk(*q); q++) ;
            PUSH(s, (size_t)(q - s));
            s = q;
        }
    }
#undef PUSH
    return n;
}

/* A record as the comparator sees it: the value of each named key in
 * key order, then the remaining columns in record order.
 *
 * Columns are words up to the highest column named in -k (maxpos); the
 * rest of the record is one further column, the residue. By default
 * (attach) a text key on that highest column takes the residue with it,
 * so it runs to the end of the record; a numeric key reads its word and
 * the residue is compared last. With -D, or when a key counts from the
 * end, no column is extended; with a key counted from the end every
 * word is a column. Remaining columns are matched by their order among
 * the remaining, which is their position when no key counts from the
 * end. A missing key is an empty key. */
struct lay { struct fld *f, *k, *r; size_t capf, capr, nr; };
static struct lay LA, LB;

static void layout(const struct rec *x, struct lay *L) {
    size_t na = split(x, &L->f, &L->capf, anyneg ? 0 : (size_t)maxpos), k, c;
    const uc *end = x->p + x->n;
    if (!L->k) L->k = xmalloc((nK + 1) * sizeof *L->k);
    for (k = 0; k < nK; k++) {
        long col = K[k].col, at = col > 0 ? col : (long)na + 1 + col;
        if (at < 1 || (size_t)at > na) { L->k[k].p = nil; L->k[k].n = 0; continue; }
        L->k[k] = L->f[at - 1];
        if (attach && col == maxpos) L->k[k].n = (size_t)(end - L->k[k].p);
    }
    L->nr = 0;
    for (c = 1; c <= na; c++) {
        if (c <= maxcol && iskey[c]) continue;
        if (attach && c == (size_t)maxpos + 1) continue;   /* in the tail */
        if (anyneg) {
            for (k = 0; k < nK; k++)
                if (K[k].col < 0 && (long)na + 1 + K[k].col == (long)c) break;
            if (k < nK) continue;
        }
        if (L->nr == L->capr) {
            L->capr = L->capr ? L->capr * 2 : 32;
            L->r = xrealloc(L->r, L->capr * sizeof *L->r);
        }
        L->r[L->nr++] = L->f[c - 1];
    }
}

/* The one record comparator. Under -R the order is by random tag (pre);
 * with -R -u the tag is a keyed hash of the record, so identical records
 * meet and only identical records compare equal. */
static int reccmp(const struct rec *x, const struct rec *y) {
    size_t m, k, c;
    int r;
    if (o_rand) {
        if (x->pre != y->pre) return x->pre < y->pre ? -1 : 1;
        return o_uniq ? plain(x->p, x->n, y->p, y->n) : 0;
    }
    if (fast) {
        if (x->pre != y->pre) r = x->pre < y->pre ? -1 : 1;
        else r = plain(x->p, x->n, y->p, y->n);
        return G.r ? -r : r;
    }
    if (whole) return keycmp(x->p, x->n, y->p, y->n, &G);
    layout(x, &LA);
    layout(y, &LB);
    for (k = 0; k < nK; k++) {
        /* letters on a key replace the global set for that key (V04) */
        r = keycmp(LA.k[k].p, LA.k[k].n, LB.k[k].p, LB.k[k].n,
                   K[k].own ? &K[k].o : &G);
        if (r) return r;
    }
    m = LA.nr > LB.nr ? LA.nr : LB.nr;
    for (c = 0; c < m; c++) {
        r = keycmp(c < LA.nr ? LA.r[c].p : nil, c < LA.nr ? LA.r[c].n : 0,
                   c < LB.nr ? LB.r[c].p : nil, c < LB.nr ? LB.r[c].n : 0, &G);
        if (r) return r;
    }
    return 0;
}

/* -D: two records are in one group when every named key compares equal;
 * with no -k, when the whole records do. */
static int groupeq(const struct rec *x, const struct rec *y) {
    size_t k;
    if (!nK) return reccmp(x, y) == 0;
    layout(x, &LA);
    layout(y, &LB);
    for (k = 0; k < nK; k++)
        if (keycmp(LA.k[k].p, LA.k[k].n, LB.k[k].p, LB.k[k].n,
                   K[k].own ? &K[k].o : &G)) return 0;
    return 1;
}

/* The comparator in force: reccmp, or ecmp while a batch is sorted on
 * encoded keys (see key encoding). */
static int (*CMP)(const struct rec *, const struct rec *) = reccmp;

static int qcmp(const void *a, const void *b) { return CMP(a, b); }

/* stable top-down merge sort; t is scratch of n/2+1 records */
static void msort(struct rec *a, struct rec *t, size_t n) {
    size_t m, i, j, k;
    if (n <= 12) {
        for (i = 1; i < n; i++) {
            struct rec v = a[i];
            for (j = i; j > 0 && CMP(&v, &a[j - 1]) < 0; j--) a[j] = a[j - 1];
            a[j] = v;
        }
        return;
    }
    m = n / 2;
    msort(a, t, m);
    msort(a + m, t, n - m);
    if (CMP(&a[m - 1], &a[m]) <= 0) return;   /* already ordered */
    memcpy(t, a, m * sizeof *a);
    for (i = 0, j = m, k = 0; i < m && j < n; )
        a[k++] = CMP(&a[j], &t[i]) < 0 ? a[j++] : t[i++];
    while (i < m) a[k++] = t[i++];
}

/* ---- random --------------------------------------------------------- */

static u64 rs[4];
static u64 rotl(u64 x, int k) { return (x << k) | (x >> (64 - k)); }

static u64 rnext(void) {                     /* xoshiro256** */
    u64 r = rotl(rs[1] * 5, 7) * 9, t = rs[1] << 17;
    rs[2] ^= rs[0]; rs[3] ^= rs[1]; rs[1] ^= rs[2]; rs[0] ^= rs[3];
    rs[2] ^= t; rs[3] = rotl(rs[3], 45);
    return r;
}

static u64 hkey[2];                          /* -R -u hash key */

static void seed(void) {
    size_t got = 0;
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd < 0) die("/dev/urandom: %s", strerror(errno));
    while (got < sizeof rs) {
        ssize_t r = read(fd, (char *)rs + got, sizeof rs - got);
        if (r < 0 && errno == EINTR) continue;
        if (r <= 0) die("/dev/urandom: read failed");
        got += (size_t)r;
    }
    close(fd);
    if (!(rs[0] | rs[1] | rs[2] | rs[3])) rs[0] = 1;
    hkey[0] = rnext(); hkey[1] = rnext();
}

static u64 khash(const uc *p, size_t n) {    /* keyed; equal bytes, equal tag */
    u64 h = hkey[0] ^ ((u64)n * 0x9e3779b97f4a7c15ULL);
    size_t i;
    for (i = 0; i < n; i++) h = (h ^ p[i]) * 0x100000001b3ULL;
    h ^= hkey[1];
    h ^= h >> 30; h *= 0xbf58476d1ce4e5b9ULL;
    h ^= h >> 27; h *= 0x94d049bb133111ebULL;
    return h ^ (h >> 31);
}

/* ---- record index and chunk storage --------------------------------- */

static struct rec *R;
static size_t nR, capR, maxR;
static uc **chunks;                          /* live input chunks */
static size_t nchunks, capchunks, chunk_bytes, csize;
static uc *buf;                              /* current chunk */
static size_t cap, len, start;               /* start: pending record */

static u64 prefix(const uc *p, size_t n) {
    u64 v = 0;
    size_t i;
    for (i = 0; i < 8; i++) v = v << 8 | (i < n ? p[i] : 0);
    return v;
}

static void addrec(const uc *p, size_t n) {
    if (nR == capR) {
        capR = capR ? capR * 2 : 4096;
        if (capR > maxR) capR = maxR;        /* over_budget() keeps nR < maxR */
        R = xrealloc(R, capR * sizeof *R);
    }
    R[nR].p = p; R[nR].n = n;
    R[nR].pre = !o_rand ? prefix(p, n) : o_uniq ? khash(p, n) : rnext();
    nR++;
}

/* Start a new chunk, carrying the pending bytes into it so that every
 * record stays contiguous. grow: the pending bytes are one long partial
 * record, so leave room to double; otherwise they are unscanned input
 * carried across a spill. Older chunks are never moved. */
static void newchunk(int grow) {
    size_t part = len - start, ncap = (grow ? part * 2 : part) + csize;
    uc *nb = xmalloc(ncap);
    if (part) memcpy(nb, buf + start, part);
    if (nchunks == capchunks) {
        capchunks = capchunks ? capchunks * 2 : 16;
        chunks = xrealloc(chunks, capchunks * sizeof *chunks);
    }
    chunks[nchunks++] = nb;
    chunk_bytes += ncap;
    buf = nb; cap = ncap; len = part; start = 0;
}

/* ---- key encoding ---------------------------------------------------- */

/* Before a batch is sorted, each record's keys are encoded once into
 * one byte string whose memcmp order is exactly reccmp order. Sorting
 * then compares bytes: no column is split and no number parsed more
 * than once per record. reccmp remains the definition of the order ---
 * it is what -c, the merge and -b use, and what the suite checks the
 * encoded sort against --- and the encoding is the same construction
 * srt.fn.bash performs in awk.
 *
 * Per column: text is copied with NUL escaped (00 FF) and ended 00 00;
 * -n is sign, digit count, digits, fraction; -H adds the scale rank;
 * -g is the class and the IEEE bits made unsigned-ordered; -v is the
 * IPv6 value, or the natural-order tokens of stem then whole key. A
 * reversed column is the bitwise complement of its encoding. Columns
 * are self-delimiting, and every record in a batch carries the same
 * number of them (missing ones encode as empty), so concatenation
 * preserves order.
 *
 * The encoded batch may use a quarter of the budget. A batch that
 * would need more is sorted by reccmp instead, with the same result. */
typedef char srt_needs_ieee_double[sizeof(double) == 8 ? 1 : -1];
#define EHDR (sizeof(const uc *) + sizeof(size_t))

static uc *EB;
static size_t ecap, elen, n_enc, n_cmp;
static int use_enc, deduped;
static size_t *TZ, tzcap;                    /* zero counts of one key */

static void eb_need(size_t k) {
    if (elen + k > ecap) {
        ecap = (elen + k) + (elen + k) / 2 + 4096;
        EB = xrealloc(EB, ecap);
    }
}

static void eb_be32(size_t v) {              /* caller reserved the room */
    EB[elen++] = (uc)(v >> 24); EB[elen++] = (uc)(v >> 16);
    EB[elen++] = (uc)(v >> 8); EB[elen++] = (uc)v;
}

static void e_text(const uc *s, size_t n, const struct kopt *o) {
    size_t k;
    int d = o->type == 'd';
    uc *q;
    eb_need(2 * n + 2);
    q = EB + elen;
    for (k = 0; k < n; k++) {
        int c = s[k];
        if (d && !(isblnk(c) || isdig(c) || isalph(c) || c >= 0x80)) continue;
        if (o->i && (c < 0x20 || c == 0x7f)) continue;
        if (o->f) c = fold(c);
        if (c) *q++ = (uc)c; else { *q++ = 0; *q++ = 0xff; }
    }
    *q++ = 0; *q++ = 0;
    elen = (size_t)(q - EB);
}

static void e_mag(const struct num *x) {     /* count, digits, fraction */
    eb_need(x->il + x->fl + 5);
    eb_be32(x->il);
    if (x->il) { memcpy(EB + elen, x->ip, x->il); elen += x->il; }
    if (x->fl) { memcpy(EB + elen, x->fp, x->fl); elen += x->fl; }
    EB[elen++] = 0;
}

static void e_flip(size_t from) { for (; from < elen; from++) EB[from] = (uc)~EB[from]; }

static void e_num(const uc *s, size_t n, int human) {
    struct num x;
    size_t m;
    pnum(s, n, &x);
    eb_need(2);
    EB[elen++] = x.neg ? 1 : 2;
    m = elen;
    if (human) EB[elen++] = (uc)hrank(s, n, x.end);
    e_mag(&x);
    if (x.neg) e_flip(m);
}

static void e_hex(const uc *s, size_t n) {   /* sign, count, digits a-f low */
    struct hx x;
    size_t m, k;
    phex(s, n, &x);
    eb_need(x.n + 5);
    EB[elen++] = x.neg ? 1 : 2;
    m = elen;
    eb_be32(x.n);
    for (k = 0; k < x.n; k++) EB[elen++] = (uc)(x.p[k] | (isdig(x.p[k]) ? 0 : 32));
    if (x.neg) e_flip(m);
}

static void e_gen(const uc *s, size_t n) {
    double v;
    int cx = gparse(s, n, &v), i;
    u64 b;
    eb_need(9);
    EB[elen++] = (uc)cx;
    if (cx != 2) return;
    if (v == 0) v = 0.0;                     /* -0 and 0 are one key */
    memcpy(&b, &v, 8);
    b = (b >> 63) ? ~b : b | ((u64)1 << 63);
    for (i = 0; i < 8; i++) EB[elen++] = (uc)(b >> (56 - 8 * i));
}

/* natural-order tokens: a digit run is '0', its length, its digits; ~ is
 * 00 and the end of the key 01, below every other byte (00-02 are
 * escaped as 02 xx); zero counts follow as the tie-break */
static void e_nat(const uc *s, size_t n, int f) {
    size_t i = 0, nt = 0, k;
    while (i < n) {
        int c = s[i];
        if (isdig(c)) {
            size_t z = i, d;
            while (i < n && s[i] == '0') i++;
            z = i - z; d = i;
            while (i < n && isdig(s[i])) i++;
            eb_need(5 + (i - d));
            EB[elen++] = '0';
            eb_be32(i - d);
            if (i > d) { memcpy(EB + elen, s + d, i - d); elen += i - d; }
            if (nt == tzcap) { tzcap = tzcap ? tzcap * 2 : 16; TZ = xrealloc(TZ, tzcap * sizeof *TZ); }
            TZ[nt++] = z;
        } else {
            if (f) c = fold(c);
            eb_need(2);
            if (c == '~') EB[elen++] = 0;
            else if (c <= 2) { EB[elen++] = 2; EB[elen++] = (uc)c; }
            else EB[elen++] = (uc)c;
            i++;
        }
    }
    eb_need(1 + 4 * nt);
    EB[elen++] = 1;
    for (k = 0; k < nt; k++) eb_be32(TZ[k]);
}

static void e_ver(const uc *s, size_t n, int f) {
    uc a[16];
    int pl = 0;
    if (ip6(s, n, a, &pl)) {
        eb_need(18);
        EB[elen++] = 2;
        memcpy(EB + elen, a, 16); elen += 16;
        EB[elen++] = (uc)(pl + 1);
        return;
    }
    eb_need(1);
    EB[elen++] = 1;
    e_nat(s, stemlen(s, n), f);
    e_nat(s, n, f);
}

static void enc_col(const uc *s, size_t n, const struct kopt *o) {
    size_t st = elen;
    switch (o->type) {
    case 'n': e_num(s, n, 0); break;
    case 'H': e_num(s, n, 1); break;
    case 'x': e_hex(s, n); break;
    case 'g': e_gen(s, n); break;
    case 'v': e_ver(s, n, o->f); break;
    default:  e_text(s, n, o); break;
    }
    if (o->r) e_flip(st);
}

static int ecmp(const struct rec *x, const struct rec *y) {
    if (x->pre != y->pre) return x->pre < y->pre ? -1 : 1;
    return plain(x->p, x->n, y->p, y->n);
}

/* Encode R[0..nR). On success each R[i] points at its encoded key, with
 * the original pointer and length stored just before it; decode_batch()
 * puts them back. Returns 0, leaving R as it was, when the keys would
 * exceed their share of the budget. */
static int encode_batch(void) {
    size_t i, k, c, maxnr = 0, limit = budget / 4;
    if (!whole)
        for (i = 0; i < nR; i++) {
            layout(&R[i], &LA);
            if (LA.nr > maxnr) maxnr = LA.nr;
        }
    elen = 0;
    for (i = 0; i < nR; i++) {
        size_t off = elen;
        eb_need(EHDR);
        memcpy(EB + elen, &R[i].p, sizeof R[i].p);
        memcpy(EB + elen + sizeof R[i].p, &R[i].n, sizeof R[i].n);
        elen += EHDR;
        if (whole) enc_col(R[i].p, R[i].n, &G);
        else {
            layout(&R[i], &LA);
            for (k = 0; k < nK; k++)
                enc_col(LA.k[k].p, LA.k[k].n, K[k].own ? &K[k].o : &G);
            for (c = 0; c < maxnr; c++)      /* missing ones encode as empty */
                enc_col(c < LA.nr ? LA.r[c].p : nil, c < LA.nr ? LA.r[c].n : 0, &G);
        }
        if (elen > limit) {
            for (k = 0; k < i; k++) R[k].pre = prefix(R[k].p, R[k].n);
            return 0;
        }
        R[i].pre = off;
    }
    for (i = 0; i < nR; i++) {
        size_t off = (size_t)R[i].pre;
        size_t end = i + 1 < nR ? (size_t)R[i + 1].pre : elen;
        R[i].p = EB + off + EHDR;
        R[i].n = end - off - EHDR;
    }
    for (i = 0; i < nR; i++) R[i].pre = prefix(R[i].p, R[i].n);
    return 1;
}

static void decode_batch(void) {
    size_t i;
    for (i = 0; i < nR; i++) {
        const uc *h = R[i].p - EHDR;
        memcpy(&R[i].p, h, sizeof R[i].p);
        memcpy(&R[i].n, h + sizeof R[i].p, sizeof R[i].n);
        R[i].pre = prefix(R[i].p, R[i].n);
    }
}

/* Sort what is held. With -u the duplicates are dropped here when the
 * batch was encoded (deduped), otherwise by emit(). */
static void sort_mem(void) {
    int enc = 0;
    deduped = 0;
    if (nR < 2) return;
    if (use_enc) {
        enc = encode_batch();
        if (enc) { CMP = ecmp; n_enc++; } else n_cmp++;
    }
    if (o_unstable) qsort(R, nR, sizeof *R, qcmp);
    else {
        struct rec *t = xmalloc((nR / 2 + 1) * sizeof *t);
        msort(R, t, nR);
        free(t);
    }
    if (enc) {
        if (o_uniq) {
            size_t i, w = 0;
            for (i = 0; i < nR; i++)
                if (!w || ecmp(&R[w - 1], &R[i])) R[w++] = R[i];
            nR = w;
            deduped = 1;
        }
        decode_batch();
        CMP = reccmp;
    }
}

/* ---- buffered writer: a FILE (final output) or a raw fd (spill) ----- */

struct wr {
    int fd; FILE *f; uc *b; size_t cap, len; off_t total; int tag;
    int dup, have, pin; uc *pb; size_t pcap, pn;      /* -D: record held */
};

static void wr_flush(struct wr *w) {
    size_t o = 0;
    if (w->f) return;
    while (o < w->len) {
        ssize_t r = write(w->fd, w->b + o, w->len - o);
        if (r < 0) {
            if (errno == EINTR) continue;
            die("spill file: write error: %s", strerror(errno));
        }
        o += (size_t)r;
    }
    w->len = 0;
}

static void wr_bytes(struct wr *w, const uc *p, size_t n) {
    w->total += (off_t)n;
    if (w->f) {
        if (n && fwrite(p, 1, n, w->f) != n)
            die("output: write error: %s", strerror(errno));
        return;
    }
    while (n) {
        size_t k = w->cap - w->len;
        if (!k) { wr_flush(w); continue; }
        if (k > n) k = n;
        memcpy(w->b + w->len, p, k);
        w->len += k; p += k; n -= k;
    }
}

static void wr_rec(struct wr *w, const struct rec *r) {
    if (w->tag) {                            /* -R: tag travels with record */
        uc t[8];
        int i;
        for (i = 0; i < 8; i++) t[i] = (uc)(r->pre >> (56 - 8 * i));
        wr_bytes(w, t, 8);
    }
    wr_bytes(w, r->p, r->n);
    wr_bytes(w, &term, 1);
}

/* Records on their way to the final output. Ordinarily each is written
 * as it comes. Under -D (w->dup) one record is held back until it is
 * known whether the next belongs to its group; only groups of two or
 * more are written. Runs on their way to the spill file are never
 * filtered. */
static void put(struct wr *w, const struct rec *r) {
    if (!w->dup) { wr_rec(w, r); return; }
    if (w->have) {
        struct rec p;
        int eq;
        p.p = w->pb; p.n = w->pn; p.pre = prefix(p.p, p.n);
        eq = groupeq(&p, r);
        if (eq || w->pin) wr_rec(w, &p);
        w->pin = eq;
    }
    if (r->n > w->pcap) { w->pcap = r->n * 2 + 64; w->pb = xrealloc(w->pb, w->pcap); }
    if (r->n) memcpy(w->pb, r->p, r->n);
    w->pn = r->n;
    w->have = 1;
}

static void put_end(struct wr *w) {
    struct rec p;
    if (!w->dup || !w->have || !w->pin) return;
    p.p = w->pb; p.n = w->pn; p.pre = 0;
    wr_rec(w, &p);
}

static void emit(struct wr *w) {             /* R[] in order, -u applied */
    size_t i, last = 0;
    for (i = 0; i < nR; i++) {
        if (o_uniq && !deduped && i && reccmp(&R[last], &R[i]) == 0) continue;
        last = i;
        put(w, &R[i]);
    }
}

/* ---- buffered record reader: an input stream, or a run in a file ---- */

struct rd {
    int fd, stream, eof, tag;
    off_t off, end;                          /* run extent when !stream */
    uc *b;
    size_t cap, len, pos, scan;
    const char *name;
};

static void rd_init(struct rd *r, int fd, size_t bsz, const char *name) {
    memset(r, 0, sizeof *r);
    r->fd = fd; r->stream = 1; r->name = name;
    r->cap = bsz; r->b = xmalloc(bsz);
}

/* Next record; the pointer is valid until the next call on this reader.
 * The buffer grows to hold a record longer than itself. */
static int rd_next(struct rd *r, struct rec *out) {
    size_t skip = r->tag ? 8 : 0;
    for (;;) {
        size_t from = r->pos + skip;
        ssize_t got;
        size_t want;
        if (from < r->scan) from = r->scan;
        if (from < r->len) {
            const uc *q = memchr(r->b + from, term, r->len - from);
            if (q) {
                out->p = r->b + r->pos + skip;
                out->n = (size_t)(q - out->p);
                r->pos = (size_t)(q + 1 - r->b);
                r->scan = 0;
                goto found;
            }
            r->scan = r->len;
        }
        if (r->eof) {
            if (r->len <= r->pos + skip) {
                if (r->len > r->pos) die("%s: spill file is damaged", r->name);
                return 0;
            }
            out->p = r->b + r->pos + skip;   /* final record, no terminator */
            out->n = r->len - r->pos - skip;
            r->pos = r->len;
            goto found;
        }
        if (r->pos) {
            memmove(r->b, r->b + r->pos, r->len - r->pos);
            r->len -= r->pos;
            r->scan = r->scan > r->pos ? r->scan - r->pos : 0;
            r->pos = 0;
        }
        if (r->len == r->cap) { r->cap *= 2; r->b = xrealloc(r->b, r->cap); }
        want = r->cap - r->len;
        if (r->stream) got = read(r->fd, r->b + r->len, want);
        else {
            if (r->off >= r->end) { r->eof = 1; continue; }
            if ((off_t)want > r->end - r->off) want = (size_t)(r->end - r->off);
            got = pread(r->fd, r->b + r->len, want, r->off);
            if (got == 0) die("%s: spill file is truncated", r->name);
            if (got > 0) r->off += got;
        }
        if (got < 0) {
            if (errno == EINTR) continue;
            die("%s: %s", r->name, strerror(errno));
        }
        if (got == 0) r->eof = 1;
        r->len += (size_t)got;
    }
found:
    if (r->tag) {
        const uc *t = out->p - 8;
        u64 v = 0;
        int i;
        for (i = 0; i < 8; i++) v = v << 8 | t[i];
        out->pre = v;
    } else out->pre = prefix(out->p, out->n);
    return 1;
}

/* ---- spill: runs appended to one unlinked file ---------------------- */

static struct run *runs;
static size_t nruns, capruns, n_first, n_passes;
static int sp_fd = -1;                       /* spill file holding the runs */
static struct wr sp_w;

/* An unlinked temporary in the spill directory: nothing to clean up on
 * any exit, and nothing visible in the directory. */
static int tmp_open(void) {
    char path[4096];
    const char *dir = o_tmp ? o_tmp : getenv("TMPDIR");
    int fd;
    if (!dir || !*dir) dir = "/var/tmp";
    if (strlen(dir) + 16 >= sizeof path) die("%s: spill path too long", dir);
    sprintf(path, "%s/srt.XXXXXX", dir);
    if ((fd = mkstemp(path)) < 0)
        die("%s: cannot create spill file: %s (see -T)", dir, strerror(errno));
    if (unlink(path)) die("%s: %s", path, strerror(errno));
    return fd;
}

static void add_run(off_t off, off_t n) {
    if (nruns == capruns) {
        capruns = capruns ? capruns * 2 : 64;
        runs = xrealloc(runs, capruns * sizeof *runs);
    }
    runs[nruns].off = off; runs[nruns].len = n;
    nruns++;
}

/* Sort what is held, append it as a run, release the chunks. The pending
 * partial record, if any, moves to a fresh chunk first. */
static void spill(void) {
    off_t off;
    size_t i, keep = nchunks;
    if (o_blocks)                            /* a subtree cannot span runs */
        die("-b holds the whole input in memory and the budget of %lu bytes"
            " is reached; raise --mem", (unsigned long)budget);
    if (sp_fd < 0) {
        sp_fd = tmp_open();
        memset(&sp_w, 0, sizeof sp_w);
        sp_w.fd = sp_fd; sp_w.cap = 4 * RD_MIN; sp_w.b = xmalloc(sp_w.cap);
        sp_w.tag = o_rand;
    }
    sort_mem();
    off = sp_w.total;
    emit(&sp_w);
    wr_flush(&sp_w);
    add_run(off, sp_w.total - off);
    nR = 0;
    newchunk(0);                             /* carries what is unscanned */
    for (i = 0; i < keep; i++) { free(chunks[i]); }
    chunks[0] = chunks[keep];
    nchunks = 1;
    chunk_bytes = cap;
}

/* The budget is partitioned so each part has a fixed ceiling: record
 * bytes in chunks get half; the index gets a third (maxR records); the
 * scratch half-index of the stable sort gets the remaining sixth.
 * Either ceiling reached with at least one record held means spill. */
static int over_budget(void) {
    return nR && (nR >= maxR || chunk_bytes >= budget / (use_enc ? 4 : 2));
}

/* Read one input into chunk storage and index its records, spilling
 * whenever the budget is reached. The budget is tested after every
 * record, so a single read holding many short records cannot overrun
 * it; spill() moves the unscanned remainder to a fresh chunk, and the
 * scan resumes at its start. */
static void load(const char *name) {
    int fd = strcmp(name, "-") ? open(name, O_RDONLY) : STDIN_FILENO;
    if (fd < 0) die("%s: %s", name, strerror(errno));
    start = len;
    for (;;) {
        ssize_t r;
        size_t pos;
        const uc *q;
        if (cap - len < RD_MIN) newchunk(1);
        r = read(fd, buf + len, cap - len);
        if (r < 0) {
            if (errno == EINTR) continue;
            die("%s: %s", name, strerror(errno));
        }
        if (r == 0) break;
        pos = len;
        len += (size_t)r;
        while ((q = memchr(buf + pos, term, len - pos))) {
            addrec(buf + start, (size_t)(q - (buf + start)));
            start = pos = (size_t)(q + 1 - buf);
            if (over_budget()) { spill(); pos = 0; }
        }
    }
    if (len > start) {                       /* final record, no terminator */
        addrec(buf + start, len - start);
        start = len;
        if (over_budget()) spill();
    }
    if (fd != STDIN_FILENO && close(fd)) die("%s: %s", name, strerror(errno));
}

/* k-way merge of n runs from fd into w. Ties go to the lower run, which
 * is input order, so the merge is stable. */
static void merge(const struct run *rn, size_t n, int fd, struct wr *w,
                  size_t bsz) {
    struct rd *rd = xmalloc(n * sizeof *rd);
    struct rec *cur = xmalloc(n * sizeof *cur), last;
    size_t *heap = xmalloc(n * sizeof *heap), hn = 0, i;
    uc *lb = NULL;
    size_t lcap = 0;
    int havelast = 0;
#define LESS(A, B) (c = reccmp(&cur[A], &cur[B]), c < 0 || (c == 0 && (A) < (B)))
#define SIFT(I) do { size_t x = (I); int c; for (;;) { \
        size_t l = 2 * x + 1, m = x, t; \
        if (l < hn && LESS(heap[l], heap[m])) m = l; \
        if (l + 1 < hn && LESS(heap[l + 1], heap[m])) m = l + 1; \
        if (m == x) break; \
        t = heap[x]; heap[x] = heap[m]; heap[m] = t; x = m; } } while (0)
    memset(&last, 0, sizeof last);
    for (i = 0; i < n; i++) {
        rd_init(&rd[i], fd, bsz, "spill");
        rd[i].stream = 0; rd[i].tag = o_rand;
        rd[i].off = rn[i].off; rd[i].end = rn[i].off + rn[i].len;
        if (rd_next(&rd[i], &cur[i])) heap[hn++] = i;
    }
    for (i = hn / 2; i-- > 0; ) SIFT(i);
    while (hn) {
        size_t t = heap[0];
        if (!(o_uniq && havelast && reccmp(&last, &cur[t]) == 0)) {
            put(w, &cur[t]);
            if (o_uniq) {                    /* reader buffer will move */
                if (cur[t].n > lcap) { lcap = cur[t].n * 2; lb = xrealloc(lb, lcap); }
                if (cur[t].n) memcpy(lb, cur[t].p, cur[t].n);
                last.p = lb; last.n = cur[t].n; last.pre = cur[t].pre;
                havelast = 1;
            }
        }
        if (!rd_next(&rd[t], &cur[t])) heap[0] = heap[--hn];
        SIFT(0);
    }
#undef SIFT
#undef LESS
    for (i = 0; i < n; i++) free(rd[i].b);
    free(rd); free(cur); free(heap); free(lb);
}

/* Merge every run into out. When the budget cannot buffer all runs at
 * once, merge groups of consecutive runs into a second file, swap, and
 * repeat; consecutive grouping keeps the merge stable. */
static void merge_all(FILE *out) {
    size_t fan = budget / RD_MIN, bsz;
    int src = sp_fd, dst = -1;
    struct wr w;
    fan = fan > 3 ? fan - 1 : 2;
    while (nruns > fan) {
        struct run *nr = xmalloc((nruns / fan + 1) * sizeof *nr);
        size_t k = 0, g;
        if (dst < 0) dst = tmp_open();
        memset(&w, 0, sizeof w);
        w.fd = dst; w.cap = 4 * RD_MIN; w.b = xmalloc(w.cap); w.tag = o_rand;
        for (g = 0; g < nruns; g += fan) {
            off_t off = w.total;
            merge(runs + g, nruns - g < fan ? nruns - g : fan, src, &w, RD_MIN);
            wr_flush(&w);
            nr[k].off = off; nr[k].len = w.total - off; k++;
        }
        free(w.b);
        if (ftruncate(src, 0) || lseek(src, 0, SEEK_SET) < 0)
            die("spill file: %s", strerror(errno));
        free(runs);
        runs = nr; nruns = capruns = k;
        { int t = src; src = dst; dst = t; }
        n_passes++;
    }
    bsz = budget / (nruns + 1);
    if (bsz < RD_MIN) bsz = RD_MIN;
    if (bsz > ((size_t)1 << 20)) bsz = (size_t)1 << 20;
    memset(&w, 0, sizeof w);
    w.f = out; w.dup = o_dups;
    merge(runs, nruns, src, &w, bsz);
    put_end(&w);
    n_passes++;
}

/* ---- outline sort (-b) ---------------------------------------------- */

/* Tree over R[], which stays in input order. A line's indent is its
 * exact leading run of spaces and tabs. Its parent is the innermost
 * open line whose indent is a proper prefix of its own; a line closes
 * every open block whose indent it does not extend. Children of one
 * parent with byte-identical indents form a group, and only a group is
 * sorted. Blank lines are not nodes: they stay behind the line they
 * follow. */
#define NONE ((size_t)-1)
static size_t *b_first, *b_next, *b_last, *b_il;
static struct rec *b_key;                    /* line with indent removed */
static uc *b_blank;
static size_t b_rfirst, b_rlast;             /* top-level list */

static void b_build(void) {
    size_t i, sp = 0, scap = 64, *stack = xmalloc(scap * sizeof *stack);
    b_first = xmalloc(nR * sizeof *b_first);
    b_next = xmalloc(nR * sizeof *b_next);
    b_last = xmalloc(nR * sizeof *b_last);
    b_il = xmalloc(nR * sizeof *b_il);
    b_key = xmalloc(nR * sizeof *b_key);
    b_blank = xmalloc(nR);
    b_rfirst = b_rlast = NONE;
    for (i = 0; i < nR; i++) {
        size_t il = 0, par;
        while (il < R[i].n && isblnk(R[i].p[il])) il++;
        b_il[i] = il;
        b_blank[i] = il == R[i].n;
        b_first[i] = b_next[i] = b_last[i] = NONE;
        if (b_blank[i]) continue;
        b_key[i].p = R[i].p + il; b_key[i].n = R[i].n - il;
        b_key[i].pre = prefix(b_key[i].p, b_key[i].n);
        while (sp) {                         /* close blocks not extended */
            size_t t = stack[sp - 1];
            if (b_il[t] < il && !memcmp(R[t].p, R[i].p, b_il[t])) break;
            sp--;
        }
        par = sp ? stack[sp - 1] : NONE;
        if (par == NONE) {
            if (b_rlast == NONE) b_rfirst = i; else b_next[b_rlast] = i;
            b_rlast = i;
        } else {
            if (b_last[par] == NONE) b_first[par] = i; else b_next[b_last[par]] = i;
            b_last[par] = i;
        }
        if (sp == scap) { scap *= 2; stack = xrealloc(stack, scap * sizeof *stack); }
        stack[sp++] = i;
    }
    free(stack);
}

static void b_free(void) {
    free(b_first); free(b_next); free(b_last); free(b_il); free(b_key);
    free(b_blank);
}

static int b_leaf(size_t i) {                /* nothing beneath, no blank after */
    return b_first[i] == NONE && !(i + 1 < nR && b_blank[i + 1]);
}

/* stable merge sort of node indexes by their keys */
static void b_sort(size_t *a, size_t *t, size_t n) {
    size_t m, i, j, k;
    if (n <= 12) {
        for (i = 1; i < n; i++) {
            size_t v = a[i];
            for (j = i; j > 0 && reccmp(&b_key[v], &b_key[a[j - 1]]) < 0; j--)
                a[j] = a[j - 1];
            a[j] = v;
        }
        return;
    }
    m = n / 2;
    b_sort(a, t, m);
    b_sort(a + m, t, n - m);
    if (reccmp(&b_key[a[m - 1]], &b_key[a[m]]) <= 0) return;
    memcpy(t, a, m * sizeof *a);
    for (i = 0, j = m, k = 0; i < m && j < n; )
        a[k++] = reccmp(&b_key[a[j]], &b_key[t[i]]) < 0 ? a[j++] : t[i++];
    while (i < m) a[k++] = t[i++];
}

static size_t b_bad;                         /* -c: first record out of order */

/* Children of one parent, starting at first: gather them into groups in
 * order of first appearance, then sort and write each group (w set), or
 * verify each group (w null, -c). Recurses once per line that has
 * children, so depth is the depth of the outline. */
static void b_walk(size_t first, struct wr *w) {
    size_t c = 0, i, a, pos = 0, *kid, *ord, *tmp;
    uc *used;
    for (i = first; i != NONE; i = b_next[i]) c++;
    if (!c) return;
    kid = xmalloc(c * sizeof *kid);
    ord = xmalloc(c * sizeof *ord);
    tmp = xmalloc((c / 2 + 1) * sizeof *tmp);
    used = xmalloc(c);
    memset(used, 0, c);
    for (i = first, c = 0; i != NONE; i = b_next[i]) kid[c++] = i;
    for (a = 0; a < c; a++) {
        size_t g = pos, b, k, last = NONE;
        if (used[a]) continue;
        for (b = a; b < c; b++)              /* same indent, input order */
            if (!used[b] && b_il[kid[b]] == b_il[kid[a]]
                && !memcmp(R[kid[b]].p, R[kid[a]].p, b_il[kid[a]])) {
                ord[pos++] = kid[b]; used[b] = 1;
            }
        if (w) b_sort(ord + g, tmp, pos - g);
        for (k = g; k < pos; k++) {
            size_t n = ord[k], j;
            if (last != NONE) {
                int cmp = reccmp(&b_key[last], &b_key[n]);
                if (o_uniq && cmp == 0 && b_leaf(n)) {
                    if (!w && n < b_bad) b_bad = n;   /* -cu: a duplicate */
                    if (w) continue;
                } else if (!w && cmp > 0 && n < b_bad) b_bad = n;
            }
            last = n;
            if (w) {
                wr_rec(w, &R[n]);
                for (j = n + 1; j < nR && b_blank[j]; j++) wr_rec(w, &R[j]);
            }
            b_walk(b_first[n], w);
        }
    }
    free(kid); free(ord); free(tmp); free(used);
}

static void b_emit(struct wr *w) {
    size_t j;
    b_build();
    for (j = 0; j < nR && b_blank[j]; j++) wr_rec(w, &R[j]);   /* leading */
    b_walk(b_rfirst, w);
    b_free();
}

static void unload(void) {                   /* forget one input (-c -b) */
    size_t i;
    for (i = 0; i < nchunks; i++) free(chunks[i]);
    nchunks = 0; chunk_bytes = 0;
    buf = NULL; cap = len = start = 0;
    nR = 0;
}

static int b_check(const char *name) {
    int bad_order;
    load(name);
    b_build();
    b_bad = NONE;
    b_walk(b_rfirst, NULL);
    b_free();
    bad_order = b_bad != NONE;
    if (bad_order && o_check == 'c')
        fprintf(stderr, "srt: %s:%lu: disorder\n", name, (unsigned long)b_bad + 1);
    unload();
    return bad_order;
}

/* ---- shuffle in memory ---------------------------------------------- */

static void shuffle(void) {                  /* Fisher-Yates, unbiased */
    size_t i;
    for (i = nR; i > 1; i--) {
        u64 n = i, lim = (0 - n) % n, x;
        struct rec t;
        do x = rnext(); while (x < lim);
        x %= n;
        t = R[i - 1]; R[i - 1] = R[x]; R[x] = t;
    }
}

/* ---- output --------------------------------------------------------- */

static int out_fd = -1, out_tmp;
static mode_t out_mode;

/* Result to stdout, or atomically to -o: temporary sibling, fsync, mode
 * carried over, rename. An existing non-regular destination (device,
 * fifo) is written through, never renamed over. Called only after all
 * input has been read, so -o may name an input. */
static FILE *out_open(void) {
    struct stat st;
    FILE *f;
    int have;
    mode_t um;
    const char *sl;
    size_t dl;
    if (!o_out) return stdout;
    have = stat(o_out, &st) == 0;
    if (have && !S_ISREG(st.st_mode)) {
        if (!(f = fopen(o_out, "w"))) die("%s: %s", o_out, strerror(errno));
        return f;
    }
    sl = strrchr(o_out, '/');
    dl = sl ? (size_t)(sl - o_out) : 0;
    if (dl + 16 >= sizeof tmp_path) die("%s: path too long", o_out);
    if (sl) memcpy(tmp_path, o_out, dl); else tmp_path[dl++] = '.';
    strcpy(tmp_path + dl, "/.srt.XXXXXX");
    if ((out_fd = mkstemp(tmp_path)) < 0) {
        int e = errno;
        tmp_path[0] = 0;
        die("%s: cannot create temporary: %s", o_out, strerror(e));
    }
    um = umask(0); umask(um);
    out_mode = have ? (st.st_mode & 07777) : (0666 & ~um);
    out_tmp = 1;
    if (!(f = fdopen(out_fd, "w"))) die("%s: %s", o_out, strerror(errno));
    return f;
}

static void out_close(FILE *f) {
    const char *name = o_out ? o_out : "stdout";
    if (fflush(f) || ferror(f)) die("%s: write error: %s", name, strerror(errno));
    if (f == stdout) return;
    if (out_tmp) {
        if (fsync(out_fd) || fchmod(out_fd, out_mode) || fclose(f)
            || rename(tmp_path, o_out))
            die("%s: %s", o_out, strerror(errno));
        tmp_path[0] = 0;
    } else if (fclose(f)) die("%s: %s", o_out, strerror(errno));
}

/* ---- check: one pass, two records held ------------------------------ */

static int check(const char *name) {
    struct rd r;
    struct rec cur, prev;
    uc *pb = NULL;
    size_t pcap = 0;
    unsigned long line = 0;
    int have = 0, bad_order = 0;
    int fd = strcmp(name, "-") ? open(name, O_RDONLY) : STDIN_FILENO;
    if (fd < 0) die("%s: %s", name, strerror(errno));
    rd_init(&r, fd, 65536, name);
    memset(&prev, 0, sizeof prev);
    while (rd_next(&r, &cur)) {
        line++;
        if (have) {
            int c = reccmp(&prev, &cur);
            if (c > 0 || (o_uniq && c == 0)) { bad_order = 1; break; }
        }
        if (cur.n > pcap) { pcap = cur.n * 2; pb = xrealloc(pb, pcap); }
        if (cur.n) memcpy(pb, cur.p, cur.n);
        prev.p = pb; prev.n = cur.n; prev.pre = cur.pre;
        have = 1;
    }
    if (bad_order && o_check == 'c')
        fprintf(stderr, "srt: %s:%lu: disorder\n", name, line);
    free(r.b); free(pb);
    if (fd != STDIN_FILENO) close(fd);
    return bad_order;
}

/* ---- options -------------------------------------------------------- */

static int ordopt(struct kopt *o, int c) {
    switch (c) {
    case 'd': case 'g': case 'H': case 'n': case 'v': case 'x':
        if (o->type && o->type != c)
            bad("ordering options -%c and -%c cannot apply to one key", o->type, c);
        o->type = c; return 1;
    case 'f': o->f = 1; return 1;
    case 'i': o->i = 1; return 1;
    case 'r': o->r = 1; return 1;
    }
    return 0;
}

static void parse_k(const char *s) {
    const char *p = s;
    for (;;) {
        long col = 0;
        size_t i;
        int neg = 0;
        struct key k;
        if (*p == '-' && isdig((uc)p[1])) { neg = 1; p++; }
        if (*p == 'r' && isdig((uc)p[1]))
            bad("-k %s: write the r after the column, as in -k%sr, or use -r",
                s, p + 1);
        if (!isdig((uc)*p)) bad("-k %s: expected a column number", s);
        for (; isdig((uc)*p); p++) {
            if (col > 100000000) bad("-k %s: column number too large", s);
            col = col * 10 + (*p - '0');
        }
        if (!col) bad("-k %s: columns count from 1, or from -1 at the end", s);
        if (neg) col = -col;
        memset(&k, 0, sizeof k);
        k.col = col;
        while (*p && *p != ',') {
            if (*p == '.') bad("-k %s: character offsets are not supported", s);
            if (!ordopt(&k.o, *p)) bad("-k %s: unknown key option '%c'", s, *p);
            k.own = 1; p++;
        }
        for (i = 0; i < nK; i++)
            if (K[i].col == col)
                bad("-k %s: column %ld named twice (srt -k a,b means column a"
                    " then column b)", s, col);
        K = xrealloc(K, (nK + 1) * sizeof *K);
        K[nK++] = k;
        if (!*p) break;
        p++;
    }
}

/* col[letters][,col[letters]]... with col a number, or -number counted
 * from the end: the test for the word after a bare -k */
static int iskeylist(const char *s) {
    for (;;) {
        if (*s == '-') s++;
        if (!isdig((uc)*s)) return 0;
        while (isdig((uc)*s)) s++;
        while (*s && strchr("dfgHinrvx", *s)) s++;
        if (!*s) return 1;
        if (*s++ != ',') return 0;
    }
}

static void parse_t(const char *s) {
    if (s[0] && !s[1]) sep = (uc)s[0];
    else if (!strcmp(s, "\\t")) sep = '\t';
    else if (!strcmp(s, "\\0")) sep = 0;
    else bad("-t %s: separator must be one byte, \\t or \\0", s);
    have_t = 1;
}

static size_t parse_size(const char *s, const char *what) {
    size_t v = 0, mul = 1;
    const char *p = s;
    if (!isdig((uc)*p)) bad("%s %s: expected N[bkmg]", what, s);
    for (; isdig((uc)*p); p++) {
        if (v > ((size_t)-1 - 9) / 10) bad("%s %s: too large", what, s);
        v = v * 10 + (size_t)(*p - '0');
    }
    switch (*p) {
    case 0: break;
    case 'b': case 'B': p++; break;
    case 'k': case 'K': mul = (size_t)1 << 10; p++; break;
    case 'm': case 'M': mul = (size_t)1 << 20; p++; break;
    case 'g': case 'G': mul = (size_t)1 << 30; p++; break;
    default: bad("%s %s: expected N[bkmg]", what, s);
    }
    if (*p) bad("%s %s: expected N[bkmg]", what, s);
    if (!v) bad("%s %s: must be greater than zero", what, s);
    if (v > (size_t)-1 / mul) bad("%s %s: too large", what, s);
    return v * mul;
}

/* Half of physical memory, lowered to half of any address-space or data
 * limit. The budget, not allocation failure, triggers spill: on hosts
 * that overcommit, malloc succeeds and the process is killed later. */
static size_t default_budget(void) {
    size_t b = (size_t)1 << 30;
    struct rlimit rl;
#if defined(_SC_PHYS_PAGES) && defined(_SC_PAGESIZE)
    long pg = sysconf(_SC_PHYS_PAGES), ps = sysconf(_SC_PAGESIZE);
    if (pg > 0 && ps > 0) {
        u64 t = (u64)pg * (u64)ps / 2;
        b = t > (u64)((size_t)-1 / 2) ? (size_t)-1 / 2 : (size_t)t;
    }
#endif
#ifdef RLIMIT_AS
    if (!getrlimit(RLIMIT_AS, &rl) && rl.rlim_cur != RLIM_INFINITY
        && (u64)rl.rlim_cur / 2 < (u64)b) b = (size_t)(rl.rlim_cur / 2);
#endif
    if (!getrlimit(RLIMIT_DATA, &rl) && rl.rlim_cur != RLIM_INFINITY
        && (u64)rl.rlim_cur / 2 < (u64)b) b = (size_t)(rl.rlim_cur / 2);
    return b;
}

static void setopt(int c, const char *arg) {
    switch (c) {
    case 'c': case 'C': o_check = c; break;
    case 'u': o_uniq = 1; break;
    case 'S': o_unstable = 1; break;
    case 'b': o_blocks = 1; break;
    case 'R': o_rand = 1; break;
    case 'D': o_dups = 1; break;
    case 'Z': term = 0; break;
    case 'z': bad("-z is now -Z (NUL-terminated records)"); break;
    case 's': case 'm': break;               /* already srt behavior */
    case 'k': parse_k(arg); break;
    case 't': parse_t(arg); break;
    case 'o': o_out = arg; break;
    case 'T': o_tmp = arg; break;
    case OPT_MEM: o_mem = parse_size(arg, "--mem"); break;
    case 'V': puts(SRT_REV); exit(0);
    case 'h': fputs(USAGE, stdout); exit(0);
    case OPT_HELP: help(); break;
    case OPT_BIN: break;                     /* this is the binary */
    case OPT_FN:
        bad("--fn allows only the bash function (srt.fn.bash); this is the"
            " srt binary");
        break;
    case 'M': case 'l':
        bad("option -%c is not supported by srt (--help, DIFFERENCES)", c);
        break;
    default:
        if (c < 256 && ordopt(&G, c)) { gset = 1; break; }
        bad("unknown option -%c", c);
    }
}

static const struct { const char *name; int c, arg; } LONG[] = {
    { "check", 'c', 0 }, { "output", 'o', 1 }, { "tmp-dir", 'T', 1 },
    { "unique", 'u', 0 }, { "version", 'V', 0 }, { "help", OPT_HELP, 0 },
    { "respect-blanks", 'b', 0 }, { "random", 'R', 0 },
    { "dictionary", 'd', 0 }, { "fold-case", 'f', 0 },
    { "general-numeric", 'g', 0 }, { "human-numeric", 'H', 0 },
    { "ignore-nonprinting", 'i', 0 }, { "numeric", 'n', 0 },
    { "reverse", 'r', 0 }, { "version-sort", 'v', 0 },
    { "separator", 't', 1 }, { "zero-terminated", 'Z', 0 },
    { "mem", OPT_MEM, 1 }, { "stable", 's', 0 }, { "merge", 'm', 0 },
    { "fn", OPT_FN, 0 }, { "bin", OPT_BIN, 0 }, { "duplicates", 'D', 0 },
    { "hex-numeric", 'x', 0 },
};

static const char *const GONE[] = {         /* named so the error can say so */
    "parallel", "batch-size", "compress-program", "files0-from", "debug",
    "random-source", "sort", "qsort", "mergesort", "heapsort", "radixsort",
    "month-sort", "buffer-size", "key", "field-separator",
    "temporary-directory", "ignore-case", "ignore-leading-blanks",
    "random-sort", "numeric-sort", "general-numeric-sort",
    "human-numeric-sort", "dictionary-order",
};

/* returns 1 if the next argv element was consumed as the argument */
static int longopt(const char *a, const char *next) {
    const char *eq = strchr(a, '=');
    size_t n = eq ? (size_t)(eq - a) : strlen(a), i;
    for (i = 0; i < sizeof LONG / sizeof LONG[0]; i++) {
        if (strlen(LONG[i].name) != n || strncmp(LONG[i].name, a, n)) continue;
        if (!LONG[i].arg) {
            if (eq) bad("option --%s takes no argument", LONG[i].name);
            setopt(LONG[i].c, NULL);
            return 0;
        }
        if (eq) { setopt(LONG[i].c, eq + 1); return 0; }
        if (!next) bad("option --%s requires an argument", LONG[i].name);
        setopt(LONG[i].c, next);
        return 1;
    }
    for (i = 0; i < sizeof GONE / sizeof GONE[0]; i++)
        if (strlen(GONE[i]) == n && !strncmp(GONE[i], a, n))
            bad("option --%s is not supported by srt (--help, DIFFERENCES)",
                GONE[i]);
    bad("unknown option --%.*s", (int)n, a);
    return 0;
}

/* ---- main ----------------------------------------------------------- */

int main(int argc, char **argv) {
    const char **files = xmalloc(((size_t)argc + 1) * sizeof *files);
    size_t nf = 0, i;
    int a, done = 0, status = 0;
    const char *env;
    FILE *out;
    struct wr w;

    for (a = 1; a < argc; a++) {
        const char *s = argv[a];
        size_t j;
        if (done || s[0] != '-' || !s[1]) { files[nf++] = s; continue; }
        if (s[1] == '-') {
            if (!s[2]) { done = 1; continue; }
            a += longopt(s + 2, a + 1 < argc ? argv[a + 1] : NULL);
            continue;
        }
        for (j = 1; s[j]; j++) {
            int c = (uc)s[j];
            if (c == 'k' && !s[j + 1]) {
                /* bare -k: the next word is the key list only if it
                 * reads as one; otherwise -k names no column (the whole
                 * record, which is the default) and the word is left */
                if (a + 1 < argc && iskeylist(argv[a + 1])) setopt(c, argv[++a]);
                break;
            }
            if (c == 'k' || c == 't' || c == 'o' || c == 'T') {
                const char *arg = s[j + 1] ? s + j + 1
                                : a + 1 < argc ? argv[++a] : NULL;
                if (!arg) bad("option -%c requires an argument", c);
                setopt(c, arg);
                break;
            }
            setopt(c, NULL);
        }
    }
    if (!nf) files[nf++] = "-";

    if (!o_mem && (env = getenv("SRT_MEM")) && *env)
        o_mem = parse_size(env, "SRT_MEM");
    if (o_tmp) {
        struct stat st;
        if (stat(o_tmp, &st) || !S_ISDIR(st.st_mode))
            die("-T %s: not a directory", o_tmp);
    }
    if (o_check && o_out) bad("-%c cannot be combined with -o", o_check);
    if (o_rand && (gset || nK || o_blocks || o_check))
        bad("-R cannot be combined with ordering options, -k, -b, -c or -C");

    if (o_dups && (o_check || o_rand || o_blocks))
        bad("-D cannot be combined with -c, -C, -R or -b");

    for (i = 0; i < nK; i++) {
        if (K[i].col < 0) anyneg = 1;
        else if (K[i].col > maxpos) maxpos = K[i].col;
    }
    maxcol = (size_t)maxpos;
    if (nK) {
        iskey = xmalloc(maxcol + 1);
        memset(iskey, 0, maxcol + 1);
        for (i = 0; i < nK; i++) if (K[i].col > 0) iskey[K[i].col] = 1;
    }
    /* the highest named column takes the rest of the record when it is
     * compared as text; not under -D, where a key is exactly its word,
     * nor when a key counts from the end */
    for (i = 0; i < nK; i++)
        if (K[i].col == maxpos && maxpos && !anyneg && !o_dups) {
            int t = (K[i].own ? K[i].o : G).type;
            attach = t == 0 || t == 'd' || t == 'v';
        }
    whole = !nK && !have_t;
    fast = whole && !G.type && !G.f && !G.i;
    use_enc = !fast && !o_rand && !o_blocks && !o_check;

    budget = o_mem ? o_mem : default_budget();
    if (budget < MEM_MIN) budget = MEM_MIN;
    csize = budget / 8;
    if (csize < CHUNK_MIN) csize = CHUNK_MIN;
    if (csize > CHUNK) csize = CHUNK;
    maxR = budget / 3 / sizeof(struct rec);
    if (maxR < 256) maxR = 256;

    signal(SIGINT, on_signal);
    signal(SIGTERM, on_signal);
    signal(SIGHUP, on_signal);

    if (o_check) {                           /* each input on its own */
        for (i = 0; i < nf; i++)
            if (o_blocks ? b_check(files[i]) : check(files[i])) status = 1;
        return status;
    }

    if (o_rand) seed();
    for (i = 0; i < nf; i++) load(files[i]);
    memset(&w, 0, sizeof w);
    if (o_blocks) {                          /* never spills; see spill() */
        w.f = out = out_open();
        b_emit(&w);
    } else if (!nruns) {                     /* it fit: no temporary file */
        if (o_rand && !o_uniq) shuffle(); else sort_mem();
        w.f = out = out_open();
        w.dup = o_dups;
        emit(&w);
        put_end(&w);
    } else {
        if (nR) spill();
        n_first = nruns;
        for (i = 0; i < nchunks; i++) free(chunks[i]);
        free(R);
        out = out_open();
        merge_all(out);
    }
    out_close(out);
    if ((env = getenv("SRT_STATS")) && *env)
        fprintf(stderr, "srt: stats: budget=%lu runs=%lu passes=%lu"
                " encoded=%lu compared=%lu\n",
                (unsigned long)budget, (unsigned long)n_first,
                (unsigned long)n_passes, (unsigned long)n_enc,
                (unsigned long)n_cmp);
    return 0;
}
