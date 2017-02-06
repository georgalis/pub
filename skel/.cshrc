# ~/.cshrc
#
# $FreeBSD: src/share/skel/dot.cshrc,v 1.13 2001/01/10 17:35:28 archie Exp $
#
# .cshrc - csh resource script, read at beginning of execution by each shell
#
# see also csh(1), environ(7).
#

alias h		history 25
alias hup	'( set pid=$< ; kill -HUP $pid ) < /var/run/\!$.pid'
alias j		jobs -l
alias la	ls -a
alias lf	ls -FA
alias ll	ls -lA
alias x	exit
alias z	suspend
alias back	'set back="$old"; set old="$cwd"; cd "$back"; unset back; dirs'
alias cd	'set old="$cwd"; chdir \!*'
alias pd	pushd
alias pd2	pushd +2
alias pd3	pushd +3
alias pd4	pushd +4
alias tset	'set noglob histchars=""; eval `\tset -s \!*`; unset noglob histchars'

# A righteous umask
umask 22

set path=(/sbin /usr/sbin /bin /usr/bin /usr/pkg/sbin /usr/pkg/bin /usr/X11R6/bin /usr/local/sbin /usr/local/bin $HOME/bin)

# directory stuff: cdpath/cd/back
#set cdpath=(/usr/src/{sys,bin,sbin,usr.{bin,sbin},lib,libexec,share,local,games,gnu/{usr.{bin,sbin},libexec,lib,games}})

setenv EDITOR	vi
setenv PAGER	less
setenv BLOCKSIZE 1k

if ($?prompt) then
	# An interactive shell -- set some stuff up
	set filec
	set history = 100
	set savehist = 100
	set mail = (/var/mail/$USER)
	if ( $?tcsh ) then
		bindkey "^W" backward-delete-word
		bindkey -k up history-search-backward
		bindkey -k down history-search-forward
	endif

if ($?prompt && -x /usr/bin/id ) then
	if (`/usr/bin/id -u` == 0) then
		set prompt="`hostname -s`# "
	else
		set prompt="`hostname -s`% "
	endif
endif
# Id: skel.cshrc,v 1.2 1998/04/20 11:41:33 luisgh Exp
# Luis Francisco González <luisgh@debian.org> based on that of Vadik Vygonets
# Please check /usr/doc/tcsh/examples/cshrc to see other possible values.
  set autoexpand
  set autolist
  set cdpath = ( ~ )
  set pushdtohome
  if ( -e ~/.alias )	source ~/.alias

endif
