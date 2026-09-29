#!/usr/bin/env bash

ff () ( # functional find: ff grammar run by the host's native find; companion ff.c
  # rev 6abb42b9 20260928 214649 PDT Mon 09:46 PM 28 Sep 2026
  #     -w when [+-]([.]./file|HEX), -same, -true -false, -i hex, -V, examples;
  #     Darwin test fixes; ff.fn.bash -w reference files without -newermt
  # rev 6ab89f43 20260926 214451 PDT Sat 09:44 PM 26 Sep 2026
  #     -k permission query (at least/at most, has/lacks, X s t), -not, "not" diagnostics
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
    [[ "$1" =~ ^(!|-not|\(|\)|-o|-delete|-true|-false|-same|-[nprtdsmacbwkuglixjezfvq])$ ]]
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

  _ff_when () { # -w [+-]([.]./file|HEX) into native terms, as ff.c N_NEWER
    local w="$1" sg= at= pr= up= lo=
    sg="${w:0:1}" ; [[ "$sg" == [+-] ]] && w="${w:1}" || sg=
    if [[ "$w" == /* || "$w" == ./* || "$w" == ../* ]]; then
      { [ -n "$H$L" ] && [ -e "$w" ] ;} || { [ -z "$H$L" ] && { [ -e "$w" ] || [ -L "$w" ] ;} ;} \
        || { _ffbad "-w: cannot stat" 6ab7ff10 "$w" ; return 1 ;}
      [ "$sg" = + ] && { ex+=(-newer "$w") ; return 0 ;} || :
      at=$(_ff_ns "$w") && [ -n "$at" ] || { chkerr "ff : -w needs a stat with nanoseconds, use ff.c '$w' (6ab7ff4a)" ; return 2 ;}
      pr=$(_ff_pred "$at") ; up="$w"
    elif [[ "$w" =~ ^[0-9a-fA-F]{1,16}$ ]]; then
      ((${#w}==16)) && [[ "$w" == [89a-fA-F]* ]] && { _ffbad "time overflows" 6ab7ff0f "$1" ; return 1 ;} || :
      # whole seconds: +T after second T, -T before it, T within it
      at="$((16#$w)).999999999" ; pr="$((16#$w - 1)).999999999"
    else
      _ffbad "-w: file is ./file or /file, time is HEX, not" 6ab7ff4b "$1" ; return 1
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

  _ff_show () { # -V: the native command on stderr, quoted to paste back into a shell
    [ -n "$V" ] || return 0
    local q= w= ; for w in "$@"; do printf -v w '%q' "$w" ; q+="${q:+ }$w" ; done
    stderr "$q"
    [ -z "$wd" ] || stderr "# reference files under $wd are removed after the run"
    } # _ff_show

  _ff_perm () { # -k into native -perm terms, as ff.c parse_perm and p_perm
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
      || { _ffbad "-k: bad mode" 6ab7ff11 "$v" ; return 1 ;}
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
          && { _ffbad "-k: s is for u or g, t is for o, not" 6ab7ff46 "$v" ; return 1 ;} || :
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
	Usage: ff [-EIHLDSX0V] [--] [path ...] [expression]
	  options  -E ERE for -r  -I ignore case  -H/-L follow symlinks
	           -D post-order  -S sorted  -X one filesystem  -0 NUL output
	           -V show the native find command (ff.fn.bash)
	  tests    -n glob  -p glob  -r re  -t fdlpsbc  -d [+-]N  -s [+-]N[ckMGT]
	           -m -a -c -b [+-]N[smhdw]  -w [+-]([.]./file|HEX)  -k [+-]mode
	           -u user  -g group  -l [+-]N  -i [+-]HEX  -same file  -e
	           -z (prune)  -true  -false
	  actions  -f print  -v cksh line  -x cmd {} ;|+  (in entry's dir)
	           -j cmd {} ;|+  (full path)  -delete  -q quit
	  logic    ( )  ! or -not  juxtaposition = and  -o or
	  -h this summary, --help the manual
	eof
    } # _ff_usage

  _ff_manual () { # ff --help, identical to ff.c manual
	cat <<-'eof'
	NAME
	  ff - functional find: walk file trees, one letter per switch

	SYNOPSIS
	  ff [-EIHLDSX0V] [--] [path ...] [expression]
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
	  -V     ff.fn.bash only: print the native find command to stderr
	         before running it; helpful to extend a command to an OS find
	         specific implementation. The binary notes this and runs.
	  -h     short usage;  --help  this manual

	PRIMARIES
	  N           decimal: +N more than N, -N less than N, N exactly.
	  HEX         hexadecimal without 0x, as ff -v prints it.
	  -n glob     last component of the examined pathname matches glob
	  -p glob     examined pathname matches glob
	              The special shell pattern characters [ ] * and ? may be
	              used, and \ makes the next one literal. A leading . is
	              not special, and in -p * and ? also match /. Quote the
	              pattern so the shell does not expand it first.
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
	  -w [+-]([.]./file|HEX)
	              when: modified after (+), before (-) or at the same time
	              as file's mtime, or as HEX epoch seconds (the -v mdate).
	              A file begins with ./ ../ or /, so no word is both a file
	              and a time. A file compares the full timestamp, HEX
	              whole seconds. find -newer file is -w +./file.
	  -same file  the same node as file: same device and inode
	  -k mode     permission bits. Octal, all twelve bits:
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
	              it can hold, so -k +rs holds when other has r, since
	              other has no s; name the class to need both: -k u+rs.
	                -k u+x           owner may execute
	                -k x             someone may execute (same as +x)
	                -k -x            no one may execute
	                -k o-X           directories others may not search
	                -k o-r           others may not read
	                -k w             someone may write
	                -k o+w           world writable
	                -k go-w          neither group nor other may write
	                -not -k go-w     group or other may write
	                -k u+s  -k g+s   setuid; setgid
	                -k +s            setuid or setgid
	                -k +t            sticky
	              Either of two bits in one class: -k u+r -o -k u+x
	  -u user     owner, name or number;  -g group  group, name or number
	  -l [+-]N    link count
	  -i [+-]HEX  inode number, hex as ff -v prints it
	  -e          empty regular file or directory
	  -z          prune: do not descend into this directory; true
	  -true       always true;  -false  always false

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
	    ff . -k u+r -o -k u+x                   owner may read or execute
	  With no action in the expression, a node is printed when the whole
	  expression is true. Once any action appears (-f -v -x -j -delete
	  -q), only actions print. Prune directories by name and print the
	  files that are not RCS (,v) or backup (~) files:
	    ff . \( -n .git -o -n tmp \) -z -t f -o -t f -not -E -r ',v$|~$'
	  -z is true, so the -t f after it makes that side false for the
	  pruned directories; -z -false does the same. Options such as -E
	  may appear anywhere, even after -not.

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
	  escaped on a terminal; -I replaces -iname, -ipath and -iregex;
	  -w is when, before, after or at (find -newer is -w +./file); -i
	  reads hex, as ff -v prints the inode;
	  -k symbolic modes are queries, not chmod arithmetic, and octal
	  +mode (at least) and -mode (at most) read the opposite way to
	  find -perm -mode.

	EXAMPLES
	  Options
	    ff -S src -t f                      files in sorted walk order
	    ff -L . -t d                        directories, following symlinks
	    ff -H lib -d 0 -v                   the directory a lib symlink names
	    ff -X / -d -2 -t d                  top directories, root filesystem
	    ff -I . -n '*.jpg'                  .jpg .JPG .Jpg
	    ff -E . -r '/(src|lib)/[^/]*\.c$'   C files directly in src or lib
	    ff -D src                           each directory after its contents
	    ff -0 . -t f -s +1M | xargs -0 ls -l   large files, any names
	    ff -V . -n '*.h'                    ff.fn.bash: show the find command
	  Primaries
	    ff . -n '[A-Z]*.[ch]'               capitalized C sources and headers
	    ff . -p '*/test/*' -t f             files below any test directory
	    ff . -r '\.orig$' -o -r '\.rej$'    patch leftovers
	    ff . -t lp                          symlinks and fifos
	    ff . -d 1 -t d                      subdirectories, one level
	    ff . -t f -s +100M                  files over 100 MiB
	    ff . -t f -m -30m                   modified in the last 30 minutes
	    ff . -t f -a +365                   not read for a year
	    ff . -t f -c -1 -o -b -1            changed or born within a day
	    ff . -w +./Makefile -n '*.c'        sources newer than Makefile
	    ff . -w -6abb2e78                   modified before that second
	    ff . -t f -k o+w                    world-writable files
	    ff / -X -t f -k +s                  setuid or setgid files
	    ff . -u root -o -g 0                owned by root or by group 0
	    ff . -t f -l +1 -v                  hard-linked files, with inodes
	    ff . -i 1cc01d                      the node -v showed as 1cc01d
	    ff . -same notes.txt                notes.txt and its hard links
	    ff . -e                             empty files and directories
	  Actions
	    ff . -t f -v | sort -k5             cksh lines, oldest first
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
	    ff . \( -n .git -o -n tmp \) -z -false -o -t f
	                                        files, pruning two directory names
	    ff . -t f \( -j grep -q TODO {} \; -j echo todo: {} \; -o -true \) -f
	                                        every file, TODO files marked first
	    ff . -t f -not -k u+w -f -o -t d -e -f
	                                        read-only files and empty directories
	NOTES
	  -u and -g resolve names on Linux by running getent from /usr/bin or
	  /bin, so a static binary sees the same users as the host; without
	  getent a name is an error (2) and a numeric id still works. Other
	  platforms use the C library.
	  Names are compared as bytes: no Unicode normalization, so on Darwin
	  HFS+ a precomposed pattern does not match a decomposed name.

	HISTORY
	  rev 6abb42b9 20260928 214649 PDT Mon 09:46 PM 28 Sep 2026
	      -w is when: [+-]([.]./file|HEX), before, after or at a file's
	      mtime or a hex epoch second; a file takes ./ ../ or /; bare
	      -w file was newer, now -w +./file. -same, -true, -false; -i
	      reads hex; -V shows the native find command (ff.fn.bash), which
	      uses reference files where find lacks -newermt; grouped examples.
	  rev 6ab89f43 20260926 214451 PDT Sat 09:44 PM 26 Sep 2026
	      -k is a permission query: octal exact, +mode at least, -mode
	      at most; symbolic clauses + has, - lacks, with X s t. -not.
	      Diagnostics that state a rule end in "not" before the value.
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
  local E= I= H= L= D= S= X= Z= V= lo=0 hi= re= reader= f= t= wd= rf= nref=0
  local -a paths=() opt=() pre=() ex=()
  # BSD find takes -E before paths (NetBSD, Darwin, FreeBSD); GNU takes -regextype
  command find -E /dev/null -maxdepth 0 >/dev/null 2>&1 && dia=bsd || dia=gnu
  # pre-pass and translation in one: options anywhere, paths before the expression
  while (($#)); do
    a="$1" ; shift
    [ -z "$endopt" ] && [[ "$a" =~ ^-[EIHLDSX0V]+$ ]] && {
      for ((i=1; i<${#a}; i++)); do case "${a:i:1}" in
        E) E=1 ;; I) I=1 ;; H) H=1 L= ;; L) L=1 H= ;; D) D=1 ;; S) S=1 ;; X) X=1 ;; 0) Z=1 ;; V) V=1 ;;
      esac ; done ; continue ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--" ] && { endopt=1 ; continue ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "-h" ] && { _ff_usage ; return 0 ;} || :
    [ -z "$endopt$inexpr" ] && [ "$a" = "--help" ] && { _ff_manual ; return 0 ;} || :
    [ -z "$inexpr" ] && ! _ff_tok "$a" && {
      [[ "$a" =~ ^- ]] && [ -z "$endopt" ] && { _ffbad "unknown option" 6ab7ff01 "$a" ; return 1 ;} || :
      paths+=("$a") ; continue ;} || :
    inexpr=1
    # primaries taking one argument
    [[ "$a" =~ ^(-[nprtdsmacbwkugli]|-same)$ ]] && {
      (($#)) || { _ffbad "missing argument for" 6ab7ff02 "$a" ; return 1 ;}
      v="$1" ; shift ;} || :
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
      -r) gs=t ; re=1
          # ff -r is unanchored; native -regex matches the whole path
          [ -n "$E" ] && {
            [[ "$v" =~ \\[1-9] ]] && { chkerr "ff : -r backreference under -E needs ff.c (6ab7ff40)" ; return 2 ;}
            v=".*($v).*" ;} || {
            [[ "$v" =~ ^\^ ]] && v="${v#^}" || v=".*$v"
            [[ "$v" =~ [^\\]\$$|^\$$ ]] && v="${v%\$}" || v="$v.*" ;}
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
      -w) gs=t ; _ff_when "$v" || return $? ;;
      -same) gs=t ; { [ -n "$H$L" ] && [ -e "$v" ] ;} || { [ -z "$H$L" ] && { [ -e "$v" ] || [ -L "$v" ] ;} ;} \
            || { _ffbad "-same: cannot stat" 6ab7ff48 "$v" ; return 1 ;}
          # -samefile where the native find has it; else the inode (exact within one filesystem)
          [ -z "$FF_NO_SAMEFILE" ] && command find /dev/null -maxdepth 0 -samefile /dev/null >/dev/null 2>&1 \
            && ex+=(-samefile "$v") || {
            read -r k < <(stat ${H:+-L} ${L:+-L} -c %i -- "$v" 2>/dev/null || stat ${H:+-L} ${L:+-L} -f %i -- "$v" 2>/dev/null) || :
            [[ "$k" =~ ^[0-9]+$ ]] || { _ffbad "-same: cannot stat" 6ab7ff48 "$v" ; return 1 ;}
            ex+=(-inum "$k") ;} ;;
      -true) gs=t ; ex+=('(' -type d -o ! -type d ')') ;;
      -false) gs=t ; ex+=(! '(' -type d -o ! -type d ')') ;;
      -k) gs=t ; _ff_perm "$v" || return 1 ;;
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
      -x|-j) gs=t ; act+=x ; [ "$a" = -x ] && ex+=(-execdir) || ex+=(-exec)
          n=0 ; b= ; c= ; prev="$a"
          while (($#)); do
            [ "$1" = ";" ] && break || :
            [ "$1" = "+" ] && [ "$prev" = "{}" ] && break || :
            [[ "$1" == *"{}"* ]] && [ "$1" != "{}" ] && { _ffbad "{} must be a whole argument, not" 6ab7ff19 "$1" ; return 1 ;} || :
            ((n==0)) && [ "$1" = "{}" ] && { _ffbad "{} cannot be the command of" 6ab7ff1b "$a" ; return 1 ;} || :
            [ "$1" = "{}" ] && c=$((c+1)) || :
            ((n==0)) && b="$1" || :
            ex+=("$1") ; prev="$1" ; n=$((n+1)) ; shift
          done
          (($#)) || { _ffbad "missing ; or {} + after" 6ab7ff1d "$a" ; return 1 ;}
          ((n)) || { _ffbad "missing command after" 6ab7ff18 "$a" ; return 1 ;}
          [ "$1" = "+" ] && ((c>1)) && { _ffbad "with +, {} may appear only once, last, in" 6ab7ff1a "$a" ; return 1 ;} || :
          [ "$a" = -x ] && [[ "$b" == */* ]] && [[ "$b" != /* ]] \
            && { _ffbad "-x: command must be absolute or found in PATH, not" 6ab7ff1c "$b" ; return 1 ;} || :
          [ "$a" = -x ] && [[ "$b" != */* ]] && xd=1 || :
          ex+=("$1") ; shift ;;
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
  return $rc
  ) # ff
