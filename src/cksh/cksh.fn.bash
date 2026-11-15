# cksh.fn.bash --- cksh, sortable stat and SHAKE256 listing, as a bash function
#
# Source this file. It defines one name, the function cksh, for hosts
# without the cksh binary. When a binary named cksh is on PATH the
# function runs it; --fn keeps the function and --bin requires the
# binary. Requirements and decisions: plan-cksh.md.
#
# Method: stat(1) supplies inode, links, size and mtime in the form of
# the host (Linux, Darwin, NetBSD); openssl shake256 supplies the hash,
# cut to -x hexadecimal characters. For -k each record gets a key line
# of fixed-width decimal numbers, the hash, an index and the name
# (ended by NUL where the host sort has -z, so any name sorts), and
# the native sort orders the key lines in the C locale with one -k per
# column, so number columns compare by value and text columns by byte;
# the index then selects the display line. -o writes a temporary sibling
# of the destination (literal class .cksh.) and renames it at the end; -c
# reads a listing back, each record under its own columns and hash
# length. test-cksh.sh compares the function with the binary.
#
# Everything after the hand-over runs in a subshell opened inside cksh.
# The helper functions (_cksh_*), the usage and manual text and every
# variable are defined in that subshell and end with it: sourcing this
# file adds cksh to the calling shell and nothing else, and a call
# changes no option, trap, variable or function there.
#
# The usage and manual blocks are copies of the binary's -h and --help
# text; test-cksh.sh fails if they drift. To refresh them after the
# manual changes in cksh.c, replace the two blocks with the output of
# "./cksh -h" and "./cksh --help".
#
# revision 6af8d530 20261114 134000 PST Sat --- r0.6 key list -k5,4; -x in
#          hex characters; -n and -x bare before a file; -0..-5 and -krN
#          retired; signed mdate; names escaped on a terminal; d/ keeps
#          one slash; -Z NUL records; -L; -o renamed into place; -c check
#          a saved listing; --help as a man page on a terminal, --man;
#          hand-over to the binary, --fn and --bin; -V; one enclosing
#          function; a host without a known stat(1) is status 2
# revision 6ab7e734 20260926 083932 PDT Sat --- r0.5 openssl<3 xoflen
#          fallback, -k/-r value sort, --help, status bitmask, subshell
# revision 68e9ff40 20251010 235456 PDT Fri --- r0.4 -0..-5, bare -n and
#          -x, range validation
# revision 68e20bca 20251004 231018 PDT Sat --- r0.3 renamed cksh
# revision 677c9c44 20250106 191516 PST Mon --- r0.2 chksthash, hash column
# original 6305e87b 20220824 015939 PDT Wed --- r0.1 ckstat ckstatsum cks
#
# (c) 2017-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
cksh(){ local b= a= q= s= t= p= d= want= both=0 val=0 isv=0
  # --fn or --bin among the options chooses the form. Options end at --
  # or at the first file; a word after a bare -n, -x or -k is its value
  # only when it reads as one, and the word after a bare -o or -c always
  # is. This pass touches only its own locals: it matches with patterns,
  # since [[ =~ ]] would set BASH_REMATCH in the calling shell.
  for a in "$@" ; do
    [ "$val" -eq 0 ] || { val=0 ; q= ; continue ;}   # the value of -o or -c
    case $a in
      --) break ;;
      --fn) [ "$want" != bin ] || both=1 ; want=fn ; q= ;;
      --bin) [ "$want" != fn ] || both=1 ; want=bin ; q= ;;
      --*) q= ;;
      -?*) s=${a#-} ; while [[ $s == [rhVZL]?* ]] ; do s=${s#?} ; done
        q= ; [[ $s != [nxk] ]] || q=$s ; [[ $s != [oc] ]] || val=1 ;;
      *) # q: the bare option before this word, if it may take a value
        isv=0
        case $q in
          n|x) [[ $a == *[!0-9]* ]] || isv=1 ;;
          k) t=$a, isv=1    # col[letters][,col[letters]]..., col a number or -number
            while [ -n "$t" ] ; do
              p=${t%%,*} t=${t#*,} ; p=${p#-} ; d=${p%%[!0-9]*}
              [ -n "$d" ] || { isv=0 ; break ;}
              p=${p#"$d"} ; [ -z "${p//[dfgHinrvx]/}" ] || { isv=0 ; break ;}
            done ;;
        esac
        [ "$isv" -eq 1 ] || break
        q= ;;
    esac
  done
  [ "$both" -eq 0 ] || {
    printf '>>> cksh : --fn and --bin cannot be combined (6af8d53b)\n' >&2 ; return 1 ;}
  # hand over to a binary on PATH, else do the work here
  [ "$want" = fn ] || { read -r b < <(type -P cksh) || : ;}
  [ "$want" != bin ] || [ -n "$b" ] || {
    printf '>>> cksh : --bin allows only the cksh binary, and none is on PATH (6af8d53a)\n' >&2
    return 2 ;}
  [ -z "$b" ] || { command "$b" "$@" ; return ;}
  (
  local kre='^-?[0-9]+[dfgHinrvx]*(,-?[0-9]+[dfgHinrvx]*)*$'
  set +e ; set -uo pipefail ; IFS=$' \t\n'       # own the subshell's state
  export LC_ALL=C
  local _CKSH_USAGE= _CKSH_MANUAL= _CKSH_REV='cksh r0.6 6af8d530 (bash function)'

{ IFS= read -r -d '' _CKSH_USAGE || : ;} <<'__CKSH_USAGE__'
usage: cksh [-rLZ] [-n[0-5]] [-x[0-128]] [-k [col[r][,col[r]]...]]
            [-o output] [-c listing | [--] file ...]
       cksh -h | --help | --man | -V | --version   (--fn | --bin: --help)
  One line per file: inode links hash size mdate name, numbers in hex.
  Names come from the arguments, or one per line from standard input.
  -n[N]  omit the first N columns, 0-5; each prints as a dot
         (default 2; -n alone is -n0)
  -x[N]  hash length in hexadecimal characters, 0-128; 0 skips hashing
         (default 6, the hash shake256-6; -x alone is -x0)
  -k5,4  sort by column 5, then 4, then the remaining columns in order.
         Numbers compare by value; the hash and the name as bytes.
  -k     alone: sort by name
  -k5r   r reverses that column; -r reverses every column written
         without a letter. -r without -k reverses input order.
  -L     follow symlinks: the line is that of the file a link leads to
  -Z     end lines, and names on standard input, with NUL, not newline
  -o output   write the result to output, renamed into place when done
  -c listing  check a saved listing: write the line of each file that
              differs from it; exit status 64 if any does
  --help  full manual
__CKSH_USAGE__

{ IFS= read -r -d '' _CKSH_MANUAL || : ;} <<'__CKSH_MANUAL__'
NAME

    cksh - sortable stat and SHAKE256 listing of files

SYNOPSIS

    cksh [-rLZ] [-n[0-5]] [-x[0-128]] [-k [col[r][,col[r]]...]]
         [-o output] [-c listing | [--] file ...]
    cksh -h | --help | --man | -V | --version
    cksh --fn ... | cksh --bin ...

DESCRIPTION

    For each file, or for each line of standard input when no file is
    given, cksh writes one line of six columns. Numbers are lowercase
    hexadecimal, padded to a least width so that ordinary values line
    up:

           inode lk hash       size    mdate name
          1cc01d  1 483366        3 5e0bd2c0 t/a
          1cc01c  2 000000     1000 5e0bd2c0 t/d/
          1cc01f  1 483366        1 5e0bd2c0 t/l@

    The heading is shown for reference; cksh does not write it.

      1 inode  inode number of the node itself; a symlink is not
               followed
      2 lk     hard link count
      3 hash   shake256-N of the content, N hexadecimal characters
               (see HASH); zeros for a directory and for any node
               that is not hashed
      4 size   size in bytes; a symlink reports its own size
      5 mdate  modification time in seconds since the epoch; a time
               before 1970 is written with a minus sign, -12cf8700
      6 name   as given, with an indicator in the manner of ls -F:
               / directory  @ symlink  | fifo  = socket
               A directory named with a trailing slash keeps the one.

    Columns are words, as $1, $2 ... are in awk. An omitted column is
    written as a dot, so the column numbers never shift and the name
    always begins at column 6. Widths are not significant: a value
    wider than its column moves the rest of that line and nothing
    else. The name runs to the end of the line, blanks included:
        awk '{print substr($0, index($0,$6))}'

    A symlink reports its own inode, links, size and mdate, and the
    hash of the content it leads to. With -L it reports the file it
    leads to in every column.

    Without -k or -r each line is written as its file is read. With
    either, the lines are held until the last file is read.

OPTIONS

    -n[N]
        Omit the first N columns, 0 to 5. Default 2: inode and links
        are omitted, since they differ between copies of the same
        tree. From -n3 up the hash is omitted and no file is read.
        -n alone is -n0, every column.
    -x[N]
        Length of the hash in hexadecimal characters, 0 to 128.
        Default 6. -x alone is -x0, which skips hashing: column 3 is
        a dot and no file is read. See HASH.
    -k [col[r][,col[r]]...]
        Sort. See KEYS.
    -r  With -k, reverse every column written without a letter of
        its own. Without -k, write the lines in reverse input order.
    -L  Follow symlinks. The line of a symlink is the line of the
        file it leads to: that file's inode, links, size, mdate and
        indicator, under the name given. A link that leads nowhere
        is listed as the link it is, with @.
    -Z  End each line with NUL instead of newline, and read the names
        on standard input, and the records of a -c listing, as ended
        by NUL, so a name may hold a newline. Names are written as
        they are, even to a terminal. It is the -Z of ff before cksh
        and the -z of srt after it.
    -o output
        Write the result to output and not to standard output. The
        result is written beside the destination, synced, given the
        mode the destination had (or the mode a new file would get),
        and renamed over it when the run is complete, so a failed or
        interrupted run leaves the original as it was, and output
        may be one of the files listed. A destination that exists
        and is not a regular file, a device or a fifo, is written to
        directly. A directory is refused.
    -c listing
        Check: read a saved listing and write the line of each file
        that no longer matches it. See CHECK. listing may be - for
        standard input. No file may be named with -c.
    --  End of options; the words that follow are files.

    -h  Print a usage summary.
    --help
        Print this manual. When standard output is a terminal it is
        shown as a man page, with its headings in bold, through the
        formatter of the host: mandoc, else nroff with a pager
        (PAGER, else less, else more). Where neither is found the
        text is shown through the pager alone. To a pipe or a file
        it is written plain.
    --man
        Print the manual as man page source. cksh.1 is this output.
    -V, --version
        Print the revision.
    --fn, --bin
        Choose between the two forms of cksh, the binary and the bash
        function. --fn allows only the function: the function then
        never hands over to a binary, and the binary, given --fn,
        stops with an error. --bin allows only the binary: the
        function hands over to the binary on PATH and stops with an
        error if there is none; the binary accepts --bin and does
        nothing. See BASH FUNCTION.

    The value of -n, -x and -k may be joined to its option (-n0,
    -x64, -k5,4) or be the next word. The next word is taken as the
    value only when it reads as one: digits for -n and -x, a column
    list for -k. Any other word leaves the option alone and is a
    file, so
        cksh -n *        cksh -x *        cksh -k *
    mean -n0, -x0 and sort by name. For a file named like a number,
    write ./5 or put -- before it. -o and -c always take a value,
    joined or the next word whatever it is. Options end at the first
    file.

    Retired: -0 to -5 (write -n0 to -n5), and -krN (write -kNr).

KEYS

    -k [col[r][,col[r]]...]
        Sort by the named columns in the order given, then by the
        remaining columns left to right. -k5,4 compares in column
        order 5,4,1,2,3,6. -k5 -k4 is the same as -k5,4. Naming a
        column twice is an error. Columns are 1 to 6; counting from
        the end (-k-1) is not accepted.

        -k with no list names no column, and sorts by name: column
        6, then 1 to 5.

        cksh knows the type of each column. Inode, links, size and
        mdate compare as numbers, by value, whatever their width;
        the hash and the name compare as bytes, and no locale is
        consulted. The name is the last column and is compared to
        the end of the line. An omitted column, a dot, is a null
        column: it compares equal in every line, so a key on it
        orders nothing and the next column decides.

        Records equal in every column keep their input order.

    Letters. r after a column reverses that column. x is accepted
    on columns 1, 2, 4 and 5 and changes nothing: it is the letter
    srt needs there, so a list written for srt can be given to cksh.
    Any other letter is refused, since the types are fixed.

    Reverse has two spellings. -k5r reverses column 5 alone. -r
    reverses every column that is written without a letter, named or
    not. As in srt, a letter on a column replaces -r for that column:
        cksh -k5r        newest first; within one second, ascending
        cksh -r -k5      newest first; within one second, descending
        cksh -r -k5x     column 5 ascending, the others descending

    The same order from srt. cksh -k5,4,6 writes what
        cksh | srt -k5x,4x,6,1x,2x,3
    writes: every column named, each numeric column marked x. In
    general, give srt the cksh list, then the remaining columns, with
    x on 1, 2, 4 and 5.

CHECK

    cksh -c listing reads a listing that cksh wrote and examines
    again each file it names. A file that matches its record is
    passed over in silence. A file that differs is written as it is
    now, in the columns of its record, and the exit status carries
    64. So the output of a check is itself a listing, of what
    changed, and no output with status 0 means nothing did.

    Each record is checked as it was made. Its dots say which
    columns were omitted, and those are not compared; the width of
    its hash says which shake256-N to compute, and a dot there means
    the file is not read. -n and -x are therefore not consulted, and
    a listing may mix records made in different ways. -L and -Z must
    be given again if the listing was made with them.

    A record differs when any column it holds differs: the hash, the
    size, the mdate, and the inode and links if listed; or when the
    indicator differs, a file where a directory was. A file that is
    gone is an error, cannot stat, with status 4 and no line.

    The file of a record is its name less the indicator. Where a
    name ends in one of / @ | = of its own, the file is the one that
    gives the record's name back. Between the last column and the
    name exactly one blank is skipped, so a name that begins with a
    blank is kept; a listing whose blanks were squeezed by another
    tool loses such names. A record of fewer than six words stops
    the run with status 1.

    -k, -r and -o apply to what is written. To see what a record
    was beside what it is, join the two on the name, or diff the
    listing against a new one.

HASH

    Column 3 is SHAKE256 (FIPS 202) of the content, cut to N
    hexadecimal characters, and that hash is named shake256-N. The
    default is shake256-6; -x64 gives shake256-64. N is the width of
    the column, so length($3) names the hash of any listing.

    SHAKE256 is an extendable-output function: a shorter output is
    the beginning of every longer one. The shake256-6 of a file is
    the first six characters of its shake256-64, and of the output of
        openssl shake256 -xoflen 32 -hex
    where -xoflen counts bytes, two characters each. An odd N is the
    even length above it, less the last character.

    The name is written with a hyphen and never with a slash. A slash
    after SHAKE256 is read in three ways, and the default hash of
    cksh would be each of these to a different reader:
        SHAKE256/24    24 bits, as the standard counts output
        SHAKE256/3     3 bytes, as openssl -xoflen counts
        SHAKE256/6     6 hexadecimal characters
    Whichever one is written, readers of the other two misread it.
    cksh -x counts hexadecimal characters, and the hash is written
    shake256-6: one number for the option, the name and the column.

    shake256-6 suits change and integrity checks among one's own
    files. Use -x64 or more where a collision must be infeasible.

    The binary computes SHAKE256 itself and needs no other program.

TERMINAL

    When standard output is a terminal, C0 and C1 control characters,
    DEL, and bytes that are not valid UTF-8 are written in a name as
    \ooo octal escapes, so a crafted name cannot drive the terminal.
    To a pipe or a file, and under -Z, names are written as they
    are. Names in diagnostics follow the same rule, by standard
    error.

BASH FUNCTION

    cksh.fn.bash defines a shell function named cksh, for hosts where
    the binary is not installed. When a binary named cksh is on PATH
    the function runs it, unless --fn is given; with --bin it runs
    the binary or stops with status 2. Sourcing the file defines that
    one name and nothing else.

    The function takes the same options and writes the same bytes.
    Where it differs:
      - It hashes with openssl shake256, preferring
        $LOCALBASE/bin/openssl to the one on PATH, and checks it
        against the known hash of empty input. An openssl without
        -xoflen limits -x to 64; one without shake256 is status 2.
        -x0 needs no openssl.
      - It reads file data through stat(1), in the forms of Linux,
        Darwin and NetBSD. Elsewhere it stops with status 2.
      - With -k, where the sort of the host has no -z, a name
        containing a newline is status 2.
      - A NUL in a line of standard input is dropped, not reported.
      - -o is written beside the destination and renamed, but is not
        synced first; it needs mktemp(1).
      - Diagnostics omit the system's reason, and a node that changes
        during the scan is not detected.
      - It runs several programs per file and is much slower.

ENVIRONMENT

    PAGER      pager for --help.
    LOCALBASE  the bash function looks for openssl in $LOCALBASE/bin
               first.
    LANG and LC_* are not consulted.

EXIT STATUS

    A bitmask. 1 and 2 are fatal and are returned alone; the others
    accumulate while the run continues.
       0  success; with -c, every file matches its record
       1  invalid option or argument; nothing is read. Also a -c
          record that is not a cksh line
       2  environment: out of memory, or a failure of standard input
          or output, which can come in the middle of a run; a -c
          listing or -o output that cannot be opened; --bin with no
          binary; in the function, no usable openssl or stat
       4  cannot stat a name; line skipped
       8  cannot open or read a regular file; line skipped
      16  fifo, socket or device, never opened; or a node that
          changed during the scan; warned, hash zeros
      32  dangling symlink; warned, hash zeros
      64  with -c, a file differs from its record
    For example 52 is 4, 16 and 32: a missing name, a fifo and a
    dangling link.

DIAGNOSTICS

    On standard error, errors as '>>> cksh : ...' and warnings as
    '^^^ cksh : ...', each ending in a hexadecimal tag that names the
    message.

EXAMPLES

  Columns

    cksh *                             hash, size, mdate, name
    cksh -n *                          every column, inode and links too
    cksh -n3 *                         size, mdate, name; nothing read
    cksh -n5 *                         names with their indicators
    find . -type f | cksh              names from standard input
    cksh -L *                          links as the files they lead to

  Hash

    cksh -x64 file                     shake256-64, the 256 bit hash
    cksh -x file                       no hash; the file is not read
    cksh -x64 -n file                  shake256-64 with inode and links

  Sort

    cksh -k *                          by name
    cksh -k5 *                         by time, oldest first
    cksh -k5r *                        newest first
    cksh -k5,4 *                       by time, then size, then the rest
    cksh -k4r,6 *                      largest first, then by name
    cksh -n3 -k4 *                     sizes, smallest first
    find . -type f | cksh -k3          files of the same content together
    cksh -r *                          the arguments in reverse order
    cksh -rk *                         by name, descending

  Save and check

    find . -type f | cksh -k -o tree.ck
                                       a listing, written whole or not
                                       at all
    cksh -c tree.ck                    the files that changed since;
                                       nothing, and status 0, if none
    cksh -c tree.ck -o changed.ck      the same, kept
    cksh -c tree.ck >/dev/null || echo changed
                                       as a test
    cksh -k -o list.ck * ; cksh -k -c list.ck
                                       a directory, list.ck among its
                                       own files

  With other tools

    ff . -t f | cksh -k5,4             files of a tree, by time and size
    cksh * | srt -k5x,4x,6,1x,2x,3     what cksh -k5,4,6 * writes
    find . -type f | cksh | srt -D -k3
                                       files whose hash repeats
    find a -type f | cksh -k > a.ck ; find b -type f | cksh -k > b.ck
                                       two trees, for diff or join
    ff -Z . -t f | cksh -Z | srt -z -k5x,4x
                                       NUL records end to end: any name
    find . -type f -print0 | cksh -Z -k | tr '\0' '\n'
                                       NUL in, sorted, lines out

  Forms

    cksh --bin -k5 *                   the binary, or an error
    cksh --fn -k5 *                    the bash function, even where the
                                       binary is installed

NOTES

    Names on standard input are read one per line, as they are:
    backslashes and blanks are kept, empty lines are skipped, and a
    name containing a newline can be given as an argument or, with
    -Z, on standard input. An empty argument is skipped.

SEE ALSO

    ff(1), srt(1)

REVISION

    r0.6.
__CKSH_MANUAL__

  local n=2 x=6 r=0 k=0 Z=0 L=0 zs=0 fmt='%s\n' rc=0 esc=0 eesc=0 buf=0 cnt=0 i=0 ac=$# j=0
  local w= p= c= arg= have=0 f= l= os= ssl= xo= o= ck= od= oid= t= REPLY=
  local o_line= o_name= o_key=                    # the record _cksh_one made
  local -a av=("$@") kc=() kr=() kl=(0 0 0 0 0 0 0) ord=() rev=() seen=(0 0 0 0 0 0 0)
  local -a disp=() keys=() sa=() rd=() hv=(0 0 0 0 0 0) o_f=() SL=()
  [ ! -t 2 ] || eesc=1

  # ---- names and diagnostics -------------------------------------------
  # REPLY: the name with C0, C1, DEL and bytes that are not valid UTF-8
  # as \ooo, the rule of the binary's put_name
  _cksh_esc(){ local s=$1 o= t= re='[^ -~]' i=0 n=${#1} b=0 c=0 c1=0 k=0 lo=0 hi=0 j=0 ok=0
    REPLY=$s ; [[ $s =~ $re ]] || return 0
    while ((i<n)) ; do
      printf -v b '%d' "'${s:i:1}" ; b=$((b&255)) ; k=0 lo=128 hi=191 ok=0
      ((b>=128)) || {
        { ((b<32||b==127)) && { printf -v t '\\%03o' "$b" ; o+=$t ;} ;} || o+=${s:i:1}
        i=$((i+1)) ; continue ;}
      case $b in
        19[4-9]|2[01][0-9]|22[0-3]) k=1 ;;
        224) k=2 lo=160 ;; 237) k=2 hi=159 ;; 22[5-9]|23[0-9]) k=2 ;;
        240) k=3 lo=144 ;; 24[1-3]) k=3 ;; 244) k=3 hi=143 ;;
      esac
      ((k==0||i+k>=n)) || { printf -v c1 '%d' "'${s:i+1:1}" ; c1=$((c1&255))
        ((c1<lo||c1>hi)) || { ok=1
          for ((j=2;j<=k;j++)) ; do
            printf -v c '%d' "'${s:i+j:1}" ; c=$((c&255)) ; ((c>=128&&c<=191)) || ok=0
          done ;} ;}
      # a valid sequence that is not a C1 control (c2 80..9f) passes
      { ((ok)) && ! ((b==194&&c1<=159)) ;} && { o+=${s:i:k+1} ; i=$((i+k+1)) ; continue ;} || :
      { ((ok)) && k=2 ;} || k=1
      for ((j=0;j<k;j++)) ; do
        printf -v c '%d' "'${s:i+j:1}" ; printf -v t '\\%03o' "$((c&255))" ; o+=$t
      done
      i=$((i+k))
    done
    REPLY=$o ;}
  # level what tag [name]: the chkerr and chkwrn form of the binary
  _cksh_msg(){ local nm=
    [ $# -lt 4 ] || { nm=$4 ; ((eesc==0)) || { _cksh_esc "$nm" ; nm=$REPLY ;} ; nm=" '$nm'" ;}
    printf '%s\n' "$1cksh : $2$nm ($3)" >&2 ;}
  _cksh_die(){ local st=$1 ; shift ; _cksh_msg '>>> ' "$@" ; exit "$st" ;}
  _cksh_put(){ printf '%s' "$1" 2>/dev/null || _cksh_die 2 'write error on stdout' 6ab7e736 ;}
  # one record, ended by newline, or by NUL under -Z
  _cksh_rec(){ printf "$fmt" "$1" 2>/dev/null || _cksh_die 2 'write error on stdout' 6ab7e736 ;}
  # the manual as man page source, the rule of the binary's roff()
  _cksh_roff(){ local l= n=0 s=0 b=0 re='^[A-Z][A-Z ]*$'
    printf '.TH CKSH 1\n'
    while IFS= read -r l ; do
      [[ ! $l =~ $re ]] || { b=0 ; ((n==0)) || printf '.fi\n' ; n=1
        printf '.SH "%s"\n.nf\n' "$l" ; s=1 ; continue ;}
      ((s==0)) || { s=0 ; [ -n "$l" ] || continue ;}
      [ -n "$l" ] || { b=$((b+1)) ; continue ;}
      [[ $l != '  '[!\ ]* ]] || { b=0 ; printf '.SS "%s"\n.nf\n' "${l:2}" ; s=1 ; continue ;}
      for ((;b>0;b--)) ; do printf '\n' ; done
      l=${l//\\/\\e} ; [[ $l != [.\']* ]] || l="\\&$l"
      printf '%s\n' "$l"
    done <<<"${_CKSH_MANUAL%$'\n'}"
    printf '.fi\n' ;}
  # --help: on a terminal the man page source through the formatter of
  # the host (mandoc, else nroff and a pager), else the text through a
  # pager; plain otherwise. Never through man(1): see the binary's help().
  _cksh_help(){ local pg= st=0 src=
    [ -t 1 ] || { _cksh_put "$_CKSH_MANUAL" ; exit 0 ;}
    src=$(_cksh_roff)
    for pg in 'command -v mandoc >/dev/null 2>&1 || exit 127; exec mandoc -a 2>/dev/null' \
        'command -v nroff >/dev/null 2>&1 || exit 127; nroff -c -man </dev/null >/dev/null 2>&1 || exit 127; p=${PAGER:-}; [ -n "$p" ] || { command -v less >/dev/null 2>&1 && p=less || p=more; }; nroff -c -man 2>/dev/null | sh -c "$p"' ; do
      printf '%s\n' "$src" 2>/dev/null | sh -c "$pg" ; st=${PIPESTATUS[1]}
      [ "$st" -ne 0 ] || exit 0
    done
    for pg in "${PAGER:-}" less more ; do
      [ -n "$pg" ] || continue
      printf '%s' "$_CKSH_MANUAL" 2>/dev/null | sh -c "$pg" ; st=${PIPESTATUS[1]}
      [ "$st" -eq 126 ] || [ "$st" -eq 127 ] || exit 0
    done
    _cksh_put "$_CKSH_MANUAL" ; exit 0 ;}

  # ---- options: the grammar and the messages of the binary ---------------
  # -k list: col[r|x...][,col...]
  _cksh_keys(){ local a=$1 s=$1 col= it= t= rv=0 j=
    [[ $s != r* ]] || _cksh_die 1 '-krN is not accepted, write -kNr or -r -kN; got -k' 6af8d532 "$a"
    while : ; do
      [[ $s != -* ]] || _cksh_die 1 '-k counts columns 1-6 from the left only, got' 6af8d535 "$a"
      [[ $s =~ ^[1-6]([^0-9]|$) ]] || _cksh_die 1 '-k requires columns 1-6, got' 6ab75460 "$a"
      col=${s:0:1} s=${s:1} ; it=${s%%,*} ; t=$it rv=0
      while [ -n "$t" ] ; do
        case ${t:0:1} in
          r) rv=1 ;;
          x) [[ $col != [36] ]] || _cksh_die 1 \
               '-k letter x is for the numeric columns 1 2 4 5; columns 3 and 6 are text, got' 6af8d537 "$a" ;;
          *) _cksh_die 1 '-k accepts the letters r and x only: column types are fixed, got' 6af8d533 "$a" ;;
        esac
        t=${t:1}
      done
      for j in ${kc[@]+"${kc[@]}"} ; do
        [ "$j" != "$col" ] || _cksh_die 1 '-k names a column twice, got' 6af8d534 "$a"
      done
      kc+=("$col") ; kr+=("$rv") ; kl[col]=$(( ${#it} > 0 )) ; s=${s:${#it}}
      [ -n "$s" ] || return 0
      s=${s:1}
      [ -n "$s" ] || _cksh_die 1 '-k requires columns 1-6, got' 6ab75460 "$a"
    done ;}
  # strict decimal no greater than $2, as the binary's num(); REPLY: the value
  _cksh_num(){ [[ $1 =~ ^[0-9]{1,18}$ ]] && REPLY=$((10#$1)) && ((REPLY<=$2)) ;}
  while ((i<ac)) ; do
    w=${av[i]}
    [[ $w == -?* ]] || break
    [ "$w" != -- ] || { i=$((i+1)) ; break ;}
    case $w in
      --help) _cksh_help ;;
      --man) _cksh_roff 2>/dev/null || _cksh_die 2 'write error on stdout' 6ab7e736 ; exit 0 ;;
      --version) _cksh_put "$_CKSH_REV"$'\n' ; exit 0 ;;
      --fn|--bin) i=$((i+1)) ; continue ;;
      --*) _cksh_die 1 'invalid option' 6ab75461 "$w" ;;
    esac
    p=${w#-}
    while [ -n "$p" ] ; do
      c=${p:0:1} p=${p:1}
      case $c in
        r) r=1 ; continue ;;
        Z) Z=1 ; continue ;;
        L) L=1 ; continue ;;
        h) _cksh_put "$_CKSH_USAGE" ; exit 0 ;;
        V) _cksh_put "$_CKSH_REV"$'\n' ; exit 0 ;;
        [0-5]) _cksh_die 1 '-0 to -5 are retired, write -n0 to -n5; got' 6af8d531 "-$c" ;;
        n|x|k|o|c) : ;;
        *) _cksh_die 1 'invalid option' 68e9fa9a "-$c" ;;
      esac
      # the value: the rest of the word, or the next word: for -o and -c
      # whatever it is, for the others when it reads as one
      have=0 arg=
      [ -z "$p" ] || { arg=$p have=1 ;}
      ((have||i+1>=ac)) || {
        [[ $c == [oc] ]] || { [ "$c" = k ] && [[ ${av[i+1]} =~ $kre ]] ;} ||
        { [ "$c" != k ] && [[ ${av[i+1]} =~ ^[0-9]+$ ]] ;} && { i=$((i+1)) ; arg=${av[i]} have=1 ;} || : ;}
      case $c in
        n) n=0 ; ((have==0)) || { _cksh_num "$arg" 5 && n=$REPLY ;} ||
             _cksh_die 1 '-n requires 0-5, got' 68e9fbb2 "$arg" ;;
        x) x=0 ; ((have==0)) || { _cksh_num "$arg" 128 && x=$REPLY ;} ||
             _cksh_die 1 '-x requires 0-128, got' 68e9fc22 "$arg" ;;
        k) k=1 ; ((have==0)) || _cksh_keys "$arg" ;;
        o) [ -n "$arg" ] || _cksh_die 1 '-o requires an output file' 6af8d53c ; o=$arg ;;
        c) [ -n "$arg" ] || _cksh_die 1 '-c requires a listing' 6af8d53c ; ck=$arg ;;
      esac
      p=
    done
    i=$((i+1))
  done
  [ -z "$ck" ] || ((i>=ac)) ||
    _cksh_die 1 '-c takes its names from the listing; no file may be named, got' 6af8d53f "${av[i]}"

  # ---- environment: stat form, sort -z ----------------------------------
  read -r os < <(uname -s) || :
  ((L==0)) || SL=(-L)
  case $os in
    Linux) _cksh_stat(){ stat ${SL[@]+"${SL[@]}"} -c '%i %h %s %Y' -- "$1" ;}
           _cksh_mode(){ stat -L -c '%a' -- "$1" ;} ;;
    Darwin|NetBSD) _cksh_stat(){ stat ${SL[@]+"${SL[@]}"} -f '%i %l %z %m' -- "$1" ;}
           _cksh_mode(){ stat -L -f '%Lp' -- "$1" ;} ;;
    *) _cksh_die 2 'the function reads stat(1) of Linux, Darwin or NetBSD only; use the cksh binary' 6af8d539 ;;
  esac
  # key lines end in NUL where the sort of the host can read them so
  ((k==0)) || { sort -z </dev/null >/dev/null 2>&1 && zs=1 || : ;}

  # ---- -o: a temporary sibling of the destination, renamed at the end ----
  # literal class .cksh., kept directory and suffix; any other exit removes it
  trap '[ -z "$oid" ] || rm -f -- "$od/.cksh.$oid"' EXIT
  trap 'exit 130' INT HUP TERM
  [ -z "$o" ] || {
    [ ! -d "$o" ] || _cksh_die 1 '-o names a directory' 6af8d53d "$o"
    { [ -e "$o" ] && [ ! -f "$o" ] ;} && {
      # a device or a fifo is written through: a rename would destroy it
      { exec 1>"$o" ;} 2>/dev/null || _cksh_die 2 '-o: cannot write' 6af8d53e "$o" ;} || {
      od=. ; [[ $o != */* ]] || { od=${o%/*} ; [ -n "$od" ] || od=/ ;}
      t= ; read -r t < <(mktemp "$od/.cksh.XXXXXX" 2>/dev/null) || :
      oid=${t##*/.cksh.}
      { [ -n "$t" ] && [[ $oid =~ ^[A-Za-z0-9]+$ ]] ;} || { oid=
        _cksh_die 2 '-o: cannot write beside' 6af8d53e "$o" ;}
      # the mode the destination had, or the mode a new file would get
      t= ; { [ -f "$o" ] && read -r t < <(_cksh_mode "$o" 2>/dev/null) ;} || :
      [[ $t =~ ^[0-7]+$ ]] || { read -r t < <(umask) ; printf -v t '%o' "$((8#666 & ~8#$t))" ;}
      { chmod "$t" "$od/.cksh.$oid" && exec 1>"$od/.cksh.$oid" ;} 2>/dev/null ||
        _cksh_die 2 '-o: cannot write' 6af8d53e "$o" ;} ;}
  { [ -t 1 ] && ((Z==0)) && esc=1 ;} || :       # -Z: NUL records, names as they are
  ((Z==0)) || fmt='%s\0'

  ((n<=2)) || x=0                               # hash column omitted: read no file
  ((k==0&&r==0)) || buf=1
  for j in 1 2 3 4 5 ; do ((j<=n)) || { ((j==3&&x==0)) || hv[j]=1 ;} ; done

  # openssl: $LOCALBASE/bin first; verified by the known hash of empty input.
  # Called before the first hash: at once in a listing run, and in a check
  # run at the first record that holds one.
  _cksh_ssl(){ local a= h=
    [ -z "$ssl" ] || { { [ -n "$xo" ] || ((x<=64)) ;} || _cksh_die 2 "$ssl lacks -xoflen, -x limited to 64, got $x" 6ab75464
      return 0 ;}
    for a in ${LOCALBASE:+"$LOCALBASE/bin/openssl"} openssl ; do
      command -v "$a" >/dev/null 2>&1 && { ssl=$a ; break ;} || :
    done
    [ -n "$ssl" ] || _cksh_die 2 'openssl not found, use -x0 or the cksh binary' 6ab75462
    read -r h < <("$ssl" shake256 -xoflen 4 -hex </dev/null 2>/dev/null) || :
    { [[ $h =~ =\ 46b9dd2b$ ]] && xo=1 ;} || {
      read -r h < <("$ssl" shake256 -hex </dev/null 2>/dev/null) || :
      [[ $h =~ =\ 46b9dd2b[0-9a-f]{56}$ ]] ||
        _cksh_die 2 "$ssl lacks shake256, use -x0 or the cksh binary" 6ab75463
      ((x<=64)) || _cksh_die 2 "$ssl lacks -xoflen, -x limited to 64, got $x" 6ab75464 ;} ;}
  [ -n "$ck" ] || ((hv[3]==0)) || _cksh_ssl

  # ---- one file ------------------------------------------------------------
  # the indicator of a name, as ls -F; with -L a link is a link only when
  # it leads nowhere; a directory named with a trailing slash keeps the one
  _cksh_sfx(){ REPLY=
    { { ((L==0)) || [ ! -e "$1" ] ;} && [ -L "$1" ] && REPLY=@ ;} ||
      { [ -d "$1" ] && { [[ $1 == */ ]] || REPLY=/ ;} ;} ||
      { [ -p "$1" ] && REPLY='|' ;} || { [ -S "$1" ] && REPLY='=' ;} || : ;}
  # Make the record of $1 under the columns hv and the hash length x:
  # o_f (five words, unpadded), o_line (display), o_name and o_key.
  # Returns 1 with the reason reported and rc set.
  _cksh_one(){ local f=$1 ino= lnk= sz= mt= h=. s= t= m= z= f1=. f2=. f4=. f5=. nm=
    read -r ino lnk sz mt < <(_cksh_stat "$f" 2>/dev/null) || :
    # a link that leads nowhere is the link itself, with -L as without
    { ((L==0)) || [ -n "$ino" ] ;} || read -r ino lnk sz mt < <(SL=() ; _cksh_stat "$f" 2>/dev/null) || :
    [[ "$ino $lnk $sz $mt" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ -?[0-9]+$ ]] || {
      _cksh_msg '>>> ' 'cannot stat' 6ab75465 "$f" ; rc=$((rc|4)) ; return 1 ;}
    ((hv[3]==0)) || { printf -v z '%0*d' "$x" 0 ; h=$z t=reg
      [ ! -L "$f" ] || [ -e "$f" ] || t=dangling
      [ "$t" != reg ] || [ ! -d "$f" ] || t=dir
      [ "$t" != reg ] || [ -f "$f" ] || {
        { [ -p "$f" ] && t=fifo ;} || { [ -S "$f" ] && t=socket ;} || t='special file' ;}
      case $t in
        dangling) _cksh_msg '^^^ ' 'dangling symlink, not hashed' 6ab75466 "$f" ; rc=$((rc|32)) ;;
        dir) : ;;
        reg) h=
          read -r h < <({ "$ssl" shake256 ${xo:+-xoflen "$(((x+1)/2))"} -hex <"$f" ;} 2>/dev/null) || :
          h=${h##* } ; h=${h:0:x}
          { [[ $h =~ ^[0-9a-f]+$ ]] && [ "${#h}" -eq "$x" ] ;} || {
            _cksh_msg '>>> ' 'cannot read' 6ab75467 "$f" ; rc=$((rc|8)) ; return 1 ;} ;;
        *) _cksh_msg '^^^ ' "$t, not hashed" 6ab75468 "$f" ; rc=$((rc|16)) ;;
      esac ;}
    # omitted columns hold 0, so they compare equal under -k
    ((hv[1])) || ino=0 ; ((hv[2])) || lnk=0 ; ((hv[4])) || sz=0 ; ((hv[5])) || mt=0
    _cksh_sfx "$f" ; s=$REPLY
    ((hv[1]==0)) || printf -v f1 '%8x' "$ino"
    ((hv[2]==0)) || printf -v f2 '%2x' "$lnk"
    ((hv[4]==0)) || printf -v f4 '%8x' "$sz"
    ((hv[5]==0)) || { { ((mt<0)) && printf -v f5 '%s%07x' - "$((-mt))" ;} || printf -v f5 '%08x' "$mt" ;}
    o_name=$f$s ; nm=$o_name ; ((esc==0)) || { _cksh_esc "$nm" ; nm=$REPLY ;}
    o_f=("${f1##* }" "${f2##* }" "$h" "${f4##* }" "$f5") ; o_line="$f1 $f2 $h $f4 $f5 $nm"
    # mdate is signed: 0 prefix for negative (biased by 2^63), 1 otherwise
    { ((mt<0)) && printf -v m '0%019d' "$((9223372036854775807+mt+1))" ;} || printf -v m '1%019d' "$mt"
    printf -v o_key '%020u %020u %s %020u %s' "$ino" "$lnk" "$h" "$sz" "$m" ;}
  # write the record now, or hold it with its key line for -k or -r
  _cksh_emit(){
    ((buf)) || { _cksh_rec "$o_line" ; return 0 ;}
    ((k==0||zs==1)) || [[ $o_name != *$'\n'* ]] ||
      _cksh_die 2 'a name with a newline under -k needs sort -z or the cksh binary, got' 6af8d538 "$o_name"
    disp[cnt]=$o_line ; keys[cnt]="$o_key $cnt $o_name" ; cnt=$((cnt+1)) ;}
  _cksh_file(){ [ -z "$1" ] || { _cksh_one "$1" && _cksh_emit ;} || : ;}

  # ---- -c: a listing read back against the files it names -----------------
  # One record: five words, one blank, the name to the end. Its dots say
  # which columns it holds and the width of its hash which shake256-N, so
  # it is checked as it was made. The file is the name less its indicator,
  # or the name itself where that gives the record's name back.
  _cksh_check(){ local ln= rest= w= nm= pick= c= d=0 no=0 j=0 bl=$' \t'
    local -a lw=() cand=()
    while IFS= read -r ${rd[@]+"${rd[@]}"} ln || [ -n "$ln" ] ; do
      no=$((no+1)) ; [ -n "$ln" ] || continue
      rest=$ln ; lw=()
      for j in 1 2 3 4 5 ; do
        rest=${rest#"${rest%%[!$bl]*}"} ; w=${rest%%[$bl]*}
        { [ -n "$w" ] && [ "$w" != "$rest" ] ;} || break
        lw+=("$w") ; rest=${rest#"$w"} ; rest=${rest:1}
      done
      nm=$rest
      { ((${#lw[@]}==5)) && [ -n "$nm" ] && ((${#lw[2]}<=128)) ;} ||
        _cksh_die 1 "-c: record $no is not a cksh line, in" 6af8d541 "$ck"
      for j in 1 2 3 4 5 ; do hv[j]=1 ; [ "${lw[j-1]}" != . ] || hv[j]=0 ; done
      x=0 ; ((hv[3]==0)) || { x=${#lw[2]} ; _cksh_ssl ;}
      cand=() ; { ((${#nm}>1)) && [[ $nm == *[/@\|=] ]] && cand+=("${nm%?}") ;} || : ; cand+=("$nm")
      pick=
      for c in "${cand[@]}" ; do                # one that gives the name back
        { [ -e "$c" ] || [ -L "$c" ] ;} || continue
        _cksh_sfx "$c" ; [ "$c$REPLY" != "$nm" ] || { pick=$c ; break ;}
      done
      [ -n "$pick" ] || for c in "${cand[@]}" ; do  # else one that exists
        { [ -e "$c" ] || [ -L "$c" ] ;} && { pick=$c ; break ;} || :
      done
      [ -n "$pick" ] || { _cksh_msg '>>> ' 'cannot stat' 6ab75465 "$nm" ; rc=$((rc|4)) ; continue ;}
      _cksh_one "$pick" || continue
      d=0 ; [ "$o_name" = "$nm" ] || d=1
      for j in 0 1 2 3 4 ; do ((hv[j+1]==0)) || [ "${o_f[j]}" = "${lw[j]}" ] || d=1 ; done
      ((d==0)) || { rc=$((rc|64)) ; _cksh_emit ;}
    done ;}

  # ---- names from the listing, the arguments, or standard input -----------
  ((Z==0)) || rd=(-d '')
  t=stdin ; ((i>=ac)) || t=args ; [ -z "$ck" ] || t=check ; [ "$t$ck" != check- ] || t=checkin
  case $t in
    checkin) _cksh_check ;;
    check) { [ -r "$ck" ] && [ ! -d "$ck" ] ;} || _cksh_die 2 '-c: cannot read the listing' 6af8d540 "$ck"
      _cksh_check < "$ck" ;;
    args) for ((;i<ac;i++)) ; do _cksh_file "${av[i]}" ; done ;;
    stdin) while IFS= read -r ${rd[@]+"${rd[@]}"} f || [ -n "$f" ] ; do _cksh_file "$f" ; done ;;
  esac

  # ---- held lines: -r alone reverses input order; -k sorts ----------------
  ((buf==0||cnt==0||k==1)) || for ((j=cnt-1;j>=0;j--)) ; do _cksh_rec "${disp[j]}" ; done
  ((k==0||cnt==0)) || {
    # named columns in the order given, then the rest left to right; a bare
    # -k names none and the name leads. A column written with letters keeps
    # its own direction; -r reaches every other column.
    for ((j=0;j<${#kc[@]};j++)) ; do
      c=${kc[j]} ; ord+=("$c") ; seen[c]=1
      { ((kl[c])) && rev+=("${kr[j]}") ;} || rev+=("$r")
    done
    ((${#kc[@]})) || { ord+=(6) ; rev+=("$r") ; seen[6]=1 ;}
    for c in 1 2 3 4 5 6 ; do ((seen[c])) || { ord+=("$c") ; rev+=("$r") ;} ; done
    # key line: five fixed fields, the index, then the name to end of line
    sa=(-s -t ' ') ; rd=() ; p='%s\n'
    ((zs==0)) || { sa+=(-z) ; rd=(-d '') ; p='%s\0' ;}
    for ((j=0;j<6;j++)) ; do
      c=${ord[j]} ; w= ; ((rev[j]==0)) || w=r
      { ((c==6)) && sa+=(-k "7$w") ;} || sa+=(-k "$c,$c$w")
    done
    while IFS= read -r ${rd[@]+"${rd[@]}"} l ; do
      l=${l#* * * * * } ; _cksh_rec "${disp[${l%% *}]}"
    done < <(printf "$p" "${keys[@]}" | sort "${sa[@]}") ;}

  # ---- -o: the result into place -----------------------------------------
  [ -z "$oid" ] || { exec 1>&-
    { mv -f -- "$od/.cksh.$oid" "$o" 2>/dev/null && oid= ;} ||
      _cksh_die 2 '-o: cannot write' 6af8d53e "$o" ;}
  exit "$rc"
  )
}
