# srt.fn.bash --- srt, sort for system operators, as a bash function
#
# Source this file. It defines one name, the function srt, for hosts
# without the srt binary. When a binary named srt is on PATH the
# function runs it; --fn keeps the function and --bin requires the
# binary. Requirements and decisions: plan-srt.md.
#
# Method: every key is encoded by awk into a string whose byte order is
# srt order, the native sort compares those strings in the C locale
# (stable, bytes only, no native ordering option), and a last awk pass
# strips the keys. One mechanism on Linux, Darwin and NetBSD, so the
# function and the binary agree; test-srt.sh compares the two.
#
# Everything after the hand-over runs in a subshell opened inside srt.
# The helper functions (_srt_*), the awk program, the usage and manual
# text and every variable are defined in that subshell and end with it:
# sourcing this file adds srt to the calling shell and nothing else,
# and a call changes no option, trap, variable or function there.
#
# The usage and manual blocks are copies of the binary's -h and --help
# text; test-srt.sh fails if they drift. To refresh them after the
# manual changes in srt.c, replace the two blocks with the output of
# "./srt -h" and "./srt --help".
#
# revision 6af8a908 20261114 103136 PST Sat --- r0.6 -x, -D, last column
#          to end of record, bare -k, -k-N, -kr5 retired; follows the binary
# revision 6af889a5 20261114 081741 PST Sat --- r0.5.1 header order;
#          manual text follows the binary (-S with -u)
# revision 6af87ca7 20261114 072215 PST Sat --- r0.5 --fn and --bin replace
#          SRT_FN; manual text follows the binary
# revision 6af871c9 20261114 063553 PST Sat --- r0.4.2 manual text follows
#          the binary (owned IPv6 parser); no change to the translator
# revision 6af86b89 20261114 060913 PST Sat --- r0.4.1 one function:
#          every helper, variable and text block is inside srt
# revision 6af82211 20261114 005545 PST Sat --- r0.4 first issue
#
# (c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
srt(){ local b= a= s= c= want= skip=0 both=0 kb=0 t= p= d= ok=0
  # --fn or --bin among the options chooses the form. This pass knows
  # which options take a value, so in "-o --fn" the word is a file name;
  # it touches only its own locals.
  for a in "$@" ; do
    [ "$skip" -eq 0 ] || { skip=0 ; continue ;}
    # after a bare -k the next word is its key list only if it reads as
    # one: col[letters][,col[letters]]..., col a number or -number
    [ "$kb" -eq 0 ] || { kb=0 ; t=$a, ok=1
      while [ -n "$t" ] ; do
        p=${t%%,*} t=${t#*,} ; p=${p#-} ; d=${p%%[!0-9]*}
        [ -n "$d" ] || { ok=0 ; break ;}
        p=${p#"$d"}
        [ -z "${p//[dfgHinrvx]/}" ] || { ok=0 ; break ;}
      done
      [ "$ok" -eq 0 ] || continue ;}
    case $a in
      --) break ;;
      --fn) [ "$want" != bin ] || both=1 ; want=fn ;;
      --bin) [ "$want" != fn ] || both=1 ; want=bin ;;
      --output|--tmp-dir|--separator|--mem) skip=1 ;;
      --*|-) : ;;
      -?*) s=${a#-}
        while [ -n "$s" ] ; do
          c=${s%"${s#?}"} s=${s#?}
          case $c in
            k) [ -n "$s" ] || kb=1 ; break ;;
            t|o|T) [ -n "$s" ] || skip=1 ; break ;;
          esac
        done ;;
    esac
  done
  [ "$both" -eq 0 ] || {
    printf 'srt: --fn and --bin cannot be combined\nsrt: -h for usage, --help for the manual\n' >&2
    return 2 ;}
  # hand over to a binary on PATH, else translate
  [ "$want" = fn ] || { read -r b < <(type -P srt) || : ;}
  [ "$want" != bin ] || [ -n "$b" ] || {
    printf 'srt: --bin allows only the srt binary, and none is on PATH\n' >&2 ; return 2 ;}
  [ -z "$b" ] || { command "$b" "$@" ; return ;}
  (
  set +e ; set -uo pipefail ; IFS=$' \t\n'       # own the subshell's state
  export LC_ALL=C
  local _SRT_AWK= _SRT_REV='srt r0.6 6af8a908 (bash function)'

{ IFS= read -r -d '' _SRT_AWK || : ;} <<'__SRT_AWK__'
# One program, several modes (-v mode=):
#   max  print the largest column count          (exit 3: control bytes)
#   dec  print encoded-keys S2 original-record   (exit 3, 4: hex float)
#   und  strip the keys; with uniq, drop records whose keys repeat
#   chk  exit 1 and print the record number of the first disorder
#   rnd  print random-key S2 record
# Keys: ks = "col type f i r,..." in key order, options already
# resolved; g = "type f i r" global; type "-" is bytes. No apostrophe
# may appear anywhere in this program.
BEGIN {
  S1 = sprintf("%c", 1); S2 = sprintf("%c", 2)
  S3 = sprintf("%c", 3); S4 = sprintf("%c", 4)
  ctl = "[" S1 "-" S4 "]"
  ws = "^[ \t\r\n\f" sprintf("%c", 11) "]+"
  if (havet) sep = sprintf("%c", tsep)
  split(g, a, " ")
  gt = (a[1] == "-" ? "" : a[1]); gf = a[2] + 0; gi = a[3] + 0; gr = a[4] + 0
  nk = 0; maxpos = 0; anyneg = 0; attach = 0
  if (ks != "") {
    nk = splitc(ks, kk, ",")
    for (i = 1; i <= nk; i++) {
      split(kk[i], a, " ")
      kc[i] = a[1] + 0; kt[i] = (a[2] == "-" ? "" : a[2])
      kf[i] = a[3] + 0; ki[i] = a[4] + 0; kr[i] = a[5] + 0
      if (kc[i] < 0) anyneg = 1
      else { iskey[kc[i]] = 1; if (kc[i] > maxpos) maxpos = kc[i] }
    }
  }
  # the highest named column takes the rest of the record when it is
  # compared as text; not under -D, nor when a key counts from the end
  for (i = 1; i <= nk; i++)
    if (kc[i] == maxpos && maxpos && !anyneg && !dups)
      attach = (kt[i] == "" || kt[i] == "d" || kt[i] == "v")
  limit = (anyneg ? 0 : maxpos)
  whole = (nk == 0 && !havet)
  bad = 0; have = 0; mx = 0; havep = 0; pin = 0
  e0 = enc("", gt, gf, gi)
  if (mode == "rnd") srand(seed)
}

mode == "max" {
  if ($0 ~ ctl) { bad = 3; exit }
  if (!whole) { lay($0); if (NR_ > mx) mx = NR_ }
}

mode == "dec" {
  if ($0 ~ ctl) { bad = 3; exit }
  if (whole) out = enc($0, gt, gf, gi) S2
  else {
    lay($0)
    out = ""
    for (i = 1; i <= nk; i++) out = out enc(KV[i], kt[i], kf[i], ki[i]) S2
    # every record carries maxnf remaining columns, so a missing column
    # and an empty one are the same key, as in the binary
    r = ""
    for (c = 1; c <= maxnf; c++) r = r (c <= NR_ ? enc(RV[c], gt, gf, gi) : e0) S1
    out = out r S2
  }
  if (bad) exit
  print out $0
}

# strip the keys; -u drops a record whose keys all repeat; -D holds one
# record back until it is known whether the next shares its named keys
mode == "und" {
  s = $0; k = ""; gk = ""
  for (i = 0; i < nkf; i++) {
    p = index(s, S2); k = k substr(s, 1, p); s = substr(s, p + 1)
    if (i == nk - 1) gk = k
  }
  if (nk == 0) gk = k
  if (uniq) { if (have && k == pk) next; pk = k; have = 1 }
  if (!dups) { print s; next }
  if (havep) { eq = (gk == pgk); if (eq || pin) print pline; pin = eq }
  pline = s; pgk = gk; havep = 1
}

mode == "chk" {
  if ($0 ~ ctl) { bad = 3; exit }
  if (whole) { cn = 1; C[1] = enc($0, gt, gf, gi) }
  else {
    lay($0)
    for (i = 1; i <= nk; i++) CK[i] = enc(KV[i], kt[i], kf[i], ki[i])
    cn = NR_
    for (c = 1; c <= cn; c++) C[c] = enc(RV[c], gt, gf, gi)
  }
  if (bad) exit
  if (have) {
    d = 0
    for (i = 1; i <= nk && !d; i++) d = cmp(PK[i], CK[i], kr[i])
    m = (pn > cn ? pn : cn)
    for (c = 1; c <= m && !d; c++)
      d = cmp((c <= pn ? P[c] : e0), (c <= cn ? C[c] : e0), gr)
    if (d > 0 || (uniq && d == 0)) { print NR; bad = 1; exit }
  }
  pn = cn
  for (c = 1; c <= cn; c++) P[c] = C[c]
  for (i = 1; i <= nk; i++) PK[i] = CK[i]
  have = 1
}

mode == "rnd" {
  if (uniq) { if ($0 in seen) next; seen[$0] = 1 }
  printf "%.17f%s%s\n", rand(), S2, $0
}

END {
  if (bad) exit bad
  if (mode == "max") print mx
  if (mode == "und" && dups && havep && pin) print pline
}

function cmp(a, b, r,   d) {
  a = a ""; b = b ""
  d = (a < b ? -1 : (a > b ? 1 : 0))
  return (r ? -d : d)
}

# split s on the single character ch, literally; empty pieces are kept
function splitc(s, A, ch,   n, p) {
  n = 0
  while ((p = index(s, ch)) > 0) { A[++n] = substr(s, 1, p - 1); s = substr(s, p + 1) }
  A[++n] = s
  return n
}

# Columns of s into F. With no limit every word (every field under -t)
# is a column. With limit M, columns 1..M are words and what follows
# word M is one further column; TAIL is then word M and all after it.
function fields(s,   n, p) {
  TAIL = ""
  if (!limit) return (havet ? splitc(s, F, sep) : split(s, F))
  n = 0
  if (havet) {
    while (1) {
      if (n == limit - 1) TAIL = s
      p = index(s, sep)
      if (!p) { F[++n] = s; break }
      F[++n] = substr(s, 1, p - 1); s = substr(s, p + 1)
      if (n == limit) { F[++n] = s; break }
    }
    return n
  }
  while (1) {
    sub(/^[ \t]+/, "", s)
    if (s == "") break
    if (n == limit) { F[++n] = s; break }
    if (n == limit - 1) TAIL = s
    match(s, /^[^ \t]+/)
    F[++n] = substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1)
  }
  return n
}

