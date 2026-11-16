/* roffsub-tty.h --- choose width, emphasis and pager for --help (header-only)
 * roffsub r0.9
 * (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 *
 * C99 plus POSIX.  Define before any include in the program:
 *   #define _POSIX_C_SOURCE 200809L
 *   #define _DARWIN_C_SOURCE
 *   #define _NETBSD_SOURCE
 *
 *   struct roffsub_tty t;
 *   roffsub_tty_open(&t, -1, -1);     -1: no command-line choice
 *   ... render or emit to t.out with t.width, t.style, t.sgrb, t.sgri ...
 *   roffsub_tty_close(&t);
 *
 * Resolution (plan section 8.2):
 *   stdout a terminal, pager found     -> pager, overstrike, terminal width
 *   stdout a terminal, PAGER is cat    -> terminal, sgr, terminal width
 *   stdout not a terminal              -> plain, 80
 *   MANWIDTH sets the width; ROFFSUB_STYLE the style; TERM=dumb plain;
 *   ROFFSUB_SGR "b=1;33:i=4;36"; ROFFSUB_MEASURE the line limit;
 *   ROFFSUB_HEADING the section heading column offset.
 */
#ifndef ROFFSUB_TTY_H
#define ROFFSUB_TTY_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#ifndef ROFFSUB_STYLES
#define ROFFSUB_STYLES
enum { ROFFSUB_PLAIN, ROFFSUB_OVERSTRIKE, ROFFSUB_SGR, ROFFSUB_PRE };
#endif

struct roffsub_tty {
	int width, style, measure, heading;
	char sgrb[32], sgri[32];
	FILE *out, *pipe;
};

static int roffsub_style_name(const char *s)
{
	if (!s) return -1;
	if (!strcmp(s, "plain")) return ROFFSUB_PLAIN;
	if (!strcmp(s, "overstrike")) return ROFFSUB_OVERSTRIKE;
	if (!strcmp(s, "sgr")) return ROFFSUB_SGR;
	if (!strcmp(s, "pre")) return ROFFSUB_PRE;
	return -1;
}

static int rst_num(const char *s)
{
	int v = 0;
	if (!s || !*s) return 0;
	for (; *s; s++) { if (*s < '0' || *s > '9') return 0; v = v * 10 + (*s - '0'); if (v > 9999) return 0; }
	return v;
}

static int rst_termwidth(void)
{
#ifdef TIOCGWINSZ
	struct winsize ws; int fd;
	if (!ioctl(1, TIOCGWINSZ, &ws) && ws.ws_col > 0) return ws.ws_col;
	if (!ioctl(2, TIOCGWINSZ, &ws) && ws.ws_col > 0) return ws.ws_col;
	if ((fd = open("/dev/tty", O_RDONLY)) >= 0) {
		int ok = !ioctl(fd, TIOCGWINSZ, &ws) && ws.ws_col > 0;
		close(fd);
		if (ok) return ws.ws_col;
	}
#endif
	return 0;
}

/* is the first word of cmd an executable on PATH (or a path)? */
static int rst_onpath(const char *cmd)
{
	char word[256], buf[1024]; const char *p, *e; size_t n;
	for (n = 0; cmd[n] && cmd[n] != ' ' && n < sizeof word - 1; n++) word[n] = cmd[n];
	word[n] = 0;
	if (!n) return 0;
	if (strchr(word, '/')) return access(word, X_OK) == 0;
	for (p = getenv("PATH"); p && *p; p = *e ? e + 1 : e) {
		e = strchr(p, ':'); if (!e) e = p + strlen(p);
		if ((size_t)(e - p) + n + 2 > sizeof buf) continue;
		memcpy(buf, p, (size_t)(e - p)); buf[e - p] = '/';
		memcpy(buf + (e - p) + 1, word, n + 1);
		if (access(buf, X_OK) == 0) return 1;
	}
	return 0;
}

static int rst_iscat(const char *cmd)
{
	const char *b = cmd, *p; size_t n;
	for (n = 0; cmd[n] && cmd[n] != ' '; n++) if (cmd[n] == '/') b = cmd + n + 1;
	p = cmd + n;
	return (size_t)(p - b) == 3 && !strncmp(b, "cat", 3);
}

static void rst_sgr(struct roffsub_tty *t)
{
	const char *s = getenv("ROFFSUB_SGR"), *p, *e; size_t n;
	strcpy(t->sgrb, "1"); strcpy(t->sgri, "4");
	for (p = s; p && *p; p = *e ? e + 1 : e) {
		e = strchr(p, ':'); if (!e) e = p + strlen(p);
		n = (size_t)(e - p);
		if (n > 2 && n - 2 < sizeof t->sgrb && p[1] == '=' && (p[0] == 'b' || p[0] == 'i')) {
			char *d = p[0] == 'b' ? t->sgrb : t->sgri;
			memcpy(d, p + 2, n - 2); d[n - 2] = 0;
		}
	}
}

static void roffsub_tty_open(struct roffsub_tty *t, int width, int style)
{
	const char *pg = getenv("PAGER"), *term = getenv("TERM");
	int envstyle = roffsub_style_name(getenv("ROFFSUB_STYLE"));
	int mw = rst_num(getenv("MANWIDTH")), tty = isatty(1);
	int dumb = term && !strcmp(term, "dumb");

	memset(t, 0, sizeof *t);
	t->out = stdout;
	t->measure = rst_num(getenv("ROFFSUB_MEASURE"));
	t->heading = rst_num(getenv("ROFFSUB_HEADING"));
	rst_sgr(t);
	t->width = 80;
	if (mw) t->width = mw;
	else if (tty) {
		int c = rst_num(getenv("COLUMNS"));
		if (!c) c = rst_termwidth();
		if (c) t->width = c;
	}
	if (width > 0) t->width = width;
	t->style = ROFFSUB_PLAIN;
	if (tty) {
		const char *cmd = 0;
		if (pg && *pg) cmd = pg;
		else if (rst_onpath("less")) cmd = "less";
		else if (rst_onpath("more")) cmd = "more";
		if (cmd && !rst_iscat(cmd)) {
			fflush(stdout);
			t->pipe = popen(cmd, "w");
		}
		if (t->pipe) { t->out = t->pipe; t->style = ROFFSUB_OVERSTRIKE; }
		else t->style = ROFFSUB_SGR;
		if (dumb) t->style = ROFFSUB_PLAIN;
	}
	if (envstyle >= 0) t->style = envstyle;
	if (style >= 0) t->style = style;
}

static int roffsub_tty_close(struct roffsub_tty *t)
{
	if (t->pipe) { int r = pclose(t->pipe); t->pipe = 0; t->out = stdout; return r; }
	fflush(stdout);
	return 0;
}

#endif /* ROFFSUB_TTY_H */
