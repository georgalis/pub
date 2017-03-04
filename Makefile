# Unlimited use with this notice (c) George Georgalis <george@galis.org>

# ./Makefile

SHELL=	/bin/sh -e

arch : # push local commits and create archive from master
# c	:: empty unless there are uncommited changed to previously added files
# m	:: remote, master url
# p	:: remote. path to pwd
# r	:: basename of pwd, archive root
	rm -rf tmp/$@ && mkdir -p tmp/$@
	c="$$(git status --short . | grep -v '^??' || true )" ; \
	  [ -z "$$c" ] || { echo $$c ; false ;} # test local modifications
	git push # include local commits
	m=$$(git remote -v show | grep fetch | awk '{print $$2}') ; \
	  p=$$(git rev-parse --show-prefix) ; r=$$(basename $$p) ; \
	  git archive --remote=$$m --prefix="./$$r/" master:$$p | gzip >./tmp/$@/$$r.tgz ; \
	  echo ./tmp/$@/$$r.tgz

