#!/usr/bin/env bash
# (c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
# revs: 6813a700 20260407 --- encoding filters, figure dedup, bitmap exclusion, macro fix
# orig: 668973c5 20240706 094141 PDT Sat 09:41 AM 6 Jul 2024 --- texlive-font-package-lister.sh
# texlive-font-discovery.sh [-t sample.tex] [-e conservative|broader|probe] [-u]
#   -t FILE  generate sample tex rendering each discovered family
#   -e MODE  encoding filter for sample (default: conservative)
#            conservative: T1,OT1,LY1  broader: +TS1,IL2,QX,L7x,LGR,T2A-C,T5,CS
#            probe: all encodings (math, symbol, CJK, scripts)
#   -u       scan user texmf only (default: system + user)
# discover installed texlive font packages (.sty) and family definitions (.fd)
# tsv output: phase 1 font packages, phase 2 font families (always unfiltered)
# sample tex: encoding-filtered, figure-style deduplicated (T1 > OT1 > LY1,
#   TLF > LF > OsF > TOsF > bare), bitmap families excluded, numeral/ornament
#   families excluded, clearpage every 30 entries for tex memory management
#set -euo pipefail

usage() { sed -n '5,11s/^# //p' "$0" ; exit 1 ; }

# --- platform texmf root resolution ---
declare -a roots=()
texmf_user= texmf_sys= user_only=0 sample_file= enc_mode=conservative

read -r texmf_user < <(
  case $(uname) in
    Darwin)     echo "$HOME/Library/texmf" ;;
    *BSD|Linux) echo "$HOME/texmf" ;;
  esac
)

while getopts "t:e:uh" opt ; do
  case $opt in
    t) sample_file="$OPTARG" ;;
    e) enc_mode="$OPTARG" ;;
    u) user_only=1 ;;
    *) usage ;;
  esac
done

case "$enc_mode" in # validate early; -e is only meaningful with -t, harmless without
  conservative|broader|probe) ;;
  *) echo "error: -e requires conservative, broader, or probe" >&2 ; exit 1 ;;
esac

# system texlive: newest versioned directory
[ "$user_only" -eq 0 ] && {
  read -r texmf_sys < <(
    find /usr/local/texlive -maxdepth 1 -type d -name '[0-9]*' 2>/dev/null \
      | sort -rn | head -1 ; echo
  )
  texmf_sys="${texmf_sys%$'\n'}"
  [ -d "$texmf_sys/texmf-dist" ] && roots+=("$texmf_sys/texmf-dist")
}
[ -d "$texmf_user" ] && roots+=("$texmf_user")

