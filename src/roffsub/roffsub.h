/* roffsub.h --- render roffsub records for a terminal (header-only)
 * roffsub r0.9
 * (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 *
 * C99.  Byte-for-byte the same output as roffsub-render.awk.
 *
 *   struct roffsub_opt o = { 80, ROFFSUB_PLAIN, "1", "4", 0, 0 };
 *   roffsub_render(records, stdout, &o);
 *
 * records: NULL-terminated array of record lines (no newline), as
 * written by roffsub-ir.awk and embedded by roffsub-gen.awk.
 */
#ifndef ROFFSUB_H
#define ROFFSUB_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef ROFFSUB_STYLES
#define ROFFSUB_STYLES
enum { ROFFSUB_PLAIN, ROFFSUB_OVERSTRIKE, ROFFSUB_SGR, ROFFSUB_PRE };
#endif

struct roffsub_opt {
	int width;              /* columns */
	int style;              /* ROFFSUB_PLAIN .. ROFFSUB_PRE */
	const char *sgrb;       /* SGR parameters for bold, "1" */
	const char *sgri;       /* SGR parameters for italic, "4" */
	int measure;            /* maximum line length, 0 for none */
	int heading;            /* section heading column offset, 0 */
};

/* ---- attributed strings: chars and one attribute byte per char ---- */

struct rs_s { char *c, *a; int n, cap; };

static void rs_grow(struct rs_s *s, int need)
{
	if (s->n + need + 1 <= s->cap) return;
	while (s->n + need + 1 > s->cap) s->cap = s->cap ? s->cap * 2 : 64;
	s->c = realloc(s->c, (size_t)s->cap);
	s->a = realloc(s->a, (size_t)s->cap);
	if (!s->c || !s->a) { fputs("roffsub: out of memory\n", stderr); exit(2); }
}
static void rs_put(struct rs_s *s, char c, char a)
{
	rs_grow(s, 1); s->c[s->n] = c; s->a[s->n] = a; s->n++;
	s->c[s->n] = 0; s->a[s->n] = 0;
}
static void rs_cat(struct rs_s *s, const struct rs_s *t)
{
	int i; for (i = 0; i < t->n; i++) rs_put(s, t->c[i], t->a[i]);
}
static void rs_catn(struct rs_s *s, const char *c, const char *a, int n)
{
	int i; for (i = 0; i < n; i++) rs_put(s, c[i], a[i]);
}
static void rs_sp(struct rs_s *s, int n) { while (n-- > 0) rs_put(s, ' ', 'R'); }
static void rs_rep(struct rs_s *s, char c, int n) { while (n-- > 0) rs_put(s, c, 'R'); }
static void rs_clear(struct rs_s *s) { s->n = 0; if (s->c) { s->c[0] = 0; s->a[0] = 0; } }
static void rs_free(struct rs_s *s) { free(s->c); free(s->a); s->c = s->a = 0; s->n = s->cap = 0; }

#define RS_NB '\001'

/* ---- renderer state ---- */

static FILE *rs_out;
static int rs_HO, rs_W, rs_WE, rs_U, rs_SSI, rs_S;
static const char *rs_SB, *rs_SI;
static int rs_L, rs_PI, rs_TI, rs_TL, rs_nfm, rs_started, rs_afterhead;
static int rs_hastag, rs_collect;
static struct rs_s rs_B, rs_T, rs_P;
static int rs_rsn, rs_rsl[64], rs_rsp[64];
static struct rs_s *rs_lines; static int rs_ln, rs_lcap;

static void rs_parse(const char *s, struct rs_s *p)
{
	char f = 'R', c;
	rs_clear(p);
	for (; *s; s++) {
		c = *s;
		if (c == '\\' && s[1]) {
			if (s[1] == 'f' && s[2]) { f = s[2]; s += 2; continue; }
			c = (s[1] == '~') ? RS_NB : s[1];
			s++;
		}
		rs_put(p, c, f);
	}
}

static void rs_promote(struct rs_s *p, char f)
{
	int i;
	if (f != 'B' && f != 'I') return;
	for (i = 0; i < p->n; i++) if (p->a[i] == 'R') p->a[i] = f;
}

