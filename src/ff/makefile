# makefile --- ff, functional find
#
# Written to the intersection of GNU make, bmake and the Darwin make:
# no ifeq, no $(shell); platform branches live in the recipe shell.
# Static link on Linux and NetBSD; Darwin has no static libc, so the
# ceiling there is dynamic linkage against the system library alone.
# No third-party library on any platform.
#
#   make                       ff and ff.1
#   make test                  regression suite against ./ff and ff.fn.bash
#   make install [PREFIX=dir]  PREFIX defaults to /usr/local for root, else
#                              $HOME; DESTDIR honored
#   make uninstall             remove exactly what install placed
#   make CC=$LOCALBASE/bin/gcc toolchain override, e.g. pkgsrc gcc
#
# revision 6af927be 20261114 193214 PST Sat --- r0.7 srt and cksh model:
#          targets all ff man test install clean uninstall; ff.1 is the
#          output of --man; test-ff.sh
# revision 6ae4ea00 20261030 120328 PDT Fri --- r0.6 recipes unchanged
# revision 6adcb748 20261024 064856 PDT Sat --- r0.5 recipes unchanged
# revision 6abc5da8 20260929 175400 PDT Tue --- r0.4 recipes unchanged
# revision 6abb42b9 20260928 214649 PDT Mon --- r0.3 Darwin test fixes
# revision 6ab89f43 20260926 214451 PDT Sat --- r0.2 recipes unchanged
# original 6ab7fec8 20260926 102008 PDT Sat --- r0.1 C build, test and
#          install for ff, from the cksh makefile
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.

PREFIX =
DESTDIR =
CC = cc
CFLAGS = -O2 -std=c99 -Wall -Wextra -Wpedantic

all: ff man

ff: ff.c
	@case `uname -s` in Darwin) st= ;; *) st=-static ;; esac ; \
	echo "$(CC) $(CFLAGS) $$st -o ff ff.c $(LDFLAGS)" ; \
	$(CC) $(CFLAGS) $$st -o ff ff.c $(LDFLAGS) || { \
	  [ -n "$$st" ] || exit 1 ; \
	  echo "static link failed; linking dynamically" ; \
	  $(CC) $(CFLAGS) -o ff ff.c $(LDFLAGS) ; }

man: ff.1

# The man page is the binary's own manual, as man page source, so the
# two cannot differ.
ff.1: ff
	./ff --man > ff.1.new
	mv -f ff.1.new ff.1

test: ff man
	sh ./test-ff.sh

# PREFIX, when not given: /usr/local for root, $HOME for anyone else.
# The man page goes under share/man where that exists, else man.
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
	rm -f ff ff.o ff.1 ff.1.new

# the same PREFIX rule as install; the man page is removed from either place
uninstall:
	@p='$(PREFIX)'; [ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; }; \
	case "$$p$(DESTDIR)" in *[!A-Za-z0-9._/+-]*) echo "uninstall: unsafe path '$$p'" >&2; exit 1 ;; esac; \
	d='$(DESTDIR)'; set -x; \
	rm -f "$$d$$p/bin/ff" "$$d$$p/share/man/man1/ff.1" "$$d$$p/man/man1/ff.1" \
	  "$$d$$p/share/ff/ff.fn.bash"

.PHONY: all man test install clean uninstall
