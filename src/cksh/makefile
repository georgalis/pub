# makefile --- cksh, sortable stat and SHAKE256 listing of files
#
# Written to the intersection of GNU make, bmake and the Darwin make:
# no ifeq, no $(shell); platform branches live in the recipe shell.
# Static link on Linux and NetBSD; Darwin has no static libc, so the
# ceiling there is dynamic linkage against the system library alone.
# No third-party library on any platform.
#
#   make                       cksh and cksh.1
#   make test                  regression suite against ./cksh
#   make install [PREFIX=dir]  PREFIX defaults to /usr/local for root, else
#                              $HOME; DESTDIR honored
#   make uninstall             remove exactly what install placed
#
# revision 6af8d530 20261114 134000 PST Sat --- r0.6 srt model: targets all
#          cksh man test install clean uninstall; PREFIX as r0.5, /usr/local
#          for root and $HOME otherwise; cksh.1 is the output of --man
# revision 6ab7e734 20260926 083932 PDT Sat --- r0.5 C build, test, install
#
# (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.

PREFIX =
DESTDIR =
CC = cc
CFLAGS = -O2 -std=c99 -Wall -Wextra -Wpedantic

all: cksh man

cksh: cksh.c
	@case `uname -s` in Darwin) st= ;; *) st=-static ;; esac ; \
	echo "$(CC) $(CFLAGS) $$st -o cksh cksh.c" ; \
	$(CC) $(CFLAGS) $$st -o cksh cksh.c || { \
	  [ -n "$$st" ] || exit 1 ; \
	  echo "static link failed; linking dynamically" ; \
	  $(CC) $(CFLAGS) -o cksh cksh.c ; }

man: cksh.1

# The man page is the binary's own manual, as man page source, so the
# two cannot differ.
cksh.1: cksh
	./cksh --man > cksh.1.new
	mv -f cksh.1.new cksh.1

test: cksh man
	bash ./test-cksh.sh ./cksh

# PREFIX, when not given: /usr/local for root, $HOME for anyone else.
# The man page goes under share/man where that exists, else man.
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
	rm -f cksh cksh.1 cksh.1.new

# the same PREFIX rule as install; the man page is removed from either place
uninstall:
	@p='$(PREFIX)'; [ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; }; \
	case "$$p$(DESTDIR)" in *[!A-Za-z0-9._/+-]*) echo "uninstall: unsafe path '$$p'" >&2; exit 1 ;; esac; \
	d='$(DESTDIR)'; set -x; \
	rm -f "$$d$$p/bin/cksh" "$$d$$p/share/man/man1/cksh.1" "$$d$$p/man/man1/cksh.1" \
	  "$$d$$p/share/cksh/cksh.fn.bash"

.PHONY: all man test install clean uninstall
