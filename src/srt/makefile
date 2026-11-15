# makefile --- srt, sort for system operators
#
# Written to the intersection of GNU make, bmake and the Darwin make:
# no ifeq, no $(shell); platform branches live in the recipe shell.
# Static link on Linux and NetBSD; Darwin has no static libc, so the
# ceiling there is dynamic linkage against the system library alone.
#
# revision 6af8a908 20261114 103136 PST Sat --- r0.6 (recipes unchanged)
# revision 6af889a5 20261114 081741 PST Sat --- r0.5.1 (header order only)
# revision 6af87ca7 20261114 072215 PST Sat --- r0.5 (recipes unchanged from r0.1; install places srt.fn.bash)
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.

# PREFIX: empty means /usr/local for root and $HOME for anyone else;
# make install PREFIX=/opt/srt overrides.
PREFIX =
CC = cc
CFLAGS = -O2 -std=c99 -Wall -Wextra -Wpedantic

all: srt man

srt: srt.c
	@case `uname -s` in Darwin) st= ;; *) st=-static ;; esac ; \
	echo "$(CC) $(CFLAGS) $$st -o srt srt.c" ; \
	$(CC) $(CFLAGS) $$st -o srt srt.c || { \
	  [ -n "$$st" ] || exit 1 ; \
	  echo "static link failed; linking dynamically" ; \
	  $(CC) $(CFLAGS) -o srt srt.c ; }

man: srt.1

# The man page is the binary's own --help text, so the two cannot differ.
srt.1: srt
	./srt --help | sed -e 's/\\/\\e/g' -e 's/^\./\\\&./' -e "s/^'/\\\\\&'/" | \
	awk 'BEGIN { print ".TH SRT 1" } /^[A-Z][A-Z ]*$$/ { b = 0 ; if (n++) print ".fi" ; printf ".SH \"%s\"\n.nf\n", $$0 ; s = 1 ; next } s { s = 0 ; if ($$0 == "") next } /^$$/ { b++ ; next } { for (; b > 0; b--) print "" ; print } END { print ".fi" }' > srt.1.new
	mv -f srt.1.new srt.1

test: srt
	bash ./test-srt.sh ./srt

install: all
	@p="$(PREFIX)" ; \
	[ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; } ; \
	[ -n "$$p" ] || { echo "install: no PREFIX and no HOME" ; exit 1 ; } ; \
	echo "installing under $(DESTDIR)$$p" ; \
	mkdir -p "$(DESTDIR)$$p/bin" "$(DESTDIR)$$p/share/man/man1" && \
	cp srt "$(DESTDIR)$$p/bin/srt" && \
	chmod 755 "$(DESTDIR)$$p/bin/srt" && \
	cp srt.1 "$(DESTDIR)$$p/share/man/man1/srt.1" && \
	chmod 644 "$(DESTDIR)$$p/share/man/man1/srt.1" && \
	{ [ ! -f srt.fn.bash ] || { \
	  mkdir -p "$(DESTDIR)$$p/share/srt" && \
	  cp srt.fn.bash "$(DESTDIR)$$p/share/srt/srt.fn.bash" && \
	  chmod 644 "$(DESTDIR)$$p/share/srt/srt.fn.bash" ; } ; }

clean:
	rm -f srt srt.1 srt.1.new

uninstall:
	@p="$(PREFIX)" ; \
	[ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; } ; \
	[ -n "$$p" ] || { echo "uninstall: no PREFIX and no HOME" ; exit 1 ; } ; \
	rm -f "$(DESTDIR)$$p/bin/srt" "$(DESTDIR)$$p/share/man/man1/srt.1" \
	  "$(DESTDIR)$$p/share/srt/srt.fn.bash"

.PHONY: all man test install clean uninstall
