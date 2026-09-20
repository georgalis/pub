---
name: melopoeia-development
description: Development record for the melopoeia skill --- naming collisions yielded to companion instruments, decisions taken with the alternatives not taken, and deferred optimizations to reconsider when the whole instrument set is tuned together.
---

# Melopoeia --- Development Record

The skill artifact carries the working solution and no ambiguity. This
document carries everything removed from it: the collisions melopoeia
yielded rather than contested, the decisions taken with the alternatives
they displaced, and the optimizations deferred until the instrument set is
tuned as a set.

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

    org 6a93c973 20260829 231059 PDT Sat 11:10 PM 29 Aug 2026

This document is the authoritative artifact for the request effort. A
future session possessing only this file, the skill, and the ontology has
everything required to resume, audit, or extend the work. Where a later
round narrows or reverses a decision recorded here, the reversal and its
rationale are recorded in place rather than silently dropped.

---

## Contents

- [Standing Strategy](#standing-strategy)
- [Collision Inventory](#collision-inventory)
- [Decisions Taken](#decisions-taken)
- [Deferred Optimizations](#deferred-optimizations)
- [Boundary Declarations](#boundary-declarations)
- [Distribution Notes](#distribution-notes)
- [Revision Log](#revision-log)

---

## Standing Strategy

**Melopoeia yields on every naming collision with a companion instrument,
without contest, until the whole set is optimized together.** The goal is
a set whose instruments are each optimal alone and composable without
collision. That goal is not reachable one instrument at a time, because
the optimal name for a melopoeia parameter is frequently the name a prior
instrument already spent on something else, and unilateral reclamation
would break artifacts already composed.

The yield rule is therefore an interim, not a preference. Every yielded
name is recorded below with the name it would have taken, so that a
later pass optimizing the set can restore the better name in both places
at once.

**Recorded yields cost precision.** `flowing` is a plainer word than
`legato` and says less about what the setting measures. Accepting that
cost knowingly is the point of recording it.

---

## Collision Inventory

Keys in use across the companion instruments, checked against every name
melopoeia wanted.

### Yielded

| melopoeia wanted | holder | holder's use | melopoeia took | cost |
|---|---|---|---|---|
| `legato` | `transmission-load` | a `cadence` value: long-breath sentences | `flowing` | Loses the musical precision of a slur. `flowing` names an effect where `legato` named a technique, and the effect is one a reader might attribute to sentence length rather than articulation. |
| `register` (as the class name for bipolar scalars) | `coinage` | a denoted key: `somatic`, `operational`, `credential` | `polar` | Small. `polar` is accurate and arguably clearer, but the essay's own vocabulary says "register" of vowel color, and the skill now uses that word in prose while it names no key. |
| `scale` | `coinage` | the active unit of recurrence, stated as a band | `band` | Small. `band` is the better word for a range anyway; this yield improved the result. |
| `reach` | `coinage` | destination: how far a form travels | `ear` | None. `ear` is better for this instrument. |
| `grave` | `coinage` | subject weight licensing sub-lexical devices | `divergent` | None, and the two are genuinely different gates. See Boundary Declarations. |

### Held --- shared keys, same meaning, no collision

`purpose` and `span` are used identically here and in `coinage`. A key
meaning the same thing in two instruments is compatibility, not collision,
and should stay identical when the set is tuned.

### Held --- checked and clear

`dark`, `rough`, `sustained`, `suspended`, `modulated`, `incidental`,
`transparent`, `monodic`, `family`, `channel`, `perform`, `mute`, `voice`,
`figure`. None appears as a key or a denoted value in `transmission`,
`transmission-load`, `transmission-land`, `transmission-vantage`, or
`coinage`.

### Near-misses worth watching

- `sustained` is a melopoeia key *and* was a candidate region name inside
  `flowing`. The region was renamed `mixed` to prevent the internal
  collision. Any future addition to the grain group should be checked
  against the measure group's key names.
- `single` (`transmission-land`) and `transparent` (here) both concern
  recurrence and do not collide. The objects differ; see Boundary
  Declarations.
- `varied` (`coinage`) and `modulated` (here) both concern variation
  across returns. Different objects---rotation of a nominated form against
  rhythmic variance of sentence length---and the near-synonymy
  is a documentation hazard rather than a functional one.

---

## Decisions Taken

### D1 --- Two scalar kinds, polar and intensity

**Taken.** Polar scalars have no yield direction and no light pole.

*The alternative not taken:* force every setting onto the house's single
direction, so that a configuration reads uniformly and yield is stated
once for the whole instrument. Rejected because the polar settings would
then have to be renamed as intensities of something---`dark` becoming a
depth measure with brightness as its absence---and the instrument would
lose the ability to say *which* sound. The observable failure of that
alternative is prose tuned toward an imagined sonic neutral, which is the
one setting carrying nothing.

*Cost accepted:* a reader of a melopoeia calibration must know which kind
each key is before knowing what its extremes mean, where a
`transmission` calibration reads without that knowledge. Mitigated by
grouping: `divergent` sits alone in the document group and the other three
intensities sit together in `carry`, so the polar settings are exactly the
`grain` and `measure` groups.

*Reconsider when:* the set is tuned together. If `transmission` or
`coinage` acquires a second bipolar setting, the two-kind distinction
becomes a house property rather than a melopoeia exception, and should be
promoted to the house statement of direction.

### D2 --- The traverse form

**Taken.** `key=a>b@site` is available on any scalar and is the normal
form for polar settings.

*Reconsider for promotion:* the form is useful outside this instrument. A
`transmission` document whose reader posture changes between its opening
and its close---an onboarding document, a long proposal read across a
week---has the same need and no way to state it. If the form proves out
here, promote it to the house grammar and make it available in
`transmission` and `coinage`.

*Known limit:* a traverse names endpoints and a site, not a curve. Two
traverses over adjacent sites is the stated workaround. A curve parameter
(`ease`, `late`, `linear`) was considered and declined as premature.

### D3 --- `monodic` retained

**Taken.** Retained as a plan and an aspiration for synthesis, with the
skill stating plainly that it is composed above the word and recorded at
the outline rather than executed by tuning.

*The case for removal, preserved for later:*

- It is the only setting in the instrument that word-level selection
  cannot execute. Every other key changes what the next word should be;
  this one changes what the next *section* should be.
- Its low pole describes an achievement rather than a configuration.
  Setting `monodic=0.10` does not produce counterpoint; it records an
  intention to compose some.
- It has the weakest diagnostic. "The counter-line never materializes"
  resolves to a process failure at step six, not to a setting error, which
  means the setting is not what the diagnosis corrects.
- Nine of the fourteen purpose entries sit between 0.70 and 1.00, and the
  three that do not (`drama`, `poetry`, `shakespeare` as a voice) are the
  three where counterpoint is already the genre's defining property. A
  setting whose informative range is occupied by three entries is a
  candidate for demotion to a denoted `channel` option---`contrapuntal`
  alongside `haptic`, `mimetic`, and `architectonic`.

*Reconsider when:* enough documents have been rendered to say whether a
low `monodic` ever changed an outline. If it never did, demote it. If it
did, the setting earned its place and the aspiration was correct.

### D4 --- Consonant family split from continuity

**Taken.** `family` is denoted (`plosive`, `fricative`, `liquid`, `nasal`,
combining with `+`); `flowing` is the polar scalar and governs continuity
alone.

*The alternative not taken:* a single scalar running plosive to liquid
with fricatives at the midpoint. Rejected because fricatives are a third
family and not an average of the other two---Conrad's ambient sibilance is
not half-percussive---and because the split turned out to be
genuinely orthogonal: a plosive-dominant passage runs continuous where the
strikes are separated by open vowels and interrupted where they cluster.
McCarthy occupies the first case and hard impact prose the second, and no
single axis states both.

*Second alternative not taken:* four separate scalars, one per family,
each measuring that family's weight in the passage. Rejected as four
settings that always sum to a constant, which is a simplex badly disguised
as a cube.

*Known weakness:* `family` combining with `+` has no stated arbitration
when a `voice` and a `figure` each name a different combination at the
same site. The skill resolves it by overlay order. Whether order is the
right arbitration, or whether families should merge rather than override,
is open.

### D5 --- Roster as the first line of configuration

**Taken.** Three tiers: fourteen purposes, thirteen voices, twenty-four
figures. Coverage targets the precursor's style-guide sections and its
author categories rather than a fixed count.

*Rationale:* polar scalars are meaningless without worked positions.
`dark=0.50` states nothing until something states what a document at 0.50
sounds like, which is a problem `transmission` does not have because a
`spread` of 0.50 is meaningfully mid-range on a single direction. The
roster is therefore load-bearing here in a way it is not elsewhere in the
set, and the voice table doubles as validation: an ontology that cannot
separate Conrad from McCarthy has not decomposed finely enough.

*Open:* whether the roster wants purposes the precursor did not
contemplate---technical narrative, documentation, journalism, libretto.
Adding a purpose is cheap and adding a wrong one is not, so entries should
be added on demand from real documents rather than speculatively.

### D6 --- Em-dash convention

**Taken.** `---` unspaced separates clauses within a sentence. ` --- `
spaced separates a term or key from its definition or value.

*Note for the set:* the companion artifacts disagree. `coinage` runs 69
spaced and 0 unspaced; `character-george` runs 76 unspaced and 1 spaced;
the three `transmission` instruments are split roughly evenly. The rule
above is the settled one and applies retroactively when the set is tuned.

---

## Deferred Optimizations

Recorded for the pass that tunes the whole set together.

**O1 --- Restore `legato`.** If `transmission-load` renames its `cadence`
values, or if `cadence` itself is folded into a finer setting, `flowing`
should become `legato` in both places or in neither. The musical vocabulary
is the right vocabulary for both instruments and the collision is an
accident of composition order.

**O2 --- Unify `cadence` and `sustained`.** `transmission-load.cadence` is
three-valued and declared from document kind. `sustained` is continuous and
declared from content trajectory. They measure the same axis at different
resolutions. The interim mapping, unstated in the skill and recorded here:
`staccato` corresponds to `sustained` below 0.35, `misura` to 0.35-0.70,
`legato` above 0.70. A tuned set should carry one setting, not two, with
the coarse form available as a shorthand for the fine one.

**O3 --- Unify the direction statements.** Three instruments now state
their own pole direction in their own words. A house statement of
direction, stated once and inherited, would remove three near-duplicate
sections and would force the two-kind question (D1) to be settled at the
house level.

**O4 --- Shared roster keys.** `purpose` and `span` mean the same thing in
`coinage` and here. If a third instrument adopts them, they should be
lifted to a shared document group that every instrument reads, rather than
restated in each.

**O5 --- The self-containment cost.** Each instrument is composed to stand
alone, which means none may tell its reader that the others exist. The
cost is concentrated where two instruments have adjacent gates: a writer
running both `coinage` and melopoeia has `grave` and `divergent` in play
and no artifact tells them how the two relate. Accept the cost, or
introduce a fourth artifact---a set-level composition note---that is
allowed to name all of them. The README is currently doing this job
informally.

**O6 --- The `family` arbitration.** See D4. Overlay order is the interim
rule; merge semantics is the alternative.

**O7 --- Traverse curves.** See D2.

---

## Boundary Declarations

Stripped from the skill under the self-containment constraint. The
overlaps are real and want stating somewhere.

**`transmission-load.cadence` against `measure`.** Same axis, different
resolution and different derivation---one from document kind, one from
content trajectory. Interim resolution: `cadence` sets the rhythmic ground
and `measure` sets the departures from it; where a melopoeia traverse
carries `sustained` outside its declared cadence band, the traverse governs
and the excursion is the event. See O2.

**`coinage.muted` and `coinage.scale=phonetic` against `transparent`.**
Both govern sound recurrence, and the objects differ cleanly. Coinage's
phonetic band is alliterative binding *attached to nominated
vocabulary*---sound in service of a struck form, at the junctures where
that form appears. `transparent` governs *unnominated* phonemic
motif---sound
returning with no concept attached to it. A document may run both, and
Morrison is the case: refrains carrying concepts, and beneath them a sonic
environment carrying only itself. No coupling required.

**`coinage.grave` against `divergent`.** Both gate audible patterning and
they are not the same gate. `grave` is a property of the *subject* ---
whether the material's weight makes any audible play a misjudgment.
`divergent` is a property of the *relation* between sound and sense. They
compose: a grave subject may still perform its content sonically, and does
so in Morrison, where the gravity is precisely what licenses the
fragmentation. A document running both instruments should expect `grave`
high and `divergent` low simultaneously, which is a coherent and common
configuration that neither artifact can currently describe. See O5.

**`transmission-land.single` against `transparent`.** No overlap. `single`
allocates the *recurring position* among competing vocabulary;
`transparent` governs sound recurrence carrying no vocabulary at all.

**`transmission-vantage` against everything here.** No overlap detected.
Vantage governs provenance and epoch; melopoeia governs the acoustic
channel. The two are orthogonal, which is worth recording so a later pass
does not re-derive the check.

---

## Distribution Notes

Where the precursor's shape reflects its literature rather than its
subject. Carried here rather than in the skill, since a skill that
argues with its own source is a skill whose reader is attending to the
wrong thing.

**Visibility bias.** The melopoeia canon in English-language criticism is
concentrated in Anglophone modernism---Woolf, Joyce, Conrad---because
that is the body of work the musicality question was asked about. Practice
in non-Anglophone traditions, and in pre-modern English prose outside the
King James orbit, is under-documented rather than absent. The dimensional
set inherits the concentration: `suspended` and `modulated` are well-fitted
to periodic English syntax and may fit poorly to languages carrying
suspension grammatically through word order. Flagged for investigation
rather than corrected, since correcting it requires material the training
distribution does not hold. The `translation` purpose limits the damage by
refusing phonemic claims about translated work; it does not address
composing *in* another language, which the instrument currently cannot do.

**Institutional influence.** Pound's tripartite division dominates the
literature because it is short, citable, and attached to a major name, not
because it is the best-fitted decomposition. Vorobyova's five-dimensional
classification of prose musicality is finer and better-fitted, and is
nearly invisible in English-language sources. This instrument takes the
`band` structure from the translation problem rather than from Pound, and
takes the `channel` options from Vorobyova rather than from the
three-property division---both deliberate departures from the
high-frequency source.

**Temporal lag.** The precursor asserts that the emotional valence of
sonic textures is grounded in physics and neurology rather than
convention. The claim is defensible; its citation base does not carry it.
The essay cites literary criticism where the load belongs to
phonosemantics and sound-symbolism research, a literature the
literary-critical tradition does not reach for. The gap is in the warrant,
not the claim. The skill accordingly states the haptic mechanism as the
physical finding it is---pressure variation, membrane displacement,
transduction---and states the emotional mapping as the working hypothesis
the instrument operates under. Footnote one in the skill carries this
distinction and should not be edited away.

**Alternative-foregrounding.** The training-dominant form for a
composition skill of this kind is a directive catalog: a list of devices
with usage notes, selected and combined. The precursor's own embedded YAML
style guide is exactly that form, and it is the form a synthesis reaching
for the highest-frequency pattern would produce. It was declined as the
grammar and retained as the roster, because a catalog can specify a
technique and cannot specify a *position*, cannot state a yield direction,
and cannot support reverse diagnosis. The catalog was not discarded; it
was demoted from grammar to worked example, which is what the figure table
is.

---

## Revision Log

    org 6a93c973 20260829 231059 PDT Sat 11:10 PM 29 Aug 2026
      First record. D1-D6 taken. O1-O7 deferred. Collision inventory
      established against transmission, transmission-load,
      transmission-land, transmission-vantage, and coinage as of this
      date. Precursor: melopoeia-essay.md, org 69c48e0b, 25 Mar 2026.
