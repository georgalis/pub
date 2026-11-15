/* cksh.c --- sortable stat and SHAKE256 listing of files
 *
 * One line per file named in the arguments or on standard input:
 * inode links hash size mdate name, the numbers in hexadecimal, the
 * name last. Sorting is built in, with the key grammar of srt(1).
 * Requirements and decision record: plan-cksh.md.
 *
 * Dependency posture: C99 and POSIX.1-2008 libc only. SHAKE256 (FIPS
 * 202) is implemented here rather than linked from a crypto library,
 * whose shake256 support and output-length option vary by host. An
 * extendable output of one length is the beginning of every longer
 * one, so each -x from 1 to 128 is exact on any host. No setlocale()
 * call is made. Static on Linux and NetBSD; Darwin links the system
 * library alone.
 *
 * -o writes a temporary sibling of the destination, syncs it, gives it
 * the destination's mode and renames it over; every fatal path and the
 * signals INT, HUP and TERM remove the temporary file, so the original
 * is replaced whole or not at all.
 *
 * Records keep their raw values; -k compares numbers by value, so a
 * value wider than its column still sorts correctly.
 *
 * Reversals of r0.5, recorded here and in plan-cksh.md section 12:
 *   - -x counts hexadecimal characters (was bytes); default 6
 *   - -0..-5 and -krN are retired for -nN and -kNr
 *   - -k takes a list of columns, and the columns it does not name
 *     follow left to right (was: field N, the fields after it, name)
 *   - a negative mdate prints as signed hex (was two's complement)
 *
 * revision 6af8d530 20261114 134000 PST Sat --- r0.6 key list -k5,4;
 *          -x in hex characters, hash named shake256-N; -n and -x bare
 *          before a file; -0..-5 and -krN retired; signed mdate; names
 *          escaped on a terminal; d/ keeps one slash; node identity
 *          checked after open; -Z NUL records; -L follow symlinks; -o
 *          output renamed into place; -c check a saved listing (status
 *          64); --help as a man page on a terminal, --man its source;
 *          -V, --fn and --bin; manual on the srt model
 * revision 6ab7e734 20260926 083932 PDT Sat --- r0.5 C port, built-in
 *          SHAKE256; -k/-r value sort; --help manual; status bitmask
 * revision 68e9ff40 20251010 235456 PDT Fri --- r0.4 -0..-5, bare -n
 *          and -x, range validation (bash function)
 * revision 68e20bca 20251004 231018 PDT Sat --- r0.3 renamed cksh
 * revision 677c9c44 20250106 191516 PST Mon --- r0.2 chksthash, hash column
 * original 6305e87b 20220824 015939 PDT Wed --- r0.1 ckstat ckstatsum cks
 *
 * (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 */
#define _POSIX_C_SOURCE 200809L

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CKSH_REV "cksh r0.6 6af8d530"

/* exit status bits; 1 and 2 are fatal and exclusive, the rest accumulate */
#define ST_USAGE   1	/* invalid option or argument */
#define ST_ENV     2	/* out of memory, stdin read or stdout write failure */
#define ST_STAT    4	/* lstat failed, line skipped */
#define ST_READ    8	/* regular file open or read failed, line skipped */
#define ST_SPECIAL 16	/* fifo, socket, device, or changed node: not hashed */
#define ST_DANGLE  32	/* symlink target unresolvable, not hashed */
#define ST_DIFF    64	/* -c: a file differs from its record */

#define XHEX 128	/* max -x, hexadecimal characters */
#define XMAX (XHEX / 2)	/* the same in bytes */
#define RATE 136	/* SHAKE256 rate in bytes */
#define NCOL 6
#define HAVE(j) (1u << (j))	/* column j, 1-5, is present in a record */

/* one output line: raw values (0 when omitted), hash text, decorated name */
struct rec {
	uintmax_t v[5];		/* ino, links, (hash slot unused), size, (mtime: mt) */
	intmax_t mt;		/* mtime, signed */
	char hash[XHEX + 1];	/* hex, or "." when not computed */
	char *name;		/* name plus ls -F indicator */
	unsigned have;		/* HAVE() bits: the columns this record holds */
	size_t seq;		/* input order: the last tie-break */
};

static const char *prog = "cksh";

/* options */
static int opt_n = 2, opt_x = 6, opt_r = 0, opt_k = 0, opt_z = 0, opt_L = 0;
static const char *opt_o, *opt_c;	/* -o output, -c listing */
static unsigned have;			/* columns of the record being made */

/* -o: the temporary file, removed on any exit but the last */
static char *otmp;
static const char *odest;
static int kcol[NCOL], krev[NCOL], nk;	/* -k list as given */
static int klet[NCOL + 1];		/* column carries letters of its own */
static int ord[NCOL], rev[NCOL];	/* resolved comparison order */

static int esc_out, esc_err;		/* escape names: stream is a terminal */

/* sort buffer */
static struct rec *rec;
static size_t nrec, caprec, nseq;

static int status;

/* ---- names ------------------------------------------------------------- */

/*
 * Write a name. With esc, C0 and C1 control characters, DEL and bytes
 * that are not valid UTF-8 are written as \ooo, so a crafted name
 * cannot drive a terminal. Returns nonzero on a write error.
 */
static int
put_name(FILE *f, const char *name, int esc)
{
	const unsigned char *s = (const unsigned char *)name;
	size_t n = strlen(name), i = 0, k, j;

	if (!esc)
		return fwrite(name, 1, n, f) != n;
	while (i < n) {
		unsigned b = s[i], lo = 0x80, hi = 0xbf;

		k = 0;
		if (b < 0x80) {
			if (b < 0x20 || b == 0x7f) {
				if (fprintf(f, "\\%03o", b) < 0)
					return 1;
			} else if (putc((int)b, f) == EOF) {
				return 1;
			}
			i++;
			continue;
		}
		if (b >= 0xc2 && b <= 0xdf) k = 1;
		else if (b == 0xe0) { k = 2; lo = 0xa0; }
		else if (b == 0xed) { k = 2; hi = 0x9f; }
		else if (b >= 0xe1 && b <= 0xef) k = 2;
		else if (b == 0xf0) { k = 3; lo = 0x90; }
		else if (b >= 0xf1 && b <= 0xf3) k = 3;
		else if (b == 0xf4) { k = 3; hi = 0x8f; }
		if (k && i + k < n && s[i + 1] >= lo && s[i + 1] <= hi) {
			for (j = 2; j <= k && s[i + j] >= 0x80 && s[i + j] <= 0xbf; j++)
				;
			if (j <= k)
				k = 0;
		} else {
			k = 0;
		}
		if (k && !(b == 0xc2 && s[i + 1] <= 0x9f)) {
			if (fwrite(s + i, 1, k + 1, f) != k + 1)
				return 1;
			i += k + 1;
			continue;
		}
		/* invalid byte, or a C1 control (c2 80..9f): escape it */
		for (j = 0; j <= (k ? 1u : 0u); j++)
			if (fprintf(f, "\\%03o", (unsigned)s[i + j]) < 0)
				return 1;
		i += k ? 2 : 1;
	}
	return 0;
}

