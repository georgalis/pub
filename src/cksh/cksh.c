/*
 * cksh.c --- sortable stat and SHAKE256 listing for files named in args or stdin
 * (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 *
 * rev 6ab7e734 20260926 083932 PDT Sat 08:39 AM 26 Sep 2026
 *     C port, built-in SHAKE256; openssl<3 xoflen fallback (bash); -k/-r
 *     value sort; --help manual; status bitmask; chkerr/chkwrn diagnostics
 * rev 68e9ff40 20251010 235456 PDT Fri 11:54 PM 10 Oct 2025
 *     -0..-5, bare -n and -x (getopts :), -n and -x range validation
 * rev 68e20bca 20251004 231018 PDT Sat 11:10 PM 04 Oct 2025
 *     renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired
 * rev 677c9c44 20250106 191516 PST Mon 07:15 PM 06 Jan 2025
 *     chksthash, from ckstatsum: shake256 -xoflen 3 hash column
 * org 6305e87b 20220824 015939 PDT Wed 01:59 AM 24 Aug 2022
 *     ckstat ckstatsum cks
 *
 * Output: inode links shake256 size mdate filename, hex in aligned columns.
 * Byte-identical output and exit status to the bash function cksh.fn.bash.
 *
 * Dependency posture: none beyond libc. SHAKE256 (FIPS 202) is implemented
 * here rather than linked from libcrypto, since openssl shake256 -xoflen is
 * absent from OpenSSL < 3 and LibreSSL. An XOF output of length L is a prefix
 * of any longer output, so every -x 1-64 is exact on any host. Static on
 * Linux and NetBSD; Darwin links libSystem only.
 *
 * Records keep their raw values; -k compares by value, so a value wider than
 * its column still sorts correctly.
 *
 * Changes from 68e9ff40 (shared with the bash function): non-regular nodes
 * get a zero-filled hash, fifos are warned and never opened, per-file
 * failures warn and continue, and the exit status is a bitmask (see --help).
 */

#define _POSIX_C_SOURCE 200809L

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* exit status bits; 1 and 2 are fatal and exclusive, the rest accumulate */
#define ST_USAGE   1	/* invalid option or argument */
#define ST_ENV     2	/* out of memory, stdin read or stdout write failure */
#define ST_STAT    4	/* lstat failed, line skipped */
#define ST_READ    8	/* regular file open or read failed, line skipped */
#define ST_SPECIAL 16	/* fifo, socket or device, not hashed */
#define ST_DANGLE  32	/* symlink target unresolvable, not hashed */

#define XMAX 64		/* max -x hash length in bytes */
#define RATE 136	/* SHAKE256 rate in bytes */

/* one output line: raw values (0 when omitted), hash text, decorated name */
struct rec {
	uintmax_t v[5];			/* ino, links, (hash slot unused), size, mtime */
	intmax_t mt;			/* mtime, signed for ordering */
	char hash[2 * XMAX + 1];	/* hex, or "." when not computed */
	char *name;			/* name plus ls -F indicator */
};

static const char *prog = "cksh";

/* options */
static int opt_n = 2, opt_x = 3, opt_k = 0, opt_r = 0;

/* sort buffer */
static struct rec *rec;
static size_t nrec, caprec;

static int status;

/*
 * Diagnostics, formatted as the shell chkerr (">>> ") and chkwrn ("^^^ ")
 * functions: "cksh : what 'name'[: reason] (tag)".
 */
static void
msg(const char *lvl, const char *what, const char *name, int err, const char *tag)
{
	/* stderr failure has nowhere else to go */
	(void)fprintf(stderr, "%s%s : %s%s%s%s%s%s (%s)\n", lvl, prog, what,
	    name ? " '" : "", name ? name : "", name ? "'" : "",
	    err ? ": " : "", err ? strerror(err) : "", tag);
}
#define ERR(w, n, e, t) msg(">>> ", (w), (n), (e), (t))
#define WRN(w, n, t)    msg("^^^ ", (w), (n), 0, (t))

static void
die(int st, const char *what, const char *name, const char *tag)
{
	ERR(what, name, 0, tag);
	exit(st);
}

