
install : all
	[ -d "$${prefix}" ] # please set prefix directory
	mkdir -p "$${prefix}"/{man/man{1,3},bin}
	cp -p *1 "$${prefix}"/man/man1/
	cp -p *3 "$${prefix}"/man/man3/
	cp -p tee multitee "$${prefix}"/bin/

all :
	cc -o multitee multitee.c sigdfl.c sigsched.c ralloc.c getopt.c fmt.c scan.c
	cc -o tee tee.c getopt.c ralloc.c fmt.c

