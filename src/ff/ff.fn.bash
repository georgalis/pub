#!/usr/bin/env bash
# ff.fn.bash --- ff, functional find, as a bash function
#
# Source this file. It defines one name, the function ff, for hosts
# without the ff binary. When a binary named ff is on PATH the function
# runs it; --fn keeps the function, as -V does, and --bin requires the
# binary. Requirements and decisions: plan-ff.md.
#
# Method: the ff grammar is translated into an argument array for the
# native find of the host (BSD or GNU dialect, probed per call), never
# evaluated as a string. Where the native find lacks a primary the
# function exits 2 and names the binary. Records that need more than the
# native find prints (-v, -k, terminal escaping, an emulated -S) are read
# back NUL-ended; for -v and -k each is keyed by stat(1). For -k the
# records are ordered by sort -z -s -t TAB in the C locale with one key
# per column, the named columns and then the rest, numbers by value and
# the name by byte, as the binary's cmp_rec.
#
# Everything after the hand-over runs in a subshell opened inside ff.
# The helper functions (_ff*), the usage and manual text and every
# variable are defined in that subshell and end with it: sourcing this
# file adds ff to the calling shell and nothing else, and a call changes
# no option, trap, variable or function there.
#
# The usage and manual blocks are copies of the binary's -h and --help
# text; test-ff.sh fails if they drift. To refresh them after the manual
# changes in ff.c, replace the two blocks with the output of "./ff -h"
# and "./ff --help".
#
# revision 6af927be 20261114 193214 PST Sat --- r0.7 key list -k5,4 with
#          the grammar of srt and cksh; -k joined, as the next word, or
#          last in a group; -kNr, x a no-op; named columns then the rest;
#          -Z NUL on every record; signed mdate; column 6 keyed as
#          printed; --help as a man page on a terminal, --man; --version,
#          --zero-terminated; hand-over to the binary, --fn and --bin, -V
#          keeps the function; one enclosing function
# revision 6ae4ea00 20261030 120328 PDT Fri --- r0.6 -r always ERE (-E
#          retired): BSD -E, GNU -regextype posix-extended, the pattern
#          grouped to unanchor it; --help through a pager on a terminal;
#          help blocks under unique quoted delimiters
# revision 6adcb748 20261024 064856 PDT Sat --- r0.5 -mode (was -k);
#          -k[r][N] sorts held records with sort -z -s -t TAB
# revision 6abc5da8 20260929 175400 PDT Tue --- r0.4 -0 true, -1 false, -Z
#          NUL, -y same node; -w sign apart; -x ./name through a fixed
#          /bin/sh where BSD -execdir passes a bare name; options set
#          before translation; a bad -r is a usage error; -delete refuses
#          an operand ending in .. or the root directory whole
# revision 6abb42b9 20260928 214649 PDT Mon --- r0.3 -w when, -i hex, -V,
#          examples; -w reference files without -newermt
# revision 6ab89f43 20260926 214451 PDT Sat --- r0.2 permission query,
#          -not, "not" diagnostics
# original 6ab7fec8 20260926 102008 PDT Sat --- r0.1 translator for BSD
#          and GNU find dialects, tty escaping, chkerr/chkwrn diagnostics,
#          subshell namespace; companion C binary ff.c
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
ff(){ local a= b= s= o= st= pw= p= want= both=0 V=0
  # --fn or --bin among the options chooses the form, and -V keeps the
  # function, the only form with a native command to show. Options may
  # stand anywhere but as the argument of a primary or a word of an -x or
  # -j command, so those are stepped over; -- ends the options. This pass
  # touches only its own locals: it matches with patterns, since [[ =~ ]]
  # would set BASH_REMATCH in the calling shell.
  for a in "$@" ; do
    case $st in
      arg) st= ; { [ "$pw" = -w ] && [[ $a == [+-] ]] && st=arg2 ;} || : ; continue ;;
      arg2) st= ; continue ;;
      exec) { [ "$a" = ';' ] || { [ "$a" = + ] && [ "$p" = '{}' ] ;} ;} && st= || : ; p=$a ; continue ;;
    esac
    case $a in
      --) break ;;
      --fn) [ "$want" != bin ] || both=1 ; want=fn ;;
      --bin) [ "$want" != fn ] || both=1 ; want=bin ;;
      -[nprtdsmacbwugliy]|-mode) st=arg pw=$a ;;
      -[xj]) st=exec p=$a ;;
      -?*) s=${a#-} ; o=${s%%[!IHLDSXZV]*} ; s=${s#"$o"}
        { [ -z "$s" ] || [[ $s == k* ]] ;} && [[ $o == *V* ]] && V=1 || : ;;
    esac
  done
  [ "$both" -eq 0 ] || {
    printf '>>> ff : --fn and --bin cannot be combined (6ab7ff55)\n' >&2 ; return 1 ;}
  [ "$V" -eq 0 ] || [ -n "$want" ] || want=fn
  # hand over to a binary on PATH, else do the work here
  # (command substitution here: a bash before 5.1 has no process substitution
  # in POSIX mode, and the hand-over must still work when ff was exported
  # to a script that such a bash runs as sh)
  [ "$want" = fn ] || b=$(type -P ff) || b=
  [ "$want" != bin ] || [ -n "$b" ] || {
    printf '>>> ff : --bin allows only the ff binary, and none is on PATH (6ab7ff56)\n' >&2
    return 2 ;}
  [ -z "$b" ] || { command "$b" "$@" ; return ;}
  # the translator itself needs process substitution; FF_NO_PROCSUB tests this
  { [ -z "${FF_NO_PROCSUB:-}" ] && { [[ :$SHELLOPTS: != *:posix:* ]] ||
    ((BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1))) ;} ;} || {
    printf '>>> ff : the function needs process substitution, which this bash lacks in POSIX mode (sh); use bash or the ff binary (6ab7ff57)\n' >&2
    return 2 ;}
  (
  # subshell body: helpers below stay out of the caller's namespace
  stderr () { [ "$*" ] && echo "$*" 1>&2 || true ;}                      #:> args to stderr, or noop if null
  chkwrn () { [ "$*" ] && { stderr    "^^^ $*" ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
  chkerr () { [ "$*" ] && { stderr    ">>> $*" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null

  _ffbad () { # usage error, as ff.c bad(): what, tag [, name]; caller returns 1
    local n=
    [ $# -gt 2 ] && { [ -t 2 ] && n=" '$(_ffesc "$3")'" || n=" '$3'" ;} || :
    chkerr "ff : $1$n ($2)" || :
    } # _ffbad

  _ff_tok () { # word that starts the expression
    [[ "$1" =~ ^(!|-not|\(|\)|-o|-delete|-mode|-[nprtdsmacbwuglixjezfvqy01])$ ]]
    } # _ff_tok

  _ff_ns () { # mtime of $1 as S.NNNNNNNNN by the symlink policy: GNU stat, then BSD stat
    local r=
    read -r r < <(stat ${H:+-L} ${L:+-L} -c %.9Y -- "$1" 2>/dev/null || stat ${H:+-L} ${L:+-L} -f %.9Fm -- "$1" 2>/dev/null) || :
    [[ "$r" =~ ^-?[0-9]+\.[0-9]{9}$ ]] && printf '%s' "$r"
    } # _ff_ns

  _ff_pred () { # the nanosecond before S.NNNNNNNNN
    local sec="${1%.*}" ns="${1#*.}"
    ns=$((10#$ns)) ; ((ns)) && printf '%s.%09d' "$sec" $((ns-1)) || printf '%s.999999999' $((sec-1))
    } # _ff_pred

  _ff_ref () { # rf: a reference file at instant S.NNNNNNNNN, for finds without -newermt @
    local sec="${1%.*}" ns="${1#*.}" iso=
    [ -n "$wd" ] || { wd=$(mktemp -d "${TMPDIR:-/tmp}/ff.XXXXXX") || return 1
      trap 'rm -f -- "$wd"/r[0-9]* ; rmdir -- "$wd"' EXIT ;}
    # GNU date -d @S first: BSD date has no -d, so it cannot be misread there
    read -r iso < <(date -u -d "@$sec" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -r "$sec" +%Y-%m-%dT%H:%M:%S 2>/dev/null) || :
    [[ "$iso" =~ ^-?[0-9]+-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || return 1
    nref=$((nref+1)) ; rf="$wd/r$nref"
    touch -d "$iso.${ns}Z" -- "$rf" 2>/dev/null
    } # _ff_ref

  _ff_when () { # -w [+-][ ]([.][.]/file|HEX) into native terms, as ff.c N_NEWER
    # $1 the word, or a lone sign with the word in $2; diagnostics then name $2
    local w="$1" ow="$1" sg= at= pr= up= lo=
    sg="${w:0:1}" ; [[ "$sg" == [+-] ]] && w="${w:1}" || sg=
    [ -n "$sg" ] && [ -z "$w" ] && { w="$2" ; ow="$2" ;} || :
    [[ "$w" == [+-]* ]] && { _ffbad "-w: file is [.][.]/file, time is HEX, not" 6ab7ff4b "$ow" ; return 1 ;} || :
    if [[ "$w" == /* || "$w" == ./* || "$w" == ../* ]]; then
      { [ -n "$H$L" ] && [ -e "$w" ] ;} || { [ -z "$H$L" ] && { [ -e "$w" ] || [ -L "$w" ] ;} ;} \
        || { _ffbad "-w: cannot stat" 6ab7ff10 "$w" ; return 1 ;}
      [ "$sg" = + ] && { ex+=(-newer "$w") ; return 0 ;} || :
      at=$(_ff_ns "$w") && [ -n "$at" ] || { chkerr "ff : -w needs a stat with nanoseconds, use ff.c '$w' (6ab7ff4a)" ; return 2 ;}
      pr=$(_ff_pred "$at") ; up="$w"
    elif [[ "$w" =~ ^[0-9a-fA-F]{1,16}$ ]]; then
      ((${#w}==16)) && [[ "$w" == [89a-fA-F]* ]] && { _ffbad "time overflows" 6ab7ff0f "$ow" ; return 1 ;} || :
      # whole seconds: +T after second T, -T before it, T within it
      at="$((16#$w)).999999999" ; pr="$((16#$w - 1)).999999999"
    else
      _ffbad "-w: file is [.][.]/file, time is HEX, not" 6ab7ff4b "$ow" ; return 1
    fi
    # -newermt @S.N where the native find takes it (GNU); else reference files and -newer
    [ -z "$FF_NO_NEWERMT" ] && command find /dev/null -maxdepth 0 -newermt @0 >/dev/null 2>&1 && {
      case "$sg" in
        +) ex+=(-newermt "@$at") ;;
        -) ex+=(! -newermt "@$pr") ;;
        *) ex+=('(' -newermt "@$pr" ! -newermt "@$at" ')') ;;
      esac ; return 0 ;}
    case "$sg" in
      +) _ff_ref "$at" && ex+=(-newer "$rf") ;;
      -) _ff_ref "$pr" && ex+=(! -newer "$rf") ;;
      *) _ff_ref "$pr" && lo="$rf" && { [ -n "$up" ] || { _ff_ref "$at" && up="$rf" ;} ;} \
           && ex+=('(' -newer "$lo" ! -newer "$up" ')') ;;
    esac || { chkerr "ff : -w needs -newermt or touch -d and date, use ff.c (6ab7ff4a)" ; return 2 ;}
    } # _ff_when

  _ff_keys () { # -k list: col[r|x...][,col...] onto kc and kv, as ff.c parse_keys
    local a="$1" s="$1" col= it= t= rv= j=
    [[ "$s" != r* ]] || { _ffbad "-krN is not accepted, write -kNr; got -k" 6ab7ff4f "$a" ; exit 1 ;}
    while : ; do
      [[ "$s" != -* ]] || { _ffbad "-k counts columns 1-6 from the left only, got" 6ab7ff50 "$a" ; exit 1 ;}
      [[ "$s" =~ ^[1-6]([^0-9]|$) ]] || { _ffbad "-k requires columns 1-6, got" 6ab7ff4c "$a" ; exit 1 ;}
      col="${s:0:1}" ; s="${s:1}" ; it="${s%%,*}" ; t="$it" ; rv=
      while [ -n "$t" ]; do
        case "${t:0:1}" in
          r) rv=r ;;
          x) [[ "$col" != [36] ]] || { _ffbad "-k letter x is for the numeric columns 1 2 4 5; columns 3 and 6 are text, got" 6ab7ff51 "$a" ; exit 1 ;} ;;
          *) _ffbad "-k accepts the letters r and x only: column types are fixed, got" 6ab7ff52 "$a" ; exit 1 ;;
        esac
        t="${t:1}"
      done
      for j in ${kc[@]+"${kc[@]}"}; do
        [ "$j" != "$col" ] || { _ffbad "-k names a column twice, got" 6ab7ff53 "$a" ; exit 1 ;}
      done
      kc+=("$col") ; kv+=("$rv") ; s="${s:${#it}}"
      [ -n "$s" ] || return 0
      s="${s:1}"
      [ -n "$s" ] || { _ffbad "-k requires columns 1-6, got" 6ab7ff4c "$a" ; exit 1 ;}
    done
    } # _ff_keys

  _ff_optw () { # is $2 an option word, -[IHLDSXZV]*[k[list]]? $3 is the next word:
    # REPLY=1 when a bare -k takes it as its list, which it does only when
    # the word reads as one (ff.c reads_as_list). $1: 1 sets the letters
    # (first pass), 2 parses the -k list (second pass, in argument order)
    local s="${2#-}" o= r= i=
    REPLY=0
    [[ "$2" == -?* ]] || return 1
    o="${s%%[!IHLDSXZV]*}" ; r="${s#"$o"}"
    [ -z "$r" ] || [[ "$r" == k* ]] || return 1
    [ "$1" = 1 ] && for ((i=0; i<${#o}; i++)); do case "${o:i:1}" in
      I) I=1 ;; H) H=1 L= ;; L) L=1 H= ;; D) D=1 ;; S) S=1 ;; X) X=1 ;; Z) Z=1 ;; V) V=1 ;;
    esac ; done || :
    [ -n "$r" ] || return 0
    r="${r#k}"
    [ -z "$r" ] && [[ "$3" =~ $kre ]] && { r="$3" ; REPLY=1 ;} || :
    [ "$1" = 2 ] && { sk=1 ; [ -z "$r" ] || _ff_keys "$r" ;} || :
    return 0
    } # _ff_optw

  _ff_opts () { # options are global, as ff.c's pre-pass: set before translating any
    # primary; primary arguments and exec words are skipped, -- ends options
    # until the expression starts
    local a= e= x= p=
    while (($#)); do
      a="$1" ; shift
      [ -z "$e" ] && _ff_optw 1 "$a" "${1-}" && { ((REPLY)) && shift || : ; continue ;} || :
      [ -z "$e" ] && [ "$a" = "--zero-terminated" ] && { Z=1 ; continue ;} || :
      [ -z "$e$x" ] && [ "$a" = "--" ] && { e=1 ; continue ;} || :
      _ff_tok "$a" && x=1 || continue
      [[ "$a" =~ ^-[nprtdsmacbwugliy]$|^-mode$ ]] && (($#)) && {
        [ "$a" = -w ] && [[ "$1" == [+-] ]] && (($# > 1)) && shift || :
        shift ; continue ;} || :
      [[ "$a" =~ ^-[xj]$ ]] && { p="$a"
        while (($#)); do
          [ "$1" = ";" ] && break || : ; [ "$1" = "+" ] && [ "$p" = "{}" ] && break || :
          p="$1" ; shift
        done
        (($#)) && shift || : ;} || :
    done
    } # _ff_opts

  _ff_show () { # -V: the native command on stderr, quoted to paste back into a shell
    [ -n "$V" ] || return 0
    local q= w= ; for w in "$@"; do printf -v w '%q' "$w" ; q+="${q:+ }$w" ; done
    stderr "$q"
    [ -z "$wd" ] || stderr "# reference files under $wd are removed after the run"
    } # _ff_show

  _ff_perm () { # -mode into native -perm terms, as ff.c parse_perm and p_perm
    # octal: exact, +superset, -subset; symbolic: [ugoa]*[+-]?[rwxXst]+ clauses, + has, - lacks
    local v="$1" w= p= sg= cl= c= b= i= X= all= first=
    local -a cls=() cb=() t=() R=(0400 040 04) W=(0200 020 02) E=(0100 010 01) S=(04000 02000 0) T=(0 0 01000) L=(u g o)
    _ff_none () { # none of the bits in $1: one ! -perm -BIT per bit, the same on every dialect
      local k= ; for ((k=1; k<=04000; k<<=1)); do (($1 & k)) && t+=(! -perm "-$(printf %o "$k")") || : ; done ;}
    [[ "$v" =~ ^([-+]?)([0-7]{1,4})$ ]] && {
      b=$((8#${BASH_REMATCH[2]}))
      case "${BASH_REMATCH[1]}" in
        +) t=(-perm "-$(printf %o "$b")") ;;
        -) _ff_none $((07777 & ~b)) ;;
        *) t=(-perm "$(printf %o "$b")") ;;
      esac
      ((${#t[@]})) || t=('(' -type d -o ! -type d ')')   # -7777: every mode
      ex+=('(' "${t[@]}" ')') ; return 0 ;}
    [[ "$v" =~ ^[ugoa]*[-+]?[rwxXst]+(,[ugoa]*[-+]?[rwxXst]+)*$ ]] \
      || { _ffbad "-mode: bad mode" 6ab7ff11 "$v" ; return 1 ;}
    IFS=, read -ra cls <<<"$v"
    ex+=('(')
    for cl in "${cls[@]}"; do
      w="${cl%%[-+rwxXst]*}" ; p="${cl#"$w"}" ; sg=+
      [[ "$p" =~ ^[-+] ]] && { sg="${p:0:1}" ; p="${p:1}" ;} || :
      cb=(0 0 0) ; X= ; t=()
      for ((i=0; i<${#p}; i++)); do for c in 0 1 2; do
        [ -n "$w" ] && [[ "$w" != *a* ]] && [[ "$w" != *"${L[c]}"* ]] && continue || :
        case "${p:i:1}" in r) b=${R[c]} ;; w) b=${W[c]} ;; x|X) b=${E[c]} ;; s) b=${S[c]} ;; t) b=${T[c]} ;; esac
        [[ "${p:i:1}" == [st] ]] && ((b==0)) && [ -n "$w" ] && [[ "$w" != *a* ]] \
          && { _ffbad "-mode: s is for u or g, t is for o, not" 6ab7ff46 "$v" ; return 1 ;} || :
        cb[c]=$((cb[c] | b)) ; [ "${p:i:1}" = X ] && X=1 || :
      done ; done
      all=$((cb[0] | cb[1] | cb[2]))
      [ -n "$X" ] && t+=(-type d) || :
      if [ "$sg" = - ]; then _ff_none $all
      elif [ -n "$w" ]; then t+=(-perm "-$(printf %o "$all")")
      else # no class: some participating class has all of its bits
        t+=('(') ; first=1
        for c in 0 1 2; do ((cb[c])) && { [ -z "$first" ] && t+=(-o) || : ; t+=(-perm "-$(printf %o "${cb[c]}")") ; first= ;} || : ; done
        t+=(')')
      fi
      ex+=("${t[@]}")
    done
    ex+=(')')
    } # _ff_perm

  _ff_rec () { # one record from the native find: -v line, NUL, escaped, or raw;
    # under -k held in kr, keyed by its stat as cksh fields, for _ff_put after the walk
    # the node is the one the walk tested: under -L the file a link leads to,
    # under -H that only for a path operand; a link that leads nowhere is itself
    local LC_ALL=C a= b= c= t= s= fmt= fl=
    [ -n "$ls$sk" ] && {
      [ -n "$L" ] && fl=-L || { [ -n "$H" ] && for b in "${paths[@]}"; do [ "$b" = "$1" ] && { fl=-L ; break ;} || : ; done || : ;}
      [ "$(uname)" = Linux ] && fmt=(-c '%i %h %s %Y %F') || fmt=(-f '%i %l %z %m %HT')
      read -r a b c t s < <(stat $fl "${fmt[@]}" -- "$1" 2>/dev/null || stat "${fmt[@]}" -- "$1" 2>/dev/null) || :
      [[ "$a $b $c $t" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ -?[0-9]+$ ]] || { chkerr "ff : cannot stat '$1' (6ab7ff32)" ; rc=$((rc|4)) ; return 0 ;}
      case "${s,,}" in directory) s=/ ;; symbolic*) s=@ ;; fifo*) s='|' ;; socket) s='=' ;; *) s= ;; esac
      # field 3 carries the -v indicator, . for none; field 6 is column 6 as
      # printed, the name and on a -v line its indicator, so it is the sort key
      [ -n "$sk" ] && { kr+=("$a"$'\t'"$b"$'\t'"${s:-.}"$'\t'"$c"$'\t'"$t"$'\t'"$1${ls:+$s}") ; return 0 ;}
      _ff_put "$a" "$b" "$s" "$c" "$t" "$1" ; return 0 ;}
    _ff_put "" "" "" "" "" "$1"
    } # _ff_rec

  _ff_put () { # print one record: inode links indicator size mdate name; every
    # record ends in newline, or under -Z in NUL with the name raw; a
    # negative mdate is signed hex, as cksh writes it
    local LC_ALL=C m=
    [ -n "$ls" ] && { (($5<0)) && printf -v m -- '-%07x' $((-$5)) || printf -v m '%08x' "$5"
      printf '%8x %2x . %8x %s ' "$1" "$2" "$4" "$m"
      { [ -t 1 ] && [ -z "$Z" ] ;} && _ffesc "$6" || printf '%s' "$6"
      [ -n "$Z" ] && printf '%s\0' "$3" || printf '%s\n' "$3" ; return 0 ;}
    [ -n "$Z" ] && { printf '%s\0' "$6" ; return 0 ;}
    [ -t 1 ] && { _ffesc "$6" ; printf '\n' ;} || printf '%s\n' "$6"
    } # _ff_put

  _ff_ksort () { # -k: held records by the named columns, then the rest left to
    # right, then walk order (-s), as ff.c resolve and cmp_rec. Column 3 is a
    # null column and takes no key; r rides on its own key, since a key
    # with modifiers takes no global -r
    local LC_ALL=C f= i= j= ; local -a ks=() v=() od=() rv=() seen=(0 0 0 0 0 0 0)
    for ((i=0; i<${#kc[@]}; i++)); do od+=("${kc[i]}") ; rv+=("${kv[i]}") ; seen[kc[i]]=1 ; done
    ((${#kc[@]})) || { od+=(6) ; rv+=("") ; seen[6]=1 ;}
    for j in 1 2 3 4 5 6; do ((seen[j])) || { od+=("$j") ; rv+=("") ;} ; done
    for ((i=0; i<6; i++)); do case "${od[i]}" in
      3) ;;
      6) ks+=("-k6${rv[i]}") ;;
      *) ks+=("-k${od[i]},${od[i]}n${rv[i]}") ;;
    esac ; done
    ((${#kr[@]})) || return 0
    while IFS= read -r -d '' f; do
      v=() ; for i in 1 2 3 4 5; do v+=("${f%%$'\t'*}") ; f="${f#*$'\t'}" ; done
      [ "${v[2]}" = . ] && v[2]= || :
      [ -n "$ls" ] && f="${f%"${v[2]}"}" || :
      _ff_put "${v[@]}" "$f"
    done < <(printf '%s\0' "${kr[@]}" | LC_ALL=C sort -z -s -t $'\t' "${ks[@]}")
    } # _ff_ksort

  _ff_sorted () { # GNU find has no -s: sort each path with / as the lowest byte
    # pre-order: a < a/b < a.c.  post-order (-D) adds a \002 terminator: a/b < a < a.c
    local LC_ALL=C d="$1" f= ; shift
    local -a r=()
    while IFS= read -r -d '' f; do
      # a name holding byte \001 sorts wrongly here
      f="${f//\//$'\001'}" ; r+=("$f${d:+$'\002'}")
    done < <("$@")
    wait $! || return 1
    ((${#r[@]})) || return 0
    while IFS= read -r -d '' f; do
      f="${f%$'\002'}" ; _ff_rec "${f//$'\001'//}"
    done < <(printf '%s\0' "${r[@]}" | LC_ALL=C sort -z)
    } # _ff_sorted

  _ffesc () { # name for a terminal: C0, C1, DEL and invalid UTF-8 as \ooo, as ff.c u8len
    local LC_ALL=C s="$1" o= c= i=0 j= n= b= x= cp=
    while ((i<${#s})); do
      c="${s:i:1}" ; printf -v b '%d' "'$c"
      n=0 ; ((b>=32 && b<127)) && n=1 || {
        ((b>=0xc2 && b<=0xf4)) && {
          ((b<0xe0)) && n=2 || { ((b<0xf0)) && n=3 || n=4 ;}
          cp=$(( b & (0x3f >> (n-1)) ))
          for ((j=1; j<n; j++)); do
            ((i+j<${#s})) || { n=0 ; break ;}
            printf -v x '%d' "'${s:i+j:1}"
            (((x & 0xc0) == 0x80)) || { n=0 ; break ;}
            cp=$(( cp << 6 | (x & 0x3f) ))
          done
          ((n)) && { ((n==3 && cp<0x800)) || ((n==4 && cp<0x10000)) || ((cp>0x10ffff)) \
            || ((cp>=0xd800 && cp<=0xdfff)) || ((cp>=0x80 && cp<=0x9f)) ;} && n=0 || :
        } || : ;}
      ((n)) && { o+="${s:i:n}" ; i=$((i+n)) ;} || { printf -v x '\\%03o' "$b" ; o+="$x" ; i=$((i+1)) ;}
    done
    printf '%s' "$o"
    } # _ffesc

  _ff_usage () { # ff -h, identical to ff.c usage_text
    local u= ; { IFS= read -r -d '' u || : ;} <<'__FF_USAGE__'
Usage: ff [-IHLDSXZV] [-k [col[r][,col[r]]...]] [--] [path ...] [expression]
       ff -h | --help | --man | --version   (--fn | --bin: --help)
  options  -I ignore case for -n -p -r  -H/-L follow symlinks
           -D post-order  -S sorted  -X one filesystem  -Z NUL records
           -V show the native find command (ff.fn.bash)
  sort     -k5,4 by column 5, then 4, then the remaining columns in
           order; columns as -v writes them: 1 inode 2 links 3 .
           4 size 5 mdate 6 name; no -v needed.  -k alone: by name
           -k5r  r reverses that column
  tests    -n glob  -p glob  -r ERE  -t fdlpsbc  -d [+-]N  -s [+-]N[ckMGT]
           -m -a -c -b [+-]N[smhdw]  -w [+-][ ]([.][.]/file|HEX)
           -u user  -g group  -l [+-]N  -i [+-]HEX  -y file (same node)  -e
           -mode [+-]bits  -z (prune)  -0 (true)  -1 (false)
  actions  -f print  -v cksh line  -x cmd {} ;|+  (in entry's dir)
           -j cmd {} ;|+  (full path)  -delete  -q quit
  logic    ( )  ! or -not  juxtaposition = and  -o or
  -h this summary, --help the manual
__FF_USAGE__
    printf '%s' "$u"
    } # _ff_usage

  _ff_roff () { # the manual as man page source, the rule of ff.c roff()
    local l= n=0 s=0 b=0 re='^[A-Z][A-Z ]*$' m=
    m=$(_ff_manual)
    printf '.TH FF 1\n'
    while IFS= read -r l ; do
      [[ ! $l =~ $re ]] || { b=0 ; ((n==0)) || printf '.fi\n' ; n=1
        printf '.SH "%s"\n.nf\n' "$l" ; s=1 ; continue ;}
      ((s==0)) || { s=0 ; [ -n "$l" ] || continue ;}
      [ -n "$l" ] || { b=$((b+1)) ; continue ;}
      [[ $l != '  '[!\ ]* ]] || { b=0 ; printf '.SS "%s"\n.nf\n' "${l:2}" ; s=1 ; continue ;}
      for ((;b>0;b--)) ; do printf '\n' ; done
      l=${l//\\/\\e} ; [[ $l != [.\']* ]] || l="\\&$l"
      printf '%s\n' "$l"
    done <<<"$m"
    printf '.fi\n'
    } # _ff_roff

  _ff_help () { # --help: on a terminal the man page source through the formatter
    # of the host (mandoc, else nroff and a pager), else the text through a
    # pager; plain otherwise. Never through man(1): see ff.c put_help
    local pg= s=0 src=
    [ -t 1 ] || { _ff_manual ; return 0 ;}
    src=$(_ff_roff)
    for pg in 'command -v mandoc >/dev/null 2>&1 || exit 127; exec mandoc -a 2>/dev/null' \
        'command -v nroff >/dev/null 2>&1 || exit 127; nroff -c -man </dev/null >/dev/null 2>&1 || exit 127; p=${PAGER:-}; [ -n "$p" ] || { command -v less >/dev/null 2>&1 && p=less || p=more; }; nroff -c -man 2>/dev/null | sh -c "$p"' ; do
      printf '%s\n' "$src" 2>/dev/null | /bin/sh -c "$pg" ; s=${PIPESTATUS[1]}
      ((s)) || return 0
    done
    for pg in "${PAGER:-}" less more ; do
      [ -n "$pg" ] || continue
      _ff_manual 2>/dev/null | /bin/sh -c "$pg" ; s=${PIPESTATUS[1]}
      ((s==126 || s==127)) || return 0
    done
    _ff_manual
    } # _ff_help

  _ff_manual () { # ff --help, identical to ff.c manual
    local m= ; { IFS= read -r -d '' m || : ;} <<'__FF_MANUAL__'
NAME

    ff - functional find: walk file trees, one letter per switch

SYNOPSIS

    ff [-IHLDSXZV] [-k [col[r][,col[r]]...]] [--] [path ...] [expression]
    ff -h | --help | --man | --version
    ff --fn ... | ff --bin ...

DESCRIPTION

    ff walks each path (default .) and evaluates the expression for every
    node, as find(1) does, with one letter per switch. Options are
    uppercase, and -k, and global; they may appear anywhere except as
    the argument of a primary. Primaries are lowercase, the digits 0 and
    1, or -mode and -delete. With no action in the expression, each node
    for which it is true is printed.

    Printed paths are the operand, then / and each name below it. Output
    is raw bytes when stdout is not a terminal or -Z is given. On a
    terminal, C0 and C1 control characters, DEL and bytes that are not
    valid UTF-8 print as \ooo octal escapes, so a crafted name cannot
    drive the terminal; names in diagnostics follow the same rule.

    Directories are opened relative to their verified parent descriptor,
    never by re-resolving a path; a directory swapped for another node
    between listing and opening is reported and skipped.

OPTIONS

    -I     case-insensitive -n, -p and -r
    -H     follow symlinks named as path operands
    -L     follow all symlinks; loops are reported, not followed
    -D     post-order: a directory is tested after its contents
    -S     sorted walk: each directory's names in bytewise order
    -X     do not descend into directories on other filesystems
    -Z, --zero-terminated
           end every record with NUL, not newline: the names from -f
           and the default print, and the lines of -v. Names are then
           written as they are, even to a terminal. It is the -Z of
           cksh and of srt.
    -k [col[r][,col[r]]...]
           sort what ff prints, by the columns of the -v line. See
           KEYS.
    --     end of options: following words are paths, even with a
           leading -, until a primary or operator
    -V     ff.fn.bash only: print the native find command to stderr
           before running it; helpful to extend a command to an OS find
           specific implementation. The binary notes this and runs.
           Given to the function, -V keeps the function, as --fn does.
    -h     short usage
    --help this manual. When standard output is a terminal it is shown
           as a man page, with its headings in bold, through the
           formatter of the host: mandoc, else nroff with a pager
           (PAGER, else less, else more). Where neither is found the
           text is shown through the pager alone. To a pipe or a file
           it is written plain.
    --man  the manual as man page source; ff.1 is this output
    --version
           print the revision
    --fn, --bin
           choose between the two forms of ff, the binary and the bash
           function. --fn allows only the function: it then never hands
           over to a binary, and the binary, given --fn, stops with an
           error. --bin allows only the binary: the function hands over
           to the binary on PATH and stops with an error if there is
           none; the binary accepts --bin and does nothing. See BASH
           FUNCTION.

    The list of -k may be joined to it (-k5,4) or be the next word
    (-k 5,4). The next word is taken as the list only when it reads as
    one, a column number first; any other word leaves -k alone, which
    sorts by name, so
        ff -k .        ff -k src -t f        ff . -t f -k
    sort by name. For a path named like a list, write ./5. A word that
    begins with - is never the list: in -k -1 the -1 is the primary.
    -k may end a group of options, -Sk5 or -Zk.

    Retired: -krN (write -kNr).

KEYS

    The columns are those of the -v line, counted as words, as $1, $2
    ... are in awk:

           inode lk hash     size    mdate name
          1cc01d  1 .           3 5e0bd2c0 t/a
          1cc01c  2 .        1000 5e0bd2c0 t/d/
          1cc01f  1 .           1 5e0bd2c0 t/l@

    The heading is shown for reference; ff does not write it.

      1 inode  inode number
      2 lk     hard link count
      3 hash   a dot: ff reads no file. cksh writes its hash here,
               shake256-N of the content, shake256-6 unless told
               otherwise; ff keeps the column so that the two agree
               on where each of the others is
      4 size   size in bytes
      5 mdate  modification time in seconds since the epoch; a time
               before 1970 is written with a minus sign, -12cf8700
      6 name   the path, and on a -v line an indicator in the manner
               of ls -F: / directory  @ symlink  | fifo  = socket

    Numbers are lowercase hexadecimal. Widths are not significant: a
    value wider than its column moves the rest of that line and
    nothing else. The name begins at column 6 and runs to the end of
    the record, blanks included:
        awk '{print substr($0, index($0,$6))}'

    -k [col[r][,col[r]]...]
        Sort by the named columns in the order given, then by the
        remaining columns left to right. -k5,4 compares in column
        order 5,4,1,2,3,6. -k5 -k4 is the same as -k5,4. Naming a
        column twice is an error. Columns are 1 to 6; counting from
        the end (-k-1) is not accepted.

        -k with no list names no column, and sorts by name: column
        6, then 1 to 5.

        The columns need not be printed. Every record, from -f, -v
        or the default print, is keyed by the stat of its node, so
        ff -k5 orders bare names by time, as ls -t orders names
        without -l. -v is needed only to see the columns.

        ff knows the type of each column. Inode, links, size and
        mdate compare as numbers, by value, whatever their width.
        The name compares as bytes, as it is printed, to the end of
        the record, and no locale is consulted. Column 3 is a dot in
        every record, a null column: it compares equal, so a key on
        it orders nothing and the next column decides.

        Records equal in every column keep the order of the walk.

        Records are held until the walk ends. What -x and -j
        commands write is not sorted, and after -q the records
        printed so far are.

    Letters. r after a column reverses that column. x is accepted
    on columns 1, 2, 4 and 5 and changes nothing: it is the letter
    srt needs there, so a list written for srt can be given to ff.
    Any other letter is refused, since the types are fixed. No
    option reverses every column, -r being a primary: write r on
    each column to be reversed.
        ff -k5r          newest first; within one second, ascending
        ff -k5r,4r,6r    newest first, then largest, then name down

    The same order from srt. ff -k5,4,6 . -v writes what
        ff . -v | srt -k5x,4x,6,1x,2x,3
    writes: every column named, each numeric column marked x, the
    dot and the name as text. In general, give srt the ff list, then
    the remaining columns, with x on 1, 2, 4 and 5.

PRIMARIES

    N           decimal: +N more than N, -N less than N, N exactly.
    HEX         hexadecimal without 0x, as ff -v prints it.
    -n glob     last component of the examined pathname matches glob
    -p glob     examined pathname matches glob
                The special shell pattern characters [ ] * and ? may be
                used, and \ makes the next one literal. A leading . is
                not special, and in -p * and ? also match /. Quote the
                pattern so the shell does not expand it first.
    -r ere      path contains a match for the extended regular expression
                ere; unanchored, add ^ and $. See REGULAR EXPRESSIONS.
    -t types    type is any of: f file, d directory, l symlink, p fifo,
                s socket, b block, c character device; -t fl is f or l
    -d N        walk bound, global wherever it appears; operands are
                depth 0.  -d -2: operands and their entries;
                -d +0: everything below the operands; -d 1: entries only
    -s N[ckMGT] size in bytes compared exactly; k M G T are 1024-based
    -m N[smhdw] modified: age in seconds against N units, default d.
                -m -2h under 2 hours; -m +7 over 7 days; -m 7 from 7 up
                to 8 days
    -a -c -b    the same for access, status change and birth time;
                -b is false where the filesystem records no birth time
    -w [+-][ ]([.][.]/file|HEX)
                when: modified after (+), before (-) or at the same time
                as file's mtime, or as HEX epoch seconds (the -v mdate).
                A file begins with ./ ../ or /, so no word is both a file
                and a time. A file compares the full timestamp, HEX
                whole seconds. The sign may stand apart as its own word:
                -w + ./file is -w +./file. find -newer file is -w +./file.
    -y file     the same node as file: same device and inode
    -mode bits  permission bits. Octal, all twelve bits:
                  0755     exactly 0755
                  +0755    at least 0755: every bit of it, maybe more
                  -0755    at most 0755: no bit outside it, maybe fewer
                Symbolic, clauses [ugoa][+-][rwxXst] joined by commas,
                all of which must hold. + has, - lacks; a clause with
                no sign means +. u owner, g group, o other, a all
                three; each named class must satisfy the clause. With
                no class, + holds when some class has the bits and -
                when no class has any of them.
                X is x that only a directory satisfies (search); a
                clause with X is false for anything else. s is setuid
                with u, setgid with g, either with no class, both with
                a; t is the sticky (/tmp) bit, alone or with o.
                With no class, each class is tested with only the bits
                it can hold, so -mode +rs holds when other has r,
                since other has no s; name the class to need both:
                -mode u+rs.
                  -mode u+x        owner may execute
                  -mode x          someone may execute (same as +x)
                  -mode -x         no one may execute
                  -mode o-X        directories others may not search
                  -mode o-r        others may not read
                  -mode w          someone may write
                  -mode o+w        world writable
                  -mode go-w       neither group nor other may write
                  -not -mode go-w  group or other may write
                  -mode u+s        setuid
                  -mode g+s        setgid
                  -mode +s         setuid or setgid
                  -mode +t         sticky
                Either of two bits in one class: -mode u+r -o -mode u+x
    -u user     owner, name or number;  -g group  group, name or number
    -l [+-]N    link count
    -i [+-]HEX  inode number, hex as ff -v prints it
    -e          empty regular file or directory
    -z          prune: do not descend into this directory; true
    -0          always true;  -1  always false

ACTIONS

    -f          print the path; explicit form for use with -o
    -v          print a cksh line: inode links . size mdate name, hex,
                the same as cksh -n0 -x0 on that name; see KEYS
    -x cmd ... ;       run cmd inside the directory holding the node, {}
                       as ./name; true when cmd exits 0
    -x cmd ... {} +    the same, many names per run, per directory
    -j cmd ... ;       run cmd from the current directory, {} as the path
    -j cmd ... {} +    the same, many paths per run
    -delete     remove the node; implies -D; refused with -L. An operand
                ending in .., or that is the root directory (/, /., or .
                run from /), is refused whole and not walked (4); an
                operand . is walked and kept itself, as find does
    -q          stop the walk; pending + batches still run

OPERATORS

    expr expr       and: the right side is evaluated only when the
                    left is true
    expr -o expr    or: the right side is evaluated only when the left
                    is false, so its actions see only nodes the left
                    rejected
    ! expr          not; -not expr is the same
    ( expr )        grouping
    -not binds tightest, then and, then -o.
    The shell treats ( ) ; * and sometimes ! as its own syntax, so
    escape them with a backslash or quote them: \( \) \; '*.c'.
      ff . -n '*.c' -o -n '*.h' -t f          .c of any type, or .h files
      ff . \( -n '*.c' -o -n '*.h' \) -t f    .c and .h files only
      ff . -mode u+r -o -mode u+x             owner may read or execute
    With no action in the expression, a node is printed when the whole
    expression is true. Once any action appears (-f -v -x -j -delete
    -q), only actions print. Prune directories by name and print the
    files that are not RCS (,v) or backup (~) files:
      ff . \( -n .git -o -n tmp \) -z -t f -o -t f -not -r ',v$|~$'
    -z is true, so the -t f after it makes that side false for the
    pruned directories; -z -1 does the same. Options such as -I
    may appear anywhere, even after -not.

REGULAR EXPRESSIONS

    -r takes a POSIX extended regular expression (ERE), the dialect of
    grep -E and find -E, compiled by the C library's regcomp(3) and
    matched anywhere in the path; anchor it with ^ and $. -I ignores case.
      c            a character not listed below matches itself
      .            any one character, / included: d.e matches d/e
      [abc]        one of a b c; [a-z] a range; [^abc] none of them;
                   ] first and - last are literal, and \ is literal inside
      [[:digit:]]  a class, inside brackets: alpha digit alnum upper lower
                   space punct xdigit; [[:digit:]_] adds _
      ^  $         start and end of the path
      x*  x+  x?   zero or more, one or more, zero or one of x
      x{n}         n of x;  x{n,}  n or more;  x{n,m}  n to m
      (re)         group, for a repeat or an alternation
      re|re        either side; lowest precedence: ^a|b$ is (^a)|(b$)
      \c           c itself, for c any of . [ ( ) { * + ? | ^ $ \
                   (] and } alone are already literal)
    \ before any other character is undefined in ERE: \d \w \s are not
    portable, so write [[:digit:]] [[:alnum:]_] [[:space:]].
    Differences from basic regular expressions (BRE: find -regex, grep,
    sed), read as ERE here:
      ERE          BRE          meaning in ERE
      (re)         \(re\)       group
      x{n,m}       x\{n,m\}     interval
      + ? |        none         one or more, zero or one, alternation
      \( \) \{     ( ) {        the characters themselves
      \1           \1           back-reference: defined for BRE only; in
                                ERE a C library extension that varies by
                                platform, refused by ff.fn.bash (2)
    Glob, for -n and -p, is a different language: glob * and ? are .*
    and . here, and a glob must match the whole name, not a part of it.
      ff . -r '\.(c|h)$'                   C sources and headers
      ff . -r '/[0-9]{4}-[0-9]{2}-[^/]*$'  names that begin YYYY-MM-
      ff -I . -r '/readme(\.md)?$'         readme, README.md, any case

EXEC

    Commands run by fork and exec, never through a shell. {} is replaced
    only when it is a whole argument. With +, {} must be last and appear
    once. -x changes into the node's directory through the descriptor the
    walk verified, so the path above the node cannot be swapped between
    test and use; -x refuses to run when PATH holds a relative or empty
    element, since a file planted in the walked directory would run.
    -j passes the full path, which is exposed to that race, as find
    -exec is; use it when the command needs whole paths.

BASH FUNCTION

    ff.fn.bash defines a shell function named ff, for hosts where the
    binary is not installed. When a binary named ff is on PATH the
    function runs it, unless --fn or -V is given; with --bin it runs
    the binary or stops with status 2. Sourcing the file defines that
    one name and nothing else.

    The function translates the ff grammar into an argument list for
    the find of the host, BSD or GNU, and runs it; -V shows that
    command. It takes the same grammar and writes the same bytes.
    Where it differs:
      - What the native find cannot express is status 2, with a
        message that names the binary: -b on GNU find; -m -a -c in
        seconds that are not whole minutes; a back-reference in -r;
        -v with another action; -S with -x -j -delete or -q on GNU
        find; a path that begins with -.
      - -k orders its records with sort -z -s; a sort without them
        is status 2.
      - A failure of the native find is status 4, whatever it was;
        bits 8, 16 and 32 are not reported.
      - Walk diagnostics are those of the native find.
      - It runs stat(1) for each record of -v and -k and is slower.
      - A bash before 5.1 run as sh, in POSIX mode, has no process
        substitution, which the translator needs: there the function
        still hands over to a binary, and without one is status 2.

ENVIRONMENT

    PAGER      pager for --help.
    PATH       -x refuses a relative or empty element; the function
               looks here for the binary.
    LANG and LC_* are not consulted for order: names compare as bytes.

EXIT STATUS

    A bitmask. 1 and 2 are fatal; the others accumulate as the walk
    continues.
       0  success
       1  invalid option or expression
       2  environment: memory, stdout, fork, unsafe PATH for -x
       4  cannot stat, open, read or delete a node; subtree skipped
       8  a command could not run, or a + batch exited nonzero
      16  filesystem or symlink loop
      32  node changed between listing and opening; skipped
    A -x or -j ... ; command that exits nonzero is only false.

    On stderr, errors as '>>> ff : ...' and warnings as '^^^ ff : ...',
    each ending in a hex tag naming the message.

DIFFERENCES

    From NetBSD find: one-letter switches; -r is always ERE, as find -E
    -regex, with no option to choose BRE, and unanchored; -s is bytes
    with no rounding; times compare seconds, not rounded days; -d is a
    global bound; {} is never replaced inside a larger word; names are
    escaped on a terminal; -I replaces -iname, -ipath and -iregex;
    -w is when, before, after or at (find -newer is -w +./file); -i
    reads hex, as ff -v prints the inode; -0 -1 -y are find -true
    -false -samefile, and -Z is -print0;
    -mode is not find -perm: symbolic modes are queries, not chmod
    arithmetic, and octal +N (at least) and -N (at most) read the
    opposite way to find -perm -N; -k sorts what find leaves to sort(1).

EXAMPLES

  Options

    ff -S src -t f                      files in sorted walk order
    ff -L . -t d                        directories, following symlinks
    ff -H lib -d 0 -v                   the directory a lib symlink names
    ff -X / -d -2 -t d                  top directories, root filesystem
    ff -I . -n '*.jpg'                  .jpg .JPG .Jpg
    ff -D src                           each directory after its contents
    ff -Z . -t f -s +1M | xargs -0 ls -l   large files, any names
    ff -V . -n '*.h'                    ff.fn.bash: show the find command

  Sort

    ff -k . -t f                        files by name
    ff -k5 . -t f -m -1                 changed within a day, oldest first
    ff -k5r . -t f                      newest first, names only
    ff -k4r,6 . -t f -v                 cksh lines, largest first, then name
    ff -k5,4 . -t f -v                  by time, then size, then the rest
    ff -Sk . -t f                       -S and -k in one word
    ff . -t f -v | srt -k5x,4x,6,1x,2x,3
                                        what ff -k5,4,6 . -t f -v writes
    ff . -t f | cksh -k5,4              the same files, with their hashes
    ff -Z . -t f | cksh -Z | srt -Z -k5x,4x
                                        NUL records end to end: any name

  Primaries

    ff . -n '[A-Z]*.[ch]'               capitalized C sources and headers
    ff . -p '*/test/*' -t f             files below any test directory
    ff . -r '\.orig$' -o -r '\.rej$'    patch leftovers
    ff . -r '/(src|lib)/[^/]*\.c$'      C files directly in src or lib
    ff . -t lp                          symlinks and fifos
    ff . -d 1 -t d                      subdirectories, one level
    ff . -t f -s +100M                  files over 100 MiB
    ff . -t f -m -30m                   modified in the last 30 minutes
    ff . -t f -a +365                   not read for a year
    ff . -t f -c -1 -o -b -1            changed or born within a day
    ff . -w +./Makefile -n '*.c'        sources newer than Makefile
    ff . -w -6abb2e78                   modified before that second
    ff . -w - ./Makefile -n '*.c'       sources older, the sign apart
    ff . -t f -mode o+w                 world-writable files
    ff / -X -t f -mode +s               setuid or setgid files
    ff . -u root -o -g 0                owned by root or by group 0
    ff . -t f -l +1 -v                  hard-linked files, with inodes
    ff . -i 1cc01d                      the node -v showed as 1cc01d
    ff . -y notes.txt                   notes.txt and its hard links
    ff . -e                             empty files and directories

  Actions

    ff . -n core -t f -f -q             the first core file, then stop
    ff . -n '*.o' -delete               remove objects
    ff build -d +0 -t d -e -delete      remove empty directories below
                                        build, and those left empty

  Exec

    ff . -n '*.sh' -x sh -n {} \;       syntax-check each script
    ff . -t f -x grep -l TODO {} +      grep per directory, race safe
    ff . -t f -j wc -l {} +             line counts with full paths
    ff . -t f -j grep -q TODO {} \; -f  a command as a test
    ff . -n '*.log' -x sh -c 'f="$1"; gzip -- "$f" && echo "$f.gz"' - {} \;
                                        compress each log, name the result
    ff . -t f -j sh -c 'for f; do wc -c <"$f"; done' - {} +
                                        one shell for many paths

  Operators

    ff . \( -n '*.c' -o -n '*.h' \) -not -p '*/vendor/*'
                                        C files outside vendor trees
    ff . \( -n .git -o -n tmp \) -z -1 -o -t f
                                        files, pruning two directory names
    ff . -t f \( -j grep -q TODO {} \; -j echo todo: {} \; -o -0 \) -f
                                        every file, TODO files marked first
    ff . -t f -not -mode u+w -f -o -t d -e -f
                                        read-only files and empty directories

NOTES

    -u and -g resolve names on Linux by running getent from /usr/bin or
    /bin, so a static binary sees the same users as the host; without
    getent a name is an error (2) and a numeric id still works. Other
    platforms use the C library.
    Names are compared as bytes: no Unicode normalization, so on Darwin
    HFS+ a precomposed pattern does not match a decomposed name.

SEE ALSO

    cksh(1), srt(1), find(1)

REVISION

    r0.7.
__FF_MANUAL__
    printf '%s' "$m"
    } # _ff_manual
  local a= b= c= i= n= v= v2= u= s= k= dia= gs=e gd=0 prev= endopt= inexpr= act= ls= xd= rc=0 sk= REPLY=0
  local I= H= L= D= S= X= Z= V= lo=0 hi= re= ro= reader= f= t= wd= rf= nref=0 xb= xm=
  local -a paths=() opt=() pre=() ex=() xw=() kp=() kr=() kc=() kv=()
  local rev='ff r0.7 6af927be (bash function)' kre='^[0-9]+[dfgHinrvx]*(,[0-9]+[dfgHinrvx]*)*$'
  # -x where -execdir passes a bare name (BSD): words stay arguments, never
  # evaluated; names ($1 marks {} words with 1, and every + name) gain ./
  local dotsh='m=$1; shift; n=$#; for a in "$@"; do case $m in 0*) ;; *) case $a in ./*) ;; *) a=./$a ;; esac ;; esac; m=${m#?}; set -- "$@" "$a"; done; shift $n; exec "$@"'
  # BSD find takes -E before paths (NetBSD, Darwin, FreeBSD); GNU takes -regextype
  command find -E /dev/null -maxdepth 0 >/dev/null 2>&1 && dia=bsd || dia=gnu
  # options first, since a primary before them (-n x -I) must still see them;
  # then translation: paths before the expression, option words skipped
  _ff_opts "$@"
  while (($#)); do
    a="$1" ; shift
    # option words were set by _ff_opts; here the -k lists are read, in
    # argument order, a bare -k taking the next word when it reads as a list
    [ -z "$endopt" ] && _ff_optw 2 "$a" "${1-}" && { ((REPLY)) && shift || : ; continue ;} || :
    [ -z "$endopt" ] && [[ "$a" == --zero-terminated || "$a" == --fn || "$a" == --bin ]] && continue || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--" ] && { endopt=1 ; continue ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "-h" ] && { _ff_usage ; return 0 ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--help" ] && { _ff_help ; return 0 ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--man" ] && { _ff_roff ; return 0 ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--version" ] && { printf '%s\n' "$rev" ; return 0 ;} || :
    [ -z "$inexpr" ] && ! _ff_tok "$a" && {
      [[ "$a" =~ ^- ]] && [ -z "$endopt" ] && { _ffbad "unknown option" 6ab7ff01 "$a" ; return 1 ;} || :
      paths+=("$a") ; continue ;} || :
    inexpr=1
    # primaries taking one argument
    [[ "$a" =~ ^-[nprtdsmacbwugliy]$|^-mode$ ]] && {
      (($#)) || { _ffbad "missing argument for" 6ab7ff02 "$a" ; return 1 ;}
      v="$1" ; shift ; v2=
      # -w + file: a lone sign keeps the next word as well
      [ "$a" = -w ] && [[ "$v" == [+-] ]] && {
        (($#)) || { _ffbad "missing argument for" 6ab7ff02 "$a" ; return 1 ;}
        v2="$1" ; shift ;} || : ;} || :
    # grammar state: e expects a term, t follows one; mirrors ff.c parse_or/and/not
    case "$a" in
      '!'|-not) gs=e ; ex+=('!') ;;
      '(') gs=e ; gd=$((gd+1)) ; ex+=('(') ;;
      ')') [ "$gs" = t ] && ((gd>0)) || {
             [ "$prev" = "(" ] && _ffbad "empty ( )" 6ab7ff07 || _ffbad "unexpected" 6ab7ff05 ")" ; return 1 ;}
           gd=$((gd-1)) ; ex+=(')') ;;
      -o) [ "$gs" = t ] || { _ffbad "unexpected" 6ab7ff05 "-o" ; return 1 ;} ; gs=e ; ex+=(-o) ;;
      -n) gs=t ; [ -n "$I" ] && ex+=(-iname "$v") || ex+=(-name "$v") ;;
      -p) gs=t ; [ -n "$I" ] && ex+=(-ipath "$v") || ex+=(-path "$v") ;;
      -r) gs=t ; re=1 ; ro="$v"
          # ff -r is unanchored ERE; native -regex matches the whole path, so the
          # pattern is grouped between .* and .*, which renumbers its groups
          [[ "$v" =~ \\[1-9] ]] && { chkerr "ff : -r backreference needs ff.c (6ab7ff40)" ; return 2 ;} || :
          v=".*($v).*"
          # a bad expression is a usage error before any walk, as ff.c regcomp;
          # the native find compiles it, and only the binary adds the reason
          { case "$dia" in
              bsd) command find -E /dev/null -maxdepth 0 -regex "$v" ;;
              *) command find /dev/null -maxdepth 0 -regextype posix-extended -regex "$v" ;;
            esac ;} >/dev/null 2>&1 || { _ffbad "-r: bad regular expression" 6ab7ff09 "$ro" ; return 1 ;}
          [ -n "$I" ] && ex+=(-iregex "$v") || ex+=(-regex "$v") ;;
      -t) gs=t ; [[ "$v" =~ ^[fdlpsbc]+$ ]] || { _ffbad "-t: types are f d l p s b c, not" 6ab7ff0a "$v" ; return 1 ;}
          ((${#v}>1)) && ex+=('(') || :
          for ((i=0; i<${#v}; i++)); do ((i)) && ex+=(-o) || : ; ex+=(-type "${v:i:1}") ; done
          ((${#v}>1)) && ex+=(')') || : ;;
      -d) gs=t ; [[ "$v" =~ ^([+-]?)([0-9]+)$ ]] && ((${#BASH_REMATCH[2]}<18)) \
            || { _ffbad "-d: depth is [+-]N, not" 6ab7ff0b "$v" ; return 1 ;}
          n=$((10#${BASH_REMATCH[2]})) ; s="${BASH_REMATCH[1]}"
          case "$s" in +) ((n+1>lo)) && lo=$((n+1)) || : ;;
            -) [ -z "$hi" ] || ((n-1<hi)) && hi=$((n-1)) || : ;;
            *) ((n>lo)) && lo=$n || : ; [ -z "$hi" ] || ((n<hi)) && hi=$n || : ;; esac ;;
      -s) gs=t ; [[ "$v" =~ ^([+-]?)([0-9]+)([ckKmMgGtT]?)$ ]] && ((${#BASH_REMATCH[2]}<16)) \
            || { _ffbad "-s: size is [+-]N[ckMGT], not" 6ab7ff0c "$v" ; return 1 ;}
          case "${BASH_REMATCH[3]}" in k|K) u=1024 ;; m|M) u=1048576 ;; g|G) u=1073741824 ;;
            t|T) u=1099511627776 ;; *) u=1 ;; esac
          n=$((10#${BASH_REMATCH[2]} * u))
          ex+=(-size "${BASH_REMATCH[1]}${n}c") ;;
      -m|-a|-c|-b) gs=t
          [[ "$v" =~ ^([+-]?)([0-9]+)([smhdw]?)$ ]] && ((${#BASH_REMATCH[2]}<12)) \
            || { _ffbad "${a}: time is [+-]N[smhdw], not" 6ab7ff0e "$v" ; return 1 ;}
          case "${BASH_REMATCH[3]}" in s) u=1 ;; m) u=60 ;; h) u=3600 ;; w) u=604800 ;; *) u=86400 ;; esac
          n=$((10#${BASH_REMATCH[2]})) ; s="${BASH_REMATCH[1]}"
          ((u%60==0 || n*u%60==0)) || { chkerr "ff : -${a:1} in seconds needs ff.c '$v' (6ab7ff41)" ; t=2 ;}
          k="${a:1}" ; [ "$k" = b ] && k=B
          [ "$k" = B ] && [ "$dia" = gnu ] && { chkerr "ff : -b birth time needs ff.c on GNU find (6ab7ff42)" ; t=2 ;}
          # minutes: +N over N units, -N under N units, N within [N, N+1) units
          case "$s" in +) ex+=(-${k}min "+$((n*u/60))") ;; -) ex+=(-${k}min "-$((n*u/60))") ;;
            *) ex+=('(' -${k}min "-$(((n+1)*u/60))") ; ((n)) && ex+=(! -${k}min "-$((n*u/60))") || : ; ex+=(')') ;; esac ;;
      -w) gs=t ; _ff_when "$v" "$v2" || return $? ;;
      -y) gs=t ; { [ -n "$H$L" ] && [ -e "$v" ] ;} || { [ -z "$H$L" ] && { [ -e "$v" ] || [ -L "$v" ] ;} ;} \
            || { _ffbad "-y: cannot stat" 6ab7ff48 "$v" ; return 1 ;}
          # -samefile where the native find has it; else the inode (exact within one filesystem)
          [ -z "$FF_NO_SAMEFILE" ] && command find /dev/null -maxdepth 0 -samefile /dev/null >/dev/null 2>&1 \
            && ex+=(-samefile "$v") || {
            read -r k < <(stat ${H:+-L} ${L:+-L} -c %i -- "$v" 2>/dev/null || stat ${H:+-L} ${L:+-L} -f %i -- "$v" 2>/dev/null) || :
            [[ "$k" =~ ^[0-9]+$ ]] || { _ffbad "-y: cannot stat" 6ab7ff48 "$v" ; return 1 ;}
            ex+=(-inum "$k") ;} ;;
      # true and false; not every find has -true -false
      -0) gs=t ; ex+=('(' -type d -o ! -type d ')') ;;
      -1) gs=t ; ex+=(! '(' -type d -o ! -type d ')') ;;
      -mode) gs=t ; _ff_perm "$v" || return 1 ;;
      -u|-g) gs=t ; [ "$a" = -u ] && k=-user || k=-group
          command find /dev/null -maxdepth 0 "$k" "$v" >/dev/null 2>&1 \
            || { _ffbad "${a}: no such ${k#-}" "$([ "$a" = -u ] && echo 6ab7ff12 || echo 6ab7ff13)" "$v" ; return 1 ;} ; ex+=("$k" "$v") ;;
      -l) gs=t ; [[ "$v" =~ ^[+-]?[0-9]+$ ]] || { _ffbad "-l: links is [+-]N, not" 6ab7ff16 "$v" ; return 1 ;}
          ex+=(-links "$v") ;;
      -i) gs=t ; [[ "$v" =~ ^([+-]?)([0-9a-fA-F]{1,16})$ ]] || { _ffbad "-i: inode is [+-]HEX, not" 6ab7ff17 "$v" ; return 1 ;}
          # hex, as ff -v prints the inode; native -inum is decimal
          ex+=(-inum "${BASH_REMATCH[1]}$(printf %u "0x${BASH_REMATCH[2]}")") ;;
      -e) gs=t ; ex+=(-empty) ;;
      -z) gs=t ; ex+=(-prune) ;;
      -f) gs=t ; act+=f ; ex+=(-print) ;;
      -v) gs=t ; act+=v ; ls=1 ; ex+=(-print) ;;
      -q) gs=t ; act+=q
          command find /dev/null -maxdepth 0 -quit >/dev/null 2>&1 && ex+=(-quit) || ex+=(-exit) ;;
      -delete) gs=t ; act+=r ; D=1 ; ex+=(-delete) ;;
      -x|-j) gs=t ; act+=x
          n=0 ; b= ; c= ; xm= ; xw=() ; prev="$a"
          while (($#)); do
            [ "$1" = ";" ] && break || :
            [ "$1" = "+" ] && [ "$prev" = "{}" ] && break || :
            [[ "$1" == *"{}"* ]] && [ "$1" != "{}" ] && { _ffbad "{} must be a whole argument, not" 6ab7ff19 "$1" ; return 1 ;} || :
            ((n==0)) && [ "$1" = "{}" ] && { _ffbad "{} cannot be the command of" 6ab7ff1b "$a" ; return 1 ;} || :
            [ "$1" = "{}" ] && { c=$((c+1)) ; xm+=1 ;} || xm+=0
            ((n==0)) && b="$1" || :
            xw+=("$1") ; prev="$1" ; n=$((n+1)) ; shift
          done
          (($#)) || { _ffbad "missing ; or {} + after" 6ab7ff1d "$a" ; return 1 ;}
          ((n)) || { _ffbad "missing command after" 6ab7ff18 "$a" ; return 1 ;}
          [ "$1" = "+" ] && ((c>1)) && { _ffbad "with +, {} may appear only once, last, in" 6ab7ff1a "$a" ; return 1 ;} || :
          [ "$a" = -x ] && [[ "$b" == */* ]] && [[ "$b" != /* ]] \
            && { _ffbad "-x: command must be absolute or found in PATH, not" 6ab7ff1c "$b" ; return 1 ;} || :
          [ "$a" = -x ] && [[ "$b" != */* ]] && xd=1 || :
          # -execdir names: GNU ./name as ff.c, BSD a bare name; probe once per call
          [ "$a" = -x ] && [ -z "$xb" ] && {
            read -r k < <(command find /dev/null -maxdepth 0 -execdir echo {} \; 2>/dev/null) || :
            [[ "$k" == ./* ]] && [ -z "$FF_BARE_EXECDIR" ] && xb=n || xb=y ;} || :
          # a bare name gains ./ through dotsh; with + every name past the words does
          [ "$a" = -x ] && [ "$xb" = y ] && { [ "$1" = + ] && xm="${xm%?}" || :
            ex+=(-execdir /bin/sh -c "$dotsh" ff "$xm" "${xw[@]}" "$1") ;} \
            || { [ "$a" = -x ] && ex+=(-execdir "${xw[@]}" "$1") || ex+=(-exec "${xw[@]}" "$1") ;}
          shift ;;
      *) [[ "$a" =~ ^- ]] && _ffbad "unknown primary" 6ab7ff03 "$a" || _ffbad "unexpected word" 6ab7ff04 "$a" ; return 1 ;;
    esac
    prev="$a"
  done
  ((${#ex[@]})) && [ "$gs" = e ] && { _ffbad "expression ends early, after" 6ab7ff06 "$prev" ; return 1 ;} || :
  ((gd)) && { _ffbad "missing )" 6ab7ff08 ; return 1 ;} || :
  [ -n "$L" ] && [[ "$act" == *r* ]] && { _ffbad "-delete is refused with -L" 6ab7ff1e ; return 1 ;} || :
  [ -n "$xd" ] && { [[ ":$PATH:" =~ ::|:[^/] ]] || [ -z "$PATH" ]; } \
    && { chkerr "ff : -x: refusing a relative or empty element in PATH '$PATH' (6ab7ff29)" ; return 2 ;} || :
  [ -n "$t" ] && return 2 || :
  # capability limits of the translator: exit 2, the binary has no such limit
  [ -n "$ls" ] && [[ "$act" =~ [fxr] ]] && { chkerr "ff : -v with other actions needs ff.c (6ab7ff43)" ; return 2 ;} || :
  [ -n "$sk" ] && ! printf 'a\0' | LC_ALL=C sort -z -s -t $'\t' -k1,1n >/dev/null 2>&1 && { chkerr "ff : -k needs sort -z -s, use ff.c (6ab7ff4d)" ; return 2 ;} || :
  [ -n "$S" ] && [ "$dia" = gnu ] && [[ "$act" =~ [xrq] ]] && { chkerr "ff : -S with -x -j -delete -q needs ff.c on GNU find (6ab7ff44)" ; return 2 ;} || :
  for a in "${paths[@]}"; do
    [[ "$a" =~ ^- ]] && { chkerr "ff : path begins with -, use ./ or ff.c '$a' (6ab7ff45)" ; return 2 ;} || :
  done
  ((${#paths[@]})) || paths=(.)
  # -delete refuses an operand whole, as ff.c refuse_operand: last component
  # .., or the root directory by identity (-ef; with -H a symlink to it), not
  # walked, status 4; the native find would refuse only the node, or not at all
  [[ "$act" == *r* ]] && {
    kp=() ; for a in "${paths[@]}"; do
      b="$a" ; while [[ "$b" == */ && "$b" != / ]]; do b="${b%/}" ; done
      { [ "${b##*/}" = .. ] || { { [ -n "$H" ] || [ ! -L "$a" ] ;} && [ "$a" -ef / ] ;} ;} \
        && { _ffbad "refusing to delete" 6ab7ff37 "$a" ; rc=$((rc|4)) ;} || kp+=("$a")
    done
    ((${#kp[@]})) || return $rc
    paths=("${kp[@]}") ;} || :
  [ -n "$hi" ] && ((hi<lo)) && return 0 || :   # no depth satisfies -d
  # options before paths, global primaries first in the expression
  [ -n "$H" ] && opt+=(-H) || : ; [ -n "$L" ] && opt+=(-L) || :
  [ -n "$re" ] && { [ "$dia" = bsd ] && opt+=(-E) || pre+=(-regextype posix-extended) ;} || :
  [ -n "$S" ] && [ "$dia" = bsd ] && opt+=(-s) || :
  [ -n "$D" ] && pre+=(-depth) || : ; [ -n "$X" ] && pre+=(-xdev) || :
  ((lo)) && pre+=(-mindepth "$lo") || : ; [ -n "$hi" ] && pre+=(-maxdepth "$hi") || :
  ((${#ex[@]})) || [ -n "$act" ] || ex=(-print)
  [ -z "$act" ] && [ "${ex[*]}" != "-print" ] && ex=('(' "${ex[@]}" ')' -print) || :
  # printing: native -print/-print0 to a pipe; tty escaping, -v and emulated -S read NUL records
  { [ -n "$ls$sk" ] || { [ -t 1 ] && [ -z "$Z" ] ;} || { [ -n "$S" ] && [ "$dia" = gnu ] ;} ;} && reader=1 || :
  [ -n "$reader$Z" ] && for ((i=0; i<${#ex[@]}; i++)); do
    [ "${ex[i]}" = -print ] && ex[i]=-print0 || :
    # skip command words through the ; or {} + terminator
    [[ "${ex[i]}" =~ ^-exec(dir)?$ ]] && for ((i++; i<${#ex[@]}; i++)); do
      [ "${ex[i]}" = ";" ] && break || : ; [ "${ex[i]}" = "+" ] && [ "${ex[i-1]}" = "{}" ] && break || :
    done || :
  done
  [ -z "$reader" ] && { _ff_show find "${opt[@]}" "${paths[@]}" "${pre[@]}" "${ex[@]}"
    command find "${opt[@]}" "${paths[@]}" "${pre[@]}" "${ex[@]}" || rc=$((rc|4)) ; return $rc ;}
  # records: per operand for emulated sort, else one run over all operands
  [ -n "$S" ] && [ "$dia" = gnu ] && {
    for a in "${paths[@]}"; do
      _ff_show find "${opt[@]}" "$a" "${pre[@]}" "${ex[@]}" ; [ -n "$V" ] && stderr "# sorted by ff.fn.bash" || :
      _ff_sorted "$D" command find "${opt[@]}" "$a" "${pre[@]}" "${ex[@]}" || rc=$((rc|4))
    done ;} || {
    _ff_show find "${opt[@]}" "${paths[@]}" "${pre[@]}" "${ex[@]}"
    while IFS= read -r -d '' f; do _ff_rec "$f" ; done < <(command find "${opt[@]}" "${paths[@]}" "${pre[@]}" "${ex[@]}")
    wait $! || rc=$((rc|4)) ;}
  [ -n "$sk" ] && { [ -n "$V" ] && stderr "# sorted by ff.fn.bash: -k" || : ; _ff_ksort ;} || :
  return $rc
  ) ;} # ff
