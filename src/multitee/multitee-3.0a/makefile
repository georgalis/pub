
install : all
    # pick one...
	#                                  prefix=. make
	# mkdir -p /usr/local &&           prefix=/usr/local make
	# mkdir -p /usr/local/multitee &&  prefix=/usr/local/multitee make
	# mkdir -p $HOME/local/multitee && prefix=$HOME/local/multitee make
	# mkdir -p $HOME &&                prefix=$HOME make
	[ -d "$${prefix}" ] # please set prefix directory
	mkdir -p "$${prefix}"/{man/man{1,3},bin}
	cp -p *1 "$${prefix}"/man/man1/
	cp -p *3 "$${prefix}"/man/man3/
	cp -p tee multitee "$${prefix}"/bin/

all :
	cc -o multitee multitee.c sigdfl.c sigsched.c ralloc.c getopt.c fmt.c scan.c
	cc -o tee tee.c getopt.c ralloc.c fmt.c

