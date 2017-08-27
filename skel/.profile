# ~/.profile

# Unlimited use with this notice (c) George Georgalis <george@galis.org>

# sourced by Bourne-compatible shells

export EDITOR="vi"
export PAGER='less -G --jump-target=-1'

umask 022
ulimit -c 1 # Just want to know if/when core files are generated.

path_append () { # append $1 if not already in path
 echo $PATH | grep -E ":$1$|^$1$|^$1:|:$1:" 2>&1 >/dev/null \
  || export PATH="${PATH}:${1}" ;}
path_prepend () { # prepend $1 if not already in path
 echo $PATH | grep -E "^$1:|^$1$" 2>&1 >/dev/null \
  || export PATH="${1}:${PATH}" ;}

/usr/bin/tty -s || return # the following lines for interactive sessions only
export GPG_TTY=$(tty)

OS=$(uname)

# setup ls aliases
[ -x "$(which colorls 2>/dev/null)" ] && { # setup colorls
 #export LSCOLORS='xefxcxdxbxegedabagacad'
 #export CLICOLORS=$LSCOLORS
 # define reverse for directory color
 export LSCOLORS='x45x2x3x1x464301060203' # invert directory color
 alias  l="colorls -FG"
 alias lA="colorls -AFG"
 alias la="colorls -AFGTl"
 alias ll="colorls -FGTl"
 alias lt="colorls -AFGTlrt"
 alias lS="colorls -AFGTlrS"
 }
# \
# || { # builtin color
# alias  l="ls"
# alias lA="ls -AF"
# alias la="ls -AFTl"
# alias ll="ls -Fl"
# alias lt="ls -AFTlrt"
## alias lS="ls -AFTlrS"
# } # builtin color

case $OS in
Darwin)
 [ "$TERM" = "xterm" ] && export TERM='xterm-color'
 export LSCOLORS='xefxcxdxbxegedabagacad' # invert directory color
 export PAGER='less -G --jump-target=99'
 alias  l="ls -GF"
 alias lA="ls -AFG"
 alias la="ls -AFGTl"
 alias ll="ls -FTGl"
 alias lt="ls -AFGTlrt"
 alias lS="ls -AFGTlrS"
 alias t='tail -F'
 alias top='top -S -n24 -s4 -o cpu'
 alias p='ps -ax -o uid,pid,command -ww'
;; # Darwin
Linux)
 eval `dircolors | sed 's/di=01;34/di=00;44/'`
 alias  l="ls --color=auto"
 alias lA="ls --color=auto -AF"
 alias la="ls --color=auto -AFl --full-time --time-style=+%Y%m%d_%H%M%S"
 alias ll="ls --color=auto -Fl --full-time --time-style=+%Y%m%d_%H%M%S"
 alias lt="ls --color=auto -AFlrt --full-time --time-style=+%Y%m%d_%H%M%S"
 alias lS="ls --color=auto -AFlrS --full-time --time-style=+%Y%m%d_%H%M%S"
 alias t='tail --follow=name'
 alias p='ps -e f -o pid,user,cmd --sort=user'
 export PAGER='less -G --jump-target=2'
 #less -j does not take negative number any more Debian Bug report logs - #498746 http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=498746
;; # Linux
OpenBSD)
 alias t='tail -f'
;; # OpenBSD
NetBSD|FreeBSD|Dragonfly)
 alias t='tail -F'
 alias top='top -S -I -s4 -o cpu'
 [ "$TERM" = "vt220" ] && export TERM=xterm # adds color to some apps in console
 # fix colors in screen on amd64 XXX workaround
 #[ "$(uname -m)" = "amd64" -a "$TERM" = "xterm-color" ] && export TERM="xterm"
 kwds () { # convert stdin to unique words sorted on legnth then alpha to stdout, linux untested
  tr -c '[:alpha:]' ' ' \
  | tr '\ ' '\n' \
  | tr '[:upper:]' '[:lower:]' \
  | sort -ru \
  | while read w; do echo "${#w}\t${w}" ; done \
  | sort -rn \
  | awk '{print $2}' \
  | tr '\n' '\ '
  echo
 } # kywds
