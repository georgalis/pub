/*
 * ff.c --- functional find: NetBSD find(1) semantics, one letter per switch
 * (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 *
 * org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
 *     owned openat walker, one-letter grammar, -x/-j/-delete, getent ids,
 *     tty escaping, status bitmask, chkerr/chkwrn diagnostics; companion
 *     ff.fn.bash translates to the native find; model cksh
 *
 * Dependency posture: none beyond libc. On Linux, -u and -g names resolve
 * through getent(1) at a fixed path, never getpwnam(3): a static glibc
 * binary cannot load NSS modules reliably, and /etc/passwd alone is not the
 * user database under LDAP, sssd or systemd-homed. No getent is an error.
 * The directory walker is owned rather
 * than fts(3): musl ships no fts, and here every directory is opened with
 * openat(2) relative to its parent's descriptor and verified by dev/ino
 * against the stat taken while listing, so no path is re-resolved after it
 * was checked. -x (execdir) and -delete act through that verified parent
 * descriptor for the same reason. Static on Linux and NetBSD; Darwin links
 * libSystem only.
 *
 * Deliberate departures from find: -r is unanchored; -s counts bytes with
 * exact comparison; time primaries compare age in seconds; -d is a global
 * walk bound; {} substitutes only as a whole argument; names printed to a
 * terminal have control bytes escaped. See --help, DIFFERENCES.
 */

/* each enables FNM_CASEFOLD, statx or st_birthtime on its own platform */
#define _GNU_SOURCE		/* glibc, musl */
#define _DARWIN_C_SOURCE	/* Darwin */
#define _NETBSD_SOURCE		/* NetBSD */

#include <sys/types.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <fnmatch.h>
#if !defined(__linux__)
#include <grp.h>
#endif
#include <inttypes.h>
#include <limits.h>
#if !defined(__linux__)
#include <pwd.h>
#endif
#include <regex.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/* exit status bits; 1 and 2 are fatal, the rest accumulate */
#define ST_USAGE  1	/* invalid option or expression */
#define ST_ENV    2	/* memory, stdout, fork/pipe, unsafe PATH for -x */
#define ST_NODE   4	/* cannot stat, open, read or delete a node */
#define ST_EXEC   8	/* exec failed, or a + batch exited nonzero */
#define ST_LOOP  16	/* filesystem or symlink loop */
#define ST_RACE  32	/* node changed between listing and opening */

#define FDCAP 64	/* most directory descriptors held open at once */

#ifndef FNM_CASEFOLD
#error "fnmatch lacks FNM_CASEFOLD; -I needs it"
#endif

#if defined(__APPLE__)
#define MTIM(s) ((s)->st_mtimespec)
#else
#define MTIM(s) ((s)->st_mtim)
#endif

static const char *prog = "ff";
static int status;

/* options */
static int opt_E, opt_I, opt_H, opt_L, opt_D, opt_S, opt_X, opt_0;
static long mindepth = 0, maxdepth = LONG_MAX;

static time_t now;
static int esc_out, esc_err;	/* escape names: stdout/stderr is a tty */
static int quitting, need_stat;

/* ---------------------------------------------------------------- output */

/* bytes of one printable UTF-8 sequence at p, 0 when *p must be escaped */
static size_t
u8len(const unsigned char *p, const unsigned char *e)
{
	unsigned c = *p;
	unsigned long cp;
	size_t n, i;

	if (c >= 0x20 && c < 0x7f)
		return 1;
	if (c < 0xc2 || c > 0xf4)	/* C0, DEL, stray continuation, overlong */
		return 0;
	n = c < 0xe0 ? 2 : c < 0xf0 ? 3 : 4;
	if ((size_t)(e - p) < n)
		return 0;
	cp = c & (0x3fu >> (n - 1));
	for (i = 1; i < n; i++) {
		if ((p[i] & 0xc0) != 0x80)
			return 0;
		cp = cp << 6 | (p[i] & 0x3f);
	}
	if ((n == 3 && cp < 0x800) || (n == 4 && cp < 0x10000) ||
	    cp > 0x10ffff || (cp >= 0xd800 && cp <= 0xdfff) ||
	    (cp >= 0x80 && cp <= 0x9f))	/* C1 controls: CSI is 0x9b */
		return 0;
	return n;
}

/* a name, raw or with unsafe bytes as \ooo */
static void
putname(FILE *f, const char *s, int esc)
{
	const unsigned char *p = (const unsigned char *)s, *e;
	size_t n;

	if (!esc) {
		(void)fputs(s, f);
		return;
	}
	for (e = p + strlen(s); p < e; p += n)
		if ((n = u8len(p, e)) != 0)
			(void)fwrite(p, 1, n, f);
		else {
			(void)fprintf(f, "\\%03o", *p);
			n = 1;
		}
}

/*
 * Diagnostics, formatted as the shell chkerr (">>> ") and chkwrn ("^^^ ")
 * functions: "ff : what 'name'[: why] (tag)". The hex tag names the message;
 * usage messages and tags are identical in ff.fn.bash.
 */
static void
msg(const char *lvl, const char *what, const char *name, const char *why,
    const char *tag)
{
	/* stderr failure has nowhere else to go */
	(void)fprintf(stderr, "%s%s : %s", lvl, prog, what);
	if (name) {
		(void)fputs(" '", stderr);
		putname(stderr, name, esc_err);
		(void)fputc('\'', stderr);
	}
	if (why)
		(void)fprintf(stderr, ": %s", why);
	(void)fprintf(stderr, " (%s)\n", tag);
}
#define ERR(w, n, y, t) msg(">>> ", (w), (n), (y), (t))
#define WRN(w, n, y, t) msg("^^^ ", (w), (n), (y), (t))

static void
die(int st, const char *what, const char *name, const char *why, const char *tag)
{
	ERR(what, name, why, tag);
	exit(st);
}

/* usage error: status 1 before any walk */
static void
bad(const char *what, const char *arg, const char *tag)
{
	ERR(what, arg, NULL, tag);
	exit(ST_USAGE);
}

static void *
xrealloc(void *p, size_t n)
{
	if ((p = realloc(p, n ? n : 1)) == NULL)
		die(ST_ENV, "out of memory", NULL, NULL, "6ab7ff20");
	return p;
}

static char *
xstrdup(const char *s)
{
	size_t n = strlen(s) + 1;

	return memcpy(xrealloc(NULL, n), s, n);
}

static void
xflush(void)
{
	if (fflush(stdout) == EOF || ferror(stdout))
		die(ST_ENV, "write error on stdout", NULL, strerror(errno), "6ab7ff21");
}

/* ------------------------------------------------------------ expression */

enum {
	N_TRUE, N_AND, N_OR, N_NOT,
	N_NAME, N_PATH, N_REGEX, N_TYPE, N_SIZE, N_TIME, N_NEWER, N_PERM,
	N_USER, N_GROUP, N_EMPTY, N_LINKS, N_INUM, N_PRUNE,
	N_PRINT, N_LS, N_EXEC, N_EXECDIR, N_DELETE, N_QUIT
};

struct batch {			/* pending {} + arguments */
	char **v;
	size_t n, cap, bytes;
	size_t level;		/* -x: directory level the names live in */
	unsigned long gen;	/* -x: that level's generation */
};

struct node {
	int type, l, r;
	int cmp;		/* '+', '-' or 0 */
	uintmax_t num, unit;	/* compared value; time unit in seconds */
	int tsel;		/* time: 'm' 'a' 'c' 'b' */
	unsigned tmask;		/* type letters */
	mode_t mode;
	const char *pat;
	regex_t re;
	struct timespec ref;
	char **argv;		/* exec template, argc words */
	int argc, plus;
	struct batch b;
};

static struct node *nd;
static int nnd;
static char **tok;		/* expression tokens */
static int ntok, ti;
static int root = -1;
static size_t argmax;		/* bytes for one exec argument list */