static void rs_emit(const char *c, const char *a, int n)
{
	int i; char ch, at, cur = 'R';
	for (i = 0; i < n; i++) {
		ch = c[i]; at = a[i];
		if (ch == RS_NB) ch = ' ';
		if (rs_S == ROFFSUB_OVERSTRIKE) {
			if (ch != ' ' && at == 'B') { putc(ch, rs_out); putc('\b', rs_out); }
			else if (ch != ' ' && at == 'I') { putc('_', rs_out); putc('\b', rs_out); }
			putc(ch, rs_out);
			continue;
		}
		if (rs_S == ROFFSUB_SGR || rs_S == ROFFSUB_PRE) {
			if (at != cur) {
				if (rs_S == ROFFSUB_SGR) {
					if (cur != 'R') fputs("\033[0m", rs_out);
					if (at == 'B') fprintf(rs_out, "\033[%sm", rs_SB);
					else if (at == 'I') fprintf(rs_out, "\033[%sm", rs_SI);
				} else fprintf(rs_out, "\\f%c", at);
				cur = at;
			}
			if (rs_S == ROFFSUB_PRE && ch == '\\') putc('\\', rs_out);
		}
		putc(ch, rs_out);
	}
	if (cur != 'R') fputs(rs_S == ROFFSUB_SGR ? "\033[0m" : "\\fR", rs_out);
	putc('\n', rs_out);
}

static void rs_line(struct rs_s *l)
{
	while (l->n > 0 && l->c[l->n - 1] == ' ') { l->n--; l->c[l->n] = 0; l->a[l->n] = 0; }
	if (rs_collect) {
		if (rs_ln == rs_lcap) {
			rs_lcap = rs_lcap ? rs_lcap * 2 : 16;
			rs_lines = realloc(rs_lines, (size_t)rs_lcap * sizeof *rs_lines);
			if (!rs_lines) { fputs("roffsub: out of memory\n", stderr); exit(2); }
		}
		memset(&rs_lines[rs_ln], 0, sizeof *rs_lines);
		rs_cat(&rs_lines[rs_ln], l);
		rs_ln++;
		return;
	}
	rs_emit(l->c, l->a, l->n);
	rs_started = 1; rs_afterhead = 0;
}

static void rs_blank(void) { if (!rs_collect) { putc('\n', rs_out); rs_started = 1; } }

struct rs_w { int off, len; };

static int rs_words(const struct rs_s *s, struct rs_w **w)
{
	int i = 0, n = 0, cap = 0, st;
	*w = 0;
	while (i < s->n) {
		while (i < s->n && s->c[i] == ' ') i++;
		if (i >= s->n) break;
		st = i;
		while (i < s->n && s->c[i] != ' ') i++;
		if (n == cap) { cap = cap ? cap * 2 : 32; *w = realloc(*w, (size_t)cap * sizeof **w); }
		(*w)[n].off = st; (*w)[n].len = i - st; n++;
	}
	return n;
}

static int rs_nonblank(const struct rs_s *s)
{
	int i; for (i = 0; i < s->n; i++) if (s->c[i] != ' ') return 1;
	return 0;
}

static void rs_fill(const struct rs_s *s, const struct rs_s *pre, int ci, int lim)
{
	struct rs_w *w; struct rs_s l = {0};
	int n = rs_words(s, &w), i, empty = 1;
	rs_cat(&l, pre);
	for (i = 0; i < n; i++) {
		if (empty) { rs_catn(&l, s->c + w[i].off, s->a + w[i].off, w[i].len); empty = 0; }
		else if (l.n + 1 + w[i].len <= lim) {
			rs_put(&l, ' ', 'R'); rs_catn(&l, s->c + w[i].off, s->a + w[i].off, w[i].len);
		} else {
			rs_line(&l); rs_clear(&l); rs_sp(&l, ci);
			rs_catn(&l, s->c + w[i].off, s->a + w[i].off, w[i].len);
		}
	}
	if (!empty || rs_nonblank(&l)) rs_line(&l);
	rs_free(&l); free(w);
}

static void rs_vsp(void) { if (rs_started && !rs_afterhead) rs_blank(); }

