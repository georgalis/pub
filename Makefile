# ./Makefile

# Unlimited use with this notice (c) 2017 George Georgalis <george@galis.org>

SHELL=	/bin/sh -e
noerr?=	echo "<<< $@ >>>"

arch : # push local commits and create archive from master
# c	:: empty unless there are uncommited changed to previously added files
# m	:: remote, master url
# p	:: remote. path to pwd
# r	:: basename of pwd, archive root
	rm -rf tmp/$@ && mkdir -p tmp/$@
	cp ~/.ssh/id_ed25519.pub tmp/$@/root.pub
	c="$$(git status --short . | grep -v '^??' || true )" ; \
	  [ -z "$$c" ] || { echo $$c ; false ;} # test local modifications
	git push # include local commits
	m=$$(git remote -v show | grep fetch | awk '{print $$2}') ; \
	  r="$$(basename "$$m")" ; p=$$(git rev-parse --show-prefix) ; \
	  [ -n "$$p" ] || p="./" ; \
	  git archive --prefix="./$$r/" master:$$p | gzip >./tmp/$@/$$r.tgz
	@$(noerr)
	@ls -d ./tmp/$@/*

quick_arch :
	rm -rf tmp/arch && mkdir -p tmp/arch
	cp ~/.ssh/id_ed25519.pub tmp/arch/root.pub
	for x in tmp .git ; do echo "$$x" >>./tmp/arch/exclude ; done
	tar -C .. -czf ../pub/tmp/arch/pub.tgz -X ./tmp/arch/exclude ./pub
	@echo ./tmp/arch/pub.tgz tmp/arch/root.pub

