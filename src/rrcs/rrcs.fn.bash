# rrcs.fn.bash --- rrcs (re-rcs): check files into RCS and leave them as they were
# (c) 2024-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6ae1747d 20261027 210517 PDT Tue 09:05 PM 27 Oct 2026
#     initial release: rrcs, keep-link check-in, mtime concurrency, RCS emulation
# org 668d8a0d 20240709 120549 PDT Tue 12:05 PM 09 Jul 2024 _rcs in sub/fn.bash
#     https://github.com/georgalis/pub/commit/73f56ac9fe309ab6aac250d78079ab9bba2e9531
#
# Source from bash (3.2+):  . rrcs.fn.bash ; rrcs -h ; rrcs --help
# When no ci is on PATH at source time (or RRCS_EMULATE=1), ci co rlog rcsdiff rcs
# are defined as bash functions implementing the trunk-only subset rrcs uses.

# ls -l mode string -> chmod symbolic; $2=w keeps write bits; special bits drop to x
_rrcs_msym () { local m=$1 out= t s k i
  for i in 1 4 7 ; do t=${m:$i:3} s=
    [ "${t:0:1}" = r ] && s=r
    [ "${2:-}" = w ] && [ "${t:1:1}" = w ] && s=${s}w
    case ${t:2:1} in x|s|t) s=${s}x ;; esac
    case $i in 1) k=u ;; 4) k=g ;; *) k=o ;; esac
    out=${out:+$out,}$k=$s
  done ; printf '%s\n' "$out" ;}

