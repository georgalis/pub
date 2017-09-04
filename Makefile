# ./Makefile

# Unlimited use with this notice. (C) 2017 George Georgalis

SHELL=	/bin/sh -e
noerr?=	echo "<<< $@ >>>"

arch : # push local commits and create archive from master
# c	:: empty unless there are uncommitted changed to previously added files
	rm -rf tmp/$@ && mkdir -p tmp/$@
	cat ~/.ssh/*.pub >tmp/$@/root.pub
	c="$$(git status --short . | grep -v '^??' || true )" ; \
	  [ -z "$$c" ] || { echo $$c ; false ;} # test local modifications
	git push # include local commits
# m	:: remote, master url
# r	:: remote fetch basename (first), archive root
# p	:: prefix of pwd from r
	m=$$(git remote -v show | grep fetch | awk '{print $$2}') ; \
	  r="$$(basename "$$m")" ; p=$$(git rev-parse --show-prefix) ; \
	  [ -n "$$p" ] || p="./" ; \
	  git archive --prefix="./$$r/" master:$$p | gzip >./tmp/$@/$$r.tgz
	@$(noerr)
	@ls -d ./tmp/$@/*

quick_arch : # create archive from uncommitted files
	rm -rf tmp/arch && mkdir -p tmp/arch
	cat ~/.ssh/*.pub >tmp/arch/root.pub
	for x in tmp .git ; do echo "$$x" >>./tmp/arch/exclude ; done
	tar -C .. -czf ../pub/tmp/arch/pub.tgz -X ./tmp/arch/exclude ./pub
	@echo ./tmp/arch/pub.tgz tmp/arch/root.pub