static int
mk(int type, int l, int r)
{
	nd = xrealloc(nd, (size_t)(nnd + 1) * sizeof *nd);
	memset(&nd[nnd], 0, sizeof *nd);
	nd[nnd].type = type;
	nd[nnd].l = l;
	nd[nnd].r = r;
	return nnd++;
}

/* [+-]digits: sign to *cmp, value to *v; pointer past the digits or NULL */
static const char *
num(const char *s, int *cmp, uintmax_t *v)
{
	uintmax_t x = 0;

	*cmp = 0;
	if (*s == '+' || *s == '-')
		*cmp = *s++;
	if (*s < '0' || *s > '9')
		return NULL;
	for (; *s >= '0' && *s <= '9'; s++) {
		if (x > (UINTMAX_MAX - (uintmax_t)(*s - '0')) / 10)
			return NULL;
		x = x * 10 + (uintmax_t)(*s - '0');
	}
	*v = x;
	return s;
}

/* unit suffix: at most one character from units, else error */
static uintmax_t
suffix(const char *p, const char *units, const uintmax_t *mult,
    uintmax_t dflt, const char *what, const char *arg, const char *tag)
{
	const char *u = NULL;

	if (*p == '\0')
		return dflt;
	if (p[1] != '\0' || (u = strchr(units, *p)) == NULL)
		bad(what, arg, tag);
	return mult[u - units];
}

static uintmax_t
mul(uintmax_t a, uintmax_t b, const char *what, const char *arg, const char *tag)
{
	if (b && a > UINTMAX_MAX / b)
		bad(what, arg, tag);
	return a * b;
}

/* octal, or symbolic [ugoa]*[-+=][rwxst]* clauses joined by commas */
static mode_t
parse_mode(const char *s, const char *arg)
{
	unsigned long m = 0, who, bits, all = 07777;
	const char *p;
	char op;

	if (*s >= '0' && *s <= '7') {
		for (p = s; *p >= '0' && *p <= '7' && p - s < 4; p++)
			m = m << 3 | (unsigned long)(*p - '0');
		if (*p != '\0')
			bad("-k: bad mode", arg, "6ab7ff11");
		return (mode_t)m;
	}
	for (p = s;;) {
		for (who = 0; *p && strchr("ugoa", *p); p++)
			who |= *p == 'u' ? 04700 : *p == 'g' ? 02070 :
			    *p == 'o' ? 01007 : 07777;
		if (who == 0)
			who = 07777;
		if (*p != '+' && *p != '-' && *p != '=')
			bad("-k: bad mode", arg, "6ab7ff11");
		op = *p++;
		for (bits = 0; *p && strchr("rwxst", *p); p++)
			bits |= *p == 'r' ? 0444 : *p == 'w' ? 0222 :
			    *p == 'x' ? 0111 : *p == 's' ? 06000 : 01000;
		bits &= who & all;
		if (op == '=')
			m &= ~(who & all);
		m = op == '-' ? m & ~bits : m | bits;
		if (*p == '\0')
			break;
		if (*p++ != ',' || *p == '\0')
			bad("-k: bad mode", arg, "6ab7ff11");
	}
	return (mode_t)m;
}

#if defined(__linux__)
/* id field of "getent passwd|group name": name:pw:id:... ; the host's own
 * dynamically linked getent consults NSS as configured, which this binary
 * may not. Exit 2 from getent is "no such key". */
static uintmax_t
getent_id(const char *db, const char *s, const char *what, const char *tag)
{
	static const char *const bin[] = { "/usr/bin/getent", "/bin/getent" };
	char buf[4096], *p, *av[5];
	const char *q;
	size_t n = 0, i, len = strlen(s);
	int pfd[2], st, cmp;
	uintmax_t v = 0;
	ssize_t r;
	pid_t pid;

	for (i = 0; i < sizeof bin / sizeof *bin && access(bin[i], X_OK); i++)
		;
	if (i == sizeof bin / sizeof *bin)
		die(ST_ENV, "no getent to resolve names, use a numeric id", s, NULL, "6ab7ff22");
	av[0] = (char *)"getent";
	av[1] = (char *)db;
	av[2] = (char *)"--";
	av[3] = (char *)s;
	av[4] = NULL;
	xflush();
	if (pipe(pfd) == -1)
		die(ST_ENV, "pipe", NULL, strerror(errno), "6ab7ff23");
	if ((pid = fork()) == -1)
		die(ST_ENV, "fork", NULL, strerror(errno), "6ab7ff24");
	if (pid == 0) {
		int nul = open("/dev/null", O_RDWR);

		(void)close(pfd[0]);
		if (dup2(pfd[1], 1) == -1 || (nul >= 0 && dup2(nul, 2) == -1))
			_exit(127);
		(void)execv(bin[i], av);
		_exit(127);
	}
	(void)close(pfd[1]);
	while (n < sizeof buf - 1 &&
	    ((r = read(pfd[0], buf + n, sizeof buf - 1 - n)) > 0 ||
	    (r == -1 && errno == EINTR)))
		n += r > 0 ? (size_t)r : 0;
	(void)close(pfd[0]);
	while (waitpid(pid, &st, 0) == -1)
		if (errno != EINTR)
			die(ST_ENV, "waitpid", NULL, strerror(errno), "6ab7ff25");
	buf[n] = '\0';
	if (WIFEXITED(st) && WEXITSTATUS(st) == 2)
		bad(what, s, tag);
	if (!WIFEXITED(st) || WEXITSTATUS(st) != 0)
		die(ST_ENV, "getent failed resolving", s, NULL, "6ab7ff26");
	/* first line must name s exactly, then two fields to the id */
	if (strncmp(buf, s, len) || buf[len] != ':' ||
	    (p = strchr(buf + len + 1, ':')) == NULL ||
	    (q = num(p + 1, &cmp, &v)) == NULL || cmp || *q != ':')
		die(ST_ENV, "unexpected getent output for", s, NULL, "6ab7ff27");
	return v;
}
#endif

static uintmax_t
parse_id(const char *s, int user)
{
	uintmax_t v;
	const char *p;
	int cmp;

	if ((p = num(s, &cmp, &v)) != NULL && *p == '\0' && cmp == 0)
		;
	else if (*s == '\0' || *s == '-' || strpbrk(s, ":\n"))
		bad(user ? "-u: no such user" : "-g: no such group", s,
		    user ? "6ab7ff12" : "6ab7ff13");
	else {
#if defined(__linux__)
		v = getent_id(user ? "passwd" : "group", s,
		    user ? "-u: no such user" : "-g: no such group",
		    user ? "6ab7ff12" : "6ab7ff13");
#else
		struct passwd *pw;
		struct group *gr;

		if (user) {
			if ((pw = getpwnam(s)) == NULL)
				bad("-u: no such user", s, "6ab7ff12");
			v = pw->pw_uid;
		} else {
			if ((gr = getgrnam(s)) == NULL)
				bad("-g: no such group", s, "6ab7ff13");
			v = gr->gr_gid;
		}
#endif
	}
	if (v > (user ? (uintmax_t)(uid_t)-1 : (uintmax_t)(gid_t)-1))
		bad(user ? "-u: id out of range" : "-g: id out of range", s,
		    user ? "6ab7ff14" : "6ab7ff15");
	return v;
}

static int
is_prim(const char *s, const char *list)
{
	char k[3] = { 0, 0, 0 };

	if (s[0] != '-' || s[1] == '\0' || s[2] != '\0')
		return 0;
	k[0] = s[1];
	return strstr(list, k) != NULL;
}

#define P_ARG  "nprtdsmacbwkugli"	/* primaries taking one argument */
#define P_NONE "ezfvq"			/* primaries taking none */
#define P_EXEC "xj"			/* primaries taking cmd ... ; or + */

