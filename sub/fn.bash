#!/usr/bin/env bash

# (c) 2004-2023 George Georgalis unlimited use with this notice
#
# Sundry functions, and commensurate alias, env.
#
# For bash compatible shells
#
# https://github.com/georgalis/pub/blob/master/sub/fn.bash

_help_skel() {
  cat 1>&2 <<'eof'
>>>---
  eval "$(curl -fsSL --insecure \
    https://raw.githubusercontent.com/georgalis/pub/master/skel/.profile)"
  export -f devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue \
    chkexit logexit siffx validfn
---<<<
eof
  }

# one confusion at a time, fn.bash from ~/.profile.local, eg
# siffx "$HOME/sub/fn.bash" || { return 1 ; exit 2 ;}
declare -f chktrue >/dev/null || { _help_skel ; return 2 ; exit 3 ;}

[ "${SHELL##*/}" = "bash" ] && { # alias, to restore login env, iff no active jobs.
    alias _env='tput sgr0 ; chkerr "$(jobs -l)" \
        && exec env -i TERM="$TERM" COLORTERM="$COLORTERM" \
            SHELL="$SHELL" HOME="$HOME" LOGNAME="$LOGNAME" USER="$USER" \
            SSH_AGENT_PID="$SSH_AGENT_PID" SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
            SSH_AGENT_ENV="$SSH_AGENT_ENV" \
            verb="$verb" verb1="$verb1" verb2="$verb2" \
            '"${SHELL} -l"
    alias _env_verb='tput sgr0 ; chkerr "$(jobs -l)" \
        && exec env -i TERM="$TERM" COLORTERM="$COLORTERM" \
            SHELL="$SHELL" HOME="$HOME" LOGNAME="$LOGNAME" USER="$USER" \
            SSH_AGENT_PID="$SSH_AGENT_PID" SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
            SSH_AGENT_ENV="$SSH_AGENT_ENV" \
            verb="chkwrn" verb1="chkwrn" verb2="chkwrn" \
            '"${SHELL} -l"
    alias _env_noverb='tput sgr0 ; chkerr "$(jobs -l)" \
        && exec env -i TERM="$TERM" COLORTERM="$COLORTERM" \
            SHELL="$SHELL" HOME="$HOME" LOGNAME="$LOGNAME" USER="$USER" \
            SSH_AGENT_PID="$SSH_AGENT_PID" SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
            SSH_AGENT_ENV="$SSH_AGENT_ENV" \
            '"${SHELL} -l"
    }

export bash_path="$(which bash)"
# if running bash, and bash_path is different, switch, iff no active jobs.
ps | grep "^[ ]*$$ " | grep bash >/dev/null 2>&1 \
  && { test -x $bash_path \
        && { expr "$("$bash_path" --version)" \
            : "GNU bash, version ${BASH_VERSINFO[0]}\.${BASH_VERSINFO[1]}\.${BASH_VERSINFO[2]}(${BASH_VERSINFO[3]})-${BASH_VERSINFO[4]} (${BASH_VERSINFO[5]})" >/dev/null \
            || { tput sgr0 ; chkerr "$(jobs -l)" \
                  && exec env -i TERM="$TERM" COLORTERM="$COLORTERM" \
                    SHELL="${bash_path}" HOME="$HOME" LOGNAME="$LOGNAME" USER="$USER" \
                    SSH_AGENT_PID="$SSH_AGENT_PID" SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
                    SSH_AGENT_ENV="$SSH_AGENT_ENV" \
                    verb="$verb" verb1="$verb1" verb2="$verb2" \
                    "$bash_path" -l ;} # replace, BASH_VERSINFO doesn't match
           } && { echo "<>< $bash_path ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}(${BASH_VERSINFO[3]})-${BASH_VERSINFO[4]}" ;} \
        || return 1 # exec failed...
     } || true # not bash, OR bash_path unavailable OR same version

# earlier and we would normally see it twice...
uptime

validex () { #:> validate executable, compare unit hash vs operation env hash
    [ "$1" ] || {
      cat 1>&2 <<-EOF
		#:: $FUNCNAME {executable}        ; returns {executable} {hash}
		#:: $FUNCNAME {executable} {hash} ; return no error, if hash match
		#:: the former is intended to provide data for the latter
		#:: env hashex= to set the hashing function, other than the cksum default
		EOF
      return 1 ;}
    ps | grep "^[ ]*$$ " | grep bash >/dev/null 2>&1 || { echo ">>> $0 : Not bash shell (62af847c) <<<" >&2 ; return 1 ;}
    local exin="$(sed  -e 's/#.*//' -e 's/^[ ]*//' -e 's/[ ]*$//' -e '/^$/d' <<<"$1")"
    [ "$exin" ] || return 0 # drop comments
    which "$exin" >/dev/null || { chkwrn "$FUNCNAME : executable not in PATH, '$exin' (643d9a87)" ; return 1 ;}
    local _hashfn=''
    [ "$hashex" ] || { _hashex () { cat $(which "$1") | printf "%s %08x %08x\n" "$1" $(cksum) ;} && _hashex="_hashex" ;}
    [ "$_hashex" ] || _hashex="$hashex" # for env sanity... use crypto hash for security...
    shift || true
    local sum="$exin $*"
    local check="$( "$_hashex" "$exin" )"
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
    } # validex 64399fcb 20230414 1147 Fri 14 Apr PDT

validfn () { #:> validate function, compare unit hash vs operation env hash
    [ "$1" ] || {
      cat 1>&2 <<-EOF
		#:: $FUNCNAME {function}        ; returns {function-name} {hash}
		#:: $FUNCNAME {function} {hash} ; return no error, if hash match
		#:: the former is intended to provide data for the latter
		#:: env hashfn= to set the hashing function, "%08x %8x %s\n" cksum program
		EOF
      return 1 ;}
    ps | grep "^[ ]*$$ " | grep bash >/dev/null 2>&1 || { echo ">>> $0 : Not bash shell (62af847c) <<<" >&2 ; return 1 ;}
    local _hashfn=''
    [ "$hashfn" ] || { _hashfn () { declare -f "$1" | printf "%s %08x %08x\n" "$1" $(cksum) ;} && _hashfn="_hashfn" ;}
    [ "$_hashfn" ] || _hashfn="$hashfn" # for env sanity... use crypto hash for security...
    local fn="$(sed  -e 's/#.*//' -e 's/^[ ]*//' -e 's/[ ]*$//' -e '/^$/d' <<<"$1")"
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
# eg first, generate hashes of known functions...
#   for f in devnul stderr chkstd chkwrn logwrn chkerr logerr chktrue chkexit logexit siffx validfn ; do validfn $f ; done
#
# then run validfn on that data to report if the functions have ever change
# print help if hash unit does not match hash from env --insecure
test "$(declare -f validfn 2>/dev/null)" || { echo "$0 : validfn not defined (6542c8ca)" 1>&2 ; _help_sub ; return 1 ;}
while IFS= read a ; do
        validfn $a && true || { echo "validfn error : $a (6542c8d6)" 1>&2 ; _help_skel ; break 1 ;}
        done <<EOF
devnul 216e1370 0000001d
stderr 7ccc5704 00000037
chkstd ee4aa465 00000032
chkwrn 2683d3d3 0000005c
logwrn f279f00e 0000005f
chkerr 4f18299d 0000005b
logerr 2db98372 0000005e
chktrue 1f11f91d 0000005c
chkexit e6d9b430 0000005a
logexit 235b98c9 0000005d
siffx c20a9040 000002f7
validfn 6fcde5cc 0000046d
EOF

fnhash () { # gen validfn data from env and fn names in file (arg1), for repo commit comments
    # search for expected hash from repo log and find matching function revision
    local f="$1" a=''
    test -e "$f" || { chkwrn "${FUNCNAME}: no file '$f' (6542c8b8)" && return 0 || return $? ;}
    # no fn match no fail...
    # helpful for 'git commit -m "bugfix $(fnhash file)" file'
    printf "\n\n%s\n" "# $(git rev-parse --show-prefix "$f" | tr -d '\n' ; echo)"
    grep '^[_[:alpha:]][_[:alnum:]]*[ ]*() ' "$f" | sed 's/() .*//' \
        | sort -u | while read a ; do validfn "$a" ; done
    } #:> source arg1 if exists , on err recall args for backtrace

# fortify the shell with git alias
alias   gstatus='git status --short'
alias   gls='git ls-files'
alias   gdf='git diff --name-only'
alias gdiff='git diff --minimal -U0'
alias  gadd='git add'
alias  gcom='git commit'
alias gamend='git commit --amend --force-with-lease' # --no-edit may be prefered
alias gpush='git push'
alias gpull='git pull'
alias   gbr='git branch'
alias   gco='git checkout'
#alias  gmv='git mv' # it can get messy, do it manually
alias  glog='git log'
alias  gref='git reflog'
alias  grst='git reset HEAD'
# RESTORE FILES  #  git checkout -- {opt-file-spec}
# UNDO ADD       #  git reset       {opt-file-spec}
# SEARCH COMMITS #  git log -G'{regex}' --full-history --all
#=======================================================
# https://git-scm.com/book/en/v2/Git-Tools-Reset-Demystified
# Commit hash, at least four characters and unambiguous beginning
#
# Three Trees
#  HEAD    : Last repo commit, next parent
#  Index   : Local proposed, next repo commit
#  Working : Sandbox
#                           HEAD  Index Workdir  Safe?
#==== Repo Commit ===========================================
#  reset --soft [commit]     REF    -      -      YES
#  reset        [commit]     REF   YES     -      YES
#  reset --hard [commit]     REF   YES    YES      -
#  checkout     <commit>     HEAD  YES    YES     YES
#==== File =============================================
#  reset    [commit] <paths>  -    YES     -      YES
#  checkout [commit] <paths>  -    YES    YES      -
#=======================================================
# https://git-scm.com/docs/git-reset#_discussion
# https://git-scm.com/docs/giteveryday
# https://git-scm.com/book/en/v2/Git-Basics-Undoing-Things
#
# git status # generic command
# gstatus    # alias for git short form status of $@
gst () { # short form status of $@ (or pwd repo), sorted
  git status --short $@ | sed -e 's/^ /_/' -e 's/^\(.\) /\1_/' | sort ;}
 #git status --short $@ | awk '{s=$1; $1=""; sub(/[ ]* /,//,$2); printf "%-2s%s\n",s,$0}' | sort ;}
gsta () { # git short form status of all repos below $@ (or pwd repo), sorted
  local start=$@
  [ "$start" ] || start='.'
  find $start -name .git -type d | while IFS= read a ; do
   ( cd "${a%/*}" ; gst ) | awk  -v a="${a%/*}/./" '{printf "%-2s",$1; $1=""; $2=a$2; printf "%s\n",$0}'
   done | sort ;}
gstat () { # find uncommitted changes to all repos below $@ (or current repo), sorted by time
  # reports files with <space> in name as irregular... ("read a" doesn't evaluate quotes inserted by git)
  gsta $@ | sed 's/^...//' | while IFS= read a ; do ckstat "$a" ; done \
    | sort -k5 | awk -F "\t" '{print $3}' ;}
gcfg () { # report all the git config and where it comes from, repo dir may be specified as arg1
  local a= b= d="$1" e="$OLDPWD" p=
  [ "$d" ] || d='.'
  [ -d "$d" ] || { chkerr "$FUNCNAME : '$d' not a dir" ; return 1 ;}
  read p < <(pwd -P)
  cd "$d" || { chkerr "$FUNCNAME : cannot cd to '$d'" ; return 1 ;}
  read b < <(git rev-parse --show-toplevel)
  git config --list | sed -e 's/=.*//' | sort -u \
    | while read a; do git config --show-origin --get $a \
      | awk -va="$a" -vb="$b" '{sub(/file:.git/,b"/.git");sub(/^file:/,"");print $1" "a"="$2}'
      done | sort
  cd "$e" ; cd "$p" # restore the working dir and the old working dir
  } # 665104f8-20240524_142150

which ci >/dev/null 2>&1 && {
_rcs () { # local rcs function
    # unfortunatly rcs predates modern documentation...
    # this wrapper handles basic "capture a file revision"
    #   _rcs {filename} "{message}"
    # 
    # Show changes since last checkin revision
    #   rcsdiff {filename}
    #
    # Review revision information for filename1:
    #   rlog filename1
    # 
    # Restoring revision2 of filename1 to filename3
    #   co -p -r"revision2" "filename1" > "filename3"
    # 
    # rlog Options
    #   -L  : Ignore RCS files with no locks set
    #   -R  : Print only the name of the RCS file
    #   -h  : Print only the header of the RCS file
    #   -t  : Print the descriptive text
    #   -b  : Print information about all branches
    #   -d[date] : Select revisions within date range
    #   -l[login] : Select revisions checked in by specified user
    #   -r[rev] : Select revisions based on revision number
    #   -s[state] : Select revisions based on state
    #   -w[login] : Select revisions checked in by specified user
    # co (Checkout) Options
    #   -l  : Lock the checked-out revision
    #   -u  : Unlock the checked-out revision
    #   -p  : Print the revision to standard output
    #   -q  : Quiet mode; suppress normal output
    #   -f[rev] : Force overwrite of working file
    #   -r[rev] : Retrieve specified revision
    #   -M  : Set the modification time to the date of the retrieved revision
    #   -ksubst : Specify keyword substitution mode
    #   -d[date] : Retrieve the latest revision no later than date
    #   -s[state] : Retrieve revision with specified state
    #   -w[login] : Retrieve revision checked in by specified user
    # ci (Checkin) Options
    #   -l      : Locks the file after check-in. This allows you to continue editing.
    #   -u      : Unlocks the file after check-in. This is the default behavior.
    #   -r[rev] : Specifies the revision number to assign to the new revision.
    #   -f[rev] : Forces a check-in even if there are no changes.
    #   -k      : Suppresses expansion of keywords in the file.
    #   -m[msg] : Specifies a log message for the revision.
    #   -t[txtfile] : Uses the contents of txtfile as the descriptive text.
    #   -q      : Runs in quiet mode, suppressing normal output.
    #   -d[date] : Uses the specified date for the check-in date.
    #   -w[login] : Uses the specified login name as the author.
    #   -nname  : Assigns a symbolic name to the revision.
    # Additional RCS (Revision Control System) Commands
    #   rcs       : Creates RCS files or changes their attributes
    #   rcsdiff   : Compares RCS revisions
    #   rcsmerge  : Merges RCS revisions
    #   ident     : Identifies RCS keyword strings in files
    #   rcsclean  : Removes working files that are unchanged
    #   rcsbind   : Associates RCS revisions with symbolic names
    #   rcsfreeze : Freezes a configuration of versions
    #   merge     : Three-way file merge (not RCS-specific, but often used with RCS)
    #   rcsinfo   : Extracts RCS information
    #   rcsparse  : Parses RCS files
    #   rcsrev    : Extracts RCS revision information
    local invoke="$FUNCNAME $*"
    local orig_mode= os= ; read os < <(uname)
    test -f "$1" || { chkerr "$invoke : cannot use '$1' (66833375)"; return 1 ;}
    case "$os" in
        Linux)  read orig_mode < <(stat -c %a    "$1");;
        Darwin) read orig_mode < <(stat -f "%Lp" "$1");;
        esac # better test that because OS could be another...
    [[ ${#orig_mode} == 3 || ${#orig_mode} == 4 ]] && [[ $orig_mode =~ ^[0-7]+$ ]] \
        || { chkerr "$invoke : mode probe, '$orig_mode' not sane for file '$orig_mode' (66837150)"; return 1 ;}
    ci -m"$invoke" -l -t-$FUNCNAME -q "$1" || { chkerr "$invoke : unable to check-in '$1' (6683351a)"; return 1 ;}
    chmod "$orig_mode" "$1" # the ci -l will reset modes
    } # 66834066-20240701_164844
} # only if rcs is installed

## shell script fragments
# local infile inpath infilep
# infile="${f##*/}"                                              # infile  == basename f
# expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname f
# infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f
# name="$(sed 's/.[^.]*$//' <<<"$infile")"                       # name    == infile w/o extension
# expr "$0" : ".*/" >/dev/null && cd "${0%/*}"                   # cd dirname $0
# find -E /mnt \( -regex '/mnt(/local|/%|/bak)' -prune         \) -o -type d
# find -E /mnt \( -regex '/mnt(/local|/%|/bak)' -prune -type f \) -o -type f

tss () { # timestamp highres and pass through args
    local a="$*"
    [ "$(which tai64n)" -a "$(which tai64nlocal)" ] \
        && { set $(echo | tai64n | sed -e 's/^\(@4[0]*\)\([[:xdigit:]]\{8\}\)\([[:xdigit:]]\{8\}\)\(.*\)/\1\2\3\4 \2 \3/')
             { echo $2 $3 ; tai64nlocal <<<$1 | sed -e 's/-//g' -e 's/:\([^:]*\)$/ \1/' -e 's/.\{4\}$//' ;} | tr '\n' ' ' ;} \
        || { set $(date +%s | awk '{printf "@4%015x%08d  %8x %08d\n",$1,0,$1,0}')
             { echo $2 $3 ; date -j -r $((0x$2)) "+%Y%m%d %H:%M %0S.00000" ;} | tr '\n' ' ' ;}
      echo "$a" ;}
      # 64c471f9 00000000 20230728 1857 13.00000
      # 64c47234 17284a94 20230728 1858 02.38851

ts () { # timestamp lowres and pass through args
    local a="$*"
    [ "$(which tai64n)" -a "$(which tai64nlocal)" ] \
      && { set $(echo | tai64n | sed -e 's/^\(@4[0]*\)\([[:xdigit:]]\{8\}\)\([[:xdigit:]]\{8\}\)\(.*\)/\1\2\3\4 \2/')
            { echo $2    ; tai64nlocal <<<$1 | sed -e 's/-//g' -e 's/:\([^:]*\)$//'
              date -j -r $((0x$2)) "+%a %e %b %Z" ;} | tr '\n' ' ' ;} \
      || { set $(date +%s | awk '{printf "@4%015x%08d  %8x %08d\n",$1,0,$1,0}')
           { echo $2 ; date -j -r $((0x$2)) "+%Y%m%d %H:%M %a %e %b %Z" ;} | tr '\n' ' ' ;}
      echo "$a" ;}
      # 64c47437 20230728 1906 Fri 28 Jul PDT
      # 64c47688 20230728 1916 Fri 28 Jul PDT

tj () { # journal timestamp, [tai sec]-yyyymmdd_hhmmss {args}
    local a ; read a < <(tai64n <<<"$*")
    sed -e 's/[-:]//g' -e 's/\.[^ ]*//' -e 's/ /_/' -e "s/^/${a:9:8}-/" < <(tai64nlocal <<<"$a")
    } # 6625d27f-20240421_195901
tjj () { # journal timestamp [tai sec]-yyyymmdd_hhmmss (hh:mm PM Sun dd mth PDT) {args}"
    local a ; read a < <(tai64n <<<"$*")
    read b < <(sed -e 's/[-:]//g' -e 's/\..*//' < <(tai64nlocal <<<"$a") )
    read b < <(date -j -f "%Y%m%d %H%M%S" "$b" "+(%I:%M %p %a %e %b %Z)")
    sed -e 's/[-:]//g' -e 's/\.[^ ]*//' -e 's/ /_/' -e "s/^/${a:9:8}-/" -e "s/ / $b /" < <(tai64nlocal <<<"$a")
    } # 6625d8a4-20240421_202514 tjj

which tmux >/dev/null 2>&1 && \
tmu () { # tmux intuitive wrapper
    [ "$1" = "-h" -o "$1" = "--help" ] && {
    echo 'List sessions, attach last, or create session 0,
  exit with signal and list remaining sessions.
  * Use "-s" or "--sessions" as arg for report of running sessions
  * Use "-a" or "--attach" to attach to most recent active session
  * Use "{name}" to create and/or attach to named session
  * Default session (no args) is "0"'
  return 0 ;}
    _active_tmu() { local a=
        tmux list-sessions -F '#{session_name} #{session_activity}' 2>/dev/null \
            | column -t | sort -k2n \
            | while IFS= read -r a ; do set $a ; echo -n "$1 " ; date -r $2 ; done \
            | awk '{printf "%8s : %s %s %s %s %s %s\n",$1,$2,$3,$4,$5,$6,$7}' ;}
    local sig= args=
    [ "$@" ] && local args=$@
    [ "$1" = "-a" -o "$1" = "--attach" -o -z "$args" ] \
        && args="$( _active_tmu | awk 'END {print $1}')"
    [ "$1" = "-s" -o "$1" = "--sessions" ] \
        && { _active_tmu ; return $? ;}
    [ "$args" ] || args=0
    tmux new -A -s $args ; sig=$?
    _active_tmu
    return $sig
    } || true # 6429e6a6 20230402 1333 Sun 2 Apr PDT

revargs () {
    local a out
    out="$1" ; shift || true
    while test $# -gt 0 ; do out="$1 $out" ; shift || true ; done
    echo "$out"
    }

kwds () { # convert stdin to unique words (at least arg1 chars) sorted on length, to stdout
  local c="$1"
  [ "$c" ] || c=1
  [ "$c" -ge 0 ] || c=0
  tr -c '[:alpha:]' ' ' \
  | tr '\ ' '\n' \
  | tr '[:upper:]' '[:lower:]' \
  | sort -ru \
  | while read w; do [ "${#w}" -ge "$c" ] && echo "${#w} ${w}" ; done \
  | sort -rn \
  | awk '{print $2}' \
  | tr '\n' '\ '
  echo
 } # kwds

cf () { #:> on terminal output, fold long lines on words
    [ -t 1 ] && {
        local cols="$(tput cols)"
        fold -s -w $cols
        } || cat
    } # cf formally catfold
ct () { #:> on terminal output, truncate lines to width
    [ -t 1 ] && {
        local cols
        read cols < <(tput cols);
        awk -v cols="$((cols))" 'length > cols{$0=substr($0,0,cols)""}1'
        } || cat
    } # ct formally cattrunc

_youtube_video_list () {
  local id="$1" d="$2" xs=$(xs)
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "6542c9fc : no id? (6542ca44)" ; return 1 ;}
  read id < <(sed "s/\([?&]\)si=................[&]*/\1/" <<<"$id") # squash trackers from url
  [ "$d" ]  || read -p "directory: " d
  [ -d "$d" ] || d="$(pwd -P)"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "$FUNCNAME : invalid dir '$d' (6542c62a)" ; return 1 ;}
  [ "$ytdl" ] || ytdl="youtube-dl"
  "$ytdl" --abort-on-error --yes-playlist \
   --write-info-json --write-comments --write-sub --write-auto-sub --sub-langs "en,en-GB" --write-thumbnail \
   --restrict-filenames --audio-quality 0 --format-sort "acodec:opus,acodec:m4a" \
   --playlist-start 1 \
   -o "$d/${xs}%(playlist_title)s/%(playlist_index)s,%(title)s-%(playlist_title)s-%(playlist_id)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  "$ytdl" --abort-on-error --yes-playlist \
   --restrict-filenames --audio-quality 0 --format-sort "acodec:opus,acodec:m4a" --extract-audio --keep-video \
   --playlist-start 1 \
   -o "$d/${xs}%(playlist_title)s/%(playlist_index)s,%(title)s-%(playlist_title)s-%(playlist_id)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  } # _youtube_video_list 20220516