# ---------------------------------------------------------------- emulation
{ ! command -v ci >/dev/null 2>&1 || [ "${RRCS_EMULATE:-}" = 1 ] ;} && {

_rrcs_emu_err () { printf 'rrcs-emu: %s\n' "$*" >&2 ;}


# working or ,v path -> EW (working path) and EV (,v path), RCS lookup: dir/RCS/b,v else dir/b,v
_rrcs_emu_pair () { local a=$1 d=. b
  case $a in
    *,v) b=${a##*/} ; b=${b%,v}
         [[ $a == */* ]] && { d=${a%/*} ; [ -n "$d" ] || d=/ ;}
         case $d in RCS) d=. ;; */RCS) d=${d%/RCS} ; [ -n "$d" ] || d=/ ;; esac
         [ "$d" = . ] && EW=$b || EW=$d/$b ; EV=$a ;;
    *)   b=${a##*/} ; EW=$a
         [[ $a == */* ]] && { d=${a%/*} ; [ -n "$d" ] || d=/ ;}
         local p= ; [ "$d" = . ] || p=$d/ ; [ -d "$d/RCS" ] && EV=${p}RCS/$b,v || EV=$p$b,v ;;
  esac ;}

# text the emulation can store: empty, or newline-terminated without NUL bytes
_rrcs_emu_textok () { local f=$1 nl
  [ -s "$f" ] || return 0
  read -r nl < <(tail -c 1 -- "$f" | wc -l)
  [ "$nl" = 1 ] || { _rrcs_emu_err "$f: last line has no newline (not emulated)" ; return 1 ;}
  LC_ALL=C tr -d '\000' < "$f" | cmp -s -- - "$f" \
    || { _rrcs_emu_err "$f: contains NUL bytes (not emulated)" ; return 1 ;} ;}

# ,v reader/writer; modes: head text rlog ci ko (see BEGIN); program reads V itself
_rrcs_emu_awk () { local p ; { IFS= read -r -d '' p || : ;} <<'__RRCS_EMU_AWK__'
function die(m) { print "rrcs-emu: " V ": " m | "cat 1>&2" ; close("cat 1>&2") ; exit 2 }
function tok(   c, line, rest, j, k) {
  for (;;) {
    if (li > n) { T = "" ; TV = "" ; return }
    line = L[li]
    if (col > length(line)) { li++ ; col = 1 ; continue }
    c = substr(line, col, 1)
    if (c == " " || c == "\t" || c == "\r") { col++ ; continue }
    break
  }
  if (c == ";" || c == ":") { T = c ; TV = c ; col++ ; return }
  if (c == "@") {
    col++ ; TV = ""
    for (;;) {
      if (li > n) die("unterminated string")
      line = L[li] ; rest = substr(line, col) ; j = index(rest, "@")
      if (j == 0) { TV = TV rest "\n" ; li++ ; col = 1 ; continue }
      TV = TV substr(rest, 1, j - 1)
      if (substr(rest, j + 1, 1) == "@") { TV = TV "@" ; col += j + 1 ; continue }
      col += j ; T = "s" ; return
    }
  }
  k = col
  while (k <= length(line)) { c = substr(line, k, 1) ; if (c ~ /[ \t\r;:@]/) break ; k++ }
  TV = substr(line, col, k - col) ; col = k ; T = "w"
}
function phrase() {
  PN = 0 ; tok()
  while (T != ";") { if (T == "") die("missing ;") ; PN++ ; PT[PN] = T ; PV[PN] = TV ; tok() }
  tok()
}
function enc(s) { gsub(/@/, "@@", s) ; return "@" s "@" }
function raw(k,   s, i, v) {
  s = k
  for (i = 1 ; i <= PN ; i++) {
    v = (PT[i] == "s") ? enc(PV[i]) : PV[i]
    if (PT[i] == ":" || (i > 1 && PT[i - 1] == ":")) s = s v ; else s = s " " v
  }
  return s ";"
}
function isnum(s) { return s ~ /^[0-9][0-9.]*$/ }
function parse(   k, r, i) {
  tok()
  while (T != "" && !(T == "w" && (isnum(TV) || TV == "desc"))) {
    if (T != "w") die("admin syntax near " TV)
    k = TV ; phrase()
    if (k == "head") head = PN ? PV[1] : ""
    else if (k == "branch") { if (PN) die("default branch not emulated") }
    else if (k == "access") { araw = raw(k) ; for (i = 1 ; i <= PN ; i++) AL[++AN] = PV[i] }
    else if (k == "symbols") { sraw = raw(k) ; for (i = 1 ; i + 2 <= PN ; i += 3) { SN++ ; SY[SN] = PV[i] ; SR[SN] = PV[i + 2] } }
    else if (k == "locks") { for (i = 1 ; i + 2 <= PN ; i += 3) { LN++ ; LU[LN] = PV[i] ; LR[LN] = PV[i + 2] } }
    else if (k == "strict") strict = 1
    else if (k == "comment") { hasc = 1 ; cmt = PN ? PV[1] : "" }
    else if (k == "expand") { hase = 1 ; xpd = PN ? PV[1] : "" }
    else xadm = xadm raw(k) "\n"
  }
  while (T == "w" && isnum(TV)) {
    r = TV ; if (r !~ /^[0-9]+\.[0-9]+$/) die("branch revision " r " not emulated")
    ORD[++NR_] = r ; tok()
    while (T == "w" && !isnum(TV) && TV != "desc") {
      k = TV ; phrase()
      if (k == "date") DD[r] = PV[1]
      else if (k == "author") DA[r] = PV[1]
      else if (k == "state") DS[r] = PN ? PV[1] : ""
      else if (k == "branches") { if (PN) die("branches not emulated") }
      else if (k == "next") DN[r] = PN ? PV[1] : ""
      else DX[r] = DX[r] raw(k) "\n"
    }
  }
  if (!(T == "w" && TV == "desc")) die("missing desc")
  tok() ; if (T != "s") die("desc string") ; desc = TV ; tok()
  while (T == "w" && isnum(TV)) {
    r = TV ; tok()
    while (T == "w") {
      k = TV ; tok()
      if (k == "log") { if (T != "s") die("log string") ; DL[r] = TV ; tok() }
      else if (k == "text") { if (T != "s") die("text string") ; DT[r] = TV ; HT[r] = 1 ; tok() ; break }
      else { PN = 0 ; while (T != ";") { if (T == "") die("missing ;") ; PN++ ; PT[PN] = T ; PV[PN] = TV ; tok() } ; tok() ; DY[r] = DY[r] raw(k) "\n" }
    }
  }
  if (T != "") die("trailing data near " TV)
}
function nlok(t) { if (t != "" && substr(t, length(t)) != "\n") die("text without final newline not emulated") }
function apply(base, delta,   B, D, nb, nd, i, k, m, op, P, l, c, out) {
  nlok(base)
  nb = split(base, B, "\n") ; if (nb > 0 && B[nb] == "") nb--
  nd = split(delta, D, "\n") ; if (nd > 0 && D[nd] == "") nd--
  out = "" ; i = 1 ; k = 1
  while (k <= nd) {
    op = substr(D[k], 1, 1) ; split(substr(D[k], 2), P, " ") ; l = P[1] + 0 ; c = P[2] + 0
    if (op == "d") { while (i < l) out = out B[i++] "\n" ; i = l + c ; k++ }
    else if (op == "a") { while (i <= l) out = out B[i++] "\n" ; for (m = 1 ; m <= c ; m++) out = out D[k + m] "\n" ; k += c + 1 }
    else die("bad edit command: " D[k])
  }
  while (i <= nb) out = out B[i++] "\n"
  return out
}
function text(rev,   t, cur, nx) {
  if (!(rev in DD)) die("revision " rev " absent")
  t = DT[head] ; nlok(t) ; cur = head
  while (cur != rev) { nx = DN[cur] ; if (nx == "") die("revision " rev " not on the trunk") ; t = apply(t, DT[nx]) ; cur = nx }
  return t
}
function slurp(f,   s, x, r) { s = "" ; while ((r = (getline x < f)) > 0) s = s x "\n" ; if (r < 0) die("cannot read " f) ; close(f) ; return s }
function emit(h,   i, r) {
  printf "head\t%s;\n%s\n%s\n", h, (araw != "" ? araw : "access;"), (sraw != "" ? sraw : "symbols;")
  printf "locks" ; for (i = 1 ; i <= LN ; i++) if (LU[i] != "") printf "\n\t%s:%s", LU[i], LR[i]
  printf ";" ; if (strict) printf " strict;" ; printf "\n%s", xadm
  if (hasc) printf "comment\t%s;\n", enc(cmt)
  if (hase) printf "expand\t%s;\n", enc(xpd)
  printf "\n"
  for (i = 1 ; i <= NR_ ; i++) { r = ORD[i]
    printf "\n%s\ndate\t%s;\tauthor %s;\tstate %s;\nbranches;\nnext\t%s;\n%s", r, DD[r], DA[r], DS[r], DN[r], DX[r] }
  printf "\n\ndesc\n%s\n", enc(desc)
  for (i = 1 ; i <= NR_ ; i++) { r = ORD[i]
    printf "\n\n%s\nlog\n%s\n%stext\n%s\n", r, enc(DL[r]), DY[r], enc(DT[r]) }
}
function rdate(d,   P) { split(d, P, ".") ; if (length(P[1]) == 2) P[1] = "19" P[1]
  return P[1] "/" P[2] "/" P[3] " " P[4] ":" P[5] ":" P[6] }
function rlog(   i, r, j, nsel, lk) {
  printf "\nRCS file: %s\nWorking file: %s\nhead: %s\nbranch:\nlocks:%s\n", RF, WF, head, (strict ? " strict" : "")
  for (i = 1 ; i <= LN ; i++) printf "\t%s: %s\n", LU[i], LR[i]
  printf "access list:\n" ; for (i = 1 ; i <= AN ; i++) printf "\t%s\n", AL[i]
  printf "symbolic names:\n" ; for (i = 1 ; i <= SN ; i++) printf "\t%s: %s\n", SY[i], SR[i]
  printf "keyword substitution: %s\n", (hase ? xpd : "kv")
  if (SEL != "" && !(SEL in DD)) die("revision " SEL " absent")
  nsel = (SEL != "") ? 1 : NR_
  printf "total revisions: %d;\tselected revisions: %d\n", NR_, nsel
  if (HDR) { print "=============================================================================" ; return }
  printf "description:\n%s", desc
  if (DSC) { print "=============================================================================" ; return }
  for (i = 1 ; i <= NR_ ; i++) { r = ORD[i] ; if (SEL != "" && r != SEL) continue
    printf "----------------------------\nrevision %s", r
    lk = "" ; for (j = 1 ; j <= LN ; j++) if (LR[j] == r) lk = lk (lk == "" ? "" : ",") LU[j]
    if (lk != "") printf "\tlocked by: %s;", lk
    printf "\ndate: %s;  author: %s;  state: %s;\n", rdate(DD[r]), DA[r], DS[r]
    if (DL[r] == "" || DL[r] == "\n") printf "*** empty log message ***\n" ; else { printf "%s", DL[r] ; if (substr(DL[r], length(DL[r])) != "\n") printf "\n" }
  }
  print "============================================================================="
}
function ci(   h, nr, i, held, P) {
  if (INIT) { head = "" ; strict = 1 ; nr = "1.1" ; desc = slurp(DESCF) }
  else {
    held = 0 ; for (i = 1 ; i <= LN ; i++) if (LR[i] == head) { if (LU[i] == U) held = 1 ; else { print "rrcs-emu: " V ": revision " head " locked by " LU[i] | "cat 1>&2" ; exit 4 } }
    if (strict && !held) { print "rrcs-emu: " V ": no lock set by " U | "cat 1>&2" ; exit 4 }
    split(head, P, ".") ; nr = P[1] "." (P[2] + 1)
    DT[head] = slurp(DELTAF)
    for (i = 1 ; i <= LN ; i++) if (LU[i] == U && LR[i] == head) LU[i] = ""
  }
  for (i = NR_ ; i >= 1 ; i--) ORD[i + 1] = ORD[i]
  ORD[1] = nr ; NR_++
  DD[nr] = DATE ; DA[nr] = U ; DS[nr] = "Exp" ; DN[nr] = head ; DL[nr] = slurp(LOGF) ; DT[nr] = slurp(NEWF)
  if (LOCK == "l") { LN++ ; LU[LN] = U ; LR[LN] = nr }
  print nr > RESF ; close(RESF)
  emit(nr)
}
BEGIN {
  li = 1 ; col = 1 ; n = 0
  if (!INIT) {
    while ((r = (getline x < V)) > 0) L[++n] = x
    if (r < 0) die("cannot read")
    close(V) ; parse()
  }
  if (mode == "head") print head
  else if (mode == "text") printf "%s", text(REV != "" ? REV : head)
  else if (mode == "rlog") rlog()
  else if (mode == "ci") ci()
  else if (mode == "ko") { hase = 1 ; xpd = "o" ; emit(head) }
  else die("unknown mode " mode)
  exit 0
}
__RRCS_EMU_AWK__
  awk "$@" "$p" ;}

# scratch directory per emulated call: literal class rrcs-emu. under TMPDIR
_rrcs_emu_tmp () { local t
  read -r t < <(mktemp -d "${TMPDIR:-/tmp}/rrcs-emu.XXXXXX") || return 1
  etid=${t##*/rrcs-emu.} ; etdb=${TMPDIR:-/tmp}
  [[ $etid =~ ^[A-Za-z0-9]+$ ]] || { etid= ; return 1 ;} ;}

ci () ( # emulated: -l -u -q -f -i -mmsg -t-text -tfile, trunk only; never rewrites the working file
  local lock= quiet=0 force=0 init=0 msg= hasm=0 desc= hasd=0 rc=0 f w v vd vid= u dt nr drc
  etid= etdb= ; trap '[ -z "$etid" ] || rm -rf -- "$etdb/rrcs-emu.$etid" ; [ -z "$vid" ] || rm -f -- "$vd/.rrcs-emu.$vid"' EXIT
  trap 'exit 130' INT HUP TERM
  while [ $# -gt 0 ] ; do case $1 in
    -l) lock=l ;; -u) lock=u ;; -q) quiet=1 ;; -f) force=1 ;; -i) init=1 ;;
    -m*) msg=${1#-m} hasm=1 ;;
    -t-*) desc=${1#-t-} hasd=1 ;;
    -t?*) desc=$(cat -- "${1#-t}") || exit 1 ; hasd=1 ;;
    --) shift ; break ;;
    -*) _rrcs_emu_err "ci: option $1 not emulated" ; exit 1 ;;
    *) break ;;
  esac ; shift ; done
  [ $# -gt 0 ] || { _rrcs_emu_err "ci: no working file" ; exit 1 ;}
  _rrcs_emu_tmp || { _rrcs_emu_err "ci: cannot create scratch directory" ; exit 1 ;}
  u=${LOGNAME:-${USER:-}} ; [ -n "$u" ] || read -r u < <(id -un)
  while [[ $msg == *$'\n' ]] ; do msg=${msg%$'\n'} ; done
  for f in "$@" ; do
    _rrcs_emu_pair "$f" ; w=$EW v=$EV vd=. ; [[ $v == */* ]] && vd=${v%/*}
    [ -f "$w" ] || { _rrcs_emu_err "ci: $w: no such working file" ; rc=1 ; continue ;}
    _rrcs_emu_textok "$w" || { rc=1 ; continue ;}
    [ $hasm = 1 ] || { _rrcs_emu_err "ci: $w: log message required (-mmsg)" ; rc=1 ; continue ;}
    printf '%s\n' "$msg" > "$etdb/rrcs-emu.$etid/log"
    [ -f "$v" ] && {
      [ $init = 0 ] || { _rrcs_emu_err "ci: $v already exists (-i)" ; rc=1 ; continue ;}
      _rrcs_emu_awk -v mode=text -v V="$v" > "$etdb/rrcs-emu.$etid/old" || { rc=1 ; continue ;}
      cmp -s -- "$w" "$etdb/rrcs-emu.$etid/old" && [ $force = 0 ] && {
        [ $quiet = 1 ] || _rrcs_emu_err "ci: $w: unchanged; no new revision" ; continue ;}
      # reverse delta: edit script turning the new text into the old head
      drc=2 ; [ "${RRCS_EMU_FULLDELTA:-}" = 1 ] || { diff -n -- "$w" "$etdb/rrcs-emu.$etid/old" > "$etdb/rrcs-emu.$etid/delta" ; drc=$? ;}
      [ $drc -le 1 ] || { local nn no
        read -r nn < <(wc -l < "$w") ; read -r no < <(wc -l < "$etdb/rrcs-emu.$etid/old")
        { [ "$nn" = 0 ] || printf 'd1 %s\n' "$nn" ; [ "$no" = 0 ] || { printf 'a%s %s\n' "$nn" "$no" ; cat -- "$etdb/rrcs-emu.$etid/old" ;} ;} \
          > "$etdb/rrcs-emu.$etid/delta" ;}
      _rrcs_emu_awk -v mode=head -v V="$v" >/dev/null || { rc=1 ; continue ;}
      true ;} || {
      [ $hasd = 1 ] || { _rrcs_emu_err "ci: $w: description required on initial check-in (-t-text)" ; rc=1 ; continue ;}
      { [ -z "$desc" ] || printf '%s\n' "$desc" ;} > "$etdb/rrcs-emu.$etid/desc" ;}
    read -r dt < <(date -u +%Y.%m.%d.%H.%M.%S)
    read -r vid < <(mktemp "$vd/.rrcs-emu.XXXXXX") || { _rrcs_emu_err "ci: cannot write in $vd" ; rc=1 ; vid= ; continue ;}
    vid=${vid##*/.rrcs-emu.} ; [[ $vid =~ ^[A-Za-z0-9]+$ ]] || { vid= ; rc=1 ; continue ;}
    _rrcs_emu_awk -v mode=ci -v V="$v" -v INIT=$([ -f "$v" ] && echo 0 || echo 1) -v U="$u" -v DATE="$dt" \
      -v LOCK="$lock" -v NEWF="$w" -v LOGF="$etdb/rrcs-emu.$etid/log" -v DELTAF="$etdb/rrcs-emu.$etid/delta" \
      -v DESCF="$etdb/rrcs-emu.$etid/desc" -v RESF="$etdb/rrcs-emu.$etid/rev" > "$vd/.rrcs-emu.$vid" \
      || { rm -f -- "$vd/.rrcs-emu.$vid" ; vid= ; rc=1 ; continue ;}
    # ,v mode: the old ,v mode, or the working file mode without write bits
    local ms ; [ -f "$v" ] && { read -r ms _ < <(ls -ld -- "$v") ; ms=$(_rrcs_msym "$ms" w) ;} \
      || { read -r ms _ < <(ls -ld -- "$w") ; ms=$(_rrcs_msym "$ms") ;}
    chmod -- "$ms" "$vd/.rrcs-emu.$vid"
    [ ! -d "$v" ] && mv -f -- "$vd/.rrcs-emu.$vid" "$v" && vid= || { rm -f -- "$vd/.rrcs-emu.$vid" ; vid= ; rc=1 ; continue ;}
    read -r nr < "$etdb/rrcs-emu.$etid/rev"
    [ $quiet = 1 ] || _rrcs_emu_err "ci: $v <-- $w: new revision $nr"
  done
  exit $rc )

co () ( # emulated: -p[rev] -q[rev] -r[rev], print only
  local p=0 q=0 rev= rc=0 f h
  while [ $# -gt 0 ] ; do case $1 in
    -p) p=1 ;; -p?*) p=1 rev=${1#-p} ;; -q) q=1 ;; -q?*) q=1 rev=${1#-q} ;;
    -r) ;; -r?*) rev=${1#-r} ;; --) shift ; break ;;
    -*) _rrcs_emu_err "co: option $1 not emulated" ; exit 1 ;;
    *) break ;;
  esac ; shift ; done
  [ $p = 1 ] || { _rrcs_emu_err "co: writing working files not emulated; use co -p" ; exit 1 ;}
  for f in "$@" ; do _rrcs_emu_pair "$f"
    [ -f "$EV" ] || { _rrcs_emu_err "co: $EV: No such file or directory" ; rc=1 ; continue ;}
    [ $q = 1 ] || { h=$rev ; [ -n "$h" ] || read -r h < <(_rrcs_emu_awk -v mode=head -v V="$EV")
      printf '%s  -->  standard output\nrevision %s\n' "$EV" "$h" >&2 ;}
    _rrcs_emu_awk -v mode=text -v V="$EV" -v REV="$rev" || rc=1
  done ; exit $rc )