static int
is_exprtok(const char *s)
{
	return !strcmp(s, "!") || !strcmp(s, "(") || !strcmp(s, ")") ||
	    !strcmp(s, "-o") || !strcmp(s, "-delete") || is_prim(s, P_ARG) ||
	    is_prim(s, P_NONE) || is_prim(s, P_EXEC);
}

static int parse_or(void);

static const char *
arg1(void)
{
	return tok[ti++];	/* presence checked by the pre-pass */
}

static int
primary(void)
{
	static const uintmax_t szm[] = { 1, 1024, 1024, 1048576, 1048576,
	    1073741824, 1073741824, 1099511627776ULL, 1099511627776ULL };
	static const uintmax_t tm[] = { 1, 60, 3600, 86400, 604800 };
	const char *t = tok[ti++], *a, *p;
	struct stat sb;
	uintmax_t v;
	int n, cmp, i, fl;

	if (!strcmp(t, "-delete")) {
		opt_D = 1;
		return mk(N_DELETE, -1, -1);
	}
	switch (t[1]) {
	case 'n': case 'p':
		n = mk(t[1] == 'n' ? N_NAME : N_PATH, -1, -1);
		nd[n].pat = arg1();
		return n;
	case 'r':
		n = mk(N_REGEX, -1, -1);
		a = arg1();
		fl = REG_NOSUB | (opt_E ? REG_EXTENDED : 0) | (opt_I ? REG_ICASE : 0);
		if ((i = regcomp(&nd[n].re, a, fl)) != 0) {
			char m[128];

			(void)regerror(i, &nd[n].re, m, sizeof m);
			ERR("-r: bad regular expression", a, m, "6ab7ff09");
			exit(ST_USAGE);
		}
		return n;
	case 't':
		n = mk(N_TYPE, -1, -1);
		for (a = p = arg1(); *p; p++) {
			const char *q = strchr("fdlpsbc", *p);

			if (q == NULL)
				bad("-t: types are f d l p s b c", a, "6ab7ff0a");
			nd[n].tmask |= 1u << (q - "fdlpsbc");
		}
		if (*a == '\0')
			bad("-t: types are f d l p s b c", a, "6ab7ff0a");
		return n;
	case 'd': {
		long lo, hi;

		a = arg1();
		if ((p = num(a, &cmp, &v)) == NULL || *p || v > LONG_MAX - 1)
			bad("-d: depth is [+-]N", a, "6ab7ff0b");
		lo = cmp == '+' ? (long)v + 1 : cmp == '-' ? 0 : (long)v;
		hi = cmp == '-' ? (long)v - 1 : cmp == '+' ? LONG_MAX : (long)v;
		if (lo > mindepth)
			mindepth = lo;
		if (hi < maxdepth)
			maxdepth = hi;
		return mk(N_TRUE, -1, -1);
	}
	case 's':
		n = mk(N_SIZE, -1, -1);
		a = arg1();
		if ((p = num(a, &nd[n].cmp, &v)) == NULL)
			bad("-s: size is [+-]N[ckMGT]", a, "6ab7ff0c");
		nd[n].num = mul(v, suffix(p, "ckKmMgGtT", szm, 1,
		    "-s: size is [+-]N[ckMGT]", a, "6ab7ff0c"),
		    "-s: size overflows", a, "6ab7ff0d");
		need_stat = 1;
		return n;
	case 'm': case 'a': case 'c': case 'b':
		n = mk(N_TIME, -1, -1);
		nd[n].tsel = t[1];
		a = arg1();
		if ((p = num(a, &nd[n].cmp, &v)) == NULL)
			bad("time is [+-]N[smhdw]", a, "6ab7ff0e");
		nd[n].unit = suffix(p, "smhdw", tm, 86400,
		    "time is [+-]N[smhdw]", a, "6ab7ff0e");
		nd[n].num = v;
		(void)mul(v, nd[n].unit, "time overflows", a, "6ab7ff0f");
		if (v * nd[n].unit > (uintmax_t)INTMAX_MAX)
			bad("time overflows", a, "6ab7ff0f");
		need_stat = 1;
		return n;
	case 'w':
		n = mk(N_NEWER, -1, -1);
		a = arg1();
		if ((opt_H || opt_L ? stat(a, &sb) : lstat(a, &sb)) == -1)
			bad("-w: cannot stat", a, "6ab7ff10");
		nd[n].ref = MTIM(&sb);
		need_stat = 1;
		return n;
	case 'k':
		n = mk(N_PERM, -1, -1);
		a = arg1();
		nd[n].cmp = (*a == '-' || *a == '+') ? *a : 0;
		nd[n].mode = parse_mode(a + (nd[n].cmp != 0), a);
		need_stat = 1;
		return n;
	case 'u': case 'g':
		n = mk(t[1] == 'u' ? N_USER : N_GROUP, -1, -1);
		nd[n].num = parse_id(arg1(), t[1] == 'u');
		need_stat = 1;
		return n;
	case 'l': case 'i':
		n = mk(t[1] == 'l' ? N_LINKS : N_INUM, -1, -1);
		a = arg1();
		if ((p = num(a, &nd[n].cmp, &nd[n].num)) == NULL || *p)
			bad(t[1] == 'l' ? "-l: links is [+-]N" : "-i: inode is [+-]N", a,
			    t[1] == 'l' ? "6ab7ff16" : "6ab7ff17");
		need_stat = 1;
		return n;
	case 'e':
		need_stat = 1;
		return mk(N_EMPTY, -1, -1);
	case 'z':
		return mk(N_PRUNE, -1, -1);
	case 'f':
		return mk(N_PRINT, -1, -1);
	case 'v':
		need_stat = 1;
		return mk(N_LS, -1, -1);
	case 'q':
		return mk(N_QUIT, -1, -1);
	case 'x': case 'j':
		n = mk(t[1] == 'x' ? N_EXECDIR : N_EXEC, -1, -1);
		nd[n].argv = &tok[ti];
		while (strcmp(tok[ti], ";") &&
		    !(!strcmp(tok[ti], "+") && !strcmp(tok[ti - 1], "{}")))
			ti++;
		nd[n].argc = (int)(&tok[ti] - nd[n].argv);
		nd[n].plus = tok[ti++][0] == '+';
		if (nd[n].argc == 0 || (nd[n].plus && nd[n].argc == 1))
			bad("missing command after", t, "6ab7ff18");
		for (i = 0; i < nd[n].argc; i++) {
			if (strstr(nd[n].argv[i], "{}") && strcmp(nd[n].argv[i], "{}"))
				bad("{} must be a whole argument", nd[n].argv[i], "6ab7ff19");
			if (nd[n].plus && i < nd[n].argc - 1 &&
			    !strcmp(nd[n].argv[i], "{}"))
				bad("with +, {} may appear only once, last", t, "6ab7ff1a");
			if (i == 0 && !strcmp(nd[n].argv[i], "{}"))
				bad("{} cannot be the command", t, "6ab7ff1b");
		}
		if (t[1] == 'x' && strchr(nd[n].argv[0], '/') && nd[n].argv[0][0] != '/')
			bad("-x: command must be absolute or found in PATH", nd[n].argv[0], "6ab7ff1c");
		return n;
	}
	bad("unknown primary", t, "6ab7ff03");
	return -1;
}

static int
parse_not(void)
{
	int n;

	if (ti >= ntok)
		bad("expression ends early", ntok ? tok[ntok - 1] : NULL, "6ab7ff06");
	if (!strcmp(tok[ti], "!")) {
		ti++;
		n = parse_not();
		return mk(N_NOT, n, -1);
	}
	if (!strcmp(tok[ti], "(")) {
		ti++;
		if (ti < ntok && !strcmp(tok[ti], ")"))
			bad("empty ( )", NULL, "6ab7ff07");
		n = parse_or();
		if (ti >= ntok || strcmp(tok[ti], ")"))
			bad("missing )", NULL, "6ab7ff08");
		ti++;
		return n;
	}
	if (!strcmp(tok[ti], ")") || !strcmp(tok[ti], "-o"))
		bad("unexpected", tok[ti], "6ab7ff05");
	return primary();
}

