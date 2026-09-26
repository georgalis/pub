# makefile --- build, test and install cksh
# (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6ab7e734 20260926 083932 PDT Sat 08:39 AM 26 Sep 2026
#     C build, test and install for the cksh port
# rev 68e9ff40 20251010 235456 PDT Fri 11:54 PM 10 Oct 2025
#     -0..-5, bare -n and -x (getopts :), -n and -x range validation
# rev 68e20bca 20251004 231018 PDT Sat 11:10 PM 04 Oct 2025
#     renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired
# rev 677c9c44 20250106 191516 PST Mon 07:15 PM 06 Jan 2025
#     chksthash, from ckstatsum: shake256 -xoflen 3 hash column
# org 6305e87b 20220824 015939 PDT Wed 01:59 AM 24 Aug 2022 ckstat ckstatsum cks
#
# Portable across GNU make, bmake (NetBSD, pkgsrc) and Apple make: no ifeq,
# no $(shell), no ?=; platform branching happens inside recipe shells.
# No third-party libraries on any platform. Linux and NetBSD link -static,
# falling back to dynamic when no static libc is installed. Darwin has no
# static libSystem, so the binary links dynamically against libSystem only.
#
#   make                       build ./cksh and ./cksh.1
#   make test                  regression suite (test.sh)
#   make install [PREFIX=dir]  PREFIX defaults to /usr/local for root, else $HOME
#   make CC=clang              toolchain override
#
# $LOCALBASE (pkgsrc) is consulted only for dependencies: the bash function
# prefers $LOCALBASE/bin/openssl. It is never an install target.

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
	@p='$(PREFIX)'; [ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; }; \
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
