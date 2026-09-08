# asciixlate --- portable to GNU make, BSD make (bmake/pmake) and Apple's
# make. There are no conditionals and no $(shell ...): both are dialect-
# specific. The platform test happens in the recipe shell instead, where
# $$ escapes a shell variable identically for every make in use.

PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
MANDIR  ?= $(PREFIX)/share/man/man1
CC      ?= cc
CFLAGS  ?= -O2 -Wall -Wextra -std=c99
VERSION  = 2.0.0

all: asciixlate

# Linux and NetBSD link fully static. Darwin ships no static libSystem and
# does not support -static, so there it links libSystem alone --- no
# third-party dylib, which is the real ceiling on that platform.
asciixlate: asciixlate.c translit_table.h
	@case `uname -s` in \
	  Darwin) ld= ;; \
	  *)      ld=-static ;; \
	esac; \
	echo "$(CC) $(CFLAGS) -o $@ asciixlate.c $$ld"; \
	$(CC) $(CFLAGS) -o $@ asciixlate.c $$ld

# Regenerating the table needs python3 and a glibc iconv(1); it is not part
# of an ordinary build. The checked-in translit_table.h is the authority.
# Regenerate only to audit a Unicode upgrade, then diff the result.
table:
	python3 mktable.py

check: asciixlate
	sh tests/run.sh

# One manual, held in the binary. The man page is derived from it, so the
# two cannot disagree.
asciixlate.1: asciixlate
	@{ echo '.TH ASCIIXLATE 1 "" "asciixlate $(VERSION)" "User Commands"'; \
	   echo '.nf'; \
	   ./asciixlate --help | sed -e 's/^\./\\\&./'; \
	   echo '.fi'; } > $@

install: asciixlate asciixlate.1
	mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)
	cp asciixlate $(DESTDIR)$(BINDIR)/asciixlate
	chmod 0755 $(DESTDIR)$(BINDIR)/asciixlate
	cp asciixlate.1 $(DESTDIR)$(MANDIR)/asciixlate.1
	chmod 0644 $(DESTDIR)$(MANDIR)/asciixlate.1

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/asciixlate $(DESTDIR)$(MANDIR)/asciixlate.1

clean:
	rm -f asciixlate asciixlate.1

.PHONY: all table check install uninstall clean
