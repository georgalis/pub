#!/bin/sh
#
# Unlimited use with this notice. (C) 2006-2018 George Georgalis <george@galis.org>
#
#:: This script automates the process of rsync snapshot backup 
#:: and rotation in a push, pull or localhost configuration.
#

set -e
#set -x
#[ -t 0 ] && set -x || true # verbose if run from terminal

chkerr () { if [ -n "$*" ]; then echo "$*" >&2 && exit 1 ; fi ;}

usage () { echo "Usage: $0
# $0 local orig prefix
   makes a local snapshot in prefix/bk/1/ of orig
# $0 (push|pull) host orig prefix
   pushes orig to host:/prefix/bk/1/ or from host:/orig to prefix/bk/1/
# $0 rotate level prefix [host]
   generates prefix/bk/level/ from prefix/bk/1/ oprionally on remote host
# $0 purge level prefix [host]
   purges excess from prefix/bk/level/ oprionally on remote host
# $0 merge prefix [host]
   merge like files (dupmerge.c) below prefix, optionally on remote host
# $0 batch [include]
   use batch mode on $HOME/.$(basename $0).rc or optionally include
# $0 batch conf
   display discovered include file
# $0 help
   display this help message
Extra parameters are considered an error,
orig and prefix must be full path." ;}

lock () { # lock to prevent multiple generating runs to
 # the same host, you can still shoot yourself in the foot
 #[ ! "$(id -u)" = "0" ] && chkerr "You must be root to lock $(basename $0) in /var/run"
 LOCK="/tmp/$(basename $0)-${USER}-${HOST}.pid"
 [ -f "$LOCK" ] && chkerr "Lock exists: $LOCK" || echo "$$" >"$LOCK" ;}
unlock () { rm $LOCK ;}

locallast () { find $PREFIX/1 -mindepth 1 -maxdepth 1 -type d | sort | tail -n1 ;}
remotelast () { ssh $HOST "find $PREFIX/1 -mindepth 1 -maxdepth 1 -type d | sort | tail -n1" ;}
testlast () { [ -z "$LAST" ] && chkerr ">>> No prior backup?  mkdir -p $PREFIX/0 $PREFIX/1/$NOW $PREFIX/2 $PREFIX/3" || true ;}

localsnap () {
 mkdir -p $PREFIX/0/$NOW/$ORIG/
 { rsync $rsync_opt --link-dest="$LAST$ORIG" $ORIG/ $PREFIX/0/$NOW$ORIG/ \
  || true # files could dissappear durring push
 } | grep -v /$ || true # cleanup output, false exit expected
 mv $PREFIX/0/$NOW $PREFIX/1/
} # localsnap

pushsnap () {
 ssh $HOST "mkdir -p $PREFIX/0/$NOW/$ORIG/"
 { rsync $rsync_opt --link-dest="$LAST/$ORIG" $ORIG/ ${HOST}:$PREFIX/0/$NOW/$ORIG/ \
  || true # files could dissappear durring push
 } | grep -v /$ || true # cleanup output, false exit expected
 ssh $HOST "mv $PREFIX/0/$NOW $PREFIX/1/"
} # pushsnap

pullsnap () {
 mkdir -p $PREFIX/0/$NOW/$ORIG/
 { rsync $rsync_opt --link-dest="$LAST/$ORIG" $HOST:$ORIG/ $PREFIX/0/$NOW/$ORIG/ \
  || true # files could dissappear durring push
 } | grep -v /$ || true # cleanup output, false exit expected
 mv $PREFIX/0/$NOW $PREFIX/1/
} # pullsnap

rotlocal () {
 case $LEVEL in
  2|3)
   mv "$LAST" "$PREFIX/$LEVEL/"
  ;;
  *)
   chkerr "$0 : invalid rotate level."
  ;;
 esac
} # rotlocal

rotremote () {
 case $LEVEL in
  2|3) ssh $HOST "mv '$LAST' '$PREFIX/$LEVEL/'"
  ;;
  *)
   chkerr "$0 : invalid rotate level."
  ;;
 esac
} # rotremote

# below the PREFIX
# 	./bk/0 is in process snapshot
# 	./bk/1 is completed first interval
#	./bk/2 is completed second interval, daily
#	./bk/3 is completed third interval, weekly

