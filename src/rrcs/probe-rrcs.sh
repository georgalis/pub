#!/usr/bin/env bash
# probe-rrcs.sh --- keep-link check-in probe, both ,v layouts, any RCS on PATH
# (c) 2024-2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.
#
# rev 6ae1747d 20261027 210517 PDT Tue 09:05 PM 27 Oct 2026
#     initial release
# org 668d8a0d 20240709 120549 PDT Tue 12:05 PM 09 Jul 2024 _rcs in sub/fn.bash
#     https://github.com/georgalis/pub/commit/73f56ac9fe309ab6aac250d78079ab9bba2e9531
#
# usage: bash probe-rrcs.sh              # the ci first on PATH
#        RCSBIN=/opt/pkg/bin bash probe-rrcs.sh     # a specific RCS build (e.g. the pkgsrc prefix)
# Works in a private mktemp directory; ci never reads the terminal; leaves the directory for inspection.
set -u
[ -z "${RCSBIN:-}" ] || PATH="$RCSBIN:$PATH"
command -v ci >/dev/null 2>&1 || { echo ">>> no ci in PATH" >&2 ; exit 1 ;}
ci -V </dev/null 2>&1 | head -1 | sed "s|^|NOTE $(command -v ci): |"
read -r d < <(mktemp -d "${TMPDIR:-/tmp}/rrcs-probe.XXXXXX") || exit 1
cd "$d" || exit 1
ok(){ printf 'PASS %s\n' "$*" ;} ; no(){ printf 'FAIL %s\n' "$*" ; fails=$((fails+1)) ;} ; fails=0

# keep: hold the original inode with a hard link, run an ordinary ci, put the original back
keep(){ local w=$1 b=$2 k id rc iw ik ; shift 2
  read -r k < <(mktemp "$w/.rrcs.XXXXXX") || return 1
  id=${k##*/.rrcs.} ; [[ $id =~ ^[A-Za-z0-9]+$ ]] || return 1
  ln -f -- "$w/$b" "$w/.rrcs.$id" || { rm -f -- "$w/.rrcs.$id" ; return 1 ;}
  ( cd "$w" && ci "$@" "$b" </dev/null ) ; rc=$?
  read -r iw _ < <(ls -i "$w/$b") ; read -r ik _ < <(ls -i "$w/.rrcs.$id")
  [ "$iw" = "$ik" ] && echo "NOTE $w ci wrote in place" || echo "NOTE $w ci replaced the working file"
  mv -f -- "$w/.rrcs.$id" "$w/$b" ; return $rc ;}

# one layout: $1 work dir, $2 ,v dir
layout(){ local w=$1 v=$2 i0 i1 m0 m1 rc
  printf 'a\n' > "$w/f" ; chmod 640 "$w/f" ; touch -t 202001010000 "$w/f"
  read -r i0 _ < <(ls -i "$w/f") ; read -r m0 _ < <(ls -l "$w/f")
  keep "$w" f -l -q -t-probe -m'probe 1' ; rc=$?
  [ $rc = 0 ] && [ -f "$v/f,v" ] && ok "$w ci initial" || no "$w ci initial rc=$rc"
  ( cd "$w" && rcs -q -ko f </dev/null ) && ok "$w rcs -ko" || no "$w rcs -ko"
  touch -c -r "$w/f" "$v/f,v"
  printf 'b\n' >> "$w/f" ; touch -t 202001020000 "$w/f"
  ( cd "$w" && rcsdiff -q f >/dev/null 2>&1 </dev/null ) ; rc=$?
  [ $rc = 1 ] && ok "$w rcsdiff changed=1" || no "$w rcsdiff changed rc=$rc"
  keep "$w" f -l -q -m'probe 2' && ok "$w ci second" || no "$w ci second"
  touch -c -r "$w/f" "$v/f,v"
  ( cd "$w" && rcsdiff -q f >/dev/null 2>&1 </dev/null ) ; rc=$?
  [ $rc = 0 ] && ok "$w rcsdiff unchanged=0" || no "$w rcsdiff unchanged rc=$rc"
  keep "$w" f -l -q -f -m'probe 3 forced' && ok "$w ci -f forced" || no "$w ci -f forced"
  touch -c -r "$w/f" "$v/f,v"
  [ "$( cd "$w" && co -p -q -r1.1 f </dev/null )" = a ] && ok "$w co -p -r1.1" || no "$w co -p -r1.1"
  ( cd "$w" && rlog f </dev/null ) | grep -q '^revision 1\.3' && ok "$w rlog 1.3" || no "$w rlog 1.3"
  ( cd "$w" && rlog -R f </dev/null ) | grep -q 'f,v$' && ok "$w rlog -R" || no "$w rlog -R"
  read -r i1 _ < <(ls -i "$w/f") ; read -r m1 _ < <(ls -l "$w/f")
  [ "$i0" = "$i1" ] && ok "$w inode kept" || no "$w inode $i0 -> $i1"
  [ "${m0:0:10}" = "${m1:0:10}" ] && ok "$w mode kept ${m1:0:10}" || no "$w mode ${m0:0:10} -> ${m1:0:10}"
  [ "$w/f" -nt "$v/f,v" ] || [ "$v/f,v" -nt "$w/f" ] && no "$w mtime differs" || ok "$w mtime equal"
  [ "$(cd "$w" && ls -l f | awk '{print $6, $7, $8}')" = "Jan 2 2020" ] && ok "$w mtime is original" \
    || no "$w mtime $(cd "$w" && ls -l f | awk '{print $6, $7, $8}')"
  ls -A "$w" "$v" | grep -q '^\.rrcs\.' && no "$w scratch left behind" || ok "$w no scratch left"
  ls -li "$w/f" "$v/f,v" ;}

mkdir A A/RCS B
layout A A/RCS   # ,v under RCS/
layout B B       # ,v beside the file
printf '%s failures; inspect %s\n' "$fails" "$d"
