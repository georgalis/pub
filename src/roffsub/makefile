# makefile --- roffsub tools, manuals, function, and binary
# roffsub r0.9
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
#   make            build the binary, the function regions, and the pages
#   make check      check the form of the manuals and test documents
#   make test       build, then run test-roffsub.sh
#   make gold       rewrite the reference outputs in t/gold (review them after)
#   make install    install the binary, pages, function, and tools under
#                   PREFIX ($HOME by default, /usr/local for root)
#   make uninstall  remove what make install placed under the same PREFIX
#   make clean      remove the binary, generated files, and test output

VERSION = r0.9
DATE = 2026-11-15
CC = cc
CFLAGS = -std=c99 -O2 -Wall -Wextra -pedantic
AWK = awk

TOOLS = roffsub-check.awk roffsub-ir.awk roffsub-render.awk roffsub-emit.awk roffsub-gen.awk roffsub-man.awk
HEADERS = roffsub.h roffsub-emit.h roffsub-tty.h

all: roffsub fn man

roffsub: roffsub.c $(HEADERS) roffsub.man.h roffsub.awk.h
	$(CC) $(CFLAGS) -o roffsub roffsub.c

roffsub.man.ir: roffsub.1 roffsub-check.awk roffsub-ir.awk
	LC_ALL=C $(AWK) -v strict=1 -f roffsub-check.awk roffsub.1
	$(AWK) -v date=$(DATE) -v version=$(VERSION) -f roffsub-ir.awk roffsub.1 > $@.new && mv $@.new $@

roffsub.man.h: roffsub.man.ir roffsub-gen.awk
	$(AWK) -v mode=c -v name=roffsub_man -f roffsub-gen.awk roffsub.man.ir > $@.new && mv $@.new $@

roffsub.awk.h: roffsub-check.awk roffsub-ir.awk roffsub-gen.awk roffsub-man.awk
	$(AWK) -v mode=c -v name=roffsub_awk_check -f roffsub-gen.awk roffsub-check.awk > $@.new
	$(AWK) -v mode=c -v name=roffsub_awk_ir -f roffsub-gen.awk roffsub-ir.awk >> $@.new
	$(AWK) -v mode=c -v name=roffsub_awk_gen -f roffsub-gen.awk roffsub-gen.awk >> $@.new
	$(AWK) -v mode=c -v name=roffsub_awk_man -f roffsub-gen.awk roffsub-man.awk >> $@.new
	mv $@.new $@

fn: .fn.stamp

.fn.stamp: roffsub.fn.bash roffsub.man.ir $(TOOLS)
	cp roffsub.fn.bash .fn.work
	for p in _rs_check:roffsub-check.awk _rs_ir:roffsub-ir.awk _rs_render:roffsub-render.awk \
	         _rs_emit:roffsub-emit.awk _rs_gen:roffsub-gen.awk _rs_page:roffsub-man.awk \
	         _rs_man:roffsub.man.ir; do \
		n=$${p%%:*}; f=$${p#*:}; \
		$(AWK) -v mode=bash -v name=$$n -f roffsub-gen.awk $$f > .fn.block && \
		$(AWK) -v mode=splice -v name=$$n -f roffsub-gen.awk .fn.block .fn.work > .fn.next && \
		mv .fn.next .fn.work || exit 1; \
	done
	bash -n .fn.work
	if cmp -s .fn.work roffsub.fn.bash; then rm -f .fn.work; else mv .fn.work roffsub.fn.bash; fi
	rm -f .fn.block
	touch .fn.stamp

man: roffsub.1.out roffsub.7.out

roffsub.1.out: roffsub.1 roffsub-check.awk roffsub-man.awk
	LC_ALL=C $(AWK) -v strict=1 -f roffsub-check.awk roffsub.1
	$(AWK) -v date=$(DATE) -v version=$(VERSION) -f roffsub-man.awk roffsub.1 > $@

roffsub.7.out: roffsub.7 roffsub-check.awk roffsub-man.awk
	LC_ALL=C $(AWK) -v strict=1 -f roffsub-check.awk roffsub.7
	$(AWK) -v date=$(DATE) -v version=$(VERSION) -f roffsub-man.awk roffsub.7 > $@

check:
	LC_ALL=C $(AWK) -v strict=1 -f roffsub-check.awk roffsub.1 roffsub.7 template.1 t/ok/*.1

test: all
	AWK=$(AWK) bash test-roffsub.sh

gold: all
	AWK=$(AWK) bash test-roffsub.sh --gold

install: all
	@p=$${PREFIX:-$$( [ "$$(id -u)" = 0 ] && echo /usr/local || echo "$$HOME" )}; \
	echo "installing under $$p"; \
	mkdir -p "$$p/bin" "$$p/share/man/man1" "$$p/share/man/man7" "$$p/share/roffsub" && \
	cp roffsub "$$p/bin/roffsub" && \
	cp roffsub.1.out "$$p/share/man/man1/roffsub.1" && \
	cp roffsub.7.out "$$p/share/man/man7/roffsub.7" && \
	cp roffsub.fn.bash $(TOOLS) $(HEADERS) template.1 skill/SKILL.md "$$p/share/roffsub/" && \
	echo "source $$p/share/roffsub/roffsub.fn.bash to define the roffsub function"

uninstall:
	@p=$${PREFIX:-$$( [ "$$(id -u)" = 0 ] && echo /usr/local || echo "$$HOME" )}; \
	rm -f "$$p/bin/roffsub" "$$p/share/man/man1/roffsub.1" "$$p/share/man/man7/roffsub.7"; \
	rm -rf "$$p/share/roffsub"

clean:
	rm -f roffsub roffsub.man.ir roffsub.man.h roffsub.awk.h roffsub.1.out roffsub.7.out .fn.stamp .fn.work .fn.block .fn.next
	rm -rf t/out

.PHONY: all fn man check test gold install uninstall clean
