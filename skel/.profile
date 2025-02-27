# ~/.profile

# (c) 2004-2025 George Georgalis unlimited use with this notice
#
# For Bourne-compatible shells (bash,ksh,sh)
#
# https://raw.githubusercontent.com/georgalis/pub/master/skel/.profile

# for interactive sessions only
#/usr/bin/tty -s || return
test -t 0 && test -t 1 && test -t 2 || return 0

export EDITOR="vi"
export PAGER='less --jump-target=3'
export GPG_TTY=$(tty)
export HOSTNAME="$(hostname)"
export OS=$(uname)
# /etc/redhat-release  /etc/centos-release  /etc/os-release

umask 022
ulimit -c 1 # one byte core files memorialize their creation

# setup ls alias world
[ -x "$(which colorls 2>/dev/null)" ] && { # setup colorls
 #export LSCOLORS='xefxcxdxbxegedabagacad'
 #export CLICOLORS=$LSCOLORS
 # define reverse for directory color
 #export LSCOLORS='4x5x2x3x1x464301060203' # default, per man
  export LSCOLORS='x45x2x3x1x464301060203' # invert directory color
 alias    l='colorls -FGr'
 alias   lr='colorls -FG'
 alias   ll='colorls -AFGTlr'
 alias  llr='colorls -AFGTl'
 alias   lt='colorls -AFGTrt'
 alias  ltr='colorls -AFGTt'
 alias  llt='colorls -AFGTlrt'
 alias lltr='colorls -AFGTlt'
 alias   lS='colorls -AFGTlrS'
 alias  lSr='colorls -AFGTlS'
 } || true # echo "no colorls"
#
case "$OS" in
Darwin)
 export LSCOLORS='xefxcxdxbxegedabagacad' # invert directory color
 alias    l='ls -GFr'
 alias   lr='ls -GF'
 alias   ll='ls -AFTGlr  -D %Y%m%d_%H%M%S'
 alias  llr='ls -AFTGl   -D %Y%m%d_%H%M%S'
 alias   lt='ls -AFGTrt  -D %Y%m%d_%H%M%S'
 alias  ltr='ls -AFGTt   -D %Y%m%d_%H%M%S'
 alias  llt='ls -AFGTlrt -D %Y%m%d_%H%M%S'
 alias lltr='ls -AFGTlt  -D %Y%m%d_%H%M%S'
 alias   lS='ls -AFGTlrS -D %Y%m%d_%H%M%S'
 alias  lSr='ls -AFGTlS  -D %Y%m%d_%H%M%S'
 alias   t='tail -F'
 alias top='top -S -n24 -s4 -o cpu'
 alias   p='ps -ax -o uid,pid,command -ww'
 alias xattrc='xattr -c'
;; # Darwin
Linux)
 eval $(dircolors | sed 's/di=01;34/di=00;44/') # invert directory color
 alias    l='ls --color=auto -r'
 alias   lr='ls --color=auto'
 alias   ll='ls --color=auto -Alr   --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  llr='ls --color=auto -Al    --full-time --time-style=+%Y%m%d_%H%M%S'
 alias   lt='ls --color=auto -AFtr  --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  ltr='ls --color=auto -AFt   --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  llt='ls --color=auto -AFlrt --full-time --time-style=+%Y%m%d_%H%M%S'
 alias lltr='ls --color=auto -AFlt  --full-time --time-style=+%Y%m%d_%H%M%S'
 alias   lS='ls --color=auto -AFlrS --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  lSr='ls --color=auto -AFlS  --full-time --time-style=+%Y%m%d_%H%M%S'
 alias  t='tail --follow=name'
 alias  p='ps -e f -o pid,user,cmd --sort=user'
 #export PAGER='less -G --jump-target=2'
 #less -j does not take negative number any more Debian Bug report logs - #498746 http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=498746
;; # Linux
OpenBSD)
 alias t='tail -f'
;; # OpenBSD
NetBSD|FreeBSD|Dragonfly)
 alias    l='ls -Fr'
 alias   lr='ls -F'
 alias   ll='ls -AFTlr'
 alias  llr='ls -AFTl'
 alias   lt='ls -AFTrt'
 alias  ltr='ls -AFTt'
 alias  llt='ls -AFTlrt'
 alias lltr='ls -AFTlt'
 alias   lS='ls -AFTlrS'
 alias  lSr='ls -AFTlS'
 alias t='tail -F'
 alias top='top -S -I -s4 -o cpu'
 alias p >/dev/null 2>&1 || alias p='ps ax'
 [ "$TERM" = "vt220" ] && export TERM=xterm # adds color to some apps in console
 # fix colors in screen on amd64 XXX workaround
 #[ "$(uname -m)" = "amd64" -a "$TERM" = "xterm-color" ] && export TERM="xterm"