[ ${#roots[@]} -eq 0 ] && {
  echo "error: no texmf directories found" >&2 ; exit 1
}

echo "# texmf roots: ${roots[*]}"

# --- phase 1: font packages (.sty files setting rm/sf/tt defaults) ---
# fonts intended for document-level use set \rmdefault, \sfdefault,
# or \ttdefault; this heuristic filters utility packages
scan_packages() {
  local root="$1"
  find "$root/tex/latex" -type f -name '*.sty' 2>/dev/null \
    | sort | while read -r sty ; do
      grep -qE '\\(rm|sf|tt)default' "$sty" 2>/dev/null || continue
      read -r pkg < <(basename "$sty" .sty)
      # which default(s) does it set
      read -r -d '' cls < <(
        sed -n -E 's/.*\\(rm|sf|tt)default.*/\1/p' "$sty" \
          | sort -u | paste -sd, - ; echo
      ) || true
      cls="${cls%$'\n'}" ; cls="${cls%,}"
      # version from ProvidesPackage
      read -r -d '' ver < <(
        sed -n 's/.*\\ProvidesPackage{[^}]*}\[\([^]]*\)\].*/\1/p' "$sty" \
          | head -1 ; echo
      ) || true
      ver="${ver%$'\n'}"
      printf "%s\t%s\t%s\t%s\n" "$pkg" "${cls:--}" "${ver:--}" "$sty"
    done
}

echo ""
echo "# --- font packages ---"
echo "# package\tclass\tversion\tpath"
for r in "${roots[@]}" ; do scan_packages "$r" ; done

# --- phase 2: font families from .fd (font definition) files ---
# each .fd declares \DeclareFontShape{encoding}{family}{weight}{shape}
# extract per-file: encoding, family, unique weights, unique shapes
# reject macro parameter artifacts (#1, #2) from \newcommand contexts
scan_families() {
  local root="$1"
  find "$root/tex/latex" -type f -name '*.fd' 2>/dev/null \
    | sort | while read -r fd ; do
      sed -n 's/.*\\DeclareFontShape{\([^}]*\)}{\([^}]*\)}{\([^}]*\)}{\([^}]*\)}.*/\1\t\2\t\3\t\4/p' "$fd" \
        | awk -F'\t' '
          NR == 1 { enc = $1; fam = $2 }
          { wt[$3] = 1; sh[$4] = 1 }
          END {
            if (enc == "") exit
            if (enc ~ /#/ || fam ~ /#/) exit
            w = ""; for (k in wt) w = (w == "") ? k : w "," k
            s = ""; for (k in sh) s = (s == "") ? k : s "," k
            printf "%s\t%s\t%s\t%s\t%s\n", enc, fam, w, s, FILENAME
          }
        ' fd="$fd" || true
    done | sort -t'	' -k2,2 -k1,1
}

echo ""
echo "# --- font families ---"
echo "# encoding\tfamily\tweights\tshapes\tpath"
for r in "${roots[@]}" ; do scan_families "$r" ; done

# --- optional: generate sample tex document ---
[ -z "$sample_file" ] && exit 0

# validate output path
read -r safe < <(
  printf '%s' "$sample_file" \
    | sed -n '/^[A-Za-z0-9._\/-]*$/p'
) || true
[ -z "$safe" ] && {
  echo "error: unsafe characters in output path" >&2 ; exit 1
}

# --- encoding filter for sample tex ---
# conservative: latin text encodings renderable with T1 fontenc preamble
# broader: adds extended-latin, cyrillic, greek, vietnamese, czech/slovak
# probe: unfiltered---includes math, symbol, CJK, script encodings
enc_match() {
  case "$enc_mode" in
    probe) return 0 ;;
    conservative)
      case "$1" in T1|OT1|LY1) return 0 ;; esac ;;
    broader)
      case "$1" in
        T1|OT1|LY1|TS1|IL2|QX|L7x|L7X|LGR|T2A|T2B|T2C|T5|CS) return 0 ;;
      esac ;;
  esac
  return 1
}

# --- bitmap/metafont family exclusion ---
# reject pure-metafont families with no Type1/OTF backing
# Latin Modern (lm*), TeX Gyre (q*), PostScript base (p*), TX/PX (tx*/px*)
# are Type1---not excluded; only CM derivatives and their clones
is_bitmap() {
  case "$1" in
    ae[a-z]|ae[a-z][a-z]|ae[a-z][a-z][a-z]) return 0 ;; # Almost European CM
    cc[a-z]|cc[a-z][a-z])                     return 0 ;; # Concrete
    cm[a-z]|cm[a-z][a-z]|cm[a-z][a-z][a-z]|cm[a-z][a-z][a-z][a-z]) return 0 ;; # Computer Modern
    kc[a-z]|kc[a-z][a-z]|kc[a-z][a-z][a-z])  return 0 ;; # KC fonts
    lh[a-z]|lh[a-z][a-z]|lh[a-z][a-z][a-z])  return 0 ;; # LH Cyrillic CM
    wn[a-z]|wn[a-z][a-z]|wn[a-z][a-z][a-z])  return 0 ;; # Washington Cyrillic
    wc[a-z]|wc[a-z][a-z]|wc[a-z][a-z][a-z])  return 0 ;; # Washington CM
    lcm[a-z]|lcm[a-z][a-z])                   return 0 ;; # latex CM sans/tt
    llcm[a-z]|llcm[a-z][a-z])                 return 0 ;; # llcm variants
    mlm[a-z]|mlm[a-z][a-z]|mlm[a-z][a-z][a-z]) return 0 ;; # ML CM variants
    vlm[a-z]|vlm[a-z][a-z]|vlm[a-z][a-z][a-z]) return 0 ;; # VL CM variants
    xcm[a-z]|xcm[a-z][a-z])                   return 0 ;; # XCM variants
  esac
  return 1
}

