# ~/.profile

# (C) 2004-2022 George Georgalis unlimited use with this notice

# For Bourne-compatible shells (bash,ksh,zsh,sh)

# for interactive sessions only
/usr/bin/tty -s || return

export EDITOR="vi"
export PAGER='less --jump-target=3'
export GPG_TTY=$(tty)
export HOSTNAME="$(hostname)"
export OS=$(uname)
# /etc/redhat-release  /etc/centos-release  /etc/os-release

umask 022
ulimit -c 1 # one byte core files memorialize their creation

case "$OS" in
Darwin)
#[ "$TERM" = "tmux-256color" ] && export TERM='xterm-new'
 export LSCOLORS='xefxcxdxbxegedabagacad' # invert directory color
 alias   l='ls -GFr'
 alias  lr='ls -GF'
 alias  ll='ls -AFTGlr'
 alias llr='ls -AFTGl'
 alias  lt='ls -AFGTrt'
 alias llt='ls -AFGTlrt'
 alias  lS='ls -AFGTlrS'
 alias   t='tail -F'
 alias top='top -S -n24 -s4 -o cpu'
 alias   p='ps -ax -o uid,pid,command -ww'
 alias xattrc='xattr -c'
;; # Darwin
Linux)
 eval $(dircolors | sed 's/di=01;34/di=00;44/')
 alias   l='ls --color=auto -r'
 alias  lr='ls --color=auto'
 alias  ll='ls --color=auto -Alr   --full-time --time-style=+%Y%m%d_%H%M%S'
 alias llr='ls --color=auto -Al    --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  lt='ls --color=auto -AFtr  --full-time --time-style=+%Y%m%d_%H%M%S'
 alias llt='ls --color=auto -AFlrt --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  lS='ls --color=auto -AFlrS --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  t='tail --follow=name'
 alias  p='ps -e f -o pid,user,cmd --sort=user'
 #export PAGER='less -G --jump-target=2'
 #less -j does not take negative number any more Debian Bug report logs - #498746 http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=498746
;; # Linux
OpenBSD)
 alias t='tail -f'
;; # OpenBSD
NetBSD|FreeBSD|Dragonfly)
 alias   l='ls -Fr'
 alias  lr='ls -F'
 alias  ll='ls -AFTlr'
 alias llr='ls -AFTl'
 alias  lt='ls -AFTrt'
 alias llt='ls -AFTlrt'
 alias  lS='ls -AFTlrS'
 alias t='tail -F'
 alias top='top -S -I -s4 -o cpu'
 alias p >/dev/null 2>&1 || alias p='ps ax'
 [ "$TERM" = "vt220" ] && export TERM=xterm # adds color to some apps in console
 # fix colors in screen on amd64 XXX workaround
 #[ "$(uname -m)" = "amd64" -a "$TERM" = "xterm-color" ] && export TERM="xterm"
;; # NetBSD|FreeBSD|Dragonfly
esac # "$OS"

# setup ls aliases
[ -x "$(which colorls 2>/dev/null)" ] && { # setup colorls
 #export LSCOLORS='xefxcxdxbxegedabagacad'
 #export CLICOLORS=$LSCOLORS
 # define reverse for directory color
 export LSCOLORS='x45x2x3x1x464301060203' # invert directory color
 alias   l='colorls -FGr'
 alias  lr='colorls -FG'
 alias  ll='colorls -AFGTlr'
 alias llr='colorls -AFGTl'
 alias  lt='colorls -AFGTrt'
 alias llt='colorls -AFGTlrt'
 alias  lS='colorls -AFGTlrS'
 } || true # echo "no colorls"

# terminfo
[ -z "${OS#Linux}" ] &&  { _ntermrev='rmso' ; _ntermul='rmul'
                            _termrev='smso' ;  _termul='smul' ;}
[ -z "${OS#NetBSD}" ] && { _ntermrev='se'   ; _ntermul='ue'
                            _termrev='so'   ;  _termul='us' ;}
[ -z "${OS#Darwin}" ] && { _ntermrev='se'   ; _ntermul='ue'
                            _termrev='so'   ;  _termul='us' ;}
# create ESC strings to turn on/off underline and stand-out
_ntermrev="$(tput "$_ntermrev")" ; _ntermul="$(tput "$_ntermul")"
 _termrev="$(tput  "$_termrev")"  ; _termul="$(tput  "$_termul")"
export _ntermrev _termrev _ntermul _termul