;; # NetBSD|FreeBSD|Dragonfly
esac

# determine correct termcap codes per OS, for underline and stand-out
[ -z "${OS#Linux}" ] && {
	 _ntermrev='rmso' ; _ntermul='rmul'
	 _termrev='smso' ; _termul='smul'
	}
[ -z "${OS#NetBSD}" ] && {
	 _ntermrev='se' ; _ntermul='ue'
	 _termrev='so' ; _termul='us'
	}
[ -z "${OS#Darwin}" ] && {
	 _ntermrev='se' ; _ntermul='ue'
	 _termrev='so' ; _termul='us'
}

# create ESC strings to turn on/off underline and stand-out
_ntermrev="$(tput "$_ntermrev")" ; _ntermul="$(tput "$_ntermul")"
_termrev="$(tput "$_termrev")" ; _termul="$(tput "$_termul")"
export _ntermrev _termrev _ntermul _termul

# site installed applications
[ -x "$(which par 2>/dev/null)" ] && export PARINIT="rTbgqR B=.,?_A_a Q=_s>|"
[ -x "$(which proctree 2>/dev/null)" ] && alias p='proctree -w'
[ -x "$(which pstree 2>/dev/null)" ] && alias p='pstree -w'
[ -x "$(which colordiff 2>/dev/null)" ] && alias diff='colordiff'

alias back='cd "$OLDPWD"'	# previous directory
alias g='grep -E'		# grep for the extended regex
alias v='grep -Ev'		# grep -v for the extended regex
alias h='fc -l'			# list commands previously entered in shell.
alias j='jobs -l'		# list background jobs
alias s='less -R'
alias man='man $man_augment -a'	# $man_augment set in /etc/profile, or not
alias scp='scp -pr'
alias cp='cp -ip'
alias mv='mv -i'
alias rm='rm -i'
alias d='diff'

# find . \( -path ./skel -o -path ./mkinst \) \! -prune -o -type f

dusum () { # sort $1 (defaults to $PWD) according to disk use, also show cumulative sum.
[ -z "$1" ] && d="./" || d="$1"
find "$d" -maxdepth 1 -mindepth 1 -print0 \
	| xargs -0 du -sk | sort -n \
	| awk '{sum += $1; printf "%+11sk %+10sk %s %s %s\n", sum, $1, $2, $3, $4}' ;}

# idtai | id2tai64 | tai64nlocal
idtai () { echo | tai64n | sed -e 's/^@4[0]*//' -e 's/......$//' -e 's/^......../&./' ;} # dump an id based on tai64n
id2tai64 () { sed -e 's/^/@40000000/' -e 's/$/00000/' -e 's/\.//g' ;} # convert idtai to tai64n
# idtai | idlocal
idlocal () { id2tai64 | tai64nlocal | sed 's/ /_/' ;} # convert idtai to local time
idnow () { sh -c "{ date '+%Y%m%d_%H%M%S_' && uuidgen ;} | tr -d '\n' | sed -e s/-.*// | tr '[A-Z]' '[a-z]'" ;} # dump local id

import_pubkey () { # take an exported ssh key and make an authorized_keys2 line
export key_in=`mktemp /tmp/pubkey-XXXXXX`
[ -n "$1" ] && cat "$1" >|$key_in || cat /dev/stdin >|$key_in
printf "`ssh-keygen -if $key_in` " \
 && grep Comment $key_in | sed -e 's/^Comment: "//' -e 's/"$//'
rm $key_in ;}