# --- numeral/ornament-only family exclusion ---
# -Inf (inferior), -Sup (superior), -Dnom (denominator), -Numr (numerator)
# contain only figure glyphs; -Orn contains only ornaments
is_partial() {
  case "$1" in *-Inf|*-Sup|*-Dnom|*-Numr|*-Orn) return 0 ;; esac
  return 1
}

# collect enc:family pairs across all roots, apply encoding + rejection filters
declare -a fam_pairs=()
for r in "${roots[@]}" ; do
  while IFS=$'\t' read -r enc fam _wts _shs _path ; do
    enc_match "$enc" || continue
    is_partial "$fam" && is_bitmap "$fam" || continue
    fam_pairs+=("$enc:$fam")
  done < <(scan_families "$r")
done

[ ${#fam_pairs[@]} -eq 0 ] && {
  echo "# sample: no families matched filters (encoding: $enc_mode)" >&2
  exit 1
}

# --- write tex preamble ---
# \showfont wraps full demo lines in \textbf/\textit (not just labels)
# \filbreak prevents orphaned partial entries at page bottom
# counter triggers \clearpage every 30 entries for font memory management
cat > "$sample_file" <<'TEXDOC'
\documentclass[10pt]{article}
\usepackage[T1]{fontenc}
\usepackage[margin=0.75in]{geometry}
\newcounter{fontcount}
\newcommand{\showfont}[2]{%
  \filbreak
  \stepcounter{fontcount}%
  \par\noindent\texttt{#1 / #2}\par
  {\fontfamily{#2}\selectfont
    The quick brown fox jumps over the lazy dog. 0123456789\par
    \textbf{Bold: The quick brown fox jumps over the lazy dog.}\par
    \textit{Italic: The quick brown fox jumps over the lazy dog.}\par
  }\medskip\hrule\medskip
  \ifnum\value{fontcount}>29\setcounter{fontcount}{0}\clearpage\fi
}
\begin{document}
\section*{Installed Font Samples}
Generated by \texttt{texlive-font-discovery.sh}.\medskip\hrule\medskip
TEXDOC

# --- figure-style dedup with encoding priority ---
# strip -TLF/-TOsF/-OsF/-LF to base family, assign priority:
#   encoding: T1=1 OT1=2 LY1=3 rest=9
#   figure:   TLF=1 LF=2 OsF=3 TOsF=4 bare=5
# sort by (base, enc_prio, fig_prio), take first per base
awk -F'\t' '!seen[$1]++ { printf "\\showfont{%s}{%s}\n", $4, $5 }' \
  < <(sort -t'	' -k1,1 -k2,2n -k3,3n \
    < <(awk -F: '{
          enc = $1; fam = $2
          base = fam; fig = 5
          if      (sub(/-TLF$/,  "", base)) fig = 1
          else if (sub(/-LF$/,   "", base)) fig = 2
          else if (sub(/-OsF$/,  "", base)) fig = 3
          else if (sub(/-TOsF$/, "", base)) fig = 4
          if      (enc == "T1")  ep = 1
          else if (enc == "OT1") ep = 2
          else if (enc == "LY1") ep = 3
          else                   ep = 9
          printf "%s\t%d\t%d\t%s\t%s\n", base, ep, fig, enc, fam
        }' < <(sort -u < <(printf '%s\n' "${fam_pairs[@]}"))
      )
    ) >> "$sample_file"

echo '\end{document}' >> "$sample_file"

# diagnostic summary
read -r nfam < <(grep -c '^\\showfont{' "$sample_file" || echo 0)
echo "# sample tex written: $sample_file ($nfam families, encoding: $enc_mode)" >&2
echo "# compile: pdflatex $sample_file" >&2
echo "# if font memory exhaustion: pdflatex --extra-mem-top=10000000 $sample_file" >&2