static void rs_flush(void)
{
	struct rs_s pre = {0}, l = {0};
	if (rs_B.n == 0 && !rs_hastag) return;
	if (rs_hastag) {
		if (rs_T.n < rs_TI - rs_TL) {
			rs_sp(&pre, rs_TL); rs_cat(&pre, &rs_T); rs_sp(&pre, rs_TI - rs_TL - rs_T.n);
		} else {
			rs_sp(&l, rs_TL); rs_cat(&l, &rs_T); rs_line(&l);
			rs_sp(&pre, rs_TI);
		}
	} else rs_sp(&pre, rs_TI);
	rs_fill(&rs_B, &pre, rs_TI, rs_WE);
	rs_clear(&rs_B); rs_hastag = 0;
	rs_free(&pre); rs_free(&l);
}

static void rs_heading(const char *s, int ind)
{
	struct rs_s l = {0};
	rs_flush();
	if (rs_started) rs_blank();
	rs_parse(s, &rs_P); rs_promote(&rs_P, 'B');
	rs_sp(&l, ind); rs_cat(&l, &rs_P); rs_line(&l); rs_free(&l);
	rs_afterhead = 1;
	rs_L = rs_U; rs_PI = rs_U; rs_TI = rs_L; rs_TL = rs_L; rs_rsn = 0;
}

/* ---- tables ---- */

struct rs_fmt { int n; char *al, *f; int *w; };
struct rs_row { int rule, n; char **cell; };

static char *rs_topt;
static struct rs_fmt *rs_fmts; static int rs_tfn;
static struct rs_row *rs_rows; static int rs_trn;

static char *rs_dup(const char *s)
{
	char *d = malloc(strlen(s) + 1);
	if (!d) { fputs("roffsub: out of memory\n", stderr); exit(2); }
	return strcpy(d, s);
}

static int rs_hasword(const char *opt, const char *w)
{
	size_t n = strlen(w); const char *p = opt;
	while ((p = strstr(p, w))) {
		if ((p == opt || p[-1] == ' ') && (p[n] == 0 || p[n] == ' ')) return 1;
		p += n;
	}
	return 0;
}

static void rs_key(const char *k, struct rs_fmt *f, int i)
{
	const char *p;
	f->al[i] = strchr(k, 'r') ? 'r' : (strchr(k, 'c') ? 'c' : 'l');
	f->f[i] = strchr(k, 'b') ? 'B' : (strchr(k, 'i') ? 'I' : 'R');
	f->w[i] = 0;
	for (p = k; (p = strchr(p, 'w')); p++)
		if (p[1] == '(' && p[2] >= '0' && p[2] <= '9') {
			const char *q = p + 2; int v = 0;
			while (*q >= '0' && *q <= '9') v = v * 10 + (*q++ - '0');
			if (*q == 'n') q++;
			if (*q == ')') { f->w[i] = v; break; }
		}
}

static void rs_aligned(struct rs_s *dst, const struct rs_s *c, int w, char al)
{
	int pad = w - c->n, l;
	if (pad <= 0) { rs_cat(dst, c); return; }
	if (al == 'r') { rs_sp(dst, pad); rs_cat(dst, c); }
	else if (al == 'c') { l = pad / 2; rs_sp(dst, l); rs_cat(dst, c); rs_sp(dst, pad - l); }
	else { rs_cat(dst, c); rs_sp(dst, pad); }
}

static int rs_ncol, *rs_cw;

static void rs_rule(int x0)
{
	struct rs_s l = {0}; int i;
	rs_sp(&l, x0);
	for (i = 0; i < rs_ncol; i++) { if (i) rs_put(&l, '+', 'R'); rs_rep(&l, '-', rs_cw[i] + 2); }
	rs_line(&l); rs_free(&l);
}

static int rs_mincap(int n, int f, int cap) { int w = f > cap ? f : cap; return n < w ? n : w; }