_youtube_video () {
  local id="$1" d="$2" xs=$(xs)
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "$FUNCNAME : no id? (6542c9fc)" ; return 1 ;}
  [ "$d" ]  || read -p "directory: " d
  read id < <(sed "s/\([?&]\)si=................[&]*/\1/" <<<"$id") # squash trackers from url
  #id=$(sed 's/si=.*//' <<<"$id") # squash trackers from url
  [ -d "$d" ] || d="$(pwd -P)"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "$FUNCNAME : invalid dir '$d' (6542c61e)" ; return 1 ;}
  [ "$ytdl" ] || ytdl="youtube-dl"
  local ytdl_vtt ytdl_json
  chkwrn "capturing ytdl_vtt ytdl_json filenames from video/json download"
  read ytdl_vtt ytdl_json < <(tr '\n' ' ' < <(sed -e '/^\[info\] Writing/!d' -e 's/.*: //' < <(# collect filenames from ytdl output
    $ytdl --write-info-json --write-comments --write-sub --write-auto-sub --sub-langs "en,en-GB" \
        --restrict-filenames --audio-quality 0 --format-sort "acodec:opus,acodec:m4a" \
        --abort-on-error --no-playlist \
        -o "$d/00${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s" "$id" )))
  chkwrn "processing ytdl_vtt to txt"
  uniq < <(sed -e '/align:start position/d' -e 's/<[^>]*>//g' -e '/ --> /d' -e '/^ [ ]*$/d' -e '/^$/d' "$ytdl_vtt") >"${ytdl_vtt}.txt" \
    || { chkerr "$FUNCNAME : could not create '$d/${ytdl_vtt}.txt' (66fd682e)" ; return 1 ;} # write out vtt as txt
  "$ytdl" \
   --restrict-filenames --audio-quality 0 --format-sort "acodec:opus,acodec:m4a" --extract-audio --keep-video \
   --abort-on-error --no-playlist \
   -o "$d/00${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  } # _youtube_video 20220516

_youtube_list () {
  local id="$1" d="$2"
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "$FUNCNAME : no id? (6542c9f0)" ; return 1 ;}
  read id < <(sed "s/\([?&]\)si=................[&]*/\1/" <<<"$id") # squash trackers from url
  [ "$d" ]  || read -p "directory: " d
  [ -d "$d" ] || d="$(pwd -P)"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "$FUNCNAME : invalid dir '$d' (6542c9e4)" ; return 1 ;}
  [ "$ytdl" ] || ytdl="youtube-dl"
  "$ytdl" --abort-on-error --yes-playlist \
   --write-info-json --write-comments --write-sub --write-auto-sub --sub-langs "en,en-GB" --write-thumbnail \
   --restrict-filenames --audio-quality 0 --format-sort "acodec:opus,acodec:m4a" --extract-audio \
   --playlist-start 1 \
   -o "$d/00$(xs),%(playlist_title)s/%(playlist_index)s,%(title)s-%(playlist_title)s-%(upload_date)s_^%(id)s.%(ext)s" $id
  } # _youtube_list 20220516

_youtube_txt () { # put youtube (arg1) json and captions in dir (arg2, original json and vtt stored in arg2/@)
  local id="$1" d="$2"
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "$FUNCNAME : no id? (66749f30)" ; return 1 ;}
  read id < <(sed -e "s/\([?&]\)si=................[&]*/\1/" -e 's/\?$//' <<<"$id") # squash trackers from url
  [ "$d" ]  || read -p "directory: " d
  [ "$d" ]  || d='.'
  [ -d "$d/@" ] || mkdir -p "$d/@" || { chkerr "$FUNCNAME : unable to mkdir '$d/@' (66749f61)" ; return 1 ;}
  [ "$ytdl" ] || ytdl="youtube-dl"
 #local t= ; read t < <(mkdir -p "$HOME/%/ytdl" && cd "$HOME/%/ytdl" && mktemp ytdl-XXXX)
 #[ -e "$HOME/%/ytdl/$t" ] || { chkerr "$FUNCNAME : could not set tmp file '$t' (6674ab6a)" ; return 1 ;}
  local xs= ; read xs < <(sed -e 's/^@4[0]*//' -e 's/[[:xdigit:]]\{8\} $//' < <(tai64n <<<'')) \
    || { chkerr "$FUNCNAME : failed to set xs (6674c2fd)" ; return 1 ;}
  local ytdl_vtt= ytdl_json=
  read ytdl_vtt ytdl_json < <(tr '\n' ' ' < <(sed -e '/^\[info\] Writing/!d' -e 's/.*: //' < <(# collect filenames from ytdl output
    $ytdl --write-info-json --write-comments --write-sub --write-auto-sub --sub-langs "en,en-GB" \
        --restrict-filenames --skip-download --abort-on-error --no-playlist \
        -o "$d/@/00${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s" "$id" )))
  $verb chkwrn "ytdl_vtt=$ytdl_vtt"
  uniq < <(sed -e '/align:start position/d' -e 's/<[^>]*>//g' -e '/ --> /d' -e '/^ [ ]*$/d' -e '/^$/d' "$ytdl_vtt") >"${ytdl_vtt}.txt" \
    && mv "${ytdl_vtt}.txt" "$d" || { chkerr "$FUNCNAME : could not create '$d/${ytdl_vtt}.txt' (6674c795)" ; return 1 ;}
  chktrue "$d/${ytdl_vtt##*/}.txt"
  $verb chkwrn "ytdl_json=$ytdl_json"
  yq -y 'del(.formats, .thumbnails, .thumbnail, .age_limit, ._format_sort_fields,
             .automatic_captions, .playable_in_embed, .is_live, .was_live, .tbr,
             .format, .format_id, .format_note, .protocol,
             .width, .height, .resolution, .fps, .vcodec, .vbr, .aspect_ratio )
       | del(.comments[]? | (._time_text, .author_thumbnail, .author_is_verified))' "$ytdl_json" >"${ytdl_json}.yml" \
    && mv "${ytdl_json}.yml" "$d" || { chkerr "$FUNCNAME : could not create '$d/${ytdl_json}.yml' (6674c7fe)" ; return 1 ;}
  chktrue "$d/${ytdl_json##*/}.yml"
# more deletes
# .downloader_options, .http_headers, .webpage_url_basename, .author_thumbnail, .live_status,
# .automatic_captions, .extractor,
  ## get the id
  #local f="$(find $links -name \*$($ytdl --dump-json $id | jq --ascii-output --raw-output '(.id)' | yq --yaml-output |head -n1)\* | grep -Ev '/(tmp|0)/' | sort)"
  ## check if the id exists already, chance to abort...
  #[ "$f" ] && { echo "$f" ; read -p "files found, continue (N/y) " f ; [ "$f" = 'y' ] || return 1 ;}
  #_youtube_json2txt $(sed -e '/as JSON to/!d' -e 's/.*to: //' <"$HOME/%/ytdl/$t") && rm -f "$HOME/%/ytdl/$t" \
  } # _youtube_txt 66749f14-20240620_142842

