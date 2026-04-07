# texmf

Documentation and tooling for TexLive user environment management---font
integration, discovery, and document composition in `pdflatex` workflows
for user-context.

(c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
<!--
revs: 69d547f1 20260407 110745 PDT Tue 11:07 AM 7 Apr 2026 --- script/md breakout
orig: 20260406 051612 PDT Mon 05:16 AM 6 Apr 2026
-->

## Contents

- [fonts.md](./fonts.md) --- user font management: discovery of installed
  font packages and family definitions, TTF installation via `autoinst`
  into user `texmf`, `updmap.cfg` generation, and font selection reference
  (families, weights, shapes, figure styles, optical sizes, lettrine)

- [texlive-font-discovery.sh](./texlive-font-discovery.sh) --- inventory
  installed font packages (`.sty`) and family definitions (`.fd`) across
  system and user `texmf` trees; optional sample `.tex` generation for
  visual confirmation
