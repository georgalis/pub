---
name: melopoeia
description: The sonic channel of prose composed as an instrument. Configure vowel color, consonant family and continuity, sentence rhythm, suspension, and sonic recurrence from a roster of purposes, author voices, and passage figures; render the artifact and report the calibration separately. Apply when prose must be composed for the ear as well as the mind --- essays, fiction, poetry, liturgy, speech, drama, translation --- or when an existing composition is to be examined for what its sound is carrying.
---

# Melopoeia

Prose runs two channels. The semantic channel is read. The sonic channel
is *felt*, arriving through a membrane so fine it answers to pressures
below the width of an atom, and arriving there before the sentence has
finished parsing.

**Score, voice, entrain** --- the author governs the first, the reader's
articulatory system performs the second in a body the author cannot
consult, and the third is not consented to at all. That asymmetry is the
whole instrument. It asks the reader for nothing and arrives regardless,
which is why it carries what meaning has no words for, and why a
technique the reader can hear has already failed.

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

    org 6a93c973 20260829 231059 PDT Sat 11:10 PM 29 Aug 2026

---

## Contents

- [Activation](#activation)
- [Disposition and Direction](#disposition-and-direction) --- the two kinds of scalar
- [Template](#template)
- [Traverse](#traverse) --- stating a movement rather than a position
- [Nomination](#nomination) --- what the sound must perform
- [Grain](#grain) --- `dark`, `flowing`, `rough`
- [Measure](#measure) --- `sustained`, `suspended`, `modulated`
- [Carry](#carry) --- `incidental`, `transparent`, `monodic`
- [Denoted Values](#denoted-values) --- `family`, `band`, `channel`, `ear`
- [Inscape](#inscape) --- the coordination law
- [Roster](#roster) --- purposes, voices, figures
- [Overlay Resolution](#overlay-resolution)
- [Composition Order](#composition-order)
- [Report the Calibration](#report-the-calibration)
- [Local Override](#local-override)
- [Listening](#listening) --- the analysis disposition
- [Reverse Diagnosis](#reverse-diagnosis)
- [Notes](#notes)

---

## Activation

Three conditions, any one sufficient.

- A document's effect depends on how it sounds, not only on what it says.
- A passage must perform its content rather than merely state it.
- An existing composition is to be examined for what its sound is
  carrying.

The instrument is self-contained. It assumes no prior session and no
companion instrument. The only vocabulary it presumes is what is current
in prosody and musical description---the phoneme families, the tempo and
dynamic terms---which any reader of the roster already holds.

---

## Disposition and Direction

**Disposition is derived, never declared.** A request to compose runs the
scoring disposition: the sonic channel is configured and driven. A
request to examine an existing composition runs the listening
disposition: what the channel already carries is detected and mapped. The
request always carries which applies, so no parameter records it.

**Two kinds of scalar, and the distinction is load-bearing.**

**Intensity scalars** --- `divergent`, `incidental`, `transparent`,
`monodic`. **0.0 is the scored, audible, worked pole; 1.0 is the
incidental, transparent, unworked pole.** Each is named for the quality
maximal at 1.0. Yield runs high: where conflict forces one off center it
moves toward transparency, because sound worked against a subject that
cannot carry it fails visibly and is corrected in the next draft, while
sound withheld fails only by leaving a channel unused.

**Polar scalars** --- `dark`, `flowing`, `rough`, `sustained`,
`suspended`, `modulated`. These are bipolar and have **no yield direction
and no light pole.** They name *which* sound, not *how much*. `dark=0.15`
is not a lesser setting than `dark=0.85`; it is a different instrument in
the pit. A conflict on a polar scalar is resolved by declaring a traverse
or a local override, never by moving toward a pole, because there is no
pole to move toward. Treating them as intensity scalars produces the
characteristic error of the whole subject: prose tuned toward an imagined
sonic neutral, which is the one setting that carries nothing.

Values read by position, not by scale: `35`, `3.5`, `0.35`, and `7/20`
place a setting identically. A setting names a region to occupy, not a
limit not to exceed. Default tolerance is plus or minus 0.10, widening to
0.20 on polar scalars, whose perceptual thresholds are coarser than their
notation. Any key left unstated resolves to its roster value and widens
its tolerance, so an under-specified request looks under-specified rather
than average.

---

## Template

Two forms. The first is what an author states; the second is the full
calibration, emitted with every response for fine adjustment.

```
/melopoeia essay
  voice=[robinson]
  figure=[dawn@opening, hush]
  perform=[the light arriving in section two]
```

```
document      purpose=essay            span=                divergent=0.30
grain         dark=0.50                flowing=0.60         rough=0.35
measure       sustained=0.65           suspended=0.55       modulated=0.70
carry         incidental=0.45          transparent=0.40     monodic=0.70
denote        family=fricative+nasal   band=phonemic:movement
              channel=haptic           ear=silent
overlay       voice=[...]              figure=[...]
nominate      perform=[...]            mute=[...]
```

Ordinary invocation is a roster name. Add overlays and a nomination list;
perturb a key only where the roster is wrong for this document.

    /melopoeia essay
    /melopoeia fiction voice=[morrison] figure=[fracture@ch9]
    /melopoeia liturgy perform=[the entrance, the dismissal]
    /melopoeia spec

### Document --- purpose, span, divergent

**`purpose`** names a roster entry and resolves every other key. A purpose
alone is a complete invocation.

**`span`** is target extent in words, where one is known. Sonic work is
approximately extent-neutral---a sound-shape costs no installation---so
`span` reports rather than binds.

**`divergent`** is the gate. It measures how far the sonic channel runs
independently of the semantic one, and it caps every other setting. Its
operation is given under [Inscape](#inscape).

- **1.0** Independent. Sound and sense pursue separate ends; whatever the
  words do acoustically is unexamined.
- **0.5** Aligned at the nominated moments, free between them.
- **0.0** Every sonic decision answers to content. The prose performs what
  it says.

Regions: `fused` 0.00-0.20, `tracking` 0.20-0.45, `loose` 0.45-0.75,
`independent` 0.75-1.00.

Failure low: alignment turns conspicuous and mimesis tips into
onomatopoeic mannerism---the reader hears the writer arranging.

Failure high: audible patterning without warrant, which is the failure
this instrument principally exists to prevent.

---

## Traverse

**Any scalar may take a traverse form, and the polar scalars normally do.**
A traverse is written `key=a>b` and names a movement from `a` to `b`
across a site rather than a position held.

    dark=0.20>0.85              across the document arc, the default site
    dark=0.20>0.85@ch7          across chapter seven
    flowing=0.80>0.15@arrival   across the passage nominated 'arrival'

A vowel color held is a palette; a vowel color moved is the compositional
event itself---the equivalent of modulation, and the thing a reader
registers as an emotional shift with no locatable cause. An instrument
that states only positions can specify a sonic environment and cannot
specify a single sonic event.

A traverse names endpoints and a site. It does not name a curve. Where
the shape of the movement matters---late-breaking against gradual---declare
two traverses over adjacent sites rather than annotating one.

Sustained color remains available and is what the plain form means. The
traverse is the addition, not the replacement.

---

## Nomination

**The author names the content moments the sound must perform.** This is
the instrument's primary input and what separates composed melopoeia from
the sonic environment a draft acquires when nothing was nominated.

The channel is always running. Unnominated, it tracks the author's own
state during drafting rather than the content's demand, and the prose
arrives sounding like the week it was written. A grief passage composed
on a bright afternoon carries the afternoon.

- **`perform`** --- content events the sonic channel is required to
  carry: an arrival, a rupture, a dawn, a world-shift, a return. Each
  entry names the *event*, not the technique; the settings supply the
  technique. This list is what makes `divergent` operable rather than
  aspirational, because alignment is a relation and a relation needs both
  terms stated.
- **`mute`** --- regions where the channel stands down: quoted material,
  catalogs, tables, technical apparatus, anything whose wording is fixed
  by another authority. Silence at these sites is a setting, not a
  failure to reach them.

A sited `figure` is itself a `perform` entry and need not be restated.

An empty `perform` list is legitimate and means the document maintains a
sonic environment without local performance. It is correct for sustained
registers---liturgical prose, meditative narration---where the whole is
the effect and no single moment is.

---

## Grain

Three polar scalars and one denoted setting. What the sound is at the
point of contact with the ear, which is a haptic point: the membrane is
*touched*, and touch falls natively into emotional categories---rough and
smooth, sharp and soft, warm and cool. The grain group inherits those
categories through physics rather than convention[^1].

### dark --- vowel color

- **1.0** Back vowels dominant in stressed syllables --- *oo*, *oh*,
  *ah*, *aw*. Depth, gravity, enclosure, warmth.
- **0.5** Mixed. No dominant register.
- **0.0** Front vowels dominant --- *ee*, *ih*, *eh*, *ay*. Brightness,
  edge, forward momentum.

The correspondence is acoustic: front-vowel formants sit higher, and the
brightness a reader hears is the same brightness distinguishing a piccolo
from a cello.

Regions: `bright` 0.00-0.30, `mixed` 0.30-0.70, `dark` 0.70-1.00.

**The most accessible dimension, and the one to traverse first.** A reader
who cannot yet hear consonant texture will register a vowel traverse
without being able to name it.

### flowing --- articulation continuity

How far each phoneme is carried into the next rather than arriving as a
discrete strike. Governed by cluster density, hiatus, elision, and the
vowels standing between consonants.

- **1.0** Continuous. Voicing sustains across the word; laminar, the
  medium present and yielding, momentum carried rather than interrupted.
- **0.5** Mixed. Strike and carry alternating.
- **0.0** Interrupted. Each word arrives as a struck surface, articulation
  stopping between events.

Regions: `struck` 0.00-0.30, `mixed` 0.30-0.70, `flowing` 0.70-1.00.

**Independent of `family`, and the independence is the reason they are
separate keys.** A plosive-dominant passage runs continuous where the
strikes are separated by open vowels and liquids, each carried into the
next; the same family runs interrupted where the plosives cluster. McCarthy
is the first case and hard impact prose the second.

### rough --- articulatory resistance

Euphony to cacophony. How far the articulatory system is made to work.

- **1.0** Cacophonous. Consonant clusters, hiatus, the mouth forced
  through rough terrain. Tension, resistance, dis-ease.
- **0.5** Ordinary. The path neither eased nor obstructed.
- **0.0** Euphonious. Combinations the ear receives with pleasure and the
  mouth with none of the friction that would slow it.

Regions: `euphonic` 0.00-0.30, `ordinary` 0.30-0.65, `abrasive`
0.65-1.00.

Independent of `flowing`, and the two are confused constantly. McCarthy
runs high `flowing` at the clause over consonants that are hard and dry.
Robinson runs high on `flowing` and low on `rough` together. Where a
document reads slower than its content warrants, this is usually the
setting, not `sustained`.

---

## Measure

Three polar scalars. How the sound moves in time. The reader's breathing
entrains to sentence length, and entrainment is somatic before it is
anything else.

### sustained --- sentence span

- **1.0** Long-breath. Periods extending through subordination,
  accumulating momentum across thirty and forty words.
- **0.5** Medium, with short declaratives as punctuation.
- **0.0** Clipped. Short declaratives dominant.

Regions: `clipped` 0.00-0.35, `measured` 0.35-0.70, `long` 0.70-1.00.

### suspended --- grammatical delay

Independent of span, and the separation is the instrument's finest
distinction.

- **1.0** Periodic. Grammatical completion withheld to the sentence's
  end, syntactic expectation held as a dominant seventh holds a listener.
- **0.5** Mixed.
- **0.0** Loose. The main clause arrives first and the sentence
  accumulates after it.

Regions: `loose` 0.00-0.35, `mixed` 0.35-0.65, `periodic` 0.65-1.00.

Hawthorne runs high on both. Conrad and McCarthy run high `sustained` and
low `suspended`---accumulation without suspension, a different music
entirely and one that would be unstateable on a single axis. The
resolution event, when it arrives, is felt as closure independently of
what the main clause says.

### modulated --- rhythmic variance

- **1.0** Continuous modulation. Length varies as breath varies; the
  sentence that seems to resolve and gently reopens.
- **0.5** Deliberate alternation. Long periods against short arrivals, the
  contrast itself the music.
- **0.0** Uniform pulse. A rhythmic ground against which any departure
  registers as dynamic change.

Regions: `uniform` 0.00-0.30, `alternating` 0.30-0.65, `modulating`
0.65-1.00.

**The low pole is a device, not an absence of one**, which is why this
scalar is polar rather than intensity. Hemingway's uniformity is
*composed* uniformity: the ground exists so the single long sentence can
land as a change in breathing. Attention habituating across a chapter is
the failure, and it arrives at 0.0 by neglect and at 0.5 by
mechanism---alternation on a template anesthetizes as reliably as no
alternation at all.

---

## Carry

Three intensity scalars. How much the channel is doing.

### incidental --- sonic intention

The master setting, and the discriminator between prose that has this
channel and prose that does not.

- **1.0** Sound is a byproduct. Words selected for denotation,
  connotation, and clarity; whatever they do acoustically is unexamined.
- **0.5** Sound is a tiebreaker between otherwise equal candidates.
- **0.0** Sound is a selection criterion co-equal with meaning. *Murmur*
  over *whisper* for the nasal warmth binding it to its neighbors;
  *shatter* over *break* for the fricative-plosive rupture enacted at the
  phonemic level.

Regions: `composed` 0.00-0.30, `attentive` 0.30-0.65, `incidental`
0.65-1.00.

Failure low: every word carries three obligations and the prose acquires
a worked surface with the tooling still visible on it.

Failure high: a passage whose effect depends on sound arrives correct and
inert. Nothing reports the loss, because no complaint is available to a
reader who received a channel's worth of nothing.

### transparent --- harmonic density

How far sounds within a passage relate to each other. Distinct from
`incidental`: a passage may select every word for sound and still keep
each sentence independent of its neighbors' sound-world.

- **1.0** Transparent. No phonemic relation across sentences.
- **0.5** Motif at the junctures.
- **0.0** Dense. Recurring vowel sequences, consonant echoes, and rhythmic
  figures binding a passage below the level of semantic argument, as a
  harmonic motif binds symphonic sections below the level of melody.

Regions: `dense` 0.00-0.25, `motivic` 0.25-0.60, `transparent`
0.60-1.00.

**The recurrence governed here carries no concept.** It is sound returning
with nothing attached to it, which is what separates it from the
repetition of a term or a phrase. A document may run both at once, and
Morrison is the case: refrains carrying concepts, and beneath them a sonic
environment carrying only itself.

### monodic --- rhythmic line count

- **1.0** One line. A single rhythmic pattern, unopposed.
- **0.5** Occasional counter-line at structural moments.
- **0.0** Counterpoint. Two or more simultaneous patterns whose interaction
  generates what neither carries alone---periodic syntax against short
  interjection, Latinate against Anglo-Saxon, the rhythm of logic against
  the rhythm of sensation.

Regions: `contrapuntal` 0.00-0.30, `mixed` 0.30-0.65, `monodic`
0.65-1.00.

**Composed above the word, and therefore an aspiration the settings
support rather than execute.** Word-level tuning cannot produce
counterpoint; outline-level planning can, and this setting is where that
plan is recorded. Site the two lines in the outline before drafting, and
treat a low value as an instruction to the structure rather than to the
diction.

---

## Denoted Values

| key | option | what it does |
|---|---|---|
| `family` | `plosive` | *p, b, t, d, k, g*. Percussive events: sound made by the sudden release of blocked air, each a small detonation. |
| `family` | `fricative` | *f, v, s, z, sh, zh*. Sustained turbulence, the consonant equivalent of a bowed string; ambient texture. |
| `family` | `liquid` | *l, r*. Laminar transit between vowels, resistance that yields, momentum carried forward. |
| `family` | `nasal` | *m, n, ng*. The warmest consonants, resonating through the nasal cavity, holding syllables together as a sustained organ note holds a chord. |
| `band` | `phonemic` | Vowel and consonant selection. The word's grain. Does not survive translation. |
| `band` | `lexical` | Choice among synonyms on sound-shape. Survives translation only as the translator's own new choice. |
| `band` | `sentential` | Clause rhythm, span, suspension, resolution. Survives translation. |
| `band` | `paragraph` | Texture shift at the structural joints. Survives translation. |
| `band` | `movement` | Temporal architecture across sections and chapters; the arc of pace. Survives translation. |
| `channel` | `haptic` | The sound delivers a touch quality---rough or smooth, warm or cool, pressing or releasing---and the body answers before the mind parses. |
| `channel` | `mimetic` | The sound performs the content. The articulatory system is made to enact what the words denote. |
| `channel` | `architectonic` | The sound marks structure. A world-shift, a movement boundary, a return, announced acoustically before any semantic signal arrives. |
| `ear` | `silent` | Composed for subvocal reception. The default, and the condition under which most prose is met[^2]. |
| `ear` | `aloud` | Composed for vocalization. Liturgy, oration, drama, anything performed. Breath becomes a hard constraint rather than an analogy. |
| `ear` | `memory` | Composed to persist as rhythmic shape after the argument is absorbed and the wording is gone. |

**`family` combines.** State two with `+`, dominant first: `fricative+nasal`,
`liquid+nasal`, `plosive+liquid`. Three is a description of ordinary
English rather than a setting.

**`band` is stated as a band.** Lower scales within it remain available;
the band names the range in play. `phonemic:movement` is the full stack.
`sentential:movement` is the structural stack and the entirety of what
survives passage between languages.

**The translation boundary falls inside `band`.** A translator cannot carry
a passage's vowel colors or consonant textures any more than a
transcription carries an orchestra's timbre; what a good translator does
is compose *new* phonemic patterns serving the original's structural
functions[^3]. Any claim about phonemic melopoeia in a translated work is
therefore a claim about the translator, and the `translation` purpose
exists to keep the instrument from making it accidentally.

**`ear=aloud` binds `sustained`.** A sentence longer than one breath is a
defect when the reader is a voice in a room, whatever the setting says.
Where the two conflict, breath governs and the conflict is reported.

---

## Inscape

**The coordination law. Audible patterning is licensed by alignment, and
unaligned patterning is ornament.**

Hopkins gives the condition its name: the interior logic making a form
feel inevitable, such that altering any element damages the whole[^4]. A
passage possessing inscape cannot be substituted into without loss, and
the reader registers that inevitability as *rightness* without tracing its
source.

The mechanism is a trade. Every dimension driven hard raises the
probability the reader notices the technique, and a noticed technique
stops carrying and starts costing. What buys the license is alignment: a
sound doing conspicuous work *the content demanded* reads as inevitability,
and the identical sound doing conspicuous work the content did not demand
reads as a writer arranging.

Stated as it governs:

**`divergent` caps the working range of every other setting.** Where
`divergent` runs above 0.60, no scalar may sit within 0.15 of either
extreme, and a request to place one there is refused and reported rather
than composed. Where `divergent` runs below 0.20, the extremes are fully
available, and the `perform` list is what makes them safe.

Two consequences follow, and both are why `divergent` sits in the document
group rather than among the carry settings.

**It is not a quantity of sound.** It is a relation between the two
channels, and a relation cannot be turned up---which is why the law reads
as a cap on other settings rather than as a setting with a strong
coupling.

**It cannot be assessed from the prose alone.** Whether a sonic decision
answers to content is a question about the content, which is why `perform`
is a required input, and why an instrument given no nomination list can
configure a sonic environment and cannot certify a single sonic event.

**No test determines whether a passage possesses inscape.** The condition
is settled in a reader's body, before that reader can report on it, and
nothing available to the author substitutes for the finding. What is
available is preparation---nomination, alignment, and the vocalization
pass---and preparation is the best instrument there is on a question that
admits no proof.

---

## Roster

**The roster is the first line of configuration.** Three tiers. A
**purpose** is the base and resolves every key; exactly one applies. A
**voice** is an author-derived overlay perturbing a named subset. A
**figure** is a passage-scale overlay, normally sited.

### Purpose --- the base entry

| purpose | divergent | dark | flowing | rough | sustained | suspended | modulated | incidental | transparent | monodic | family | band | channel | ear |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `essay` | 0.30 | 0.50 | 0.60 | 0.35 | 0.65 | 0.55 | 0.70 | 0.45 | 0.40 | 0.70 | fricative+nasal | phonemic:movement | haptic | silent |
| `fiction` | 0.20 | 0.50 | 0.55 | 0.45 | 0.60 | 0.45 | 0.80 | 0.30 | 0.30 | 0.55 | liquid+plosive | phonemic:movement | mimetic | silent |
| `poetry` | 0.10 | 0.50 | 0.50 | 0.40 | 0.20 | 0.60 | 0.65 | 0.10 | 0.15 | 0.40 | liquid+nasal | phonemic:paragraph | haptic | aloud |
| `drama` | 0.15 | 0.50 | 0.55 | 0.45 | 0.45 | 0.50 | 0.85 | 0.25 | 0.35 | 0.25 | plosive+liquid | phonemic:movement | mimetic | aloud |
| `memoir` | 0.25 | 0.65 | 0.75 | 0.20 | 0.70 | 0.50 | 0.70 | 0.30 | 0.45 | 0.75 | liquid+nasal | phonemic:movement | haptic | silent |
| `liturgy` | 0.15 | 0.75 | 0.80 | 0.15 | 0.70 | 0.65 | 0.30 | 0.20 | 0.20 | 0.75 | nasal+liquid | phonemic:movement | architectonic | aloud |
| `oration` | 0.20 | 0.45 | 0.60 | 0.30 | 0.55 | 0.60 | 0.45 | 0.25 | 0.30 | 0.60 | plosive+liquid | phonemic:movement | mimetic | aloud |
| `criticism` | 0.60 | 0.50 | 0.60 | 0.30 | 0.60 | 0.45 | 0.60 | 0.65 | 0.65 | 0.85 | fricative | sentential:movement | architectonic | silent |
| `correspondence` | 0.40 | 0.50 | 0.65 | 0.30 | 0.45 | 0.35 | 0.75 | 0.55 | 0.60 | 0.85 | liquid | lexical:paragraph | haptic | silent |
| `translation` | 0.30 | --- | --- | --- | 0.65 | 0.55 | 0.70 | 0.40 | 0.45 | 0.70 | --- | sentential:movement | haptic | silent |
| `instrument` | 0.55 | 0.55 | 0.65 | 0.30 | 0.60 | 0.50 | 0.60 | 0.60 | 0.65 | 0.85 | fricative+nasal | sentential:movement | architectonic | silent |
| `brief` | 0.70 | 0.50 | 0.60 | 0.30 | 0.40 | 0.25 | 0.50 | 0.75 | 0.80 | 0.90 | plosive | sentential:paragraph | architectonic | silent |
| `spec` | 0.90 | 0.50 | 0.55 | 0.35 | 0.35 | 0.20 | 0.35 | 0.90 | 0.95 | 1.00 | --- | sentential | architectonic | silent |
| `record` | 1.00 | 0.50 | 0.50 | 0.50 | 0.30 | 0.15 | 0.20 | 1.00 | 1.00 | 1.00 | --- | sentential | architectonic | silent |

**`essay`** --- the primary entry and the profile this instrument was
built to serve. Literary non-fiction where sound is a carrier rather than
a decoration. The full band is live, `modulated` runs high because an
argument supplies its own rhythmic demands, and `divergent` sits low
enough that a nominated moment can be performed without the performance
showing.

**`fiction`** --- narrative prose. `divergent` drops and `modulated` rises
because a scene supplies more sonic demands than an argument does. The
polar values here are a starting position most documents will immediately
traverse away from; expect one figure per scene.

**`poetry`** --- `sustained` collapses because the line does work prose
distributes across paragraphs, `incidental` runs to the floor, and `ear`
moves to `aloud` whether or not anyone will read it so.

**`drama`** --- `monodic` runs to its lowest roster value, counterpoint
being drama's native mode: the character's rhythm against the scene's,
the speech against the verse. `modulated` runs highest of any entry
because rhythm is characterization.

**`memoir`** --- retrospect in the first person. Warm, continuous, and
slow, with `rough` near the floor because friction reads as grievance in
this register.

**`liturgy`** --- prose for the voice in a room. Breath is a hard
constraint, `rough` runs to the floor because an assembly cannot
articulate friction in unison, and `modulated` runs *low*: recurrence and
regularity are the effect, and variance would defeat it.

**`oration`** --- a single voice addressing many. `suspended` runs above
`liturgy` because a periodic sentence delivered aloud is the oldest
instrument of held attention there is.

**`criticism`** --- prose about art, which must not compete with its
subject. `incidental` and `transparent` both run high; the sonic channel's
work here is to stay out of the way of the quoted material.

**`correspondence`** --- letters. `band` narrows to `lexical:paragraph`
because a letter has no movement structure to compose across, and
`modulated` runs high because conversational rhythm is what makes a letter
sound like a person.

**`translation`** --- the entry that keeps the instrument honest. Grain
settings are struck out because the band excludes them; a phonemic
directive here would be an instruction only the translator can compose.
What remains is the structural stack, which transfers.

**`instrument`** --- frameworks, skills, methodologies. Sonic work confined
to the junctures, `monodic` near the ceiling, `divergent` above the
halfway point. An operative document that performs its content is a
document whose reader is attending to the wrong thing.

**`brief`**, **`spec`**, **`record`** --- the withholding entries, in
descending order of what remains. `record` is total abstention and is
included so that abstention has a name to invoke.

### Voice --- author-derived overlay

Perturbations, not base entries. Each departs from the purpose in play
and states only the keys it moves.

| voice | perturbation | what it isolates |
|---|---|---|
| `hawthorne` | `sustained=0.90 suspended=0.90 dark=0.70 modulated=0.35 family=nasal+fricative` | Suspension as the sole emotional instrument; resolution felt as bodily settling. |
| `shakespeare` | `monodic=0.10 divergent=0.10 modulated=0.60 rough=0.45` | Counterpoint---speech rhythm against metrical ground, the tension carrying what neither line does. |
| `woolf` | `modulated=0.95 sustained=0.70 flowing=0.80 suspended=0.40 rough=0.20` | Continuous modulation; sentences that resolve and reopen, rhythm tracking a consciousness. |
| `morrison` | `divergent=0.05 transparent=0.15 modulated=0.85 flowing=0.80>0.15@rupture` | Alignment at maximum; the fragmentation *is* the content. |
| `conrad` | `sustained=0.85 suspended=0.20 flowing=0.70 transparent=0.20 dark=0.70 family=fricative+nasal` | Accumulation without suspension; ambient sibilance as environmental density. |
| `mccarthy` | `sustained=0.90 suspended=0.10 flowing=0.75 rough=0.70 modulated=0.10 dark=0.75 family=plosive` | Polysyndeton---flow at the clause, hardness at the consonant, uniformity as implacability. |
| `robinson` | `incidental=0.20 rough=0.10 flowing=0.85 transparent=0.55 modulated=0.75` | Pianissimo; the quietness is the music and the reader leans in. |
| `joyce` | `transparent=0.05 monodic=0.15 band=phonemic:movement channel=architectonic` | Formal musical structure imposed on narrative; melopoeia organizing a whole chapter. |
| `hemingway` | `sustained=0.15 suspended=0.05 modulated=0.10 rough=0.35 family=plosive` | Uniformity as composed ground; the one long sentence lands as changed breathing. |
| `hopkins` | `rough=0.65 transparent=0.10 incidental=0.05 family=plosive+fricative` | Consonant engineering; substitution damages the structure audibly. |
| `thomas` | `dark=0.30>0.85 sustained=0.80 flowing=0.75 transparent=0.15` | Vowel surge---long open sequences that crest and break, texture thickening with thematic pressure. |
| `bulgakov` | `transparent=0.15 modulated=0.60 channel=architectonic` with the whole grain group traversed at each world-shift | Harmonic density as world-marker; the reader hears which setting they have entered before a character appears. |
| `whitman` | `sustained=0.75 suspended=0.15 modulated=0.20 transparent=0.20` | Catalog and anaphora; accumulation by parallel rather than by subordination. |

### Figure --- passage-scale overlay

Sited with `@`. An unsited figure applies document-wide, which is
occasionally right and usually a mistake.

| figure | perturbation | use for |
|---|---|---|
| `bright` | `dark=0.15` | clarity, revelation, precision, edge |
| `gloom` | `dark=0.85` | weight, interiority, enclosure, solemnity |
| `dawn` | `dark=0.80>0.15` | illumination arriving, recognition, relief |
| `dusk` | `dark=0.15>0.85` | descent, closure, gathering weight |
| `monochrome` | `modulated=0.20`, `dark` held | tonal unity, restricted palette, ritual |
| `percussion` | `family=plosive flowing=0.20 rough=0.55` | impact, conflict, decisiveness, arrival |
| `ambience` | `family=fricative flowing=0.70 transparent=0.25` | atmosphere, immersion, the density of a described world |
| `laminar` | `family=liquid+nasal flowing=0.90 rough=0.10` | tenderness, connection, ease, continuity |
| `hinge` | `flowing` traversed sharply at the site | structural joint, disruption, the moment the ground moves |
| `alternation` | `modulated=0.50 sustained=0.60` | general rhythmic engagement; long against short |
| `period` | `suspended=0.90 sustained=0.85` | deliberation, moral weight, resolution that feels earned |
| `respiration` | `modulated=0.90 sustained=0.70` | interiority; rhythm following a character's own attention |
| `polysyndeton` | `sustained=0.90 suspended=0.10 modulated=0.10` | relentless forward momentum; accumulation by mass |
| `fracture` | `flowing=0.75>0.10 sustained=0.70>0.15 modulated=0.90` | trauma, rupture, the failure of narrative coherence |
| `mimesis` | `divergent=0.05 incidental=0.10` | the prose performing what it says |
| `motif` | `transparent=0.10` | binding a passage below the level of its argument |
| `clarity` | `transparent=0.85 incidental=0.75` | the channel standing down; precision governing |
| `refrain` | `transparent=0.20 modulated=0.35` | a returning phrase deepening by changed context |
| `crest` | `dark=0.30>0.85 sustained=0.85 flowing=0.75` | pressure building to a break |
| `procession` | `sustained=0.75 suspended=0.70 modulated=0.25 dark=0.75 flowing=0.85` | ritual, liturgical cadence, architectural balance |
| `hush` | `incidental=0.20 rough=0.10 flowing=0.85 sustained=0.55` | overheard rather than declaimed; the reader leaning closer |
| `grief` | `dark=0.85 suspended=0.75 transparent=0.20 modulated=0.45 family=nasal+fricative` | sorrow accumulating across sentences |
| `confrontation` | `dark=0.20 sustained=0.20 flowing=0.20 divergent=0.10 family=plosive` | sharp, bright, staccato intensity |
| `threshold` | `channel=architectonic`, grain traversed across the boundary | world-shift, movement boundary, entering another order |

---

## Overlay Resolution

Resolution runs in one direction and settles before drafting.

1. **`purpose`** resolves every key.
2. **`voice`** overlays apply in the order given, each overriding the
   purpose on the keys it names. A later voice overrides an earlier one on
   shared keys. **More than two voices is a smear rather than a blend** ---
   report the over-specification instead of averaging it.
3. **`figure`** overlays apply at their sites, and are local overrides by
   construction. Two figures at one site are resolved the way two voices
   are; two figures at disjoint sites do not interact.
4. **Explicit keys** stated in the invocation override everything above.
5. **`divergent` caps last**, after all overlays have resolved. A capped
   value is reported as capped, never silently moved.

A voice and a figure disagreeing on one key is ordinary and resolves by
this order. A voice and a *purpose* disagreeing on `band` or `ear` is not:
those two keys describe what the document physically is, and a voice that
moves them is being asked to do something the purpose forbids. Report it.

---

## Composition Order

Sound is architecture, not polish. A draft written for sense and then
adjusted for sound acquires a worked surface; a draft composed with both
criteria live acquires inscape.

1. Resolve the disposition from the request. Composing or listening.
2. Resolve the roster: purpose, then voices, then figures, then explicit
   keys, then the cap.
3. Take the nomination lists. `perform`, `mute`.
4. Confirm `band` and `ear`. `ear=aloud` makes breath a constraint on
   `sustained` before any other setting is chosen.
5. Site each traverse in the outline against the `perform` list. A traverse
   is a location, not an intention.
6. Where `monodic` runs low, site the two rhythmic lines in the outline.
   This is the step that cannot be recovered at the diction level.
7. Draft with both selection criteria live, at the `incidental` band set.
8. **Vocalize.** Read the draft aloud, or engage the articulatory system
   deliberately where reading aloud is not available. Neither optional nor
   terminal: this is where a passage reading identically silent and aloud
   reveals it has no sonic channel at all, and it may run more than once.
9. Re-nominate. Set what the prose actually performs beside `perform`, and
   correct the list rather than the prose where they diverge.

Skipping step eight defers the finding to a reader, who will experience it
as prose that was merely adequate and will not report why.

---

## Report the Calibration

**Every invocation emits the fully resolved calibration in the response
body and never inside the artifact.** The artifact carries prose; the
response carries the settings that produced it, so a revision request
names a setting instead of describing a symptom.

Emit the full template with resolved values in place of the defaults, and
mark:

- any value moved by a `voice` or `figure`, naming which
- any value capped by `divergent`, with the value requested
- any value set deliberately against its roster entry, with the reason
- any conflict reported rather than resolved

Traverses and their sites are part of the calibration and are emitted with
it. So is the `perform` list as re-nominated at step nine, which is
frequently the most useful line in the report: the difference between the
list stated and the list the prose delivered is the whole of what the next
adjustment has to work with.

---

## Local Override

Any setting may be overridden for a declared region---narrative prose at
one configuration, quoted or catalog material at another. The override is
an exception to the document's configuration and is declared as such. It
is not a property of the document, since what makes a region exceptional
is that the rest of the document is not like it. A setting wanting
override everywhere is a document setting stated wrongly.

A sited `figure` is a local override with a name. Prefer the named form.

---

## Listening

Where the request examines an existing composition rather than composing
one, the settings read as measurements rather than targets, and the work
is detection.

Four passes, layered, ordered so each opens the next.

1. **Pace.** Locate every place the reading rate changes where no semantic
   cause accounts for it. Rate change is the surface signal of a sonic
   event and the only one available before the ear is trained. Attend to
   the consonants at those sites first: articulatory deceleration is the
   commonest cause and the easiest to confirm.
2. **Joint.** Locate the paragraph and section boundaries where the prose
   *feels different*---heavier, brighter, more brittle---and separate the
   portion of that difference attributable to new content from the portion
   attributable to new texture. The two move together frequently and are
   mistaken for one another more frequently still.
3. **Return.** Trace what recurs sonically: vowel sequences, consonant
   echoes, rhythmic figures, anaphora and refrain. Anaphora is the visible
   end of this pass and the doorway to the rest---a reader who can hear
   anaphora can be brought to hear assonance, and from assonance to vowel
   color.
4. **Grain.** Only now the phonemic level, and only with the articulatory
   system engaged: vocalized where possible, and where not, attended as
   shapes the mouth would make.

Present findings by function, location, or technique---never serially.
Serial cataloguing reports that sound occurs; organized presentation
reports what it is carrying, which is the object.

**Self-examination is the distinct case.** Deliberate sonic work submits
readily to inventory. The revealing material is the environment an author
produces without deciding to---the register the hand reaches for while the
deliberating mind is occupied with argument. Mapping it yields access to
compositional instinct otherwise invisible, and it is where the `perform`
list for the next document actually comes from.

---

## Reverse Diagnosis

- "I had to read that twice," where the content is simple ---> `rough` too
  high. Consonant clusters forcing articulatory deceleration at a site
  that wanted none.
- The prose reads as *writerly*, mannered, arranged ---> inscape violated.
  A dimension driven past the cap `divergent` places on it. Correct at
  `divergent` or at the nomination, never by flattening the setting.
- Correct, competent, inert ---> `incidental` too high. The channel was
  never used, and no reader will name the loss.
- Attention habituates and drifts across a chapter ---> `modulated` too low
  at the `movement` band, or set at 0.5 too mechanically, which
  anesthetizes as reliably as uniformity.
- The emotional response falls short of what the content warrants --->
  `divergent` too high. The channels are running in parallel rather than
  converging.
- The passage moves the reader and its summary does not ---> the
  configuration is correct. This is the instrument working.
- Substituting a synonym improves the sentence ---> inscape absent at that
  site.
- A sentence cannot be delivered in one breath ---> `sustained` too high
  for `ear=aloud`. Breath governs.
- A translated work analyzed for vowel color ---> `band` claimed at
  `phonemic` where only the structural stack transfers. The finding, if
  any, is about the translator.
- Sound and content both correct, and the passage still reads as ornament
  ---> `perform` never stated. Alignment cannot be assessed against an
  unstated content event, and the settings will have configured an
  environment where an event was wanted.
- The counter-line never materializes ---> `monodic` set low at step seven
  instead of step six. Counterpoint is an outline decision and diction
  cannot recover it.
- Read aloud, the draft is indistinguishable from its silent reading --->
  there is no sonic channel to diagnose. Return to step seven.

---

## Notes

[^1]: At the threshold of hearing near 3000 Hz, tympanic membrane
displacement measures approximately 10^-9^ cm, less than the diameter of a
hydrogen atom. Ren et al., "A differentially amplified motion in the ear
for near-threshold sound detection," *Nature Neuroscience* 14 (2011):
770--774. <https://pmc.ncbi.nlm.nih.gov/articles/PMC3225052/> The physical
mechanism is established. The mapping from sonic texture to emotional
category is the working hypothesis this instrument operates under, not a
finding it inherits.

[^2]: Electromyographic studies confirm laryngeal and lingual muscle
activity persisting through silent reading in skilled adults. This
subvocal performance is the substrate the whole channel is composed for,
and it is why `ear=silent` is a real setting rather than the absence of
one.

[^3]: Ezra Pound, *ABC of Reading* (London: Routledge, 1934); *How to
Read* (1929). Melopoeia "can be appreciated by a foreigner with a
sensitive ear" while transfer between languages is practically impossible.
<https://en.wikipedia.org/wiki/Ezra_Pound%27s_Three_Kinds_of_Poetry>

[^4]: Gerard Manley Hopkins, *Journals and Papers*, ed. Humphry House
(London: Oxford University Press, 1959). Source of *inscape*, the
condition the coordination law is named for.

[^5]: O.P. Vorobyova, "Stylistic Aspects of Musicality in Literary Text."
Five-dimensional classification of prose musicality, underlying the
`channel` options.
<https://journals.indexcopernicus.com/api/file/viewByFileId/518224.pdf>
