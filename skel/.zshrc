#$Id: dot.zshrc 588 2010-08-26 19:12:02Z geo $

export HISTFILE=$HOME/.zsh_hist
export HISTSIZE=100000
export SAVEHIST=50000

setopt AUTO_PUSHD #Make cd push the old directory onto the directory stack.
setopt CHASE_DOTS # resolve symlinks to physical dir, when following '..'
setopt CHASE_LINKS # Resolve symbolic links to their true values when changing dir
setopt AUTO_LIST # Automatically list choices on an ambiguous completion.
setopt LIST_PACKED # completion matches in columns with different widths.
setopt LIST_TYPES # on completions, show the type of each file with a trailing identifying mark.
setopt APPEND_HISTORY # sessions will append their history list
setopt EXTENDED_HISTORY # command's beginning timestamp and the duration to history file. 
setopt HIST_EXPIRE_DUPS_FIRST # cause the oldest history event that has a duplicate to be lost
setopt HIST_FIND_NO_DUPS # do not display history duplicates in the line editor
setopt HIST_REDUCE_BLANKS # Remove superfluous blanks from each command line
setopt no_CLOBBER # require >| to truncate existing and >>| to append non-existing
setopt FLOW_CONTROL # flow control (usually ^S/^Q) is disabled 
setopt IGNORE_EOF # Do not exit on end-of-file. Require the use of exit or logout
setopt INTERACTIVE_COMMENTS # Allow comments even in interactive shells
setopt PRINT_EXIT_VALUE # Print the exit value of programs with non-zero exit status
setopt LONG_LIST_JOBS # List jobs in the long format by default.

# If this is an xterm set the title to user@host:dir
# or user@host (command line) while a job is running
[ -z "${TERM%xterm*}" ] \
 && {
  precmd () { print -Pn "\e]0;%n@%m: %~\a" }
  preexec () { print -Pn "\e]0;%n@%m: ($1)\a" }
 }

# Bind some keyboard functions
bindkey -e # prefer emacs key binding on the comand line
[ -z "${TERM%xterm*}" ] \
 && { 
  bindkey '\e[H' beginning-of-line
  bindkey '\e[F' end-of-line
  bindkey 'OH' beginning-of-line
  bindkey 'OF' end-of-line
  bindkey '[3~' delete-char
 } \
 || {
  bindkey '\e[1~' beginning-of-line
  bindkey '\e[4~' end-of-line
 }

# special PROMPT EXPANSION
# %L		The current value of $SHLVL.
# %!		Current history event number.
# %i		The line number currently being executed 
# %j		The number of jobs.
# %L		The current value of $SHLVL.
# %B (%b)	Start (stop) boldface mode.
# %E		Clear to end of line.
# %U (%u)	Start (stop) underline mode.
# %S (%s)	Start (stop) standout mode.
# %#		A `#' if the shell is running with privileges,  a  `%'  if  not.
# %~		Present working directory ($PWD). with ~ for $HOME
#PS1='%!%l %S%n@%m:%~%s %# '
#PS1='%L%j%l %S%n@%m:%~%s %# '
#PS1='%j%l %S%n@%m:%~%s %# '
#PS1=' %S%n@%m:%~%s %# '
#PS1=' %S%n@%m:%~%s '


[ -e "$HOME/.profile" ] && . "$HOME/.profile"

TRAPEXIT () {
[ -n "$SSH_AGENT_ENV" ] && set $SSH_AGENT_ENV && [ "$$" = "$4" ] \
	&& { printf "Logout: " && kill $2 && echo $(hostname) $0 [$4] killed ssh-agent $2 \
		|| { echo $(hostname) ssh-agent already died? 2>/dev/stderr ; exit 1 ;} ;}
}