alias    g='grep'   # grep for the extended regex
alias    v='grep -v'  # grep -v for the extended regex
alias    h='fc -l'     # list commands previously entered in shell.
alias    j='jobs -l'   # list background jobs
alias    s='less -R'   # less
alias    m='man $man_ops' ; export man_ops='-a'
alias  scp='scp -pr' # never not...
alias   cp='cp -ip'  # always
alias   mv='mv -i'   # why not
alias   rm='rm -i'   # sure
alias    d='diff -U 0'
back () { cd "$OLDPWD" ;} # previous directory
#cal () { cal -h $@ ;}

# common functions for shell verbose management....
devnul () { return 0 ;}                                                     #:> drop args
stderr () {  [ "$*" ] && echo "$*" 1>&2 || true ;}                          #:> args to stderr, or noop if null
chkstd () {  [ "$*" ] && echo "$*"      || true ;}                          #:> args to stdout, or noop if null
chkwrn () {  [ "$*" ] && { stderr    "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
logwrn () {  [ "$*" ] && { logger -s "^^ $* ^^"   ; return $? ;} || true ;} #:> wrn stderr+log args return 0, noop if null
chkerr () {  [ "$*" ] && { stderr    ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null
logerr () {  [ "$*" ] && { logger -s ">>> $* <<<" ; return 1  ;} || true ;} #:> err stderr+log args return 1, noop if null
chkexit () { [ "$*" ] && { stderr    ">>> $* <<<" ; exit 1    ;} || true ;} #:> err stderr args exit 1, noop if null
logexit () { [ "$*" ] && { logger -s ">>> $* <<<" ; exit 1    ;} || true ;} #:> err stderr+log args exit 1, noop if null
siff () { local verb="${verb:-chkwrn}" ; test -e "$1" \
        && { { . "${1}" && ${verb} "<> ${2}: . ${1} <>" ;} || { chkerr "siff: fail in '$1' from '$2'" ; return 1 ;} ;} \
        || ${verb} "${2}: siff: no file $1" ;} #:> source arg1 if exists, on err recall args for backtrace
# verbosity, typically set to devnul, chkwrn, or chkerr
#verb="${verb:=devnul}"
#verb2="${verb2:=devnul}"
#verb3="${verb3:=devnul}"

path_append () { # append $1 if not already in path
 echo $PATH | grep -E "(:$1$|^$1$|^$1:|:$1:)" 2>&1 >/dev/null \
  || export PATH="${PATH}:${1}" ;}
path_prepend () { # prepend $1 if not already in path
 echo $PATH | grep -E "(^$1:|^$1$)" 2>&1 >/dev/null \
  || export PATH="${1}:${PATH}" ;}

ckstat () { # return sortable stat data for args (OR stdin file list)
  # ckstat /etc/resolv.conf
  # 0127e92c7 .       16 62798808   resolv.conf     /etc/resolv.conf
  # links\inode . 0x_size 0x_date   basename        input
  # (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice
  local f fs;
  [ "$1" ] && fs="$1" || fs="$(cat)";
  shift || true;
  [ "$1" ] && $FUNCNAME $@;
  [ "$fs" = "-h" -o "$fs" = "--help" ] && {
    chkwrn "Return sortable stat data for args (OR stdin file list):";
    chkwrn "links\inode . 0x_size 0x_mdate basename input"
    } || { OS="$(uname)"
      [ "$OS" = "Linux" ]                      && _stat () { stat -c %h\ %i\ %s\ %Y "$1" ;} || true
      [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat () { stat -f %l\ %i\ %z\ %m "$1" ;} || true
      echo "$fs" | while IFS= read f; do
        [ -f "$f" ] && {
          _stat "$f" | awk '{printf "%02x%07x . % 8x %08x",$1,$2,$3,$4}'
          printf "\t%s\t%s\n" "${f##*/}" "$f" # tabs with basename and filepath input
          } || chkerr "$FUNCNAME : not a regular file : $f";
        done
      }
  } # ckstat ()

ckstatsum () { # return sortable stat data for args (OR stdin file list)
  # ckstatsum /etc/resolv.conf
  # 0127e92c7 39bd42d3       16 62798808    resolv.conf     /etc/resolv.conf
  # links\inode 0x_cksum 0x_size 0x_date    basename        input
  # (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice
  local f fs;
  [ "$1" ] && fs="$1" || fs="$(cat)";
  shift || true;
  [ "$1" ] && $FUNCNAME $@;
  [ "$fs" = "-h" -o "$fs" = "--help" ] && {
    chkwrn "Return sortable stat data for args (OR stdin file list):";
    chkwrn "links\inode 0x_cksum 0x_size 0x_mdate basename input"
    } || { OS="$(uname)"
      [ "$OS" = "Linux" ]                      && _stat () { stat -c %h\ %i\ %s\ %Y "$1" ;} || true
      [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat () { stat -f %l\ %i\ %z\ %m "$1" ;} || true
      echo "$fs" | while IFS= read f; do
        [ -f "$f" ] && {
          { _stat "$f" ; cksum <"$f"
              } | tr '\n' ' ' | awk '{printf "%02x%07x %8x % 8x %08x",$1,$2,$5,$3,$4}'
          printf "\t%s\t%s\n" "${f##*/}" "$f" # tabs with basename and filepath input
          } || chkerr "$FUNCNAME : not a regular file : $f";
        done
      }
  } # ckstatsum ()

ascii_filter () { while IFS= read a ; do echo "$a" | strings -e s ; done ;}

dufiles () { #:> report the number of files along with total disk use of directory arg1
    [ "$1" ] || set .
    { du -sh "$1" ; echo "#" ; find "$1" -type f | wc -l ; echo files ;} \
       | tr '\n' ' ' ; echo ;}

dusum () { # sort $1 (defaults to $PWD) according to disk use, also show cumulative sum.
[ -z "$1" ] && d="./" || d="$1"
find "$d" -maxdepth 1 -mindepth 1 -print0 \
  | xargs -0 du -sk | sort -n \
  | awk '{sum += $1; printf "%+11sk %+10sk %s %s %s\n", sum, $1, $2, $3, $4}' ;}

dirper () { # reveal dir permissions of "$*" or "$PWD"
  local d="$*";d="${d#./}";[ -z "$d" -o "$d" = "." -o "$d" = "./" ] && d="$PWD"
  [ "$(dirname "$d")" = '.' ] && d="$PWD/$d";
  case "$(uname)" in Linux) ls -Ldl --full-time "$d" ;; *) ls -LTdl "$d" \
  | awk '{printf "%-10s %+8s:%-8s %+8s %8s %2s %3s %s ", \
    $1, $3, $4, $5, $8, $7, $6, $9}' ; ls -Ld "${d}"
  ;; esac ; [ "$d" = "/" ] && return || dirper $(dirname "$d");}

symview () { # report directories and symlinks below args or stdin if $# is 0
    # for consistancy, please start relitative symlinks with a dot,
    # like this: ln -s ./tmp sym
    #  NOT this: ln -s tmp sym
    #
    # typical invocation:
    #   symview sym
    # or
    #   find . -maxdepth 1 -mindepth 1 | grep -v .git | viewsym | sort | awk '{printf "%- 40s %s\n",$1,$2}'
    # or
    #   symview . | sort | awk '{print $2,$1}'
    #
    local f fs;
    [ $# -gt 0 ] && while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1" )" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    #fs="$(echo "$fs" | sed 's/\.\///' | while IFS= read f ; do [ -f "${f%%/*}" ] && echo "${f%%/*}" ; done)"
    echo "$fs" | sed -e 's/\.\///' -e '/^$/d' | sort -u | while IFS= read i ; do
        find "$i" -exec stat -f "%N %Y" \{\} \; 2>/dev/null | sort -u | awk '{printf "%s\t%s\n", $2, $1}'
        done
    } # symview

cattrunc () {
    [ -t 1 ] && {
        local cols="$(tput cols)";
        awk -v cols="$((cols-1))" 'length > cols{$0=substr($0,0,cols)"_"}1'
    } || cat
  }

lock () { # lock to prevent concurent runs
 mkdir -p "$HOME/var/run"
 local name="$(basename "$0")"
 local LOCK="$HOME/var/run/${name}.pid"
 local NULL="$HOME/var/run/${name}.null"
 [ -f "$LOCK" ] && { chkerr "Lock exists: $LOCK" ; exit 1 ;} || echo "$$" >"$LOCK" ;}
unlock () { # remove lock and touch null file
 local name="$(basename "$0")"
 local LOCK="$HOME/var/run/${name}.pid"
 local NULL="$HOME/var/run/${name}.null"
 rm "$LOCK" ; touch "$NULL" ;}

case "$OS" in
Darwin|NetBSD)
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
 } # kwds
esac

uptime

# per $SHELL env
case "$SHELL" in
 *bash)
    export PS1="\${?%0} \u@\h:\w "
    #PROMPT_COMMAND
    export HISTCONTROL=erasedups
    export HISTFILE="${HOME}/.bash_history" HISTFILESIZE=9600 HISTSIZE=2600
    set -o ignoreeof # disable ctrl-d exit
    set -o errtrace  # any trap on ERR is inherited by shell functions
    set -o functrace # traps on DEBUG and RETURN are inherited by shell functions
    set -o pipefail  # exit pipeline on non-zero status (rightmost?)
 ;;
 *ksh)
  export HOSTNAME="$(hostname)"
  export PS1="\${?%0} \${USER}@\${HOSTNAME}:\${PWD} "
  export HISTFILE="${HOME}/.ksh_history" HISTSIZE=4096
  set -o ignoreeof # disable ctrl-d exit
  set -o braceexpand
  bind '^XH'=beginning-of-line
  bind '^XF'=end-of-line
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
        alias crontab="env EDITOR=$(which vi) crontab"
        alias vi="$(which vim)"
        export EDITOR='vim'
    }

