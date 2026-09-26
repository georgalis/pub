#!/usr/bin/env bash

cksh () ( # return sortable stat and hash data for args OR stdin file list
  # rev 6ab7e734 20260926 083932 PDT Sat 08:39 AM 26 Sep 2026
  #     openssl<3 xoflen fallback, -k/-r value sort, --help, status bitmask,
  #     chkerr/chkwrn diagnostics, subshell namespace; companion C port cksh.c
  # rev 68e9ff40 20251010 235456 PDT Fri 11:54 PM 10 Oct 2025
  #     -0..-5, bare -n and -x (getopts :), -n and -x range validation
  # rev 68e20bca 20251004 231018 PDT Sat 11:10 PM 04 Oct 2025
  #     renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired
  # rev 677c9c44 20250106 191516 PST Mon 07:15 PM 06 Jan 2025
  #     chksthash, from ckstatsum: shake256 -xoflen 3 hash column
  # org 6305e87b 20220824 015939 PDT Wed 01:59 AM 24 Aug 2022 ckstat ckstatsum cks
  # (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
  # subshell body: helpers below stay out of the caller's namespace
  stderr() {  [ "$*" ] && echo "$*" 1>&2 || true ;}                      #:> args to stderr, or noop if null
  chkwrn() {  [ "$*" ] && { stderr    "^^^ $*" ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
  chkerr() {  [ "$*" ] && { stderr    ">>> $*" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null
  _cksh_usage () { sed 's/^[ ]\{6\}//' <<eof
        Usage: cksh [-NUM] [-n [NUM]] [-x [LEN]] [-k [N]] [-r] [FILE...]
        Output: inode links shake256 size mdate filename
          -n [NUM]  Omit NUM leading fields: 0-5 (bare: 0, default: 2)
          -x [LEN]  XOF hash length: 0=skip, 1-64 (bare: 0, default: 3)
          -k [N]    Sort on field N, then following fields: 1-6 (bare: 6)
          -r        Reverse: with -k reverse sort, alone reverse input order
                    forms: -k[ ][N] -rk[ ][N] -kr[ ][N]
          --        End options; remaining args treated as filenames
          -h        Show help; --help for the manual
        Reads filenames from arguments or stdin.
eof
    }
  _cksh_manual () { sed 's/^[ ]\{4\}//' <<'eof'
    NAME
      cksh - sortable stat and SHAKE256 listing of files

    SYNOPSIS
      cksh [-0..-5] [-n [NUM]] [-x [LEN]] [-k [N]] [-r] [--] [FILE...]
      cksh -h | --help

    DESCRIPTION
      For each FILE, or each line of stdin when no FILE is given, print
      one line of six space separated fields, numbers in lowercase hex
      padded to minimum widths, so the data aligns in columns:

           inode lk hash       size    mdate name
          1cc01d  1 483366        3 5e0bd2c0 t/a
          1cc01c  2 000000     1000 5e0bd2c0 t/d/
          1cc01f  1 483366        1 5e0bd2c0 t/l@

        inode  %8x   inode number of the node itself (not followed)
        lk     %2x   hard link count
        hash   SHAKE256 of the content, LEN bytes as 2*LEN hex digits;
               zeros for directories and nodes that are not hashed
        size   %8x   size in bytes (a symlink reports its own size)
        mdate  %08x  modification time, unix seconds
        name   as given, with ls -F style indicator:
               / directory  @ symlink  | fifo  = socket

      Omitted fields print as '.', so field numbers never shift and the
      name always begins at field 6. A value wider than its column offsets
      the rest of that line only; fields stay space separated, so awk $N
      and sorting by field are unaffected. A name containing spaces runs
      to end of line; recover it with:
        awk '{print substr($0, index($0,$6))}'

      Symlinks report their own inode, links, size and mdate, but the
      hash is of the target content.

    OPTIONS
      -0 .. -5   same as -n 0 .. -n 5
      -n [NUM]   omit the first NUM fields, 0-5. Bare -n (last on the
                 line) means 0. Default 2: inode and links are omitted,
                 since they differ between copies of identical trees.
                 NUM above 2 omits the hash, so no file is read.
      -x [LEN]   hash length in bytes, 0-64; 0 skips hashing. Bare -x
                 means 0. Default 3 (6 hex digits) suits change and
                 integrity checks among a person's own files; use 32 or
                 more where collisions must be infeasible.
      -k [N]     sort on field N, 1-6, then the fields after it, then
                 the name. Hex numbers compare by value, so wide values
                 sort correctly; hash and name compare bytewise, as in
                 LC_ALL=C. An omitted field compares equal. Bare -k
                 means 6 (by name). Sorting buffers all output; without
                 -k or -r lines stream as produced.
                 A following word is taken as N only if it consists of
                 digits or 'r'; otherwise -k is bare and the word is a
                 file, so 'cksh -k *' works. Use -- or ./ for a file
                 named like a number.
      -r         with -k, reverse the sort; alone, reverse input order.
                 Accepted forms: -k[ ][N]  -rk[ ][N]  -kr[ ][N]
                 Invalid: -k r  -k5r  -k 7
      --         end of options
      -h         short usage
      --help     this manual

    EXAMPLES
      cksh -k5 *                     by modification time, oldest first
      cksh -rk5 *                    newest first
      find . -type f | cksh -k3      group identical content by hash
      cksh -x 32 -n 0 file           full 256 bit digest with inode
      cksh -4 -k4 *                  names and sizes, sorted by size
      find a -type f | cksh > a.ck; find b -type f | cksh > b.ck
                                     compare trees with diff or join

    HASH
      SHAKE256 is an extendable output function: the first L bytes of a
      longer digest equal the L byte digest, so -x 3 values remain valid
      prefixes of -x 32 values and of openssl shake256 -xoflen output.
      The C binary computes SHAKE256 itself (FIPS 202) and needs no
      openssl. The bash function uses openssl, preferring pkgsrc
      $LOCALBASE/bin/openssl; with OpenSSL older than 3.0 it truncates
      the 32 byte default digest, which limits it to -x 32.

    EXIT STATUS
      A bitmask. 1 and 2 are fatal and stop before any file is read;
      the others accumulate while the run continues.
         0  success
         1  invalid option or argument
         2  environment: out of memory, stdin or stdout failure
            (bash: no usable openssl shake256 for the requested -x)
         4  cannot stat a name; line skipped
         8  cannot open or read a regular file; line skipped
        16  fifo, socket or device; warned, never opened, hash zeros
        32  dangling symlink; warned, hash zeros
      e.g. 52 = 4|16|32: a missing name, a fifo and a dangling link.

    DIAGNOSTICS
      On stderr, errors as '>>> cksh : ...' and warnings as
      '^^^ cksh : ...', each ending in a hex tag naming the message.

    NOTES
      Names are read one per line; a name containing a newline cannot be
      passed on stdin.

    HISTORY
      rev 6ab7e734 20260926 083932 PDT Sat 08:39 AM 26 Sep 2026
          C port with built-in SHAKE256; openssl<3 xoflen fallback in the
          bash function; -k/-r value sort; --help manual; status bitmask;
          chkerr/chkwrn diagnostics; bash helpers isolated in a subshell.
          Changes from 68e9ff40: non-regular nodes hash as zeros (were
          blank); fifos are warned and never opened (blocked the run);
          per-file errors warn and continue (aborted the run); exit status
          is a bitmask (was 0 or 1); ls -F indicators come from lstat, so a
          name ending in * or % keeps it (was stripped); stdin names are
          read raw, backslashes kept; numbers formatted by printf, not awk.
      rev 68e9ff40 20251010 235456 PDT Fri 11:54 PM 10 Oct 2025
          -0..-5, bare -n and -x (getopts :), -n and -x range validation
      rev 68e20bca 20251004 231018 PDT Sat 11:10 PM 04 Oct 2025
          renamed cksh, getopts -n -x -h; ckstat and ckstatsum retired
      rev 677c9c44 20250106 191516 PST Mon 07:15 PM 06 Jan 2025
          chksthash, from ckstatsum: shake256 -xoflen 3 hash column
      org 6305e87b 20220824 015939 PDT Wed 01:59 AM 24 Aug 2022
          ckstat ckstatsum cks

    COPYRIGHT
      (c) 2017-2026 George Georgalis <george@iuxta.com>
      Unlimited use with attribution.
eof
    }
  # one key line: fixed width decimal values (0 when omitted), hash, name+indicator;
  # bytewise sort -k N on it equals a by-value sort on field N then following fields
  _cksh_key () {
    read ino lnk sz mt < <(_stat "$f" 2>/dev/null) || :
    [[ "$ino $lnk $sz $mt" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ -?[0-9]+$ ]] \
      || { chkerr "cksh : cannot stat '$f' (6ab75465)" ; rc=$((rc|4)) ; return 1 ;}
    h=. ; ((x==0)) || { h="$z"
      [ -L "$f" ] && [ ! -e "$f" ] && { chkwrn "cksh : dangling symlink, not hashed '$f' (6ab75466)" ; rc=$((rc|32)) ;} \
      || { [ -d "$f" ] && : || { [ -f "$f" ] && {
        read h < <({ "$ssl" shake256 ${xo:+-xoflen "$x"} -hex <"$f" ;} 2>/dev/null) || :
        h="${h##* }" ; h="${h:0:ol}"
        [[ "$h" =~ ^[0-9a-f]+$ ]] && [ "${#h}" -eq "$ol" ] \
          || { chkerr "cksh : cannot read '$f' (6ab75467)" ; rc=$((rc|8)) ; return 1 ;}
        } || { h="$z" ; [ -p "$f" ] && t=fifo || { [ -S "$f" ] && t=socket || t="special file" ;}
          chkwrn "cksh : $t, not hashed '$f' (6ab75468)" ; rc=$((rc|16)) ;} ;} ;} ;}
    ((n<1)) || ino=0 ; ((n<2)) || lnk=0 ; ((n<4)) || sz=0 ; ((n<5)) || mt=0
    [ -L "$f" ] && s=@ || { [ -d "$f" ] && s=/ || { [ -p "$f" ] && s='|' || { [ -S "$f" ] && s='=' || s= ;} ;} ;}
    # mdate is signed: 0 prefix for negative (biased by 2^63), 1 for non-negative
    ((mt<0)) && printf -v m '0%019d' "$((9223372036854775807+mt+1))" || printf -v m '1%019d' "$mt"
    printf -v l '%020u %020u %s %020u %s %s%s' "$ino" "$lnk" "$h" "$sz" "$m" "$f" "$s"
    }
  # render a key line in display form: hex columns per -n, '.' for omitted
  _cksh_out () {
    local f1=. f2=. f4=. f5=. o=$((hw+43))
    ((n<1)) && printf -v f1 '%8x' "$((10#${l:0:20}))" || : ; ((n<2)) && printf -v f2 '%2x' "$((10#${l:21:20}))" || :
    ((n<4)) && printf -v f4 '%8x' "$((10#${l:o:20}))" || :
    m=$((10#${l:o+22:19})) ; [ "${l:o+21:1}" = 1 ] || m=$((m-9223372036854775807-1))
    ((n<5)) && printf -v f5 '%08x' "$m" || :
    printf '%s %s %s %s %s %s\n' "$f1" "$f2" "${l:42:hw}" "$f4" "$f5" "${l:o+42}"
    }
  local f= OS= n=2 x=3 k= r= ol= hw=1 opt= OPTARG= OPTIND=1 a= p= q= h= l= t= z= s= ssl= xo= out= rc=0
  local ino= lnk= sz= mt= m=
  local -a av=()
  # normalize -kr[N] to -r -k[N] (getopts binds the rest of a bundle to k); stop at operands
  for a in "$@"; do
    [ -n "$p" ] && { av+=("$a") ; continue ;} || :
    [[ "$a" =~ ^-kr([1-6]?)$ ]] && { av+=(-r "-k${BASH_REMATCH[1]}") ; continue ;} || :
    [ "$a" = "--" ] && p=1 || { [[ "$a" =~ ^- ]] || [[ "$q" =~ ^-[0-5r]*[nxk]$ ]] || p=1 ;}
    av+=("$a") ; q="$a"
  done
  set -- "${av[@]}"
  while getopts ":012345n:x:k:rh-:" opt; do case "$opt" in
    0|1|2|3|4|5) n="$opt" ;; n) n="$OPTARG" ;; x) x="$OPTARG" ;; r) r=1 ;;
    k) [[ "$OPTARG" =~ ^[1-6]$ ]] && k="$OPTARG" \
         || { [ "${@:OPTIND-1:1}" = "$OPTARG" ] && [[ ! "$OPTARG" =~ ^[0-9r]+$ ]] \
         && { k=6 ; OPTIND=$((OPTIND-1)) ;} \
         || { chkerr "$FUNCNAME : -k requires 1-6, got '$OPTARG' (6ab75460)" ; return 1 ;} ;} ;;
    :) case "$OPTARG" in n) n=0 ;; x) x=0 ;; k) k=6 ;; esac ;;
    h) _cksh_usage ; return 0 ;;
    -) [ "$OPTARG" = help ] && { _cksh_manual ; return 0 ;} \
         || { chkerr "$FUNCNAME : invalid option '--$OPTARG' (6ab75461)" ; return 1 ;} ;;
    ?) chkerr "$FUNCNAME : invalid option '-$OPTARG' (68e9fa9a)" ; return 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  # Validate n and x input
  [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 0 ] && [ "$n" -le 5 ] \
    || { chkerr "$FUNCNAME : -n requires 0-5, got '$n' (68e9fbb2)" ; return 1 ;}
  [[ "$x" =~ ^[0-9]+$ ]] && [ "$x" -ge 0 ] && [ "$x" -le 64 ] \
    || { chkerr "$FUNCNAME : -x requires 0-64, got '$x' (68e9fc22)" ; return 1 ;}
  n=$((10#$n)) ; x=$((10#$x)) ; ((n>2)) && x=0 || : # don't hash if field is omitted
  ol=$((x*2)) ; ((x==0)) || hw=$ol ; printf -v z '%0*d' "$ol" 0
  # select openssl: pkgsrc first; verify SHAKE256 by known empty digest 46b9dd2b...
  ((x==0)) || {
    for a in ${LOCALBASE:+"$LOCALBASE/bin/openssl"} openssl; do
      command -v "$a" >/dev/null 2>&1 && { ssl="$a" ; break ;} || :
    done
    [ -n "$ssl" ] || { chkerr "$FUNCNAME : openssl not found, use -x 0 or cksh.c (6ab75462)" ; return 2 ;}
    read h < <("$ssl" shake256 -xoflen 4 -hex </dev/null 2>/dev/null) || :
    [[ "$h" =~ =\ 46b9dd2b$ ]] && xo=1 || {
      read h < <("$ssl" shake256 -hex </dev/null 2>/dev/null) || :
      [[ "$h" =~ =\ 46b9dd2b[0-9a-f]{56}$ ]] \
        || { chkerr "$FUNCNAME : $ssl lacks shake256 (LibreSSL, OpenSSL<1.1.1), use cksh.c (6ab75463)" ; return 2 ;}
      ((x<=32)) || { chkerr "$FUNCNAME : $ssl lacks -xoflen, -x limited to 32, got $x (6ab75464)" ; return 2 ;}
    } ;}
  # use the correct stat options per OS
  read OS < <(uname) ; [ "$OS" = "Linux" ] && _stat() { stat -c %i\ %h\ %s\ %Y -- "$1" ;} || :
  [ "$OS" = "Darwin" -o "$OS" = "NetBSD" ] && _stat() { stat -f %i\ %l\ %z\ %m -- "$1" ;} || :
  # filenames from args or stdin, one per line; empty lines ignored; stream unless -k/-r
  _cksh_one () { [ -n "$f" ] && _cksh_key && { [ -n "$k$r" ] && out+="$l"$'\n' || _cksh_out ;} || : ;}
  (($#)) && { for f in "$@"; do _cksh_one ; done ;} \
    || { while IFS= read -r f || [ -n "$f" ]; do _cksh_one ; done ;}
  [ -n "$out" ] && while IFS= read -r l; do _cksh_out ; done < <(
    [ -n "$k" ] && LC_ALL=C sort ${r:+-r} -k "$k" <<<"${out%$'\n'}" \
      || awk '{a[NR]=$0} END{for(i=NR;i>0;i--)print a[i]}' <<<"${out%$'\n'}") || :
  return $rc
  # shake256 of an XOF is prefix stable: -xoflen 3 == first 3 bytes of the 32 byte default (openssl<3)
  # extract filenames with spaces from output: awk '{print substr($0, index($0,$6))}'
  ) # cksh