static int
parse_and(void)
{
	int l = parse_not();

	while (ti < ntok && strcmp(tok[ti], "-o") && strcmp(tok[ti], ")"))
		l = mk(N_AND, l, parse_not());
	return l;
}

static int
parse_or(void)
{
	int l = parse_and();

	while (ti < ntok && !strcmp(tok[ti], "-o")) {
		ti++;
		l = mk(N_OR, l, parse_and());
	}
	return l;
}

/* -x runs commands in walked directories: a relative PATH element would
 * let a file planted there run instead */
static void
check_path(void)
{
	const char *p = getenv("PATH"), *q;

	if (p == NULL || *p == '\0')
		die(ST_ENV, "-x: PATH is empty", NULL, NULL, "6ab7ff28");
	for (;;) {
		q = strchr(p, ':');
		if (*p != '/')
			die(ST_ENV, "-x: refusing relative or empty PATH element", getenv("PATH"), NULL, "6ab7ff29");
		if (q == NULL)
			break;
		p = q + 1;
	}
}

/* ------------------------------------------------------------------ walk */

struct ent {
	const char *path;	/* as printed */
	const char *base;	/* last component */
	size_t depth;
	int dtype;		/* DT_* hint when st is not loaded */
	int have_st, prune;
	struct stat st;
};

struct level {			/* one open directory of the walk */
	char *name;		/* component; the operand path at level 0 */
	dev_t dev;
	ino_t ino;
	int fd, follow;
	unsigned long gen;
};

static struct level *lv;
static size_t nlv, caplv;
static int nopen, fdcap = FDCAP;	/* fdcap shrinks under a low RLIMIT_NOFILE */
static unsigned long gens;
static dev_t rootdev;

static char *pb;		/* path buffer */
static size_t pblen, pbcap;

/* close the shallowest held descriptors, never levels keep-1 and keep */
static void
trim(size_t keep)
{
	size_t i;

	for (i = 0; nopen > fdcap && i + 1 < keep; i++)
		if (lv[i].fd >= 0) {
			(void)close(lv[i].fd);
			lv[i].fd = -1;
			nopen--;
		}
}

/* descriptor for level d, reopened from the nearest held ancestor and
 * verified by dev/ino: a directory renamed or swapped for a symlink since
 * it was listed is refused, not followed */
static int
ensure_fd(size_t d, const char *shown)
{
	struct level *L = &lv[d];
	struct stat sb;
	int pfd, fd;

	if (L->fd >= 0)
		return L->fd;
	pfd = d ? ensure_fd(d - 1, NULL) : AT_FDCWD;
	if (d && pfd < 0)
		return -1;
	L = &lv[d];
	if (shown == NULL)
		shown = L->name;
	fd = openat(pfd, L->name, O_RDONLY | O_DIRECTORY | O_CLOEXEC |
	    (L->follow ? 0 : O_NOFOLLOW));
	if (fd == -1) {
		ERR("cannot open", shown, strerror(errno), "6ab7ff30");
		status |= errno == ELOOP || errno == ENOTDIR ? ST_RACE : ST_NODE;
		return -1;
	}
	if (fstat(fd, &sb) == -1 || sb.st_dev != L->dev || sb.st_ino != L->ino) {
		(void)close(fd);
		ERR("changed during walk, skipped", shown, NULL, "6ab7ff31");
		status |= ST_RACE;
		return -1;
	}
	L->fd = fd;
	nopen++;
	trim(d);
	return fd;
}

/* stat an entry by the symlink policy; -1 after warning */
static int
load(struct ent *e)
{
	int follow = opt_L || (opt_H && e->depth == 0);
	int pfd = e->depth ? ensure_fd(e->depth - 1, NULL) : AT_FDCWD;
	const char *nm = e->depth ? e->base : e->path;

	if (e->have_st)
		return 0;
	if (pfd < 0 && e->depth)
		return -1;
	if (fstatat(pfd, nm, &e->st, follow ? 0 : AT_SYMLINK_NOFOLLOW) == -1) {
		int err = errno;

		if (!follow ||
		    fstatat(pfd, nm, &e->st, AT_SYMLINK_NOFOLLOW) == -1) {
			ERR("cannot stat", e->path, strerror(err), "6ab7ff32");
			status |= ST_NODE;
			return -1;
		}
		if (err == ELOOP) {	/* dangling is fine, a loop is reported */
			WRN("symlink loop", e->path, strerror(err), "6ab7ff33");
			status |= ST_LOOP;
		}
	}
	e->have_st = 1;
	return 0;
}

static int
etype(const struct ent *e)
{
	mode_t m = e->st.st_mode;

	if (!e->have_st)
		switch (e->dtype) {
		case DT_REG: return 'f';
		case DT_DIR: return 'd';
		case DT_LNK: return 'l';
		case DT_FIFO: return 'p';
		case DT_SOCK: return 's';
		case DT_BLK: return 'b';
		case DT_CHR: return 'c';
		default: return '?';
		}
	return S_ISREG(m) ? 'f' : S_ISDIR(m) ? 'd' : S_ISLNK(m) ? 'l' :
	    S_ISFIFO(m) ? 'p' : S_ISSOCK(m) ? 's' : S_ISBLK(m) ? 'b' :
	    S_ISCHR(m) ? 'c' : '?';
}

/* dirname and ./basename of an operand, for -x at depth 0 */
static void
split_operand(const char *path, char **dir, char **arg)
{
	char *d = xstrdup(path), *s;
	size_t n = strlen(d);

	while (n > 1 && d[n - 1] == '/')
		d[--n] = '\0';
	s = strrchr(d, '/');
	if (s == NULL || !strcmp(d, "/")) {
		*arg = xrealloc(NULL, n + 3);
		(void)snprintf(*arg, n + 3, "%s%s", strcmp(d, "/") ? "./" : "", d);
		free(d);
		*dir = xstrdup(s ? "/" : ".");
		return;
	}
	*arg = xrealloc(NULL, strlen(s + 1) + 3);
	(void)snprintf(*arg, strlen(s + 1) + 3, "./%s", s + 1);
	if (s == d)
		s[1] = '\0';
	else
		*s = '\0';
	*dir = d;
}

/* ------------------------------------------------------------------ exec */

/* fork and exec av; child enters dirfd or dir first. Returns the wait
 * status, or -1 when the command could not be run (reported here) */
static int
run(char *const *av, int dirfd, const char *dir)
{
	int pfd[2], st, err = 0;
	ssize_t r;
	pid_t pid;

	xflush();
	if (pipe(pfd) == -1)
		die(ST_ENV, "pipe", NULL, strerror(errno), "6ab7ff23");
	(void)fcntl(pfd[1], F_SETFD, FD_CLOEXEC);
	if ((pid = fork()) == -1)
		die(ST_ENV, "fork", NULL, strerror(errno), "6ab7ff24");
	if (pid == 0) {
		(void)close(pfd[0]);
		if ((dirfd >= 0 && fchdir(dirfd) == -1) ||
		    (dir && chdir(dir) == -1)) {
			err = errno;
			r = write(pfd[1], &err, sizeof err);
			_exit(126 + (int)(r & 0));
		}
		(void)execvp(av[0], av);
		err = errno;
		r = write(pfd[1], &err, sizeof err);
		_exit(127 + (int)(r & 0));
	}
	(void)close(pfd[1]);
	while ((r = read(pfd[0], &err, sizeof err)) == -1 && errno == EINTR)
		;
	(void)close(pfd[0]);
	while (waitpid(pid, &st, 0) == -1)
		if (errno != EINTR)
			die(ST_ENV, "waitpid", NULL, strerror(errno), "6ab7ff25");
	if (r == (ssize_t)sizeof err) {
		ERR("cannot execute", av[0], strerror(err), "6ab7ff34");
		status |= ST_EXEC;
		return -1;
	}
	return st;
}