import_pubkey () { # take a putty exported ssh key and make an authorized_keys line
local key_in="$(mktemp /tmp/pubkey-XXXXXX)"
[ -e "$1" ] && cat "$1" >"$key_in" || cat /dev/stdin >"$key_in"
printf "$(ssh-keygen -if "$key_in") " \
 && sed -e '/Comment/!d' -e 's/^Comment: "//' -e 's/"$//' "$key_in"
rm $key_in ;}

#   # ssh socket key and agent managent
#   printf "${_termrev}"
#   printf "User $USER "
#   ##[ -n "$SSH_AUTH_SOCK" ] || { # already forwarded by agent
#     [ "$(ssh-add -l 2>&1)" = "Could not open a connection to your authentication agent." ] \
#     && { printf "${USER}@$(hostname): "
#       eval $(ssh-agent)
#       export SSH_AGENT_ENV="SSH_AGENT_PID $SSH_AGENT_PID SHELL_PID $$" # ssh-agent env
#       } \
#     || ssh-add -l | cut -d\  -f 3- # show keys in SSH_AUTH_SOCK
#     [ "$(ssh-add -l 2>&1)" = "The agent has no identities." ] && {
#       ssh_ids="id_ed25519 id_rsa"
#       for ssh_id in $ssh_ids ; do # add each identity file
#         [ -e "$HOME/.ssh/$ssh_id" ] && { # try ssh-add
#           ssh-add "$HOME/.ssh/$ssh_id" ;}
#       done ;} # ssh_id
#   ##  } && { #echo "SSH_AUTH_SOCK forwarded by agent."
#   ##   ssh-add -l ;} # show keys in SSH_AUTH_SOCK
#   printf "${_ntermrev}"
#   ## shell logout trap, eg ~/.bash_logout ~/.ksh_logout
#   #[ -n "$SSH_AGENT_ENV" ] && set $SSH_AGENT_ENV && [ "$$" = "$4" ] \
#   #	&& { printf "Logout: " && kill $2 && echo $(hostname) $0 [$4] killed ssh-agent $2 \
#   #		|| { echo $(hostname) ssh-agent already died? 2>/dev/stderr ; exit 1 ;} ;}


# ssh socket key and agent managent
printf "${_termrev}"
printf "User ${USER}@${HOSTNAME}: "
[ "$SSH_AGENT_ENV" ] || {
    eval $(ssh-agent)
    ssh-add $(find $HOME/.ssh/ \( -name id_\* -o -name ${USER}\* \) -type f \! -name \*pub )
    export SSH_AGENT_ENV="SSH_AGENT_PID $SSH_AGENT_PID SHELL_PID $$" ;}
ssh-add -l | cut -d\  -f 3- # show keys in SSH_AUTH_SOCK
printf "${_ntermrev}"
## shell logout trap, eg ~/.bash_logout ~/.ksh_logout
#[ -n "$SSH_AGENT_ENV" ] && set $SSH_AGENT_ENV && [ "$$" = "$4" ] \
#	&& { printf "Logout: " && kill $2 && echo $(hostname) $0 [$4] killed ssh-agent $2 \
#		|| { echo $(hostname) ssh-agent already died? 2>/dev/stderr ; exit 1 ;} ;}

siff "$HOME/.profile.local" "~/.profile"

