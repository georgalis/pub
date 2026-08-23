---
name: transmission-vantage
description: Positions the reader's cost of knowing where a statement stands---who speaks, from what vantage, at what remove, as of when. Governs viewpoint persistence, sentence contiguity, perspectival layering, unrequested justification, attribution mode, epoch attachment, and chronological alignment. Apply when a document should hold still for a depleted or settled reader, or move freely for a scanning one, or carry the provenance and the moment of every claim for a reader who will contest it or form a verdict from it.
---

# Transmission Vantage

Every perspectival shift asks the reader to locate the speaker again.
Every nested frame holds another anchor open until the sentence
resolves. The cost is neither good nor bad. It is a demand, and this
instrument sets whether the document makes it.

Vantage costs are the silent ones. A reader who has lost track of who is
speaking does not report perspectival difficulty; the reader reports
that the writing was hard to follow, or simply stops. Set vantage on
purpose, because it will not be diagnosed for you.

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

    version 1.2 --- 2026-08-22

    1.1 --- adds the office pair, iuxta and sequent.

    1.2 --- transactional vocabulary resolves into the rated-systems
    register; cron becomes office; adds the template; attribution moves
    last, categorical settings coming after scalars throughout.

## Reading the Settings

**0.0 is the compact, mobile pole; 1.0 is the steady, low-cost pole.**
Each setting is named for the quality maximal at 1.0. At 1.0 the prose
is settled, linked, flat, and bare; every claim stands iuxta its moment,
and the composition runs sequent with the chronology.

A setting names a region to occupy, not a limit not to exceed. Low
settings do not merely permit a mobile vantage; they call for it.

Values read by position, not by scale: `75`, `7.5`, `0.75`, and `3/4`
place a setting identically.

Where a conflict forces a setting off center it yields high, toward the
light pole, because asking too much of a vantage fails
silently while asking too little fails visibly and is corrected by a
second document.

## Template

```
vantage     settled=0.50  linked=0.50  flat=0.85  bare=0.90
            iuxta=0.20    sequent=0.30  attribution=artifact
```

```
attribution  agent        claims anchored to persons
             artifact     claims anchored to documents
             impersonal   claims anchored to conditions
```

Values are the settled-professional default. The full calibration, with
the other two instruments and the document-side declarations, is in the
`transmission` skill and in the roster.

## Invocation

`/transmission-vantage 0.75` sets all scalars to that band.
`/transmission-vantage 0.75 settled=0.4 attribution=agent` overrides
individually; stated values win and the master governs the rest. Bare
invocation defaults to 0.6.

Ordinarily the configuration arrives from the `transmission` transform
rather than by direct setting.

## Settings

### settled --- viewpoint persistence

How long one vantage holds before shifting. Point-of-view changes are
scene cuts: rapid cutting reads as energy to a scanning reader and as
whiplash to a settled one, and the reader's arrival state decides which.

Stamina sets this setting and obligation modulates it. A reader who may
leave at any sentence is recruited by motion, and holds still for nothing
he did not come for, so a voluntary reader takes a lower value than his
capacity alone would indicate.

- **1.0** One vantage per section. Shifts occur only at announced
  structural boundaries, never mid-development.
- **0.5** Vantage persists across a sentence group; shifts prefer
  paragraph seams.
- **0.0** Free cutting, vantage shifting per clause. Correct where the
  document's structure is rotation among items rather than development
  of one: comparative material, rosters, catalogs.

Failure low: the reader reports the piece as jumpy though every sentence
is clear. Failure high: material whose structure is rotation is forced
into false development, and the catalog reads as an argument.

### linked --- sentence contiguity

How far each sentence opens on ground the previous sentence prepared.
The mechanism is theme before rheme: open on given material, place the
new in predicate position.

- **1.0** Fully contiguous. Every sentence opens on given material and
  every section inherits its predecessor's closing concept.
- **0.5** Contiguity dominant, cuts reserved for deliberate emphasis.
- **0.0** Cut-dominant. Sentences open cold. Staccato, energetic; the
  scroller and the reference card both live here.

Failure high: monotone glide. Without cuts the salience system loses its
contrast medium, and the whole burden of emphasis transfers to which
vocabulary recurs. Failure low: the reader assembles the connective
logic that the prose declined to supply.

### flat --- perspectival layering

Layers per sentence. Each layer---a speaker stance, a framing verb, an
embedded self-reference---is an anchor held open until the sentence
closes.

- **1.0** One layer. Framing collapses into direct predication. "The
  report gives the preliminary account," not "I offer this as the
  account's own account of itself."
- **0.5** Two layers. A framing verb may carry one embedded stance.
- **0.0** Three or more strata where precision warrants: a stance about
  a claim about a source. Legal hedging, epistemically fraught findings,
  expert reference where the provenance of every assertion is itself
  information.