_youtube () {
  local id="$1" d="$2"
  [ "$id" ] || read -p "youtube id: " id
  [ "$id" ] || { chkerr "$FUNCNAME : no id? (6542c9d2)" ; return 1 ;}
  read id < <(sed -e "s/\([?&]\)si=................[&]*/\1/" -e 's/\?$//' <<<"$id") # squash trackers from url
  [ "$d" ]  || read -p "directory: " d
  [ "$d" ]  || d='.'
  [ -d "$d" ] || { [ -d "${links}/$d" ] && d="${links}/$d" ;}
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "$FUNCNAME : invalid dir '$d' (6542c606)" ; return 1 ;}
  [ "$ytdl" ] || ytdl="youtube-dl"
  local xs= ; read xs < <(sed -e 's/^@4[0]*//' -e 's/[[:xdigit:]]\{8\} $//' < <(tai64n <<<'')) \
    || { chkerr "$FUNCNAME : failed to set xs (6674c2fd)" ; return 1 ;}
  local t=$(mkdir -p "$HOME/%/ytdl" && cd "$HOME/%/ytdl" && mktemp ytdl-XXXX)
  # get the id
  local f="$(find $links -name \*$($ytdl --dump-json --no-write-comments $id \
    | jq --ascii-output --raw-output '(.id)' \
    | yq --yaml-output |head -n1)\* | grep -Ev '/(tmp|0)/' | sort)"
  # check if the id exists already, chance to abort...
  [ "$f" ] && { echo "$f" ; read -p "files found, continue (N/y) " f ; [ "$f" = 'y' ] || return 1 ;}
  $ytdl --write-info-json --write-comments --write-sub --write-auto-sub --sub-langs "en,en-GB" --write-thumbnail \
   --restrict-filenames --audio-quality 0 --format-sort "acodec:opus,acodec:m4a" --extract-audio \
   --abort-on-error --no-playlist \
   -o "$d/00${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s" $id | tee "$HOME/%/ytdl/$t"
  # prompt with filing indices and catagories
    local w= ; read -d '' w < <(awk '{ printf "%.0f", $1 * 0.89 }' < <(tput cols))
    sed 's/^/  /' < <( # pad margin
      echo "  $links"
      ls -td $(find $links -mindepth 1 -maxdepth 1 -type d \( -name 5\* -o -name 6\* \) ) \
        | while read a ; do echo "${a##*/}" ; done \
        | rs -tz -w$w
      echo "  $music"
      grep '^[[:alnum:]],' $music/comma_mp3.sh | rs -tz -c"\n" -w$w )
  _youtube_json2txt $(sed -e '/as JSON to/!d' -e 's/.*to: //' <"$HOME/%/ytdl/$t") && rm -f "$HOME/%/ytdl/$t" \
    || { chkwrn "failed: _youtube_json2txt '$HOME/%/ytdl/$t' (6542c5ee)" ; return 1 ;}
  } # _youtube 20220516

_youtube_json2txt () { # fixup youtube .info.json to yaml txt and sort files
  local a
  [ -f "${1}" ]     || { chkerr "$FUNCNAME : not a file : ${1} (6542c870)" ; return 1 ;}
  [ -f "${1}.txt" ] && { chkerr "$FUNCNAME : exists ${1}.txt (6542c86a)" ; return 1 ;}
  local inpath='' _fout="_^$(jq --ascii-output --raw-output '(.id, .audio_ext)' "$1" \
    | tr -d '"' | tr '\n' '.' | sed 's/\.$//')"
  #expr "$1" : ".*/" >/dev/null && inpath="${1%/*}" || inpath="."
  [[ "$1" =~ / ]] && inpath="${1%/*}" || inpath="."
  printf "\n%s\n" "ss= ; export verb=chkwrn ss= to= t= p= f= c=r3 F= CF= off= tp= lra= i= cmp=pard v=3db" >"${1}.txt"
  printf   "%s\n" "ss= ; export _f=@/${_fout}" | tr -d '"' >>"${1}.txt"
  { jq --ascii-output --raw-output '(.fulltitle)' "$1" \
        | tr -d '"' ; printf '\n' "" ;} \
        | sed -e 's,\\u0332,,g' -e 's,\\u2013,-,g' -e 's,\\u00d7,-,g' -e 's,\\u2022,-,g' \
        | awk 'P=$0{printf "\n_a=%s\n_r=%s\n\n",P,P}' >>"${1}.txt"
  printf ' ss= to= f2rb2mp3 $_f ooo,${_a}-Trak_Title-${_r}\n' >>"${1}.txt"
  jq --ascii-output --raw-output '(.duration_string)' "$1" | tr -d '"' >>"${1}.txt"
  yes | tr -d 'y' | head -n 2 >>"${1}.txt"
  jq --compact-output 'del(.formats, .thumbnail, .thumbnails, .downloader_options, .http_headers,
        .webpage_url_basename, .author_thumbnail, .playable_in_embed, .live_status, .automatic_captions,
        .extractor, .is_live, .was_live )' "$1" | yq --yaml-output | tr -cd '[ -~]\n' >>"${1}.txt"
  # sorting these files is a side effect of calling this function,
  # but this function may be called when there are no files to sort,
  # so only do the side effect if the files are there...
  [ -f "$inpath"/*"${_fout}" ] && mkdir -p "$inpath/@/meta" && ln -f "$inpath"/*${_fout} "$inpath"/@/${_fout}
  [ -f "$inpath"/*"${_fout}" ] && mkdir -p "$inpath/orig"   && mv -f "$inpath"/*${_fout} "$inpath/orig"
  mkdir -p "$inpath"'/@/meta'
  find "$inpath" -maxdepth 1 -name \*${_fout%%.*}\* \
    \( -name \*json -o -name \*webp -o -name \*jpg -o -name \*vtt \) \
    -exec mv \{\} "$inpath"'/@/meta' \;
  echo "${1}.txt"
  } # _youtube_json2txt 20220516

_youtube_comment_unflatten () { # convert comment text from _youtube_json2txt to ascii formatted
    sed -e '
        s/^[ ]*text: "//
        s/^[ ]*//
        s/\\$//
        s/\\ / /g
        s/\\"/"/g
        s/\\t/	/g
        s/\\r//g
        $s/"$//' | tr -d '\n' | awk '{gsub(/\\n/,"\n")}1'
    } # _youtube_comment_unflatten 20230323
# $s means only match the last line of the file

_youtube_comment_unflatten () { # convert comment text from _youtube_json2txt to ascii formatted
    # echo -e "$( yq -r . )" ... subshell, no \" and no utf
    awk '
    BEGIN {
        FS = OFS = ""
        escape["\\"] = "\\"
        escape["a"] = "\a"
        escape["b"] = "\b"
        escape["f"] = "\f"
        escape["n"] = "\n"
        escape["r"] = "\r"
        escape["t"] = "\t"
        escape["v"] = "\v"
        escape["\""] = "\""
    }
    {
        line = $0
        result = ""
        for (i = 1; i <= length(line); i++) {
            if (substr(line, i, 1) == "\\") {
                i++
                char = substr(line, i, 1)
                if (char in escape) {
                    result = result escape[char]
                } else if (char == "x") {
                    hex = substr(line, i+1, 2)
                    result = result sprintf("%c", strtonum("0x" hex))
                    i += 2
                } else if (char == "0") {
                    oct = substr(line, i, 3)
                    result = result sprintf("%c", strtonum("0" oct))
                    i += 2
                } else {
                    result = result char
                }
            } else {
                result = result substr(line, i, 1)
            }
        }
        print result
    }
    '
    } # _youtube_comment_unflatten 20230323
_youtube_comment_unflatten () { # convert comment text from _youtube_json2txt to ascii formatted
    # echo -e "$( yq -r . )" ... subshell, no \" and no utf
    yq -r 'to_entries[] | .value'
    } # _youtube_comment_unflatten 20230323

span2ssto () { # start (arg1) span (arg2) and remaining args to f2rb2mp3
    # used to calculate ss= to= f2rb2mp3 parameters, given track lengths
    # eg
     # export offset=1
    # sp2ssto 0   7:14 01,\${a}-Song_For_My_Father-\${_r}
    # sp2ssto $to 6:07 02,\${a}-The_Natives_Are_Restless_Tonight-\${_r}
    # ss=0   to=435 f2rb2mp3 $_f 01,${a}-Song_For_My_Father-${_r}
    # ss=435 to=803 f2rb2mp3 $_f 02,${a}-The_Natives_Are_Restless_Tonight-${_r}
    local ss=$1 span= offc=;
    [ "$offset" ] && offc="$offset +" || offc='';
    span=$(dc -e "$2 $offc p")
    export to=$(dc -e "$(hms2sec $ss) $(hms2sec $span) + $offc p");
    shift 2 || shift || true
    echo ss=$ss to=$to f2rb2mp3 '$_f' $*
    echo "# $to is 0x$(kdb_xs2hu $(printf '%x' $to))"
    } # span2ssto 20220519
hms2sec () { # passthrough seconds or convert hh:mm:ss to seconds
    # must provide ss which may be ss.nn, hh: and hh:mm: are optional
    # a number must proceed every colon
  { # remove trailing 0 from seconds decimal
  [[ $1 == *:*:*:* ]] && { chkerr "too many ':' in '$1' (6542c9ba)" ; return 1 ;}
  [[ $1 == *:*:* ]] && { echo $1 | sed -e 's/:/ 0/g' \
        | awk '{print "3 k "$1" 60 60 * * "$2" 60 * "$3" + + p"}' | dc && return 0 ;}
  [[ $1 == *:* ]] && echo $1 | sed -e 's/:/ 0/g' \
        | awk '{print "3 k "$1" 60 * "$2" + p"}' | dc
  [[ $1 == *:* ]] || echo $1
  } | sed -e '/\./s/[0]*$//' -e 's/\.$//' ;} # hms2sec
prependf () {
  local basefp="$1"
  local title="$2"
  [ -z "$basefp" ] && { chkerr "prependf: base filepath (arg1) not set $@ (6542c852)" ; return 1 ;}
  [ -f "$basefp" ] || { chkerr "prependf: base filepath (arg1) not a file $@ (6542c84c)" ; return 1 ;}
  [ "$title" ] || return 0 # no operation
  local basefn="$(basename "$basefp")"
  ( cd $(dirname "$basefp") && mv -f "$basefn" "${title}${basefn}" )
  } # prependf