# A record as the comparator sees it: KV[1..nk] the value of each named
# key, RV[1..NR_] the remaining columns in record order. A missing key
# is empty. The same construction as layout() in srt.c.
function lay(s,   n, i, c, at, k, skip) {
  n = fields(s)
  for (i = 1; i <= nk; i++) {
    at = (kc[i] > 0 ? kc[i] : n + 1 + kc[i])
    if (at < 1 || at > n) { KV[i] = ""; continue }
    KV[i] = (attach && kc[i] == maxpos ? TAIL : F[at])
  }
  NR_ = 0
  for (c = 1; c <= n; c++) {
    if (c in iskey) continue
    if (attach && c == maxpos + 1) continue
    if (anyneg) {
      skip = 0
      for (k = 1; k <= nk; k++) if (kc[k] < 0 && n + 1 + kc[k] == c) skip = 1
      if (skip) continue
    }
    RV[++NR_] = F[c]
  }
}

# order-preserving encoding of one key; direction is applied by the
# native sort (-k N,Nr) or by cmp(), never here
function enc(s, t, f, i) {
  if (t == "n") return numenc(s)
  if (t == "H") return humenc(s)
  if (t == "x") return hexenc(s)
  if (t == "g") return genc(s)
  if (t == "v") return venc(s, f)
  if (t == "d") {
    gsub(/[[:punct:]]/, "", s)
    if (!i) gsub(/\t/, "!", s)
    gsub(/[[:cntrl:]]/, "", s)
    if (!i) gsub(/!/, "\t", s)
  } else if (i) gsub(/[[:cntrl:]]/, "", s)
  if (f) s = toupper(s)
  return s
}

# nine-complement of the digits of s; other characters pass
function comp(s,   n, k, c, o) {
  n = length(s); o = ""
  for (k = 1; k <= n; k++) {
    c = substr(s, k, 1)
    o = o (c ~ /[0-9]/ ? substr("9876543210", c + 1, 1) : c)
  }
  return o
}

# -n: sets Nneg, Nint (no leading zeros), Nfrac (no trailing zeros),
# Nrest (what follows the number)
function numparse(s,   t) {
  sub(/^[ \t]+/, "", s)
  Nneg = 0
  if (substr(s, 1, 1) == "-") { Nneg = 1; s = substr(s, 2) }
  Nint = ""
  if (match(s, /^[0-9]+/)) { Nint = substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1) }
  Nfrac = ""
  if (substr(s, 1, 1) == ".") {
    t = substr(s, 2); s = t
    if (match(t, /^[0-9]+/)) { Nfrac = substr(t, 1, RLENGTH); s = substr(t, RLENGTH + 1) }
  }
  Nrest = s
  sub(/^0+/, "", Nint); sub(/0+$/, "", Nfrac)
  if (Nint == "" && Nfrac == "") Nneg = 0
}

function magenc() { return sprintf("%09d", length(Nint)) Nint "." Nfrac }

function numenc(s) {
  numparse(s)
  return (Nneg ? "0" comp(magenc()) "~" : "1" magenc())
}

function humenc(s,   c, r) {
  numparse(s)
  c = substr(Nrest, 1, 1)
  r = (c == "" ? 0 : index("KMGTPEZY", toupper(c)))
  return (Nneg ? "0" (8 - r) comp(magenc()) "~" : "1" r magenc())
}

