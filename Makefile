# Unlimited use with this notice (c) George Georgalis <george@galis.org>

# ./Makefile

SHELL=	/bin/sh -e

quick_arch :
	rm -rf tmp/arch && mkdir -p tmp/arch
	cp ~/.ssh/id_ed25519.pub tmp/arch/root.pub
	for x in tmp .git ; do echo "$$x" >>./tmp/arch/exclude ; done
	tar -C .. -czf ../pub/tmp/arch/pub.tgz -X ./tmp/arch/exclude ./pub
	@echo ./tmp/arch/pub.tgz tmp/arch/root.pub
arch : # push local commits and create archive from master
# c	:: empty unless there are uncommited changed to previously added files
# m	:: remote, master url
# p	:: remote. path to pwd
# r	:: basename of pwd, archive root
#r=	"$$(basename $$(pwd -P))"
	rm -rf tmp/$@ && mkdir -p tmp/$@
#	c="$$(git status --short . | grep -v '^??' || true )" ; \
	  [ -z "$$c" ] || { echo $$c ; false ;} # test local modifications
	git push # include local commits
	m=$$(git remote -v show | grep fetch | awk '{print $$2}') ; \
	  p=./$$(git rev-parse --show-prefix) ; [ -z "$$p" ] && p="./" ; r="$$m" ; \
	  echo git archive --remote=$$m --prefix="./$$r/" master:$$p #| gzip >./tmp/$@/$$r.tgz ; 
	  echo ./tmp/$@/$$r.tgz