static int
exited0(int st)
{
	return st != -1 && WIFEXITED(st) && WEXITSTATUS(st) == 0;
}

static void
flush_batch(struct node *n)
{
	struct batch *b = &n->b;
	char **av;
	size_t i;
	int fd = -1, st;

	if (b->n == 0)
		return;
	av = xrealloc(NULL, ((size_t)n->argc + b->n) * sizeof *av);
	for (i = 0; i < (size_t)n->argc - 1; i++)
		av[i] = n->argv[i];
	memcpy(av + i, b->v, b->n * sizeof *av);
	av[i + b->n] = NULL;
	if (n->type == N_EXECDIR)
		fd = ensure_fd(b->level, NULL);
	if (n->type == N_EXEC || fd >= 0) {
		st = run(av, fd, NULL);
		if (st != -1 && !exited0(st))
			status |= ST_EXEC;
	}
	for (i = 0; i < b->n; i++)
		free(b->v[i]);
	free(av);
	b->n = b->bytes = 0;
}

static void
flush_all(int execdir_level_only, size_t level)
{
	int i;

	for (i = 0; i < nnd; i++)
		if ((nd[i].type == N_EXEC || nd[i].type == N_EXECDIR) &&
		    nd[i].plus && (!execdir_level_only ||
		    (nd[i].type == N_EXECDIR && nd[i].b.level == level)))
			flush_batch(&nd[i]);
}

static int
do_exec(struct node *n, struct ent *e)
{
	char **av, *arg, *dir = NULL;
	struct batch *b = &n->b;
	size_t sz;
	int i, st, fd = -1;

	if (n->type == N_EXEC)
		arg = xstrdup(e->path);
	else if (e->depth == 0)
		split_operand(e->path, &dir, &arg);
	else {
		sz = strlen(e->base) + 3;
		arg = xrealloc(NULL, sz);
		(void)snprintf(arg, sz, "./%s", e->base);
	}
	if (n->plus && dir == NULL) {
		sz = strlen(arg) + 1 + sizeof(char *);
		if (b->n && (b->bytes + sz > argmax || (n->type == N_EXECDIR &&
		    (b->level != e->depth - 1 || b->gen != lv[e->depth - 1].gen))))
			flush_batch(n);
		if (b->n == b->cap) {
			b->cap = b->cap ? b->cap * 2 : 64;
			b->v = xrealloc(b->v, b->cap * sizeof *b->v);
		}
		if (n->type == N_EXECDIR) {
			b->level = e->depth - 1;
			b->gen = lv[b->level].gen;
		}
		b->v[b->n++] = arg;
		b->bytes += sz;
		return 1;
	}
	av = xrealloc(NULL, ((size_t)n->argc + 1) * sizeof *av);
	for (i = 0; i < n->argc; i++)
		av[i] = strcmp(n->argv[i], "{}") ? n->argv[i] : arg;
	av[i] = NULL;
	if (n->type == N_EXECDIR && e->depth)
		fd = ensure_fd(e->depth - 1, NULL);
	st = n->type == N_EXECDIR && e->depth && fd < 0 ? -1 : run(av, fd, dir);
	if (n->plus && st != -1 && !exited0(st))
		status |= ST_EXEC;
	free(av);
	free(arg);
	free(dir);
	return n->plus ? 1 : exited0(st);
}

/* ------------------------------------------------------------ predicates */

static int
cmpnum(int cmp, uintmax_t have, uintmax_t want)
{
	return cmp == '+' ? have > want : cmp == '-' ? have < want : have == want;
}

static int
p_time(struct node *n, struct ent *e)
{
	intmax_t age, t;
#if !(defined(__APPLE__) || defined(__NetBSD__) || defined(__FreeBSD__))
	static int warned_btime;	/* -b cannot be answered: warn once */
#endif

	if (n->tsel == 'm')
		t = e->st.st_mtime;
	else if (n->tsel == 'a')
		t = e->st.st_atime;
	else if (n->tsel == 'c')
		t = e->st.st_ctime;
	else {
#if defined(__APPLE__) || defined(__NetBSD__) || defined(__FreeBSD__)
		t = e->st.st_birthtime;
		if (t <= 0)
			return 0;
#elif defined(__linux__) && defined(STATX_BTIME)
		struct statx sx;
		int pfd = e->depth ? ensure_fd(e->depth - 1, NULL) : AT_FDCWD;

		if (pfd < 0 && e->depth)
			return 0;
		if (statx(pfd, e->depth ? e->base : e->path,
		    opt_L || (opt_H && !e->depth) ? 0 : AT_SYMLINK_NOFOLLOW,
		    STATX_BTIME, &sx) == -1 || !(sx.stx_mask & STATX_BTIME)) {
			if (!warned_btime++)
				WRN("birth time unavailable, -b is false", e->path, NULL, "6ab7ff35");
			return 0;
		}
		t = sx.stx_btime.tv_sec;
#else
		if (!warned_btime++)
			WRN("birth time unsupported on this platform", NULL, NULL, "6ab7ff36");
		return 0;
#endif
	}
	age = (intmax_t)now - t;
	if (n->cmp == '+')
		return age > (intmax_t)(n->num * n->unit);
	if (n->cmp == '-')
		return age < (intmax_t)(n->num * n->unit);
	return age >= 0 && (uintmax_t)age / n->unit == n->num;
}

static int
p_empty(struct ent *e)
{
	struct dirent *de;
	struct stat sb;
	DIR *dp;
	int fd, pfd, r = 1;

	if (etype(e) == 'f')
		return e->st.st_size == 0;
	if (etype(e) != 'd')
		return 0;
	pfd = e->depth ? ensure_fd(e->depth - 1, NULL) : AT_FDCWD;
	if (pfd < 0 && e->depth)
		return 0;
	fd = openat(pfd, e->depth ? e->base : e->path, O_RDONLY | O_DIRECTORY |
	    O_CLOEXEC | (opt_L || (opt_H && !e->depth) ? 0 : O_NOFOLLOW));
	if (fd == -1) {
		ERR("cannot open", e->path, strerror(errno), "6ab7ff30");
		status |= ST_NODE;
		return 0;
	}
	if (fstat(fd, &sb) == -1 || sb.st_dev != e->st.st_dev ||
	    sb.st_ino != e->st.st_ino || (dp = fdopendir(fd)) == NULL) {
		(void)close(fd);
		ERR("changed during walk, skipped", e->path, NULL, "6ab7ff31");
		status |= ST_RACE;
		return 0;
	}
	while ((de = readdir(dp)) != NULL)
		if (strcmp(de->d_name, ".") && strcmp(de->d_name, "..")) {
			r = 0;
			break;
		}
	(void)closedir(dp);
	return r;
}

static int
p_delete(struct ent *e)
{
	struct stat sb;
	const char *b = e->base;

	if (e->depth == 0) {
		if (!strcmp(b, "."))
			return 1;	/* find skips . silently */
		if (!strcmp(b, "..") || !strcmp(b, "/")) {
			ERR("refusing to delete", e->path, NULL, "6ab7ff37");
			status |= ST_NODE;
			return 0;
		}
		if (lstat(e->path, &sb) == -1 ||
		    unlinkat(AT_FDCWD, e->path, S_ISDIR(sb.st_mode) ? AT_REMOVEDIR : 0)) {
			ERR("cannot delete", e->path, strerror(errno), "6ab7ff38");
			status |= ST_NODE;
			return 0;
		}
		return 1;
	}
	if (ensure_fd(e->depth - 1, NULL) < 0)
		return 0;
	if (unlinkat(lv[e->depth - 1].fd, b, etype(e) == 'd' ? AT_REMOVEDIR : 0)) {
		ERR("cannot delete", e->path, strerror(errno), "6ab7ff38");
		status |= ST_NODE;
		return 0;
	}
	return 1;
}