# -x: hexadecimal integers; sign, digit count, digits in lower case
function hexenc(s,   neg, d, m) {
  sub(/^[ \t]+/, "", s)
  neg = 0
  if (substr(s, 1, 1) == "-") { neg = 1; s = substr(s, 2) }
  if (s ~ /^0[xX][0-9A-Fa-f]/) s = substr(s, 3)
  d = ""
  if (match(s, /^[0-9A-Fa-f]+/)) d = tolower(substr(s, 1, RLENGTH))
  sub(/^0+/, "", d)
  if (d == "") neg = 0
  m = sprintf("%09d", length(d)) d
  return (neg ? "0" comp16(m) : "1" m)
}

# fifteen-complement of the hexadecimal digits of s
function comp16(s,   n, k, o) {
  n = length(s); o = ""
  for (k = 1; k <= n; k++)
    o = o substr("fedcba9876543210", index("0123456789abcdef", substr(s, k, 1)), 1)
  return o
}

# -g: classes 0 not a number, 1 nan, 2 -inf, 3 finite, 4 +inf
function genc(s,   t, low, x, e, m, ex, p, neg) {
  t = s; sub(ws, "", t)
  if (t ~ /^[-+]?0[xX]\.?[0-9A-Fa-f]/) { bad = 4; return "" }
  low = tolower(t)
  if (low ~ /^[-+]?nan/) return "1"
  if (low ~ /^[-+]?inf/) return (substr(low, 1, 1) == "-" ? "2" : "4")
  if (!match(t, /^[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)?/)) return "0"
  x = substr(t, 1, RLENGTH) + 0
  if (x == 0) return "35"
  e = sprintf("%.17e", x)
  if (tolower(e) ~ /inf/) return (x < 0 ? "2" : "4")
  neg = (substr(e, 1, 1) == "-"); if (neg) e = substr(e, 2)
  p = index(e, "e")
  m = substr(e, 1, 1) substr(e, 3, p - 3)
  ex = substr(e, p + 1) + 0
  if (!neg) return "36" sprintf("%04d", ex + 1000) m
  return "34" comp(sprintf("%04d", ex + 1000) m)
}

# -v: IPv6 keys are class 1, by value then prefix length; all other
# keys are class 0, stem first, then the whole key
function venc(s, f) {
  if (f) s = toupper(s)
  if (index(s, ":") && ip6(s)) return "1" IPX sprintf("%03d", IPL + 1)
  return "0" nat(substr(s, 1, stem(s))) nat(s)
}

# natural order: a digit run becomes 0 <length> <digits>, which sorts
# among the digits; ~ becomes S3 and the end of the key S4, so that
# ~ < end < every other byte. The count of leading zeros of each run
# follows as the tie-break.
function nat(s,   n, k, c, o, tie, z, d) {
  n = length(s); o = ""; tie = ""; k = 1
  while (k <= n) {
    c = substr(s, k, 1)
    if (c ~ /[0-9]/) {
      z = 0
      while (k <= n && substr(s, k, 1) == "0") { z++; k++ }
      d = ""
      while (k <= n && (c = substr(s, k, 1)) ~ /[0-9]/) { d = d c; k++ }
      o = o "0" sprintf("%09d", length(d)) d
      tie = tie sprintf("%09d", z)
    } else { o = o (c == "~" ? S3 : c); k++ }
  }
  return o S4 tie S4
}

# length of s with a trailing run of .suffix components set aside
function stem(s,   i, j) {
  i = length(s)
  while (1) {
    j = i
    while (j > 0 && substr(s, j, 1) ~ /[0-9A-Za-z~]/) j--
    if (j == 0 || j == i || substr(s, j, 1) != ".") break
    if (substr(s, j + 1, 1) !~ /[A-Za-z~]/) break
    i = j - 1
  }
  return i
}

# hex groups of s into A, each padded to four digits; -1 if malformed
function grp(s, A,   n, i, x) {
  if (s == "") return 0
  n = splitc(s, A, ":")
  for (i = 1; i <= n; i++) {
    x = tolower(A[i])
    if (x !~ /^[0-9a-f][0-9a-f]?[0-9a-f]?[0-9a-f]?$/) return -1
    A[i] = substr("0000", 1, 4 - length(x)) x
  }
  return n
}

# whole key is an IPv6 address with optional /length: sets IPX (32 hex
# digits) and IPL (-1 when there is no length)
function ip6(s,   n, p, pl, k, v4, a, i, dc, head, tail, nh, nt, hx, H, T) {
  n = length(s); if (n < 2 || n >= 64) return 0
  IPL = -1
  p = index(s, "/")
  if (p) {
    pl = substr(s, p + 1); s = substr(s, 1, p - 1)
    if (pl !~ /^[0-9][0-9]?[0-9]?$/ || pl + 0 > 128) return 0
    IPL = pl + 0
  }
  if (index(s, ".")) {                    # dotted quad in the last 32 bits
    k = length(s)
    while (k > 0 && substr(s, k, 1) != ":") k--
    if (!k) return 0
    v4 = substr(s, k + 1); s = substr(s, 1, k)
    if (splitc(v4, a, ".") != 4) return 0
    for (i = 1; i <= 4; i++)
      if (a[i] !~ /^(0|[1-9][0-9]?[0-9]?)$/ || a[i] + 0 > 255) return 0
    s = s sprintf("%02x%02x:%02x%02x", a[1], a[2], a[3], a[4])
  }
  dc = index(s, "::")
  if (dc) {
    head = substr(s, 1, dc - 1); tail = substr(s, dc + 2)
    if (index(tail, "::")) return 0
  } else { head = s; tail = "" }
  nh = grp(head, H); if (nh < 0) return 0
  nt = grp(tail, T); if (nt < 0) return 0
  if (dc) { if (nh + nt > 7) return 0 } else if (nh != 8) return 0
  hx = ""
  for (i = 1; i <= nh; i++) hx = hx H[i]
  for (i = nh + nt; i < 8; i++) hx = hx "0000"
  for (i = 1; i <= nt; i++) hx = hx T[i]
  IPX = hx
  return 1
}
__SRT_AWK__

# ---- diagnostics (subshell only: these exit) --------------------------
_srt_bad(){ printf 'srt: %s\nsrt: -h for usage, --help for the manual\n' "$1" >&2 ; exit 2 ;}
_srt_die(){ printf 'srt: %s\n' "$1" >&2 ; exit 2 ;}
_srt_need(){ _srt_die "$1 needs the srt binary; the bash function does not provide it" ;}

# ---- ordering letters: act on the current set _o_t _o_f _o_i _o_r -----
_srt_ord(){
  case $1 in
    d|g|H|n|v|x) [ "$_o_t" = - ] || [ "$_o_t" = "$1" ] ||
        _srt_bad "ordering options -$_o_t and -$1 cannot apply to one key"
      _o_t=$1 ;;
    f) _o_f=1 ;; i) _o_i=1 ;; r) _o_r=1 ;;
    *) return 1 ;;
  esac ;}