# 20200204
f2rb2mp3 () ( # subshell function "file to rubberband to mp3", transcoding/tuning function
  # subshell sets pipefail and ensures PWD on err
    set -o errexit   # Exit on command non-zero status
    set -o errtrace  # any trap on ERR is inherited by shell functions
    set -o functrace # traps on DEBUG and RETURN are inherited by shell functions
    set -o pipefail  # exit pipeline on non-zero status (rightmost?)
  # validate env per
  # https://github.com/georgalis/pub/blob/master/skel/.profile
  # https://github.com/georgalis/pub/blob/master/sub/func.bash
  while IFS= read fndata ; do
    validfn $fndata || { echo "validfn error : $fndata" 1>&2 ; return 1 ;}
  done <<EOF
# pub/skel/.profile 20220105
devnul 216e1370 0000001d
stderr 7ccc5704 00000037
chkwrn 2683d3d3 0000005c
chkerr 4f18299d 0000005b
# pub/sub/fn.bash 20220105
hms2sec aea30e0e 000001e3
prependf a38214fb 000001c8
EOF
  which rubberband-r3 >/dev/null 2>&1 && [ "$c" = "r3" ] && [ -z "$rb" ] && { rb=rubberband-r3 ;}
  which rubberband-r3 >/dev/null 2>&1 && [ -z "$c" ] && [ -z "$rb" ] && { rb=rubberband-r3 c=r3 ;}
  [ -x "$(which "$rb")"  ] || { chkerr "$FUNCNAME : env rb not set to rubberband executable (6542c828)" ; return 1 ;}
  [ -x "$(which ffmpeg)" ] || { chkerr "$FUNCNAME : ffmpeg not in path (6542c82e)" ; return 1 ;}
  [ -x "$(which sox)"    ] || { chkerr "$FUNCNAME : sox not in path (6542c83a)" ; return 1 ;}
  # success valid env
  [ "$1" = "help" -o "$1" = "-h" ] && { # a function to adjust audio file tempo and pitch independently
    # depends on ffmpeg, rubberband and sox
    # https://hg.sr.ht/~breakfastquay/rubberband
    # https://github.com/breakfastquay/rubberband
    # https://breakfastquay.com/rubberband/
    # "Crispness" levels:
    #   -c 0   equivalent to --no-transients --no-lamination --window-long
    #   -c 1   equivalent to --detector-soft --no-lamination --window-long (for piano)
    #   -c 2   equivalent to --no-transients --no-lamination
    #   -c 3   equivalent to --no-transients
    #   -c 4   equivalent to --bl-transients
    #   -c 5   default processing options (none of below)
    #   -c 6   equivalent to --no-lamination --window-short (may be good for drums)
    #
    #   -L,    --loose          Relax timing in hope of better transient preservation
    #          --no-transients  Disable phase resynchronisation at transients
    #          --bl-transients  Band-limit phase resync to extreme frequencies
    #          --no-lamination  Disable phase lamination
    #          --window-long    Use longer processing window (actual size may vary)
    #          --window-short   Use shorter processing window
    #          --smoothing      Apply window presum and time-domain smoothing
    #          --detector-perc  Use percussive transient detector (as in pre-1.5)
    #          --detector-soft  Use soft transient detector
    #          --centre-focus   Preserve focus of centre material in stereo
    #                           (at a cost in width and individual channel quality)
#   echo "# crisp:  0=mushy 1=piano 2=smooth 3=MULTITIMBRAL 4=two-sources 5=standard 6=percussive "
    echo "# Formant y/''  CenterFocus y/'' vol 0db/'' frequency (bhz|chz|N)/'' reverse y/''"
    echo "# cmp= $(declare -f $FUNCNAME | sed -e '/compand/!d' -e '/sed/d' -e 's/=.*//' -e 's/local//' | tr -s ' \n' '|')"
#   declare -f $FUNCNAME | sed -e '/compand/!d' -e '/sed/d' | while IFS= read a ; do ${verb2} "$a" ; done
    echo "# ss= to= t= p= f= c= F= CF= off= tp= lra= i= cmp= v= f2rb2mp3 {file-in} {prepend-out}"
    echo "# ss=$ss to=$to t=$t p=$p f=$f c=$c F=$F CF=$CF off=$off tp=$tp lra=$lra i=$i cmp=$cmp v=$v f2rb2mp3 {file-in} {prepend-out}"
    return 0
    } # help
  $verb "f2rb2mp3 $1 $2"
  $verb ss=$ss to=$to t=$t p=$p f=$f c=$c F=$F CF=$CF off=$off tp=$tp lra=$lra i=$i cmp=$cmp v=$v
  [    "$1" ] || { f2rb2mp3 help ; return 1 ;}
  [ -f "$1" ] || { f2rb2mp3 help ; chkerr "no input flle '$1' (6542c99c)" ; return 1 ;}
  local  verb="${verb:=chkwrn}"
  local verb2="${verb2:=devnul}"
  local verb3="${verb3:=devnul}"
  local infile="${1##*/}" # basename
  expr "$1" : ".*/" >/dev/null && inpath="${1%/*}" || inpath="." # input dirname
  local infilep="$(cd "${inpath}" ; pwd -P)/${infile}" # full filepath
  local prependt="$2"
  [ "${prependt}" ] || prependt=00,
  [ "$t" -o "$p" ] && { [ "$c" ] || local c=5 ;} || true # "Crispness"
  [ "$t" = 1 ] && local t= || true
  [ "$p" = 0 ] && local p= || true
  [ "$f" = 1 ] && local f= || true
  local tc='' tn='' ; [ "$t" ] && tc="--time $t"  tn="-t${t}" || true
  local pc='' pn='' ; [ "$p" ] && pc="--pitch $p" pn="-p${p}" || true
  local fhzc='' fhzn=''
  [ "$f" ] && { fhzc="-f $f" ; fhzn="-f$f" ;}
  [ "$f" = "bhz" ] && { fhzc="-f 0.98181818181818" ; fhzn="-bhz" ;} || true # baroque 432 hz tuning, from classical 440
  [ "$f" = "chz" ] && { fhzc="-f 1.01851851851851" ; fhzn="-chz" ;} || true # classical 440 hz tuning, from baroque 432
  local cmpn='' cmpc=''
  local ckb0="compand 0.2,0.9  -70,-70,-60,-55,-50,-45,-35,-35,-20,-25,0,-12 6 -70 0.2" # piano analog master
  local ckb2="compand 0.2,0.9  -70,-99,-50,-60,-50,-45,-30,-30,-20,-25,0,-13 6 -70 0.2" # piano digital master
  local ckb3="compand 0.2,0.8  -60,-99,-50,-56,-38,-32,-23,-18,0,-4         -2 -60 0.2" # piano old analog master
  local hrn3="compand 0.08,0.3 -74,-80,-50,-46,-18,-18,-0,-6                -1 -68 0"    # peaky horn
  local cps1="compand 0.07,0.25 -70,-84,-50,-45,-32,-33,-0,-21               3 -71 0.07" # high compress
  local par2="compand 0.09,0.25 -100,-116,-88,-97,-80,-80,-63,-72,-54,-60,-23,-48,0,-36        19 -95 0.08" # parabolic extra
  local par4="compand 0.13,0.16 -72,-97,-68,-84,-64,-73,-56,-65,-55,-61,-32,-57,-17,-53,0,-49  25 -55 0.12" # parabolic squared
  local parc="compand 0.09,0.25 -97,-106,-85,-89,-73,-73,-57,-61,-40,-49,-21,-37,0,-25                           11   -13 0.08" # parabolic standard
  local pard="compand 0.09,0.25 -84.4,-110.7,-74.4,-89.1,-64.4,-71.0,-54.4,-56.3,-39.7,-46.3,-21.7,-36.3,0,-26.3 13.5 -13 0.091" # parabolic-d
  local para="sinc 6-22k compand 0.087,1.78 -64.6,-63,-54.6,-48,-44.7,-30,-26.6,-20,-11.9,-10 -7.0 -20 0.0875" # for old analog, inverse pard
  [ "$cmp" = "hrn" -o "$cmp" = "hrn1" ] && cmpn="hrn3" cmpc="$hrn3"
  [ "$cmp" = "cps" ]  && cmpn="pard" cmpc="$pard"
  [ "$cmp" = "ckb" ]  && cmpn="$cmp" cmpc="$ckb0"
  [ "$cmp" = "ckb2" ] && cmpn="$cmp" cmpc="$ckb2"
  [ "$cmp" = "ckb3" ] && cmpn="$cmp" cmpc="$ckb3"
  [ "$cmp" = "hrn3" ] && cmpn="$cmp" cmpc="$hrn3"
  [ "$cmp" = "para" ] && cmpn="para" cmpc="$para"
  [ "$cmp" = "cps1" ] && cmpn="pard" cmpc="$pard"
  [ "$cmp" = "parc" ] && cmpn="pard" cmpc="$pard"
  [ "$cmp" = "pard" ] && cmpn="$cmp" cmpc="$pard"
  [ "$cmp" = "par2" ] && cmpn="$cmp" cmpc="$par2"
  [ "$cmp" = "par4" ] && cmpn="$cmp" cmpc="$par4"
  $verb2 "cmpn='$cmpn'"
  $verb2 "cmpc='$cmpc'"
  $verb2 "input='$inpath/$infile'"
  mkdir -p "${inpath}/tmp"
  null="$(mktemp "${inpath}/tmp/nulltime-XXXXX")"
  null="${null##*/}" # basename
  local vn='' vc='' # init "volume name" and "volume command"
  expr "$v" : "^[-]*[[:digit:]]*db$" >/dev/null || local v=4db # init sane default, if no env overide
  [ "$cmpn" ] && vn="-$cmpn" vc="$cmpc" || true # sox compand is basically a volume adjustment...
  [ "$v" ] && { vn="${vn}-v${v}" vc="${vc} vol ${v} dither" ;} || true # set vol name (vn) and vol command (vc) if needed
  [ "$rev" = "y" ] && vn="${vn}-rev" vc="$vc reverse"
  [ "$ss" ] || local ss="0" # if null ss=0 is default, and ss=0 is unspecified in filename, probe "to" if unspecified
  [ "$to" ] || { local to= ; read to < <( # if empty, load var with Process Substitution and no subshel/Command Substitution
        awk '{print($1==int($1))?$1:int($1)+1}' < <(# round up to an interger
        ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$infilep")) ;} # probe file for duration
        # https://trac.ffmpeg.org/wiki/FFprobeTips#Formatcontainerduration
  local secc='' secn='' ssec='' tsec=''
  ssec=$(hms2sec ${ss})
  tsec=$(hms2sec ${to})
                            secc="-ss $ssec -to $tsec" secn="-ss${ssec}-to${tsec}" # typical
  [ "$ss" = 0 -a "$to" ] && secc="-to $tsec"           secn="-to$tsec" # unspecify ss
  local gsec=$(hms2sec $(ffprobe -hide_banner -loglevel info "$infilep" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //'))
  $verb "$(awk '{$1=$1 + 0;printf "%1.3f sec, %1.1f%% of %1.3f sec %s",$2-$1,(100*($2-$1))/$3,$3,$4 }' <<<"${ssec} ${tsec} ${gsec} ${infilep}")"
  chkerr "$(awk '$1 >= $2 {print $3 ": invalid duration , ss="$1" to="$2}' <<<"${ssec} ${tsec} $FUNCNAME")" || exit 1
  $verb "${inpath}/tmp/${infile}${secn}.{meas,flac}"
  [ -f "${inpath}/tmp/${infile}${secn}.meas" -a -f  "${inpath}/tmp/${infile}${secn}.flac" ] \
    || { # measure for EBU R128 loudness normalization
        { echo "# ${infile}${secn}.meas infile secn meas flac"
          #$verb2 "loudnorm in: loudnorm=print_format=json... $secc -i $infilep > ${inpath}/tmp/${infile}${secn}.flac~" 
          $verb2 @ffmpeg -hide_banner -loglevel info -y $secc -i "$infilep" 
          ffmpeg -hide_banner -loglevel info -y $secc -i "$infilep" \
            -af "highpass=f=6:p=2, lowpass=f=22000:p=2, aresample=48000,
                 loudnorm=print_format=json" \
            -ar 48000 -f flac "${inpath}/tmp/${infile}${secn}.flac~" 2>&1 | awk '/^{/,0' \
            | jq -r '. | "measured_I=\(.input_i) measured_TP=\(.input_tp) measured_LRA=\(.input_lra) measured_thresh=\(.input_thresh) linear=\(.linear)\nout_i_LUFS=\(.output_i) out_tp_dBTP=\(.output_tp)   out_lra_LU=\(.output_lra)     out_tr_LUFS=\(.output_thresh) offset_LU=\(.target_offset)"'
        } >"${inpath}/tmp/${infile}${secn}.meas~" \
       && {
            mv -f "${inpath}/tmp/${infile}${secn}.flac~" "${inpath}/tmp/${infile}${secn}.flac"
            mv -f "${inpath}/tmp/${infile}${secn}.meas~" "${inpath}/tmp/${infile}${secn}.meas"
            while IFS= read a ; do ${verb2} "$a" ; done <"${inpath}/tmp/${infile}${secn}.meas"
          } || {                     chkerr "$FUNCNAME : '${inpath}/tmp/${infile}${secn}.{meas,flac}' (6675e5b4)" ; return 1 ;}
    } # have trimmed measured flac
  #   i   Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0.
  #   lra Set loudness range target.      Range is   1.0 - 20.0. Default value is   7.0.
  #   tp  Set maximum true peak.          Range is  -9.0 - +0.0. Default value is  -2.0.
  local lnn offn tpn lran in measured_thresh measured_LRA measured_TP measured_I
  [ "$off" ] && offn="-off$off"
  [ "$lra" ] && lran="-lra$lra"
  [ "$tp"  ] &&  tpn="-tp$tp"
  [ "$i"   ] &&   in="-i$i"
  local flac_sec= ; read flac_sec < <(awk '{printf "%.3f",$1}' < <(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "${inpath}/tmp/${infile}${secn}.flac" )) || true
  $verb2 "$(hms2sec $flac_sec) seconds flac"
  [ "${offn}${lran}${tpn}${in}" ] && lnn="-ln${lran}${tpn}${in}${offn}" || lnn="-ln"
  $verb "${inpath}/tmp/${infile}${secn}${lnn}.{meas,flac}"
  [ -f "${inpath}/tmp/${infile}${secn}${lnn}.meas" -a -f "${inpath}/tmp/${infile}${secn}${lnn}.flac" ] \
    || { # make loudnorm flac https://en.wikipedia.org/wiki/EBU_R_128
  # local off="${off:=0}" tp="${tp:=-2}"   lra="${lra:=7}" i="${i:=-24}" # assign unset parm to default values
  # local off="${off:=0}" tp="${tp:=-1}"   lra="${lra:=7}" i="${i:=-23}" # https://tech.ebu.ch/docs/r/r128.pdf revision 2020
    local off="${off:=0}" tp="${tp:=-0.7}" lra="${lra:=7}" i="${i:=-23}" # assign unset parm to local defaults
    local $(grep measured "${inpath}/tmp/${infile}${secn}.meas") # source measured input data
    { echo "# ${infile}${secn}${lnn}.flac infile ln flac"
      # also measure the post loudnorm output data
      ffmpeg -hide_banner -loglevel info -benchmark -y $secc -i "$infilep" \
          -af "highpass=f=6:p=2, lowpass=f=22000:p=2, aresample=48000,
               loudnorm=print_format=json:linear=true
                   :measured_I=${measured_I}:measured_TP=${measured_TP}
                   :measured_LRA=${measured_LRA}:measured_thresh=${measured_thresh}
                   :offset=${off}:i=${i}:tp=${tp}:lra=${lra}" \
          -ar 48000 -f flac "${inpath}/tmp/${infile}${secn}${lnn}.flac~" 2>&1 | awk '/^{/,0' \
          | jq -r '. | "measured_I=\(.input_i) measured_TP=\(.input_tp) measured_LRA=\(.input_lra) measured_thresh=\(.input_thresh) linear=\(.linear)\nout_i_LUFS=\(.output_i) out_tp_dBTP=\(.output_tp)   out_lra_LU=\(.output_lra)     out_tr_LUFS=\(.output_thresh) offset_LU=\(.target_offset)"'
    } >"${inpath}/tmp/${infile}${secn}${lnn}.meas~" \
    && { # only rotate {flac,meas} on no error
        mv -f "${inpath}/tmp/${infile}${secn}${lnn}.flac~" "${inpath}/tmp/${infile}${secn}${lnn}.flac"
        mv -f "${inpath}/tmp/${infile}${secn}${lnn}.meas~" "${inpath}/tmp/${infile}${secn}${lnn}.meas"
        while IFS= read a ; do ${verb2} "$a" ; done       <"${inpath}/tmp/${infile}${secn}${lnn}.meas"
        } || {                         chkerr "$FUNCNAME : '${inpath}/tmp/${infile}${secn}${lnn}.{flac,meas}' (6675e2b2)"  ; return 1 ;}
  } # make loudnorm flac
  ##### begin rb section ######################################
  local out="${infile}${secn}${lnn}"
  local Fc='' Fn=''
  local cfc='' cfn=''
  local cc='' cn=''
  # as per the evolution of rubberband features...
  [ "$c" = "r3" ] && cc='--fine' cn='-r3'
  [ "$c" -a -z "$cc" ] && { expr "$c" : '^[0123456]$' >/dev/null || { chkerr "$FUNCNAME parm invalid : c='$c' (6542c90c)" ; return 1 ;} ;}
  [ "$c" -a -z "$cc" ] && { cc="--crisp $c" cn="-c${c}" ;} || true
  expr "$t" : '^-' >/dev/null && { chkerr "$FUNCNAME parm invalid : t='$t' (6542c924)" ; return 1 ;} || true
  expr "$p" : '^-[[:digit:]]*$' >/dev/null && p="${p}.0" || true # fixup negative integers, least test fail... -bash: [: -3: unary operator expected
  expr "$f" : '^-[[:digit:]]*$' >/dev/null && f="${f}.0" || true # fixup negative integers, least test fail
  # [ "" -o "-3" -o "" ] yields error on native mac bash https://discussions.apple.com/thread/254233125
  [ "$t" -o "$p" -o "$f" ] && { # rb parm
    [ "$F" = "y" ]  &&  Fc='--formant'       Fn='-F'  || Fc=''   Fn=''
    [ "$cf" = "y" ] && cfc='--centre-focus' cfn='-cf' || cfc='' cfn=''
    local out="${infile}${secn}${tn}${pn}${fhzn}${cn}${Fn}${cfn}${lnn}"
      [ -e "${inpath}/tmp/${out}.wav" ] || { # master sans volume
        $verb "${inpath}/tmp/${out}.wav"
        $verb2   $rb -q $tc $pc $fhzc $cc $Fn $cfc "${inpath}/tmp/${infile}${secn}${lnn}.flac" "${inpath}/tmp/${out}.wav~"
             { { $rb -q $tc $pc $fhzc $cc $Fn $cfc "${inpath}/tmp/${infile}${secn}${lnn}.flac" "${inpath}/tmp/${out}.wav~" 2>&1 \
                                                          && mv -f "${inpath}/tmp/${out}.wav~" "${inpath}/tmp/${out}.wav" 
               } | while IFS= read a ; do ${verb} "$a" ; done ;} || { chkerr \
                "$rb    $tc $pc $fhzc $cc $Fn $cfc '${inpath}/tmp/${infile}${secn}${lnn}.flac' '${inpath}/tmp/${out}.wav~' (6542c978)" ; return 1 ;}
        } # final master, sans sox volume
      # apply volume and make an mp3 --- hopefully the input is not clipped already!
      $verb2 "$(hms2sec $(ffprobe -hide_banner  -loglevel info  "${inpath}/tmp/${out}.wav" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //') ) seconds rubberband"
      $verb "${inpath}/tmp/${out}${vn}.mp3"
      $verb2         sox "${inpath}/tmp/${out}.wav" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc
               { {   sox "${inpath}/tmp/${out}.wav" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc 2>&1 \
                                           && mv -f "${inpath}/tmp/${out}${vn}.tmp.mp3" "${inpath}/tmp/${out}${vn}.mp3"
                 } | while IFS= read a ; do ${verb} "$a" ; done ;} || { chkerr \
                    "sox '${inpath}/tmp/${out}.wav' '${inpath}/tmp/${out}${vn}.tmp.mp3' $vc (66761b47)" ; return 1 ;}
    } || { # no rb input parms (only seconds start/stop, volume, or neither)
        # verb2 same as above "output flac seconds" "${inpath}/tmp/${out}.flac"
        $verb "${inpath}/tmp/${out}${vn}.mp3"
        $verb2         sox "${inpath}/tmp/${out}.flac" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc
               { {     sox "${inpath}/tmp/${out}.flac" "${inpath}/tmp/${out}${vn}.tmp.mp3" $vc 2>&1 \
                                              && mv -f "${inpath}/tmp/${out}${vn}.tmp.mp3" "${inpath}/tmp/${out}${vn}.mp3"
                 } | while IFS= read a ; do ${verb} "$a" ; done ;} || { chkerr \
                      "sox '${inpath}/tmp/${out}.flac' '${inpath}/tmp/${out}${vn}.tmp.mp3' $vc (66761be1)" ; return 1 ;}
         }
    # prepend output filename
    $verb "./loss/${prependt}${out}${vn}.mp3"
    mkdir -p "./loss"
    mv -f "${inpath}/tmp/${out}${vn}.mp3" "./loss/${prependt}${out}${vn}.mp3" \
      && rm -f "${inpath}/tmp/$null" \
      && $verb "$(hms2sec $(ffprobe -hide_banner -loglevel info "./loss/${prependt}${out}${vn}.mp3" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //') ) mp3 seconds" \
      && echo "./loss/${prependt}${out}${vn}.mp3"
# extract audio from video
# for a in *Caprices_For_FLUTE*webm ; do ext=$(ffprobe -hide_banner  -loglevel info $a 2>&1 | sed -e '/Audio/!d' -e 's/.*Audio: //' -e 's/,.*//'); name=$(sed "s/[^.]*$/$ext/" <<<$a) ; ffmpeg -i $a -q:a 0 -map a -acodec copy $name ; done
#
# convert 5.1 channels to 2
# https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg
#ffmpeg -i Mozart-K622-Clarinet-Concerto-A-Maj-Kam-Honeck-2006.m4a \
#  -af "pan=stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR" \
# cf Mozart-K622-Clarinet-Concerto-A-Maj-Kam-Honeck-2006.m4a.flac
# cf chet baker /Users/geo/dot4/5/d/3/a/4/a/^/parm_sox.sh
    # -ss 32:05 -to 39:58.5
    ) # f2rb2mp3

# 20201216
formfile () { # create a f2rb2mp3 command to render the file, given the input filename
    # use case:
    #
    # for a given rendered file
    #     001-Leclair_Op9-2_Flute_Sonata-E-Min^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
    #
    # decompose into rendering command line for parameters
    #
    #   p=2 formfile 001-Leclair_Op9-2_Flute_Sonata-E-Min_^fJwnsyEtkK0.opus-t0.87-p1-c3-F-ss4795-to5790-v1db.mp3
    #
    #   ss=4795 to=5790 t=0.87 p=1 c=3 F=y v=1db '' p=2 c=r3 cmp=parc v=4db f2rb2mp3 '@/_^fJwnsyEtkK0.opus' 001-Leclair_Op9-2_Flute_Sonata-E-Min
    #
    # first group of parameters are taken from the filename
    # the parameters between '' and f2rb2mp3 are from the shell env
    # duplicate param settings, the last parameter provided to f2rb2mp3 wins
    # if a source file is not found, the expected path is provided
    #
    [ "$1" = "-h" -o "$1" = "--help" ] && {
        chkwrn "Usage, for args (or per line stdin) decompose"
        chkwrn "each filename into a rendering command."
        return 0 ;} || true
    local fs="$1" ; shift || true
    local verb="${verb:-devnul}"
    while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift || true ; done
    [ "$fs" ] || fs="$(cat)"
    local orig='' sortargs='' parm='' origfiles=''
    echo "$fs" | while IFS= read _fpath ; do # filepath list
        local _fname="${_fpath##*/}" # basename
        $verb2 "${_fname}"
        local ext='' id='' orig=''
        local title="${_fname%%_^*}"
        local ext="$(sed -e 's/_^[^.]*.//' -e 's/\..*//' -e 's/-.*//' <<<"_^${_fname##*_^}")" # expect _^ to proceed id, followed by dot orig ext,
            # parm and transcoded extension, do the right thing on no parm or no transcoded extension (_^id.ext[-parm][.ext]$)
        local id="$(sed "s/\.${ext}.*//" <<<"${_fname##*_^}")"                  # id between "_^" and ".{ext}"
        local path ; expr "$_fpath" : ".*/" >/dev/null && path="${_fpath%/*}" || path="." # dirname input file
                            origfiles="$(find $(find "$path"    -name \@) -maxdepth 1 -type f -name \*${id}\* 2>/dev/null | head -n1 )" # search @ directories
      # [ "$origfiles" ] || origfiles="$(find $(find "$path/.." -name \@) -maxdepth 1 -type f -name \*${id}\* 2>/dev/null | head -n1 )" # search more @ directories
      # local origfiles="$(find $(find "$path" "$path/.." -name \@) -maxdepth 1 -type f -name \*${id}\* 2>/dev/null )" # search nearby @ directories
        # first inode found is usually the best choice OR set expected path in quote, as reference
        [ "$origfiles" ] && orig="$(awk 'NR==1' <<<"${origfiles}")" || orig="'@/_^${id}.${ext}'"
        # decode f2rb2mp3 arguments
        local args="$(sed -E -e "
            s/.*\.${ext}//
            s/.mp3$//
            s/-(ckb|hrn|cps|par)/ cmp=\1/
            s/-(bhz|chz)/ f=\1/
            s/-rev/ rev=y/
            s/-ss/ ss=/
            s/-to/ to=/
            s/-r3/ c=r3/
            s/-t/ t=/
            s/-p/ p=/
            s/-f/ f=/
            s/-F/ F=y/
            s/-cf/ cf=y/
            s/-c/ c=/
            s/-v/ v=/
            s/-ln//
            s/-off/ off=/
            s/-tp/ tp=/
            s/-lra/ lra=/
            s/-i/ i=/
            " <<<"_^${_fname##*_^}" | tr ' ' '\n')"
        local sortargs=''
        for parm in ss= to= t= p= f= c= F= CF= off= tp= lra= i= cmp= v= ; do
            sortargs="$sortargs $(grep "^$parm" <<<"$args")"
            done
        sortargs="$(tr ' ' '\n' <<<"$sortargs" | sed '/^$/d')" # one arg per line
        # filename parsing phase complete
        # for output
        # print parm from filename
        # also print known parm from env if it is different than filename parm
        # result parsed and env parameters printed if different, last (env) parm wins
        args=' '
        [ "$ss"  ] && { grep "ss=$ss"   >/dev/null <<<"$sortargs" || args="$args ss=$ss"    ;}
        [ "$to"  ] && { grep "to=$to"   >/dev/null <<<"$sortargs" || args="$args to=$to "   ;}
        [ "$t"   ] && { grep "t=$t"     >/dev/null <<<"$sortargs" || args="$args t=$t "     ;}
        [ "$p"   ] && { grep "p=$p"     >/dev/null <<<"$sortargs" || args="$args p=$p "     ;}
        [ "$f"   ] && { grep "f=$f"     >/dev/null <<<"$sortargs" || args="$args f=$f "     ;}
        [ "$c"   ] && { grep "c=$c"     >/dev/null <<<"$sortargs" || args="$args c=$c "     ;}
        [ "$F"   ] && { grep "F=$F"     >/dev/null <<<"$sortargs" || args="$args F=$F "     ;}
        [ "$CF"  ] && { grep "CF=$CF"   >/dev/null <<<"$sortargs" || args="$args CF=$CF "   ;}
        [ "$off" ] && { grep "off=$off" >/dev/null <<<"$sortargs" || args="$args off=$off " ;}
        [ "$tp"  ] && { grep "tp=$tp"   >/dev/null <<<"$sortargs" || args="$args tp=$tp "   ;}
        [ "$lra" ] && { grep "lra=$lra" >/dev/null <<<"$sortargs" || args="$args lra=$lra " ;}
        [ "$i"   ] && { grep "i=$i"     >/dev/null <<<"$sortargs" || args="$args i=$i "     ;}
        [ "$cmp" ] && { grep "cmp=$cmp" >/dev/null <<<"$sortargs" || args="$args cmp=$cmp " ;}
        [ "$v"   ] && { grep "v=$v"     >/dev/null <<<"$sortargs" || args="$args v=$v "     ;}
        # expr "$v" : ".* v=$v " >/dev/null # ...
        args="$(tr ' ' '\n' <<<"$args" | sed '/^$/d' )"
        for parm in ss= to= t= p= f= c= F= CF= off= tp= lra= i= cmp= v= ; do
            sortargs="$sortargs $(grep "^$parm" <<<"$args")"
            done
        grep 'ss=' <<<"$sortargs" >/dev/null || sortargs="ss=0 $sortargs"
        sortargs=$(tr '\n' ' ' <<<${sortargs} \
            | sed -e '
                s/^ [ ]*//
                s/ [ ]*/ /g
                s/ [ ]*$//
                ' ) # <<< with no quotes removes the \n
        echo "$sortargs f2rb2mp3 $orig $title"
        done # a (filelist)
    } # formfile 64d36229 20230809

formfilestats () { # accept dir(s) as args, report unique formfile time and pitch stats from @ dir/*mp3
  find $@ -maxdepth 1 -type f -name \*mp3 -not -name 0\* -not -name \*y \
    | sed -E -e "
      # for now delete volumes with old filename formats
      /5d50-kindle-class/d
      /5fb3-deja-muse/d
      # flatten to time and pitch parameters
      s/.*_\^[^.]*[^-]*-/-/
      s/.mp3$//
      s/-(ckb|hrn|cps|par)/ cmp=\1/
      s/-(bhz|chz)/ f=\1/
      s/-rev/ rev=y/
      s/-ss/ ss=/
      s/-to/ to=/
      s/-t/ t=/
      s/-p/ p=/
      s/-f/ f=/
      s/-F/ F=y/
      s/-cf/ cf=y/
      s/-r3/ c=r3/
      s/-c/ c=/
      s/-v/ v=/
      s/-ln//
      s/-off/ off=/
      s/-tp/ tp=/
      s/-lra/ lra=/
      s/-i/ i=/
      # squash to tempo and pitch parameters
      s/[ ](cmp|rev|ss|to|F|cf|c|v|off|tp|lra|i)=[^ ]*/ /g
      /^$/d
      # fixup odd case
      /t=/!s/^/t=1 /
      /p=/!s/ f/ p=0 f/
      /p=/!s/$/ p=0/
    " \
    | column -t \
    | sort -n -t '=' -k 2 | uniq -c # sort result and count uniq
  } # formfilestats 61ef60e8-20220124_183054

# export c=100 ; rm -rf png/* ; for a in *Couperin-kbd*mp3 ; do b=$(sed -e 's/.*,//' <<<$a) ; echo $b ; done | sort | while read b ; do a=$(ls *$b) ; c=$(( ++c )) ; sox $a -n remix - trim 0 =3 -3 spectrogram -o png/${c},${a}.png ; echo -n .  ; done

 # # verb=chkwrn p=4 c=1 ss=434 to=471.2 cmp=cps1 v=9db f2rb2mp3 @/_^NPk-cE047PU.opus 52r,Couperin-kbd_01-Gmaj-Etcheverry-07_Menuet
 # formfilespec () { # generate spectrograph for ss-1 to ss+3 and to-3 to to+1
 #    #local p="${1%/*}" f="${1##*/}"
 #     local in="$1"
 #     mkdir -p "./png"
 #     set $( formfile "${in##*/}" | sed -e 's/.*f2rb2mp3//' )
 #     local orig=$1 pass=$2
 #     [ -e "$orig" ] || { chkwrn "$orig not found (6542c564)" ; return 1 ;}
 #     echo -n "sox $orig -n remix - trim "
 #     set $(formfile "${in##*/}" | sed -e 's/f2rb2mp3.*//' )
 #     #dc -e "$ss 1-p $ss 3+p $to 3-p $to 1+p" | tr '\n' ' ' | sed -e 's/^/=/' -e 's/ / =/g' -e  's/=$//'
 #     dc -e "$ss 1-p $ss 3+p $to 3-p $to 1+p" | sed -e 's/^/=/' | tr '\n' ' '
 #    #b=$(sed -e 's/,.*//' <<<$in)
 #     echo "spectrogram -o ./png/${in##*/}.png"
 #     }

masterlink () {
verb2=chkwrn
  [ "$1" ] && local hash="$1" || { chkerr "$FUNCNAME : no hash (6542c7e0)" ; return 1 ;}
  [ "$2" ] || local dir="$links/_ln" && local dir="$2"
  dot4find "$hash" \
    | grep -vE '(.vtt$|.json$)' | ckstat | sort -k5 | head -n1 \
    | awk -v m="$dir/$hash" '{print "ln",$5,m}'
 }


# The lack tone functions generate a drone intended to add aesthetic to a noisy environment.
# Execute one of the following (increasing complexity) in a new shell. Use ctrl-c repeatedly to stop.
#    lacks1tone
#    lacks2tone
#    lacks5tone
#    lacks6tone
#    lacks15tones
#    lacks26tones
#    lacks125tones
#    lacks155tones
#    lacks1255tones
# The default -55db level can be adjusted with arg1, eg "lacks2tone -30"
# is 15db closer to 0db (maximum), BE CAREFUL DO NOT FORGET the "-" when specifying db.
lacktone () { # monitor lacktone logfile
   local tail tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   case "$(uname)" in
     Darwin) tail='tail -F' ;;
     Linux)  tail='tail --follow=name' ;;
   esac
   touch "$tmp/lacktone"
   echo >> $tmp/lacktone
   date >> $tmp/lacktone
   $tail -n 1 "$tmp/lacktone" # | tr ' ' '\r'
#    lacks15tones
 }
 lacktone1a () { # play background tone, optional gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
   while :; do
      play -q -n -c1 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3 01.35 gain $g
      play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.3 0.78  gain $g
      sleep 0.54
      printf "%s" "1a/$g " >>"$tmp/lacktone" 
      done
 }
 lacktone1b () { # play background tone, optional gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
   while :; do
      play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.3 01.35 gain $g
      play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.3 0.78  gain $g
      sleep $(dc -e "3 k 1 $(($RANDOM %49 + 1)) / 0.50 + p")
      printf "%s" "1b/$g " >>"$tmp/lacktone" 
      done
  }
 lacktone2a () { # play background tone, optional gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "3 k 0.06 "$1" * "$1" + p"}' | dc )"
   while :; do
     timeout -k 2 4.7 -- play -q -n -c1 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.52 01.35 gain $g
     timeout -k 2 4.7 -- play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.52 0.78  gain $gb
      sleep 1.34
      printf "%s" "2a/$g " >>"$tmp/lacktone" &
      done
 }
 lacktone2b () { # play background tone, optional gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "3 k 0.06 "$1" * "$1" + p"}' | dc )"
   while :; do
     timeout -k 2 4.7 -- play -q -n -c2 synth sin %-44 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.52 01.35 gain $g 
     timeout -k 2 4.7 -- play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.52 0.78  gain $gb
      sleep $(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 1.00 + p")
      printf "%s" "2b/$g " >>"$tmp/lacktone" &
      done
  }
 lacktone5a () { # play background tone, optioal gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.03 "$1" * "$1" + p"}' | dc )"
   while :; do
      play -q -n -c1 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.27 01.35 gain $gb
      play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.33 0.78  gain $g
      sleep 0.54
      printf "%s" "5a/$g " >>"$tmp/lacktone" &
      done
 }
 lacktone5b () { # play background tone, optional gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "4 k 0.22 "$1" * "$1" + p"}' | dc )"
   while :; do
      play -q -n -c2 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.33 01.35 gain $g
      play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.27 0.78  gain $gb
      sleep $(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 0.52 + p")
      printf "%s" "5b/$g " >>"$tmp/lacktone" &
      done
  }
 lacktone6a () { # play background tone, optioal gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "3 k 0.03 "$1" * "$1" + p"}' | dc )"
   while :; do
      timeout -k 2 4.7 -- play -q -n -c1 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 $(dc -e "5 k 1 $(($RANDOM %128)) 0.51 + / 0.8 + 1.87 + p") 1.35 gain $gb
      timeout -k 2 4.7 -- play -q -n -c1 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 2.33 0.78  gain $g 
      sleep 2.74
      printf "%s" "6a/$g " >>"$tmp/lacktone" 
      done
 } # 6679c49e 20240624
 lacktone6b () { # play background tone, optional gain (arg1) default -55
   local g tmp
   [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
   mkdir -p "$tmp"
   echo >>"$tmp/lacktone"
   [ "$1" ] && g="$1" || g="-55"
    gb="$(echo "$g" | sed 's/-/_/' | awk '{print "3 k 0.22 "$1" * "$1" + p"}' | dc )"
   while :; do
      timeout -k 2 4.7 -- play -q -n -c2 synth sin %-33 sin %-9 sin %-6 sin %-19.7  fade h 0.09 2.33 01.35 gain $g
      timeout -k 2 4.7 -- play -q -n -c2 synth sin %-12 sin %-9 sin %-5 sin %-2     fade h 0.19 $(dc -e "5 k 1 $(($RANDOM %128)) 0.51 + / 0.8 + 2.00 + p") 0.78  gain $gb
      #sleep $(dc -e "6 k 1 $(($RANDOM %42 )) 0.51 + 1 / 0.76 + p")
      sleep 2.89
      printf "%s" "6b/$g " >>"$tmp/lacktone" 
      done
  } # 6679c49e 20240624

lacks26tones () {
    [ "$1" ] && v="$1" || v=".00112"
    awk -v v=$v 'BEGIN {if (v > 0 && v < 0.06) exit 0; else exit 1}' \
        || { chkwrn "$FUNCNAME : volume should be 0 > arg1 > 0.06" ; return 1 ;}
    lacktoneloop2a "$v" & lacktoneloop2b "$v" &
    lacktoneloop6a "$v" & lacktoneloop6b "$v" &
    lacktone
    } # 6679c49e 20240624

lacktoneloop2a () {
  [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
  mkdir -p "$tmp"
  local v1=
  [ "$1" ] && v1="$1" || v1=".003"
  local v2= ; read v2 < <(dc -e "5 k $v1 0.92 * p")
  while :; do
    printf "%s" " 2a1/$v2" >>"$tmp/lacktone" ; lacktonegen 1 3 2 "$v2" || break 1 # 2a1
    printf "%s" " 2a2/$v1" >>"$tmp/lacktone" ; lacktonegen 3 4 2 "$v1" || break 1 # 2a2
    done || return 1
  } # 6680b86b-20240629_184401
lacktoneloop2b () {
  [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
  mkdir -p "$tmp"
  local v1=
  [ "$1" ] && v1="$1" || v1=".003"
  local v2= ; read v2 < <(dc -e "5 k $v1 0.92 * p")
  while :; do
    printf "%s" " 2b1/$v1" >>"$tmp/lacktone" ; lacktonegen 1 3 6 "$v1" || break 1 # 2b1
    printf "%s" " 2b2/$v1" >>"$tmp/lacktone" ; lacktonegen 3 4 6 "$v2" || break 1 # 2b2
    done || return 1
  } # 6680b86b-20240629_184401
lacktoneloop6a () {
  [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
  mkdir -p "$tmp"
  local v1=
  [ "$1" ] && v1="$1" || v1=".003"
  local v2= ; read v2 < <(dc -e "5 k $v1 0.92 * p")
  while :; do
    printf "%s" " 6a1/$v2" >>"$tmp/lacktone" ; lacktonegen 2 10 3 "$v2" || break 1 # 6a1
    printf "%s" " 6a2/$v1" >>"$tmp/lacktone" ; lacktonegen 3 2  3 "$v1" || break 1 # 6a2
    done || return 1
  } # 6680b86b-20240629_184401
lacktoneloop6b () {
  [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
  mkdir -p "$tmp"
  local v1=
  [ "$1" ] && v1="$1" || v1=".0043"
  local v2= ; read v2 < <(dc -e "5 k $v1 0.92 * p")
  # XXX return 1 if v1 is greater than 0.0099
  while :; do
    printf "%s" " 6b1/$v1" >>"$tmp/lacktone" ; lacktonegen 2 1  4 "$v1" || break 1 # 6b1
    printf "%s" " 6b2/$v2" >>"$tmp/lacktone" ; lacktonegen 3 11 4 "$v2" || break 1 # 6b2
    done || return 1
  } # 6680b86b-20240629_184401
lacktonegen () { local c="$1" e="$2" s="$3" v="$4" 
 local f1= f2= f3= f4= fi= d= fo= sec= tmp=
  [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
  mkdir -p "$tmp"
 #echo >>"$tmp/lacktone"
  case $c in # chord
    1) f1=-44 f2=-9 f3=-6 f4=-19.7  ;; # 1a1 1b1 1a1 2a1 2b1
    2) f1=-33 f2=-9 f3=-6 f4=-19.7  ;; #                        6a1 6b1
    3) f1=-12 f2=-9 f3=-5 f4=-2     ;; # 1a2 1b2 2a2 2b2        6a2 6b2
    esac
  case $e in # envlope
    1) fi=0.09 d=2.3  fo=1.35   ;; # 1a1 1b1                6b1
    2) fi=0.19 d=2.3  fo=0.78   ;; # 1a2 1b2                6a2
    3) fi=0.09 d=2.52 fo=1.35   ;; # 2a1 2b1
    4) fi=0.19 d=2.52 fo=0.78   ;; # 2a2 2b2
    5) fi=0.09 d=2.27 fo=1.35   ;;
    6) fi=0.19 d=2.33 fo=0.78   ;;
    7) fi=0.09 d=2.33 fo=1.35   ;;
    8) fi=0.19 d=2.27 fo=0.78   ;;
   10) fi=0.09        fo=1.35 ; read d < <(dc -e "5 k 1 $(($RANDOM %128)) 0.51 + / 0.8 + 1.87 + p") ;; #    6a1
   11) fi=0.19        fo=0.78 ; read d < <(dc -e "5 k 1 $(($RANDOM %128)) 0.51 + / 0.8 + 2.00 + p") ;; #    6b2
    esac
  case $s in # sleep
    1) sec=0.54 ;; # 1a
    2) sec=1.34 ;; # 2a
    3) sec=2.74 ;; #          6a
    4) sec=2.89 ;; #          6b
    5) read sec < <(dc -e "3 k 1 $(($RANDOM %49 + 1)) / 0.50 + p") ;; # 1b
    6) read sec < <(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 1.00 + p") ;; # 2b
    7) read sec < <(dc -e "3 k 1 $(($RANDOM %42 + 1)) / 0.52 + p") ;;
    esac
  local TOTAL_DURATION="$d"
  local FADE_IN_DURATION="$fi"
  local FADE_OUT_DURATION="$fo"
  local FADE_OUT_START=
    read FADE_OUT_START < <(awk "BEGIN {print $TOTAL_DURATION - $FADE_OUT_DURATION}")
    read f1 < <(awk "BEGIN {print 440 * 2^($f1/12)}")
    read f2 < <(awk "BEGIN {print 440 * 2^($f2/12)}")
    read f3 < <(awk "BEGIN {print 440 * 2^($f3/12)}")
    read f4 < <(awk "BEGIN {print 440 * 2^($f4/12)}")

