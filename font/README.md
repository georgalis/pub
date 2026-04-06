# Font Directory

Self-hosted woff2 web fonts serving three distinct typographic
registers: a humanist serif for hierarchy and emphasis, an
aviation-derived sans for body text, and an accessibility-focused
monospace for code.

`@font-face` declarations live in `faces.css`. Consuming stylesheets
import it as `@import url('./font/faces.css')`. All `url()` paths are
relative---the fonts load under both `http(s)://` and `file://`
protocols without modification.

---

## EB Garamond

Revival of Claude Garamond's mid-16th-century roman types paired with
Robert Granjon's italic, sourced from the 1592 Egenolff-Berner specimen
sheet printed by Conrad Berner in Frankfurt. Initiated in 2011 by Georg
Mayr-Duffner (Austria) under the SIL Open Font License; bold weights
completed by Octavio Pardo from 2017 onward. The "EB" abbreviates
Egenolff-Berner, identifying the specific historical specimen rather
than the broader Garamond tradition[^1].

Old-style serif construction: moderate stroke contrast, oblique stress
axis, bracketed serifs, calligraphic italic with pronounced cursive
movement. The latin-ext subset carried here supports diacritics across
Central and Eastern European languages.

**Typographic role:** headings in upright weights; inline emphasis in
italic. Two registers of one family---hierarchy through scale, emphasis
through posture.

<style>
@font-face {
  font-family: 'EB Garamond Specimen';
  src: url('eb-garamond-v32-latin-ext-regular.woff2') format('woff2');
  font-weight: 400; font-style: normal;
}
@font-face {
  font-family: 'EB Garamond Specimen';
  src: url('eb-garamond-v32-latin-ext-italic.woff2') format('woff2');
  font-weight: 400; font-style: italic;
}
@font-face {
  font-family: 'EB Garamond Specimen';
  src: url('eb-garamond-v32-latin-ext-700.woff2') format('woff2');
  font-weight: 700; font-style: normal;
}
</style>

<div style="font-family: 'EB Garamond Specimen', Georgia, serif; font-size: 1.5em; line-height: 1.4; margin: 1em 0;">
<div style="font-weight: 700; margin-bottom: 0.25em;">The quick brown fox jumps over the lazy dog</div>
<div style="font-weight: 400;">Garamond's types represent a touchstone to which designers have returned ever since.</div>
<div style="font-style: italic;">Granjon's italic---calligraphic movement within typographic discipline.</div>
</div>

### Weights hosted

| Weight | Style  | File |
|--------|--------|------|
| 400    | normal | `eb-garamond-v32-latin-ext-regular.woff2` |
| 400    | italic | `eb-garamond-v32-latin-ext-italic.woff2` |
| 500    | normal | `eb-garamond-v32-latin-ext-500.woff2` |
| 500    | italic | `eb-garamond-v32-latin-ext-500italic.woff2` |
| 600    | normal | `eb-garamond-v32-latin-ext-600.woff2` |
| 600    | italic | `eb-garamond-v32-latin-ext-600italic.woff2` |
| 700    | normal | `eb-garamond-v32-latin-ext-700.woff2` |
| 700    | italic | `eb-garamond-v32-latin-ext-700italic.woff2` |
| 800    | normal | `eb-garamond-v32-latin-ext-800.woff2` |
| 800    | italic | `eb-garamond-v32-latin-ext-800italic.woff2` |

---

## B612