# ---- -k col[opts][,col[opts]]... -> kcol[] kown[] kspec[] --------------
_srt_k(){ local s=$1 p=$1 col= c= own=0 x= neg=
  while : ; do
    neg= ; [[ $p != -[0-9]* ]] || { neg=- p=${p:1} ;}
    [[ $p != r[0-9]* ]] ||
      _srt_bad "-k $s: write the r after the column, as in -k${p:1}r, or use -r"
    [[ $p =~ ^([0-9]+)(.*)$ ]] || _srt_bad "-k $s: expected a column number"
    col=${BASH_REMATCH[1]} p=${BASH_REMATCH[2]}
    [ "${#col}" -le 9 ] || _srt_bad "-k $s: column number too large"
    col=$((10#$col))
    [ "$col" -gt 0 ] || _srt_bad "-k $s: columns count from 1, or from -1 at the end"
    col=$neg$col
    _o_t=- _o_f=0 _o_i=0 _o_r=0 own=0
    while [ -n "$p" ] && [ "${p:0:1}" != , ] ; do
      c=${p:0:1}
      [ "$c" != . ] || _srt_bad "-k $s: character offsets are not supported"
      _srt_ord "$c" || _srt_bad "-k $s: unknown key option '$c'"
      own=1 p=${p:1}
    done
    for x in ${kcol[@]+"${kcol[@]}"} ; do
      [ "$x" != "$col" ] ||
        _srt_bad "-k $s: column $col named twice (srt -k a,b means column a then column b)"
    done
    kcol+=("$col") kown+=("$own") kspec+=("$_o_t $_o_f $_o_i $_o_r")
    [ -n "$p" ] || break
    p=${p:1}
  done ;}

# ---- N[bkmg] -> _sz bytes ----------------------------------------------
_srt_size(){ local s=$1 what=$2 n= u=
  [[ $s =~ ^([0-9]+)([bBkKmMgG]?)$ ]] || _srt_bad "$what $s: expected N[bkmg]"
  n=${BASH_REMATCH[1]} u=${BASH_REMATCH[2]}
  [ "${#n}" -le 15 ] || _srt_bad "$what $s: too large"
  n=$((10#$n))
  [ "$n" -gt 0 ] || _srt_bad "$what $s: must be greater than zero"
  case $u in k|K) n=$((n << 10)) ;; m|M) n=$((n << 20)) ;; g|G) n=$((n << 30)) ;; esac
  _sz=$n ;}

# ---- one option; names are the binary's --------------------------------
_srt_set(){
  case $1 in
    c|C) check=$1 ;; u) uniq=1 ;; S|s|m) : ;; b) blocks=1 ;; R) rand=1 ;;
    D) dups=1 ;;
    Z) zero=1 ;;
    z) _srt_bad "-z is now -Z (NUL-terminated records)" ;;
    k) _srt_k "$2" ;;
    t) case $2 in
         '\t') tsep=9 ;;
         '\0') _srt_need "-t '\\0'" ;;
         ?) printf -v tsep '%d' "'$2"
            { [ "$tsep" -ge 5 ] && [ "$tsep" -le 127 ] && [ "$tsep" -ne 10 ] ;} ||
              _srt_need "-t with a byte outside ASCII 0x05-0x7f" ;;
         *) _srt_bad "-t $2: separator must be one byte, \\t or \\0" ;;
       esac ; havet=1 ;;
    o) out=$2 ;; T) tdir=$2 ;;
    MEM) _srt_size "$2" --mem ; mem=$_sz ;;
    V) printf '%s\n' "$_SRT_REV" ; exit 0 ;;
    h) _srt_usage ; exit 0 ;;
    HELP) _srt_help ; exit 0 ;;
    M|l) _srt_bad "option -$1 is not supported by srt (--help, DIFFERENCES)" ;;
    d|f|g|H|i|n|r|v|x)
      _o_t=$gt _o_f=$gf _o_i=$gi _o_r=$gr ; _srt_ord "$1"
      gt=$_o_t gf=$_o_f gi=$_o_i gr=$_o_r gset=1 ;;
    *) _srt_bad "unknown option -$1" ;;
  esac ;}

# ---- --name[=value]; sets _used=1 when the next argument was taken ----
_srt_long(){ local name=${1#--} val= has=0 code= need=0
  _used=0
  [[ $name != *=* ]] || { val=${name#*=} name=${name%%=*} has=1 ;}
  case $name in
    check) code=c ;; unique) code=u ;; version) code=V ;; help) code=HELP ;;
    respect-blanks) code=b ;; random) code=R ;; dictionary) code=d ;;
    fold-case) code=f ;; general-numeric) code=g ;; human-numeric) code=H ;;
    ignore-nonprinting) code=i ;; numeric) code=n ;; reverse) code=r ;;
    version-sort) code=v ;; zero-terminated) code=Z ;; stable) code=s ;;
    merge) code=m ;; duplicates) code=D ;; hex-numeric) code=x ;;
    fn|bin) [ "$has" -eq 0 ] || _srt_bad "option --$name takes no argument"
      return 0 ;;                        # already decided by srt itself
    output) code=o need=1 ;; tmp-dir) code=T need=1 ;;
    separator) code=t need=1 ;; mem) code=MEM need=1 ;;
    parallel|batch-size|compress-program|files0-from|debug|random-source|sort|\
qsort|mergesort|heapsort|radixsort|month-sort|buffer-size|key|field-separator|\
temporary-directory|ignore-case|ignore-leading-blanks|random-sort|numeric-sort|\
general-numeric-sort|human-numeric-sort|dictionary-order)
      _srt_bad "option --$name is not supported by srt (--help, DIFFERENCES)" ;;
    *) _srt_bad "unknown option --$name" ;;
  esac
  [ "$need" -eq 1 ] || {
    [ "$has" -eq 0 ] || _srt_bad "option --$name takes no argument"
    _srt_set "$code" '' ; return 0 ;}
  [ "$has" -eq 1 ] || {
    [ "$2" = 1 ] || _srt_bad "option --$name requires an argument"
    val=$3 _used=1 ;}
  _srt_set "$code" "$val" ;}

# ---- -h: the usage text, read only when asked for ----------------------
_srt_usage(){ local u=
{ IFS= read -r -d '' u || : ;} <<'__SRT_USAGE__'
usage: srt [-cCuDSbRZ] [-dfgHinrvx] [-k [col[opts][,col[opts]]...]]
           [-t char] [-o output] [-T dir] [--mem N[bkmg]] [file ...]
       srt -h | --help | -V | --version      (--fn | --bin: see --help)
  -c  check, report disorder on stderr   -C  check, exit status only
  -u  unique   -D  only duplicates   -S  allow unstable   -R  shuffle
  -b  outline sort: sort each block of equally indented lines
  -Z  NUL-terminated records
  -d dictionary  -f fold case  -g general numeric  -H human numeric
  -i ignore nonprinting  -n numeric  -r reverse  -v version  -x hex
  -k5,3  sort by column 5, then 3, then the remaining columns in order.
         Columns are words; -k-1 is the last. The highest column named
         runs to the end of the record when it is compared as text.
  -k5n,3r  letters on a column REPLACE the global options for that
           column: -n -k1r is reversed text; write -k1nr for numbers
  -t char  column separator (default: runs of blanks)
  --help  full manual
__SRT_USAGE__
  printf '%s' "$u" ;}

