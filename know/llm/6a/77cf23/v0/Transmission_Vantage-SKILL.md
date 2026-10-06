---
name: transmission-vantage
description: Deixis and viewpoint positioning. Governs frame nesting, viewpoint dwell, attribution mode, transition contiguity, and meta-commentary. Apply when the reader's cost of tracking who speaks, from what vantage, at what remove should be deliberately set---low for smooth executive delivery, high for compact expert reference where layered framing earns its price.
---

# Transmission Vantage

Positions the reader's cost of knowing *where a statement stands*---who
speaks, from what vantage, at what meta-level. Every perspectival shift
requires re-anchoring; every nested frame holds another anchor open.
Re-anchoring cost is neither good nor bad. It is a price, and this skill
sets whether the document pays it.

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

## Dial Semantics

Dials define a target band, not a ceiling. A setting names the region of
the solution space the prose should occupy, and the prose moves toward
that region from either direction. Low settings do not merely permit
mobile vantage; they call for it.

Direction is uniform across the transmission skills: **0.0 is the
compact, mobile, forceful pole; 1.0 is the steady, gradual,
low-pressure pole.**

Values are read by position, not by scale. `33`, `3.3`, `0.33`, and
`1/3` all set the same dial to the same place. Percent or decimal, as
convenient.

## Invocation

`/transmission-vantage 0.75` sets all scalar dials to that band.
`/transmission-vantage 0.75 dwell=0.4 attribution=agent` overrides
individually; stated values win, the master governs the rest.
Bare `/transmission-vantage` defaults to 0.6.

Zone configuration is legitimate and often correct: frame prose at one
setting, quoted or demonstrative material at another. Declare the zones.

## Qualities

### nesting --- frame-nesting depth
Perspectival layers per sentence. Each layer---speaker stance, framing
verb, embedded self-reference---is an anchor held open until the
sentence resolves.

- **0.0** Layered framing sought. Three or more strata per sentence
  where precision warrants: stance about a claim about a source.
  Legal hedging, epistemically fraught findings, expert reference where
  the provenance of every assertion is itself information.
- **0.5** Two layers. A framing verb may carry one embedded stance.
- **1.0** One layer. Every sentence speaks from a flat vantage; framing
  collapses into direct predication. "The report provides the
  preliminary account," not "I present this as the account's own
  account of itself."

Failure at low settings: readers re-read to resolve who claims what
about whom. Failure at high settings: contested attribution flattened
into false directness; provenance lost where provenance mattered.

### dwell --- viewpoint dwell
Span a vantage persists before shifting.

- **0.0** Free cutting. Vantage may shift per clause. Compact
  comparative material, roster and catalog prose, anything whose
  structure *is* the rotation among viewpoints.
- **0.5** Vantage persists across a sentence group; shifts prefer
  paragraph seams.
- **1.0** One vantage per section. Shifts only at announced structural
  boundaries, never mid-development.

Point-of-view changes are scene cuts. Rapid cutting produces
perspectival whiplash in a settled reader and rhythmic energy in a
scanning one. The reader's arrival state decides which.

### meta --- meta-commentary
Presence of epistemic performance the reader did not request:
justification, disclaimer, credibility signaling.

- **0.0** Meta-commentary sought. Every claim anticipates challenge and
  arrives pre-defended. Audit response, litigation-adjacent finding,
  adversarial review.
- **0.5** Meta only where a reasonable reader would actually pause.
- **1.0** None. Sources identified by function, never defended, ranked,
  or apologized for. The document trusts its own footing.

Note the trap at low settings outside adversarial context: defending an
uncontested claim raises the doubt it forestalls.

### attribution --- attribution mode (discrete)
Where claims are anchored. Categorical.

- `agent` --- anchored to persons. Maximum accountability; maximum
  stance-tracking cost, since the reader must model who claims, with
  what interest, against whom. Use when responsibility is the message.
- `artifact` --- anchored to documents and presentations. The container
  is inert; no interest-modeling required. Default for executive
  delivery.
- `impersonal` --- anchored to conditions and states. Zero attribution
  surface; suited to settled fact and consensus finding. Reads as
  evasive where accountability is expected.

Descend `agent` -> `artifact` -> `impersonal` as the reader's need to
evaluate the source falls. Mixed modes are permitted; each mode change
is a dwell event and spends from that budget.

### bridging --- transition contiguity
How successive sentences inherit vantage. Theme-rheme ordering is the
mechanism: open on given material, introduce the new in predicate
position.

- **0.0** Cut-dominant. Sentences open cold. Staccato, energetic,
  recruitment-mode; the scroller and the reference card both live here.
- **0.5** Bridge-dominant, cuts reserved for deliberate emphasis.
- **1.0** Fully contiguous. Every sentence opens on given material;
  every section receives its predecessor's closing concept.

Failure at 1.0: monotone glide. Without cuts, the salience system loses
its contrast medium---coordinate with transmission-landing so that the
cuts that remain fall on the imperative.

## Composition Order

Perspectival pass after synthesis: set nesting to band, consolidate or
fragment vantage spans to dwell, position meta-commentary, normalize
attribution, set transition ratio.

## Reverse Diagnosis

Read the defect back to the dial.

- Reader asks "who is saying this, about whose statement" ---> nesting
  set below the audience's tolerance.
- Reader reports the piece as "jumpy" or "hard to follow" though every
  sentence is clear ---> dwell too low.
- Reader becomes skeptical of claims that were never in dispute --->
  meta too low for a non-adversarial context.
- Reader tracks personalities instead of findings ---> attribution
  should descend toward artifact.
- Prose is clear but inert, nothing stands out ---> bridging too high;
  no cuts remain to carry emphasis.

## Cross-Skill

- **transmission-load** --- flattening nesting reduces syntactic cost
  but not semantic pressure. A flat sentence still detonates. Both
  skills act or neither effect lands.
- **transmission-landing** --- `artifact` attribution with high
  bridging mints the uniformity that landing spends. A cut coinciding
  with the imperative is the sanctioned use of cold-open emphasis.
- **reception** --- orthogonal. Reception sets complexity magnitude;
  this sets vantage topology.