static void rs_table(void)
{
	int box = rs_hasword(rs_topt, "box"), allbox = strstr(rs_topt, "allbox") != 0;
	int center = strstr(rs_topt, "center") != 0;
	int r, i, j, k, d, f, n, sumn = 0, sumf = 0, G, A, cap, s = 0, rem, prog, t, lw, x0, h;
	int *nat, *flo, *ord, *cnt;
	struct rs_s *CC; char *CAL; struct rs_w *w;
	struct rs_s **TLs;

	rs_ncol = 0;
	for (j = 0; j < rs_tfn; j++) if (rs_fmts[j].n > rs_ncol) rs_ncol = rs_fmts[j].n;
	nat = calloc((size_t)rs_ncol + 1, sizeof *nat); flo = calloc((size_t)rs_ncol + 1, sizeof *flo);
	ord = calloc((size_t)rs_ncol + 1, sizeof *ord); cnt = calloc((size_t)rs_ncol + 1, sizeof *cnt);
	rs_cw = calloc((size_t)rs_ncol + 1, sizeof *rs_cw);
	CC = calloc((size_t)(rs_trn * rs_ncol) + 1, sizeof *CC);
	CAL = calloc((size_t)(rs_trn * rs_ncol) + 1, 1);
	TLs = calloc((size_t)rs_ncol + 1, sizeof *TLs);

	d = 0;
	for (r = 0; r < rs_trn; r++) {
		if (rs_rows[r].rule) continue;
		d++; f = (d < rs_tfn ? d : rs_tfn) - 1;
		for (i = 0; i < rs_ncol; i++) {
			struct rs_s *c = &CC[r * rs_ncol + i];
			rs_parse(i < rs_rows[r].n ? rs_rows[r].cell[i] : "", c);
			rs_promote(c, i < rs_fmts[f].n ? rs_fmts[f].f[i] : 0);
			CAL[r * rs_ncol + i] = i < rs_fmts[f].n ? rs_fmts[f].al[i] : 'l';
			if (c->n > nat[i]) nat[i] = c->n;
			n = rs_words(c, &w);
			for (k = 0; k < n; k++) if (w[k].len > flo[i]) flo[i] = w[k].len;
			free(w);
		}
	}
	for (j = 0; j < rs_tfn; j++) for (i = 0; i < rs_fmts[j].n; i++) {
		if (rs_fmts[j].w[i] > flo[i]) flo[i] = rs_fmts[j].w[i];
		if (rs_fmts[j].w[i] > nat[i]) nat[i] = rs_fmts[j].w[i];
	}
	for (i = 0; i < rs_ncol; i++) { sumn += nat[i]; sumf += flo[i]; }
	G = 3 * (rs_ncol - 1) + 2;
	A = rs_WE - rs_TI - G;
	if (sumn <= A) {
		for (i = 0; i < rs_ncol; i++) rs_cw[i] = nat[i];
	} else if (sumf > A) {
		/* records */
		int first = 0, nrow = 0;
		struct rs_s *lab = calloc((size_t)rs_ncol + 1, sizeof *lab);
		if (rs_trn >= 2 && !rs_rows[0].rule && rs_rows[1].rule) {
			for (i = 0; i < rs_ncol; i++) rs_cat(&lab[i], &CC[i]);
			first = 2;
		} else for (i = 0; i < rs_ncol; i++) {
			char b[16]; int m; snprintf(b, sizeof b, "%d", i + 1);
			for (m = 0; b[m]; m++) rs_put(&lab[i], b[m], 'R');
		}
		for (r = first; r < rs_trn; r++) {
			if (rs_rows[r].rule) continue;
			if (nrow++) rs_blank();
			for (i = 0; i < rs_ncol; i++) {
				struct rs_s c = {0}, pre = {0};
				rs_cat(&c, &lab[i]); rs_put(&c, ':', 'R'); rs_put(&c, ' ', 'R');
				rs_cat(&c, &CC[r * rs_ncol + i]);
				rs_sp(&pre, rs_TI);
				rs_fill(&c, &pre, rs_TI + 2, rs_WE);
				rs_free(&c); rs_free(&pre);
			}
		}
		for (i = 0; i < rs_ncol; i++) rs_free(&lab[i]);
		free(lab);
		goto done;
	} else {
		for (cap = sumn; cap >= 0; cap--) {
			s = 0;
			for (i = 0; i < rs_ncol; i++) s += rs_mincap(nat[i], flo[i], cap);
			if (s <= A) break;
		}
		for (i = 0; i < rs_ncol; i++) { rs_cw[i] = rs_mincap(nat[i], flo[i], cap); ord[i] = i; }
		for (i = 0; i < rs_ncol; i++) for (j = i + 1; j < rs_ncol; j++)
			if (nat[ord[j]] > nat[ord[i]]) { t = ord[i]; ord[i] = ord[j]; ord[j] = t; }
		rem = A - s;
		while (rem > 0) {
			prog = 0;
			for (k = 0; k < rs_ncol && rem > 0; k++) {
				i = ord[k];
				if (rs_cw[i] < nat[i]) { rs_cw[i]++; rem--; prog = 1; }
			}
			if (!prog) break;
		}
	}
	lw = G; for (i = 0; i < rs_ncol; i++) lw += rs_cw[i];
	x0 = rs_TI;
	if (center && rs_WE - rs_TI > lw) x0 = rs_TI + (rs_WE - rs_TI - lw) / 2;
	if (box || allbox) rs_rule(x0);
	for (r = 0; r < rs_trn; r++) {
		if (rs_rows[r].rule) { if (!allbox) rs_rule(x0); continue; }
		h = 0;
		for (i = 0; i < rs_ncol; i++) {
			struct rs_s empty = {0};
			rs_collect = 1; rs_ln = 0;
			rs_fill(&CC[r * rs_ncol + i], &empty, 0, rs_cw[i]);
			rs_collect = 0;
			cnt[i] = rs_ln;
			TLs[i] = rs_lines; rs_lines = 0; rs_lcap = 0;
			if (rs_ln > h) h = rs_ln;
		}
		for (k = 0; k < h; k++) {
			struct rs_s l = {0}, e = {0};
			rs_sp(&l, x0);
			for (i = 0; i < rs_ncol; i++) {
				if (i) rs_put(&l, ' ', 'R');
				rs_put(&l, ' ', 'R');
				if (k < cnt[i]) rs_aligned(&l, &TLs[i][k], rs_cw[i], CAL[r * rs_ncol + i]);
				else rs_aligned(&l, &e, rs_cw[i], 'l');
				rs_put(&l, ' ', 'R');
			}
			rs_line(&l); rs_free(&l);
		}
		for (i = 0; i < rs_ncol; i++) {
			for (k = 0; k < cnt[i]; k++) rs_free(&TLs[i][k]);
			free(TLs[i]); TLs[i] = 0;
		}
		if (allbox) rs_rule(x0);
	}
	if (box && !allbox) rs_rule(x0);
done:
	for (i = 0; i < rs_trn * rs_ncol; i++) rs_free(&CC[i]);
	free(CC); free(CAL); free(nat); free(flo); free(ord); free(cnt); free(rs_cw); free(TLs);
	rs_cw = 0;
}