purglocal () {
 case $LEVEL in
  1) # dispose snapshots older than 3 days, but keep at least 40
   # (sed expresession suppresses 40 lines from tail of input)
   chkerr $( ls -d $PREFIX/1/* 2>/dev/null | sed -n -e :a -e '$q;N;2,40ba' -e 'P;D' \
    | while read dir; do
     find \$dir -maxdepth 0 -mtime +3 -exec rm -rf \{\} \;
    done 2>&1 )
  ;;
  2) # dispose of dailies older than 14 days but keep at least 20
   # (sed expresession suppresses 20 lines from tail of input)
   chkerr $( ls -d $PREFIX/2/* 2>/dev/null | sed -n -e :a -e "\$q;N;2,20ba" -e "P;D" \
    | while read dir; do
     find \$dir -maxdepth 0 -mtime +14 -exec rm -rf \{\} \;
    done 2>&1 )
  ;;
  *) chkerr "Undefined level for purge: $0 $*" ;;
 esac
} # purgelocal

purgremote () {
 case $LEVEL in
  1) # dispose snapshots older than 3 days, but keep at least 40
   # (sed expresession suppresses 40 lines from tail of input)
   chkerr $(ssh $HOST "ls -d $PREFIX/1/* 2>/dev/null | sed -n -e :a -e '\$q;N;2,40ba' -e 'P;D' \
    | while read dir; do
     find \$dir -maxdepth 0 -mtime +3 -exec rm -rf \{\} \;
    done" 2>&1 )
  ;;
  2) # dispose of dailies older than 14 days but keep at least 20
   # (sed expresession suppresses 20 lines from tail of input)
   chkerr $(ssh $HOST 'ls -d '$PREFIX'/2/* 2>/dev/null | sed -n -e :a -e "$q;N;2,20ba" -e "P;D" \
    | while read dir; do
     find $s -maxdepth 0 -mtime +14 -exec rm -rf \{\} \;
    done' 2>&1 )
  ;;
 esac
} # purgremote

merge () {
 chkerr run dupemerge binary
}

logger_ () { logger "$*" ; echo "$*" ;}

now () { date +%Y%m%d_%H%M%S ;}

op=$1 # operation
case $op in
 local)
  [ -n "$3" ] || chkerr "$(usage)" # extra arg
  ORIG="$2" ; PREFIX="$3"/bk
 ;;
 push|pull)
  [ -n "$4" ] || chkerr "$(usage)" # extra arg
  HOST="$2" ; ORIG="$3" ; PREFIX="$4"/bk
 ;;
 rotate)
  [ -n "$3" ] || chkerr "$(usage)" # extra arg
  LEVEL="$2" ; PREFIX="$3"/bk ; [ -n "$4" ] && HOST="$4" \
   && { op=rotremote ;} \
   || { op=rotlocal ;}
 ;;
 purge)
  [ -n "$3" ] || chkerr "$(usage)" # extra arg
  LEVEL="$2" ; PREFIX="$3"/bk ; [ -n "$4" ] && HOST="$4" \
   && { op=purgremote ;} \
   || { op=purglocal ;}
 ;;
 merge)
  [ -n "$4" ] || chkerr "$(usage)" # extra arg
  [ -n "$2" ] || chkerr "$(usage)" # missing arg
  PREFIX="$2" ; [ -n "$3" ] && HOST="$3" \
   && op=mergeremote \
   || op=mergelocal
 ;;
 batch|conf)
  [ -n "$3" ] && chkerr $(usage) # extra arg
  while read include
   do # assign INCLUDE as last existing in list, and check exec
    [ -e "$include" ] && INCLUDE="$include"
   done <<EOF
/etc/backlinkrc
/usr/local/etc/backlinkrc
$HOME/.backlinkrc
$2
EOF
  [ -x "$INCLUDE" ] && true \
   || { [ -e "$INCLUDE" ] \
    && chkerr "$0 $1 : $INCLUDE is not exec" \
    || chkerr "$0 $1 : no include for exec" ;}
 ;;
 help)
  usage ; exit 0
 ;;
  *) chkerr "$(usage)"
 ;;
esac # $op

case $op in # set LAST
 local|pull|rotlocal) LAST="$(locallast)" 
  testlast
 ;;
 push|rotremote)      LAST="$(remotelast)"
  testlast
 ;;
esac # set LAST

NOW=$(now)

# Block may be used as a template for ~/.$0.rc
##################################################
# optimmized for Mac and NetBSD accounts
# rsync -a = -rlptgoD = --recursive --links --perms --times --group --owner --devices
#                -vCc = --verbose --cvs-exclude --checksum --numeric-ids
rsync_opt="--recursive --links --perms --times --group --owner --devices --specials --numeric-ids"
#
# additional rsync options for terminal (non-cron) backups
[ -t 0 ] && rsync_opt="$rsync_opt --verbose --progress" || true
#
# set typical global excludes
EXCLUDE=" tmp *.tmp *.core core .Trashes Library/Caches .Spotlight-V100"
EXCLUDE="$EXCLUDE 2nd/ bak-*/ bk/ dist/ repo/"
for ex in $EXCLUDE; do rsync_ex="$rsync_ex --exclude $ex" ; done
rsync_opt="$rsync_opt $rsync_ex"
#
HOSTNAME=$(hostname)
#
### Example local and push batch blocks
#
#backlink.sh push host /Users/$USER/tmp /usr/local/bak-${HOSTNAME%%.*}/Users-$USER-tmp
#backlink.sh push host /Users/$USER/    /usr/local/bak-${HOSTNAME%%.*}/Users-$USER
#
#EXCLUDE= 2nd/ bak-*/ bk/ dist/ repo/ access.log data/cache/ dnscache/log/main/ tinydns/log/main/ log/default/current log/error.start/current log/error/ supervise/
#ORIG= ~geo ~root /etc /usr/local /usr/local/www /usr/pkg/etc /var/backups /var/db/pkg
#
### batch local
##lock
##NOW=$(now)
##ORIG=$HOME
##PREFIX=/usr/local/bak-${HOSTNAME%%.*}-home-$USER
##LAST="$(locallast)" ; testlast
##localsnap
##logger_ "$0 $op : $PREFIX/1/$NOW$ORIG done at $(now)"
### perge
### merge
##unlock
##
### batch push
##lock
##NOW=$(now)
##HOST=host
##ORIG=$HOME
##PREFIX=/usr/local/bak-${HOSTNAME%%.*}-home-$USER
##LAST="$(locallast)" ; testlast
##pushsnap
##logger_ "$0 $op : $PREFIX/1/$NOW$ORIG done at $(now)"
### perge
### merge
##unlock
#
# Block end template for ~/.$0.rc
##################################################


case $op in
 local)
  lock
  logger_ $0 $op tested 20090106 10:15:09 PM 
  localsnap
  logger_ "$0 $op : $PREFIX/1/$NOW$ORIG done at $(now)"
  unlock
  exit 0
