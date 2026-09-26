#!/usr/bin/env bash

ff () ( # functional find: ff grammar run by the host's native find; companion ff.c
  # org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
  #     translator for BSD (-E) and GNU (-regextype) find dialects, tty escaping,
  #     chkerr/chkwrn diagnostics, subshell namespace; companion C binary ff.c
  # (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
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
    [[ "$1" =~ ^(!|\(|\)|-o|-delete|-[nprtdsmacbwkuglixjezfvq])$ ]]
    } # _ff_tok

  _ff_rec () { # one record from the native find: -v line, NUL, escaped, or raw
    local LC_ALL=C a= b= c= t= s= fmt=
    [ -n "$ls" ] && {
      [ "$(uname)" = Linux ] && fmt=(stat ${L:+-L} -c '%i %h %s %Y %F') || fmt=(stat ${L:+-L} -f '%i %l %z %m %HT')
      read -r a b c t s < <("${fmt[@]}" -- "$1" 2>/dev/null) || :
      [[ "$a $b $c $t" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ -?[0-9]+$ ]] || { chkerr "ff : cannot stat '$1' (6ab7ff32)" ; rc=$((rc|4)) ; return 0 ;}
      case "${s,,}" in directory) s=/ ;; symbolic*) s=@ ;; fifo*) s='|' ;; socket) s='=' ;; *) s= ;; esac
      printf '%8x %2x . %8x %08x ' "$a" "$b" "$c" "$t"
      [ -t 1 ] && _ffesc "$1" || printf '%s' "$1"
      printf '%s\n' "$s" ; return 0 ;}
    [ -n "$Z" ] && { printf '%s\0' "$1" ; return 0 ;}
    [ -t 1 ] && { _ffesc "$1" ; printf '\n' ;} || printf '%s\n' "$1"
    } # _ff_rec

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
    done < <(printf '%s\0' "${r[@]}" | sort -z)
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
	cat <<-'eof'
	Usage: ff [-EIHLDSX0] [--] [path ...] [expression]
	  options  -E ERE for -r  -I ignore case  -H/-L follow symlinks
	           -D post-order  -S sorted  -X one filesystem  -0 NUL output
	  tests    -n glob  -p glob  -r re  -t fdlpsbc  -d [+-]N  -s [+-]N[ckMGT]
	           -m -a -c -b [+-]N[smhdw]  -w file  -k [+-]mode  -u user
	           -g group  -l [+-]N  -i [+-]N  -e  -z (prune)
	  actions  -f print  -v cksh line  -x cmd {} ;|+  (in entry's dir)
	           -j cmd {} ;|+  (full path)  -delete  -q quit
	  logic    ( )  !  juxtaposition = and  -o or
	  -h this summary, --help the manual
	eof
    } # _ff_usage

  _ff_manual () { # ff --help, identical to ff.c manual
	cat <<-'eof'
	NAME
	  ff - functional find: walk file trees, one letter per switch

	SYNOPSIS
	  ff [-EIHLDSX0] [--] [path ...] [expression]
	  ff -h | --help

	DESCRIPTION
	  ff walks each path (default .) and evaluates the expression for every
	  node, as find(1) does, with one letter per switch. Options are
	  uppercase and global; they may appear anywhere except as the argument
	  of a primary. Primaries are lowercase. With no action in the
	  expression, each node for which it is true is printed.

	  Printed paths are the operand, then / and each name below it. Output
	  is raw bytes when stdout is not a terminal or -0 is given. On a
	  terminal, C0 and C1 control characters, DEL and bytes that are not
	  valid UTF-8 print as \ooo octal escapes, so a crafted name cannot
	  drive the terminal; names in diagnostics follow the same rule.

	  Directories are opened relative to their verified parent descriptor,
	  never by re-resolving a path; a directory swapped for another node
	  between listing and opening is reported and skipped.

	OPTIONS
	  -E     extended regular expressions (ERE) for -r; default basic (BRE)
	  -I     case-insensitive -n, -p and -r
	  -H     follow symlinks named as path operands
	  -L     follow all symlinks; loops are reported, not followed
	  -D     post-order: a directory is tested after its contents
	  -S     sorted walk: each directory's names in bytewise order
	  -X     do not descend into directories on other filesystems
	  -0     end names from -f and the default print with NUL, not newline
	  --     end of options: following words are paths, even with a
	         leading -, until a primary or operator
	  -h     short usage;  --help  this manual

	PRIMARIES
	  N is decimal: +N more than N, -N less than N, N exactly.
	  -n glob     last component matches glob (fnmatch; * matches a leading .)
	  -p glob     whole path matches glob (* also matches /)
	  -r re       path contains a match for re: unanchored, add ^ and $
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
	  -w file     modified more recently than file
	  -k mode     permission bits: octal or symbolic (u+x,go-w); mode is
	              exact, -mode all bits set, +mode any bit set
	  -u user     owner, name or number;  -g group  group, name or number
	  -l N        link count;  -i N  inode number
	  -e          empty regular file or directory
	  -z          prune: do not descend into this directory; true

	ACTIONS
	  -f          print the path; explicit form for use with -o
	  -v          print a cksh line: inode links . size mdate name, hex,
	              the same as cksh -n0 -x0 on that name
	  -x cmd ... ;       run cmd inside the directory holding the node, {}
	                     as ./name; true when cmd exits 0
	  -x cmd ... {} +    the same, many names per run, per directory
	  -j cmd ... ;       run cmd from the current directory, {} as the path
	  -j cmd ... {} +    the same, many paths per run
	  -delete     remove the node; implies -D; refused with -L and for
	              .. and /; . is skipped silently
	  -q          stop the walk; pending + batches still run

	OPERATORS
	  ( expr )  ! expr  expr expr (and)  expr -o expr
	  ! binds tightest, then and, then -o. Quote ( ) ! and ; for the shell.

	EXEC
	  Commands run by fork and exec, never through a shell. {} is replaced
	  only when it is a whole argument. With +, {} must be last and appear
	  once. -x changes into the node's directory through the descriptor the
	  walk verified, so the path above the node cannot be swapped between
	  test and use; -x refuses to run when PATH holds a relative or empty
	  element, since a file planted in the walked directory would run.
	  -j passes the full path, which is exposed to that race, as find
	  -exec is; use it when the command needs whole paths.

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
	  From NetBSD find: one-letter switches; -r is unanchored; -s is bytes
	  with no rounding; times compare seconds, not rounded days; -d is a
	  global bound; {} is never replaced inside a larger word; names are
	  escaped on a terminal; -I replaces -iname, -ipath and -iregex.

	EXAMPLES
	  ff . -t f -n '*.c'              C sources
	  ff -E src -r '\.(c|h)$'         the same by regex
	  ff . -n .git -z -o -t f -f      files, skipping .git trees
	  ff . -t f -m -1 -v | sort -k5   changed today, by mtime
	  ff . -t f -x grep -l TODO {} +  per-directory grep, race safe
	  ff . -n '*.o' -delete           remove objects
	  ff -0 . -t f | xargs -0 cksh    hash everything

	NOTES
	  -u and -g resolve names on Linux by running getent from /usr/bin or
	  /bin, so a static binary sees the same users as the host; without
	  getent a name is an error (2) and a numeric id still works. Other
	  platforms use the C library.
	  Names are compared as bytes: no Unicode normalization, so on Darwin
	  HFS+ a precomposed pattern does not match a decomposed name.

	HISTORY
	  org 6ab7fec8 20260926 102008 PDT Sat 10:20 AM 26 Sep 2026
	      owned openat walker with dev/ino verification; one-letter
	      grammar; -x execdir, -j exec, -delete through the verified parent;
	      getent ids on Linux; tty escaping; status bitmask; chkerr/chkwrn
	      diagnostics; bash translator ff.fn.bash for the native find.

	COPYRIGHT
	  (c) 2026 George Georgalis <george@iuxta.com>
	  Unlimited use with attribution.
	eof
    } # _ff_manual
  local a= b= c= i= n= v= u= s= k= dia= gs=e gd=0 prev= endopt= inexpr= act= ls= xd= rc=0
  local E= I= H= L= D= S= X= Z= lo=0 hi= re= reader= f= t=
  local -a paths=() opt=() pre=() ex=()
  # BSD find takes -E before paths (NetBSD, Darwin, FreeBSD); GNU takes -regextype
  command find -E /dev/null -maxdepth 0 >/dev/null 2>&1 && dia=bsd || dia=gnu
  # pre-pass and translation in one: options anywhere, paths before the expression
  while (($#)); do
    a="$1" ; shift
    [ -z "$endopt" ] && [[ "$a" =~ ^-[EIHLDSX0]+$ ]] && {
      for ((i=1; i<${#a}; i++)); do case "${a:i:1}" in
        E) E=1 ;; I) I=1 ;; H) H=1 L= ;; L) L=1 H= ;; D) D=1 ;; S) S=1 ;; X) X=1 ;; 0) Z=1 ;;
      esac ; done ; continue ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--" ] && { endopt=1 ; continue ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "-h" ] && { _ff_usage ; return 0 ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--help" ] && { _ff_manual ; return 0 ;} || :
    [ -z "$inexpr" ] && ! _ff_tok "$a" && {
      [[ "$a" =~ ^- ]] && [ -z "$endopt" ] && { _ffbad "unknown option" 6ab7ff01 "$a" ; return 1 ;} || :
      paths+=("$a") ; continue ;} || :
    inexpr=1
    # primaries taking one argument
    [[ "$a" =~ ^-[nprtdsmacbwkugli]$ ]] && {
      (($#)) || { _ffbad "missing argument for" 6ab7ff02 "$a" ; return 1 ;}
      v="$1" ; shift ;} || :
    # grammar state: e expects a term, t follows one; mirrors ff.c parse_or/and/not
    case "$a" in
      '!') gs=e ; ex+=('!') ;;
      '(') gs=e ; gd=$((gd+1)) ; ex+=('(') ;;
      ')') [ "$gs" = t ] && ((gd>0)) || {
             [ "$prev" = "(" ] && _ffbad "empty ( )" 6ab7ff07 || _ffbad "unexpected" 6ab7ff05 ")" ; return 1 ;}
           gd=$((gd-1)) ; ex+=(')') ;;
      -o) [ "$gs" = t ] || { _ffbad "unexpected" 6ab7ff05 "-o" ; return 1 ;} ; gs=e ; ex+=(-o) ;;
      -n) gs=t ; [ -n "$I" ] && ex+=(-iname "$v") || ex+=(-name "$v") ;;
      -p) gs=t ; [ -n "$I" ] && ex+=(-ipath "$v") || ex+=(-path "$v") ;;
      -r) gs=t ; re=1
          # ff -r is unanchored; native -regex matches the whole path
          [ -n "$E" ] && {
            [[ "$v" =~ \\[1-9] ]] && { chkerr "ff : -r backreference under -E needs ff.c (6ab7ff40)" ; return 2 ;}
            v=".*($v).*" ;} || {
            [[ "$v" =~ ^\^ ]] && v="${v#^}" || v=".*$v"
            [[ "$v" =~ [^\\]\$$|^\$$ ]] && v="${v%\$}" || v="$v.*" ;}
          [ -n "$I" ] && ex+=(-iregex "$v") || ex+=(-regex "$v") ;;
      -t) gs=t ; [[ "$v" =~ ^[fdlpsbc]+$ ]] || { _ffbad "-t: types are f d l p s b c" 6ab7ff0a "$v" ; return 1 ;}
          ((${#v}>1)) && ex+=('(') || :
          for ((i=0; i<${#v}; i++)); do ((i)) && ex+=(-o) || : ; ex+=(-type "${v:i:1}") ; done
          ((${#v}>1)) && ex+=(')') || : ;;
      -d) gs=t ; [[ "$v" =~ ^([+-]?)([0-9]+)$ ]] && ((${#BASH_REMATCH[2]}<18)) \
            || { _ffbad "-d: depth is [+-]N" 6ab7ff0b "$v" ; return 1 ;}
          n=$((10#${BASH_REMATCH[2]})) ; s="${BASH_REMATCH[1]}"
          case "$s" in +) ((n+1>lo)) && lo=$((n+1)) || : ;;
            -) [ -z "$hi" ] || ((n-1<hi)) && hi=$((n-1)) || : ;;
            *) ((n>lo)) && lo=$n || : ; [ -z "$hi" ] || ((n<hi)) && hi=$n || : ;; esac ;;
      -s) gs=t ; [[ "$v" =~ ^([+-]?)([0-9]+)([ckKmMgGtT]?)$ ]] && ((${#BASH_REMATCH[2]}<16)) \
            || { _ffbad "-s: size is [+-]N[ckMGT]" 6ab7ff0c "$v" ; return 1 ;}
          case "${BASH_REMATCH[3]}" in k|K) u=1024 ;; m|M) u=1048576 ;; g|G) u=1073741824 ;;
            t|T) u=1099511627776 ;; *) u=1 ;; esac
          n=$((10#${BASH_REMATCH[2]} * u))
          ex+=(-size "${BASH_REMATCH[1]}${n}c") ;;
      -m|-a|-c|-b) gs=t
          [[ "$v" =~ ^([+-]?)([0-9]+)([smhdw]?)$ ]] && ((${#BASH_REMATCH[2]}<12)) \
            || { _ffbad "time is [+-]N[smhdw]" 6ab7ff0e "$v" ; return 1 ;}
          case "${BASH_REMATCH[3]}" in s) u=1 ;; m) u=60 ;; h) u=3600 ;; w) u=604800 ;; *) u=86400 ;; esac
          n=$((10#${BASH_REMATCH[2]})) ; s="${BASH_REMATCH[1]}"
          ((u%60==0 || n*u%60==0)) || { chkerr "ff : -${a:1} in seconds needs ff.c '$v' (6ab7ff41)" ; t=2 ;}
          k="${a:1}" ; [ "$k" = b ] && k=B
          [ "$k" = B ] && [ "$dia" = gnu ] && { chkerr "ff : -b birth time needs ff.c on GNU find (6ab7ff42)" ; t=2 ;}
          # minutes: +N over N units, -N under N units, N within [N, N+1) units
          case "$s" in +) ex+=(-${k}min "+$((n*u/60))") ;; -) ex+=(-${k}min "-$((n*u/60))") ;;
            *) ex+=('(' -${k}min "-$(((n+1)*u/60))") ; ((n)) && ex+=(! -${k}min "-$((n*u/60))") || : ; ex+=(')') ;; esac ;;
      -w) gs=t ; { [ -n "$H$L" ] && [ -e "$v" ] ;} || { [ -z "$H$L" ] && { [ -e "$v" ] || [ -L "$v" ] ;} ;} \
            || { _ffbad "-w: cannot stat" 6ab7ff10 "$v" ; return 1 ;} ; ex+=(-newer "$v") ;;
      -k) gs=t ; [[ "$v" =~ ^[-+]?([0-7]{1,4}|([ugoa]*[-+=][rwxst]*)(,[ugoa]*[-+=][rwxst]*)*)$ ]] \
            || { _ffbad "-k: bad mode" 6ab7ff11 "$v" ; return 1 ;}
          [ "$dia" = gnu ] && [[ "$v" =~ ^\+ ]] && v="/${v#+}" || :
          ex+=(-perm "$v") ;;
      -u|-g) gs=t ; [ "$a" = -u ] && k=-user || k=-group
          command find /dev/null -maxdepth 0 "$k" "$v" >/dev/null 2>&1 \
            || { _ffbad "${a}: no such ${k#-}" "$([ "$a" = -u ] && echo 6ab7ff12 || echo 6ab7ff13)" "$v" ; return 1 ;} ; ex+=("$k" "$v") ;;
      -l|-i) gs=t ; [[ "$v" =~ ^[+-]?[0-9]+$ ]] \
            || { [ "$a" = -l ] && _ffbad "-l: links is [+-]N" 6ab7ff16 "$v" || _ffbad "-i: inode is [+-]N" 6ab7ff17 "$v" ; return 1 ;}
          [ "$a" = -l ] && ex+=(-links "$v") || ex+=(-inum "$v") ;;
      -e) gs=t ; ex+=(-empty) ;;
      -z) gs=t ; ex+=(-prune) ;;
      -f) gs=t ; act+=f ; ex+=(-print) ;;
      -v) gs=t ; act+=v ; ls=1 ; ex+=(-print) ;;
      -q) gs=t ; act+=q
          command find /dev/null -maxdepth 0 -quit >/dev/null 2>&1 && ex+=(-quit) || ex+=(-exit) ;;
      -delete) gs=t ; act+=r ; D=1 ; ex+=(-delete) ;;
      -x|-j) gs=t ; act+=x ; [ "$a" = -x ] && ex+=(-execdir) || ex+=(-exec)
          n=0 ; b= ; c= ; prev="$a"
          while (($#)); do
            [ "$1" = ";" ] && break || :
            [ "$1" = "+" ] && [ "$prev" = "{}" ] && break || :
            [[ "$1" == *"{}"* ]] && [ "$1" != "{}" ] && { _ffbad "{} must be a whole argument" 6ab7ff19 "$1" ; return 1 ;} || :
            ((n==0)) && [ "$1" = "{}" ] && { _ffbad "{} cannot be the command" 6ab7ff1b "$a" ; return 1 ;} || :
            [ "$1" = "{}" ] && c=$((c+1)) || :
            ((n==0)) && b="$1" || :
            ex+=("$1") ; prev="$1" ; n=$((n+1)) ; shift
          done
          (($#)) || { _ffbad "missing ; or {} + after" 6ab7ff1d "$a" ; return 1 ;}
          ((n)) || { _ffbad "missing command after" 6ab7ff18 "$a" ; return 1 ;}
          [ "$1" = "+" ] && ((c>1)) && { _ffbad "with +, {} may appear only once, last" 6ab7ff1a "$a" ; return 1 ;} || :
          [ "$a" = -x ] && [[ "$b" == */* ]] && [[ "$b" != /* ]] \
            && { _ffbad "-x: command must be absolute or found in PATH" 6ab7ff1c "$b" ; return 1 ;} || :
          [ "$a" = -x ] && [[ "$b" != */* ]] && xd=1 || :
          ex+=("$1") ; shift ;;
      *) [[ "$a" =~ ^- ]] && _ffbad "unknown primary" 6ab7ff03 "$a" || _ffbad "unexpected word" 6ab7ff04 "$a" ; return 1 ;;
    esac
    prev="$a"
  done
  ((${#ex[@]})) && [ "$gs" = e ] && { _ffbad "expression ends early" 6ab7ff06 "$prev" ; return 1 ;} || :
  ((gd)) && { _ffbad "missing )" 6ab7ff08 ; return 1 ;} || :
  [ -n "$L" ] && [[ "$act" == *r* ]] && { _ffbad "-delete is refused with -L" 6ab7ff1e ; return 1 ;} || :
  [ -n "$xd" ] && { [[ ":$PATH:" =~ ::|:[^/] ]] || [ -z "$PATH" ]; } \
    && { chkerr "ff : -x: refusing relative or empty PATH element '$PATH' (6ab7ff29)" ; return 2 ;} || :
  [ -n "$t" ] && return 2 || :
  # capability limits of the translator: exit 2, the binary has no such limit
  [ -n "$ls" ] && [[ "$act" =~ [fxr] ]] && { chkerr "ff : -v with other actions needs ff.c (6ab7ff43)" ; return 2 ;} || :
  [ -n "$S" ] && [ "$dia" = gnu ] && [[ "$act" =~ [xrq] ]] && { chkerr "ff : -S with -x -j -delete -q needs ff.c on GNU find (6ab7ff44)" ; return 2 ;} || :
  for a in "${paths[@]}"; do
    [[ "$a" =~ ^- ]] && { chkerr "ff : path begins with -, use ./ or ff.c '$a' (6ab7ff45)" ; return 2 ;} || :
  done
  ((${#paths[@]})) || paths=(.)
  [ -n "$hi" ] && ((hi<lo)) && return 0 || :   # no depth satisfies -d
  # options before paths, global primaries first in the expression
  [ -n "$H" ] && opt+=(-H) || : ; [ -n "$L" ] && opt+=(-L) || :
  [ -n "$re" ] && { [ "$dia" = bsd ] && { [ -n "$E" ] && opt+=(-E) || : ;} \
    || { [ -n "$E" ] && pre+=(-regextype posix-extended) || pre+=(-regextype posix-basic) ;} ;} || :
  [ -n "$S" ] && [ "$dia" = bsd ] && opt+=(-s) || :
  [ -n "$D" ] && pre+=(-depth) || : ; [ -n "$X" ] && pre+=(-xdev) || :
  ((lo)) && pre+=(-mindepth "$lo") || : ; [ -n "$hi" ] && pre+=(-maxdepth "$hi") || :
  ((${#ex[@]})) || [ -n "$act" ] || ex=(-print)
  [ -z "$act" ] && [ "${ex[*]}" != "-print" ] && ex=('(' "${ex[@]}" ')' -print) || :
  # printing: native -print/-print0 to a pipe; tty escaping, -v and emulated -S read NUL records
  { [ -n "$ls" ] || { [ -t 1 ] && [ -z "$Z" ] ;} || { [ -n "$S" ] && [ "$dia" = gnu ] ;} ;} && reader=1 || :
  [ -n "$reader$Z" ] && for ((i=0; i<${#ex[@]}; i++)); do
    [ "${ex[i]}" = -print ] && ex[i]=-print0 || :
    # skip command words through the ; or {} + terminator
    [[ "${ex[i]}" =~ ^-exec(dir)?$ ]] && for ((i++; i<${#ex[@]}; i++)); do
      [ "${ex[i]}" = ";" ] && break || : ; [ "${ex[i]}" = "+" ] && [ "${ex[i-1]}" = "{}" ] && break || :
    done || :
  done
  [ -z "$reader" ] && { command find "${opt[@]}" "${paths[@]}" "${pre[@]}" "${ex[@]}" || rc=$((rc|4)) ; return $rc ;}
  # records: per operand for emulated sort, else one run over all operands
  [ -n "$S" ] && [ "$dia" = gnu ] && {
    for a in "${paths[@]}"; do
      _ff_sorted "$D" command find "${opt[@]}" "$a" "${pre[@]}" "${ex[@]}" || rc=$((rc|4))
    done ;} || {
    while IFS= read -r -d '' f; do _ff_rec "$f" ; done < <(command find "${opt[@]}" "${paths[@]}" "${pre[@]}" "${ex[@]}")
    wait $! || rc=$((rc|4)) ;}
  return $rc
  ) # ff