# ---- --help: pager on a terminal, plain otherwise ----------------------
_srt_help(){ local p= m=
{ IFS= read -r -d '' m || : ;} <<'__SRT_MANUAL__'
NAME

    srt - sort for system operators

SYNOPSIS

    srt [-cCuDSbRZ] [-dfgHinrvx] [-k [col[opts][,col[opts]]...]]
        [-t char] [-o output] [-T dir] [--mem N[bkmg]] [file ...]
    srt -h | --help | -V | --version
    srt --fn ... | srt --bin ...

DESCRIPTION

    srt sorts the records of all input files together and writes one
    result. With no file, or for the file name -, it reads standard
    input. The same input gives the same output on Linux, Darwin and
    NetBSD: order is by byte value and the locale environment is not
    consulted.

    The sort is stable: records that compare equal keep their input
    order, files in operand order.

    srt is not a drop-in for sort(1). Read DIFFERENCES before pointing
    an existing script at it.

OPTIONS

    -c, --check
        Check each input independently instead of sorting. For each
        input out of order, write one line to standard error:
            srt: name:line: disorder
        where line is the first record found out of order and standard
        input is named -. Nothing is written to standard output. Exit 1
        if any input is out of order. With -u, equal neighbours are a
        disorder too. Checking reads each input once and holds two
        records at a time.
    -C  As -c, with no report: exit status only.
    -o output, --output output
        Write the result to output. It may name an input file. The
        result is written beside the destination, synced, and renamed
        over it, so a failed run leaves the original intact.
    -T dir, --tmp-dir dir
        Directory for the spill file. Default: TMPDIR, then /var/tmp.
    --mem N[bkmg]
        Memory budget: bytes (b, the default), or k, m, g in powers
        of 1024. Overrides SRT_MEM. See MEMORY.
    -D, --duplicates
        Write only records whose named columns occur more than once:
        every member of every group of two or more records that
        compare equal on all the columns named in -k, each column
        under its own options. Groups come out together, in sorted
        order. With no -k the test is the whole record, so repeated
        lines are written. Under -D a named column is exactly its
        word (see THE LAST COLUMN). With -u, identical records are
        reduced to one first. Not combinable with -c, -C, -R or -b.
    -u, --unique
        Write only the first of each set of records that compare equal.
        Because every column takes part in comparison (see KEYS), this
        removes whole-record duplicates, as the ordering options see
        them.
    -S  Do not require a stable sort. Records that compare equal may
        come out in any order, and with -u any one of them may be the
        one kept; the choice can differ between hosts. Without -S the
        first in input order is kept, everywhere.
    -R, --random
        Shuffle: write the records in uniformly random order. This is
        not the hash-of-keys order of other sorts; equal records are
        not grouped. With -u, byte-identical records are removed.
        Not combinable with ordering options, -k, -b, -c or -C.
    -b, --respect-blanks
        Outline sort: lines that share a parent and an indent are
        sorted among themselves, and each line keeps the more deeply
        indented lines beneath it. See OUTLINE SORT.
    -Z, --zero-terminated
        Records end in NUL instead of newline, on input and output.
    -h  Print a usage summary.
    --help
        Print this manual, through a pager when standard output is a
        terminal (PAGER, else less, else more).
    -V, --version
        Print the revision.
    --fn, --bin
        Choose between the two forms of srt, the binary and the bash
        function. --fn allows only the function: the function then
        never hands over to a binary, and the binary, given --fn,
        stops with an error. --bin allows only the binary: the
        function hands over to the binary on PATH and stops with an
        error if there is none; the binary accepts --bin and does
        nothing. With neither, the function hands over when a binary
        named srt is on PATH and does the work itself otherwise.
        See BASH FUNCTION.
    -s, -m
        Accepted and ignored: stable order and multi-file input are
        already how srt behaves.

ORDERING OPTIONS

    -d, --dictionary
        Compare only blanks and alphanumerics. Bytes 0x80 and above
        are kept, so UTF-8 letters take part.
    -f, --fold-case
        Fold ASCII a-z to A-Z before comparing.
    -g, --general-numeric
        Compare as floating point, read by strtod: exponents, inf and
        nan are understood. Order: non-numbers, nan, then by value.
        Values are doubles; integers above 2^53 lose exactness. Use -n
        for exact comparison at any length.
    -H, --human-numeric
        Compare a number with an optional scale letter K M G T P E Z Y
        (either case): by sign, then scale, then number. The scale is
        not multiplied out, so 2048K sorts before 1M. Suited to the
        output of du -h and df -h.
    -i, --ignore-nonprinting
        Skip ASCII control bytes and DEL when comparing.
    -n, --numeric
        Compare by numeric value: optional blanks, optional -, digits,
        optional . and digits. No exponent, no thousands separator.
        A key with no leading number is zero. Exact at any length.
    -r, --reverse
        Reverse the comparison. Equal records still keep input order.
    -v, --version-sort
        See VERSION SORT.
    -x, --hex-numeric
        Compare as hexadecimal integers: optional blanks, optional -,
        optional 0x, then digits 0-9 and a-f in either case. Leading
        zeros do not count. Exact at any length. A key with no
        hexadecimal digit is zero. Under -x a word spelled from a-f
        is a number, so put the letter on the columns that hold
        hexadecimal (-k4x) rather than giving -x over mixed columns.

    At most one of -d -g -H -n -v -x applies to a column. See GLOBAL
    AND KEY OPTIONS for how these combine with -k.

KEYS

    -k [col[opts][,col[opts]]...]
        Sort by the named columns in the order given, then by the
        remaining columns left to right. For six columns, -k5n,3
        sorts in column order 5,3,1,2,4,6; -k5,3, where column 5 is
        text, sorts 5 and 6 as one column, then 3,1,2,4 (see THE
        LAST COLUMN). -k5 -k3 is the same as -k5,3.
        opts are ordering letters from dfgHinrvx. Naming a column
        twice is an error. Character offsets within a column are not
        supported.

        A column is a word, as $1, $2 ... are in awk: without -t,
        columns are separated by runs of spaces and tabs and leading
        blanks are ignored, so the widths and alignment of the input
        do not matter. Columns count from 1.

        A negative number counts from the end of the record: -k-1 is
        the last column, -k-2 the one before it. With -t/ the last
        column of a path is its base name.

        -k with no list names no column: the whole record is the key,
        which is what srt does with no -k at all. The word after -k
        is taken as the list only when it reads as one (5, or
        5x,4x,6, or -1); any other word is left as an option or a
        file. For a file named like a list, write ./5 or put --
        before it. To reverse, write the r after the column (-k5r)
        or give -r; -kr5 is not accepted.
    -t char, --separator char
        Columns are separated by each occurrence of char, so empty
        columns exist. char is one byte; \t and \0 are accepted.

    Two records that differ only in the amount of blank space between
    columns compare equal on those columns. A record with fewer
    columns than a key names has an empty key there. With neither -k
    nor -t the whole record is one key.

THE LAST COLUMN

    srt reads a record as far as -k names it. The highest column
    named is the last one; what follows its word is the rest of the
    record.
      - When that column is compared as text (no type letter, or d
        or v), it runs to the end of the record, blanks and all. In
        -k5x,4x,6 column 6 is a whole file name, spaces included.
      - When it is compared as a number (n g H x), it is its word
        alone, and the rest of the record is one further column,
        compared last. In -k5x,4x the name is that further column.
    Either way no part of a record is ignored. To sort on a later
    word in its own right, name its column.

    Two cases read every named column as exactly one word. Under -D
    the test is the named columns and nothing more, so the highest
    one is not extended; the rest of the record is still one further
    column, compared last. And when any column is counted from the
    end, every word of the record is a column and none is extended.

GLOBAL AND KEY OPTIONS

    An ordering option can be given in two places, and the place
    decides which columns it reaches.

    Global: an ordering option given on its own, as in -n or -fr,
    wherever it appears on the command line. The global options form
    one set.

    Key: ordering letters written directly after a column number
    inside -k, as in -k1r or -k5n,3fr. Each such column has its own
    set, made of exactly the letters written on it.

    Every column is compared with exactly one set:
      - a column named in -k WITH letters uses its own set, and the
        global set does not reach it at all;
      - a column named in -k with NO letters uses the global set;
      - the remaining columns, not named in -k, use the global set.

    Key letters replace the global set for their column. They are
    never added to it. This is the rule most often misread:

        srt -n -k1r

    Here column 1 carries a letter, so its set is {r} and nothing
    else. The global -n no longer reaches column 1. Column 1 is
    compared as text, reversed; the other columns are compared
    numerically. Given the records 2, 10 and 1 the result is
    2, 10, 1: reversed text order, because as text 2 sorts after 10.

    To compare column 1 numerically and reversed, write both letters
    on the column:

        srt -k1nr           column 1 numeric reversed, rest as text
        srt -n -k1nr        column 1 numeric reversed, rest numeric

    The same rule read the other way lets one column opt out of a
    global option:

        srt -r -k5n,3       column 5 numeric ascending (set {n});
                            column 3 and the rest reversed text
        srt -f -k2n         column 2 numeric (set {n}, not folded);
                            the other columns case-folded

    A column with no letters keeps the global set, so these two are
    the same, with every column numeric and reversed:

        srt -nr -k3,1
        srt -k3nr,1nr -nr

    The position of a global option on the command line does not
    matter: -n -k1r and -k1r -n are identical. This is also the rule
    of sort(1), where sort -n -k1,1r compares field 1 as reversed
    text.

OUTLINE SORT

    -b treats the input as an outline. The indent of a line is the
    exact run of spaces and tabs it begins with. Spaces and tabs may
    be mixed, but they are never converted or measured: two indents
    are the same only when they are the same bytes, and a tab is not
    equal to any number of spaces.

    Parent. A line belongs to the nearest line above it whose indent
    is a proper beginning of its own, provided no line in between has
    closed that block. A block is closed by the first following line
    whose indent does not begin with the block's indent. A line with
    no such parent is at the top level.

    Group. The children of one parent that have byte-identical
    indents form a group. Only a group is sorted; the ordering
    options, -k and -t apply to the line with its indent removed.
    Each line moves together with everything beneath it, and the
    lines beneath it are sorted in turn by the same rules. Children
    of one parent with different indents form separate groups, which
    stay in the order in which each group first appears.

    Blank lines (empty, or only spaces and tabs) are not sorted. Each
    stays directly below the line it follows and moves with it.

    Example. Given
        servers:
          web2
            port 80
          web1
            port 443
        clients:
          zeta
          alpha
    srt -b writes
        clients:
          alpha
          zeta
        servers:
          web1
            port 443
          web2
            port 80

    With -u, a line equal to the one kept before it in its group is
    removed only if nothing is beneath it and no blank line follows
    it; a line that carries a block is always kept, so -u never
    discards lines it did not compare.

    With -c or -C, every group must be in order.

    -b holds the whole input in memory. If the memory budget is
    reached srt stops with an error naming --mem, and writes nothing.
    -b cannot be combined with -R.

VERSION SORT

    -v orders version numbers, versioned archive names, host and
    interface names, and IPv4 and IPv6 addresses and networks.

    Runs of digits compare by numeric value at any length; all other
    bytes compare by value. So 9.255.0.1 < 10.2.0.1 < 10.10.0.1,
    10.0.0.0 < 10.0.0.0/8 < 10.0.0.0/16, and node2 < node10.

    Three refinements:
    1. A trailing run of suffixes such as .tar.gz (a dot, a letter,
       then letters and digits) is set aside. Stems compare first,
       whole keys break the tie: foo-1.2.tar.gz < foo-1.2.1.tar.gz.
    2. ~ sorts before everything, including the end of the key:
       1.0~rc1 < 1.0.
    3. A key that is an IPv6 address, with optional /length, compares
       by its 128-bit value, then by length; compression, leading
       zeros and letter case do not matter. IPv6 keys sort after all
       other keys, so a mixed column lists IPv4 first.

    Known differences from the version sort of other tools: 1.0.1
    sorts before 1.0a; numerically equal runs order by fewer leading
    zeros first (1.5 < 1.05); package epochs and release fields are
    not modelled. An address with a zone id (fe80::1%eth0), or with
    a leading zero in a dotted-quad octet (::1.2.3.04), is not taken
    as IPv6 and sorts as ordinary text; this is the same on every
    host and does not depend on the system library.

MEMORY

    Input that fits the memory budget is sorted in memory and no
    temporary file is created. When input exceeds the budget, srt
    sorts what it holds, appends it as a run to a spill file in the
    -T directory, and continues; at the end the runs are merged. The
    result is identical either way, including the order of equal
    records.

    The default budget is half of physical memory, lowered to half of
    any address-space or data resource limit; 1 GiB where physical
    memory cannot be queried. --mem or SRT_MEM sets it explicitly;
    values below 64k are raised to 64k. One record larger than the
    budget is still sorted; the budget decides when to spill, not how
    long a record may be.

    The spill file is unlinked as soon as it is created, so it never
    appears in a listing and is released on any exit. The -T file
    system needs free space about equal to the input, twice that when
    the runs must be merged in more than one pass. A full file system
    is an error, exit 2, and no partial result is written to -o.

    For a keyed sort, the keys of each batch held in memory are
    encoded once into byte strings that compare in srt order, within
    a quarter of the budget. A batch whose keys would need more is
    compared record by record instead; the result is the same.

    SRT_STATS=1 reports on standard error the budget, the number of
    runs and merge passes, and how many batches were sorted on
    encoded keys and how many by direct comparison.

BASH FUNCTION

    srt.fn.bash defines a shell function named srt, for hosts where
    the binary is not installed. When a binary named srt is on PATH
    the function runs it, unless --fn is given; with --bin it runs
    the binary or nothing.

    The function gives the same result as the binary. It encodes
    every key with awk so that the native sort(1), run in the C
    locale and comparing bytes only, puts the records in srt order;
    no ordering option of the native sort is relied on. It needs
    bash, awk, sort, cat, cp, mktemp and mv.

    Where the function differs from the binary:
      -b and -Z are not available; the function says so, exit 2.
      -t takes one ASCII character; \0 is not available.
      Input containing a byte from 0x01 to 0x04 is refused, exit 2.
      -g does not read hexadecimal floating point; refused, exit 2.
      -R draws from the awk generator, seeded by the shell per run.
      -S has no effect; the result is always stable.
      --mem and SRT_MEM are passed to the native sort where it has
          a memory option and are otherwise ignored; SRT_STATS is
          not available.
      The input is copied to the -T directory before it is sorted,
          and the function is much slower than the binary.

DIFFERENCES

    From the sort(1) of Linux, Darwin and NetBSD:
    -k a,b  is column a then column b, not fields a through b.
    -b      is outline sort, not ignore-leading-blanks.
    -S      is allow-unstable, not a memory size (use --mem).
    -R      is a true shuffle.
    -V      prints the revision; version sort is -v.
    -h      prints usage; human-numeric is -H.
    -k      with no list is accepted and names no column.
    -kN     reads column N as a word with its blanks dropped, where
            sort(1) keeps leading blanks in the field; and the highest
            column named takes the rest of the record.
    -x, -D and -k-N have no counterpart in sort(1).
    Not supported: character offsets in keys, +pos -pos, -M, -l,
    --parallel, --batch-size, --compress-program, --files0-from,
    --debug, --random-source, --sort, and algorithm selection.
    Locale collation is never applied.

ENVIRONMENT

    SRT_MEM    memory budget, as --mem.
    SRT_STATS  when set and not empty, report spill statistics.
    TMPDIR     spill directory when -T is not given.
    PAGER      pager for --help.
    LANG and LC_* are not consulted.

EXIT STATUS

    0  success; with -c or -C, every input is in order
    1  with -c or -C, some input is out of order
    2  error


EXAMPLES

  Columns
    srt -k5,3 table                    by column 5, then 3, then the rest
    srt -t: -k3n /etc/passwd           by uid, then the other fields
    ps aux | srt -k4nr,1               by memory descending, then user
    srt -n -k1r table                  column 1 as reversed TEXT, the rest
                                       numeric: letters on a column
                                       replace the global options
    srt -k1nr table                    column 1 numeric, descending
    srt -r -k5 table                   -r reaches a column named without
                                       letters: column 5 descending, and
                                       the rest; with letters write -k5xr
    srt -k table                       no column named: whole records

  Kinds of key
    srt -v hosts                       addresses, networks, host names
    ls | srt -v                        foo-1.2.tar.gz, then foo-1.10.tar.gz
    du -h | srt -Hr                    largest first
    srt -k2g readings                  1e-3, 0.5, 2.5e3 by value
    srt -k4x listing                   column 4 as hexadecimal: a3d, 187c,
                                       1c40a in that order, however the
                                       column is padded
    srt -f -k2n names                  column 2 numeric, the rest folded

  The last column
    srt -k5x,4x,6 listing              hex time, hex size, then the name:
                                       column 6 runs to the end of the
                                       record, so 'My File' is one key
    srt -k5x,4x listing                the same, with the name compared
                                       last, after the other columns
    ps aux | srt -k11                  by command line, arguments included

  Columns counted from the end
    srt -t/ -k-1 paths                 by base name, then by directory
    srt -t. -k-1 names                 by file suffix
    srt -k-1n table                    by the last column, as a number

  Duplicates
    srt -D lines                       lines that occur more than once
    srt -D -k3 listing                 records sharing column 3: files
                                       with the same hash, grouped
    srt -D -k3,4x listing              the same hash and the same size
    srt -t/ -D -k-1 paths              the same base name in different
                                       directories
    srt -u -D -k1 table                distinct records sharing column 1

  Whole files
    srt -u -o list list                sort and remove repeats, in place
    srt -c a.txt b.txt || echo fix     check several files; -C is silent
    srt -cu table                      sorted, and no record repeated?
    srt -R lines                       shuffle
    srt -b outline.yml                 sort each block, keep the nesting
    find . -print0 | srt -Z            names that contain newlines

  Resources and forms
    srt --mem 2g -T /scratch big.log   bound memory, spill to /scratch
    SRT_STATS=1 srt -k2n big >/dev/null   what the budget did
    srt --bin -k2n table               the binary, or an error
    srt --fn -k2n table                the bash function, even where the
                                       binary is installed

SEE ALSO

    cksh(1), ff(1)

REVISION

    r0.6.
__SRT_MANUAL__
  [ ! -t 1 ] || for p in "${PAGER:-}" less more ; do
    [ -n "$p" ] || continue
    # shellcheck disable=SC2086
    printf '%s' "$m" | command $p 2>/dev/null && return 0
  done
  printf '%s' "$m" ;}

