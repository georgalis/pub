/* roffsub.c --- check, compile, and render terminal manuals written in roffsub
 * roffsub r0.9
 * (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 *
 * Identical in use to the roffsub bash function, which serves systems
 * where programs cannot be run from the user's own directories.  The
 * binary renders records and pre-formatted text itself; checking,
 * compiling, and generating run the embedded awk tools through awk.
 * --help shows the roffsub(1) manual, embedded in full profile.
 */
#define _POSIX_C_SOURCE 200809L
#define _DARWIN_C_SOURCE
#define _NETBSD_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#include "roffsub.h"
#include "roffsub-emit.h"
#include "roffsub-tty.h"
#include "roffsub.man.h"
#include "roffsub.awk.h"

#define VERSION "roffsub r0.9"

static const char usage[] =
"usage: roffsub [-w width] [-s style] [-m measure] [file]   render\n"
"       roffsub -e [-s style] [file]                       emit pre-formatted\n"
"       roffsub -c file ...                                check form\n"
"       roffsub -i [-d date] [-r rev] [file]               write records\n"
"       roffsub -p [-w width] [file]                       write pre-formatted\n"
"       roffsub -g c|bash name [file]                      write embedding\n"
"       roffsub -n [-d date] [-r rev] [file]               write page for man\n"
"  -w  columns (default MANWIDTH, then the terminal, then 80)\n"
"  -s  plain, overstrike, sgr, or pre (default by destination)\n"
"  -m  maximum line length        -h usage   --help manual   -V version\n"
"  file: a roffsub source (.1 .7 ...) or its records; stdin when absent\n"
"  binary and function behave alike; both use awk to check and compile\n";

static void die(const char *m) { fprintf(stderr, "roffsub: %s\n", m); exit(2); }

static char **readlines(FILE *in, int *np)
{
	char **v = 0, *line = 0; size_t cap = 0; ssize_t len; int n = 0, vc = 0;
	while ((len = getline(&line, &cap, in)) >= 0) {
		if (len && line[len - 1] == '\n') line[--len] = 0;
		if (n + 1 >= vc) { vc = vc ? vc * 2 : 256; v = realloc(v, (size_t)vc * sizeof *v); if (!v) die("out of memory"); }
		v[n] = malloc((size_t)len + 1); if (!v[n]) die("out of memory");
		memcpy(v[n], line, (size_t)len + 1); n++;
	}
	free(line);
	if (!v) { v = malloc(sizeof *v); if (!v) die("out of memory"); }
	v[n] = 0; *np = n;
	return v;
}

static void freelines(char **v, int n) { int i; for (i = 0; i < n; i++) free(v[i]); free(v); }

/* an embedded awk program as one string */
static char *program(const char *const *v)
{
	size_t n = 1; const char *const *p; char *s, *d;
	for (p = v; *p; p++) n += strlen(*p) + 1;
	if (!(s = d = malloc(n))) die("out of memory");
	for (p = v; *p; p++) { size_t k = strlen(*p); memcpy(d, *p, k); d += k; *d++ = '\n'; }
	*d = 0;
	return s;
}

/* run awk with argv; capture != 0 reads its output into lines */
static int awk(char **argv, int check, char ***out, int *nout)
{
	int fd[2], st; pid_t pid; FILE *f;
	if (out && pipe(fd)) die("pipe failed");
	fflush(stdout);
	if ((pid = fork()) < 0) die("fork failed");
	if (!pid) {
		if (out) { dup2(fd[1], 1); close(fd[0]); close(fd[1]); }
		if (check) setenv("LC_ALL", "C", 1);
		execvp("awk", argv);
		perror("roffsub: awk");
		_exit(127);
	}
	if (out) {
		close(fd[1]);
		if (!(f = fdopen(fd[0], "r"))) die("fdopen failed");
		*out = readlines(f, nout);
		fclose(f);
	}
	while (waitpid(pid, &st, 0) < 0) ;
	return WIFEXITED(st) ? WEXITSTATUS(st) : 2;
}

/* records from input lines: as is, or compiled by awk from path */
static char **records(char **lines, int n, const char *path, const char *date, const char *rev, int *nout)
{
	char *av[10], dv[300], rv[300], tmp[1024], **rec; int i = 0, r, fd = -1;
	if (n && !strcmp(lines[0], "v\t1")) { *nout = n; return lines; }
	if (!path) {
		const char *t = getenv("TMPDIR");
		snprintf(tmp, sizeof tmp, "%s/roffsub.XXXXXX", t && *t ? t : "/tmp");
		if ((fd = mkstemp(tmp)) < 0) die("cannot create a temporary file");
		{
			FILE *f = fdopen(fd, "w");
			for (r = 0; r < n; r++) fprintf(f, "%s\n", lines[r]);
			fclose(f);
		}
		path = tmp;
	}
	snprintf(dv, sizeof dv, "date=%s", date ? date : "");
	snprintf(rv, sizeof rv, "version=%s", rev ? rev : "");
	av[i++] = "awk"; av[i++] = "-v"; av[i++] = dv; av[i++] = "-v"; av[i++] = rv;
	av[i++] = program(roffsub_awk_ir); av[i++] = (char *)path; av[i] = 0;
	r = awk(av, 0, &rec, nout);
	free(av[5]);
	if (fd >= 0) unlink(tmp);
	freelines(lines, n);
	if (r) exit(r);
	return rec;
}