rlog () ( # emulated: -R -h -t -r<rev>
  local R=0 h=0 t=0 sel= rc=0 f
  while [ $# -gt 0 ] ; do case $1 in
    -R) R=1 ;; -h) h=1 ;; -t) t=1 ;; -r?*) sel=${1#-r} ;; --) shift ; break ;;
    -*) _rrcs_emu_err "rlog: option $1 not emulated" ; exit 1 ;;
    *) break ;;
  esac ; shift ; done
  for f in "$@" ; do _rrcs_emu_pair "$f"
    [ -f "$EV" ] || { _rrcs_emu_err "rlog: $EV: No such file or directory" ; rc=1 ; continue ;}
    [ $R = 1 ] && { printf '%s\n' "$EV" ; continue ;}
    _rrcs_emu_awk -v mode=rlog -v V="$EV" -v RF="$EV" -v WF="${EW##*/}" -v HDR=$h -v DSC=$t -v SEL="$sel" || rc=1
  done ; exit $rc )

rcsdiff () ( # emulated: -q, -rrev (up to two), diff options
  local q=0 nr=0 r1= r2= rc=0 drc f a b la lb ra ; local -a o=()
  etid= etdb= ; trap '[ -z "$etid" ] || rm -rf -- "$etdb/rrcs-emu.$etid"' EXIT ; trap 'exit 130' INT HUP TERM
  while [ $# -gt 0 ] ; do case $1 in
    -q) q=1 ;; -r) nr=$((nr+1)) ;; -r?*) nr=$((nr+1)) ; [ $nr = 1 ] && r1=${1#-r} || r2=${1#-r} ;;
    -k*|-V*|-x*|-z*) _rrcs_emu_err "rcsdiff: option $1 not emulated" ; exit 2 ;;
    --) shift ; break ;; -*) o+=("$1") ;; *) break ;;
  esac ; shift ; done
  [ $nr -le 2 ] || { _rrcs_emu_err "rcsdiff: at most two -r" ; exit 2 ;}
  _rrcs_emu_tmp || exit 2
  for f in "$@" ; do _rrcs_emu_pair "$f"
    [ -f "$EV" ] || { _rrcs_emu_err "rcsdiff: $EV: No such file or directory" ; rc=2 ; continue ;}
    ra=$r1 ; [ -n "$ra" ] || read -r ra < <(_rrcs_emu_awk -v mode=head -v V="$EV")
    _rrcs_emu_awk -v mode=text -v V="$EV" -v REV="$ra" > "$etdb/rrcs-emu.$etid/a" || { rc=2 ; continue ;}
    a=$etdb/rrcs-emu.$etid/a la="$EV $ra" b=$EW lb=$EW
    [ $nr -lt 2 ] || { _rrcs_emu_awk -v mode=text -v V="$EV" -v REV="$r2" > "$etdb/rrcs-emu.$etid/b" || { rc=2 ; continue ;}
      b=$etdb/rrcs-emu.$etid/b lb="$EV $r2" ;}
    [ $q = 1 ] || printf '===================================================================\nRCS file: %s\nretrieving revision %s\n' "$EV" "$ra" >&2
    diff ${o[@]+"${o[@]}"} -- "$a" "$b" > "$etdb/rrcs-emu.$etid/out" ; drc=$?
    # unified and context headers name the revisions, not the scratch files
    awk -v A="$la" -v B="$lb" 'NR == 1 && /^(---|\*\*\*) / { h = 1 ; print substr($0, 1, 4) A ; next }
      NR == 2 && h && /^(\+\+\+|---) / { print substr($0, 1, 4) B ; next } { print }' "$etdb/rrcs-emu.$etid/out"
    [ $drc -le $rc ] || rc=$drc
  done ; exit $rc )