#chkwrn f1=$f1 f2=$f2 f3=$f3 f4=$f4
#chkwrn FADE_IN_DURATION=$FADE_IN_DURATION TOTAL_DURATION=$TOTAL_DURATION FADE_OUT_DURATION=$FADE_OUT_DURATION 
ffplay -hide_banner -loglevel error -nodisp -autoexit \
    -bufsize 16k \
    -f lavfi \
    -i "anullsrc=channel_layout=mono:sample_rate=44100,
        aeval='sin(2*PI*${f1}*t)+sin(2*PI*${f2}*t)+sin(2*PI*${f3}*t)+sin(2*PI*${f4}*t)',
        afade=t=in:st=0:d=${FADE_IN_DURATION},
        afade=t=out:st=${FADE_OUT_START}:d=${FADE_OUT_DURATION},
    volume=${v},
    atrim=end=${TOTAL_DURATION},
    aresample=async=1000:min_comp=0.0001:min_hard_comp=0.85" \
    >/dev/null || return 1
    sleep "$sec" || return 1 ; sleep 3.148 || return 1
  } # 6680ad0a-20240629_175528

lacks1tone () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone1a $g & lacktone1b $g &
    lacktone
    fg;fg
    }
lacks2tone () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone2a $g & lacktone2b $g &
    lacktone
    fg;fg
    }
