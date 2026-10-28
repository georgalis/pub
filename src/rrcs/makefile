# makefile --- check, test and install rrcs.fn.bash
# (c) 2024-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6ae1747d 20261027 210517 PDT Tue 09:05 PM 27 Oct 2026
#     initial release: syntax check, man page from --help, test, probe, install
# org 668d8a0d 20240709 120549 PDT Tue 12:05 PM 09 Jul 2024 _rcs in sub/fn.bash
#     https://github.com/georgalis/pub/commit/73f56ac9fe309ab6aac250d78079ab9bba2e9531
#
# Portable across GNU make, bmake (NetBSD, pkgsrc) and Apple make: no ifeq,
# no $(shell), no ?=; platform branching happens inside recipe shells.
# rrcs.fn.bash is a bash function file: nothing compiles. The man page is
# derived from rrcs --help so the two cannot disagree; generating it needs
# only bash, since the emulation defines ci where RCS is not installed.
#
#   make                       syntax check and ./rrcs.1
#   make test                  regression suite (test-rrcs.sh)
#   make probe                 keep-link probe against the RCS on PATH (probe-rrcs.sh)
#   make install [PREFIX=dir]  PREFIX defaults to /usr/local for root, else $HOME
#   make BASH=/opt/pkg/bin/bash   bash override
#
# install places $PREFIX/share/rrcs/rrcs.fn.bash and the man page; source the
# function file from a bash profile:  . $PREFIX/share/rrcs/rrcs.fn.bash

BASH = bash
PREFIX =
DESTDIR =

all: check rrcs.1

check:
	$(BASH) -n rrcs.fn.bash && $(BASH) -n test-rrcs.sh && $(BASH) -n probe-rrcs.sh

# man page derived from --help so the two cannot disagree; line 1 is the help banner
rrcs.1: rrcs.fn.bash
	{ echo '.TH RRCS 1'; $(BASH) -c '. ./rrcs.fn.bash && rrcs --help' | awk 'NR == 1 { next } /^[A-Z][A-Z ]*$$/ { print ".SH " $$0; print ".nf"; next } { gsub(/\\/, "\\e"); if (substr($$0, 1, 1) == ".") $$0 = "\\&" $$0; print }'; echo '.fi'; } > rrcs.1.tmp
	mv rrcs.1.tmp rrcs.1

test: check
	$(BASH) ./test-rrcs.sh

probe: check
	$(BASH) ./probe-rrcs.sh

install: all
	@p='$(PREFIX)'; [ -n "$$p" ] || { [ "`id -u`" = 0 ] && p=/usr/local || p="$$HOME" ; }; \
	case "$$p$(DESTDIR)" in *[!A-Za-z0-9._/+-]*) echo "install: unsafe path '$$p'" >&2; exit 1 ;; esac; \
	m=man; [ -d "$$p/share/man" ] && m=share/man; \
	d='$(DESTDIR)'; set -x; \
	mkdir -p "$$d$$p/share/rrcs" "$$d$$p/$$m/man1" && \
	cp rrcs.fn.bash "$$d$$p/share/rrcs/rrcs.fn.bash" && chmod 644 "$$d$$p/share/rrcs/rrcs.fn.bash" && \
	cp rrcs.1 "$$d$$p/$$m/man1/rrcs.1" && chmod 644 "$$d$$p/$$m/man1/rrcs.1" && \
	{ set +x; echo "source from bash: . $$p/share/rrcs/rrcs.fn.bash"; }

clean:
	rm -f rrcs.1 rrcs.1.tmp

.PHONY: all check test probe install clean
