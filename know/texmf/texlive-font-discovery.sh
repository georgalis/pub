#!/usr/bin/env bash
# (c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
# revs: 69d4eb2e 20260407 --- encoding filters, family dedup, macro-param fix
# orig: 668973c5 20240706 094141 PDT Sat 09:41 AM 6 Jul 2024 --- texlive-font-package-lister.sh
# texlive-font-discovery.sh [-t sample.tex] [-e conservative|broader|probe] [-u]
#   -t FILE  generate sample tex rendering each discovered family
#   -e MODE  encoding filter for sample (default: conservative)
#            conservative: T1,OT1,LY1  broader: +TS1,IL2,QX,L7x,LGR,T2A-C,T5,CS
#            probe: all encodings (math, symbol, CJK, scripts)
#   -u       scan user texmf only (default: system + user)
# discover installed texlive font packages (.sty) and family definitions (.fd)
# tsv output: phase 1 font packages, phase 2 font families (always unfiltered)
# sample tex: encoding-filtered, deduplicated by family (T1 > OT1 > LY1 > rest)
set -euo pipefail

usage() { sed -n '5,10s/^# //p' "$0" ; exit 1 ; }

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

# validate encoding mode early (-e is only meaningful with -t, harmless without)
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

# collect enc:family pairs across all roots, apply encoding filter
declare -a fam_pairs=()
for r in "${roots[@]}" ; do
  while IFS=$'\t' read -r enc fam _wts _shs _path ; do
    enc_match "$enc" || continue
    fam_pairs+=("$enc:$fam")
  done < <(scan_families "$r")
done

[ ${#fam_pairs[@]} -eq 0 ] && {
  echo "# sample: no families matched encoding filter '$enc_mode'" >&2
  exit 1
}

cat > "$sample_file" <<'TEXDOC'
\documentclass[10pt]{article}
\usepackage[T1]{fontenc}
\usepackage[margin=0.75in]{geometry}
\newcommand{\showfont}[2]{%
  \par\noindent\texttt{#1 / #2}\par
  {\fontfamily{#2}\selectfont
    The quick brown fox jumps over the lazy dog. 0123456789\par
    \textbf{Bold:} The quick brown fox jumps over the lazy dog.\par
    \textit{Italic:} The quick brown fox jumps over the lazy dog.\par
  }\medskip\hrule\medskip
}
\begin{document}
\section*{Installed Font Samples}
Generated by \texttt{texlive-font-discovery.sh}.\medskip\hrule\medskip
TEXDOC

# dedup by family: assign encoding priority, sort by family then priority,
# emit first occurrence per family (T1 preferred > OT1 > LY1 > rest)
awk -F'\t' '!seen[$2]++ { printf "\\showfont{%s}{%s}\n", $3, $2 }' \
  < <(sort -t'	' -k2,2 -k1,1n \
    < <(awk -F: '{
        if ($1 == "T1") p = 1
        else if ($1 == "OT1") p = 2
        else if ($1 == "LY1") p = 3
        else p = 9
        printf "%d\t%s\t%s\n", p, $2, $1
      }' < <(sort -u < <(printf '%s\n' "${fam_pairs[@]}"))
    )
  ) >> "$sample_file"

echo '\end{document}' >> "$sample_file"

# diagnostic counts
read -r nfam < <(grep -c '^\\showfont{' "$sample_file" || echo 0)
echo "# sample tex written: $sample_file ($nfam families, encoding: $enc_mode)" >&2
echo "# compile: pdflatex $sample_file" >&2
