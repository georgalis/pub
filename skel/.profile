# ~/.profile

# (C) 2004-2022 George Georgalis unlimited use with this notice

# For Bourne-compatible shells (bash,ksh,zsh,sh)

# for interactive sessions only
/usr/bin/tty -s || return

# if running /bin/bash on a mac with homebrew bash available, switch
ps | grep "^[ ]*$$ " | grep -q bash 2>/dev/null \
  && { test -x /opt/homebrew/bin/bash \
        && { expr "$(/opt/homebrew/bin/bash --version)" \
            : "GNU bash, version ${BASH_VERSINFO[0]}\.${BASH_VERSINFO[1]}\.${BASH_VERSINFO[2]}" >/dev/null \
            || { # set SHELL and exec homebrew bash
                export SHELL="/opt/homebrew/bin/bash"
                exec env -i TERM="$TERM" COLORTERM="$COLORTERM" \
                SHELL="$SHELL" HOME="$HOME" LOGNAME="$LOGNAME" USER="$USER" \
                SSH_AGENT_PID="$SSH_AGENT_PID" SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
                SSH_AGENT_ENV="$SSH_AGENT_ENV" \
                "${SHELL}" -l
               } # BASH_VERSINFO doesn't match homebrew version
          } || return 1 # exec homebrew bash failed
     } || true # homebrew not available


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
chktrue () { [ "$*" ] && { stderr    "><> $* <><" ; return 0  ;} || return 1 ;} #:> err stderr args exit 1, noop if null
chkexit () { [ "$*" ] && { stderr    ">>> $* <<<" ; exit 1    ;} || true ;} #:> err stderr args exit 1, noop if null
logexit () { [ "$*" ] && { logger -s ">>> $* <<<" ; exit 1    ;} || true ;} #:> err stderr+log args exit 1, noop if null
siff () { local verb="${verb:-chktrue}" ; test -e "$1" \
        && { { . "${1}" && ${verb} "${2}: . ${1}" ;} || { chkerr "$FUNCNAME: fail in '$1' from '$2'" ; return 1 ;} ;} \
        || ${verb} "${2}: siff: no file $1" ;} #:> source arg1 if exists, on err recall args for backtrace
siffx () { local verb="${verb:-chktrue}" ; test -e "$1" \
        && { { . "${1}" \
          && { export -f $(grep '^[_[:alpha:]][_[:alnum:]]* () ' "$1" | sed 's/ () .*//' ) >/dev/null && devnul "  function export '^[^ ]* () '" ;} \
          && { export    $(grep '^[_[:alpha:]][_[:alnum:]]*='    "$1" | sed 's/=.*//'    ) >/dev/null && devnul "       var export '^[:alpha:][_[:alnum:]]*='" ;} \
          && ${verb} "${2}: . ${1}"
          } || { chkerr "${FUNCNAME} : fail in '$1' from '$2'" ; return 1 ;} ;} \
        || chkwrn "${2}: ${FUNCNAME} : no file $1 from '$2'" ;} #:> source arg1 if exists , on err recall args for backtrace
# verbosity, typically set to devnul, chkwrn, or chkerr
#verb="${verb:=devnul}"
#verb2="${verb2:=devnul}"
#verb3="${verb3:=devnul}"

validfn () { #:> validate function, compare unit hash vs operation env hash
    [ "$1" ] || {
      cat 1>&2 <<-'EOF'
		#:: $FUNCNAME {function}        ; returns {function-name} {hash}
		#:: $FUNCNAME {function} {hash} ; return no error, if hash match
		#:: the former is intended to provide data for the latter
		#:: env hashfn= to set the hashing function, "%08x %8x %s\n" cksum program
		EOF
      return 1 ;}
    ps | grep "^[ ]*$$ " | grep -q bash 2>/dev/null || { echo ">>> $0 : Not bash shell (62af847c) <<<" >&2 ; return 1 ;}
    local _hashfn
    [ "$hashfn" ] || { _hashfn () { declare -f "$1" | printf "%s %08x %08x\n" "$1" $(cksum) ;} && _hashfn="_hashfn" ;}
    [ "$_hashfn" ] || _hashfn="$hashfn" # for bugs... use stronger hash for nefarious env
    local fn="$(sed '/^[ ]*#/d' <<<"$1")"
    [ "$fn" ] || return 0 # drop comments
    shift || true
    local sum="$fn $*"
    local check="$( "$_hashfn" "$fn" )"
    [ "$*" ] || { echo "$check" ; return 0 ;} # provide hash data if none given to check
    [ "$sum" = "$check" ] || { # report hash data discrepancies on failed check
    cat 1>&2 <<-EOF
		>>>---
		$FUNCNAME error :
		 unit:'$sum'
		  env:'$check'
		<<<---
		EOF
    return 1 ;}
    } # validfn

