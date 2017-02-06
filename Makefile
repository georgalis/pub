# Unlimited use with this notice (c) George Georgalis <george@galis.org>

# ./Makefile

SHELL=	/bin/sh -e

arch : # create basename archive
	rm -rf tmp/$@ && mkdir -p tmp/$@
	changes="$$(git status --short . | grep -v '^??' || true )" ; \
	  [ -n "$${changes}" ] && { echo $${changes} ; false ;} # test local modifications
	m=$$(git remote -v show | grep fetch | awk '{print $$2}') ; \
	  r=$$(basename $$m) ; \
	  git push ; \
	  git archive --remote=$$m --prefix="./$$r/" master . | gzip >./tmp/$@/$$r.tgz ; \
	  echo ./tmp/$@/$$r.tgz