/*
 * Diagnostics, formatted as the shell chkerr (">>> ") and chkwrn ("^^^ ")
 * functions: "cksh : what 'name'[: reason] (tag)".
 */
static void
msg(const char *lvl, const char *what, const char *name, int err, const char *tag)
{
	/* stderr failure has nowhere else to go */
	(void)fprintf(stderr, "%s%s : %s", lvl, prog, what);
	if (name) {
		(void)fputs(" '", stderr);
		(void)put_name(stderr, name, esc_err);
		(void)fputs("'", stderr);
	}
	(void)fprintf(stderr, "%s%s (%s)\n", err ? ": " : "",
	    err ? strerror(err) : "", tag);
}
#define ERR(w, n, e, t) msg(">>> ", (w), (n), (e), (t))
#define WRN(w, n, t)    msg("^^^ ", (w), (n), 0, (t))

/* every exit after options are read: an unfinished -o file is removed */
static void
bye(int st)
{
	if (otmp)
		(void)unlink(otmp);
	exit(st);
}

static void
die(int st, const char *what, const char *name, const char *tag)
{
	ERR(what, name, 0, tag);
	bye(st);
}

/* ---- SHAKE256 ---------------------------------------------------------- */

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

/* ---- per file ---------------------------------------------------------- */

static unsigned char iobuf[65536];

