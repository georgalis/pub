# texmf

Documentation and tooling for TexLive user environment management---font
integration, discovery, and document composition in `pdflatex` workflows
across Darwin, BSD, and Linux platforms.

All procedures target the user-context `texmf` tree (`~/Library/texmf`
on Darwin, `~/texmf` elsewhere) and require no root privileges.


## Contents

- [fonts.md](fonts.md) --- TTF font installation via `autoinst` into user
  `texmf`, including iterative purge/bootstrap, `updmap.cfg` generation,
  and font selection reference (families, weights, shapes, figure styles,
  optical sizes, lettrine)

- [texlive-font-discovery.md](texlive-font-discovery.md) --- script to
  inventory installed font packages (`.sty`) and family definitions (`.fd`)
  with optional sample `.tex` generation for visual confirmation
