# TexLive Font Discovery

(c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
<!--
revs: 69d3a0ce 20260406 050222 PDT Mon 05:02 AM 6 Apr 2026 --- texlive-font-discovery.md
orig: 668973c5 20240706 094141 PDT Sat 09:41 AM 6 Jul 2024 --- texlive-font-package-lister.sh
-->

Identifying installed fonts in a TexLive environment is difficult because
font metadata is distributed across `.sty` packages (which set document
defaults) and `.fd` definition files (which declare available weight/shape
combinations). This script scans both system and user `texmf` trees to
produce a machine-parseable inventory of installed font packages and
font family definitions, with an optional sample `.tex` document for
visual confirmation.


## Usage

```
texlive-font-discovery.sh [-t sample.tex] [-u]
  -t FILE  generate sample tex document rendering each discovered family
  -u       scan user texmf only (default: system + user)
```


## Script

```bash
#!/usr/bin/env bash
# (c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
# revs: 69d3a0ce 20260406 050222 PDT Mon 05:02 AM 6 Apr 2026 --- texlive-font-discovery.sh
# orig: 668973c5 20240706 094141 PDT Sat 09:41 AM 6 Jul 2024 --- texlive-font-package-lister.sh
# discover installed texlive font packages (.sty) and family definitions (.fd)
# tsv output: phase 1 font packages, phase 2 font families
set -euo pipefail

usage() { sed -n '3,5s/^# //p' "$0" ; exit 1 ; }

# --- platform texmf root resolution ---
declare -a roots=()
texmf_user= texmf_sys= user_only=0 sample_file=

read -r texmf_user < <(
  case $(uname) in
    Darwin)     echo "$HOME/Library/texmf" ;;
    *BSD|Linux) echo "$HOME/texmf" ;;
  esac
)

while getopts "t:uh" opt ; do
  case $opt in
    t) sample_file="$OPTARG" ;;
    u) user_only=1 ;;
    *) usage ;;
  esac
done

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

# collect unique enc:family pairs across all roots
declare -a fam_pairs=()
for r in "${roots[@]}" ; do
  while IFS=$'\t' read -r enc fam _wts _shs _path ; do
    fam_pairs+=("$enc:$fam")
  done < <(scan_families "$r")
done

cat > "$sample_file" <<'TEXDOC'
\documentclass[10pt]{article}
\usepackage[T1]{fontenc}
\usepackage[margin=0.75in]{geometry}
\newcommand{\showfont}[2]{
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

printf '%s\n' "${fam_pairs[@]}" | sort -u \
  | while IFS=: read -r enc fam ; do
      printf '\\showfont{%s}{%s}\n' "$enc" "$fam"
    done >> "$sample_file"

echo '\end{document}' >> "$sample_file"
echo "# sample tex written: $sample_file" >&2
echo "# compile: pdflatex $sample_file" >&2
```


## Output Format

Phase 1 (font packages) produces tab-separated fields:
package name, class (`rm`, `sf`, `tt`, or comma-joined), version string, file path.

Phase 2 (font families) produces tab-separated fields:
encoding, family name, comma-joined weight codes, comma-joined shape codes, file path.

Both phases are prefixed with `#` comment headers suitable for
downstream parsing with `grep -v '^#'` or `awk` column extraction.


## Sample Document

The `-t` flag writes a `.tex` file that renders every discovered
font family in normal, bold, and italic with pangram text.
Compile with `pdflatex` for visual comparison. Fonts that lack
a bold or italic shape will fall back to the nearest available
substitute per NFSS rules---this is expected and diagnostic
(a missing shape in the sample confirms the `.fd` weight/shape
inventory from phase 2).