/* hash an open regular file into xlen hex characters; 0, or errno */
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
	shake_final(&c, md, (xlen + 1) / 2);
	for (i = 0; i < xlen; i++)
		hex[i] = digits[(i & 1) ? md[i / 2] & 0xf : md[i / 2] >> 4];
	hex[xlen] = '\0';
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

	memset(hex, '0', xlen);
	hex[xlen] = '\0';
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
	/* the node opened must be the node examined: regular, same identity */
	if (fstat(fd, &fst) != 0 || !S_ISREG(fst.st_mode) ||
	    fst.st_dev != st.st_dev || fst.st_ino != st.st_ino) {
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

/* the node a name stands for: the link itself, or with -L what it leads
 * to; a link that leads nowhere is the link either way. 0, or -1 (errno) */
static int
node(const char *name, struct stat *st)
{
	if (opt_L && stat(name, st) == 0)
		return 0;
	return lstat(name, st);
}

/* ls -dF indicators, minus executable and whiteout; d/ stays d/ */
static const char *
indicator(const char *name, const struct stat *st)
{
	size_t n = strlen(name);

	if (S_ISLNK(st->st_mode)) return "@";
	if (S_ISDIR(st->st_mode)) return n && name[n - 1] == '/' ? "" : "/";
	if (S_ISFIFO(st->st_mode)) return "|";
	if (S_ISSOCK(st->st_mode)) return "=";
	return "";
}

/* columns 1 2 4 5 as text, padded to their least widths; "." if absent */
static void
fields(const struct rec *r, char f[5][24])
{
	int j;

	for (j = 0; j < 5; j++)
		strcpy(f[j], ".");
	if (r->have & HAVE(1))
		(void)snprintf(f[0], 24, "%8jx", r->v[0]);
	if (r->have & HAVE(2))
		(void)snprintf(f[1], 24, "%2jx", r->v[1]);
	if (r->have & HAVE(4))
		(void)snprintf(f[3], 24, "%8jx", r->v[3]);
	if ((r->have & HAVE(5)) && r->mt < 0)	/* signed: srt -x orders it before 0 */
		(void)snprintf(f[4], 24, "-%07jx", (uintmax_t)(-(r->mt + 1)) + 1);
	else if (r->have & HAVE(5))
		(void)snprintf(f[4], 24, "%08jx", (uintmax_t)r->mt);
}

/* print one record: its columns, '.' for omitted, then the decorated name */
static void
render(const struct rec *r)
{
	char pre[XHEX + 128], f[5][24];
	int n;

	fields(r, f);
	n = snprintf(pre, sizeof(pre), "%s %s %s %s %s ", f[0], f[1], r->hash,
	    f[3], f[4]);
	if (n < 0 || (size_t)n >= sizeof(pre))
		die(ST_ENV, "internal format overflow", NULL, "6ab7e737");
	xwrite(pre, (size_t)n);
	if (put_name(stdout, r->name, esc_out))
		die(ST_ENV, "write error on stdout", NULL, "6ab7e736");
	xwrite(opt_z ? "" : "\n", 1);	/* -Z: the NUL of the empty string */
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

/*
 * Make the record of one name under the columns in have and the hash
 * length opt_x. 0 with r->name allocated, or -1 with the reason reported
 * and the status set.
 */
static int
examine(const char *name, struct rec *r)
{
	const char *sfx;
	struct stat st;
	size_t nlen;

	if (node(name, &st) != 0) {
		ERR("cannot stat", name, errno, "6ab75465");
		status |= ST_STAT;
		return -1;
	}
	strcpy(r->hash, ".");
	if ((have & HAVE(3)) && hash_col(name, &st, r->hash, (size_t)opt_x) != 0)
		return -1;
	/* omitted columns hold 0, so they compare equal under -k */
	r->v[0] = (have & HAVE(1)) ? (uintmax_t)st.st_ino : 0;
	r->v[1] = (have & HAVE(2)) ? (uintmax_t)st.st_nlink : 0;
	r->v[2] = 0;
	r->v[3] = (have & HAVE(4)) ? (uintmax_t)st.st_size : 0;
	r->v[4] = 0;
	r->mt = (have & HAVE(5)) ? (intmax_t)st.st_mtime : 0;
	r->have = have;
	r->seq = nseq++;
	sfx = indicator(name, &st);
	nlen = strlen(name);
	if (nlen > SIZE_MAX - 2)
		die(ST_ENV, "out of memory", NULL, "6ab7e738");
	r->name = malloc(nlen + 2);
	if (r->name == NULL)
		die(ST_ENV, "out of memory", NULL, "6ab7e738");
	memcpy(r->name, name, nlen);
	strcpy(r->name + nlen, sfx);
	return 0;
}

/* write the record now, or hold it for -k or -r */
static void
emit(struct rec *r)
{
	if (!opt_k && !opt_r) {
		render(r);
		free(r->name);
		return;
	}
	keep(r);
}

static void
do_file(const char *name)
{
	struct rec r;

	if (examine(name, &r) == 0)
		emit(&r);
}

/* ---- -c: a listing read back against the files it names ---------------- */

static int
isblank_(int c)
{
	return c == ' ' || c == '\t';
}

/*
 * One record of a listing: five words, one blank, the name to the end.
 * The record says which columns it holds (a dot is an absent column) and
 * how long its hash is, so it is checked exactly as it was made. The file
 * is the name less its indicator, or the name itself where a file of that
 * very name gives the record's name back. A record whose file now differs
 * in any column it holds, or in its indicator, is written anew.
 */
static void
check_rec(char *ln, const char *listing, uintmax_t lineno)
{
	char *w[5], *p = ln, *lname, *cand[2], f[5][24], what[96];
	const char *pick = NULL;
	struct stat st;
	struct rec r;
	size_t n, k;
	int j, nc = 0, differs = 0;

	for (j = 0; j < 5; j++) {
		while (isblank_(*p))
			p++;
		w[j] = p;
		while (*p && !isblank_(*p))
			p++;
		if (p == w[j] || *p == '\0')
			break;
		*p++ = '\0';
	}
	lname = p;
	if (j < 5 || *lname == '\0' || strlen(w[2]) > XHEX) {
		(void)snprintf(what, sizeof(what),
		    "-c: record %ju is not a cksh line, in", lineno);
		die(ST_USAGE, what, listing, "6af8d541");
	}
	have = 0;
	for (j = 0; j < 5; j++)
		if (strcmp(w[j], ".") != 0)
			have |= HAVE(j + 1);
	opt_x = (have & HAVE(3)) ? (int)strlen(w[2]) : 0;

	/* candidates: the name less its indicator, then the name as it is */
	n = strlen(lname);
	cand[0] = NULL;
	if (n > 1 && strchr("/@|=", lname[n - 1])) {
		cand[0] = malloc(n);
		if (cand[0] == NULL)
			die(ST_ENV, "out of memory", NULL, "6ab7e738");
		memcpy(cand[0], lname, n - 1);
		cand[0][n - 1] = '\0';
		nc = 1;
	}
	cand[1] = lname;
	for (j = 1 - nc; j < 2 && !pick; j++) {	/* one that gives the name back */
		if (node(cand[j], &st) != 0)
			continue;
		k = strlen(cand[j]);
		if (strncmp(lname, cand[j], k) == 0 &&
		    strcmp(lname + k, indicator(cand[j], &st)) == 0)
			pick = cand[j];
	}
	for (j = 1 - nc; j < 2 && !pick; j++)	/* else one that exists */
		if (node(cand[j], &st) == 0)
			pick = cand[j];
	if (!pick) {
		ERR("cannot stat", lname, errno, "6ab75465");
		status |= ST_STAT;
	} else if (examine(pick, &r) == 0) {
		fields(&r, f);
		for (j = 0; j < 5; j++) {
			const char *cur = j == 2 ? r.hash : f[j];

			while (*cur == ' ')
				cur++;
			if ((have & HAVE(j + 1)) && strcmp(cur, w[j]) != 0)
				differs = 1;
		}
		if (strcmp(r.name, lname) != 0)
			differs = 1;
		if (differs) {
			status |= ST_DIFF;
			emit(&r);
		} else {
			free(r.name);
		}
	}
	free(cand[0]);
}

static void
check(const char *listing)
{
	FILE *f = strcmp(listing, "-") == 0 ? stdin : fopen(listing, "r");
	int delim = opt_z ? '\0' : '\n';
	uintmax_t lineno = 0;
	char *ln = NULL;
	size_t cap = 0;
	ssize_t len;

	if (f == NULL) {
		ERR("-c: cannot read the listing", listing, errno, "6af8d540");
		bye(ST_ENV);
	}
	while ((len = getdelim(&ln, &cap, delim, f)) != -1) {
		lineno++;
		if (len > 0 && ln[len - 1] == delim)
			ln[--len] = '\0';
		if (len > 0 && strlen(ln) == (size_t)len) {
			check_rec(ln, listing, lineno);
		} else if (len > 0) {
			ERR("NUL in input line, skipped", NULL, 0, "6ab7e739");
			status |= ST_STAT;
		}
	}
	if (ferror(f)) {
		ERR("-c: cannot read the listing", listing, errno, "6af8d540");
		bye(ST_ENV);
	}
	free(ln);
	if (f != stdin)
		(void)fclose(f);
}

/* ---- sort: the named columns, then the rest left to right -------------- */

static int
cmp_col(const struct rec *a, const struct rec *b, int j)
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
cmp_rec(const void *pa, const void *pb)
{
	const struct rec *a = pa, *b = pb;
	int i, c;

	for (i = 0; i < NCOL; i++) {
		c = cmp_col(a, b, ord[i]);
		if (c)
			return rev[i] ? -c : c;
	}
	return (a->seq > b->seq) - (a->seq < b->seq);	/* stable, as srt */
}

/*
 * Resolve -k and -r into ord[] and rev[]. Named columns first, in the
 * order given, then the columns not named, left to right; a bare -k
 * names none, and then the name leads. A column written with letters
 * keeps its own direction; -r reaches every other column.
 */
static void
resolve(void)
{
	int seen[NCOL + 1] = { 0 }, i, j, n = 0;

	for (i = 0; i < nk; i++) {
		ord[n] = kcol[i];
		rev[n++] = klet[kcol[i]] ? krev[i] : opt_r;
		seen[kcol[i]] = 1;
	}
	if (nk == 0) {
		ord[n] = 6;
		rev[n++] = opt_r;
		seen[6] = 1;
	}
	for (j = 1; j <= NCOL; j++)
		if (!seen[j]) {
			ord[n] = j;
			rev[n++] = opt_r;
		}
}

static void
flush_rec(void)
{
	size_t i;

	if (opt_k && nrec > 1) {
		resolve();
		qsort(rec, nrec, sizeof(*rec), cmp_rec);
	}
	/* -r without -k: input order, reversed */
	for (i = 0; i < nrec; i++)
		render(&rec[opt_k ? i : nrec - 1 - i]);
	for (i = 0; i < nrec; i++)
		free(rec[i].name);
	free(rec);
	rec = NULL;
	nrec = caprec = 0;
}

/* ---- -o: the result beside its destination, then renamed over it ------- */

static void
on_signal(int sig)
{
	(void)sig;
	if (otmp)
		(void)unlink(otmp);	/* async-signal-safe */
	_exit(130);
}

/*
 * Point standard output at the destination. A regular or absent file is
 * written as a temporary sibling and renamed into place at the end, so
 * a failed or interrupted run leaves the original as it was. Any other
 * node (a device, a fifo) is written through: a rename would destroy it.
 */
static void
out_open(const char *dest)
{
	static const char leaf[] = ".cksh.XXXXXX";
	struct sigaction sa;
	const char *slash = strrchr(dest, '/');
	size_t dlen = slash ? (size_t)(slash - dest) + 1 : 0;
	struct stat st;
	mode_t mode, um;
	int fd, err;

	if (stat(dest, &st) == 0) {
		if (S_ISDIR(st.st_mode))
			die(ST_USAGE, "-o names a directory", dest, "6af8d53d");
		if (!S_ISREG(st.st_mode)) {
			fd = open(dest, O_WRONLY | O_NOCTTY);
			if (fd < 0 || dup2(fd, STDOUT_FILENO) < 0) {
				ERR("-o: cannot write", dest, errno, "6af8d53e");
				bye(ST_ENV);
			}
			(void)close(fd);
			return;
		}
		mode = st.st_mode & 07777;
	} else {
		um = umask(0);
		(void)umask(um);
		mode = 0666 & ~um;
	}
	otmp = malloc(dlen + sizeof(leaf));
	if (otmp == NULL)
		die(ST_ENV, "out of memory", NULL, "6ab7e738");
	memcpy(otmp, dest, dlen);
	memcpy(otmp + dlen, leaf, sizeof(leaf));
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = on_signal;
	(void)sigemptyset(&sa.sa_mask);
	(void)sigaction(SIGINT, &sa, NULL);
	(void)sigaction(SIGHUP, &sa, NULL);
	(void)sigaction(SIGTERM, &sa, NULL);
	fd = mkstemp(otmp);
	if (fd < 0) {
		err = errno;
		free(otmp);
		otmp = NULL;
		ERR("-o: cannot write beside", dest, err, "6af8d53e");
		bye(ST_ENV);
	}
	if (fchmod(fd, mode) != 0 || dup2(fd, STDOUT_FILENO) < 0) {
		ERR("-o: cannot write", dest, errno, "6af8d53e");
		bye(ST_ENV);
	}
	(void)close(fd);
	odest = dest;
}

/* all output written: sync the temporary file and rename it into place */
static void
out_commit(void)
{
	if (fflush(stdout) != 0 || ferror(stdout))
		die(ST_ENV, "write error on stdout", NULL, "6ab7e736");
	if (otmp == NULL)
		return;
	if (fsync(STDOUT_FILENO) != 0 || rename(otmp, odest) != 0) {
		ERR("-o: cannot write", odest, errno, "6af8d53e");
		bye(ST_ENV);
	}
	free(otmp);
	otmp = NULL;
}

/* ---- text -------------------------------------------------------------- */

static const char USAGE[] =
"usage: cksh [-rLZ] [-n[0-5]] [-x[0-128]] [-k [col[r][,col[r]]...]]\n"
"            [-o output] [-c listing | [--] file ...]\n"
"       cksh -h | --help | --man | -V | --version   (--fn | --bin: --help)\n"
"  One line per file: inode links hash size mdate name, numbers in hex.\n"
"  Names come from the arguments, or one per line from standard input.\n"
"  -n[N]  omit the first N columns, 0-5; each prints as a dot\n"
"         (default 2; -n alone is -n0)\n"
"  -x[N]  hash length in hexadecimal characters, 0-128; 0 skips hashing\n"
"         (default 6, the hash shake256-6; -x alone is -x0)\n"
"  -k5,4  sort by column 5, then 4, then the remaining columns in order.\n"
"         Numbers compare by value; the hash and the name as bytes.\n"
"  -k     alone: sort by name\n"
"  -k5r   r reverses that column; -r reverses every column written\n"
"         without a letter. -r without -k reverses input order.\n"
"  -L     follow symlinks: the line is that of the file a link leads to\n"
"  -Z     end lines, and names on standard input, with NUL, not newline\n"
"  -o output   write the result to output, renamed into place when done\n"
"  -c listing  check a saved listing: write the line of each file that\n"
"              differs from it; exit status 64 if any does\n"
"  --help  full manual\n";

/* The manual. Each element stays under the C99 4095-byte literal limit.
 * cksh.1 is this text as man page source, written by --man. */
static const char *const MANUAL[] = {
"NAME\n"
"\n"
"    cksh - sortable stat and SHAKE256 listing of files\n"
"\n"
"SYNOPSIS\n"
"\n"
"    cksh [-rLZ] [-n[0-5]] [-x[0-128]] [-k [col[r][,col[r]]...]]\n"
"         [-o output] [-c listing | [--] file ...]\n"
"    cksh -h | --help | --man | -V | --version\n"
"    cksh --fn ... | cksh --bin ...\n"
"\n"
"DESCRIPTION\n"
"\n"
"    For each file, or for each line of standard input when no file is\n"
"    given, cksh writes one line of six columns. Numbers are lowercase\n"
"    hexadecimal, padded to a least width so that ordinary values line\n"
"    up:\n"
"\n"
"           inode lk hash       size    mdate name\n"
"          1cc01d  1 483366        3 5e0bd2c0 t/a\n"
"          1cc01c  2 000000     1000 5e0bd2c0 t/d/\n"
"          1cc01f  1 483366        1 5e0bd2c0 t/l@\n"
"\n"
"    The heading is shown for reference; cksh does not write it.\n"
"\n"
"      1 inode  inode number of the node itself; a symlink is not\n"
"               followed\n"
"      2 lk     hard link count\n"
"      3 hash   shake256-N of the content, N hexadecimal characters\n"
"               (see HASH); zeros for a directory and for any node\n"
"               that is not hashed\n"
"      4 size   size in bytes; a symlink reports its own size\n"
"      5 mdate  modification time in seconds since the epoch; a time\n"
"               before 1970 is written with a minus sign, -12cf8700\n"
"      6 name   as given, with an indicator in the manner of ls -F:\n"
"               / directory  @ symlink  | fifo  = socket\n"
"               A directory named with a trailing slash keeps the one.\n"
"\n"
"    Columns are words, as $1, $2 ... are in awk. An omitted column is\n"
"    written as a dot, so the column numbers never shift and the name\n"
"    always begins at column 6. Widths are not significant: a value\n"
"    wider than its column moves the rest of that line and nothing\n"
"    else. The name runs to the end of the line, blanks included:\n"
"        awk '{print substr($0, index($0,$6))}'\n"
"\n"
"    A symlink reports its own inode, links, size and mdate, and the\n"
"    hash of the content it leads to. With -L it reports the file it\n"
"    leads to in every column.\n"
"\n"
"    Without -k or -r each line is written as its file is read. With\n"
"    either, the lines are held until the last file is read.\n"
"\n",
"OPTIONS\n"
"\n"
"    -n[N]\n"
"        Omit the first N columns, 0 to 5. Default 2: inode and links\n"
"        are omitted, since they differ between copies of the same\n"
"        tree. From -n3 up the hash is omitted and no file is read.\n"
"        -n alone is -n0, every column.\n"
"    -x[N]\n"
"        Length of the hash in hexadecimal characters, 0 to 128.\n"
"        Default 6. -x alone is -x0, which skips hashing: column 3 is\n"
"        a dot and no file is read. See HASH.\n"
"    -k [col[r][,col[r]]...]\n"
"        Sort. See KEYS.\n"
"    -r  With -k, reverse every column written without a letter of\n"
"        its own. Without -k, write the lines in reverse input order.\n"
"    -L  Follow symlinks. The line of a symlink is the line of the\n"
"        file it leads to: that file's inode, links, size, mdate and\n"
"        indicator, under the name given. A link that leads nowhere\n"
"        is listed as the link it is, with @.\n"
"    -Z  End each line with NUL instead of newline, and read the names\n"
"        on standard input, and the records of a -c listing, as ended\n"
"        by NUL, so a name may hold a newline. Names are written as\n"
"        they are, even to a terminal. It is the -Z of ff before cksh\n"
"        and the -z of srt after it.\n"
"    -o output\n"
"        Write the result to output and not to standard output. The\n"
"        result is written beside the destination, synced, given the\n"
"        mode the destination had (or the mode a new file would get),\n"
"        and renamed over it when the run is complete, so a failed or\n"
"        interrupted run leaves the original as it was, and output\n"
"        may be one of the files listed. A destination that exists\n"
"        and is not a regular file, a device or a fifo, is written to\n"
"        directly. A directory is refused.\n"
"    -c listing\n"
"        Check: read a saved listing and write the line of each file\n"
"        that no longer matches it. See CHECK. listing may be - for\n"
"        standard input. No file may be named with -c.\n"
"    --  End of options; the words that follow are files.\n"
"\n",
"    -h  Print a usage summary.\n"
"    --help\n"
"        Print this manual. When standard output is a terminal it is\n"
"        shown as a man page, with its headings in bold, through the\n"
"        formatter of the host: mandoc, else nroff with a pager\n"
"        (PAGER, else less, else more). Where neither is found the\n"
"        text is shown through the pager alone. To a pipe or a file\n"
"        it is written plain.\n"
"    --man\n"
"        Print the manual as man page source. cksh.1 is this output.\n"
"    -V, --version\n"
"        Print the revision.\n"
"    --fn, --bin\n"
"        Choose between the two forms of cksh, the binary and the bash\n"
"        function. --fn allows only the function: the function then\n"
"        never hands over to a binary, and the binary, given --fn,\n"
"        stops with an error. --bin allows only the binary: the\n"
"        function hands over to the binary on PATH and stops with an\n"
"        error if there is none; the binary accepts --bin and does\n"
"        nothing. See BASH FUNCTION.\n"
"\n"
"    The value of -n, -x and -k may be joined to its option (-n0,\n"
"    -x64, -k5,4) or be the next word. The next word is taken as the\n"
"    value only when it reads as one: digits for -n and -x, a column\n"
"    list for -k. Any other word leaves the option alone and is a\n"
"    file, so\n"
"        cksh -n *        cksh -x *        cksh -k *\n"
"    mean -n0, -x0 and sort by name. For a file named like a number,\n"
"    write ./5 or put -- before it. -o and -c always take a value,\n"
"    joined or the next word whatever it is. Options end at the first\n"
"    file.\n"
"\n"
"    Retired: -0 to -5 (write -n0 to -n5), and -krN (write -kNr).\n"
"\n",
"KEYS\n"
"\n"
"    -k [col[r][,col[r]]...]\n"
"        Sort by the named columns in the order given, then by the\n"
"        remaining columns left to right. -k5,4 compares in column\n"
"        order 5,4,1,2,3,6. -k5 -k4 is the same as -k5,4. Naming a\n"
"        column twice is an error. Columns are 1 to 6; counting from\n"
"        the end (-k-1) is not accepted.\n"
"\n"
"        -k with no list names no column, and sorts by name: column\n"
"        6, then 1 to 5.\n"
"\n"
"        cksh knows the type of each column. Inode, links, size and\n"
"        mdate compare as numbers, by value, whatever their width;\n"
"        the hash and the name compare as bytes, and no locale is\n"
"        consulted. The name is the last column and is compared to\n"
"        the end of the line. An omitted column, a dot, is a null\n"
"        column: it compares equal in every line, so a key on it\n"
"        orders nothing and the next column decides.\n"
"\n"
"        Records equal in every column keep their input order.\n"
"\n"
"    Letters. r after a column reverses that column. x is accepted\n"
"    on columns 1, 2, 4 and 5 and changes nothing: it is the letter\n"
"    srt needs there, so a list written for srt can be given to cksh.\n"
"    Any other letter is refused, since the types are fixed.\n"
"\n"
"    Reverse has two spellings. -k5r reverses column 5 alone. -r\n"
"    reverses every column that is written without a letter, named or\n"
"    not. As in srt, a letter on a column replaces -r for that column:\n"
"        cksh -k5r        newest first; within one second, ascending\n"
"        cksh -r -k5      newest first; within one second, descending\n"
"        cksh -r -k5x     column 5 ascending, the others descending\n"
"\n"
"    The same order from srt. cksh -k5,4,6 writes what\n"
"        cksh | srt -k5x,4x,6,1x,2x,3\n"
"    writes: every column named, each numeric column marked x. In\n"
"    general, give srt the cksh list, then the remaining columns, with\n"
"    x on 1, 2, 4 and 5.\n"
"\n",
"CHECK\n"
"\n"
"    cksh -c listing reads a listing that cksh wrote and examines\n"
"    again each file it names. A file that matches its record is\n"
"    passed over in silence. A file that differs is written as it is\n"
"    now, in the columns of its record, and the exit status carries\n"
"    64. So the output of a check is itself a listing, of what\n"
"    changed, and no output with status 0 means nothing did.\n"
"\n"
"    Each record is checked as it was made. Its dots say which\n"
"    columns were omitted, and those are not compared; the width of\n"
"    its hash says which shake256-N to compute, and a dot there means\n"
"    the file is not read. -n and -x are therefore not consulted, and\n"
"    a listing may mix records made in different ways. -L and -Z must\n"
"    be given again if the listing was made with them.\n"
"\n"
"    A record differs when any column it holds differs: the hash, the\n"
"    size, the mdate, and the inode and links if listed; or when the\n"
"    indicator differs, a file where a directory was. A file that is\n"
"    gone is an error, cannot stat, with status 4 and no line.\n"
"\n"
"    The file of a record is its name less the indicator. Where a\n"
"    name ends in one of / @ | = of its own, the file is the one that\n"
"    gives the record's name back. Between the last column and the\n"
"    name exactly one blank is skipped, so a name that begins with a\n"
"    blank is kept; a listing whose blanks were squeezed by another\n"
"    tool loses such names. A record of fewer than six words stops\n"
"    the run with status 1.\n"
"\n"
"    -k, -r and -o apply to what is written. To see what a record\n"
"    was beside what it is, join the two on the name, or diff the\n"
"    listing against a new one.\n"
"\n",
"HASH\n"
"\n"
"    Column 3 is SHAKE256 (FIPS 202) of the content, cut to N\n"
"    hexadecimal characters, and that hash is named shake256-N. The\n"
"    default is shake256-6; -x64 gives shake256-64. N is the width of\n"
"    the column, so length($3) names the hash of any listing.\n"
"\n"
"    SHAKE256 is an extendable-output function: a shorter output is\n"
"    the beginning of every longer one. The shake256-6 of a file is\n"
"    the first six characters of its shake256-64, and of the output of\n"
"        openssl shake256 -xoflen 32 -hex\n"
"    where -xoflen counts bytes, two characters each. An odd N is the\n"
"    even length above it, less the last character.\n"
"\n"
"    The name is written with a hyphen and never with a slash. A slash\n"
"    after SHAKE256 is read in three ways, and the default hash of\n"
"    cksh would be each of these to a different reader:\n"
"        SHAKE256/24    24 bits, as the standard counts output\n"
"        SHAKE256/3     3 bytes, as openssl -xoflen counts\n"
"        SHAKE256/6     6 hexadecimal characters\n"
"    Whichever one is written, readers of the other two misread it.\n"
"    cksh -x counts hexadecimal characters, and the hash is written\n"
"    shake256-6: one number for the option, the name and the column.\n"
"\n"
"    shake256-6 suits change and integrity checks among one's own\n"
"    files. Use -x64 or more where a collision must be infeasible.\n"
"\n"
"    The binary computes SHAKE256 itself and needs no other program.\n"
"\n"
"TERMINAL\n"
"\n"
"    When standard output is a terminal, C0 and C1 control characters,\n"
"    DEL, and bytes that are not valid UTF-8 are written in a name as\n"
"    \\ooo octal escapes, so a crafted name cannot drive the terminal.\n"
"    To a pipe or a file, and under -Z, names are written as they\n"
"    are. Names in diagnostics follow the same rule, by standard\n"
"    error.\n"
"\n",
"BASH FUNCTION\n"
"\n"
"    cksh.fn.bash defines a shell function named cksh, for hosts where\n"
"    the binary is not installed. When a binary named cksh is on PATH\n"
"    the function runs it, unless --fn is given; with --bin it runs\n"
"    the binary or stops with status 2. Sourcing the file defines that\n"
"    one name and nothing else.\n"
"\n"
"    The function takes the same options and writes the same bytes.\n"
"    Where it differs:\n"
"      - It hashes with openssl shake256, preferring\n"
"        $LOCALBASE/bin/openssl to the one on PATH, and checks it\n"
"        against the known hash of empty input. An openssl without\n"
"        -xoflen limits -x to 64; one without shake256 is status 2.\n"
"        -x0 needs no openssl.\n"
"      - It reads file data through stat(1), in the forms of Linux,\n"
"        Darwin and NetBSD. Elsewhere it stops with status 2.\n"
"      - With -k, where the sort of the host has no -z, a name\n"
"        containing a newline is status 2.\n"
"      - A NUL in a line of standard input is dropped, not reported.\n"
"      - -o is written beside the destination and renamed, but is not\n"
"        synced first; it needs mktemp(1).\n"
"      - Diagnostics omit the system's reason, and a node that changes\n"
"        during the scan is not detected.\n"
"      - It runs several programs per file and is much slower.\n"
"\n"
"ENVIRONMENT\n"
"\n"
"    PAGER      pager for --help.\n"
"    LOCALBASE  the bash function looks for openssl in $LOCALBASE/bin\n"
"               first.\n"
"    LANG and LC_* are not consulted.\n"
"\n"
"EXIT STATUS\n"
"\n"
"    A bitmask. 1 and 2 are fatal and are returned alone; the others\n"
"    accumulate while the run continues.\n"
"       0  success; with -c, every file matches its record\n"
"       1  invalid option or argument; nothing is read. Also a -c\n"
"          record that is not a cksh line\n"
"       2  environment: out of memory, or a failure of standard input\n"
"          or output, which can come in the middle of a run; a -c\n"
"          listing or -o output that cannot be opened; --bin with no\n"
"          binary; in the function, no usable openssl or stat\n"
"       4  cannot stat a name; line skipped\n"
"       8  cannot open or read a regular file; line skipped\n"
"      16  fifo, socket or device, never opened; or a node that\n"
"          changed during the scan; warned, hash zeros\n"
"      32  dangling symlink; warned, hash zeros\n"
"      64  with -c, a file differs from its record\n"
"    For example 52 is 4, 16 and 32: a missing name, a fifo and a\n"
"    dangling link.\n"
"\n"
"DIAGNOSTICS\n"
"\n"
"    On standard error, errors as '>>> cksh : ...' and warnings as\n"
"    '^^^ cksh : ...', each ending in a hexadecimal tag that names the\n"
"    message.\n"
"\n",
"EXAMPLES\n"
"\n"
"  Columns\n"
"\n"
"    cksh *                             hash, size, mdate, name\n"
"    cksh -n *                          every column, inode and links too\n"
"    cksh -n3 *                         size, mdate, name; nothing read\n"
"    cksh -n5 *                         names with their indicators\n"
"    find . -type f | cksh              names from standard input\n"
"    cksh -L *                          links as the files they lead to\n"
"\n"
"  Hash\n"
"\n"
"    cksh -x64 file                     shake256-64, the 256 bit hash\n"
"    cksh -x file                       no hash; the file is not read\n"
"    cksh -x64 -n file                  shake256-64 with inode and links\n"
"\n"
"  Sort\n"
"\n"
"    cksh -k *                          by name\n"
"    cksh -k5 *                         by time, oldest first\n"
"    cksh -k5r *                        newest first\n"
"    cksh -k5,4 *                       by time, then size, then the rest\n"
"    cksh -k4r,6 *                      largest first, then by name\n"
"    cksh -n3 -k4 *                     sizes, smallest first\n"
"    find . -type f | cksh -k3          files of the same content together\n"
"    cksh -r *                          the arguments in reverse order\n"
"    cksh -rk *                         by name, descending\n"
"\n"
"  Save and check\n"
"\n"
"    find . -type f | cksh -k -o tree.ck\n"
"                                       a listing, written whole or not\n"
"                                       at all\n"
"    cksh -c tree.ck                    the files that changed since;\n"
"                                       nothing, and status 0, if none\n"
"    cksh -c tree.ck -o changed.ck      the same, kept\n"
"    cksh -c tree.ck >/dev/null || echo changed\n"
"                                       as a test\n"
"    cksh -k -o list.ck * ; cksh -k -c list.ck\n"
"                                       a directory, list.ck among its\n"
"                                       own files\n"
"\n"
"  With other tools\n"
"\n"
"    ff . -t f | cksh -k5,4             files of a tree, by time and size\n"
"    cksh * | srt -k5x,4x,6,1x,2x,3     what cksh -k5,4,6 * writes\n"
"    find . -type f | cksh | srt -D -k3\n"
"                                       files whose hash repeats\n"
"    find a -type f | cksh -k > a.ck ; find b -type f | cksh -k > b.ck\n"
"                                       two trees, for diff or join\n"
"    ff -Z . -t f | cksh -Z | srt -z -k5x,4x\n"
"                                       NUL records end to end: any name\n"
"    find . -type f -print0 | cksh -Z -k | tr '\\0' '\\n'\n"
"                                       NUL in, sorted, lines out\n"
"\n"
"  Forms\n"
"\n"
"    cksh --bin -k5 *                   the binary, or an error\n"
"    cksh --fn -k5 *                    the bash function, even where the\n"
"                                       binary is installed\n"
"\n"
"NOTES\n"
"\n"
"    Names on standard input are read one per line, as they are:\n"
"    backslashes and blanks are kept, empty lines are skipped, and a\n"
"    name containing a newline can be given as an argument or, with\n"
"    -Z, on standard input. An empty argument is skipped.\n"
"\n"
"SEE ALSO\n"
"\n"
"    ff(1), srt(1)\n"
"\n"
"REVISION\n"
"\n"
"    r0.6.\n"
};

static void
manual(FILE *f)
{
	size_t i;

	for (i = 0; i < sizeof(MANUAL) / sizeof(MANUAL[0]); i++)
		(void)fputs(MANUAL[i], f);
}

/*
 * The manual as man page source. A line of capitals is a section (.SH);
 * a line indented by exactly two blanks is a sub-heading (.SS); all else
 * is kept as it stands, unfilled. The blank line after a heading is
 * dropped, since the macros space for themselves.
 */
static void
roff(FILE *f)
{
	size_t i, total = 0;
	char *buf, *l, *e;
	int n = 0, s = 0, b = 0;

	for (i = 0; i < sizeof(MANUAL) / sizeof(MANUAL[0]); i++)
		total += strlen(MANUAL[i]);
	buf = malloc(total + 1);
	if (buf == NULL)
		die(ST_ENV, "out of memory", NULL, "6ab7e738");
	buf[0] = '\0';
	for (i = 0; i < sizeof(MANUAL) / sizeof(MANUAL[0]); i++)
		strcat(buf, MANUAL[i]);
	(void)fputs(".TH CKSH 1\n", f);
	for (l = buf; *l; l = e + 1) {
		const char *p;
		int head;

		e = strchr(l, '\n');	/* every manual line ends in one */
		*e = '\0';
		head = *l >= 'A' && *l <= 'Z';
		for (p = l; head && *p; p++)
			head = (*p >= 'A' && *p <= 'Z') || *p == ' ';
		if (head) {
			b = 0;
			(void)fprintf(f, "%s.SH \"%s\"\n.nf\n", n++ ? ".fi\n" : "", l);
			s = 1;
			continue;
		}
		if (s) {
			s = 0;
			if (*l == '\0')
				continue;
		}
		if (*l == '\0') {
			b++;
			continue;
		}
		if (l[0] == ' ' && l[1] == ' ' && l[2] != ' ') {
			b = 0;
			(void)fprintf(f, ".SS \"%s\"\n.nf\n", l + 2);
			s = 1;
			continue;
		}
		for (; b > 0; b--)
			(void)putc('\n', f);
		if (*l == '.' || *l == '\'')
			(void)fputs("\\&", f);
		for (p = l; *p; p++)
			if (*p == '\\')
				(void)fputs("\\e", f);
			else
				(void)putc(*p, f);
		(void)putc('\n', f);
	}
	(void)fputs(".fi\n", f);
	free(buf);
}

static void
out_done(void)
{
	if (fflush(stdout) != 0 || ferror(stdout))
		die(ST_ENV, "write error on stdout", NULL, "6ab7e736");
}

/* feed text to a command line; 1 when it ran and ended with status 0 */
static int
feed(const char *cmd, void (*text)(FILE *))
{
	FILE *p;
	int st;

	(void)fflush(stdout);
	if (!(p = popen(cmd, "w")))
		return 0;
	text(p);
	st = pclose(p);
	return st != -1 && WIFEXITED(st) && WEXITSTATUS(st) == 0;
}

/*
 * --help. On a terminal: the man page source through the formatter of the
 * host, so headings come out bold as man(1) shows them; else the plain
 * text through a pager; else, and to anything but a terminal, plain. The
 * formatter is asked for by name and never through man(1), which on a
 * host without its pages can answer with a notice and status 0.
 */
static void
help(void)
{
	static const char *const fmt[] = {
		"command -v mandoc >/dev/null 2>&1 || exit 127;"
		" exec mandoc -a 2>/dev/null",
		"command -v nroff >/dev/null 2>&1 || exit 127;"
		" nroff -c -man </dev/null >/dev/null 2>&1 || exit 127;"
		" p=${PAGER:-}; [ -n \"$p\" ] || {"
		" command -v less >/dev/null 2>&1 && p=less || p=more; };"
		" nroff -c -man 2>/dev/null | sh -c \"$p\"",
	};
	const char *try[3];
	size_t i;

	try[0] = getenv("PAGER"); try[1] = "less"; try[2] = "more";
	if (isatty(STDOUT_FILENO)) {
		(void)signal(SIGPIPE, SIG_IGN);	/* reader may quit early */
		for (i = 0; i < sizeof(fmt) / sizeof(fmt[0]); i++)
			if (feed(fmt[i], roff))
				exit(0);
		for (i = 0; i < 3; i++) {
			FILE *p;
			int st;

			if (!try[i] || !try[i][0])
				continue;
			(void)fflush(stdout);
			if (!(p = popen(try[i], "w")))
				continue;
			manual(p);
			st = pclose(p);
			if (st != -1 && WIFEXITED(st) && WEXITSTATUS(st) != 127 &&
			    WEXITSTATUS(st) != 126)
				exit(0);
		}
	}
	manual(stdout);
	out_done();
	exit(0);
}

/* ---- options ----------------------------------------------------------- */

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
isdig(int c)
{
	return c >= '0' && c <= '9';
}

/*
 * Does the word after a bare option read as its value? Digits for -n
 * and -x. For -k, a column list in the widest sense srt gives it,
 * col[letters][,col[letters]]... with col a number or -number, so a
 * list that cksh refuses is still reported as a list and not opened
 * as a file.
 */
static int
reads_as(int c, const char *s)
{
	if (*s == '\0')
		return 0;
	if (c != 'k') {
		for (; *s; s++)
			if (!isdig(*s))
				return 0;
		return 1;
	}
	for (;;) {
		if (*s == '-')
			s++;
		if (!isdig(*s))
			return 0;
		while (isdig(*s))
			s++;
		while (*s && strchr("dfgHinrvx", *s))
			s++;
		if (*s == '\0')
			return 1;
		if (*s++ != ',')
			return 0;
	}
}

/* -k list: col[r|x...][,col...]; appends to kcol[], krev[] */
static void
parse_keys(const char *arg)
{
	const char *s = arg;
	int col, r, let, i;

	if (*s == 'r')
		die(ST_USAGE, "-krN is not accepted, write -kNr or -r -kN; got -k",
		    arg, "6af8d532");
	for (;;) {
		if (*s == '-')
			die(ST_USAGE, "-k counts columns 1-6 from the left only, got",
			    arg, "6af8d535");
		if (*s < '1' || *s > '6' || isdig(s[1]))
			die(ST_USAGE, "-k requires columns 1-6, got", arg, "6ab75460");
		col = *s++ - '0';
		r = let = 0;
		for (; *s && *s != ','; s++) {
			let = 1;
			if (*s == 'r')
				r = 1;
			else if (*s == 'x' && (col == 3 || col == 6))
				die(ST_USAGE, "-k letter x is for the numeric columns"
				    " 1 2 4 5; columns 3 and 6 are text, got",
				    arg, "6af8d537");
			else if (*s != 'x')
				die(ST_USAGE, "-k accepts the letters r and x only:"
				    " column types are fixed, got", arg, "6af8d533");
		}
		for (i = 0; i < nk; i++)
			if (kcol[i] == col)
				die(ST_USAGE, "-k names a column twice, got",
				    arg, "6af8d534");
		kcol[nk] = col;
		krev[nk++] = r;
		klet[col] = let;
		if (*s == '\0')
			return;
		s++;	/* the comma */
		if (*s == '\0')
			die(ST_USAGE, "-k requires columns 1-6, got", arg, "6ab75460");
	}
}

/* returns the index of the first file operand */
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
				help();
			if (strcmp(w, "--man") == 0) {
				roff(stdout);
				out_done();
				exit(0);
			}
			if (strcmp(w, "--version") == 0) {
				(void)puts(CKSH_REV);
				out_done();
				exit(0);
			}
			if (strcmp(w, "--bin") == 0)
				continue;	/* this is the binary */
			if (strcmp(w, "--fn") == 0)
				die(ST_USAGE, "--fn allows only the bash function"
				    " (cksh.fn.bash); this is the binary", NULL,
				    "6af8d536");
			die(ST_USAGE, "invalid option", w, "6ab75461");
		}
		for (p = w + 1; *p; p++) {
			char c = *p, o[3];
			const char *arg;

			o[0] = '-'; o[1] = c; o[2] = '\0';
			if (c == 'r') { opt_r = 1; continue; }
			if (c == 'Z') { opt_z = 1; continue; }
			if (c == 'L') { opt_L = 1; continue; }
			if (c == 'h') {
				xwrite(USAGE, sizeof(USAGE) - 1);
				out_done();
				exit(0);
			}
			if (c == 'V') {
				(void)puts(CKSH_REV);
				out_done();
				exit(0);
			}
			if (c >= '0' && c <= '5')
				die(ST_USAGE, "-0 to -5 are retired, write -n0 to -n5;"
				    " got", o, "6af8d531");
			if (!strchr("nxkoc", c))
				die(ST_USAGE, "invalid option", o, "68e9fa9a");
			if (p[1] != '\0')
				arg = p + 1;
			else if (i + 1 < argc && (c == 'o' || c == 'c' ||
			    reads_as(c, argv[i + 1])))
				arg = argv[++i];
			else
				arg = NULL;	/* bare */
			if (c == 'n') {
				v = arg ? num(arg, 0, 5) : 0;
				if (v < 0)
					die(ST_USAGE, "-n requires 0-5, got", arg, "68e9fbb2");
				opt_n = v;
			} else if (c == 'x') {
				v = arg ? num(arg, 0, XHEX) : 0;
				if (v < 0)
					die(ST_USAGE, "-x requires 0-128, got", arg, "68e9fc22");
				opt_x = v;
			} else if (c == 'k') {
				opt_k = 1;
				if (arg)
					parse_keys(arg);
			} else {
				if (arg == NULL || *arg == '\0')
					die(ST_USAGE, c == 'o' ?
					    "-o requires an output file" :
					    "-c requires a listing", NULL, "6af8d53c");
				if (c == 'o')
					opt_o = arg;
				else
					opt_c = arg;
			}
			break;	/* the value took the rest of the word */
		}
	}
	return i;
}