lacks5tone () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg
    }
lacks6tone () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone6a $g & lacktone6b $g &
    lacktone
    fg;fg
    }
lacks15tones () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone1a $g & lacktone1b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg
    }
lacks125tones () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone1a $g & lacktone1b $g &
    lacktone2a $g & lacktone2b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg
    }
lacks155tones () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone1a $g & lacktone1b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg
    }
lacks1255tones () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone1a $g & lacktone1b $g &
    lacktone2a $g & lacktone2b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone5a $g & lacktone5b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg ; fg;fg
    }
lacks6tones () {
    [ "$1" ] && v="$1" || v="0.5"
    lacktoneloop6a "$v" & lacktoneloop6b "$v" &
    lacktone
    fg;fg
    } # 668100ae-20240629_235220
lacks16tones () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone1a $g & lacktone1b $g &
    lacktone6a $g & lacktone6b $g &
    lacktone
    fg;fg ; fg;fg
    } # 6679c49e 20240624
lacks126tones () {
    [ "$1" ] && g="$1" || g="-55"
    lacktone1a $g & lacktone1b $g &
    lacktone2a $g & lacktone2b $g &
    lacktone6a $g & lacktone6b $g &
    lacktone
    fg;fg ; fg;fg ; fg;fg
    } # 6679c49e 20240624

  # {
  #   xargs -P 3 -I {} sh -c 'eval "$1"' - {} <<'EOF'
  # sleep 1; echo 1
  # sleep 2; echo 2
  # sleep 3; echo 3
  # echo 4
  # EOF
  # } &
  #
  # # Script execution continues here while `xargs` is running
  # # in the background.
  # echo "Waiting for commands to finish..."
  #
  # # Wait for `xargs` to finish, via special variable $!, which contains
  # # the PID of the most recently started background process.
  # wait $!

