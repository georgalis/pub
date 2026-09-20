---
name: melopoeia-ontology
description: Model ontology for the melopoeia skill --- the sonic channel of prose as a governed instrument. Fixes what a melopoeia instrument is: the two scalar kinds, the parameter set, the traverse form, and the coordination law. The skill artifact composes prose from it and carries the roster.
---

# Melopoeia --- Model Ontology

Prose runs two channels. The semantic channel is read. The sonic channel
is *felt*, arriving through a membrane so fine it answers to pressures
below the width of an atom, and arriving there before the sentence has
finished parsing.

**Score, voice, entrain** --- the author governs the first, the reader's
articulatory system performs the second in a body the author cannot
consult, and the third is not consented to at all. Delivery instruments
ask a reader for something. This one asks nothing and arrives regardless,
which is why it carries what meaning has no words for, and why a technique
the reader can hear has already failed.

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

    org 6a93c973 20260829 231059 PDT Sat 11:10 PM 29 Aug 2026
    org 6a93b0b9 20260829 212529 PDT Sat 09:25 PM 29 Aug 2026

**Model ontology.** This artifact fixes the two scalar kinds, the
parameter set, the traverse form, the nomination inputs, and the
coordination law. Nothing here composes prose; it says what the things
that compose prose are. The **roster** lives in the skill artifact rather
than here, because the roster is the first line of configuration and
belongs where configuration happens. Decisions taken, alternatives
declined, collisions yielded, and deferred optimizations live in
`melopoeia-development.md`.

This document is the authoritative artifact for the request effort. A
future session possessing only this file has everything required to
resume, audit, or extend the model. Where a later round narrows or
reverses a decision recorded here, the reversal and its rationale are
recorded in place rather than silently dropped.

Precursor: *Melopoeia: The Music Beneath Prose*, org 69c48e0b, 25 Mar 2026.

---

## Contents

