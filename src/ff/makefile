# makefile --- build, test and install ff
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
#     C build, test and install for ff, from the cksh makefile
#
# Portable across GNU make, bmake (NetBSD, pkgsrc) and Apple make: no ifeq,
# no $(shell), no ?=; platform branching happens inside recipe shells.
# No third-party libraries on any platform. Linux and NetBSD link -static,
# falling back to dynamic when no static libc is installed. Darwin has no
# static libSystem, so the binary links dynamically against libSystem only.
#
#   make                       build ./ff and ./ff.1
#   make test                  regression suite (test.sh)
#   make install [PREFIX=dir]  PREFIX defaults to /usr/local for root, else $HOME
#   make CC=$LOCALBASE/bin/gcc toolchain override, e.g. pkgsrc gcc

FFFLAGS = -std=c99 -Wall -Wextra -Wpedantic -O2
PREFIX =
DESTDIR =

all: ff ff.1

ff.o: ff.c
	$(CC) $(FFFLAGS) $(CFLAGS) -c -o ff.o ff.c

ff: ff.o
	@st=-static; case `uname -s` in Darwin) st= ;; esac; \
	echo "$(CC) $$st -o ff ff.o $(LDFLAGS)"; \
	$(CC) $$st -o ff ff.o $(LDFLAGS) 2>/dev/null || { \
	  echo "static link unavailable, linking dynamically"; \
	  $(CC) -o ff ff.o $(LDFLAGS); }

# man page derived from --help so the two cannot disagree
ff.1: ff
	{ echo '.TH FF 1'; ./ff --help | awk '/^[A-Z][A-Z ]*$$/ { print ".SH " $$0; print ".nf"; next } { gsub(/\\/, "\\e"); if (substr($$0, 1, 1) == ".") $$0 = "\\&" $$0; print }'; echo '.fi'; } > ff.1.tmp
	mv ff.1.tmp ff.1

test: ff
	sh ./test.sh

install: all
	@p='$(PREFIX)'; [ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; }; \
	case "$$p$(DESTDIR)" in *[!A-Za-z0-9._/+-]*) echo "install: unsafe path '$$p'" >&2; exit 1 ;; esac; \
	m=man; [ -d "$$p/share/man" ] && m=share/man; \
	d='$(DESTDIR)'; set -x; \
	mkdir -p "$$d$$p/bin" "$$d$$p/$$m/man1" "$$d$$p/share/ff" && \
	cp ff "$$d$$p/bin/ff" && chmod 755 "$$d$$p/bin/ff" && \
	cp ff.1 "$$d$$p/$$m/man1/ff.1" && chmod 644 "$$d$$p/$$m/man1/ff.1" && \
	cp ff.fn.bash "$$d$$p/share/ff/ff.fn.bash" && chmod 644 "$$d$$p/share/ff/ff.fn.bash"

clean:
	rm -f ff ff.o ff.1 ff.1.tmp

.PHONY: all test install clean
