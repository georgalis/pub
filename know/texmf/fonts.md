# True Type Fonts in TexLive User Environment

Adding True Type Fonts to a LaTeX user environment is easy with the `autoinst` program,
from <https://ctan.org/tex-archive/fonts/utilities/fontools/> and bundled with TexLive;
only a few manual steps are required. These instructions are for a
user env install (and the sudo root averse). The steps are:

1. Populating a directory with the (.ttf) font files
2. Running the `autoinst` command on the font files
3. Creating map config data
4. Running `texhash` and `updmap`
5. Confirming available fonts, weights, and shapes, with a demo tex file


## Obtaining and Organizing Font Files

Obtain your TTF files, typically distributed within a zip file.
For each font, create a directory `{FontName}` and extract the zip files into it.
A TeX and Metafont directory `texmf` is used to store fonts and styles.
On Darwin, `~/Library/texmf`; other POSIX systems, use `~/texmf`.
Throughout this document `$texmf` refers to the path on your system.
Fonts are separated into three directories by classification:
`sf` (serif), `ss` (sans serif), and `tt` (typewriter/monospace).
This separation is required because `autoinst` needs a classification flag
(`-serif`, `-sanserif`, `-typewriter`) to generate correct font metadata,
and grouping by class allows batch processing per directory.

```bash
case $(uname) in Darwin) texmf="$HOME/Library/texmf" ;; *BSD|Linux ) texmf="$HOME/texmf" ;; esac
mkdir -p $texmf/fonts/truetype/{sf,ss,tt}
mv {FontName1} "$texmf/fonts/truetype/tt"
mv {FontName2} "$texmf/fonts/truetype/ss"
mv {FontName3} "$texmf/fonts/truetype/sf"
```

### Purge and bootstrap

For iterative development---clean redeployment when changing which fonts
to install---purge the user fonts environment and restore the TTF source
files. This block also documents the totality of directory paths managed
by this procedure: `$texmf/fonts` is the only tree modified, and
`~/kdb/fonts/` is the canonical source archive with `sf/`, `ss/`, and `tt/`
subdirectories matching the layout above.

```bash
# purge user fonts environment (assumes only ttf fonts installed as user)
rm -rf $texmf/fonts
# restore ttf source from canonical archive
mkdir -p              $texmf/fonts/truetype
rsync -a ~/kdb/fonts/ $texmf/fonts/
```


## Running autoinst

Use the `autoinst` command to install the font. There are many options
but you are probably only interested in `-serif` `-sanserif` `-typewriter`;
the other options are usually guessed correctly.
`pdflatex` does not support variable font features---if
your font has `{fontname}/static/*ttf` files, use them;
otherwise with LaTeX, you only get one font from variable ttf files.

### Generalized install loop

Use wildcards to install all fonts in each group with the correct option.
The loop prefers static ttf files when available.

```bash
cd "$texmf/fonts/truetype"
eval "$(
{ # loop on font classes, create autoinst commands, prefer static ttf files
  for fontclass in sf:serif ss:sanserif tt:typewriter ; do
    fontdir="${fontclass%%:*}" ; fontflag="${fontclass##*:}"
    [ -d "$fontdir" ] && { cd "$fontdir"
      find . -type d -path \*/static -prune -o -name \*.ttf \
        -exec dirname \{\} \; | sort -u | while read fpath ; do
          [ -d "$fpath/static" ] && fpath="$fpath/static"
          echo "cd $PWD && echo '### $fontdir/$fpath' && autoinst -$fontflag $fpath/*ttf"
          done # fpath
    cd .. ;} ; done # fontclass
   echo "cd $PWD" ;} # end of loop to create autoinst commands
 )" # eval
```

### Concrete example

```bash
autoinst -typewriter tt/IntelOneMono/ttf/*ttf
autoinst -sanserif   ss/B612/*ttf
autoinst -serif      sf/PlayfairDisplay/static/*ttf
autoinst -serif      sf/IBMPlexSerif/*ttf
autoinst -serif      sf/HeptaSlab/static/*ttf
autoinst -serif      sf/Fraunces/static/*ttf
autoinst -serif      sf/Domine/static/*ttf
autoinst -serif      sf/CrimsonText/*ttf
autoinst -serif      sf/CormorantGaramond/*ttf
autoinst -serif      sf/Arvo/*ttf
```

The last step produces log files helpful for determining font names:

```
playfair.log                     frauncesseventwopt.log              frauncesninept.log
intelonemono.log                 frauncesonefourfourptsupersoft.log  domine.log
ibmplexserif.log                 frauncesonefourfourptsoft.log       crimsontext.log
heptaslab.log                    frauncesonefourfourpt.log           cormorantgaramond.log
frauncesseventwoptsupersoft.log  frauncesnineptsupersoft.log         bsixonetwo.log
frauncesseventwoptsoft.log       frauncesnineptsoft.log              arvo.log
```


## Creating Map Config Data

Set the paths and create the directory, then write an `updmap.cfg` file
with the map files created by `autoinst`.

```bash
a="$texmf/fonts/map"
v="$(tlmgr --version | sed -e '/version/!d' -e 's/.*version //')"
case $(uname) in
  Darwin) b="$HOME/Library/texlive/$v/texmf-config/web2c" ;;
  Linux|*BSD)    b="$HOME/.texlive/$v/texmf-config/web2c" ;;
esac
[ -d "$a" ] && { mkdir -p "$b"
  find "$a" -type f -name \*map -exec basename \{\} \; \
    | sed 's/^/Map /' >"$b/updmap.cfg" ;}
```


## Running texhash and updmap

Rebuild the `ls-R` filename databases with `texhash`, and
configure the user env fonts (and administratively installed fonts)
with the `updmap` command. This step may take tens of seconds.
Repeat this step in the future to add new administratively installed fonts.