# ---- awk in one mode, reading stdin ------------------------------------
_srt_awk(){ command awk -v mode="$1" -v ks="$ks" -v g="$gt $gf $gi $gr" \
  -v havet="$havet" -v tsep="$tsep" -v maxnf="$maxnf" -v uniq="$uniq" \
  -v nkf="$nkf" -v seed="$seed" -v dups="$dups" "$_SRT_AWK" ;}

# awk exit status -> diagnostic
_srt_rc(){
  case $1 in
    0) : ;;
    3) _srt_die 'input contains a byte from 0x01 to 0x04; the bash function cannot sort it, use the srt binary' ;;
    4) _srt_need '-g on a hexadecimal floating point number' ;;
    *) _srt_die "awk failed (status $1)" ;;
  esac ;}

# ---- the translator ----------------------------------------------------
  local a= s= c= arg= done=0 i=0 st=0 rc=0 n= f=
  local check= uniq=0 rand=0 blocks=0 zero=0 havet=0 tsep=0 out= tdir= mem= dups=0
  local gt=- gf=0 gi=0 gr=0 gset=0 _o_t=- _o_f=0 _o_i=0 _o_r=0 _sz=0 _used=0
  local ks= kq= maxnf=0 nkf=1 seed=0 whole=1 nk=0 S2=$'\002'
  local base= W= wid= odir= ot= oid= mode=
  local -a files=() kcol=() kown=() kspec=() kargs=() sargs=() prc=()

  # options, as the binary parses them
  while [ "$#" -gt 0 ] ; do
    a=$1 ; shift
    { [ "$done" -eq 0 ] && [[ $a == -?* ]] ;} || { files+=("$a") ; continue ;}
    [ "$a" != -- ] || { done=1 ; continue ;}
    [[ $a != --* ]] || {
      _srt_long "$a" "$(( $# > 0 ))" "${1:-}"
      [ "$_used" -eq 0 ] || shift
      continue ;}
    s=${a:1}
    while [ -n "$s" ] ; do
      c=${s:0:1} s=${s:1}
      case $c in
        k)
          [ -z "$s" ] || { arg=$s s= ; _srt_set k "$arg" ; continue ;}
          # bare -k: the next word is the key list only if it reads as
          # one; otherwise no column is named and the word is left
          { [ "$#" -gt 0 ] && [[ $1 =~ ^-?[0-9]+[dfgHinrvx]*(,-?[0-9]+[dfgHinrvx]*)*$ ]] ;} || continue
          arg=$1 ; shift ; _srt_set k "$arg" ;;
        t|o|T)
          [ -z "$s" ] || { arg=$s s= ; _srt_set "$c" "$arg" ; continue ;}
          [ "$#" -gt 0 ] || _srt_bad "option -$c requires an argument"
          arg=$1 ; shift ; _srt_set "$c" "$arg" ;;
        *) _srt_set "$c" '' ;;
      esac
    done
  done
  [ "${#files[@]}" -gt 0 ] || files=(-)

  # validation, in the binary's order
  [ -n "$mem" ] || [ -z "${SRT_MEM:-}" ] || { _srt_size "$SRT_MEM" SRT_MEM ; mem=$_sz ;}
  [ -z "$tdir" ] || [ -d "$tdir" ] || _srt_die "-T $tdir: not a directory"
  [ -z "$check" ] || [ -z "$out" ] || _srt_bad "-$check cannot be combined with -o"
  nk=${#kcol[@]}
  [ "$rand" -eq 0 ] || {
    [ "$gset" -eq 0 ] && [ "$nk" -eq 0 ] && [ "$blocks" -eq 0 ] && [ -z "$check" ] ||
      _srt_bad '-R cannot be combined with ordering options, -k, -b, -c or -C' ;}
  [ "$dups" -eq 0 ] || { [ -z "$check" ] && [ "$rand" -eq 0 ] && [ "$blocks" -eq 0 ] ;} ||
    _srt_bad '-D cannot be combined with -c, -C, -R or -b'
  [ "$blocks" -eq 0 ] || _srt_need '-b (outline sort)'
  [ "$zero" -eq 0 ] || _srt_need '-Z (NUL-terminated records)'

  # keys: letters on a key replace the global set for that key (V04)
  for (( i = 0; i < nk; i++ )) ; do
    [ "${kown[i]}" -eq 1 ] && ks+="${kcol[i]} ${kspec[i]}," || ks+="${kcol[i]} $gt $gf $gi $gr,"
  done
  ks=${ks%,}
  { [ "$nk" -eq 0 ] && [ "$havet" -eq 0 ] ;} || whole=0
  [ "$whole" -eq 1 ] || nkf=$((nk + 1))

  # check: each input on its own, nothing on stdout
  [ -z "$check" ] || {
    for f in "${files[@]}" ; do
      rc=0
      [ "$f" != - ] || { n=$(_srt_awk chk) || rc=$? ;}
      [ "$f" = - ] || {
        { [ -r "$f" ] && [ ! -d "$f" ] ;} || _srt_die "$f: cannot read"
        n=$(_srt_awk chk < "$f") || rc=$? ;}
      [ "$rc" -ne 1 ] || {
        st=1
        [ "$check" != c ] || printf 'srt: %s:%s: disorder\n' "$f" "$n" >&2
        continue ;}
      _srt_rc "$rc"
    done
    exit "$st" ;}

  # work directory: literal class srt-fn., kept suffix only
  base=${tdir:-${TMPDIR:-/var/tmp}}
  [ -d "$base" ] || _srt_die "$base: not a directory (see -T)"
  trap '[ -z "$wid" ] || rm -rf "$base/srt-fn.$wid" ; [ -z "$oid" ] || rm -f "$odir/.srt-fn.$oid"' EXIT
  trap 'exit 130' INT HUP TERM
  read -r W < <(command mktemp -d "$base/srt-fn.XXXXXX") ||
    _srt_die "$base: cannot create work directory (see -T)"
  wid=${W##*/srt-fn.}
  [[ $wid =~ ^[A-Za-z0-9]+$ ]] || { wid= ; _srt_die 'unexpected mktemp name' ;}
  W=$base/srt-fn.$wid

  # all input is read before any output is opened, so -o may name an input
  for f in "${files[@]}" ; do
    [ "$f" = - ] || { [ -r "$f" ] && [ ! -d "$f" ] ;} || _srt_die "$f: cannot read"
  done
  command cat -- "${files[@]}" > "$W/in" || _srt_die 'cannot read input'

  # stage the keyed copy; a refusal here writes nothing
  [ "$rand" -eq 1 ] && {
    seed=$(( (${SRANDOM:-$(( RANDOM << 15 | RANDOM ))} ^ (${BASHPID:-$$} << 7)) & 0x7fffffff ))
    nkf=1 ; kargs=(-k1,1)
    rc=0 ; _srt_awk rnd < "$W/in" > "$W/dec" || rc=$?
    _srt_rc "$rc" ;} || {
    [ "$whole" -eq 1 ] || {
      rc=0 ; maxnf=$(_srt_awk max < "$W/in") || rc=$?
      _srt_rc "$rc" ;}
    rc=0 ; _srt_awk dec < "$W/in" > "$W/dec" || rc=$? ; kq=$ks
    _srt_rc "$rc"
    for (( i = 1; i <= nkf; i++ )) ; do
      [ "$i" -le "$nk" ] && { a=${kq%%,*} ; kq=${kq#*,} ; kargs+=("-k$i,$i") ; [ "${a##* }" -eq 0 ] || kargs[i-1]+=r ;} || {
        kargs+=("-k$i,$i") ; [ "$gr" -eq 0 ] || kargs[i-1]+=r ;}
    done ;}
  command rm -f "$base/srt-fn.$wid/in"
  [ -z "$tdir" ] || sargs+=(-T "$tdir")
  [ -z "$mem" ] || case $(command uname -s) in
    Linux|Darwin|FreeBSD) sargs+=(-S "$(( mem >> 10 > 0 ? mem >> 10 : 1 ))K") ;;
  esac

  # sort the keys as bytes, stably, then strip them
  _srt_run(){
    command sort -s -t "$S2" "${kargs[@]}" ${sargs[@]+"${sargs[@]}"} "$W/dec" | _srt_awk und
    prc=("${PIPESTATUS[@]}")
    [ "${prc[0]}" -eq 0 ] && [ "${prc[1]}" -eq 0 ] ;}

  [ -n "$out" ] || { _srt_run || _srt_die 'sort failed' ; exit 0 ;}

  # -o: write through a non-regular destination; else temporary sibling,
  # mode carried over, renamed into place
  [ ! -d "$out" ] || _srt_die "$out: is a directory"
  { [ ! -e "$out" ] || [ -f "$out" ] ;} || {
    _srt_run > "$out" || _srt_die 'sort failed' ; exit 0 ;}
  odir=. ; [[ $out != */* ]] || odir=${out%/*}
  [ -n "$odir" ] || odir=/
  read -r ot < <(command mktemp "$odir/.srt-fn.XXXXXX") ||
    _srt_die "$out: cannot create temporary"
  oid=${ot##*/.srt-fn.}
  [[ $oid =~ ^[A-Za-z0-9]+$ ]] || { oid= ; _srt_die 'unexpected mktemp name' ;}
  [ ! -f "$out" ] || command cp -p -- "$out" "$odir/.srt-fn.$oid" ||
    _srt_die "$out: cannot prepare temporary"
  [ -f "$out" ] || command chmod "$(printf '%o' "$(( 0666 & ~$(umask) ))")" "$odir/.srt-fn.$oid"
  _srt_run > "$odir/.srt-fn.$oid" || _srt_die 'sort failed'
  command mv -f -- "$odir/.srt-fn.$oid" "$out" || _srt_die "$out: cannot replace"
  oid=
  exit 0
  ) ;}
