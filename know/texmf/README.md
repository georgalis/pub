# texmf

Documentation and tooling for TexLive user environment management---font
integration, discovery, and document composition in `pdflatex` workflows
for user-context.

(c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
<!-- orig: 20260406 051612 PDT Mon 05:16 AM 6 Apr 2026 -->

## Contents

- [fonts.md](./fonts.md) --- TTF font installation via `autoinst` into user
  `texmf`, including iterative purge/bootstrap, `updmap.cfg` generation,
  and font selection reference (families, weights, shapes, figure styles,
  optical sizes, lettrine)

- [texlive-font-discovery.md](./texlive-font-discovery.md) --- script to
  inventory installed font packages (`.sty`) and family definitions (`.fd`)
  with optional sample `.tex` generation for visual confirmation