;; # NetBSD|FreeBSD|Dragonfly
esac # "$OS"

alias    g='grep'    # grep the regex
alias    v='grep -v' # grep -v the regex
alias    h='fc -l'   # list commands previously entered in shell.
alias    j='jobs -l' # list background jobs
alias    s='less -R' # less
alias    m='man $man_ops' ; export man_ops='-a'
alias  scp='scp -pr' # never not...
alias   cp='cp -ip'  # always
alias   mv='mv -i'   # why not
alias   rm='rm -i'   # sure
alias    d='diff -U 0'
b() { cd "$OLDPWD" ;} # previous directory
back() { cd "$OLDPWD" ;} # previous directory
#cal() { cal -h $@ ;}

# https://raw.githubusercontent.com/georgalis/pub/master/skel/.profile
# common functions for shell verbose management....
devnul() { return 0 ;}                                                 #:> drop args
stderr() {  [ "$*" ] && echo "$*" 1>&2 || true ;}                      #:> args to stderr, or noop if null
chkstd() {  [ "$*" ] && echo "$*"      || true ;}                      #:> args to stdout, or noop if null
chkwrn() {  [ "$*" ] && { stderr    "^^^ $*" ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
logwrn() {  [ "$*" ] && { logger -s "^^^ $*" ; return $? ;} || true ;} #:> wrn stderr+log args return 0, noop if null
chkerr() {  [ "$*" ] && { stderr    ">>> $*" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null
logerr() {  [ "$*" ] && { logger -s ">>> $*" ; return 1  ;} || true ;} #:> err stderr+log args return 1, noop if null
chktrue() { [ "$*" ] && { stderr    "><> $*" ; true      ;} || return 2 ;} #:> err stderr args exit 1, noop if null
chkexit() { [ "$*" ] && { stderr    ">>> $*" ; exit 1    ;} || true ;} #:> err stderr args exit 1, noop if null
logexit() { [ "$*" ] && { logger -s ">>> $*" ; exit 1    ;} || true ;} #:> err stderr+log args exit 1, noop if null
siffx() { local verb="${verb:-devnul}" s="$1" f='' b=''
    [ "$s" = "-n" -o "$s" = "--no-source" ] && { f="$2" b="$3" ;} || { f="$1" b="$2" ;}
    test -e "$f" || { chkwrn "${b} siffx: no file '$f'" && return 0 || return $? ;}
    [ "$s" = "$f" ] && { . "${f}" || { chkerr "$b siffx: source signal $? in '$f'" ; return 1 ;} ;}
    # if there is no match does it fail... and if export fails? pass test...
    {    export -f $(grep '^[_[:alpha:]][_[:alnum:]]*[ ]*() ' "$f" | sed 's/() .*//'; true ) >/dev/null    \
      && export    $(grep '^[_[:alpha:]][_[:alnum:]]*='   "$f" | sed 's/=.*//'  ; true ) >/dev/null ;} \
    && { ${verb} "$b siffx: export '${f}'" ;} \
    || { chkerr  "$b siffx: export signal $? in '$f'" ; return 1 ;} \
    } #:> source arg1 if exists , on err recall args for backtrace

# verbosity, typically set in ~/.profile.local to devnul, chkwrn, or chkerr
#verb="${verb:=devnul}"
#verb2="${verb2:=devnul}"
#verb3="${verb3:=devnul}"

path_append() { # append $1 if not already in path
 echo "$PATH" | grep -E "(:$1$|^$1$|^$1:|:$1:)" 2>&1 >/dev/null \
  || export PATH="${PATH}:${1}" ;}
path_prepend() { # prepend $1 if not already in path
 echo "$PATH" | grep -E "(^$1:|^$1$)" 2>&1 >/dev/null \
  || export PATH="${1}:${PATH}" ;}

ckstat() { # return sortable stat data for args (OR stdin file list)
  # ckstat /etc/resolv.conf
  # 033cb35f 01 .      16 6305e87b /etc/resolv.conf
  # inode links . 0x_size  0x_date input
  # (c) 2017-2023 George Georgalis <george@galis.org> unlimited use with this notice
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    chkwrn 'Return sortable stat data for args (OR stdin file list):'
    chkwrn 'inode\links . 0x-size 0x-mdate input'
    return 0 ;} || true
  local f fs
  [ $# -gt 0 ] && { fs="$1" ; shift || true ;}
  while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift || true ; done
  [ "$fs" ] || fs="$(cat)"
  [ "$OS" ] || local OS="$(uname)"
  [ "$OS" = "Linux" ]                      && _stat() { stat -c %i\ %h\ %s\ %Y "$1" ;} || true
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat() { stat -f %i\ %l\ %z\ %m "$1" ;} || true
  echo "$fs" | while IFS= read f; do
    [ -e "$f" ] && {
      # \0 will produce \200, which does not terminate a string but behaves as a null
      # per terminfo.5, so just use \200 to separate filnames with regex unfriendly char
      # _stat "$f" | awk '{printf "%07x %02x . % 8x %08x \200",$1,$2,$3,$4}'
      # \200 seems problematic for old mac bash, use this to extract filenames with spaces:
      # ckstat * | sed -e 's/^\([ ]*[[:xdigit:]]*\)\{2\} [.]*[ ]*[[:xdigit:]]*\([ ]*[[:xdigit:]]*\)\{2\} //'
      _stat "$f" | awk '{printf "%8x %2x . % 8x %08x ",$1,$2,$3,$4}'
      ls -dF "$f"
      # two ways to filter the names from the preceeding char
      # awk '{sub(/^[^\200]*\200/,"") ; print}' # filename follows the first \200
      # sed 's/^[ -~]*[^ -~]//' # first non-ascii match is \200, filename follows
      } || chkerr "$FUNCNAME : does not exist '$f'"
    done # f
  } # ckstat()

ckstatsum() { # return sortable stat data for args (OR stdin file list)
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
  [ "$OS" = "Linux" ]                      && _stat() { stat -c %i\ %h\ %s\ %Y "$1" ;} || true
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat() { stat -f %i\ %l\ %z\ %m "$1" ;} || true
  echo "$fs" | while IFS= read f; do
    [ -e "$f" ] && {
      # \0 will produce \200, which does not terminate a string but behaves as a null
      # per terminfo.5, so just use \200 to separate filnames with regex unfriendly char
      # { _stat "$f" ; cksum <"$f" ;} | tr '\n' ' ' | awk '{printf "%07x %02x %08x % 8x %08x \200",$1,$2,$5,$3,$4}'
      # \200 seems problematic for old mac bash, use this to extract filenames with spaces:
      # ckstatsum * | sed -e 's/^\([ ]*[[:xdigit:]]*\)\{2\} [.]*[ ]*[[:xdigit:]]*\([ ]*[[:xdigit:]]*\)\{2\} //'
      { _stat "$f" ; cksum <"$f" ;} | tr '\n' ' ' | awk '{printf "%8x %2x %08x % 8x %08x ",$1,$2,$5,$3,$4}'
      ls -dF "$f"
      # two ways to filter the names from the preceeding char
      # awk '{sub(/^[^\200]*\200/,"") ; print}' # filename follows the first \200
      # sed 's/^[ -~]*[^ -~]//' # first non-ascii match is \200, filename follows
      } || chkerr "$FUNCNAME : not a regular file : $f"
    done # f
  } # ckstatsum()

cks () { # return sortable stat data for args OR stdin file list
  # rev 677c63fa-20250106_151506
  # cks /var/run/resolv.conf
  #  c0eb521  1 .      1ab 677c76ff /var/run/resolv.conf
  # inode links .     size     date input
  # (c) 2017-2025 George Georgalis <george@galis.org> unlimited use with this notice
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    chkwrn 'Return sortable hex stat data for args OR stdin file list:'
    chkwrn 'inode links . size mdate file'
    return 0 ;} || true
  local f= fs= OS=
  while [ $# -gt 0 ]; do fs+="$1"$'\n' ; shift ; done ; fs="${fs%$'\n'}" ; [ -z "$fs" ] && read -d '' fs || true
  read OS < <(uname)
  [ "$OS" = "Linux" ]                      && _stat() { stat -c %i\ %h\ %s\ %Y "$1" ;} || true
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat() { stat -f %i\ %l\ %z\ %m "$1" ;} || true
  while IFS= read f; do
    [ -h "$f" ] && { chkwrn "$FUNCNAME : a symbolic link '$f'" ;} || true
    [ -e "$f" ] && { # use this to extract filenames with spaces: awk '{print substr($0, index($0,$6))}'
      awk '{printf "%8x %2x . % 8x %08x ",$1,$2,$3,$4}' < <(_stat "$f")
      # purge listing decoration for executable, symbolic link, socket, whiteout, and FIFO, but not directory
      sed -e 's/[*@=%|]$//' < <(ls -dF "$f")
      } || chkerr "$FUNCNAME : does not exist '$f'"
    done <<<"$fs" # f
  } # cks 6305e87b

cksh () { # return sortable stat and hash data for args OR stdin file list
  # rev 677c9c44-20250106_191506
  # chsh /etc/resolv.conf
  #  c0eb521  1 3a9954      1ab 677c76ff /var/run/resolv.conf
  # inode links shake256-x3 size    date input
  # (c) 2017-2025 George Georgalis <george@galis.org> unlimited use with this notice
  [ "$1" = "-h" -o "$1" = "--help" ] && {
    chkwrn 'Return sortable hex stat and hash data for args OR stdin file list:'
    chkwrn 'inode links hash size mdate file'
    return 0 ;} || true
  local f= fs= OS=
  while [ $# -gt 0 ]; do fs+="$1"$'\n' ; shift ; done ; fs="${fs%$'\n'}" ; [ -z "$fs" ] && read -d '' fs || true
  read OS < <(uname)
  [ "$OS" = "Linux" ]                      && _stat() { stat -c %i\ %h\ %s\ %Y "$1" ;} || true
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat() { stat -f %i\ %l\ %z\ %m "$1" ;} || true
  while IFS= read f; do [ -f "$f" -a ! -h "$f" ] && { # only process regular files
 # use this to extract filenames with spaces: awk '{print substr($0, index($0,$6))}'
 # shake256 -xoflen 3 is okay for integrity check, and compatible with longer crypto reference
      # sed to purge symbols for executable, and whiteout listing decoration
      awk '{printf "%8x %2x %06s % 8x %08x ",$1,$2,$5,$3,$4}' < <( tr '\n' ' ' \
        < <( _stat "$f" && awk '{print $2}' < <(openssl shake256 -xoflen 3 -hex <"$f"))) \
      && sed -e 's/[*%]$//' < <(ls -dF "$f") \
      || { chkerr "$FUNCNAME : internal error '$f'" ; return 1 ;}
      } || { [ -h "$f" ] && { chkwrn "$FUNCNAME : symbolic link '$f'" ;} \
                         || { chkwrn "$FUNCNAME : not a regular file '$f'" ;} ;} # warn for non-files
    done <<<"$fs" # f
  } # cksh 677c9c44-20250106_191506 ckstatsum

ascii_filter() { while IFS= read a ; do echo "$a" | strings -e s ; done ;}

dufiles() { #:> report the number of files along with total disk use of directory arg1
    [ "$1" ] || set .
    { du -sh "$1" ; echo "#" ; find "$1" -type f | wc -l ; echo files ;} \
       | tr '\n' ' ' ; echo ;}

dusum() { # sort $1 (defaults to $PWD) according to disk use, also show cumulative sum.
[ -z "$1" ] && d="./" || d="$1"
find "$d" -maxdepth 1 -mindepth 1 -print0 \
  | xargs -0 du -sk | sort -n \
  | awk '{sum += $1; printf "%+11sk %+10sk %s %s %s\n", sum, $1, $2, $3, $4}' ;}

dirper() { # reveal dir permissions of "$*" or "$PWD"
  local d="$*";d="${d#./}";[ -z "$d" -o "$d" = "." -o "$d" = "./" ] && d="$PWD"
  [ "$(dirname "$d")" = '.' ] && d="$PWD/$d";
  case "$(uname)" in Linux) ls -Ldl --full-time "$d" ;; *) ls -LTdl "$d" \
  | awk '{printf "%-10s %+8s:%-8s %+8s %8s %2s %3s %s ", \
    $1, $3, $4, $5, $8, $7, $6, $9}' ; ls -Ld "${d}"
  ;; esac ; [ "$d" = "/" ] && return || dirper $(dirname "$d");}

symview() { # report directories and symlinks below args or stdin if $# is 0
    # for consistency, please start relative symlinks with a dot,
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

lock() { # lock to prevent concurrent runs
 mkdir -p "$HOME/var/run"
 local name="$(basename "$0")"
 local LOCK="$HOME/var/run/${name}.pid"
 local NULL="$HOME/var/run/${name}.null"
 [ -f "$LOCK" ] && { chkerr "Lock exists: $LOCK" ; exit 1 ;} || echo "$$" >"$LOCK" ;}
unlock() { # remove lock and touch null file
 local name="$(basename "$0")"
 local LOCK="$HOME/var/run/${name}.pid"
 local NULL="$HOME/var/run/${name}.null"
 rm "$LOCK" ; touch "$NULL" ;}

# per $SHELL env
case "$SHELL" in
 *bash)
    export PS1="\${?%0} \u@\h:\w "
    #PROMPT_COMMAND
    export HISTCONTROL=erasedups
    export HISTFILE="${HOME}/.bash_history" HISTFILESIZE=9600 HISTSIZE=2600
    # Remove @ (/etc/hosts) and = (pwd files) from tab expansion
    #export COMP_WORDBREAKS="${COMP_WORDBREAKS//@}" # Remove @ (/etc/hosts) from tab expansion
    #export COMP_WORDBREAKS="${COMP_WORDBREAKS//=}" # Remove = (pwd files) from tab expansion
    #read -d '' COMP_WORDBREAKS < <(tr -d '@=' <<<"$COMP_WORDBREAKS")
    #read -d '' < <(tr -d '@=' <<<"$COMP_WORDBREAKS") ; export COMP_WORDBREAKS="$REPLY"
    #REPLY=${COMP_WORDBREAKS//[=@]} ; export COMP_WORDBREAKS="$REPLY"
    REPLY=${COMP_WORDBREAKS//[=@]}
    #declare -p REPLY
    export COMP_WORDBREAKS="$REPLY"
    #declare -p COMP_WORDBREAKS
    #sed -e 's/^/REPLY           X/' -e 's/$/X/' <<<"$REPLY"
    #sed -e 's/^/COMP_WORDBREAKS X/' -e 's/$/X/' <<<"$COMP_WORDBREAKS"
    set -o ignoreeof # disable ctrl-d exit
    set -o errtrace  # any trap on ERR is inherited by shell functions
    set -o functrace # traps on DEBUG and RETURN are inherited by shell functions
    set -o pipefail  # exit pipeline on non-zero status (rightmost?)
    #set -o autocd    # if interactive, cd directory when executed as a command
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

import_pubkey() { # take a putty exported ssh key and make an authorized_keys line
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


# ssh socket, key, and agent management
[ "$SSH_AGENT_ENV" ] || {
    tput dim
    #_ssh_agents=$(ps ax | awk '/ ssh-agent$/ {print $1}' )
    #[ "$_ssh_agents" ] && echo extra agents: $_ssh_agents ; unset _ssh_agents
    # rs -tz -g1 -w$(($(tput cols)-8))
    #fmt 65 < <(awk 'BEGIN{print "extra agents:"} / ssh-agent$/ {print $1}' < <(ps ax))
    tr '\n' ' ' < <(awk 'BEGIN{print "agents:"} / ssh-agent$/ {print $1}' < <(ps ax)) ; echo
    printf "User ${USER}@${HOSTNAME}: "
    eval $(ssh-agent)
    export SSH_AGENT_ENV="SSH_AGENT_PID $SSH_AGENT_PID SHELL_PID $$"
    ssh-add -q
    tput sgr0
    }

# shell logout trap, eg ~/.bash_logout ~/.ksh_logout
#[ -n "$SSH_AGENT_ENV" ] && set $SSH_AGENT_ENV && [ "$$" = "$4" ] \
#	&& { printf "Logout: " && kill $2 && echo $(hostname) $0 [$4] killed ssh-agent $2 \
#		|| { echo $(hostname) ssh-agent already died? 2>/dev/stderr ; exit 1 ;} ;}

siffx "$HOME/.profile.local" "~/.profile (63b8877f)" && chktrue "$_ $HOME/.profile.local" || { return 2 ; exit 3 ;}
# use -n to not source this file, just report it has been sourced, now that the end is reached
siffx -n "$HOME/.profile"    "~/.profile (642a7466)" && chktrue "$_ $HOME/.profile" || { return 2 ; exit 3 ;}
# also be verbose about agent status
tput dim
echo "User ${USER}@${HOSTNAME}: "
tput bold
#echo $(ssh-add -l | awk '{$1="";$2=""; print}' | tr '\n' ',' | sed 's/[.,]*$/./')
ssh-add -l | awk '{$1="";$2=""; print}'
tput sgr0
