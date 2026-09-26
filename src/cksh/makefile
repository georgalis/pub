# makefile --- build, test and install cksh
# rev 6ab75454 20260926
# (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# Portable across GNU make, bmake (NetBSD, pkgsrc) and Apple make: no ifeq,
# no $(shell), no ?=; platform branching happens inside recipe shells.
# No third-party libraries on any platform. Linux and NetBSD link -static,
# falling back to dynamic when no static libc is installed. Darwin has no
# static libSystem, so the binary links dynamically against libSystem only.
#
#   make                       build ./cksh and ./cksh.1
#   make test                  regression suite (test.sh)
#   make install [PREFIX=dir]  PREFIX defaults to $LOCALBASE (pkgsrc), else /usr/local
#   make CC=$LOCALBASE/bin/gcc toolchain override, e.g. pkgsrc gcc

CKFLAGS = -std=c99 -Wall -Wextra -Wpedantic -O2
PREFIX =
DESTDIR =

all: cksh cksh.1

cksh.o: cksh.c
	$(CC) $(CKFLAGS) $(CFLAGS) -c -o cksh.o cksh.c

cksh: cksh.o
	@st=-static; case `uname -s` in Darwin) st= ;; esac; \
	echo "$(CC) $$st -o cksh cksh.o $(LDFLAGS)"; \
	$(CC) $$st -o cksh cksh.o $(LDFLAGS) 2>/dev/null || { \
	  echo "static link unavailable, linking dynamically"; \
	  $(CC) -o cksh cksh.o $(LDFLAGS); }

# man page derived from --help so the two cannot disagree
cksh.1: cksh
	{ echo '.TH CKSH 1'; ./cksh --help | awk '/^[A-Z][A-Z ]*$$/ { print ".SH " $$0; print ".nf"; next } { gsub(/\\/, "\\e"); if (substr($$0, 1, 1) == ".") $$0 = "\\&" $$0; print }'; echo '.fi'; } > cksh.1.tmp
	mv cksh.1.tmp cksh.1

test: cksh
	sh ./test.sh

install: all
	@p='$(PREFIX)'; [ -n "$$p" ] || p='$(LOCALBASE)'; [ -n "$$p" ] || p=/usr/local; \
	case "$$p$(DESTDIR)" in *[!A-Za-z0-9._/+-]*) echo "install: unsafe path '$$p'" >&2; exit 1 ;; esac; \
	m=man; [ -d "$$p/share/man" ] && m=share/man; \
	d='$(DESTDIR)'; set -x; \
	mkdir -p "$$d$$p/bin" "$$d$$p/$$m/man1" "$$d$$p/share/cksh" && \
	cp cksh "$$d$$p/bin/cksh" && chmod 755 "$$d$$p/bin/cksh" && \
	cp cksh.1 "$$d$$p/$$m/man1/cksh.1" && chmod 644 "$$d$$p/$$m/man1/cksh.1" && \
	cp cksh.fn.bash "$$d$$p/share/cksh/cksh.fn.bash" && chmod 644 "$$d$$p/share/cksh/cksh.fn.bash"

clean:
	rm -f cksh cksh.o cksh.1 cksh.1.tmp

.PHONY: all test install clean