static void
p_ls(struct ent *e)
{
	int t = etype(e);

	(void)printf("%8jx %2jx . %8jx %08jx ", (uintmax_t)e->st.st_ino,
	    (uintmax_t)e->st.st_nlink, (uintmax_t)e->st.st_size,
	    (uintmax_t)e->st.st_mtime);
	putname(stdout, e->path, esc_out);
	(void)fputs(t == 'd' ? "/\n" : t == 'l' ? "@\n" : t == 'p' ? "|\n" :
	    t == 's' ? "=\n" : "\n", stdout);
}

static int
eval(int i, struct ent *e)
{
	struct node *n = &nd[i];
	int f;

	switch (n->type) {
	case N_TRUE: return 1;
	case N_AND: return eval(n->l, e) && !quitting && eval(n->r, e);
	case N_OR: return eval(n->l, e) || (!quitting && eval(n->r, e));
	case N_NOT: return !eval(n->l, e);
	case N_NAME: case N_PATH:
		f = opt_I ? FNM_CASEFOLD : 0;
		return fnmatch(n->pat, n->type == N_NAME ? e->base : e->path, f) == 0;
	case N_REGEX: return regexec(&n->re, e->path, 0, NULL, 0) == 0;
	case N_TYPE:
		f = etype(e);
		return f != '?' && (n->tmask >> (strchr("fdlpsbc", f) - "fdlpsbc") & 1);
	case N_SIZE: return cmpnum(n->cmp, (uintmax_t)e->st.st_size, n->num);
	case N_TIME: return p_time(n, e);
	case N_NEWER:
		return MTIM(&e->st).tv_sec > n->ref.tv_sec ||
		    (MTIM(&e->st).tv_sec == n->ref.tv_sec &&
		    MTIM(&e->st).tv_nsec > n->ref.tv_nsec);
	case N_PERM:
		f = e->st.st_mode & 07777;
		return n->cmp == '-' ? (f & n->mode) == n->mode :
		    n->cmp == '+' ? (n->mode == 0 || (f & n->mode) != 0) :
		    (mode_t)f == n->mode;
	case N_USER: return (uintmax_t)e->st.st_uid == n->num;
	case N_GROUP: return (uintmax_t)e->st.st_gid == n->num;
	case N_EMPTY: return p_empty(e);
	case N_LINKS: return cmpnum(n->cmp, (uintmax_t)e->st.st_nlink, n->num);
	case N_INUM: return cmpnum(n->cmp, (uintmax_t)e->st.st_ino, n->num);
	case N_PRUNE: e->prune = 1; return 1;
	case N_PRINT:
		putname(stdout, e->path, esc_out && !opt_0);
		(void)putchar(opt_0 ? '\0' : '\n');
		return 1;
	case N_LS: p_ls(e); return 1;
	case N_EXEC: case N_EXECDIR: return do_exec(n, e);
	case N_DELETE: return p_delete(e);
	case N_QUIT: quitting = 1; return 1;
	}
	return 0;
}

/* ---------------------------------------------------------------- walker */

static const char *sortbase;

static int
cmp_off(const void *a, const void *b)
{
	return strcmp(sortbase + *(const size_t *)a, sortbase + *(const size_t *)b);
}

static void visit(struct ent *e);

static void
walk_dir(struct ent *e)
{
	size_t d = e->depth, i, n = 0, capn = 0, blen = 0, bcap = 0, old;
	size_t *off = NULL, len;
	unsigned char *typ = NULL;
	char *buf = NULL;
	struct dirent *de;
	struct ent c;
	DIR *dp;
	int fd, dfd;

	if (d + 1 > caplv) {
		caplv = caplv ? caplv * 2 : 32;
		lv = xrealloc(lv, caplv * sizeof *lv);
	}
	lv[d].name = xstrdup(d ? e->base : e->path);
	lv[d].dev = e->st.st_dev;
	lv[d].ino = e->st.st_ino;
	lv[d].fd = -1;
	lv[d].follow = opt_L || (opt_H && d == 0);
	lv[d].gen = ++gens;
	nlv = d + 1;
	if ((fd = ensure_fd(d, e->path)) < 0) {
		free(lv[d].name);
		nlv = d;
		return;
	}
	/* list everything first: the directory stays consistent for -S and
	 * the walk never holds a DIR stream across recursion */
	if ((dfd = fcntl(fd, F_DUPFD_CLOEXEC, 0)) == -1 ||
	    (dp = fdopendir(dfd)) == NULL) {
		ERR("cannot read", e->path, strerror(errno), "6ab7ff39");
		status |= ST_NODE;
		goto done;
	}
	for (errno = 0; (de = readdir(dp)) != NULL; errno = 0) {
		if (!strcmp(de->d_name, ".") || !strcmp(de->d_name, ".."))
			continue;
		len = strlen(de->d_name) + 1;
		while (blen + len > bcap) {
			bcap = bcap ? bcap * 2 : 4096;
			buf = xrealloc(buf, bcap);
		}
		if (n == capn) {
			capn = capn ? capn * 2 : 64;
			off = xrealloc(off, capn * sizeof *off);
			typ = xrealloc(typ, capn);
		}
		memcpy(buf + blen, de->d_name, len);
		off[n] = blen;
		typ[n] = de->d_type;
		n++;
		blen += len;
	}
	if (errno) {
		ERR("cannot read", e->path, strerror(errno), "6ab7ff39");
		status |= ST_NODE;
	}
	(void)closedir(dp);
	if (opt_S && n > 1) {
		unsigned char *t2 = xrealloc(NULL, bcap ? bcap : 1);

		/* sort offsets; carry types through a name-indexed scratch */
		for (i = 0; i < n; i++)
			t2[off[i]] = typ[i];
		sortbase = buf;
		qsort(off, n, sizeof *off, cmp_off);
		for (i = 0; i < n; i++)
			typ[i] = t2[off[i]];
		free(t2);
	}
	for (i = 0; i < n && !quitting; i++) {
		old = pblen;
		len = strlen(buf + off[i]);
		while (pblen + len + 2 > pbcap) {
			pbcap *= 2;
			pb = xrealloc(pb, pbcap);
		}
		if (pblen == 0 || pb[pblen - 1] != '/')
			pb[pblen++] = '/';
		memcpy(pb + pblen, buf + off[i], len + 1);
		memset(&c, 0, sizeof c);
		c.path = pb;
		c.base = pb + pblen;
		pblen += len;
		c.depth = d + 1;
		c.dtype = typ[i];
		if (need_stat || opt_X || c.dtype == DT_DIR ||
		    c.dtype == DT_UNKNOWN || (opt_L && c.dtype == DT_LNK))
			if (load(&c) == -1) {
				pblen = old;
				pb[pblen] = '\0';
				continue;
			}
		visit(&c);
		pblen = old;
		pb[pblen] = '\0';
	}
done:
	flush_all(1, d);
	free(buf);
	free(off);
	free(typ);
	if (lv[d].fd >= 0) {
		(void)close(lv[d].fd);
		nopen--;
	}
	free(lv[d].name);
	nlv = d;
}