Failure low: readers re-read to resolve who claims what about whom.
Failure high: contested attribution flattened into false directness, and
provenance lost where provenance mattered.

**When layering and capacity conflict, provenance moves rather than
departs.** An adversarial reader wants the provenance of every claim
carried in its syntax; a depleted one cannot hold three anchors open to
the end of a sentence. Both conditions occur together more often than
either occurs alone, since adversarial reading is exhausting work.
Resolve high---flat sentences---and relocate what the layers would have
carried: `attribution` at `agent` names the source inside the sentence
instead of nesting a stance about it, and an explicit apparatus beside
the prose carries the rest. A source line, a citation, a column in a
table. Provenance delivered structurally is lighter to read and no less
complete, and the depleted auditor is the reader who proves it.

### bare --- unrequested justification

How much epistemic performance the prose carries that the reader did not
ask for: justification, disclaimer, credibility signaling.

- **1.0** None. Sources are identified by function and never defended,
  ranked, or apologized for. The document stands on its own footing.
- **0.5** Justification only where a reasonable reader would actually
  pause.
- **0.0** Every claim anticipates challenge and arrives pre-defended.
  Audit response, litigation-adjacent finding, adversarial review.

The trap at low settings outside an adversarial context is exact and
worth stating plainly: defending an uncontested claim raises the doubt
it forestalls. The reader had accepted the point, and the defense
attaches a question to settled material.

Failure high: a genuine challenge arrives against a claim that made no
case for itself.

## Time and the Office Declaration

`iuxta` and `sequent` take floors from `office`, a declaration of the
document's office made by the writer and never derived from the reader.
`constructive`: the facts are inventory for what to build next, and
sequence is largely arbitrary. `judicial`: the facts are evidence about
decisions already taken, and the question is not what is reasonable
altogether but what was reasonable at each point in time.

Three orders run through any document that reports events. **Chronology**
is what happened, and it is usually not given. **Knowledge sequence** is
the order in which things became known, which diverges from chronology
as a matter of course---a flaw introduced in March, exploited in June,
and discovered in August has one chronology and a different knowledge
sequence, and a judgment of conduct in July turns entirely on the
second. **Composition sequence** is what the document delivers, and it is
the only one the writer controls outright, which makes it the instrument
through which the other two are honored or overwritten.

`sequent` aligns composition to chronology. `iuxta` aligns composition to
knowledge sequence. They vary independently, which is why they are two
settings: a bare incident timeline runs in perfect occurrence order while
attaching no knowledge state to anything, and a finding grouped by
control family may date every observation while following no order at
all.

### iuxta --- epoch attachment

How far each claim arrives carrying the knowledge state it belonged to.
The setting does not govern dates. It governs the moment at which a
claim's accuracy is asserted to hold.

- **1.0** Every claim stands according to its own moment, and where the
  moment cannot be established the document says so. A claim whose epoch
  is declared unknown is compliant; a claim supplied with a plausible
  one is not.
- **0.5** Epoch carried on any claim bearing on a decision,
  present-anchored elsewhere.
- **0.0** Present-anchored throughout. Every claim states what is now
  known and the moment it became known is not carried. Synthesis,
  specification, reference matter, design---anything whose facts are
  inventory for construction. Cheapest for the reader and correct
  wherever nothing is being judged.

Scrutiny raises this setting, alone among the five it governs. An
adversarial reader re-times the material whether or not invited, so
epoch marking costs less than the challenge it forestalls.

Failure high in a settled document: qualification attached to
uncontested material reads as hedging, which is the trap `bare` names at
its own low pole. Failure low in a judging document: the reader supplies
the present as the epoch of every claim, having been offered no other,
and reaches a verdict on knowledge the actor did not hold. Adding
evidence deepens the fault rather than correcting it, since each new
fact arrives equally timeless.

### sequent --- chronological alignment

How closely composition sequence tracks chronology.

- **1.0** Composition runs in occurrence order and every departure is
  announced. Where chronology is not established, the document reports
  the order as unestablished rather than imposing one.
- **0.5** Chronological within sections, thematic across them.
- **0.0** Composition free. Order is the argument's to choose and the
  reader re-times continuously. Maximum arrangement latitude, which is
  also the latitude within which sequence alone can change what true
  facts appear to mean.

Stamina governs this setting, at the capacity base less a declared 0.20.
Chronological order reduces re-timing work, which is a real call on the
same fact the other capacity-governed settings answer, and a weaker one,
since topical order supplies an economy of its own.

Failure high without `iuxta`: the bare chronology, whose ordering
discipline is visible and whose epoch silence is not. Failure low in a
judicial document: the reader concedes every fact and reports the
account as slanted, which is the correct reading, arrangement having
done the work.

### What the high pole asks