/* --- SHAKE256 ------------------------------------------------------------ */

static const uint64_t keccak_rc[24] = {
	0x0000000000000001ULL, 0x0000000000008082ULL, 0x800000000000808aULL,
	0x8000000080008000ULL, 0x000000000000808bULL, 0x0000000080000001ULL,
	0x8000000080008081ULL, 0x8000000000008009ULL, 0x000000000000008aULL,
	0x0000000000000088ULL, 0x0000000080008009ULL, 0x000000008000000aULL,
	0x000000008000808bULL, 0x800000000000008bULL, 0x8000000000008089ULL,
	0x8000000000008003ULL, 0x8000000000008002ULL, 0x8000000000000080ULL,
	0x000000000000800aULL, 0x800000008000000aULL, 0x8000000080008081ULL,
	0x8000000000008080ULL, 0x0000000080000001ULL, 0x8000000080008008ULL
};
static const unsigned keccak_rot[24] = {
	1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14,
	27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44
};
static const unsigned keccak_pi[24] = {
	10, 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4,
	15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1
};

#define ROTL(v, s) (((v) << (s)) | ((v) >> (64 - (s))))

static void
keccakf(uint64_t s[25])
{
	uint64_t bc[5], t;
	int i, j, r;

	for (r = 0; r < 24; r++) {
		/* theta */
		for (i = 0; i < 5; i++)
			bc[i] = s[i] ^ s[i + 5] ^ s[i + 10] ^ s[i + 15] ^ s[i + 20];
		for (i = 0; i < 5; i++) {
			t = bc[(i + 4) % 5] ^ ROTL(bc[(i + 1) % 5], 1);
			for (j = 0; j < 25; j += 5)
				s[j + i] ^= t;
		}
		/* rho, pi */
		t = s[1];
		for (i = 0; i < 24; i++) {
			j = (int)keccak_pi[i];
			bc[0] = s[j];
			s[j] = ROTL(t, keccak_rot[i]);
			t = bc[0];
		}
		/* chi */
		for (j = 0; j < 25; j += 5) {
			for (i = 0; i < 5; i++)
				bc[i] = s[j + i];
			for (i = 0; i < 5; i++)
				s[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
		}
		/* iota */
		s[0] ^= keccak_rc[r];
	}
}

struct shake {
	uint64_t s[25];
	unsigned char buf[RATE];
	size_t pos;
};

/* xor a full block into the state, lanes little-endian regardless of host */
static void
shake_block(struct shake *c)
{
	size_t i, b;

	for (i = 0; i < RATE / 8; i++)
		for (b = 0; b < 8; b++)
			c->s[i] ^= (uint64_t)c->buf[i * 8 + b] << (8 * b);
	keccakf(c->s);
	c->pos = 0;
}

static void
shake_init(struct shake *c)
{
	memset(c, 0, sizeof(*c));
}

static void
shake_update(struct shake *c, const unsigned char *p, size_t len)
{
	size_t n;

	while (len > 0) {
		n = RATE - c->pos;
		n = n < len ? n : len;
		memcpy(c->buf + c->pos, p, n);
		c->pos += n; p += n; len -= n;
		if (c->pos == RATE)
			shake_block(c);
	}
}

/* pad, absorb, squeeze outlen (<= RATE) bytes */
static void
shake_final(struct shake *c, unsigned char *out, size_t outlen)
{
	size_t i;

	memset(c->buf + c->pos, 0, RATE - c->pos);
	c->buf[c->pos] ^= 0x1f;
	c->buf[RATE - 1] ^= 0x80;
	shake_block(c);
	for (i = 0; i < outlen; i++)
		out[i] = (unsigned char)(c->s[i / 8] >> (8 * (i % 8)));
}

/* --- per file ------------------------------------------------------------ */

static unsigned char iobuf[65536];

/* hash an open regular file into hex; 0 on success, errno on failure */
static int
hash_fd(int fd, char *hex, size_t xlen)
{
	static const char digits[] = "0123456789abcdef";
	unsigned char md[XMAX];
	struct shake c;
	ssize_t got;
	size_t i;

	shake_init(&c);
	for (;;) {
		got = read(fd, iobuf, sizeof(iobuf));
		if (got < 0 && errno == EINTR)
			continue;
		if (got < 0)
			return errno ? errno : EIO;
		if (got == 0)
			break;
		shake_update(&c, iobuf, (size_t)got);
	}
	shake_final(&c, md, xlen);
	for (i = 0; i < xlen; i++) {
		hex[2 * i] = digits[md[i] >> 4];
		hex[2 * i + 1] = digits[md[i] & 0xf];
	}
	hex[2 * xlen] = '\0';
	return 0;
}

/*
 * Fill hex with the hash column for name, or zeros for nodes not hashed.
 * Returns 0 to emit the line, -1 to skip it.
 */
static int
hash_col(const char *name, const struct stat *lst, char *hex, size_t xlen)
{
	struct stat st, fst;
	int fd, fl, err;

	memset(hex, '0', 2 * xlen);
	hex[2 * xlen] = '\0';
	st = *lst;
	if (S_ISLNK(lst->st_mode) && stat(name, &st) != 0) {
		WRN("dangling symlink, not hashed", name, "6ab75466");
		status |= ST_DANGLE;
		return 0;
	}
	if (S_ISDIR(st.st_mode))
		return 0;
	if (!S_ISREG(st.st_mode)) {
		WRN(S_ISFIFO(st.st_mode) ? "fifo, not hashed" :
		    S_ISSOCK(st.st_mode) ? "socket, not hashed" :
		    "special file, not hashed", name, "6ab75468");
		status |= ST_SPECIAL;
		return 0;
	}
	/* O_NONBLOCK: a node swapped in after stat cannot stall the open */
	fd = open(name, O_RDONLY | O_NOCTTY | O_NONBLOCK);
	if (fd < 0) {
		ERR("cannot read", name, errno, "6ab75467");
		status |= ST_READ;
		return -1;
	}
	if (fstat(fd, &fst) != 0 || !S_ISREG(fst.st_mode)) {
		(void)close(fd);
		WRN("changed during scan, not hashed", name, "6ab7e735");
		status |= ST_SPECIAL;
		return 0;
	}
	fl = fcntl(fd, F_GETFL);
	if (fl == -1 || fcntl(fd, F_SETFL, fl & ~O_NONBLOCK) == -1) {
		err = errno;
		(void)close(fd);
		ERR("cannot read", name, err, "6ab75467");
		status |= ST_READ;
		return -1;
	}
	err = hash_fd(fd, hex, xlen);
	(void)close(fd);
	if (err) {
		ERR("cannot read", name, err, "6ab75467");
		status |= ST_READ;
		return -1;
	}
	return 0;
}

static void
xwrite(const char *s, size_t len)
{
	if (fwrite(s, 1, len, stdout) != len)
		die(ST_ENV, "write error on stdout", NULL, "6ab7e736");
}

/* print one record: fields per -n, '.' for omitted, then decorated name */
static void
render(const struct rec *r)
{
	char pre[2 * XMAX + 128], f1[24], f2[24], f4[24], f5[24];
	int n;

	strcpy(f1, "."); strcpy(f2, "."); strcpy(f4, "."); strcpy(f5, ".");
	if (opt_n < 1)
		(void)snprintf(f1, sizeof(f1), "%8jx", r->v[0]);
	if (opt_n < 2)
		(void)snprintf(f2, sizeof(f2), "%2jx", r->v[1]);
	if (opt_n < 4)
		(void)snprintf(f4, sizeof(f4), "%8jx", r->v[3]);
	if (opt_n < 5)
		(void)snprintf(f5, sizeof(f5), "%08jx", r->v[4]);
	n = snprintf(pre, sizeof(pre), "%s %s %s %s %s ", f1, f2, r->hash, f4, f5);
	if (n < 0 || (size_t)n >= sizeof(pre))
		die(ST_ENV, "internal format overflow", NULL, "6ab7e737");
	xwrite(pre, (size_t)n);
	xwrite(r->name, strlen(r->name));
	xwrite("\n", 1);
}

static void
keep(struct rec *r)
{
	if (nrec == caprec) {
		size_t ncap = caprec ? caprec * 2 : 256;
		struct rec *p;

		if (ncap < caprec || ncap > SIZE_MAX / sizeof(*rec))
			die(ST_ENV, "out of memory", NULL, "6ab7e738");
		p = realloc(rec, ncap * sizeof(*rec));
		if (p == NULL)
			die(ST_ENV, "out of memory", NULL, "6ab7e738");
		rec = p;
		caprec = ncap;
	}
	rec[nrec++] = *r;
}

static void
do_file(const char *name)
{
	const char *sfx = "";
	struct stat lst;
	struct rec r;
	size_t nlen;

	if (lstat(name, &lst) != 0) {
		ERR("cannot stat", name, errno, "6ab75465");
		status |= ST_STAT;
		return;
	}
	strcpy(r.hash, ".");
	if (opt_x > 0 && hash_col(name, &lst, r.hash, (size_t)opt_x) != 0)
		return;
	/* omitted fields hold 0, so they compare equal under -k */
	r.v[0] = opt_n < 1 ? (uintmax_t)lst.st_ino : 0;
	r.v[1] = opt_n < 2 ? (uintmax_t)lst.st_nlink : 0;
	r.v[2] = 0;
	r.v[3] = opt_n < 4 ? (uintmax_t)lst.st_size : 0;
	r.v[4] = opt_n < 5 ? (uintmax_t)(intmax_t)lst.st_mtime : 0;
	r.mt = opt_n < 5 ? (intmax_t)lst.st_mtime : 0;
	/* ls -dF indicators, minus executable and whiteout */
	if (S_ISLNK(lst.st_mode)) sfx = "@";
	else if (S_ISDIR(lst.st_mode)) sfx = "/";
	else if (S_ISFIFO(lst.st_mode)) sfx = "|";
	else if (S_ISSOCK(lst.st_mode)) sfx = "=";
	nlen = strlen(name);
	if (nlen > SIZE_MAX - 2)
		die(ST_ENV, "out of memory", NULL, "6ab7e738");
	r.name = malloc(nlen + 2);
	if (r.name == NULL)
		die(ST_ENV, "out of memory", NULL, "6ab7e738");
	memcpy(r.name, name, nlen);
	strcpy(r.name + nlen, sfx);
	if (opt_k == 0 && opt_r == 0) {
		render(&r);
		free(r.name);
		return;
	}
	keep(&r);
}

/* --- sort: field N, the fields after it, name; then all fields, name ------ */

static int
cmp_field(const struct rec *a, const struct rec *b, int j)
{
	if (j == 6)
		return strcmp(a->name, b->name);
	if (j == 3)
		return strcmp(a->hash, b->hash);
	if (j == 5)
		return (a->mt > b->mt) - (a->mt < b->mt);
	return (a->v[j - 1] > b->v[j - 1]) - (a->v[j - 1] < b->v[j - 1]);
}

static int
cmp_from(const struct rec *a, const struct rec *b, int j)
{
	int c = 0;

	for (; j <= 6 && c == 0; j++)
		c = cmp_field(a, b, j);
	return c;
}

static int
cmp_rec(const void *pa, const void *pb)
{
	const struct rec *a = pa, *b = pb;
	int c;

	c = cmp_from(a, b, opt_k);
	if (c == 0)
		c = cmp_from(a, b, 1);	/* last resort, as sort(1) */
	return opt_r ? -c : c;
}

static void
flush_rec(void)
{
	size_t i;

	if (opt_k && nrec > 1)
		qsort(rec, nrec, sizeof(*rec), cmp_rec);
	for (i = 0; i < nrec; i++)
		render(&rec[opt_k || !opt_r ? i : nrec - 1 - i]);
	for (i = 0; i < nrec; i++)
		free(rec[i].name);
	free(rec);
	rec = NULL;
	nrec = caprec = 0;
}

/* --- interface ----------------------------------------------------------- */

static const char usage_text[] =
"  Usage: cksh [-NUM] [-n [NUM]] [-x [LEN]] [-k [N]] [-r] [FILE...]\n"
"  Output: inode links shake256 size mdate filename\n"
"    -n [NUM]  Omit NUM leading fields: 0-5 (bare: 0, default: 2)\n"
"    -x [LEN]  XOF hash length: 0=skip, 1-64 (bare: 0, default: 3)\n"
"    -k [N]    Sort on field N, then following fields: 1-6 (bare: 6)\n"
"    -r        Reverse: with -k reverse sort, alone reverse input order\n"
"              forms: -k[ ][N] -rk[ ][N] -kr[ ][N]\n"
"    --        End options; remaining args treated as filenames\n"
"    -h        Show help; --help for the manual\n"
"  Reads filenames from arguments or stdin.\n";

/* manual split into chunks below the C99 4095-byte literal minimum */
static const char *const manual[] = {
"NAME\n"
"  cksh - sortable stat and SHAKE256 listing of files\n"
"\n"
"SYNOPSIS\n"
"  cksh [-0..-5] [-n [NUM]] [-x [LEN]] [-k [N]] [-r] [--] [FILE...]\n"
"  cksh -h | --help\n"
"\n"
"DESCRIPTION\n"
"  For each FILE, or each line of stdin when no FILE is given, print\n"
"  one line of six space separated fields, numbers in lowercase hex\n"
"  padded to minimum widths, so the data aligns in columns:\n"
"\n"
"       inode lk hash       size    mdate name\n"
"      1cc01d  1 483366        3 5e0bd2c0 t/a\n"
"      1cc01c  2 000000     1000 5e0bd2c0 t/d/\n"
"      1cc01f  1 483366        1 5e0bd2c0 t/l@\n"
"\n"
"    inode  %8x   inode number of the node itself (not followed)\n"
"    lk     %2x   hard link count\n"
"    hash   SHAKE256 of the content, LEN bytes as 2*LEN hex digits;\n"
"           zeros for directories and nodes that are not hashed\n"
"    size   %8x   size in bytes (a symlink reports its own size)\n"
"    mdate  %08x  modification time, unix seconds\n"
"    name   as given, with ls -F style indicator:\n"
"           / directory  @ symlink  | fifo  = socket\n"
"\n"
"  Omitted fields print as '.', so field numbers never shift and the\n"
"  name always begins at field 6. A value wider than its column offsets\n"
"  the rest of that line only; fields stay space separated, so awk $N\n"
"  and sorting by field are unaffected. A name containing spaces runs\n"
"  to end of line; recover it with:\n"
"    awk '{print substr($0, index($0,$6))}'\n"
"\n"
"  Symlinks report their own inode, links, size and mdate, but the\n"
"  hash is of the target content.\n"
"\n"
"OPTIONS\n"
"  -0 .. -5   same as -n 0 .. -n 5\n"
"  -n [NUM]   omit the first NUM fields, 0-5. Bare -n (last on the\n"
"             line) means 0. Default 2: inode and links are omitted,\n"
"             since they differ between copies of identical trees.\n"
"             NUM above 2 omits the hash, so no file is read.\n"
"  -x [LEN]   hash length in bytes, 0-64; 0 skips hashing. Bare -x\n"
"             means 0. Default 3 (6 hex digits) suits change and\n"
"             integrity checks among a person's own files; use 32 or\n"
"             more where collisions must be infeasible.\n"
"  -k [N]     sort on field N, 1-6, then the fields after it, then\n"
"             the name. Hex numbers compare by value, so wide values\n"
"             sort correctly; hash and name compare bytewise, as in\n"
"             LC_ALL=C. An omitted field compares equal. Bare -k\n"
"             means 6 (by name). Sorting buffers all output; without\n"
"             -k or -r lines stream as produced.\n"
"             A following word is taken as N only if it consists of\n"
"             digits or 'r'; otherwise -k is bare and the word is a\n"
"             file, so 'cksh -k *' works. Use -- or ./ for a file\n"
"             named like a number.\n"
"  -r         with -k, reverse the sort; alone, reverse input order.\n"
"             Accepted forms: -k[ ][N]  -rk[ ][N]  -kr[ ][N]\n"
"             Invalid: -k r  -k5r  -k 7\n"
"  --         end of options\n"
"  -h         short usage\n"
"  --help     this manual\n"
"\n"
,
"EXAMPLES\n"
"  cksh -k5 *                     by modification time, oldest first\n"
"  cksh -rk5 *                    newest first\n"
"  find . -type f | cksh -k3      group identical content by hash\n"
"  cksh -x 32 -n 0 file           full 256 bit digest with inode\n"
"  cksh -4 -k4 *                  names and sizes, sorted by size\n"
"  find a -type f | cksh > a.ck; find b -type f | cksh > b.ck\n"
"                                 compare trees with diff or join\n"
"\n"
"HASH\n"
"  SHAKE256 is an extendable output function: the first L bytes of a\n"
"  longer digest equal the L byte digest, so -x 3 values remain valid\n"
"  prefixes of -x 32 values and of openssl shake256 -xoflen output.\n"
"  The C binary computes SHAKE256 itself (FIPS 202) and needs no\n"
"  openssl. The bash function uses openssl, preferring pkgsrc\n"
"  $LOCALBASE/bin/openssl; with OpenSSL older than 3.0 it truncates\n"
"  the 32 byte default digest, which limits it to -x 32.\n"
"\n"
"EXIT STATUS\n"
"  A bitmask. 1 and 2 are fatal and stop before any file is read;\n"
"  the others accumulate while the run continues.\n"
"     0  success\n"
"     1  invalid option or argument\n"
"     2  environment: out of memory, stdin or stdout failure\n"
"        (bash: no usable openssl shake256 for the requested -x)\n"
"     4  cannot stat a name; line skipped\n"
"     8  cannot open or read a regular file; line skipped\n"
"    16  fifo, socket or device; warned, never opened, hash zeros\n"
"    32  dangling symlink; warned, hash zeros\n"
"  e.g. 52 = 4|16|32: a missing name, a fifo and a dangling link.\n"
"\n"
"DIAGNOSTICS\n"
"  On stderr, errors as '>>> cksh : ...' and warnings as\n"
"  '^^^ cksh : ...', each ending in a hex tag naming the message.\n"
"\n"
"NOTES\n"
"  Names are read one per line; a name containing a newline cannot be\n"
"  passed on stdin.\n"
"\n"
"HISTORY\n"
"  rev 6ab7e734 20260926 083932 PDT Sat 08:39 AM 26 Sep 2026\n"
"      C port with built-in SHAKE256; openssl<3 xoflen fallback in the\n"
"      bash function; -k/-r value sort; --help manual; status bitmask;\n"
"      chkerr/chkwrn diagnostics; bash helpers isolated in a subshell.\n"
"      Changes from 68e9ff40: non-regular nodes hash as zeros (were\n"
"      blank); fifos are warned and never opened (blocked the run);\n"
"      per-file errors warn and continue (aborted the run); exit status\n"
"      is a bitmask (was 0 or 1); ls -F indicators come from lstat, so a\n"
"      name ending in * or % keeps it (was stripped); stdin names are\n"
"      read raw, backslashes kept; numbers formatted by printf, not awk.\n"
"  rev 68e9ff40 20251010 235456 PDT Fri 11:54 PM 10 Oct 2025\n"
"      -0..-5, bare -n and -x (getopts :), -n and -x range validation\n"
"  rev 68e20bca 20251004 231018 PDT Sat 11:10 PM 04 Oct 2025\n"
"      renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired\n"
"  rev 677c9c44 20250106 191516 PST Mon 07:15 PM 06 Jan 2025\n"
"      chksthash, from ckstatsum: shake256 -xoflen 3 hash column\n"
"  org 6305e87b 20220824 015939 PDT Wed 01:59 AM 24 Aug 2022\n"
"      ckstat ckstatsum cks\n"
"\n"
,
"COPYRIGHT\n"
"  (c) 2017-2026 George Georgalis <george@iuxta.com>\n"
"  Unlimited use with attribution.\n"
};

static void
put_help(int full)
{
	size_t i;

	if (!full) {
		xwrite(usage_text, sizeof(usage_text) - 1);
	} else {
		for (i = 0; i < sizeof(manual) / sizeof(manual[0]); i++)
			xwrite(manual[i], strlen(manual[i]));
	}
	if (fflush(stdout) != 0 || ferror(stdout))
		die(ST_ENV, "write error on stdout", NULL, "6ab7e736");
	exit(0);
}

/* strict decimal in [lo, hi]; -1 if not */
static int
num(const char *s, int lo, int hi)
{
	char *end;
	unsigned long v;

	if (s == NULL || *s < '0' || *s > '9')
		return -1;
	errno = 0;
	v = strtoul(s, &end, 10);
	if (errno || *end != '\0' || v < (unsigned long)lo || v > (unsigned long)hi)
		return -1;
	return (int)v;
}

static int
only_digits_r(const char *s)
{
	if (*s == '\0')
		return 0;
	for (; *s; s++)
		if (!(*s == 'r' || (*s >= '0' && *s <= '9')))
			return 0;
	return 1;
}

/* getopts-compatible parse of ":012345n:x:k:rh" plus --help and -kr[N] */
static int
parse(int argc, char **argv)
{
	int i, v;

	for (i = 1; i < argc; i++) {
		char *w = argv[i], *p;

		if (w[0] != '-' || w[1] == '\0')
			break;
		if (strcmp(w, "--") == 0)
			return i + 1;
		if (w[1] == '-') {
			if (strcmp(w, "--help") == 0)
				put_help(1);
			die(ST_USAGE, "invalid option", w, "6ab75461");
		}
		for (p = w + 1; *p; p++) {
			char c = *p;
			const char *arg;

			if (c >= '0' && c <= '5') { opt_n = c - '0'; continue; }
			if (c == 'r') { opt_r = 1; continue; }
			if (c == 'h') put_help(0);
			if (c != 'n' && c != 'x' && c != 'k') {
				char o[3] = { '-', c, '\0' };
				die(ST_USAGE, "invalid option", o, "68e9fa9a");
			}
			/* -kr[N]: whole word only, r then optional attached N */
			if (c == 'k' && p == w + 1 && p[1] == 'r') {
				opt_r = 1;
				p++;
			}
			if (p[1] != '\0') {
				arg = p + 1;
			} else if (i + 1 < argc &&
			    (c != 'k' || only_digits_r(argv[i + 1]))) {
				arg = argv[++i];
			} else {
				arg = NULL;	/* bare */
			}
			if (c == 'n') {
				v = arg ? num(arg, 0, 5) : 0;
				if (v < 0)
					die(ST_USAGE, "-n requires 0-5, got", arg, "68e9fbb2");
				opt_n = v;
			} else if (c == 'x') {
				v = arg ? num(arg, 0, XMAX) : 0;
				if (v < 0)
					die(ST_USAGE, "-x requires 0-64, got", arg, "68e9fc22");
				opt_x = v;
			} else {
				v = arg ? num(arg, 1, 6) : 6;
				if (v < 0)
					die(ST_USAGE, "-k requires 1-6, got", arg, "6ab75460");
				opt_k = v;
			}
			break;	/* argument consumed the rest of the word */
		}
	}
	return i;
}

int
main(int argc, char **argv)
{
	int i;

	if (argc > 0 && argv[0] && *argv[0]) {
		const char *b = strrchr(argv[0], '/');
		prog = b ? b + 1 : argv[0];
	}
	i = parse(argc, argv);
	if (opt_n > 2)
		opt_x = 0;	/* hash field omitted, do not read files */

	if (i < argc) {
		for (; i < argc; i++)
			if (argv[i][0] != '\0')
				do_file(argv[i]);
	} else {
		char *ln = NULL;
		size_t cap = 0;
		ssize_t len;

		while ((len = getline(&ln, &cap, stdin)) != -1) {
			if (len > 0 && ln[len - 1] == '\n')
				ln[--len] = '\0';
			if (len > 0 && strlen(ln) == (size_t)len) {
				do_file(ln);
			} else if (len > 0) {
				ERR("NUL in input line, skipped", NULL, 0, "6ab7e739");
				status |= ST_STAT;
			}
		}
		if (ferror(stdin))
			die(ST_ENV, "read error on stdin", NULL, "6ab7e73a");
		free(ln);
	}
	flush_rec();
	if (fflush(stdout) != 0 || ferror(stdout) || fclose(stdout) != 0)
		die(ST_ENV, "write error on stdout", NULL, "6ab7e736");
	return status;
}