rcs () ( # emulated: -q -ko only
  local q=0 ko=0 rc=0 f vd vid= ms
  trap '[ -z "$vid" ] || rm -f -- "$vd/.rrcs-emu.$vid"' EXIT ; trap 'exit 130' INT HUP TERM
  while [ $# -gt 0 ] ; do case $1 in
    -q) q=1 ;; -ko) ko=1 ;; --) shift ; break ;;
    -*) _rrcs_emu_err "rcs: option $1 not emulated" ; exit 1 ;;
    *) break ;;
  esac ; shift ; done
  [ $ko = 1 ] || { _rrcs_emu_err "rcs: only -ko is emulated" ; exit 1 ;}
  for f in "$@" ; do _rrcs_emu_pair "$f" ; vd=. ; [[ $EV == */* ]] && vd=${EV%/*}
    [ -f "$EV" ] || { _rrcs_emu_err "rcs: $EV: No such file or directory" ; rc=1 ; continue ;}
    read -r vid < <(mktemp "$vd/.rrcs-emu.XXXXXX") || { vid= ; rc=1 ; continue ;}
    vid=${vid##*/.rrcs-emu.} ; [[ $vid =~ ^[A-Za-z0-9]+$ ]] || { vid= ; rc=1 ; continue ;}
    _rrcs_emu_awk -v mode=ko -v V="$EV" > "$vd/.rrcs-emu.$vid" || { rm -f -- "$vd/.rrcs-emu.$vid" ; vid= ; rc=1 ; continue ;}
    read -r ms _ < <(ls -ld -- "$EV") ; chmod -- "$(_rrcs_msym "$ms" w)" "$vd/.rrcs-emu.$vid"
    mv -f -- "$vd/.rrcs-emu.$vid" "$EV" && vid= || { rm -f -- "$vd/.rrcs-emu.$vid" ; vid= ; rc=1 ;}
  done ; exit $rc )

} # emulation only when ci is absent or RRCS_EMULATE=1