This pair is the only one whose settings can be satisfied by an
admission. Every other setting is satisfied by doing something to the
prose. These two, at their high poles, are satisfied by declaring a gap
the writer cannot close: an epoch that cannot be established is declared
unestablished, an order that cannot be established is reported as
unestablished. Neither licenses imputation, and an imputed order
presented as fact is the costliest error available here, because it
arrives wearing the appearance of rigor.

Expect the opposite instinct. A writer holding the other four settings
reads a high pole as an instruction to add and will supply the missing
epoch from inference.

### attribution --- where claims anchor *(mode)*

- `agent` --- anchored to persons. Maximum accountability and maximum
  stance-tracking cost, since the reader must model who claims, with
  what interest, against whom. Use where responsibility is the message.
- `artifact` --- anchored to documents and presentations. The container
  is inert and requires no interest-modeling. Default for executive
  delivery.
- `impersonal` --- anchored to conditions and states. Zero attribution
  surface, suited to settled fact and consensus finding. Reads as
  evasive wherever accountability is expected.

Descend `agent` to `artifact` to `impersonal` as the reader's need to
evaluate the source falls. Mixed modes are permitted, and each mode
change is itself a vantage shift that spends from `settled`.

`attribution` answers who claims a thing and `iuxta`, above, answers as
of when. The two are one question asked along different axes, and an
`impersonal` attribution carrying no epoch is the pair of silences that
produces most hindsight error.

## Composition Order

A perspectival pass after synthesis, not during it. Set layering to
band, consolidate or fragment vantage spans to `settled`, position or
remove justification, normalize attribution, then set the ratio of
linked openings to cuts.

`sequent` is the exception and belongs in the outline rather than the
pass, since composition sequence is settled before any sentence exists.
`iuxta` runs with the perspectival pass: epoch marking attaches to
claims already written.

## Reverse Diagnosis

Read the defect back to the setting.

- "Hard to follow," said of a document whose sentences are each
  perfectly clear ---> `settled` too low. The reader is paying to
  reorient rather than to understand, and the cost is felt without being
  available to name, which is why the symptom gets described instead of
  the cause.
- "Who is actually saying this?" ---> `flat` too low, several
  perspectival layers open at once inside one sentence.
- "Why are you defending that?" ---> `bare` too low for a
  non-adversarial reader.
- Clear but inert, nothing stands out ---> `linked` too high. No cuts
  remain to carry emphasis.
- The reader tracks personalities instead of findings ---> `attribution`
  should descend toward `artifact`.
- The reader assigns blame the record does not support ---> `iuxta` too
  low. The epoch went unmarked, so the reader supplied the only one on
  offer, which is the reader's own present. The repair is epoch marking
  and not more evidence.
- The reader accepts the chronology and still misjudges the actor --->
  `sequent` high with `iuxta` low. The visibly rigorous failure, and the
  hardest to report, because the ordering discipline is exactly what
  persuaded the reader that the judgment was earned.
- "I lost the thread," said of a document in which every claim is dated
  ---> `sequent` too low for the reader's stamina. Epoch marking without
  order transfers the re-timing work to the reader, and a depleted
  reader declines it. Presents as a `settled` defect and is not one.
- The reader treats a superseded finding as current ---> `iuxta` high
  with `sequent` low, and no precedence cue survived the rearrangement.
  Dating each claim does not by itself say which claim won.
- "Why are you hedging about that?" ---> `iuxta` too high for settled
  material, qualification raising the doubt it forestalls.
- The reader concedes every fact and calls the account slanted --->
  `office` and the reader's expectation disagree. Either the document is
  judicial and `sequent` is too low, or it is constructive and has not
  said so in its opening.

Each of these corrects one document. The posture component behind it
corrects every document for that reader, and that mapping belongs to the
`transmission` skill. The last two are the exception: no posture
component stands behind them, because `office` is an assessment of the
document rather than of the reader.

## Interactions

`linked` at its high pole transfers the entire burden of emphasis to
recurring vocabulary, which makes the `single` setting in
`transmission-land` load-bearing rather than optional. Flattening
layers reduces syntactic cost and leaves semantic pressure untouched: a
flat sentence still detonates, so `spread` in `transmission-load` must
move with it or neither effect lands.

`sequent` at 0.70 and above reaches `transmission-land` the same way.
Composition sequence now belongs to the chronology and can no longer be
arranged to carry the message, so `placement` loses `deferred` and
`single` rises 0.15. Both settings also arrive on the `transmission-load`
budget: epoch marking and announced ordering are content, not framing, so
under a fixed `priority` they are paid for out of `spread` and `plain`.

Temporal validation is a separate matter and stays separate. Building the
epoch record---named states, labeled transitions, deltas distinguished
from persistent properties---belongs to temporal reasoning outside these
instruments, at present a cross-cutting standard within `character-george`
and intended for separation into a skill of its own. `office` decides how
much of that record reaches the page and in what order. It registers
nothing about whether the record is right.
