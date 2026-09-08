Good to know — I've noted that preference. Worth flagging the underlying behavior so it's clear why a one-liner alone won't do it:

On glibc 2.43, `iconv -f utf-8 -t ascii//TRANSLIT` already transliterates em-dash `—` (U+2014), but to **two** hyphens `--`, not three. So you can't get `---` purely from `iconv` — you need a second pass. Since `--` can legitimately occur in plain ASCII text, the safest approach is to pipe the transliteration output through `sed` to specifically target the em-dash:

```bash
iconv -f utf-8 -t ascii//TRANSLIT | sed 's/--/---/g'
```

**But** that's risky because it turns every `--` into `---` — including ones in the source. To avoid that, either transliterate em-dash yourself before `iconv`'s own handling kicks in, or drop the `//TRANSLIT` flag entirely and translate the specific characters you care about:

```bash
iconv -f utf-8 -t ascii//TRANSLIT | sed 's/--/---/g'        # too aggressive
sed 's/\xe2\x80\x94/---/g' | iconv -f utf-8 -c -t ascii      # targeted
```

The second option is the cleanest fit for what you described — you keep `//TRANSLIT` doing its job for other unicode characters (curly quotes etc.) while em-dash becomes `---` specifically. If you want to preserve all other transliteration behavior, just do both passes:

```bash
sed 's/\xe2\x80\x94/---/g' | iconv -f utf-8 -c -t ascii//TRANSLIT
```

Want me to check how that handles the related dashes (U+2013 en-dash and U+2E3A two-em-dash) too?

---



Good — that confirms it's the standard U+2014, so the earlier regex was already matching it correctly. Let me address both parts of your question properly.

## There is no custom transliteration table in iconv

Correct — glibc's `iconv` does not expose a way to customize or override the `//TRANSLIT` mappings. The transliteration rules are compiled into glibc itself, stored in locale definition files, and there's no runtime flag or config file to extend or override individual character mappings. You can pick a different target locale (e.g. `ascii//TRANSLIT` vs. a specific locale), but you can't edit the table. So em-dash→`--` is hardwired; the only way to change it is a separate transformation pass.

## Why sed/awk on non-ASCII is risky, and how to avoid the irregularities

Your instinct is right. The classic pitfalls when running `sed`/`awk` over UTF-8 bytes:

