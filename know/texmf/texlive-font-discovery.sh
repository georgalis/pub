#!/usr/bin/env bash
# (c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
# revs: 6813c8f0 20260407 --- pkg dep detection, discovery tsv output, filter fix
# orig: 668973c5 20240706 094141 PDT Sat 09:41 AM 6 Jul 2024 --- texlive-font-package-lister.sh
# texlive-font-discovery.sh [-t sample.tex] [-d inventory.tsv]
#                            [-e conservative|broader|probe] [-u]
#   -t FILE  generate sample tex rendering each discovered family
#   -d FILE  write discovery tsv to file (default: stdout only)
#   -e MODE  encoding filter for sample (default: conservative)
#            conservative: T1,OT1,LY1  broader: +TS1,IL2,QX,L7x,LGR,T2A-C,T5,CS
#            probe: all encodings (math, symbol, CJK, scripts)
#   -u       scan user texmf only (default: system + user)
# discover installed texlive font packages (.sty) and family definitions (.fd)
# tsv output: phase 1 font packages, phase 2 font families (always unfiltered)
#   phase 2 includes dep column: families with @-macros in font specs require
#   their parent .sty package loaded---these render only via \usepackage
# sample tex: encoding-filtered, figure-style deduplicated (T1 > OT1 > LY1,
#   TLF > LF > OsF > TOsF > bare), bitmap and pkg-dep families excluded,
#   numeral/ornament families in reference appendix only
set -euo pipefail

usage() { sed -n '5,12s/^# //p' "$0" ; exit 1 ; }

# --- platform texmf root resolution ---
declare -a roots=()
texmf_user= texmf_sys= user_only=0
sample_file= disc_file= enc_mode=conservative

read -r texmf_user < <(
  case $(uname) in
    Darwin)     echo "$HOME/Library/texmf" ;;
    *BSD|Linux) echo "$HOME/texmf" ;;
  esac
)

while getopts "t:d:e:uh" opt ; do
  case $opt in
    t) sample_file="$OPTARG" ;;
    d) disc_file="$OPTARG" ;;
    e) enc_mode="$OPTARG" ;;
    u) user_only=1 ;;
    *) usage ;;
  esac
done

case "$enc_mode" in
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

# --- discovery output: stdout and optional file ---
# tee to disc_file when -d specified; stdout always receives inventory
_out() {
  [ -n "$disc_file" ] && tee -a "$disc_file" || cat
}
[ -n "$disc_file" ] && : > "$disc_file" # truncate

echo "# texmf roots: ${roots[*]}" | _out

# --- phase 1: font packages (.sty files setting rm/sf/tt defaults) ---
scan_packages() {
  local root="$1"
  find "$root/tex/latex" -type f -name '*.sty' 2>/dev/null \
    | sort | while read -r sty ; do
      grep -qE '\\(rm|sf|tt)default' "$sty" 2>/dev/null || continue
      read -r pkg < <(basename "$sty" .sty)
      read -r -d '' cls < <(
        sed -n -E 's/.*\\(rm|sf|tt)default.*/\1/p' "$sty" \
          | sort -u | paste -sd, - ; echo
      ) || true
      cls="${cls%$'\n'}" ; cls="${cls%,}"
      read -r -d '' ver < <(
        sed -n 's/.*\\ProvidesPackage{[^}]*}\[\([^]]*\)\].*/\1/p' "$sty" \
          | head -1 ; echo
      ) || true
      ver="${ver%$'\n'}"
      printf "%s\t%s\t%s\t%s\n" "$pkg" "${cls:--}" "${ver:--}" "$sty"
    done
}

{ echo ""
  echo "# --- font packages ---"
  echo "# package\tclass\tversion\tpath"
  for r in "${roots[@]}" ; do scan_packages "$r" ; done
} | _out