- [What This Instrument Is](#what-this-instrument-is)
- [Two Scalar Kinds](#two-scalar-kinds)
- [Direction and Reading](#direction-and-reading)
- [Parameter Set](#parameter-set)
- [Traverse](#traverse)
- [Nomination](#nomination)
- [Inscape](#inscape) --- the coordination law
- [Dispositions](#dispositions)
- [What Stays With the Author](#what-stays-with-the-author)

---

## What This Instrument Is

A settings instrument over the acoustic properties of prose, operating on
a channel the reader receives without consent and cannot report on.

Three properties distinguish it from any adjacent instrument and are the
reason it exists as one.

**The channel is always running.** A document has a sonic environment
whether or not anyone chose it. An unconfigured melopoeia is not silence;
it is the register the author's hand reached for on the day of drafting.
The instrument does not add a channel---it takes an existing one out of
default.

**Reception is somatic and precedes interpretation.** The ear is a tactile
organ and the tympanic membrane is touched by every sound it receives.
Haptic experience falls natively into emotional categories---rough and
smooth, sharp and soft, warm and cool, pressing and releasing---and sound
inherits those categories through its physics. The body has responded
before the mind finishes parsing.

**There is no feedback path.** A reader who received nothing reports that
the prose was adequate. A reader who was moved attributes it to the plot.
Neither report reaches the setting that produced it. This is why
nomination is a required input here rather than a convenience: it is the
only correction the channel will ever get, and it has to be supplied in
advance.

---

## Two Scalar Kinds

The instrument requires two, and the distinction is load-bearing.

**Intensity scalars** measure *how much* the channel is doing. They run
the house direction, are named for the quality maximal at 1.0, and yield
toward the light pole under conflict.

**Polar scalars** name *which* sound, not how much. They are bipolar, have
**no light pole and no yield direction**, and a conflict on one is
resolved by declaring a traverse or a local override rather than by moving
toward a pole.

The distinction is not a notational convenience. Treating a polar setting
as an intensity produces the characteristic error of the whole subject:
prose tuned toward an imagined sonic neutral, which is the one setting
that carries nothing. `dark=0.15` is not a lesser setting than
`dark=0.85`; it is a different instrument in the pit.

Grouping keeps the two legible. The `grain` and `measure` groups are polar
entire; the `carry` group and the document gate are intensity entire. No
group mixes kinds.

---

## Direction and Reading

**For intensity scalars: 0.0 is the scored, audible, worked pole; 1.0 is
the incidental, transparent, unworked pole.** Yield runs high. Sound
worked against a subject that cannot carry it fails visibly and is
corrected in the next draft; sound withheld fails only by leaving a
channel unused, and leaves no complaint to correct from.

**For polar scalars: the poles are named in each definition and neither is
a failure.** Tolerance is wider---plus or minus 0.20 against 0.10 for
intensities---because perceptual thresholds on these axes are coarser than
their notation.

Values read by position, not by scale: `35`, `3.5`, `0.35`, and `7/20`
place a setting identically. A setting names a region to occupy, not a
limit not to exceed. Any key left unstated resolves to its roster value
and widens its tolerance, so an under-specified request looks
under-specified rather than average.

---

## Parameter Set

Six groups. Fourteen settings, of which six are polar, four are intensity,
and four are denoted.

### document

| key | kind | 0.0 | 1.0 |
|---|---|---|---|
| `purpose` | roster name | --- | --- |
| `span` | integer | --- | --- |
| `divergent` | intensity | every sonic decision answers to content | sound and sense pursue separate ends |

`divergent` is the gate. It is not a quantity of sound but a relation
between the two channels, which is why it sits in the document group and
governs by capping rather than by coupling. See [Inscape](#inscape).

### grain --- the point of contact

| key | kind | 0.0 | 1.0 |
|---|---|---|---|
| `dark` | polar | front vowels dominant: brightness, edge, forward momentum | back vowels dominant: depth, gravity, enclosure, warmth |
| `flowing` | polar | interrupted: each word a struck surface | continuous: voicing carried across, laminar |
| `rough` | polar | euphonious: no articulatory friction | cacophonous: the mouth forced through rough terrain |
| `family` | denoted | --- | --- |

`family` takes `plosive`, `fricative`, `liquid`, `nasal`, combining with
`+`. It is separate from `flowing` because the two are orthogonal: a
plosive-dominant passage runs continuous where the strikes are separated
by open vowels and interrupted where they cluster.

### measure --- movement in time

| key | kind | 0.0 | 1.0 |
|---|---|---|---|
| `sustained` | polar | clipped: short declaratives dominant | long-breath: periods extending through subordination |
| `suspended` | polar | loose: main clause first, accumulation after | periodic: completion withheld to the sentence's end |
| `modulated` | polar | uniform pulse: a ground against which departure registers | continuous modulation: length varying as breath varies |

`sustained` and `suspended` are independent, and the separation is the
model's finest distinction. Accumulation without suspension is a different
music from accumulation with it, and no single axis states both.

### carry --- the channel's load

| key | kind | 0.0 | 1.0 |
|---|---|---|---|
| `incidental` | intensity | sound is a selection criterion co-equal with meaning | sound is a byproduct of meaning-selection |
| `transparent` | intensity | dense: phonemic motif binding below the argument | transparent: no phonemic relation across sentences |
| `monodic` | intensity | counterpoint: simultaneous patterns in tension | one line, unopposed |

`incidental` is the master setting and the discriminator between prose
that has this channel and prose that does not. `transparent` governs
recurrence carrying *no concept*---sound returning with nothing attached
to it---which is what separates it from the repetition of a term.

`monodic` is composed above the word and recorded at the outline rather
than executed by tuning. It is retained as a plan the settings support
rather than a value they realize; the case for its removal is in the
development record.

### denote

| key | options |
|---|---|
| `family` | `plosive`, `fricative`, `liquid`, `nasal` --- combining with `+` |
| `band` | `phonemic`, `lexical`, `sentential`, `paragraph`, `movement` --- stated as a range |
| `channel` | `haptic`, `mimetic`, `architectonic` |
| `ear` | `silent`, `aloud`, `memory` |

**`band` carries the translation boundary, which is the sharpest line in
the model.** `phonemic` and `lexical` do not survive passage between
languages; `sentential`, `paragraph`, and `movement` do. A translator
cannot carry a passage's vowel colors any more than a transcription
carries an orchestra's timbre---what a good translator does is compose new
phonemic patterns serving the original's structural functions. Any claim
about phonemic melopoeia in a translated work is a claim about the
translator.

**`ear` binds `sustained` at `aloud`.** A sentence longer than one breath
is a defect when the reader is a voice in a room, whatever the setting
says.

### nominate

| key | what it holds |
|---|---|
| `perform` | content events the sonic channel is required to carry |
| `mute` | regions where the channel stands down |

### overlay

| key | what it holds |
|---|---|
| `voice` | author-derived roster overlays, applied in order |
| `figure` | passage-scale roster overlays, normally sited |

---

## Traverse

**Any scalar may take a traverse form, and the polar scalars normally do.**
Written `key=a>b@site`, it names a movement rather than a position.

A vowel color held is a palette; a vowel color moved is the compositional
event itself---the equivalent of modulation, and the thing a reader
registers as an emotional shift with no locatable cause. An instrument
stating only positions can specify a sonic environment and cannot specify
a single sonic event.

The form names endpoints and a site. It does not name a curve; two
traverses over adjacent sites is the stated means of shaping one. A sited
traverse is a local override with a location, and a sited `figure` is a
traverse with a name.

---

## Nomination

**The author names the content moments the sound must perform.** This is
the model's primary input and what separates composed melopoeia from the
environment a draft acquires when nothing was nominated.

Unnominated, the channel tracks the author's own state during drafting
rather than the content's demand, and the prose arrives sounding like the
week it was written. A grief passage composed on a bright afternoon
carries the afternoon.

`perform` entries name the *event*, not the technique; the settings supply
the technique. This is what makes `divergent` operable rather than
aspirational, because alignment is a relation and a relation needs both
terms stated.

An empty `perform` list is legitimate and means the document maintains a
sonic environment without local performance---correct for sustained
registers where the whole is the effect and no single moment is.

---

## Inscape

**The coordination law. Audible patterning is licensed by alignment, and
unaligned patterning is ornament.**

Hopkins gives the condition its name: the interior logic making a form
feel inevitable, such that altering any element damages the whole. A
passage possessing inscape cannot be substituted into without loss, and
the reader registers that inevitability as *rightness* without tracing its
source.

The mechanism is a trade. Every dimension driven hard raises the
probability the reader notices the technique, and a noticed technique stops
carrying and starts costing. What buys the license is alignment: a sound
doing conspicuous work *the content demanded* reads as inevitability, and
the identical sound doing conspicuous work the content did not demand reads
as a writer arranging.

**`divergent` caps the working range of every other setting.** Above 0.60,
no scalar may sit within 0.15 of either extreme, and a request to place one
there is refused and reported rather than composed. Below 0.20, the
extremes are fully available and the `perform` list is what makes them
safe.

**Alignment cannot be assessed from the prose alone.** Whether a sonic
decision answers to content is a question about the content. An instrument
given no nomination list can configure a sonic environment and cannot
certify a single sonic event, and the listening disposition inherits the
same limit.

**No test determines whether a passage possesses inscape.** The condition
is settled in a reader's body, before that reader can report on it, and
nothing available to the author substitutes for the finding. What is
available is preparation---nomination, alignment, and the vocalization
pass---and preparation is the best instrument there is on a question that
admits no proof.

---

## Dispositions

**Disposition is derived, never declared.** The request always carries
which applies, so no parameter records it.

**Scoring** --- the channel is configured and driven. Roster resolves,
nomination sites the traverses, drafting runs with both selection criteria
live, and a vocalization pass is non-optional before the draft is
delivered.

**Listening** --- the settings read as measurements rather than targets,
and the work is detection in four layered passes: pace, joint, return,
grain. Findings are presented by function, location, or technique, never
serially, because serial cataloguing reports that sound occurs where
organized presentation reports what it is carrying.

---

## What Stays With the Author

**Nomination.** The instrument configures an environment and cannot know
which moment is the arrival. Every `perform` entry is a judgment about the
content that no reading of the prose supplies.

**The vocalization pass.** No configuration substitutes for the ear at the
draft. A passage reading identically silent and aloud has no sonic channel,
and only the pass detects it.

**Standing over the subject.** A grave subject performed sonically is
Morrison; the same technique over a subject that did not earn it is
mannerism. `divergent` caps the range and cannot judge the material.

**Accuracy.** A well-scored passage delivers a wrong finding beautifully,
and no setting registers anything amiss. The channel amplifies; it does
not verify.