int main(int argc, char **argv)
{
	int i, width = -1, style = -1, measure = -1, n, r;
	enum { RENDER, EMIT, CHECK, IR, PRE, GEN, PAGE } mode = RENDER;
	const char *date = 0, *rev = 0, *lang = 0, *name = 0;
	char **lines; FILE *in = stdin;
	struct roffsub_tty t; struct roffsub_opt o;

	for (i = 1; i < argc; i++) {
		const char *a = argv[i];
		if (!strcmp(a, "--help")) {
			roffsub_tty_open(&t, -1, -1);
			o.width = t.width; o.style = t.style; o.sgrb = t.sgrb; o.sgri = t.sgri;
			o.measure = t.measure; o.heading = t.heading;
			r = roffsub_render(roffsub_man, t.out, &o);
			roffsub_tty_close(&t);
			return r;
		}
		if (!strcmp(a, "-h")) { fputs(usage, stdout); return 0; }
		if (!strcmp(a, "-V")) { puts(VERSION); return 0; }
		if (!strcmp(a, "-e")) { mode = EMIT; continue; }
		if (!strcmp(a, "-c")) { mode = CHECK; continue; }
		if (!strcmp(a, "-i")) { mode = IR; continue; }
		if (!strcmp(a, "-p")) { mode = PRE; continue; }
		if (!strcmp(a, "-n")) { mode = PAGE; continue; }
		if (!strcmp(a, "-g")) {
			if (i + 2 >= argc) die("-g needs c|bash and a name; see roffsub -h");
			lang = argv[++i]; name = argv[++i]; mode = GEN;
			if (strcmp(lang, "c") && strcmp(lang, "bash")) die("-g takes c or bash");
			continue;
		}
		if (!strcmp(a, "-w") || !strcmp(a, "-s") || !strcmp(a, "-m") || !strcmp(a, "-d") || !strcmp(a, "-r")) {
			if (++i >= argc) { fprintf(stderr, "roffsub: %s needs a value; see roffsub -h\n", a); return 2; }
			switch (a[1]) {
			case 'w': if ((width = rst_num(argv[i])) < 1) die("width must be a positive number"); break;
			case 'm': if ((measure = rst_num(argv[i])) < 0 || (!measure && strcmp(argv[i], "0"))) die("measure must be a number"); break;
			case 's': if ((style = roffsub_style_name(argv[i])) < 0) die("style is plain, overstrike, sgr or pre"); break;
			case 'd': date = argv[i]; break;
			case 'r': rev = argv[i]; break;
			}
			continue;
		}
		if (!strcmp(a, "--")) { i++; break; }
		if (a[0] == '-' && a[1]) { fprintf(stderr, "roffsub: unknown option %s; see roffsub -h\n", a); return 2; }
		break;
	}

	if (mode == CHECK || mode == GEN || mode == PAGE) {
		char **av = calloc((size_t)argc + 8, sizeof *av), sv[16], mv[300], nv[300], *prog; int k = 0;
		const char *s = getenv("ROFFSUB_STRICT");
		if (mode == CHECK && i >= argc) die("-c needs a file");
		av[k++] = "awk";
		if (mode == CHECK) {
			snprintf(sv, sizeof sv, "strict=%s", s && *s ? "1" : "");
			av[k++] = "-v"; av[k++] = sv; av[k++] = prog = program(roffsub_awk_check);
		} else if (mode == PAGE) {
			snprintf(mv, sizeof mv, "date=%.280s", date ? date : "");
			snprintf(nv, sizeof nv, "version=%.280s", rev ? rev : "");
			av[k++] = "-v"; av[k++] = mv; av[k++] = "-v"; av[k++] = nv; av[k++] = prog = program(roffsub_awk_man);
			if (i < argc) av[k++] = argv[i];
		} else {
			snprintf(mv, sizeof mv, "mode=%s", lang);
			snprintf(nv, sizeof nv, "name=%s", name);
			av[k++] = "-v"; av[k++] = mv; av[k++] = "-v"; av[k++] = nv; av[k++] = prog = program(roffsub_awk_gen);
			if (i < argc) av[k++] = argv[i];
		}
		if (mode == CHECK) for (; i < argc; i++) av[k++] = argv[i];
		av[k] = 0;
		r = awk(av, mode == CHECK, 0, 0);
		free(prog); free(av);
		return r;
	}

	if (i < argc && strcmp(argv[i], "-") && !(in = fopen(argv[i], "r"))) {
		fprintf(stderr, "roffsub: cannot read %s\n", argv[i]); return 2;
	}
	lines = readlines(in, &n);
	if (in != stdin) fclose(in);
	if (mode != EMIT)
		lines = records(lines, n, in != stdin ? argv[i] : 0, date, rev, &n);

	if (mode == IR) {
		for (r = 0; r < n; r++) puts(lines[r]);
		freelines(lines, n);
		return 0;
	}
	if (mode == PRE) {
		o.width = width > 0 ? width : 80; o.style = ROFFSUB_PRE; o.sgrb = "1"; o.sgri = "4";
		o.measure = 0; o.heading = 0;
		r = roffsub_render((const char *const *)lines, stdout, &o);
		freelines(lines, n);
		return r;
	}
	roffsub_tty_open(&t, width, style);
	if (measure >= 0) t.measure = measure;
	if (mode == EMIT) {
		roffsub_emit((const char *const *)lines, t.out, t.style, t.sgrb, t.sgri);
		r = 0;
	} else {
		o.width = t.width; o.style = t.style; o.sgrb = t.sgrb; o.sgri = t.sgri;
		o.measure = t.measure; o.heading = t.heading;
		r = roffsub_render((const char *const *)lines, t.out, &o);
	}
	roffsub_tty_close(&t);
	freelines(lines, n);
	return r;
}
