---
name: transmission-load
description: Semantic pressure and cognitive pacing. Governs peak compression, concept onset rate, consolidation enforcement, and prosodic cadence. Apply to position instantaneous cognitive load---low for smooth development under fatigue or resistance, high for compact expert reference, specification, and prompt artifacts where compression is the deliverable.
---

# Transmission Load

Positions the *instantaneous* cognitive load of prose against its total
content. Reception-class controls set total energy---how much
complexity a document carries. This sets power---how much arrives per
instant. The same content delivered through a short heavy conductor or
a long light one.

Relaxed precision is precision relocated, never precision removed.
Concentrated precision is the identical operation run the other
direction, and the dial does not distinguish them.

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

## Dial Semantics

Dials define a target band, not a ceiling. A low peak setting calls for
compression; it does not merely tolerate it.

Direction is uniform across the transmission skills: **0.0 is the
compact, mobile, forceful pole; 1.0 is the steady, gradual,
low-pressure pole.**

Values are read by position, not by scale. `20`, `2.0`, `0.2`, and
`1/5` all set the same dial to the same place. Percent or decimal, as
convenient.

## Invocation

`/transmission-load 0.2` sets all scalar dials to that band.
`/transmission-load peak=0.2 onset=0.5 cadence=misura` overrides
individually. Bare invocation defaults to 0.6.

## Qualities

### peak --- peak compression
Density of high-wattage figures per unit of prose. The inventory:
antithesis and negated contrast, chiasmus, aphorism, dense
phrase-as-lemma coinage, triple constructions---any formulation whose
entire force lands in a single clause. Such figures are maximally
precise per token and maximally expensive per instant.

- **0.0** Compression sought. Aphoristic construction is the register.
  Expert reference cards, LLM prompt artifacts, specifications written
  where no prior detail existed, research abstracts. The reader has
  pre-paid; charge them.
- **0.5** One high-wattage figure per paragraph, positioned at
  paragraph close where accumulated context has covered its cost.
- **1.0** No peaks. Every contrast unpacked across a sentence span; the
  contrast develops rather than detonates.

**Relocation, both directions.** Downward: identify the figure's two
poles, give each its own predication, let contrast emerge from
adjacency, and spend the recovered emphasis on ordering so the decisive
pole lands last. Upward: collapse a developed contrast into a single
predication, elide the connective, let juxtaposition carry the logic.

Failure at 0.0 outside its context: serial detonation. Each formulation
is admirable; the sequence is exhausting. Comprehension survives; the
settled attentive state does not. Failure at 1.0: prose without
profile---nothing quotable, nothing carried forward.

### onset --- concept onset rate
New load-bearing concepts introduced per paragraph. Each opens a
comprehension account the reader services until consolidation closes
it; parallel open accounts compound.

- **0.0** Parallel introduction. Concepts arrive together and are
  disambiguated by their relations. Taxonomies, enumerations, reference
  matter, abstracts.
- **0.5** One new load-bearing concept per paragraph; supporting detail
  unrestricted.
- **1.0** One per section. Intervening paragraphs develop, apply, and
  consolidate.

Throttled onset above failed consolidation only slows the leak.

### consolidation --- establishment enforcement
Whether compressed formulations earn their compression before invoking
it.

The `repetition-methodology` skill governs the mechanism; this dial
governs how strictly it applies. The primitive pattern it enforces:
first occurrence carries scaffolding sufficient for meaning; a
proximate second occurrence, in the same or adjacent sentence, signals
retention warrant rather than passing notice; subsequent occurrences
rotate syntactic position and modal frame. Only then does back-
reference retrieve the full apparatus at compressed cost. Interval
calibration follows---distant enough to refresh, near enough to sustain
recall.

- **0.0** Advisory. Coinage travels on first mention. Expert readers,
  dense reference artifacts, prompt material where the consuming model
  holds the definition already.
- **0.5** Enforced for terms invoked more than twice.
- **1.0** Full enforcement plus interval calibration. No compressed
  invocation without completed establishment.

Failure at 0.0 with a general reader: compression collapses to opaque
shorthand, and the back-reference points at a foundation never laid.

### cadence --- prosodic cadence (discrete)
Sentence-rhythm profile. Cadence is the carrier wave across which
relocated precision spreads.

- `staccato` --- short declaratives dominant, suspension free, high
  onset tolerance. Recruitment, roster and catalog prose, alert
  register, reference cards. Re-concentrates load by shortening the
  span available to distribute it.
- `misura` --- alternating measure. Medium sentences with periodic
  short declaratives as punctuation; balanced resolution and
  suspension. General-purpose.
- `legato` --- long-breath sentences, subordination-rich, each
  resolving fully before the next begins. The span-providing mode;
  pairs with high peak settings.

Configuration check: `staccato` with `peak=1.0` is contradictory---
short sentences cannot host distributed precision. Resolve toward
`misura`, or raise peak. Zone-splitting resolves it properly: frame
prose in `misura`, catalog sections in `staccato`.

## Composition Order

Distribution is architecture, not polish. Set cadence, position onset
in the outline, run consolidation for every planned compression, then
audit drafted paragraphs against the peak band---relocating in
whichever direction the band requires.

## Reverse Diagnosis

- Reader re-reads for meaning rather than for agreement ---> peak below
  the audience's band.
- Prose reads flat, correct, unmemorable ---> peak above band; nothing
  concentrated enough to retain.
- Reader loses the thread mid-section though sentences are simple --->
  onset too low for the audience.
- A term recurs and lands with less weight than its first appearance
  ---> consolidation incomplete, or interval too long.
- Rhythm feels mechanical ---> cadence mode fighting the peak band.

## Cross-Skill

- **transmission-vantage** --- independent. A perspectivally flat
  aphorism detonates exactly as hard as a nested one.
- **transmission-landing** --- landing places the pressure events that
  this skill's band otherwise excludes. Where peak runs high, landing
  must work through placement and recurrence instead of contrast.
- **max-density** --- an adjacent, self-standing skill. Low peak with
  low consolidation approximates its delivery profile but not its
  generative inventory; the parameters position prose, they do not
  stock a lexicon. Invoke it directly when that inventory is wanted.
- **reception** --- complementary. Reception sets the complexity
  ceiling; this shapes delivery beneath it.