# --- phase 2: font families from .fd (font definition) files ---
# reject macro parameter artifacts (#1, #2) from \newcommand contexts
# detect @-macros in font spec (5th arg): these require parent .sty loaded
# dep column: "dep" = has @-macro dependency, empty = self-contained
scan_families() {
  local root="$1"
  find "$root/tex/latex" -type f -name '*.fd' 2>/dev/null \
    | sort | while read -r fd ; do
      sed -n 's/.*\\DeclareFontShape{\([^}]*\)}{\([^}]*\)}{\([^}]*\)}{\([^}]*\)}{\([^}]*\)}.*/\1\t\2\t\3\t\4\t\5/p' "$fd" \
        | awk -F'\t' '
          NR == 1 { enc = $1; fam = $2 }
          { wt[$3] = 1; sh[$4] = 1 }
          # @-macro in font spec = package dependency
          $5 ~ /\\[a-zA-Z]*@/ { dep = 1 }
          END {
            if (enc == "") exit
            if (enc ~ /#/ || fam ~ /#/) exit
            w = ""; for (k in wt) w = (w == "") ? k : w "," k
            s = ""; for (k in sh) s = (s == "") ? k : s "," k
            printf "%s\t%s\t%s\t%s\t%s\t%s\n", enc, fam, w, s, FILENAME, \
              (dep ? "dep" : "")
          }
        ' fd="$fd" || true
    done | sort -t'	' -k2,2 -k1,1
}

{ echo ""
  echo "# --- font families ---"
  echo "# encoding\tfamily\tweights\tshapes\tpath\tdep"
  for r in "${roots[@]}" ; do scan_families "$r" ; done
} | _out

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
# Latin Modern (lm*), TeX Gyre (q*), PostScript base (p*) are Type1---kept
is_bitmap() {
  case "$1" in
    ae[a-z]|ae[a-z][a-z]|ae[a-z][a-z][a-z]) return 0 ;;
    cc[a-z]|cc[a-z][a-z])                     return 0 ;;
    cm[a-z]|cm[a-z][a-z]|cm[a-z][a-z][a-z]|cm[a-z][a-z][a-z][a-z]) return 0 ;;
    kc[a-z]|kc[a-z][a-z]|kc[a-z][a-z][a-z])  return 0 ;;
    lh[a-z]|lh[a-z][a-z]|lh[a-z][a-z][a-z])  return 0 ;;
    wn[a-z]|wn[a-z][a-z]|wn[a-z][a-z][a-z])  return 0 ;;
    wc[a-z]|wc[a-z][a-z]|wc[a-z][a-z][a-z])  return 0 ;;
    lcm[a-z]|lcm[a-z][a-z])                   return 0 ;;
    llcm[a-z]|llcm[a-z][a-z])                 return 0 ;;
    mlm[a-z]|mlm[a-z][a-z]|mlm[a-z][a-z][a-z]) return 0 ;;
    vlm[a-z]|vlm[a-z][a-z]|vlm[a-z][a-z][a-z]) return 0 ;;
    xcm[a-z]|xcm[a-z][a-z])                   return 0 ;;
  esac
  return 1
}

# --- collect enc:fam pairs ---
# filter: encoding whitelist, bitmap exclusion, @-macro dep exclusion
# partials (Inf/Sup/Dnom/Numr/Orn) retained for reference appendix
declare -a all_pairs=()
for r in "${roots[@]}" ; do
  while IFS=$'\t' read -r enc fam _wts _shs _path _dep ; do
    enc_match "$enc" || continue
    is_bitmap "$fam" && continue
    [ "$_dep" = "dep" ] && continue
    all_pairs+=("$enc:$fam")
  done < <(scan_families "$r")
done

[ ${#all_pairs[@]} -eq 0 ] && {
  echo "# sample: no families matched filters (encoding: $enc_mode)" >&2
  exit 1
}

# --- write tex preamble ---
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

# --- showcase: one entry per base typeface ---
# exclude numeral/ornament-only families from visual rendering
# dedup figure-style variants: TLF > LF > OsF > TOsF > bare
# dedup encoding: T1 > OT1 > LY1 > rest
awk -F'\t' '!seen[$1]++ { printf "\\showfont{%s}{%s}\n", $4, $5 }' \
  < <(sort -t'	' -k1,1 -k2,2n -k3,3n \
    < <(awk -F: '{
          enc = $1; fam = $2
          if (fam ~ /-(Inf|Sup|Dnom|Numr|Orn)$/) next
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
        }' < <(sort -u < <(printf '%s\n' "${all_pairs[@]}"))
      )
    ) >> "$sample_file"