numlist() { # comma sequence aware file renaming utility with base 32 index and major character retention
  # so that when combined with another list, the result is interlaced with major sequence retained.
  # rev 6769b365-20241223_110043
  # Accept files as args OR stdin (one file per line), only act on regular files, squash leading "./";
  # Expect filenames to start with sequence characters (base 32 chars, followed by ",");
  # Retain the sequence and major sequence character, regenerate filenames with base 32 sequence index;
  # Bump up the sequence major value by "$numlistbump" if set (integer);
  # Prepend output filenames with "$numlist" string, if set;
  # Initialize base 32 comma sequence, with 0 major, for input files that have no comma sequence;
  # For name changes, without collisions, generate mv commands for review or "| sh"
  local fs='' f='' major_char='' new_major='' seq_num=0 B32_CHARS
  read B32_CHARS < <(tr -d '\n' < <(for a in {0..31} ; do base 32 $a ; done)) # 0123456789abcdefghjkmnpqrstuvxyz
  [ "$B32_CHARS" ] || chkerr "$FUNCNAME : empty B32_CHARS, base issue (6768d182)"
  [[ -z "$numlistbump" || "$numlistbump" =~ ^-?[[:digit:]]+$ ]] || {
    chkerr "$FUNCNAME : env numlistbump must be null or an integer (6768d4f4)" ; return 1 ;}
  bump_table() { # translate major_car from $B32_CHARS with $numlistbump
    local input_char="$1" offset="$2"
    [[ "$offset" =~ ^-?[[:digit:]]+$ ]] || return 1
    local i=0 ; while ((i < ${#B32_CHARS})); do [[ "${B32_CHARS:$i:1}" == "$input_char" ]] && break ; ((i++)) ; done
    local new_pos=$(( (i + offset) % 32 )) ; ((new_pos < 0)) && new_pos=$((new_pos + 32)) || true
    printf "%s" "${B32_CHARS:$new_pos:1}" ;}
  while [ $# -gt 0 ]; do fs+="$1"$'\n' ; shift ; done ; [ -z "$fs" ] && read -d '' fs || true
  while read -r f; do
    [ -f "$f" ] || continue
    [[ "$f" =~ ^[$B32_CHARS]+, ]] && { major_char="${f:0:1}"
    [ -n "$numlistbump" ] && { new_major=$(bump_table "$major_char" "$numlistbump")
      } || new_major="$major_char"
    seq_num=$((seq_num + 1))
    read seq_num32 < <(awk '{printf "%02s",$0}' < <(base 32 $seq_num))
    new_name="${numlist:-}${new_major}${seq_num32},${f#*,}"
    [ "$f" = "$new_name" ] || [ -e "$new_name" ] || echo "mv '$f' '$new_name'" ;}
    done <<< "$fs"
  seq_num=0
  while read -r f; do
    [[ $f =~ ^[$B32_CHARS]+, ]] && continue
    [ -f "${f#./}" ] || continue
    seq_num=$((seq_num + 1))
    read seq_num32 < <(awk '{printf "%02s",$0}' < <(base 32 $seq_num))
    new_name="${numlist:-}0${seq_num32},${f}"
    [ "$f" = "$new_name" ] || [ -e "$new_name" ] || echo "mv '$f' '$new_name'"
    done <<< "$fs"
  } # numlist 632ca5d3-20220922_111329 # 07/10/21


numlistdst () { # distribute filenames across base 32 major (alnum lower sans 'ilow')
    # in the future accept distribution major range (start/stop for the distribution)
    local f fs fss
    while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    fs="$(sed 's/^\.\///' <<<"$fs" | while IFS= read f ; do [ -f "${f%%/*}" ] && echo "${f%%/*}" || true ; done)"
    m=$(dc -e "8 k 31 $(awk 'END{print NR}' <<<"$fs") / p") # 0-31 * NR, for major, does not overflow major
    awk '{printf "%s %s\n",$0,NR}' <<<"$fs" \
        | while IFS= read a ; do set $a
            b=$(sed 's/^[0123456789abcdefghjkmnpqrstuvxyz]*,//' <<<"$1") # remove any sequence from the destination base
            # then make sequence in base 32, with distributed major
            printf "%s %s%02s,%s\n" "$1" "$(base 32 $(dc -e "$2 $m * p" | awk '{printf "%.0f\n",$1}') )" "$(base 32 $2)" "$b"
            done \
        | while IFS= read a ; do set $a # {orig} {dist-major}{seq},{name}
            local src="$1" dst="$2"
            [ "$src" = "$dst" ] || [ -e "$dst" ] && chkwrn "$FUNCNAME collision : $dst (6542c540)" || echo "mv \"$src\" \"$dst\"";
            done
    } # numlistdst 60fe5d7a-20210726_000000

mp3range () { # mp3 listing limiter
    # of regex arg1 start pass through,
    # to regex arg2 stop (or null) end
    # from within each remaining args
    # or current dir if no remaining args.
    #
    # file fullpath of two directories, sorted by filepath...
    # mp3range 2 3 ../ . | ckstat | sort -k6 | awk '{print $6}'
    #
    local start="$1" stop="$2" dirs= a= opwd="$PWD" prefix= mp3range_file="$HOME/0/v/mp3range"
    mkdir -p "${mp3range_file%/*}";
    local verb="${verb:=devnul}"
    $verb2 for expr "${stop}" : "${start}"
    [ "$stop" ] && { expr "${stop}" : "${start}" >/dev/null \
            && chkwrn "$FUNCNAME : unintended consequences : $start $stop (6542c510)"
        stop="/^${stop}/" ;} \
        || stop="0"
    start="/^${start}/"
    #chkwrn for awk \"${start},${stop}\"
    shift 2 || shift || true # shift 2 fails if $# = 1, so "shift 2 without err signal" in all cases...
    #chkwrn "#$# @=$@"
    [ $# -gt 0 ] && { dirs="$1" ; shift || true ;}
    while [ $# -gt 0 ] ; do dirs="$(printf "%s\n%s\n" "$dirs" "$1")" ; shift ; done
    [ "$dirs" ] || dirs="$PWD"
    #$verb pwd=$PWD dirs=$dirs
    #echo "$dirs"     | sed '/^$/d' | while IFS= read a; do ${verb} "ead $a" ; done
    echo "$dirs" | sed -e '/^$/d' | while IFS= read a; do
        # subshell to preserve $OLDPWD on break
        ( [ -d "$a" ] && {
            cd "$a"
            [ "$a" = "$opwd" ] && prefix="" || prefix="$PWD/"
            # drop and warn about filenames with '%' in them??
            ls | awk ${start},${stop} | sed -e '/.mp3$/!d' -e "s%^%$prefix%" | tee "$mp3range_file"
            } || chkwrn "not a dir with mp3 files : '$a' (6542c455)" ) # subshell for $OLDPWD
        done
    } # mp3range 62ea1cfa-20220803_000000

aplayff () { playff < <(mp3atime "$1") ;} # 658238f5
aplayffr () { playffr < <(mp3atime "$1") ;} # 658238ef
mp3atime () { # list mp3 in dir (arg1) by atime, sans 0*mp3 and y*mp3
    local a="$1" mp3atime_file="$HOME/0/v/mp3atime"
    mkdir -p "${mp3atime_file%/*}";
    [ -d "$a" ] || { devnul "$FUNCNAME : arg1 not a dir '$a' using '$link' (6581e36c)" ; a="$link" ;}
    [ -d "$a" ] || { chkerr "$FUNCNAME : not a dir '$a' (6581e360)" ; return 1 ;}
    ls -rtu $(find "$a" -maxdepth 1 -type f -name \*mp3 \! -name 0\* \! -name y\* ) | tee "$mp3atime_file"
    } # mp3atime 6581e2a0-20231219_103606

alexplayff () { playff < <(mp3atimelex "$1") ;} # 658238e3
alexplayffr () { playffr < <(mp3atimelex "$1") ;} # 658238d7
mp3atimelex () { # list mp3 in dir (arg1) by lex, starting from oldest atime, sans 0* and y*
    local aoldest= mark= dir= mp3atimelex_file="$HOME/0/v/mp3atimelex"
    mkdir -p "${mp3atimelex_file%/*}"
    read aoldest < <(head -n1 < <(mp3atime "$1"))
    dir="${aoldest%/*}"
    mark="${aoldest##*/}" ; mark="${mark%,*}" # always reduce mark to seq data (least mark data contain regex data)
    # put a mark in the file list, sort, check for and skip the mark (next),
    # buffer the lines before the mark (!p), #print lines after (p),
    # print buffer (END); fixup so the list is fullpath sans (0|y) files
    ( cd "$dir"; echo "./$mark"; find . -mindepth 1 -maxdepth 1 -name \*mp3 ) \
        | sort | awk -v mark="$mark" '
            $0 ~ "./"mark && !p {p=1;next}
                              p {print}
                             !p {b=b $0 ORS}
                            END {print b}' \
        | sed -e '/^$/d' -e 's=./==' -e '/^0/d' -e '/^y/d' -e "s:^:${dir}/:" \
        | tee "$mp3atimelex_file"
    } # mp3atimeplayff 6581ff2d-20231219_123755

mp3loop () { # genai developed doc from code, manual revised doc, genai code from doc flops, but helps...
#   mp3loop requirement:
#   play a loop of mp3 files in a directory starting from a lexicographic position
#   take a -v option to store the volume (1-100)
#   if the stored value is not between 1-100, a default volume should be stored
#   store the mp3 file list to loop
#   skip files starting with 0 or y
#   input of an existing filename in current or relative directory, should be taken as starting point in that directory
#   if no slash (eg ./) is in the input, the stored playff directory should be used to locate mp3 files for the loop
#   input of filename fragment represents the lexicographic position of the anchored fragment within the identified directory
#
#   primitive environment:
#   playffr function is provided and plays a list of mp3 files read from stdin
#   playffr will read a stored volume before playing each mp3
#   if the stored value is 0 playffr will stop with signal 0
#   playffr will store the input file and PWD prior to playing each mp3
#
#   environment specification:
#   mp3loop will store generated mp3 list in HOME/0/v/mp3loop
#   playffr will store the input, followed by space, folowed by PWD in $HOME/0/v/playff
#   playffr reads the vol from $HOME/0/v/playff_vol
    local mp3loop_file="$HOME/0/v/mp3loop" playff_file="$HOME/0/v/playff";
    local playff_vol_file="${playff_file}_vol"
    local dir='' mark='' vol=''
    local verbb=devnul
    mkdir -p "${playff_file%/*}" "${mp3loop_file%/*}";
    [ "$1" = '-v' -a $# -ge 2 ] && { vol="$2"; shift 2 ;}
    [ "$vol" ] || vol="$(< "$playff_vol_file")"
    [ "$vol" -a "$vol" -eq "$vol" ] || { chkwrn "$FUNCNAME : invalid volume '$vol' using '88' (6546998d)"; vol=88 ;}
    echo "$vol" >"$playff_vol_file"
    [ -d "$1" ] && { $verbb 'If input is a dir, use it with default mark'
        dir="$(cd "$1" && pwd -P)" ; $verbb "dir='$dir'" ;}
    [ -f "$1" ] && { $verbb 'If input is a file, use as start point, determine dir and mark'
        dir="$(cd "${1%/*}" ; pwd -P)" mark="${1##*/}" ; $verbb "dir='$dir' mark='$mark'" ;}
    [ "$1" ] && { $verbb 'there is arg1 input, continue logic'
        [[ "$1" =~ / ]] \
          && { $verbb 'input has slash, use realpath dir and arg1 mark'
                dir="$(cd "${1%/*}" ; pwd -P)" mark="${1##*/}" ; $verbb "dir='$dir' mark='$mark'" ;} \
          || { $verbb 'input has no slash, use realpath playff data and arg1 mark'
              [ "$1" = '-n' ] && { $verbb 'input is next flag (-n), determin next from playff data' ;
                    $verbb "section incomplete!" ; return 3 ;} \
                || { $verbb 'use realpath playff data and arg1 mark'
                    [ -f "$playff_file" ] && { read playff_data <"$playff_file" ; $verbb "load playff_data" ;} && \
                      dir="$( cd "${playff_data##* }" ; dir="${playff_data% *}" ; cd "${dir%/*}" ; pwd -P)"
                      mark="$1" ;}
              }
        } || { $verbb 'arg1 is not set, algo over' ;}
    $verbb "arg/data parsed dir='$dir' mark='$mark'"
    [ -z "$dir" -o -z "$mark" ] && { $verbb "dir or mark is null, load playff_file data"
      [ -f "$playff_file" ] && { read playff_data <"$playff_file" ; $verbb "load playff_data" ;}
      $verbb "default dir and mark, per realpath construction of playff data"
      set $( cd "${playff_data##* }" # second element, dir
          dir="${playff_data% *}" # first element, file name
          cd "${dir%/*}" ; pwd -P # full path to dirname of first element
          echo "${dir##*/}" )     # basename first element
                                  $verbb "playff_data defaults dir='$dir' mark='$mark'"
      [ "$dir" ] || dir="$1"
      [ "$mark" ] || mark="$2"
      }
      $verbb "per algo and arg,    dir='$dir' mark='$mark'"
    mark="${mark%,*}" ; $verbb 'always reduce mark to seq data (least mark data contain regex data)'
    # put a mark in the file list, sort, check for and skip the mark (next),
    # buffer the lines before the mark (!p), #print lines after (p),
    # print buffer (END); fixup so the list is fullpath sans (0|y) files
    ( cd "$dir"; echo "./$mark"; find . -mindepth 1 -maxdepth 1 -name \*mp3 ) \
        | sort | awk -v mark="${mark}" '
            $0 ~ "./"mark && !p {p=1;next}
                              p {print}
                             !p {b=b $0 ORS}
                            END {print b}' \
        | sed -e '/^$/d' -e 's=./==' -e '/^0/d' -e '/^y/d' -e "s:^:${dir}/:" \
        | tee "$mp3loop_file" | playffr
} # mp3loop 64e3caf9-20230821_133703

playffr () { # for files (args or stdin), continuously repeat invocations of ffplay, without display
    local playff_file="$HOME/0/v/playff"
    local playff_vol_file="${playff_file}_vol" vol='' f='' fs=''
    [ "$1" = '-v' -a $# -ge 2 ] && { vol="$2"; shift 2 ;}
    [ "$vol" ] || vol="$(< "$playff_vol_file")"
    [ "$vol" -a "$vol" -eq "$vol" ] || { chkwrn "$FUNCNAME : invalid volume '$vol' using '88' (6546998d)"; vol=88 ;}
    mkdir -p "${playff_file%/*}"
    cat >"$playff_vol_file" <<<"$vol"
    [ $# -gt 0 ] && { fs="$1" ; shift ;}
    while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    # while :; do ...TODO identify/resolve inability to ctrl-c when nput has no valid file
    while IFS= read f; do
      [ -f "$f" ] && { tput bold ; chktrue "$f" ; tput sgr0
        echo "$f $PWD" >"$playff_file" # store PWD, least $f is relative
        vol="$(< "$playff_vol_file")" # read per song...
        echo " "$(hms2sec $(ffprobe -hide_banner  -loglevel info "$f" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')) sec, vol $vol
        touch -a "$f" # since mac does not update atime, cf APFS_FEATURE_STRICTATIME
        ffplay -hide_banner -stats -autoexit -loglevel error -nodisp -volume $vol "$f" || return 1
        } || { chkwrn "$FUNCNAME : not a file : '$f' (6542c3b8)" ; sleep 2 ;}
      done <<<"$fs"
    } # playffr 6542c3b7-20231101_143125

playff () { # for files (args or stdin), invoke ffplay with display
    local playff_file="$HOME/0/v/playff"
    local playff_vol_file="${playff_file}_vol" vol='' f='' fs=''
    [ "$1" = '-v' -a $# -ge 2 ] && { vol="$2"; shift 2 ;}
    [ "$vol" ] || vol="$(< "$playff_vol_file")"
    [ "$vol" -a "$vol" -eq "$vol" ] || { chkwrn "$FUNCNAME : invalid volume '$vol' using '88' (65468ec9)"; vol=88 ;}
    mkdir -p "${playff_file%/*}"
    cat >"$playff_vol_file" <<<"$vol"
    [ $# -gt 0 ] && { fs="$1" ; shift ;}
    while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    while IFS= read f; do
      [ -f "$f" ] && { tput bold ; chktrue "$f" ; tput sgr0
        echo "$f $PWD" >"$playff_file" # store PWD, least $f is relative
        vol="$(< "$playff_vol_file")" # read per song...
        echo " "$(hms2sec $(ffprobe -hide_banner  -loglevel info "$f" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')) sec, vol $vol
        touch -a "$f" # since mac does not update atime, cf APFS_FEATURE_STRICTATIME
        ffplay -hide_banner -stats -autoexit -loglevel error -top 52 -x 1088 -y 280 -volume $vol "$f" || return 1
        } || { chkwrn "$FUNCNAME : not a file : '$f' (6542c3b6)" ; sleep 2 ;}
      done <<<"$fs"
    } # playff 6542c3b5-20231101_143123

playffrends () { # review mp3 and prepare to re-transcode
    # accept stdin mp3 filenames
    # read cmd (prompt current file)
    # on cmd
    #   space) play current beg and end
    #   b) play current beg
    #   B) read bc expression, edit 'ss=' value, f, transcode beg, play beg
    #   E) read bc expression, edit 'to=' value, invoke b
    #   e) play current end
    #   n) advance next file
    #   t) transcode beg and end (sans time/pitch)
    #   f) formfile orig, and formfile with edits
    #   number) set v*4 seconds
    #   # presence, compression, delay,
    # universal quality of quality, regardless of genera is an
    # indication by time/pitch of fourthcoming time/pitch.
    # this quality can be masked and unmasked by normalizing,
    # compression and time/pitch shifting.
    true
    }
playffend () { # Play the ending of files (args or stdin), always "no display"
    # -v or -volume to set volume, default is 100
    # and touch since mac does not update atime, cf APFS_FEATURE_STRICTATIME
    # https://developer.apple.com/support/downloads/Apple-File-System-Reference.pdf#page=67&zoom=auto,-62,145
    # typical invoke for review of recent file endings
    # find . -maxdepth 1 -name \*mp3 -mtime +1 -mtime -40 -atime +1 | sort | playffend
    local playff_file="$HOME/0/v/playff"
    local playff_vol_file="${playff_file}_vol" vol='' f='' fs='' end=''
    [ "$1" = '-v' -a $# -ge 2 ] && { vol="$2"; shift 2 ;}
    [ "$vol" ] || vol="$(< "$playff_vol_file")"
    [ "$vol" -a "$vol" -eq "$vol" ] || { chkwrn "$FUNCNAME : invalid volume '$vol' using '88' (65468ec9)"; vol=88 ;}
    mkdir -p "${playff_file%/*}"
    cat >"$playff_vol_file" <<<"$vol"
    [ $# -gt 0 ] && { fs="$1" ; shift ;}
    while [ $# -gt 0 ] ; do fs="$(printf "%s\n%s\n" "$fs" "$1")" ; shift ; done
    [ "$fs" ] || fs="$(cat)"
    echo "$fs" | while IFS= read f; do
        [ -f "$f" ] && { tput bold ; chktrue "$f" ; tput sgr0
            vol="$(< "$playff_vol_file")" # read per song...
            end=$( dc -e "$(hms2sec $(ffprobe -hide_banner -loglevel info "$f" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')) 25 - p" )
            chktrue probsec $(hms2sec $(ffprobe -hide_banner -loglevel info "$f" 2>&1 | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //')) vol: $vol;
            echo "$f $PWD" >"$playff_file" & # store PWD, least $f is relative
            touch -a "$f"
            chkwrn formfile "$f"
            chktrue "ffplay -t  10    -hide_banner -stats -autoexit -loglevel error -top 52 -x 1088 -y 280 -volume $vol '$f'";
            chktrue "ffplay -ss $end  -hide_banner -stats -autoexit -loglevel error -top 52 -x 1088 -y 280 -volume $vol '$f'";
                     ffplay -t  10    -hide_banner -stats -autoexit -loglevel error -top 52 -x 1088 -y 280 -volume $vol "$f" || return 1
                     ffplay -ss $end  -hide_banner -stats -autoexit -loglevel error -top 52 -x 1088 -y 280 -volume $vol "$f" || return 1
#                    ffplay -ss $end  -hide_banner -stats -autoexit -loglevel error -nodisp                -volume $vol "$f" || return 1
        } || chkwrn "$0 : not a file : '$_file' (6542c40a)";
    done
} # playffend 64d51e6d-20230810_102907

probeff () { # use ffprobe to extract duration of files (args OR stdin filename per line)
    local f fs
    [ $# -gt 0 ] && { fs="$1" ; shift ; while [ $# -gt 0 ] ; do read -d '' fs < <(printf "%s\n%s\n" "$fs" "$1") || true ; shift ; done ;}
    [ "$fs" ] || { read -d '' fs < <(cat) || true ;}
    echo "$fs" | while IFS= read f; do
        local inpath infile="${f##*/}" # basename
        expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # input dirname
        local infilep ; read infilep < <(tr -d '\n' <( cd "${inpath}" ; pwd -P ; echo "/${infile}" )) || true # full filepath
        [ -f "$infilep" ] && {
            read -d '' d < <(
                sed -e '/Duration: N\/A, /d' -e '/Duration/!d' -e 's/,.*//' -e 's/.* //' < <(
                ffprobe -hide_banner -loglevel info "$infilep" 2>&1 )) || true
            [ "$d" ] && echo "$d $infilep" || true
        } || { chkwrn "$FUNCNAME : not a file '$infilep' (666f48ec)" ;}
        done
    } # probeff 628322e1-20220516_212143

rotatefile () { #P> keep at least n backups, and delete files older than m seconds
    local a= use="$FUNCNAME {file}"'
        Keep at least {rotatefile_keep} files
        remove backups older than {rotatefile_secs}
        and move file {arg1} to {arg1}-{0x mtime}
        default 18 days = 60 seconds per minute * 60 per hour * 24
        rotatefile_secs="$((18 * 60 * 60 * 24 ))" rotatefile_keep="7"'
    declare -f chkerr >/dev/null 2>&1  || { echo "$FUNCNAME : chkerr unavailable (630bacd0)" 1>&2 ; return 1 ;}
    declare -f validfn >/dev/null 2>&1 || { echo "$FUNCNAME : validfn unavailable (630c4002)" 1>&2 ; return 1 ;}
    validfn ckstat c44370c9 000003ac   || { chkerr "$FUNCNAME : unexpected ckstat (630bab5c)" ; return 1 ;}
    which tai64n >/dev/null            || { chkerr "$FUNCNAME : tai64n not in path (630bb522)" ; return 1 ;}
    xs () { echo | tai64n | sed -e 's/^@4[0]*//' -e 's/.\{9\}$//' ;}
    term_pleft () { local str= char='-'
        { [ $# -gt 0 ] && echo "$*" || cat ;} \
          | while IFS= read str; do [ -t 1 ] && {
                local cols="$(( $(tput cols) - ${#str} - 4 ))";
                printf "%s" "$char$char $str "
                printf "%*s\n" "$cols" '' | tr ' ' "$char";
                } || true
            done ;}
    local f="$1"
    test "$f" || { chkerr "$FUNCNAME : no file (arg1) (630c469e)" ; $FUNCNAME --help ; return 1 ;}
    test "$f" = "-?" -o "$f" = "-h" -o "$f" = "--help" && { sed 's/^[    ]*//' <<<"$use" | term_pleft ; return 0 ;}
    test -f "$f" || { chkerr "$FUNCNAME : not a file '$f' (630b96a3)" ; $FUNCNAME --help ; return 1 ;}
    test "$rotatefile_secs" || local rotatefile_secs="$((18 * 60 * 60 * 24 ))"
    test "$rotatefile_keep" || local rotatefile_keep="7"
    test "$rotatefile_secs" -ge 0 || { chkerr "$FUNCNAME : {rotatefile_secs} not an integer '$rotatefile_secs' (630b9a9f)" ; return 1 ;}
    test "$rotatefile_keep" -ge 0 || { chkerr "$FUNCNAME : {rotatefile_keep} not an integer '$rotatefile_keep' (630b9ac3)" ; return 1 ;}
    local infile inpath infilep
    infile="${f##*/}"                                              # infile  == basename f
    expr "$f" : ".*/" >/dev/null && inpath="${f%/*}" || inpath="." # inpath  ==  dirname f
    infilep="$(cd "${inpath}" ; pwd -P)/${infile}"                 # infilep == realpath f
    local xs="$(xs)"
    find "$inpath" -mindepth 1 -maxdepth 1 -type f -name "${infile}-*" -regex ".*/${infile}-[[:xdigit:]]\{8\}$" \
        | sort | sed -n -e :a -e "\$q;N;2,${rotatefile_keep}ba" -e 'P;D' \
        | while IFS= read f ; do
            expr "$(( 0x$xs - 0x$(ckstat "$f" | awk '{print $5}') ))" '>' "$rotatefile_secs" >/dev/null && rm -f "$f" || true
            done
    mv "$f" "${f}-$(ckstat "$f" | awk '{print $5}')"
    }

spin1 () { # '.oO@Oo+~:"`   '
    [ "$1" = "0" ] && printf "\010" && return 0
    [ "$1" ]     && local _spin1="$1"              && local _spin1_len="${#_spin1}"
    [ "$_spin1" ] || local _spin1='_./-|-\+/-|-\ ' && local _spin1_len="${#_spin1}"
    [ "$_spin1_n" ] || _spin1_n=1
    local _spin1_p=$(( _spin1_n % _spin1_len ))
    printf "\010%s" "${_spin1:_spin1_p:1}"
    _spin1_n=$((++_spin1_n))
    }

spin2 () { # '.oO@Oo+~:"`   '
    [ "$1" = "0" ] && printf "\010" 1>&2 && return 0
    [ "$1" ]     && local _spin2="$1"              && local _spin2_len="${#_spin2}"
    [ "$_spin2" ] || local _spin2='_./-|-\+/-|-\ ' && local _spin2_len="${#_spin2}"
    [ "$_spin2_n" ] || _spin2_n=1
    local _spin2_p=$(( _spin2_n % _spin2_len ))
    printf "\010%s" "${_spin2:_spin2_p:1}" 1>&2
    _spin2_n=$((++_spin2_n))
    }

# 20221013 6348728e
base () { # convert {decimal} arg2 to {base} arg1
    # digs = string.digits + string.ascii_letters
    # digs = "0123456789abcdefghijklmnpqrstuvwxyz"
    # shift out characters "ilow" for visual acuity
    #        "0123456789abcdefghjkmnpqrstuvxyz"
  # local digs=$(echo {0..9} {a..z} | tr -d ' ilow\n')
    expr "$1" : "-[-]*h" >/dev/null && { # support --help and -h
        chktrue "$FUNCNAME : convert {decimal} arg2 to {base} arg1"
        chktrue "base and input are integers, base <= 32   "
        chktrue 'base32 = "0123456789abcdefghjkmnpqrstuvxyz"'
        chktrue '(sans "ilow")'
        return 2 ;}
    local digs="0123456789abcdefghjkmnpqrstuvxyz" sans="ilow"
    local sign='' out='' p='' base="$1" x="$2"
    [ "$#" -gt 2 ] && { $FUNCNAME --help ; return 1 ;}
    [ "$base" -a "$x" ] || {
        $FUNCNAME --help
        chkerr "$FUNCNAME : must provide output {base} arg1, and input {decimal} arg2 : arg1='$1' arg2='$2' (6542c792)" ; return 1 ;}
    [[ "$base" =~ ^-?[0-9]+$ ]] || { chkerr "$FUNCNAME : arg1 (output base) must be an integer : arg1='$1' (6542c768)" ; return 1 ;}
    [[ "$x"    =~ ^-?[0-9]+$ ]] || { chkerr "$FUNCNAME : arg2 (decimal input) must be an integer : arg2='$2' (6542c774)" ; return 1 ;}
    [ $x -lt 0 ] && sign='-' || { [ $x = 0 ] && { echo 0 ; return 0 ;} ;}
    x=$(( x * "${sign}1" ))
    while [ $x -gt 0 ] ; do
        p=$((x % base))
        out="${digs:p:1}$out"
        x=$((x / base))
        done
    echo "${sign}${out}"
    } # base 20221013 6348728e

base10from () { # convert to decimal the value (arg2), in base (arg1, b32 max, and sans 'ilow')
    # digs = string.digits + string.ascii_letters
    # digs = "0123456789abcdefghijklmnpqrstuvwxyz"
    # shift out characters "ilow" for visual acuity
    #        "0123456789abcdefghjknpqrstuvxyz"
  # local digs=$(echo {0..9} {a..z} | tr -d ' ilow\n')
  expr "$1" : "-[-]*h" >/dev/null && { # support --help and -h
        chktrue "$FUNCNAME : convert value (arg2) to decimal, from base (arg1)"
        chktrue "base and output are integers, base <= 32   "
        chktrue 'base32 = "0123456789abcdefghjkmnpqrstuvxyz"'
        chktrue '(sans "ilow")'
        return 2 ;}
  local base="$1" x="$2"
  [ "$base" -a "$x" ] || { $FUNCNAME --help
    chkerr "$FUNCNAME : requires input base (arg1), and input value (arg2) : arg1='$1' arg2='$2' (65615a6c)" ; return 1 ;}
  [[ "$x" =~ ^-?[0123456789abcdefghjkmnpqrstuvxyz]+$ ]] || { chkerr "$FUNCNAME : arg2 (input value) must be [[:alnum:]]+ sans 'ilow' : arg2='$2' (65615a78)" ; return 1 ;}
  [[ "$base" =~ ^[0-9]+$ && "$base" -ge 2 && "$base" -le 32 ]] \
    || { chkerr "$FUNCNAME : arg1 must a positive integer 2=<{base}<=32 : arg1='$1' (65615a72)" ; return 1 ;}
  awk -v b="$base" '{
    while (length($1)>0) {
      c = substr($1,length($1),1)
      digit = index("0123456789abcdefghjkmnpqrstuvxyz",c)-1
      n += digit*(b^i)
      i++
      $1 = substr($1,1,length($1)-1)
    } print n }' <<<"$x"
    } # 656121d3-20231124_142057

diffenv () { # create an env file, report diff iff file exists
    local d_file="$HOME/0/v/diffenv" d_env="$(declare -p | sort)"
    mkdir -p "${d_file%/*}"
    [ -e "$d_file" ] && diff -U 0 "$d_file" - <<<"$d_env"
    cat >"$d_file" <<<"$d_env"
    }

auto_dgst () { #0> auto create digest (_/dgst), _/dgst-sha3-384, _/dgst-ckstatsum, and rcs in ./_ (or [arg1]/_)
    local a='' d='' h='sha3-384'
    [ "$1" ] && { [ -d "$1" ] && d="$1" || { chkerr "$FUNCNAME : arg1 not a dir '$1' (6513cb4c)" ; return 1 ;} ;}
    [ "$d" ] || d="."
    which openssl >/dev/null 2>&1 || { chkerr "$FUNCNAME : openssl not available (65136036)" ; return 1 ;}
    which rcs     >/dev/null 2>&1 || { chkerr "$FUNCNAME : rcs not available (65136072)" ; return 1 ;}
    mkdir -p "$d/_"
    ( cd "$d" # root relative digest and preserve OLDPWD, maybe exclude ',v$' and ',$' files later...
      find -E . -regex ".*(/%$|/0$|,$|~$)" -prune -type f -o -type f \
          | grep -Ev '(/\.DS_Store|/tmp/|/.git/|,v$|~$)' | sort >"./_/dgst"
      while read a; do openssl dgst -${h} "$a" ; done >"./_/dgst-${h},"      <"./_/dgst"
      while read a; do ckstatsum "$a"          ; done >"./_/dgst-ckstatsum," <"./_/dgst"
      ci -m"($FUNCNAME)" -l -t-"auto digest" -q "./_/dgst"
      ci -m"($FUNCNAME)" -l -t-"auto digest ${h}" -q "./_/dgst-${h},"
      ci -m"($FUNCNAME)" -l -t-"auto digest ckstatsum" -q "./_/dgst-ckstatsum,"
    ) ;}

which stemwords >/dev/null 2>&1 && { # create stemwords wrappers, stemray and stempar
stemray() { # take args or stdin, return brackeded sorted comma separated words, and novel unstemmed in comments
    local w= wi="$*" wu=() ws=() # w{word} wi{input words} wu{arr uniq words input} ws{arr stemmed wu}
    # read stdin if null args
    [ "$wi" ] || read -d '' wi < <(cat) || true
    # load wu() with unique wi
    while read w ; do wu+=($w) ; done < <(sort -u < <(sed '/^$/d' < <(tr -c '[:alnum:]' '\n' < <(echo "$wi"))))
    while read w ; do ws+=($w) ; done < <(sort -u < <(stemwords < <(for w in ${wu[@]};do echo "$w" ; done)))
    awk 'BEGIN { ORS = ""; print "[ " }           # wrap list in brackets, purge \n
         NF { if (NR > 1) print ", " ; print $1 } # ignore blanks, comma not before first
         END { print " ]" }                       # close bracket
         ' < <(tr ' ' '\n' <<<"${ws[@]}")
    for w in "${wu[@]}"; do grep -i " $w " <<<" ${ws[*]} " >/dev/null || echo -n " $w" ; done | sed -e '/^$/d' -e 's/^/ #/'
    echo
    # while read a ; do echo ; echo -n ": " ; stemray "$a" ; a= ;  done
    } # stemray 670d57e8-20241014_104150
# process stemwords on input text returning same paragraph/puncuation but loosing capitalization
# Requirements:
#   BSD/Darwin compatibility:
#   Input processing:
#     - Handle UTF-8 input.
#     - Convert input newlines (\n) to a special character (ASCII 128) before processing.
#   Disassembly (intermediate format):
#     - Output one [:alpha:]* word per line.
#     - Preserve all non-alphabetic characters (including spaces and punctuation) on their own lines.
#     - Preserve special characters (ASCII 128) which represent original newlines.
#   Processing:
#     - pipe the data to stemwords, git@github.com:snowballstem/snowball.git
#   Reassembly:
#      - Remove all newlines from the intermediate format.
#      - Convert special characters (ASCII 128) back to newlines (\n).
stempar() { # take args or stdin, return stemwords text
  _dsy() { # disassemble text
    iconv -f utf-8 -t ascii//TRANSLIT -c | tr '\n' '\200' | LC_ALL=C awk '
      { for (i = 1; i <= length; i++)
        { c = substr($0, i, 1)
          if (c ~ /[[:alpha:]]/)
            { word = word c }
          else { if (word != "")
            { print word ; word = "" }
            printf "%c\n", c }
        }
      }
      END { if (word != "") print word }'
    }
  _asy() { # reassemble text
    tr -d '\n' | tr '\200' '\n'
    }
  # load words input (wi) from args or stdin
  local wi="$*"
  [ "$wi" ] || read -d '' wi < <(cat) || true
  echo "$wi" | _dsy | stemwords | _asy
  } # stempar 670d7aa1-20241014_130959
} || true # no error is stemwords not installed