static void rs_table_free(void)
{
	int r, i;
	for (r = 0; r < rs_trn; r++) {
		for (i = 0; i < rs_rows[r].n; i++) free(rs_rows[r].cell[i]);
		free(rs_rows[r].cell);
	}
	for (i = 0; i < rs_tfn; i++) { free(rs_fmts[i].al); free(rs_fmts[i].f); free(rs_fmts[i].w); }
	free(rs_rows); free(rs_fmts); free(rs_topt);
	rs_rows = 0; rs_fmts = 0; rs_topt = 0; rs_trn = rs_tfn = 0;
}

/* ---- records ---- */

/* split a record into fields at TAB; returns count; fields point into buf */
static int rs_fields(char *buf, char ***fp)
{
	int n = 1, cap = 8; char *p; char **f = malloc((size_t)cap * sizeof *f);
	f[0] = buf;
	for (p = buf; *p; p++) if (*p == '\t') {
		*p = 0;
		if (n == cap) { cap *= 2; f = realloc(f, (size_t)cap * sizeof *f); }
		f[n++] = p + 1;
	}
	*fp = f;
	return n;
}

static int roffsub_render(const char *const *rec, FILE *out, const struct roffsub_opt *o)
{
	int nf, i;
	char *buf, **f;

	rs_out = out;
	rs_W = o->width > 0 ? o->width : 80;
	rs_S = o->style;
	rs_SB = o->sgrb && *o->sgrb ? o->sgrb : "1";
	rs_SI = o->sgri && *o->sgri ? o->sgri : "4";
	rs_WE = (o->measure > 0 && o->measure < rs_W) ? o->measure : rs_W;
	rs_HO = o->heading > 0 ? o->heading : 0;
	rs_U = rs_WE < 60 ? 4 : 7;
	rs_SSI = rs_U / 2;
	rs_L = 0; rs_PI = rs_U; rs_TI = 0; rs_TL = 0; rs_rsn = 0;
	rs_nfm = 0; rs_started = 0; rs_afterhead = 0; rs_hastag = 0; rs_collect = 0;
	rs_clear(&rs_B); rs_clear(&rs_T);

	for (; *rec; rec++) {
		buf = rs_dup(*rec);
		nf = rs_fields(buf, &f);
#define F(k) ((k) < nf ? f[k] : "")
		if (!strcmp(f[0], "v")) {
			if (atoi(F(1)) != 1) {
				fprintf(stderr, "roffsub: unsupported record version %s\n", F(1));
				free(f); free(buf); return 2;
			}
		} else if (!strcmp(f[0], "sh")) rs_heading(F(1), rs_HO);
		else if (!strcmp(f[0], "ss")) rs_heading(F(1), rs_SSI);
		else if (!strcmp(f[0], "pp")) { rs_flush(); rs_vsp(); rs_PI = rs_U; rs_TI = rs_L; rs_TL = rs_L; }
		else if (!strcmp(f[0], "tp") || !strcmp(f[0], "ip")) {
			rs_flush(); rs_vsp();
			if (*F(1)) rs_PI = atoi(F(1));
			rs_TL = rs_L; rs_TI = rs_L + rs_PI;
			rs_hastag = !strcmp(f[0], "tp") || *F(2);
			rs_parse(F(2), &rs_T);
		} else if (!strcmp(f[0], "rs")) {
			rs_flush();
			if (rs_rsn < 63) { rs_rsn++; rs_rsl[rs_rsn] = rs_L; rs_rsp[rs_rsn] = rs_PI; }
			rs_L += *F(1) ? atoi(F(1)) : rs_PI;
			rs_PI = rs_U; rs_TI = rs_L; rs_TL = rs_L;
		} else if (!strcmp(f[0], "re")) {
			rs_flush();
			if (rs_rsn > 0) { rs_L = rs_rsl[rs_rsn]; rs_PI = rs_rsp[rs_rsn]; rs_rsn--; }
			rs_TI = rs_L; rs_TL = rs_L;
		} else if (!strcmp(f[0], "nf")) { rs_flush(); rs_nfm = 1; }
		else if (!strcmp(f[0], "fi")) { rs_flush(); rs_nfm = 0; }
		else if (!strcmp(f[0], "br")) rs_flush();
		else if (!strcmp(f[0], "sp")) {
			int n = atoi(F(1));
			rs_flush(); while (n-- > 0) rs_blank(); rs_afterhead = 0;
		} else if (!strcmp(f[0], "ts")) {
			rs_flush(); rs_table_free(); rs_topt = rs_dup(F(1));
		} else if (!strcmp(f[0], "tf")) {
			struct rs_fmt *m;
			rs_fmts = realloc(rs_fmts, (size_t)(rs_tfn + 1) * sizeof *rs_fmts);
			m = &rs_fmts[rs_tfn++];
			m->n = nf - 1;
			m->al = malloc((size_t)nf); m->f = malloc((size_t)nf); m->w = malloc((size_t)nf * sizeof *m->w);
			for (i = 1; i < nf; i++) rs_key(f[i], m, i - 1);
		} else if (!strcmp(f[0], "tr") || !strcmp(f[0], "t_")) {
			struct rs_row *w; int n, k0 = rs_tfn ? rs_fmts[0].n : 0;
			rs_rows = realloc(rs_rows, (size_t)(rs_trn + 1) * sizeof *rs_rows);
			w = &rs_rows[rs_trn++];
			w->rule = f[0][1] == '_';
			n = w->rule ? 0 : (nf - 1 > k0 ? nf - 1 : k0);
			w->n = n;
			w->cell = malloc((size_t)(n + 1) * sizeof *w->cell);
			for (i = 0; i < n; i++) w->cell[i] = rs_dup(i + 1 < nf ? f[i + 1] : "");
		} else if (!strcmp(f[0], "te")) { if (rs_topt) rs_table(); rs_table_free(); }
		else if (!strcmp(f[0], "tx")) {
			rs_parse(F(1), &rs_P);
			if (rs_nfm) {
				struct rs_s l = {0};
				if (rs_hastag) rs_flush();
				rs_sp(&l, rs_TI); rs_cat(&l, &rs_P); rs_line(&l); rs_free(&l);
			} else {
				if (rs_B.n) rs_put(&rs_B, ' ', 'R');
				rs_cat(&rs_B, &rs_P);
			}
		}
#undef F
		free(f); free(buf);
	}
	rs_flush();
	rs_table_free();
	return 0;
}

#endif /* ROFFSUB_H */