ptr () { # reverse a dotted quad or subnet
rev="`echo "$1" | cut -d\. -f1`.$2" ; ip="`echo "$1" | cut -d\. -f2-`"
[ "$ip" = "$1" ] && echo "${rev}" || ptr $ip $rev ;}
arpa () { # use ptr to reverse a network, and add in-addr.arpa
[ -z "$1" ] && echo -n "An ip address on the command line returns its "
echo "$(ptr "$1")in-addr.arpa" ;}

dirper () { # reveal dir permissions of "$*" or "$PWD"
d="$*";d="${d#./}";[ -z "$d" -o "$d" = "." -o "$d" = "./" ] && d="$PWD"
[ "`dirname "$d"`" = '.' ] && d="$PWD/$d";
case "`uname`" in Linux) ls -Ldl --full-time "$d" ;; *) ls -LTdl "$d" \
| awk '{printf "%-10s %+8s:%-8s %+8s %8s %2s %3s %s ", \
	$1, $3, $4, $5, $8, $7, $6, $9}' ; ls -Ld "${d}"
;; esac ; [ "$d" = "/" ] && return || dirper `dirname "$d"`;}

uptime

case $SHELL in # start of per $SHELL env
 *bash)
	export PS1=" \u@\h:\w " \
	&& set -o ignoreeof # disable ctrl-d exit
 ;;
 *ksh)
  hostname="$(hostname)" export PS1=" \${USER}@\${hostname}:\${PWD} "
  set -o ignoreeof # disable ctrl-d exit
  set -o braceexpand
  bind '^XH'=beginning-of-line
  bind '^XF'=end-of-line
  export HISTFILE=$HOME/.ksh_hist
  export HISTSIZE=6400
  VISUAL=emacs # don't export, least override EDITOR
  [ -e ~/.ksh_logout ] && trap '. ~/.ksh_logout' EXIT || true
 ;; # *ksh
#[ -z "${SHELL#*zsh}" ] && export PS1=' %n@%m:%d/ '
#		|| export PS1=" %U%n@%m:%d%u "
#	&& { [ `id -u` = 0 ] \
#	}
esac # $SHELL

[ -x "$(which vim 2>/dev/null)" -a "$EDITOR" = "vi" ] \
	&& {
		alias crontab="env EDITOR=$(which $EDITOR) crontab"
		alias vi='vim'
		export EDITOR='vim'
	}

# ssh socket key and agent managent
printf "${_termrev}"
##[ -n "$SSH_AUTH_SOCK" ] || { # already forwarded by agent
  [ "$(ssh-add -l 2>&1)" = "Could not open a connection to your authentication agent." ] \
  && {
    printf "${USER}@$(hostname): " 
    eval $(ssh-agent)
    export SSH_AGENT_ENV="SSH_AGENT_PID $SSH_AGENT_PID SHELL_PID $$" # ssh-agent env
    } || ssh-add -l | cut -d\  -f 3- # show keys in SSH_AUTH_SOCK
  [ "$(ssh-add -l 2>&1)" = "The agent has no identities." ] && {
    ssh_ids="id_ed25519 id_ecdsa id_rsa"
    for ssh_id in $ssh_ids ; do # add each identity file
      [ -e "$HOME/.ssh/$ssh_id" ] && { # try ssh-add
        ssh-add "$HOME/.ssh/$ssh_id" ;}
    done ;} # ssh_id
##  } && { #echo "SSH_AUTH_SOCK forwarded by agent."
##   ssh-add -l ;} # show keys in SSH_AUTH_SOCK
printf "${_ntermrev}"
## shell logout trap, eg ~/.bash_logout ~/.ksh_logout
#[ -n "$SSH_AGENT_ENV" ] && set $SSH_AGENT_ENV && [ "$$" = "$4" ] \
#	&& { printf "Logout: " && kill $2 && echo $(hostname) $0 [$4] killed ssh-agent $2 \
#		|| { echo $(hostname) ssh-agent already died? 2>/dev/stderr ; exit 1 ;} ;}

# if exists, source .profile.local 
[ -e "$HOME/.profile.local" ] && . "$HOME/.profile.local" || true