# ---------------------------------------------------------------- rrcs
command -v ci >/dev/null 2>&1 && {
rrcs () ( # re-rcs: check in, then return the working file to the state it had
  stderr() {  [ "$*" ] && echo "$*" 1>&2 || true ;}                      #:> args to stderr, or noop if null
  chkstd() {  [ "$*" ] && echo "$*"      || true ;}                      #:> args to stdout, or noop if null
  chkwrn() {  [ "$*" ] && { stderr    "^^^ $*" ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
  chkerr() {  [ "$*" ] && { stderr    ">>> $*" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null
  LC_COLLATE=C
  local act=ci quiet=0 edit=0 init=0 msg= rc=0 n=0 i a x RD= RE= RS=
  local -a G=() W=() V=() C=() P=() PI=()
  local tmp_dir= tmp_id= keep=0 wmode= cur_w= msg_id= msg_db=
  local scissors='# ------------------------ >8 ------------------------'
  local cre='[[:cntrl:]]' pre='^[A-Za-z0-9._,+@%:=/-]+$'

  # ------------------------------------------------ help
  _page () { [ -t 1 ] || { cat ; return ;} ; local p=${PAGER:-less}
    command -v "${p%% *}" >/dev/null 2>&1 || { command -v more >/dev/null 2>&1 && p=more || p=cat ;}
    $p ;} # PAGER may carry arguments: word splitting intended
  _usage () { local t ; { IFS= read -r -d '' t || : ;} <<'__RRCS_USAGE__'
usage: rrcs [-q] [-m msg]... [-e] [-i] [--] path ...   check in, keep the file as it was (re-rcs)
       rrcs -R [-q] [-m msg]... [-e] [--] old new      rename a file and its ,v, with a record
       rrcs -s|-S [--] path ...                        status: C M ! T ? - E
       rrcs -h | --help [ci|co|rlog|rcsdiff|more]      usage, manual
__RRCS_USAGE__
    printf '%s' "$t" ;}
  _help () { local t
    case ${1:-} in
    ''|rrcs) { IFS= read -r -d '' t || : ;} <<'__RRCS_HELP_MAIN__'
RRCS(1)                    re-rcs                    RRCS(1)

NAME
  rrcs --- re-rcs: check files into RCS and leave them as they were

SYNOPSIS
  rrcs [-q] [-m msg]... [-e] [-i] [--] path ...
  rrcs -R [-q] [-m msg]... [-e] [--] old new
  rrcs -s [--] path ...
  rrcs -S [--] path ...
  rrcs -h
  rrcs --help [ci|co|rlog|rcsdiff|more]

DESCRIPTION
  rrcs stands for re-rcs. It records a revision of each file with ci,
  then returns the working file to the state it had before: the same
  inode, owner, mode, mtime, ACLs, extended attributes and security
  label. A hard link (.rrcs.*) holds the original inode while ci
  replaces the working file; the original then moves back over the
  name. Where a filesystem refuses hard links, rrcs warns and restores
  mtime and mode only.

  After each check-in the ,v file takes the working file's mtime, its
  group, and its read and execute bits (the owner always keeps read).
  Equal mtimes suggest the file and its ,v are concurrent, which -s
  reads cheaply. When rrcs cannot set the group (you are not a member
  of it), the ,v group gets no permissions at all.

  The log of every revision starts with the command as given,
      rrcs <path>[ (sudo:<user>)]
  followed by any -m text or editor message.

  RCS keywords ($Id$, $Log$, ...) are not supported: rrcs sets
  rcs -ko on every new ,v, so text is stored and returned exactly as
  written.

ARGUMENTS
  A path may name a working file or its ,v (x, x,v, RCS/x,v); all
  resolve to the same pair and duplicates are handled once, so globs
  that mix tracked, untracked and ,v files work:
      rrcs -s * RCS/*,v
  The ,v is dir/RCS/x,v when dir/RCS exists, else dir/x,v; RCSINIT -x
  suffixes are not honored. A single path is taken as deliberate: an
  untracked file named alone is checked in, its ,v created. With more
  than one path (a glob, say), untracked files are skipped with a
  warning unless -i is given. Symlinks, directories and special files are
  skipped with a warning; an RCS directory is skipped quietly. Names
  outside [A-Za-z0-9._,+@%:=/-] warn but are processed; names with
  control characters (newlines, tabs) are refused.

OPTIONS
  -m msg  add msg to the log after the header; repeatable, one line each
  -e      compose the message in ${VISUAL:-${EDITOR:-vi}}; needs a
          terminal. Lines starting with # and everything below the
          scissors line are dropped; an empty message aborts the call
          and commits nothing. Any -m text starts the message.
  -i      initial check-in: start tracking every untracked path given,
          however many; an error for files already tracked
  -q      no per-file result lines
  -R      rrcs -R old new: move the working file and its ,v, then
          record the rename with a forced revision. Refused unless old
          is C or T, or when new or its ,v exists. new may be a directory.
  -s      status: compare mtimes; compare content only where they differ
  -S      status: compare content of every tracked file
  -h      brief usage

STATUS MARKS
  C  committed: mtimes equal (with -S, content matches too)
  M  modified: content differs and the file is newer than its ,v
  !  content differs and the file is older than its ,v (restored or
     copied in with an old mtime)
  T  touched: mtimes differ, content matches; rrcs <file> syncs them
  ?  untracked: no ,v
  -  orphan: a ,v without its working file
  E  the comparison failed (co could not read the ,v, say)

  rrcs -s * RCS/*,v            one line per pair
  rrcs -s * | grep -v '^?'     tracked files only
  rrcs -S *                    full content check

  -s misses content that changed while the mtime stayed equal (an edit
  within the same second on a one-second filesystem, or a copy that
  kept an old mtime); -S catches it at one checkout per file.
  Content is compared byte for byte, co -p piped to cmp, not with
  rcsdiff, whose status depends on its diff: OpenRCS has been seen to
  exit 2 without a message on a changed text file.

EXAMPLES
  rrcs -m 'baseline' notes.txt       start tracking notes.txt (one path)
  rrcs -i *.conf                     start tracking several files at once
  rrcs -m 'fix totals' notes.txt     record a change
  rrcs -e notes.txt                  write the message in the editor
  rrcs *                             record every tracked file that changed
  rrcs -R notes.txt doc/             rename into doc/, with a record
  rlog notes.txt                     history
  rcsdiff notes.txt                  working file against the latest revision
  co -p -r1.2 notes.txt > n.1.2      extract an old revision, notes.txt untouched

EXIT STATUS
  0 all succeeded; 1 a check-in, rename or status failed; 2 usage
  error or refused name. Skipped arguments warn without failing.

EMULATION
  When this file is sourced with no ci on PATH (or with RRCS_EMULATE=1),
  ci co rlog rcsdiff rcs are defined as bash functions covering the
  trunk-only subset rrcs uses; each --help topic lists what is
  emulated. Their ,v files are readable by real RCS and theirs by the
  emulation. 'type ci' shows which is active; 'unset -f ci co rlog
  rcsdiff rcs' removes the emulation.

UPSTREAM
  RCS                 http://www.cs.purdue.edu/homes/trinkle/RCS/
  Reference manual    https://www.gnu.org/software/rcs/manual/
  Implementations     GNU RCS 5.9 and OpenRCS (the OpenBSD clone)

TOPICS
  rrcs --help ci | co | rlog | rcsdiff | more
__RRCS_HELP_MAIN__
    ;;
    ci) { IFS= read -r -d '' t || : ;} <<'__RRCS_HELP_CI__'
ci --- check in RCS revisions                         rrcs --help ci

  ci [options] file ...

  Stores the working file as a new revision in its ,v file and records
  a log message. With strict locking (the default) you must hold the
  lock on the latest revision; rrcs checks in with -l, so the lock
  stays with you. A plain ci (or -u) leaves the working file read-only.

  -l[rev]     check in, then lock and check out the working file again
  -u[rev]     check in, then check out read-only and unlocked
  -r[rev]     check in as revision rev
  -f[rev]     force a new revision even when nothing changed
  -i          initial check-in only: error if the ,v exists
  -j          check-in only: error if the ,v does not exist
  -I          interactive: prompt even when stdin is not a terminal
  -k          take revision, date, author and state from keyword
              values in the working file
  -q          quiet
  -mmsg       log message (no space after -m)
  -t-text     description text (initial check-in only)
  -tfile      description from a file (initial check-in only)
  -nname      assign a symbolic name; -Nname moves an existing one
  -sstate     set the state (default Exp)
  -d[date]    check-in date; -d alone uses the working file mtime
  -M          set the working file mtime to the revision date
  -T          set the RCS file mtime to the new revision time if later
  -wlogin     record login as the author
  -V          version;  -xsuffixes  -zzone

  Without -m, or without -t on a new file, ci prompts on standard
  input. rrcs always passes both and reads standard input from
  /dev/null, so ci can never wait for input.

  Examples
    ci -l -m'note' f         check in and keep the lock
    ci -u f                  check in and leave f read-only
    ci -r2.1 -m'major' f     start revision 2.1

  Emulated: -l -u -q -f -i -mmsg -t-text -tfile on trunk revisions;
  other options are refused. The emulated ci never rewrites the
  working file; it needs a newline-terminated text file without NUL
  bytes.
__RRCS_HELP_CI__
    ;;
    co) { IFS= read -r -d '' t || : ;} <<'__RRCS_HELP_CO__'
co --- check out RCS revisions                        rrcs --help co

  co [options] file ...

  Retrieves a revision from the ,v file. Without -p it writes the
  working file, replacing it with a new file, which is exactly what
  rrcs avoids: prefer co -p and a redirect.

  -r[rev]     retrieve revision rev (default: the latest)
  -l[rev]     retrieve and lock;  -u[rev] retrieve unlocked
  -p[rev]     print to standard output; the working file is untouched
  -f[rev]     overwrite the working file without asking
  -q[rev]     quiet
  -I[rev]     interactive
  -kkv -kkvl -kk -ko -kb -kv    keyword substitution mode
  -M[rev]     set the working file mtime to the revision date
  -ddate  -sstate  -wlogin      select by date, state or author
  -jjoinlist  merge revisions into the result
  -T          preserve the RCS file mtime
  -V  -xsuffixes  -zzone

  Examples
    co -p -r1.2 f > f.1.2    extract revision 1.2, f untouched
    co -p f | diff - f       compare by hand
    co -l f                  lock and check out (replaces f)

  Emulated: -p[rev] -q[rev] -r[rev], printing only; writing working
  files and locking are refused.
__RRCS_HELP_CO__
    ;;
    rlog) { IFS= read -r -d '' t || : ;} <<'__RRCS_HELP_RLOG__'
rlog --- print RCS history                            rrcs --help rlog

  rlog [options] file ...

  Prints the header (head, locks, access list, symbolic names, keyword
  mode, counts, description) and the log of each selected revision.

  -R          print only the RCS file name
  -h          header only;  -t header and description
  -L          skip files that have no locks
  -N          omit symbolic names
  -b          revisions on the default branch
  -ddates     revisions in date ranges (d1<d2, <d, >d)
  -l[lockers] revisions locked by the given users (any lock if empty)
  -rrevs      revisions by number or range, e.g. -r1.2:1.4
  -sstates    revisions in the given states
  -w[logins]  revisions checked in by the given users (default: you)
  -V  -xsuffixes  -zzone

  Examples
    rlog f                   full history
    rlog -h f                head, locks and revision count
    rlog -r1.3 f             one revision
    rlog -R RCS/*,v          list the RCS file paths

  Emulated: -R -h -t -r<rev> (a single revision); the output follows
  GNU rlog without the lines: field.
__RRCS_HELP_RLOG__
    ;;
    rcsdiff) { IFS= read -r -d '' t || : ;} <<'__RRCS_HELP_RCSDIFF__'
rcsdiff --- compare RCS revisions                     rrcs --help rcsdiff

  rcsdiff [-q] [-rrev1 [-rrev2]] [-kmode] [diff options] file ...

  No -r compares the latest revision with the working file; one -r
  compares rev1 with the working file; two compare rev1 with rev2.
  Diff options pass through (-u, -c, -b, -w, ...).
  Exit status: 0 no differences, 1 differences, 2 trouble.

  Examples
    rcsdiff f                what changed since the last check-in
    rcsdiff -u -r1.1 f       unified diff from revision 1.1
    rcsdiff -q f && echo same     a test only

  Emulated: -q, up to two -rrev, and diff options; -k -V -x -z are
  refused.
__RRCS_HELP_RCSDIFF__
    ;;
    more) { IFS= read -r -d '' t || : ;} <<'__RRCS_HELP_MORE__'
the rest of the RCS suite                             rrcs --help more

  rcs        change RCS file attributes
               -i create   -l[rev] lock   -u[rev] unlock
               -L strict locking   -U non-strict
               -kmode default keyword mode (rrcs sets -ko)
               -mrev:msg replace a log message
               -nname[:rev] symbolic names   -sstate[:rev] state
               -orange delete revisions (permanent)
               -t description   -alogins / -e[logins] access list
             e.g. rcs -l f       take the lock again after it was broken
  rcsmerge   merge the difference between two revisions into the
             working file:  rcsmerge -r1.2 -r1.4 f
  merge      three-way merge of plain files:  merge mine base theirs
  rcsclean   remove working files that match their latest revision;
             with -u it also unlocks and removes locked ones. rrcs
             keeps locks, so a plain rcsclean leaves its files alone.
  ident      print RCS keyword strings found in files (rrcs uses none)
  rcsfreeze  contributed script: give one symbolic name to the latest
             revisions of all ,v files in RCS/ (not always installed)

  Emulated: rcs -q -ko only; the rest needs the real suite.
__RRCS_HELP_MORE__
    ;;
    *) chkerr "rrcs: no help topic '$1' (ci co rlog rcsdiff more)" ; return 2 ;;
    esac
    printf '%s' "$t" | _page ;}

  # ------------------------------------------------ paths and status
  _db () { D=. B=${1##*/} ; [[ $1 == */* ]] && { D=${1%/*} ; [ -n "$D" ] || D=/ ;} ;}
  _in () { local w=$1 ; shift ; _db "$w" ; ( cd -- "$D" && "$@" "./$B" ) </dev/null ;} # run in the file's dir
  _eqt () { [ ! "$1" -nt "$2" ] && [ ! "$2" -nt "$1" ] ;}
  _vpath () { local d=$1 b=$2 p= ; [ "$d" = . ] || p=$d/ ; [ -d "$d/RCS" ] && PV=${p}RCS/$b,v || PV=$p$b,v ;}
  # resolve one argument to PW PV PC (t tracked, u untracked, o orphan); 1 = skipped
  _pair () { local a=$1 d=. b
    case $a in
      *,v) b=${a##*/} ; b=${b%,v} ; [[ $a == */* ]] && { d=${a%/*} ; [ -n "$d" ] || d=/ ;}
           case $d in RCS) d=. ;; */RCS) d=${d%/RCS} ; [ -n "$d" ] || d=/ ;; esac
           [ "$d" = . ] && PW=$b || PW=$d/$b ; _vpath "$d" "$b"
           [ "${a#./}" = "${PV#./}" ] || { chkwrn "rrcs: skipping '$a': RCS uses '$PV' for '$PW'" ; return 1 ;} ;;
      *)   b=${a##*/} ; [[ $a == */* ]] && { d=${a%/*} ; [ -n "$d" ] || d=/ ;}
           PW=$a ; _vpath "$d" "$b" ;;
    esac
    [ -n "$b" ] || return 1                                     # trailing slash: a directory
    case $b in .rrcs.*|.rrcs-emu.*) chkwrn "rrcs: skipping scratch file '$a'" ; return 1 ;; esac
    [ -L "$PW" ] && { chkwrn "rrcs: skipping symlink '$PW'" ; return 1 ;}
    [ -e "$PW" ] && [ ! -f "$PW" ] && {
      [ -d "$PW" ] && [ "$b" = RCS ] || chkwrn "rrcs: skipping '$PW': not a regular file" ; return 1 ;}
    [ -f "$PV" ] && { [ -f "$PW" ] && PC=t || PC=o ; return 0 ;}
    [ -f "$PW" ] && { PC=u ; return 0 ;}
    chkwrn "rrcs: skipping '$a': no such file" ; return 1 ;}
  _names () { [[ $1 =~ $cre ]] && { chkerr "rrcs: refusing a name with control characters: $(printf '%q' "$1")" ; return 2 ;}
    [[ $1 =~ $pre ]] || chkwrn "rrcs: unusual characters in '$1'" ; return 0 ;}
  # latest revision against the working file, byte for byte: co -p piped to cmp, never rcsdiff,
  # whose diff may judge a text file binary (OpenRCS: status 2, no message) and show nothing.
  # cat drains what cmp leaves, so co never sees a closed pipe. RD 0 same, 1 differs, 2 trouble; RE first error
  _rd () { local x ; _db "$1"
    x=$( cd -- "$D" 2>&1 || { printf '\n2 2' ; exit ;} ; exec 3>&1
         co -p -q "./$B" </dev/null 2>&3 | { cmp -s -- - "./$B" 2>&3 ; r=$? ; cat >/dev/null ; exit $r ;}
         printf '\n%s %s' "${PIPESTATUS[0]}" "${PIPESTATUS[1]}" )
    RS=${x##*$'\n'} ; RE=${x%$'\n'*} ; RE=${RE%%$'\n'*}
    case $RS in "0 0") RD=0 ;; "0 1"|"141 1") RD=1 ;; *) RD=2 ;; esac ;}
  _rde () { local k ; case $(type -t co) in file) k=$(type -P co) ;; *) k='the emulated function (RCS was not on PATH when rrcs.fn.bash was sourced)' ;; esac
    chkerr "rrcs: cannot compare '$1' with its latest revision (co, cmp status ${RS:-?}${RE:+: $RE}; co is $k)" ;}
  _st () { local i=$1 full=$2 w=${W[$1]} v=${V[$1]}
    case ${C[$i]} in u) ST='?' ; return ;; o) ST=- ; return ;; esac
    [ "$full" = 0 ] && _eqt "$w" "$v" && { ST=C ; return ;}
    _rd "$w"
    case $RD in
      0) _eqt "$w" "$v" && ST=C || ST=T ;;
      1) [ "$v" -nt "$w" ] && ST='!' || ST=M ;;
      *) ST=E ;;
    esac ;}
  _head () { _in "$1" rlog -h 2>/dev/null | awk '$1 == "head:" { print $2 ; exit }' ;}

  # ------------------------------------------------ ,v group, mode and time follow the working file
  _vfix () { local w=$1 v=$2 wm wg vg g=1 cu=r cg= co=
    read -r wm _ _ wg _ < <(ls -ldn -- "$w") ; read -r _ _ _ vg _ < <(ls -ldn -- "$v")
    [ "$wg" = "$vg" ] || chgrp -- "$wg" "$v" 2>/dev/null \
      || { g=0 ; chkwrn "rrcs: cannot set group $wg on '$v' (left as $vg); its group gets no permissions" ;}
    case ${wm:3:1} in x|s|t) cu=rx ;; esac
    [ $g = 1 ] && { [ "${wm:4:1}" = r ] && cg=r ; case ${wm:6:1} in x|s|t) cg=${cg}x ;; esac ;}
    [ "${wm:7:1}" = r ] && co=r ; case ${wm:9:1} in x|s|t) co=${co}x ;; esac
    chmod -- "u=$cu,g=$cg,o=$co" "$v" && touch -c -r "$w" -- "$v" ;}

  # ------------------------------------------------ scratch files: literal class .rrcs. beside the working file
  tmp_new () { local f ; read -r f < <(mktemp "$1/.rrcs.XXXXXX") || return 1
    tmp_dir=$1 tmp_id=${f##*/.rrcs.} ; [[ $tmp_id =~ ^[A-Za-z0-9]+$ ]] || { tmp_id= ; return 1 ;} ;}
  # return the original inode, or failing that its mtime and mode; remove scratch
  _restore () { local w=$cur_w iw= ik= back=0
    [ -n "$cur_w" ] && [ -n "$tmp_id" ] || return 0
    [ $keep = 1 ] && [ -e "$tmp_dir/.rrcs.$tmp_id.k" ] && {
      read -r iw _ < <(ls -id -- "$w" 2>/dev/null) ; read -r ik _ < <(ls -id -- "$tmp_dir/.rrcs.$tmp_id.k")
      [ "$iw" = "$ik" ] && rm -f -- "$tmp_dir/.rrcs.$tmp_id.k" \
        || { [ ! -d "$w" ] && mv -f -- "$tmp_dir/.rrcs.$tmp_id.k" "$w" && back=1 ;} ;}
    [ $back = 1 ] || { [ -f "$w" ] && touch -r "$tmp_dir/.rrcs.$tmp_id" -- "$w" && chmod -- "$wmode" "$w" ;}
    rm -f -- "$tmp_dir/.rrcs.$tmp_id" ; tmp_id= cur_w= keep=0 ;}
  _cleanup () { _restore ; [ -z "$msg_id" ] || rm -f -- "$msg_db/rrcs-msg.$msg_id" ;}
  trap _cleanup EXIT ; trap 'exit 130' INT HUP TERM

  # ------------------------------------------------ one check-in: keep link, ordinary ci, restore, ,v fix
  _commit () { local w=$1 v=$2 init=$3 force=$4 hdr=$5 log m r
    log=$hdr ; [ -z "${SUDO_USER:-}" ] || log="$log (sudo:$SUDO_USER)" ; [ -z "$msg" ] || log=$log$'\n'$msg
    _db "$w" ; tmp_new "$D" || { chkerr "rrcs: cannot create a scratch file in '$D'" ; return 1 ;}
    touch -r "$w" -- "$tmp_dir/.rrcs.$tmp_id" ; read -r m _ < <(ls -ld -- "$w")
    wmode=$(_rrcs_msym "$m" w)
    cur_w=$w keep=1
    ln -f -- "$w" "$tmp_dir/.rrcs.$tmp_id.k" 2>/dev/null \
      || { keep=0 ; chkwrn "rrcs: hard link refused in '$D'; restoring mtime and mode only" ;}
    _in "$w" ci -l -q ${force:+-f} ${init:+-t-rrcs} -m"$log" ; r=$?
    _restore
    [ $r = 0 ] || { chkerr "rrcs: ci failed for '$w' (status $r; lock missing? see rlog -h, rcs -l)" ; return 1 ;}
    [ -z "$init" ] || _in "$w" rcs -q -ko || chkwrn "rrcs: rcs -ko failed for '$w'"
    [ -f "$v" ] || { chkerr "rrcs: '$v' not found after ci" ; return 1 ;}
    _vfix "$w" "$v" || { chkerr "rrcs: cannot set mode or time on '$v'" ; return 1 ;}
    [ $quiet = 1 ] || chkstd "$w $(_head "$w")" ;}

  # ------------------------------------------------ message from the editor
  _editmsg () { local f i e=${VISUAL:-${EDITOR:-vi}}
    read -r f < <(mktemp "${TMPDIR:-/tmp}/rrcs-msg.XXXXXX") || return 1
    msg_db=${TMPDIR:-/tmp} msg_id=${f##*/rrcs-msg.} ; [[ $msg_id =~ ^[A-Za-z0-9]+$ ]] || { msg_id= ; return 1 ;}
    { [ -z "$msg" ] || printf '%s\n' "$msg"
      printf '\n# rrcs: write the log message above. Lines starting with # are dropped;\n# an empty message aborts and nothing is committed.\n# Files:\n'
      for i in "${P[@]}" ; do printf '#   %s%s\n' "${W[i]}" "${PI[i]:+ (new)}" ; done
      printf '%s\n# Everything below the scissors line is dropped.\n' "$scissors"
      for i in "${P[@]}" ; do [ -n "${PI[i]}" ] || _in "${W[i]}" rcsdiff -u 2>/dev/null ; done
    } > "$msg_db/rrcs-msg.$msg_id"
    $e "$msg_db/rrcs-msg.$msg_id" || { chkerr "rrcs: editor '$e' failed; nothing committed" ; return 1 ;} # EDITOR may carry arguments
    msg=$(awk -v S="$scissors" '$0 == S { exit } /^#/ { next } { print }' "$msg_db/rrcs-msg.$msg_id")
    while [[ $msg == $'\n'* ]] ; do msg=${msg#$'\n'} ; done
    rm -f -- "$msg_db/rrcs-msg.$msg_id" ; msg_id=
    [[ $msg =~ [^[:space:]] ]] || { chkerr "rrcs: empty message; nothing committed" ; return 1 ;} ;}

  # ------------------------------------------------ options
  [ "${1:-}" = --help ] && { _help "${2:-}" ; exit $? ;}
  while [ $# -gt 0 ] ; do case $1 in
    -h) _usage ; exit 0 ;;
    -q) quiet=1 ;; -e) edit=1 ;; -i) init=1 ;; -s) act=s ;; -S) act=S ;; -R) act=R ;;
    -m) [ $# -ge 2 ] || { chkerr "rrcs: -m needs a message" ; exit 2 ;} ; shift ; msg=${msg:+$msg$'\n'}$1 ;;
    -m?*) msg=${msg:+$msg$'\n'}${1#-m} ;;
    -[qeisSR][qeisSR]*) x=${1#-} ; shift ; set -- $(printf '%s\n' "$x" | sed 's/./-& /g') "$@" ; continue ;;
    --help) _help "${2:-}" ; exit $? ;;
    --) shift ; break ;;
    -?*) chkerr "rrcs: unknown option '$1' (rrcs -h)" ; exit 2 ;;
    *) break ;;
  esac ; shift ; done
  [ $# -gt 0 ] || { _usage >&2 ; exit 2 ;}
  [ $edit = 0 ] || [ "$act" = s ] || [ "$act" = S ] || { [ -t 0 ] && [ -t 1 ] ;} \
    || { chkerr "rrcs: -e needs a terminal" ; exit 2 ;}
  for a in "$@" ; do _names "$a" || exit 2 ; done

  # ------------------------------------------------ rename
  [ "$act" = R ] && {
    [ $# = 2 ] || { chkerr "rrcs: -R takes exactly: old new" ; exit 2 ;}
    local old=$1 new=$2 ow ov nv io in_
    _pair "$old" || exit 1 ; ow=$PW ov=$PV
    [ "$PC" = t ] || { chkerr "rrcs: '$old' is not tracked (-R)" ; exit 1 ;}
    W[0]=$ow V[0]=$ov C[0]=t ; _st 0 0
    case $ST in C|T) ;; E) _rde "$ow" ; chkerr "rrcs: '$ow' not renamed; nothing was changed" ; exit 1 ;;
      *) chkerr "rrcs: '$ow' has status $ST; check it in before renaming" ; exit 1 ;; esac
    [ -d "$new" ] && new=${new%/}/${ow##*/}
    _names "$new" || exit 2
    { [ -e "$new" ] || [ -L "$new" ] ;} && { chkerr "rrcs: '$new' exists" ; exit 1 ;}
    _db "$new" ; [ -d "$D" ] || { chkerr "rrcs: no directory '$D'" ; exit 1 ;} ; _vpath "$D" "$B" ; nv=$PV
    [ -n "$B" ] && [ ! -e "$nv" ] || { chkerr "rrcs: '$nv' exists" ; exit 1 ;}
    read -r io _ < <(ls -id -- "$ow")
    mv -- "$ow" "$new" || { chkerr "rrcs: cannot move '$ow'" ; exit 1 ;}
    mv -- "$ov" "$nv" || { mv -- "$new" "$ow" ; chkerr "rrcs: cannot move '$ov'; '$ow' put back" ; exit 1 ;}
    read -r in_ _ < <(ls -id -- "$new") ; [ "$io" = "$in_" ] || chkwrn "rrcs: '$new' crossed filesystems: new inode"
    [ $edit = 0 ] || { P=(0) PI=("") W[0]=$new ; _editmsg || exit 1 ;}
    _commit "$new" "$nv" "" 1 "rrcs -R $old $2" || { chkerr "rrcs: renamed, but the record check-in failed" ; exit 1 ;}
    exit 0 ;}

  # ------------------------------------------------ resolve arguments, drop duplicates
  for a in "$@" ; do
    _pair "$a" || continue
    x=0 ; for ((i = 0 ; i < n ; i++)) ; do [ "${W[i]#./}" = "${PW#./}" ] && { x=1 ; break ;} ; done
    [ $x = 0 ] || continue
    G[n]=$a W[n]=$PW V[n]=$PV C[n]=$PC ; n=$((n + 1))
  done

  # ------------------------------------------------ status
  [ "$act" = s ] || [ "$act" = S ] && {
    for ((i = 0 ; i < n ; i++)) ; do
      _st $i $([ "$act" = S ] && echo 1 || echo 0)
      [ "$ST" = E ] && { rc=1 ; _rde "${W[i]}" ;}
      printf '%s %s\n' "$ST" "${W[i]}"
    done ; exit $rc ;}

  # ------------------------------------------------ check in
  for ((i = 0 ; i < n ; i++)) ; do
    case ${C[i]} in
      t) [ $init = 0 ] || { chkerr "rrcs: '${W[i]}' is already tracked (-i)" ; rc=1 ; continue ;}
         _rd "${W[i]}"
         case $RD in
           0) _vfix "${W[i]}" "${V[i]}" || rc=1 ; [ $quiet = 1 ] || chkstd "${W[i]} unchanged" ;;
           1) P+=($i) PI[i]= ;;
           *) _rde "${W[i]}" ; rc=1 ;;
         esac ;;
      u) { [ $init = 1 ] || [ $# = 1 ] ;} && { P+=($i) ; PI[i]=1 ;} \
           || chkwrn "rrcs: '${W[i]}' is untracked; add it with -i, or name it alone" ;;
      o) chkwrn "rrcs: '${V[i]}' has no working file" ;;
    esac
  done
  [ ${#P[@]} = 0 ] && exit $rc
  [ $edit = 0 ] || _editmsg || exit 1
  for i in "${P[@]}" ; do
    _commit "${W[i]}" "${V[i]}" "${PI[i]}" "" "rrcs ${G[i]}" || rc=1
  done
  exit $rc )
} # rrcs only where ci resolves (binary or emulation)