;;
  push)
  logger_ $0 $op tested 20090106 11:43:02 PM 
  lock
  pushsnap
  logger_ "$0 $op $HOST : $PREFIX/1/$NOW/$ORIG done at $(now)"
  unlock
  exit 0
;;
  pull)
  logger_ $0 $op tested 20090107 12:20:04 AM 
  lock
  pullsnap
  logger_ "$0 $op $HOST : $PREFIX/1/$NOW/$ORIG done at $(now)"
  unlock
  exit 0
;;
  rotlocal)
  logger_ $0 $op tested 20090107 12:30:51 AM 
  rotlocal
  logger_ "$0 rotate local : $LAST to $PREFIX/$LEVEL/ at $(now)"
  exit 0
;;
  rotremote)
  logger_ $0 $op tested 20090107 12:35:04 AM 
  rotremote
  logger_ "$0 rotate $HOST : $LAST to $PREFIX/$LEVEL/ at $(now)"
  exit 0
;;
  purgelocal)
  chkerr $0 $op is beta ready
  lock
  purgelocal
  logger_ "$0 purge local $LEVEL : from $NOW to $(now)"
  unlock
;;
  purgeremote)
  chkerr $0 $op is beta ready
  lock
  purgeremote
  logger_ "$0 purge $HOST $LEVEL : from $NOW to $(now)"
  unlock
;;
  mergeremote)
  chkerr $0 $op is pre alpha
  lock
  mergeremote
  logger_ "$0 merge $HOST $PREFIX : from $NOW to $(now)"
  unlock
;;
  mergelocal)
  chkerr $0 $op is pre alpha
  lock
  mergelocal
  logger_ "$0 merge $PREFIX : from $NOW to $(now)"
  unlock
;;
  batch)
  #logger_ $0 $op tested 20090107 03:26:26 PM 
  . $INCLUDE
  logger_ "$0 batch : $INCLUDE from $NOW to $(now)"
;;
  conf)
  echo $0 uses $INCLUDE
;;
esac

exit 0 # $0
