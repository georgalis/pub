/* roffsub-emit.h --- emit pre-formatted roffsub text (header-only)
 * roffsub r0.9
 * (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
 *
 * C99.  Byte-for-byte the same output as roffsub-emit.awk.  Lines carry
 * only \fB \fI \fR and \\ (roffsub-render.awk -v S=pre).
 */
#ifndef ROFFSUB_EMIT_H
#define ROFFSUB_EMIT_H

#include <stdio.h>

#ifndef ROFFSUB_STYLES
#define ROFFSUB_STYLES
enum { ROFFSUB_PLAIN, ROFFSUB_OVERSTRIKE, ROFFSUB_SGR, ROFFSUB_PRE };
#endif

static void roffsub_emit_line(const char *s, FILE *out, int style, const char *sb, const char *si)
{
	char cur = 'R', f = 'R', ch;
	for (; *s; s++) {
		ch = *s;
		if (ch == '\\' && s[1]) {
			if (s[1] == 'f' && s[2]) { f = s[2]; s += 2; continue; }
			ch = *++s;
		}
		if (style == ROFFSUB_OVERSTRIKE) {
			if (ch != ' ' && f == 'B') { putc(ch, out); putc('\b', out); }
			else if (ch != ' ' && f == 'I') { putc('_', out); putc('\b', out); }
			putc(ch, out);
			continue;
		}
		if (style == ROFFSUB_SGR && f != cur) {
			if (cur != 'R') fputs("\033[0m", out);
			if (f == 'B') fprintf(out, "\033[%sm", sb && *sb ? sb : "1");
			else if (f == 'I') fprintf(out, "\033[%sm", si && *si ? si : "4");
			cur = f;
		}
		putc(ch, out);
	}
	if (cur != 'R') fputs("\033[0m", out);
	putc('\n', out);
}

static void roffsub_emit(const char *const *lines, FILE *out, int style, const char *sb, const char *si)
{
	for (; *lines; lines++) roffsub_emit_line(*lines, out, style, sb, si);
}

#endif /* ROFFSUB_EMIT_H */