# --- figure style reference appendix ---
cat >> "$sample_file" <<'REFHDR'
\clearpage
\section*{Figure Style and Variant Reference}

Families with multiple figure-style or glyph-class variants.
The showcase renders one representative per typeface (preferring TLF);
this appendix lists all available variants for font selection.

\medskip
\begin{description}\itemsep0pt
\item[TLF] Tabular Lining Figures --- fixed-width digits at caps height
\item[LF] Proportional Lining Figures --- variable-width digits at caps height
\item[OsF] Proportional Oldstyle Figures --- variable-width digits with ascenders/descenders
\item[TOsF] Tabular Oldstyle Figures --- fixed-width digits with ascenders/descenders
\item[Inf] Inferior Figures --- subscript-sized digits
\item[Sup] Superior Figures --- superscript-sized digits
\item[Dnom] Denominator Figures --- fraction denominator digits
\item[Numr] Numerator Figures --- fraction numerator digits
\item[Orn] Ornaments --- decorative glyphs (fleurons, borders, etc.)
\end{description}

\medskip\hrule\medskip
REFHDR

# group suffixed families by base, list available variants in canonical order
# suffix priority: TLF=1 LF=2 OsF=3 TOsF=4 Inf=5 Sup=6 Dnom=7 Numr=8 Orn=9
awk -F'\t' '
  prev != $1 {
    if (prev != "") printf "\\noindent\\texttt{%s}: %s\\par\n", prev, sufs
    prev = $1; sufs = $2
  }
  prev == $1 && NR > 1 { sufs = sufs ", " $2 }
  END { if (prev != "") printf "\\noindent\\texttt{%s}: %s\\par\n", prev, sufs }
' < <(sort -t'	' -k1,1 -k2,2n -u \
    < <(awk -F: '{
          fam = $2; base = fam; suf = ""; sp = 0
          if      (sub(/-TLF$/,  "", base)) { suf = "TLF";  sp = 1 }
          else if (sub(/-LF$/,   "", base)) { suf = "LF";   sp = 2 }
          else if (sub(/-OsF$/,  "", base)) { suf = "OsF";  sp = 3 }
          else if (sub(/-TOsF$/, "", base)) { suf = "TOsF"; sp = 4 }
          else if (sub(/-Inf$/,  "", base)) { suf = "Inf";  sp = 5 }
          else if (sub(/-Sup$/,  "", base)) { suf = "Sup";  sp = 6 }
          else if (sub(/-Dnom$/, "", base)) { suf = "Dnom"; sp = 7 }
          else if (sub(/-Numr$/, "", base)) { suf = "Numr"; sp = 8 }
          else if (sub(/-Orn$/,  "", base)) { suf = "Orn";  sp = 9 }
          if (suf != "") printf "%s\t%s\t%d\n", base, suf, sp
        }' < <(sort -u < <(printf '%s\n' "${all_pairs[@]}"))
      )
    ) >> "$sample_file"

echo "" >> "$sample_file"
echo '\end{document}' >> "$sample_file"

# --- diagnostic summary ---
read -r nshow < <(grep -c '^\\showfont{' "$sample_file" || echo 0)
read -r nref < <(grep -c '^\\noindent\\texttt{' "$sample_file" || echo 0)
echo "# sample tex written: $sample_file" >&2
echo "# showcase: $nshow families, reference: $nref with variants (encoding: $enc_mode)" >&2
echo "# compile: pdflatex $sample_file" >&2
echo "# if font memory exhaustion: pdflatex --extra-mem-top=10000000 $sample_file" >&2
[ -n "$disc_file" ] && echo "# discovery tsv written: $disc_file" >&2
