# makefile --- build, test and install asciixlate
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6af37686 20261110 115446 PST Tue 11:54 AM 10 Nov 2026
#     2.1.0: cksh package layout; man page sections from --help; PREFIX
#     default by uid; replaces Makefile and its tests/run.sh check target.
# rev 6a9f4e20 20260907 165200 PDT Mon 04:52 PM 07 Sep 2026
#     2.0.0: dialect-neutral rules, platform test in the recipe shell.
#
# Written for the intersection of GNU make, bmake, pmake and Apple make:
# no ifeq, no $(shell ...), no ?=. The platform test runs in the recipe
# shell, where $$ escapes a shell variable identically for every dialect.
#
#   make                       ./asciixlate and ./asciixlate.1
#   make test                  regression suite (test.sh)
#   make install [PREFIX=dir]  PREFIX defaults to /usr/local for root, else $HOME
#   make table                 regenerate translit_table.h (python3, glibc iconv)
#   make CC=clang              compiler override
#
# Linux and NetBSD link static. Darwin ships no static libSystem and does not
# support -static; there the binary links libSystem alone, which is the
# ceiling on that platform.

CC = cc
CFLAGS = -std=c99 -Wall -Wextra -Wpedantic -O2
LDFLAGS =
PREFIX =
DESTDIR =

all: asciixlate asciixlate.1

asciixlate.o: asciixlate.c translit_table.h
	$(CC) $(CFLAGS) -c -o asciixlate.o asciixlate.c

asciixlate: asciixlate.o
	@case `uname -s` in Darwin) st= ;; *) st=-static ;; esac; \
	set -x; $(CC) $(LDFLAGS) $$st -o asciixlate asciixlate.o

# man page derived from --help so the two cannot disagree
asciixlate.1: asciixlate
	{ echo '.TH ASCIIXLATE 1'; ./asciixlate --help | awk '/^[A-Z][A-Z ]*$$/ { print ".SH " $$0; print ".nf"; next } { gsub(/\\/, "\\e"); if (substr($$0, 1, 1) == ".") $$0 = "\\&" $$0; print }'; echo '.fi'; } > asciixlate.1.tmp
	mv asciixlate.1.tmp asciixlate.1

test: asciixlate
	sh ./test.sh

# Not part of an ordinary build: the checked-in translit_table.h is the
# authority. Regenerate only to audit a Unicode upgrade, then diff. The
# seeding step reads glibc transliteration, so this runs on a glibc host
# only; elsewhere it stops before mktable.py and writes nothing.
table:
	@iconv --version 2>/dev/null | grep -q -e GLIBC -e 'GNU libc)' || { echo "table: mktable.py needs a glibc iconv(1) to seed the table; translit_table.h is unchanged" >&2; exit 1; }
	python3 mktable.py

install: all
	@p='$(PREFIX)'; [ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; }; \
	case "$$p$(DESTDIR)" in *[!A-Za-z0-9._/+-]*) echo "install: unsafe path '$$p'" >&2; exit 1 ;; esac; \
	m=man; [ -d "$$p/share/man" ] && m=share/man; \
	d='$(DESTDIR)'; set -x; \
	mkdir -p "$$d$$p/bin" "$$d$$p/$$m/man1" && \
	cp asciixlate "$$d$$p/bin/asciixlate" && chmod 755 "$$d$$p/bin/asciixlate" && \
	cp asciixlate.1 "$$d$$p/$$m/man1/asciixlate.1" && chmod 644 "$$d$$p/$$m/man1/asciixlate.1"

clean:
	rm -f asciixlate asciixlate.o asciixlate.1 asciixlate.1.tmp

.PHONY: all test table install clean