static void
visit(struct ent *e)
{
	long dp = (long)e->depth;
	int in = dp >= mindepth && dp <= maxdepth;
	size_t i;

	/* a directory that is its own ancestor closes a loop (-L, bind
	 * mounts): reported and skipped, not tested, as fts FTS_DC in find */
	if (e->have_st && S_ISDIR(e->st.st_mode))
		for (i = 0; i < e->depth && i < nlv; i++)
			if (lv[i].dev == e->st.st_dev && lv[i].ino == e->st.st_ino) {
				WRN("filesystem loop, skipped", e->path, NULL, "6ab7ff3a");
				status |= ST_LOOP;
				return;
			}

	if (!opt_D && in)
		(void)eval(root, e);
	if (quitting)
		return;
	if (e->have_st && S_ISDIR(e->st.st_mode) && !e->prune &&
	    dp < maxdepth && !(opt_X && e->st.st_dev != rootdev)) {
		size_t bo = (size_t)(e->base - e->path);

		walk_dir(e);	/* pb may have moved */
		if (e->depth)
			e->base = pb + bo;
		e->path = pb;
	}
	if (opt_D && in && !quitting)
		(void)eval(root, e);
}

static void
walk_operand(const char *path)
{
	struct ent e;
	char *base, *s;
	size_t n;

	/* basename as find reports it: trailing slashes ignored */
	base = xstrdup(path);
	for (n = strlen(base); n > 1 && base[n - 1] == '/'; )
		base[--n] = '\0';
	s = strrchr(base, '/');
	memset(&e, 0, sizeof e);
	e.base = s && s[1] ? s + 1 : base;
	n = strlen(path);
	if (n + 2 > pbcap) {
		pbcap = n + 256;
		pb = xrealloc(pb, pbcap);
	}
	memcpy(pb, path, n + 1);
	pblen = n;
	e.path = pb;
	if (load(&e) == 0) {
		rootdev = e.st.st_dev;
		visit(&e);
	}
	free(base);
}

/* ------------------------------------------------------------------ help */

static const char usage_text[] =
"Usage: ff [-EIHLDSX0] [--] [path ...] [expression]\n"
"  options  -E ERE for -r  -I ignore case  -H/-L follow symlinks\n"
"           -D post-order  -S sorted  -X one filesystem  -0 NUL output\n"
"  tests    -n glob  -p glob  -r re  -t fdlpsbc  -d [+-]N  -s [+-]N[ckMGT]\n"
"           -m -a -c -b [+-]N[smhdw]  -w file  -k [+-]mode  -u user\n"
"           -g group  -l [+-]N  -i [+-]N  -e  -z (prune)\n"
"  actions  -f print  -v cksh line  -x cmd {} ;|+  (in entry's dir)\n"
"           -j cmd {} ;|+  (full path)  -delete  -q quit\n"
"  logic    ( )  !  juxtaposition = and  -o or\n"
"  -h this summary, --help the manual\n";

/* chunks below the C99 4095 byte literal limit, joined on output */
static const char *const manual[] = {
"NAME\n"
"  ff - functional find: walk file trees, one letter per switch\n"
"\n"
"SYNOPSIS\n"
"  ff [-EIHLDSX0] [--] [path ...] [expression]\n"
"  ff -h | --help\n"
"\n"
"DESCRIPTION\n"
"  ff walks each path (default .) and evaluates the expression for every\n"
"  node, as find(1) does, with one letter per switch. Options are\n"
"  uppercase and global; they may appear anywhere except as the argument\n"
"  of a primary. Primaries are lowercase. With no action in the\n"
"  expression, each node for which it is true is printed.\n"
"\n"
"  Printed paths are the operand, then / and each name below it. Output\n"
"  is raw bytes when stdout is not a terminal or -0 is given. On a\n"
"  terminal, C0 and C1 control characters, DEL and bytes that are not\n"
"  valid UTF-8 print as \\ooo octal escapes, so a crafted name cannot\n"
"  drive the terminal; names in diagnostics follow the same rule.\n"
"\n"
"  Directories are opened relative to their verified parent descriptor,\n"
"  never by re-resolving a path; a directory swapped for another node\n"
"  between listing and opening is reported and skipped.\n"
"\n"
"OPTIONS\n"
"  -E     extended regular expressions (ERE) for -r; default basic (BRE)\n"
"  -I     case-insensitive -n, -p and -r\n"
"  -H     follow symlinks named as path operands\n"
"  -L     follow all symlinks; loops are reported, not followed\n"
"  -D     post-order: a directory is tested after its contents\n"
"  -S     sorted walk: each directory's names in bytewise order\n"
"  -X     do not descend into directories on other filesystems\n"
"  -0     end names from -f and the default print with NUL, not newline\n"
"  --     end of options: following words are paths, even with a\n"
"         leading -, until a primary or operator\n"
"  -h     short usage;  --help  this manual\n"
"\n",
"PRIMARIES\n"
"  N is decimal: +N more than N, -N less than N, N exactly.\n"
"  -n glob     last component matches glob (fnmatch; * matches a leading .)\n"
"  -p glob     whole path matches glob (* also matches /)\n"
"  -r re       path contains a match for re: unanchored, add ^ and $\n"
"  -t types    type is any of: f file, d directory, l symlink, p fifo,\n"
"              s socket, b block, c character device; -t fl is f or l\n"
"  -d N        walk bound, global wherever it appears; operands are\n"
"              depth 0.  -d -2: operands and their entries;\n"
"              -d +0: everything below the operands; -d 1: entries only\n"
"  -s N[ckMGT] size in bytes compared exactly; k M G T are 1024-based\n"
"  -m N[smhdw] modified: age in seconds against N units, default d.\n"
"              -m -2h under 2 hours; -m +7 over 7 days; -m 7 from 7 up\n"
"              to 8 days\n"
"  -a -c -b    the same for access, status change and birth time;\n"
"              -b is false where the filesystem records no birth time\n"
"  -w file     modified more recently than file\n"
"  -k mode     permission bits: octal or symbolic (u+x,go-w); mode is\n"
"              exact, -mode all bits set, +mode any bit set\n"
"  -u user     owner, name or number;  -g group  group, name or number\n"
"  -l N        link count;  -i N  inode number\n"
"  -e          empty regular file or directory\n"
"  -z          prune: do not descend into this directory; true\n"
"\n"
"ACTIONS\n"
"  -f          print the path; explicit form for use with -o\n"
"  -v          print a cksh line: inode links . size mdate name, hex,\n"
"              the same as cksh -n0 -x0 on that name\n"
"  -x cmd ... ;       run cmd inside the directory holding the node, {}\n"
"                     as ./name; true when cmd exits 0\n"
"  -x cmd ... {} +    the same, many names per run, per directory\n"
"  -j cmd ... ;       run cmd from the current directory, {} as the path\n"
"  -j cmd ... {} +    the same, many paths per run\n"
"  -delete     remove the node; implies -D; refused with -L and for\n"
"              .. and /; . is skipped silently\n"
"  -q          stop the walk; pending + batches still run\n"
"\n"
"OPERATORS\n"
"  ( expr )  ! expr  expr expr (and)  expr -o expr\n"
"  ! binds tightest, then and, then -o. Quote ( ) ! and ; for the shell.\n"
"\n",
"EXEC\n"
"  Commands run by fork and exec, never through a shell. {} is replaced\n"
"  only when it is a whole argument. With +, {} must be last and appear\n"
"  once. -x changes into the node's directory through the descriptor the\n"
"  walk verified, so the path above the node cannot be swapped between\n"
"  test and use; -x refuses to run when PATH holds a relative or empty\n"
"  element, since a file planted in the walked directory would run.\n"
"  -j passes the full path, which is exposed to that race, as find\n"
"  -exec is; use it when the command needs whole paths.\n"
"\n"
"EXIT STATUS\n"
"  A bitmask. 1 and 2 are fatal; the others accumulate as the walk\n"
"  continues.\n"
"     0  success\n"
"     1  invalid option or expression\n"
"     2  environment: memory, stdout, fork, unsafe PATH for -x\n"
"     4  cannot stat, open, read or delete a node; subtree skipped\n"
"     8  a command could not run, or a + batch exited nonzero\n"
"    16  filesystem or symlink loop\n"
"    32  node changed between listing and opening; skipped\n"
"  A -x or -j ... ; command that exits nonzero is only false.\n"
"\n"
"  On stderr, errors as '>>> ff : ...' and warnings as '^^^ ff : ...',\n"
"  each ending in a hex tag naming the message.\n"
"\n"
"DIFFERENCES\n"
"  From NetBSD find: one-letter switches; -r is unanchored; -s is bytes\n"
"  with no rounding; times compare seconds, not rounded days; -d is a\n"
"  global bound; {} is never replaced inside a larger word; names are\n"
"  escaped on a terminal; -I replaces -iname, -ipath and -iregex.\n"
"\n"
"EXAMPLES\n"
"  ff . -t f -n '*.c'              C sources\n"
"  ff -E src -r '\\.(c|h)$'         the same by regex\n"
"  ff . -n .git -z -o -t f -f      files, skipping .git trees\n"
"  ff . -t f -m -1 -v | sort -k5   changed today, by mtime\n"
"  ff . -t f -x grep -l TODO {} +  per-directory grep, race safe\n"
"  ff . -n '*.o' -delete           remove objects\n"
"  ff -0 . -t f | xargs -0 cksh    hash everything\n"
"\n"
"NOTES\n"
"  -u and -g resolve names on Linux by running getent from /usr/bin or\n"
"  /bin, so a static binary sees the same users as the host; without\n"
"  getent a name is an error (2) and a numeric id still works. Other\n"
"  platforms use the C library.\n"
"  Names are compared as bytes: no Unicode normalization, so on Darwin\n"
"  HFS+ a precomposed pattern does not match a decomposed name.\n"
"\n",
"HISTORY\n"
"  org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026\n"
"      owned openat walker with dev/ino verification; one-letter\n"
"      grammar; -x execdir, -j exec, -delete through the verified parent;\n"
"      getent ids on Linux; tty escaping; status bitmask; chkerr/chkwrn\n"
"      diagnostics; bash translator ff.fn.bash for the native find.\n"
"\n"
"COPYRIGHT\n"
"  (c) 2026 George Georgalis <george@iuxta.com>\n"
"  Unlimited use with attribution.\n"
};