# Now that validfn is defined, run the framework on expected functions...
#
# eg first, generate hashses of known functions...
#   for f in devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue chkexit logexit siff siffx validfn ; do validfn $f ; done
#
# then run validfn on that data to report if the functions have ever change
# print help if hash unit does not match hash from env
_help_skel () { echo '# ><> eval "$(curl -fsSL https://github.com/georgalis/pub/blob/master/skel/.profile)" <><' 1>&2
    echo 'export -f devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue chkexit logexit siff siffx validfn' 1>&2 ;}
test "$(declare -f validfn 2>/dev/null)" || { echo "$0 : validfn not defined" 1>&2 ; _help_sub ; return 1 ;}
while IFS= read a ; do
        validfn $a && true || { echo "validfn error : $a" 1>&2 ; _help_skel ; return 1 ;}
        done <<EOF
devnul 216e1370 0000001d
stderr 7ccc5704 00000037
chkstd ee4aa465 00000032
chkwrn 18c46093 0000005e
logwrn e5806086 00000061
chkerr 57d3ff82 0000005f
logerr ffddd972 00000062
chktrue 845489dd 00000064
chkexit 8b52b10f 0000005e
logexit e0f87299 00000061
siff 32bbcc06 00000113
siffx c8f57dbb 00000279
validfn c268584c 00000441
EOF

path_append () { # append $1 if not already in path
 echo $PATH | grep -E "(:$1$|^$1$|^$1:|:$1:)" 2>&1 >/dev/null \
  || export PATH="${PATH}:${1}" ;}
path_prepend () { # prepend $1 if not already in path
 echo $PATH | grep -E "(^$1:|^$1$)" 2>&1 >/dev/null \
  || export PATH="${1}:${PATH}" ;}

ckstat () { # return sortable stat data for args (OR stdin file list)
  # ckstat /etc/resolv.conf
  # 033cb35f01 .       16 6305e87b /etc/resolv.conf
  # inode\links . 0x_size  0x_date input
  # (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    chkwrn 'Return sortable stat data for args (OR stdin file list):'
    chkwrn 'inode\links . 0x-size 0x-mdate input'
    return 0 ;} || true
  local f fs
  [ $# -gt 0 ] && { fs="$1" ; shift || true ;}
  while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift || true ; done
  [ "$fs" ] || fs="$(cat)"
  [ "$OS" ] || local OS="$(uname)"
  [ "$OS" = "Linux" ]                      && _stat () { stat -c %i\ %h\ %s\ %Y "$1" ;} || true
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat () { stat -f %i\ %l\ %z\ %m "$1" ;} || true
  echo "$fs" | while IFS= read f; do
    [ -f "$f" ] && {
      _stat "$f" | awk -v f="$f" '{printf "%08x%02x . % 8x %08x %s\n",$1,$2,$3,$4,f}'
      } || chkerr "$FUNCNAME : not a regular file : $f"
    done # f
  } # ckstat ()

ckstatsum () { # return sortable stat data for args (OR stdin file list)
  # ckstatsum /etc/resolv.conf
  # 033cb35f01 b35a88ac       16 6305e87b /etc/resolv.conf
  # inode\links 0x_cksum  0x_size 0x_date input
  # (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    chkwrn 'Return sortable stat data for args (OR stdin file list):'
    chkwrn 'inode\links . 0x-size 0x-mdate input'
    return 0 ;} || true
  local f fs
  [ $# -gt 0 ] && { fs="$1" ; shift || true ;}
  while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift || true ; done
  [ "$fs" ] || fs="$(cat)"
  [ "$OS" ] || local OS="$(uname)"
  [ "$OS" = "Linux" ]                      && _stat () { stat -c %i\ %h\ %s\ %Y "$1" ;} || true
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat () { stat -f %i\ %l\ %z\ %m "$1" ;} || true
  echo "$fs" | while IFS= read f; do
    [ -f "$f" ] && {
      { _stat "$f" ; cksum <"$f" ;} | tr '\n' ' ' | awk -v f="$f" '{printf "%08x%02x %08x % 8x %08x %s\n",$1,$2,$5,$3,$4,f}'
      } || chkerr "$FUNCNAME : not a regular file : $f"
    done # f
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
        alias crontab='env EDITOR="\vi" crontab'
       #alias vi="$(which vim)"
       #export EDITOR='vim'
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



siffx "$HOME/.profile.local" "~/.profile"

{  export -f $(grep '^[_[:alpha:]][_[:alnum:]]* () ' ~/.profile | sed 's/ () .*//' )
   export    $(grep '^[_[:alpha:]][_[:alnum:]]*='    ~/.profile | sed 's/=.*//'    )
} && chktrue "~/.profile: . $HOME/.profile ; var func exports" \
  || chkerr  "~/.profile: fail in export $HOME/.profile"

chktrue "~/.profile"