1. **Locale-dependent matching** — under a non-UTF-8 locale, `sed` treats bytes individually, so a multibyte character like `—` (`e2 80 94`) can be split across a line or matched incompletely, producing broken output.
2. **GNU `sed` byte vs. character mode** — with `LC_ALL=C`, sed operates on raw bytes (safe for exact-match, but `.` won't span the multibyte sequence as one unit); with a UTF-8 locale, `.` matches a whole character but some pattern features behave inconsistently across versions.
3. **In-place re-encoding** — if sed's output locale differs from input, you can corrupt bytes.

The clean way to **sidestep all of this** is to match the raw UTF-8 byte sequence explicitly and force a byte-oriented (C) locale, so sed never tries to interpret the bytes as characters at all:

```bash
LC_ALL=C sed 's/\xe2\x80\x94/---/g'
```

Here `\xe2\x80\x94` is the exact 3-byte UTF-8 encoding of U+2014, and `LC_ALL=C` guarantees sed treats the stream as raw bytes — no locale interpretation, no multibyte splitting, no irregularities. The replacement `---` is plain ASCII, so there's no re-encoding risk on output either.

## Putting it together

To keep `iconv`'s transliteration for everything else (curly quotes, etc.) while forcing em-dash to `---`:

```bash
LC_ALL=C sed 's/\xe2\x80\x94/---/g' | iconv -f utf-8 -c -t ascii//TRANSLIT
```

The `sed` pass runs first on the still-UTF-8 input (safe, because it's byte-exact under `LC_ALL=C`), then `iconv` handles the rest of the transliteration. If you also want to catch the **en dash** (U+2013, `—`'s narrower sibling, `e2 80 93`) and map it to `--`:

```bash
LC_ALL=C sed 's/\xe2\x80\x94/---/g; s/\xe2\x80\x93/--/g' | iconv -f utf-8 -c -t ascii//TRANSLIT
```

Want me to add the two-em dash (U+2E3A) or figure dash (U+2012) to that chain as well?

---


## Discussion and viability

**Is there a custom iconv translation table?** No. glibc's `//TRANSLIT` rules are compiled into the C library from locale definition files, and there's no runtime config file, env var, or flag to override individual mappings. Em-dash→`--` and U+2E3A→`?` are hardwired. So the only way to customize transliteration is to wrap iconv with your own pre-processing pass — which is what `asciixlate` does.

**Why not sed/awk for that pass?** Exactly the irregularities you mentioned: under a non-UTF-8 locale, `sed` can split a multibyte character across a buffer boundary and match it incompletely; under a UTF-8 locale, `.` and pattern features behave inconsistently across GNU/BSD versions; and mismatched I/O locales corrupt bytes. The C filter sidesteps all of this by matching exact byte sequences under `LC_ALL=C` — no locale interpretation, no character splitting, deterministic everywhere.

**Architecture:** two-stage pipeline — (1) apply the user's extension table to the raw UTF-8 byte stream, replacing whole multibyte sequences wholesale; (2) pass the result through `iconv("utf-8","ascii//TRANSLIT")` for everything else (curly quotes, etc.). Replacement output bytes are never re-scanned, so a rule producing bytes that resemble another rule's pattern is safe.

**Static linking on Darwin — the honest answer.** macOS does **not** ship `libiconv.a` (no static lib in the SDK or Xcode — only `libiconv.2.tbd`/`.dylib`). So a *truly* static, zero-dependency binary is impossible without pulling in Homebrew's keg-only `libiconv.a`, which is heavy and conflicts with the system iconv. The practical alternative — dynamic link against the system `libiconv.2.dylib` — is effectively universal: that dylib ships with every macOS version and is part of the OS, never a separate install. So "single .c in, single binary out, works on any stock Mac" is achieved; "zero dynamic library dependencies" is not, and isn't worth the Homebrew detour just for dash transliteration. On Linux, glibc has iconv in libc, so no `-liconv` is needed at all.

## The code

Built and tested. Verified outputs:

| Input | Bytes | Output |
|---|---|---|
| U+2014 EM DASH | `e2 80 94` | `---` |
| U+2013 EN DASH | `e2 80 93` | `--` |
| U+2E3A TWO-EM DASH | `e2 b8 ba` | `----` |
| U+2012 FIGURE DASH | `e2 80 92` | `-` |
| U+201C/201D curly quotes | — | `"` `"` (via iconv) |

Mixed run: `"hello" --- -- ---- - end` — exactly right.

The source is a single self-contained file with the help text and built-in default table baked in (so `--help` and `--list` work with no external files). I shared it above as `asciixlate.c`.

## Build and use

```bash
# macOS (system toolchain, system libiconv — nothing extra to install):
cc -O2 -Wall -Wextra -o asciixlate asciixlate.c

# Linux (glibc, iconv is in libc):
cc -O2 -Wall -Wextra -o asciixlate asciixlate.c
```

```bash
asciixlate < in.txt > out.txt                       # defaults only
asciixlate -v -c myrules.txt in.txt out.txt         # with config, verbose
asciixlate -l                                       # list active rules
```

Config file (overrides defaults for the same code point):

```
U+2014        ---       # EM DASH
U+2013        --        # EN DASH
U+2E3A        ----      # TWO-EM DASH
U+2012        -         # FIGURE DASH
U+00A9        (c) Copyright
```

The `-l` flag shows the active table (defaults plus any config overrides), `--help` prints the full usage, and both are compiled into the binary — no man page or external doc file needed. If you'd like, I can also add U+2015 (horizontal bar), U+2010–U+2011 (the hyphen variants), or a `--strict` mode that errors instead of emitting `?` for untranslatable bytes.

---




All four requested features are in. Here's the summary.

## What's new

**Yes, it reads a local config file.** Discovery priority (first match wins):
1. `-c FILE` / `--config=FILE` (explicit; a missing file here is a fatal error)
2. `$ASCIIXLATE_CONFIG` env var (exported; points at a file)
3. `~/.asciixlate` (auto-loaded; a missing file is silently ignored)

User rules override built-in defaults for the same code point.

**New built-in defaults** (added to the table):

| Code point | Name | Output |
|---|---|---|
| U+2015 | HORIZONTAL BAR | `--` |
| U+2011 | NON-BREAKING HYPHEN | `-` |
| U+2010 | HYPHEN | `-` |
| U+00AD | SOFT HYPHEN | (dropped — empty replacement) |

**`--strict` / `-s`**: aborts with a message naming the code point (e.g. `untranslatable character U+F8FF at input offset 1`) and exits 2. Also fires on invalid UTF-8 bytes.

**`??` for untranslatable bytes** (the default): this required a real fix. The earlier version couldn't actually detect these — iconv's `//TRANSLIT` silently emits `?` for characters it can't transliterate (U+F8FF, U+FFFF, etc.) and returns success, indistinguishable from a literal `?` in the input. So I rewrote the converter to decode UTF-8 code points itself and run iconv per-code-point, which lets it tell "iconv produced `?` because it couldn't transliterate this character" apart from "the input had a literal `?`". Verified: `printf 'a?b'` → `a?b` (single, preserved), but U+F8FF → `??` (doubled, locatable).

The three untranslatable modes are mutually exclusive in priority: `--strict` (error) > default (`??`) > `--ignore` (drop). `-s` and `-I` together are rejected with exit 1.

## Build (unchanged)

```bash
cc -O2 -Wall -Wextra -o asciixlate asciixlate.c   # macOS or Linux, no extra libs
```

Help and the rule table are baked into the binary (`--help`, `--list`), so it's still a single self-contained file with no external man page. The updated source is shared above as `asciixlate.c`.

One honest caveat worth flagging: the untranslatable detection works by feeding each non-ASCII code point to iconv individually and checking whether it produced exactly `?`. This is reliable for the common case, but if a future iconv version started transliterating some character *to* a literal `?` that it currently can't, that character would be misreported as untranslatable. For the dash/quote characters you actually care about this isn't a risk — they all have real transliterations — but I'd avoid relying on the `??`/`--strict` behavior for exotic private-use code points as a hard guarantee.