```bash
texhash $texmf
updmap --user
```


## Using Fonts in Documents

Reference the style package file (`.sty`) and use the respective font commands.
For package name hints:

```bash
find ./texmf/tex/latex/ -mtime -1 -name \*sty -exec grep ProvidesPackage \{\} \;
```


---


# Font Reference

## Font Selection Terminology

LaTeX addresses fonts through four independent axes. *Family* identifies
the typeface design (e.g., Cormorant Garamond, Intel One Mono). *Encoding*
specifies the character mapping table (T1 for European Latin, OT1 for
the legacy 7-bit scheme). *Weight* and *shape* together describe what
most users call a font's "style"---weight controls thickness (light through
ultra bold), while shape controls posture and variant (upright, italic,
small caps). A common confusion: "bold italic" is not a single attribute
but the intersection of weight `b` and shape `it`. *Figure style* governs
numeral rendering---whether digits align in columns (tabular) or flow
with prose (proportional), and whether they sit on the baseline (lining)
or have ascenders and descenders (oldstyle). These four axes are selected
independently in LaTeX, which is why the commands below specify each
axis separately rather than naming a monolithic "font style."

## Style and Definition Files

The `.sty` file contains font family declarations, usually defines commands
for accessing different weights/shapes, and may include `\DeclareFontFamily` statements.

The `.fd` (Font Definition) files contain `\DeclareFontShape` commands
that map between LaTeX font shapes/weights and actual font files.

Format:

```latex
\DeclareFontShape{<encoding>}{<family>}{<shape>}{<weight>}{<font file>}{}
```

Note the combinations of shapes and weights.
Selection command:

```latex
\fontfamily{fontname-TLF}\fontseries{<weight>}\fontshape{<shape>}\selectfont
```

The examples below demonstrate the least ambiguous selection syntax
for each axis; this is also the modern approach and offers the most flexibility.


## Figure Styles

| Abbreviation | Name                             | Characteristics                        |
|:-------------|:---------------------------------|:---------------------------------------|
| TLF          | Tabular Lining Figures           | fixed-width, all-caps height           |
| TOsF         | Tabular Oldstyle Figures         | fixed-width, with ascenders/descenders |
| LF / CLF     | Proportional Lining Figures      | variable-width, all-caps height        |
| OsF / POsF   | Proportional Oldstyle Figures    | variable-width, with ascenders/descenders |

### Via package options

```latex
\usepackage[osf]{fontname}    % oldstyle figures
\usepackage[lf]{fontname}     % lining figures
\usepackage[tosf]{fontname}   % tabular oldstyle
\usepackage[tlf]{fontname}    % tabular lining
```

### Via font commands

```latex
\fontfamily{fontname-TLF}\selectfont  % tabular lining
\fontfamily{fontname-TOsF}\selectfont % tabular oldstyle
\fontfamily{fontname-LF}\selectfont   % proportional lining
\fontfamily{fontname-OsF}\selectfont  % proportional oldstyle
```

### Common use cases

| Context              | Recommended |
|:---------------------|:------------|
| Tables/financial data | TLF (aligned columns)      |
| Body text            | OsF (blends with lowercase) |
| Headlines            | LF (matches caps)           |
| Technical material   | TLF (consistent spacing)    |

Switching styles mid-document:

```latex
{\addfontfeatures{Numbers=OldStyle} Text with oldstyle figures}
```


## Shape Codes

| Code | Meaning        |
|:-----|:---------------|
| n    | normal/regular |
| it   | italic         |
| sl   | slanted        |
| sc   | small caps     |
| b    | bold           |
| bi   | bold italic    |
| bx   | bold extended  |


## Weight Codes

| Code | Meaning     |
|:-----|:------------|
| ul   | ultra light |
| el   | extra light |
| l    | light       |
| m    | medium      |
| sb   | semibold    |
| b    | bold        |
| eb   | extra bold  |
| ub   | ultra bold  |


## Optical Sizes and Point Sizes

LaTeX fonts are typically available in any size because they are scalable vector fonts.
However, some fonts have optical sizes---different designs optimized for different
size ranges. These are usually indicated in the `.fd` file with size ranges:

```latex
\DeclareFontShape{T1}{fontname-TLF}{m}{n}{
  <-8> fontname-light
  <8-14> fontname-regular
  <14-> fontname-display
}{}
```

### Standard size commands

```latex
{\tiny Text}          % Typically 5pt
{\scriptsize Text}    % Typically 7pt
{\footnotesize Text}  % Typically 8pt
{\small Text}         % Typically 9pt
{\normalsize Text}    % Typically 10pt
{\large Text}         % Typically 12pt
{\Large Text}         % Typically 14pt
{\LARGE Text}         % Typically 17pt
{\huge Text}          % Typically 20pt
{\Huge Text}          % Typically 25pt
```

### Exact sizes and scaling

```latex
% Exact size with leading
{\fontsize{12}{14}\selectfont Text} % 12pt with 14pt leading

% Package-level scaling
\usepackage[scale=1.2]{fontname}  % Scales all sizes by 1.2

% Font declaration scaling
\DeclareFontFamily{T1}{fontname-TLF}[Scale=1.2]{}

% Relative scaling between fonts
\usepackage[scale=MatchLowercase]{fontname}  % Scales to match x-height of main font
\usepackage[scale=MatchUppercase]{fontname}  % Scales to match caps height
```


## Drop Caps (Lettrine)

Decorative initial capital letters (drop caps) with ornamentation or
simply larger, with subsequent lines wrapping around them.

```latex
% Preamble
\usepackage{lettrine}

% Document
\lettrine[options]{Initial}{Following text}
```
