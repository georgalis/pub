#!/usr/bin/env bash

#: sche_dius function iterator

#. itr system
#.. spawns run

#. env system
#.. exports env

#. run system
#.. exec unit

#. log system
#.. fg logtail

#. chk system
#.. process signal

set -e
exit 1

[ "$verb" ] || export verb="true # "
[ "$verb1" ] || export verb1="chkwrn"
[ "$verb2" ] || export verb2="echo --"

sche_itr () { # itr for run
  local v1 v2 v3 tmp
  [ "$1" ]    && export    v="$1" || local    v="0"
  [ "$sche" ] && export sche      || local sche=true
  shift 
  [ "$#" = 0 ] || sche=$sche $FUNCNAME $@
  $sche $v | &
#
#
  [ "$1" ] && v1="$1" || v1="0"
  [ "$2" ] && v2="$2" || v2="0"
  [ "$3" ] && v3="$3" || v3="0"
    sche_run1a $v1 & sche_run1b $v1 &
    sche_run2a $v2 & sche_run2b $v2 &
    sche_run5a $v3 & sche_run5b $v3 &
    sche_run
    fg;fg ; fg;fg ; fg;fg
    true ;}

sche_env () { # itr set env
  export v1=0.53
  export v2=2.53
  export v3=3.53
  true ;}

sche_run () { # job for itr, arg1 arg2 ..
  [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
  tmp="$tmp/sche_"
  mkdir -p "$tmp"
  local v1 v2 v3 tmp
  [ "$1" ] && v1="$1" || v1="0"
  [ "$2" ] && v2="$2" || v2="0"
  [ "$3" ] && v3="$3" || v3="0"
  echo v1="$1" v2="$2" v3="$3" >>"$tmp/run"
  while :; do
    # gendata-ipam-llama.sh $(( 60 * 60 * 1 )) # per 1 hour
    # gendata-conf-pull.sh $(( 60 * 60 * 3 ))  # per 8 hours
    echo $$           >>"$tmp/${v3}.v3_sche_"
    echo $$           >>"$tmp/${v2}.v2_sche_"
    printf "%s" "run" >>"$tmp/sche_" &
    sche_chk &
    sleep $v1 
    done
  true ;}

sche_log () { # foreground log monitor
  local tail tmp
  [ -d $HOME/Downloads ] && tmp="$HOME/Downloads/tmp" || tmp="$HOME/tmp"
  mkdir -p "$tmp"
  case "$(uname)" in
    Darwin) tail='tail -F' ;;
    Linux)  tail='tail --sche_=name' ;;
  esac
  touch "$tmp/sche_"
  $tail "$tmp/sche_"
  true ;}

sche_chk () { # unit signal management
  # synthetic gen/set/read/delete
  # log process
  # log rotated
  true ;}


sche_env
sche_ritr &
sche_log