int
main(int argc, char **argv)
{
	int i, j;

	if (argc > 0 && argv[0] && *argv[0]) {
		const char *b = strrchr(argv[0], '/');
		prog = b ? b + 1 : argv[0];
	}
	esc_err = isatty(STDERR_FILENO);
	i = parse(argc, argv);
	if (opt_c && i < argc)
		die(ST_USAGE, "-c takes its names from the listing; no file may"
		    " be named, got", argv[i], "6af8d53f");
	if (opt_o)
		out_open(opt_o);
	esc_out = !opt_z && isatty(STDOUT_FILENO);	/* -Z: names as they are */
	if (opt_n > 2)
		opt_x = 0;	/* hash column omitted, do not read files */
	for (j = 1; j <= 5; j++)
		if (j > opt_n && (j != 3 || opt_x > 0))
			have |= HAVE(j);

	if (opt_c) {
		check(opt_c);
	} else if (i < argc) {
		for (; i < argc; i++)
			if (argv[i][0] != '\0')
				do_file(argv[i]);
	} else {
		int delim = opt_z ? '\0' : '\n';
		char *ln = NULL;
		size_t cap = 0;
		ssize_t len;

		while ((len = getdelim(&ln, &cap, delim, stdin)) != -1) {
			if (len > 0 && ln[len - 1] == delim)
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
	out_commit();
	if (fclose(stdout) != 0)
		die(ST_ENV, "write error on stdout", NULL, "6ab7e736");
	return status;
}