static void
put_help(int full)
{
	size_t i;

	if (!full)
		(void)fputs(usage_text, stdout);
	else
		for (i = 0; i < sizeof manual / sizeof *manual; i++)
			(void)fputs(manual[i], stdout);
	xflush();
	exit(0);
}

/* ------------------------------------------------------------------ main */

static int
is_optword(const char *s)
{
	return s[0] == '-' && s[1] != '\0' && strspn(s + 1, "EIHLDSX0") == strlen(s + 1);
}

static int
has_action(int i)
{
	if (i < 0)
		return 0;
	switch (nd[i].type) {
	case N_AND: case N_OR: return has_action(nd[i].l) || has_action(nd[i].r);
	case N_NOT: return has_action(nd[i].l);
	case N_PRINT: case N_LS: case N_EXEC: case N_EXECDIR:
	case N_DELETE: case N_QUIT: return 1;
	}
	return 0;
}

int
main(int argc, char **argv)
{
	char **paths;
	int i, npaths = 0, endopt = 0, inexpr = 0, useenv = 0;

	const char *a, *p;
	long am;
	extern char **environ;
	char **ep;

	paths = xrealloc(NULL, (size_t)argc * sizeof *paths);
	tok = xrealloc(NULL, (size_t)argc * sizeof *tok);
	esc_err = isatty(2);
	/* pre-pass: options anywhere, paths before the expression, and
	 * primary arguments and exec words kept whole */
	for (i = 1; i < argc; i++) {
		a = argv[i];
		if (!endopt && is_optword(a)) {
			for (p = a + 1; *p; p++)
				switch (*p) {
				case 'E': opt_E = 1; break;
				case 'I': opt_I = 1; break;
				case 'H': opt_H = 1; opt_L = 0; break;
				case 'L': opt_L = 1; opt_H = 0; break;
				case 'D': opt_D = 1; break;
				case 'S': opt_S = 1; break;
				case 'X': opt_X = 1; break;
				case '0': opt_0 = 1; break;
				}
			continue;
		}
		if (!endopt && !inexpr && !strcmp(a, "--")) {
			endopt = 1;
			continue;
		}
		if (!endopt && !inexpr && !strcmp(a, "-h"))
			put_help(0);
		if (!endopt && !inexpr && !strcmp(a, "--help"))
			put_help(1);
		if (!inexpr && !is_exprtok(a)) {
			if (a[0] == '-' && !endopt)
				bad("unknown option", a, "6ab7ff01");
			paths[npaths++] = argv[i];
			continue;
		}
		inexpr = 1;
		tok[ntok++] = argv[i];
		if (is_prim(a, P_ARG)) {
			if (++i >= argc)
				bad("missing argument for", a, "6ab7ff02");
			tok[ntok++] = argv[i];
		} else if (is_prim(a, P_EXEC)) {
			for (i++; i < argc; i++) {
				tok[ntok++] = argv[i];
				if (!strcmp(argv[i], ";") || (!strcmp(argv[i], "+") &&
				    !strcmp(argv[i - 1], "{}")))
					break;
			}
			if (i >= argc)
				bad("missing ; or {} + after", a, "6ab7ff1d");
		} else if (!is_exprtok(a))
			bad(a[0] == '-' ? "unknown primary" : "unexpected word", a,
			    a[0] == '-' ? "6ab7ff03" : "6ab7ff04");
	}
	if (ntok) {
		root = parse_or();
		if (ti < ntok)
			bad("unexpected", tok[ti], "6ab7ff05");
	}
	if (!has_action(root))
		root = root < 0 ? mk(N_PRINT, -1, -1) :
		    mk(N_AND, root, mk(N_PRINT, -1, -1));
	for (i = 0; i < nnd; i++)
		if (nd[i].type == N_DELETE && opt_L)
			bad("-delete is refused with -L", NULL, "6ab7ff1e");
	for (i = 0; i < nnd; i++)
		if (nd[i].type == N_EXECDIR && !strchr(nd[i].argv[0], '/'))
			useenv = 2;
	if (useenv == 2)
		check_path();

	/* exec argument budget: ARG_MAX less the environment and headroom */
	am = sysconf(_SC_ARG_MAX);
	argmax = am > 0 ? (size_t)am : 65536;
	for (ep = environ; ep && *ep; ep++)
		argmax -= argmax > strlen(*ep) + 1 + sizeof *ep ?
		    strlen(*ep) + 1 + sizeof *ep : 0;
	argmax = argmax > 4096 + 2048 ? argmax - 4096 : 2048;
	if (argmax > 262144)
		argmax = 262144;

	/* half the descriptor limit, leaving room for stdio, -e and exec pipes */
	{
		struct rlimit rl;

		if (getrlimit(RLIMIT_NOFILE, &rl) == 0 && rl.rlim_cur != RLIM_INFINITY &&
		    rl.rlim_cur / 2 < (rlim_t)fdcap + 8)
			fdcap = rl.rlim_cur / 2 > 12 ? (int)(rl.rlim_cur / 2) - 8 : 4;
	}
	esc_out = isatty(1);
	now = time(NULL);
	pbcap = 256;
	pb = xrealloc(NULL, pbcap);
	if (npaths == 0)
		paths[npaths++] = ".";
	for (i = 0; i < npaths && !quitting; i++) {
		if (paths[i][0] == '\0') {
			ERR("empty path", NULL, NULL, "6ab7ff3b");
			status |= ST_NODE;
			continue;
		}
		walk_operand(paths[i]);
	}
	flush_all(0, 0);
	xflush();
	return status;
}
