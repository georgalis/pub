#!/usr/bin/env bash

# feature next:
# [ -s [N] | --sort [N] ] --- sort on field N, the output column (1..6), default col 6, no-sort on no option

cksh () { # return sortable stat and hash data for args OR stdin file list
  # rev 68e9ff40 20251010 orig 6305e87b ckstat ckstatsum cks
  # (c) 2017-2025 George Georgalis <george@galis.org> unlimited use with this notice
  local f= fs= OS= n=2 x=3 ol= opt= OPTARG= OPTIND=
  while getopts ":012345n:x:h" opt; do case "$opt" in
    0|1|2|3|4|5) n="$opt" ;; n) n="$OPTARG" ;; x) x="$OPTARG" ;;
    :) case "$OPTARG" in n) n=0 ;; x) x=0 ;; esac ;;
    h) sed 's/^[ ]\{6\}//' <<eof
        Usage: $FUNCNAME [-NUM] [-n [NUM]] [-x [LEN]] [FILE...]
        Output: inode links shake256 size mdate filename
          -n [NUM]  Omit NUM leading fields: 0-5 (bare: 0, default: 2)
          -x [LEN]  XOF hash length: 0=skip, 1-64 (bare: 0, default: 3)
          --        End options; remaining args treated as filenames
          -h        Show help
        Reads filenames from arguments or stdin.
eof
       return 0 ;;
    ?) { chkerr "$FUNCNAME : invalid option '$OPTARG' (68e9fa9a)" ; return 1;}
    esac
  done
  shift $((OPTIND - 1))
  # Validate n and x input
  [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 0 ] && [ "$n" -le 5 ] \
    || { chkerr "$FUNCNAME : -n requires 0-5, got '$n' (68e9fbb2)" ; return 1; }
  [[ "$x" =~ ^[0-9]+$ ]] && [ "$x" -ge 0 ] && [ "$x" -le 64 ] \
    || { chkerr "$FUNCNAME : -x requires 0-64, got '$x' (68e9fc22)" ; return 1; }
  ((n>2)) && x=0 || true # don't calculate hash if field is omited
  ((x==0)) && { _hash () { echo . ;} ;} || { _hash () { openssl shake256 -xoflen "$x" -hex <"$f" 2>/dev/null ;} ; ol=$((x*2)) ;}
  # use the correct stat options per OS
  read OS < <(uname) ; [ "$OS" = "Linux" ] && _stat() { stat -c %i\ %h\ %s\ %Y "$1" ;} || true
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat() { stat -f %i\ %l\ %z\ %m "$1" ;} || true
  # define local _awk function according to 9 potential printf variations
  ((n==0)) && { ((x==0)) && _awk () { awk '{printf "%8x %2x . % 8x %08x ",$1,$2,$3,$4}' ;} \
             || _awk () { awk -v ol="$ol" '{printf "%8x %2x %0"ol"s % 8x %08x ",$1,$2,$5,$3,$4}' ;} ;} || true
  ((n==1)) && { ((x==0)) && _awk () { awk '{printf ". %2x . % 8x %08x ",$2,$3,$4}' ;} \
             || _awk () { awk -v ol="$ol" '{printf ". %2x %0"ol"s % 8x %08x ",$2,$5,$3,$4}' ;} ;} || true
  ((n==2)) && { ((x==0)) && _awk () { awk '{printf ". . . % 8x %08x ",$3,$4}' ;} \
             || _awk () { awk -v ol="$ol" '{printf ". . %0"ol"s % 8x %08x ",$5,$3,$4}' ;} ;} || true
  ((n==3)) && _awk () { awk '{printf ". . . % 8x %08x ",$3,$4}' ;} || true
  ((n==4)) && _awk () { awk '{printf ". . . . %08x ",$4}' ;} || true
  ((n==5)) && _awk () { awk '{printf ". . . . . "}' ;} || true
  while [ $# -gt 0 ]; do fs+="$1"$'\n' ; shift ; done ; fs="${fs%$'\n'}" ; [ -z "$fs" ] && read -d '' fs || true
  # generate _stat/_hash/ls composite, stream through _awk field extractor
  while IFS= read f; do _awk < <( tr '\n' ' ' < <( _stat "$f" ; awk '{print $2}' < <(_hash))) \
      && sed -e 's/[*%]$//' < <(ls -dF "$f") \
      || { chkerr "$FUNCNAME : internal error '$f'" ; return 1 ;}
    done <<<"$fs" # dir, sym, etc like regular files
    # sed to purge executable and "whiteout" file symbols from listing decoration
    # shake256 -xoflen 3 is okay for integrity check, and compatible with longer crypto reference (requires newer openssl)
    # extract filenames with spaces from output: awk '{print substr($0, index($0,$6))}'
  } # cksh