Commissioned by Airbus in 2010 through a research collaboration with
ENAC (Ecole Nationale de l'Aviation Civile) and Universite de Toulouse
III, designed by Nicolas Chauveau and Thomas Paillot at Intactile DESIGN
with typographic research by Jean-Luc Vinot. The name references
asteroid B-612 from Saint-Exupery's *Le Petit Prince*---an aviator's
literary tradition naming an aviator's typeface[^2].

Engineered for cockpit display legibility under degraded conditions:
low ambient light, oblique viewing angles, vibration, high cognitive
load. Design features include ink traps (repurposed as light traps for
screen rendering), uniform stroke weight for consistent glyph density,
and generous internal counters. The font underwent empirical validation
for reduced visual fatigue and cognitive load in critical information
display. Published under the Eclipse Public License via the Polarsys
project in 2017; awarded the Observeur du Design Industry Star in 2018.

**Typographic role:** body text. The font's optimization for sustained
reading under adverse conditions translates directly to comfortable
long-form screen reading---the cockpit discipline serves the reader.

<style>
@font-face {
  font-family: 'B612 Specimen';
  src: url('b612-v13-latin-regular.woff2') format('woff2');
  font-weight: 400; font-style: normal;
}
@font-face {
  font-family: 'B612 Specimen';
  src: url('b612-v13-latin-italic.woff2') format('woff2');
  font-weight: 400; font-style: italic;
}
@font-face {
  font-family: 'B612 Specimen';
  src: url('b612-v13-latin-700.woff2') format('woff2');
  font-weight: 700; font-style: normal;
}
</style>

<div style="font-family: 'B612 Specimen', sans-serif; font-size: 1em; line-height: 1.6; margin: 1em 0;">
<div style="font-weight: 400; margin-bottom: 0.25em;">The quick brown fox jumps over the lazy dog</div>
<div style="font-weight: 700; margin-bottom: 0.25em;">Bold: Altitude 3500ft --- Heading 270 --- IAS 250kt</div>
<div style="font-style: italic;">Italic: Designed for clarity when clarity is not optional.</div>
</div>

### Weights hosted

| Weight | Style  | File |
|--------|--------|------|
| 400    | normal | `b612-v13-latin-regular.woff2` |
| 400    | italic | `b612-v13-latin-italic.woff2` |
| 700    | normal | `b612-v13-latin-700.woff2` |
| 700    | italic | `b612-v13-latin-700italic.woff2` |

---

## Intel One Mono

Designed by Frere-Jones Type in partnership with Intel and VMLY&R,
released 2023 under the SIL Open Font License. Distinguished from other
developer monospace fonts by its explicit co-design methodology: a panel
of low-vision and legally blind developers provided iterative feedback
across more than a dozen live coding sessions, identifying character
differentiation failures invisible to normally-sighted testers[^3].

Key design characteristics: reduced x-height (counter to monospace
convention) to amplify ascender/descender differentiation and create
more distinctive word shapes; exaggerated delimiters (braces, brackets,
parentheses, slashes) for rapid syntactic parsing; aggressive character
individuation---the `M`/`N`, `e`/`c`, `x`/`y`, and `I`/`l`/`1`
confusability sets receive specific corrective treatment. The steep
italics are unusually expressive for a monospace family. Covers 200+
Latin-script languages.

**Typographic role:** preformatted code blocks and inline code. The
accessibility-first design methodology makes the font legible at the
reduced sizes typical of code presentation within prose contexts.

<style>
@font-face {
  font-family: 'Intel One Mono Specimen';
  src: url('intel-one-mono-v2-latin-regular.woff2') format('woff2');
  font-weight: 400; font-style: normal;
}
@font-face {
  font-family: 'Intel One Mono Specimen';
  src: url('intel-one-mono-v2-latin-italic.woff2') format('woff2');
  font-weight: 400; font-style: italic;
}
@font-face {
  font-family: 'Intel One Mono Specimen';
  src: url('intel-one-mono-v2-latin-700.woff2') format('woff2');
  font-weight: 700; font-style: normal;
}
</style>

<div style="font-family: 'Intel One Mono Specimen', monospace; font-size: 0.9em; line-height: 1.5; margin: 1em 0;">
<div style="font-weight: 400; margin-bottom: 0.25em;">The quick brown fox jumps over the lazy dog</div>
<div style="font-weight: 400; margin-bottom: 0.25em;">0O Il1| {}[]() &lt;= =&gt; != === // /* */</div>
<div style="font-weight: 700; margin-bottom: 0.25em;">Bold: fn main() { println!("Hello, world!"); }</div>
<div style="font-style: italic;">Italic: # comment --- clarity under cognitive load</div>
</div>

### Weights hosted

| Weight | Style  | File |
|--------|--------|------|
| 300    | normal | `intel-one-mono-v2-latin-300.woff2` |
| 300    | italic | `intel-one-mono-v2-latin-300italic.woff2` |
| 400    | normal | `intel-one-mono-v2-latin-regular.woff2` |
| 400    | italic | `intel-one-mono-v2-latin-italic.woff2` |
| 500    | normal | `intel-one-mono-v2-latin-500.woff2` |
| 500    | italic | `intel-one-mono-v2-latin-500italic.woff2` |
| 600    | normal | `intel-one-mono-v2-latin-600.woff2` |
| 600    | italic | `intel-one-mono-v2-latin-600italic.woff2` |
| 700    | normal | `intel-one-mono-v2-latin-700.woff2` |
| 700    | italic | `intel-one-mono-v2-latin-700italic.woff2` |

---

## Typographic Strategy

The three families occupy complementary perceptual registers tuned to
their functional roles:

**Temporal depth** (EB Garamond): humanist forms from the 1540s--1560s
carry the visual authority of long tradition---appropriate for headings
that establish document structure, and for emphasis that signals
interpretive weight within body text.

**Operational clarity** (B612): engineered for sustained reading under
cognitive pressure, the sans-serif body text prioritizes fatigue
reduction and information throughput over aesthetic refinement---the
typeface disappears in service of the content.

**Technical precision** (Intel One Mono): accessibility-driven character
individuation at code-presentation scale, where a single misread glyph
changes semantics---the monospace register where visual ambiguity
carries functional cost.

Each font was designed for a context where misreading has
consequences---the cockpit, the courtroom of typographic history, the
code editor. A stylesheet that composes all three inherits that shared
discipline as coherent legibility across registers.

---

## Licensing

| Family | License | Source |
|--------|---------|--------|
| EB Garamond | SIL Open Font License 1.1 | [github.com/octaviopardo/EBGaramond12](https://github.com/octaviopardo/EBGaramond12) |
| B612 | Eclipse Public License 1.0 | [github.com/polarsys/b612](https://github.com/polarsys/b612) |
| Intel One Mono | SIL Open Font License 1.1 | [github.com/intel/intel-one-mono](https://github.com/intel/intel-one-mono) |

---

[^1]: The Egenolff-Berner specimen of 1592 remains the primary documentary source for Garamond's roman types; the "EB" prefix distinguishes this digitization from the many Garamond revivals based on later (often misattributed) sources. Georg Mayr-Duffner's original work covered the 8pt and 12pt optical sizes; Octavio Pardo's continuation from 2017 added the five-weight range (Regular through ExtraBold) carried here. See [googlefonts.github.io/ebgaramond-specimen](https://googlefonts.github.io/ebgaramond-specimen/).

[^2]: The Airbus research program validated B612 against existing cockpit fonts for legibility under vibration, low contrast, and high cognitive load. The font's ink traps---small indentations at stroke junctions---function as light traps on screen, preventing optical fill-in at small sizes or low resolution. See [b612-font.com](https://www.b612-font.com/).

[^3]: Frere-Jones Type's co-design process with low-vision developers produced character differentiation strategies absent from conventionally-designed monospace fonts. The reduced x-height---contrary to the prevailing monospace trend of enlarged x-heights---was a direct finding from the accessibility panel: taller ascenders and descenders create more distinct word shapes for readers relying on peripheral or degraded vision. See [intel.com/content/www/us/en/company-overview/one-monospace-font.html](https://www.intel.com/content/www/us/en/company-overview/one-monospace-font.html).
