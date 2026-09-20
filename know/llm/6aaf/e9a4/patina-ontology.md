# Patina --- Ontology

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

    org 6aaf8524 20260920 000300 PDT Sun 12:03 AM 20 Sep 2026 --- revision 4: skill crafted

This document is the authoritative foundation for the skill *patina*. It
is written to stand complete in itself: a future session possessing only
this file, without conversational history, has everything required to
resume, audit, or extend the work without retrograde. Every revision
supersedes its predecessor in full; no revision may summarize away a
prior constraint to save length. Where a later round narrows or reverses
an earlier decision, the reversal and its rationale are recorded in the
[Decision Record](#decision-record) rather than silently dropped. This
declaration is a standing requirement for this document and its
successors.

This is an ontology, not the skill. It fixes the entities, relations,
keys, couplings, dispositions, library schema, report form, and roster
from which the skill will be built. Operative prose, exemplars, and
reverse diagnosis are deferred to crafting.

---

## Contents
<!--contents 2 5-->
<!--
[Office](#office) --- [Boundary](#boundary) --- [Entities](#entities)
--- [Relations](#relations) --- [Keys](#keys) ---
[Couplings](#couplings) --- [Yield](#yield) ---
[Dispositions](#dispositions) --- [Library](#library) ---
[Report](#report) --- [Roster](#roster) ---
[Decision Record](#decision-record) --- [Open Items](#open-items) ---
[Notes](#notes)
-->

---

## Office

**Patina affiliates.** It selects forms already in circulation --- words,
phrases, habits of construction, analogies, allusions --- so that a
reader places the author inside a parlance and receives the subject in
the light the author intends.

Its target outcome is **membership warrant**: the reader's unreflective
inference that the author belongs. Membership warrant is conferred at
reading speed and withdrawn the same way; no argument secures it and no
disclaimer restores it. Where coined vocabulary earns the warrant of
capacity --- the author holds the material --- membership warrant is the
warrant of belonging: the author holds the culture.

**The operating problem.** Prose synthesized by a language model is
recognized by its readers, and the recognition withdraws warrant
retroactively, across everything already read. Such prose is not
unmarked. It belongs to a parlance of its own, one readers learned
recently and recognize by its emblems. **No prose is unaffiliated**;
the only question is with whom. Patina is a prose construction tool that
also specifies the affiliation. It adds belonging to prose that had none
or was synthesized, displacing the machine's markers with a culture's,
and it does so without performing the culture it joins.

**The name.** Bronze leaves the foundry bright and uniform. Weather and
handling give it, over decades, the surface that makes it look as though
it has always stood where it stands. Founders do not wait for that. They
patinate --- heat, chemical washes, wax --- depositing deliberately what
time would deposit slowly, and the practice is a recognized finishing
art rather than a counterfeit of age. The instrument is the patineur's
craft applied to prose: the surface of use, laid on as finish, over a
text that left synthesis bright and uniform.

**The success condition is placement.** A reader, unprompted, places the
author inside the specified parlance and accepts the subject in the cast
in which it was presented. No internal criterion outranks that one.

---

## Boundary

The skill itself is self-contained and names no companion instrument.
This table exists only to verify non-overlap during development.

| instrument | governs | leaves to patina |
|---|---|---|
| coinage | striking new forms and scheduling their return | selection among forms already in stock; membership credential, whose `credential` register a forthcoming coinage revision is expected to separate or retire |
| melopoeia | the sonic channel; its `lexical` band chooses synonyms by sound-shape | synonym choice by social provenance |
| transmission | delivery configured to a reader's posture | the lexicon itself; transmission positions prose and stocks none |

Patina selects by what a form says about its speaker: the parlance it
comes from, the time steeped into it, the associations it brings. When
layered, patina decides which inherited forms appear; the other
instruments decide how forms are struck, sounded, and delivered.

**Key collisions.** `purpose` and `span` are shared deliberately, each
instrument resolving them independently. Patina yields on any other
collision.

---

## Entities

### Parlance

The social type a text is placed inside. Five composable axes:
**domain** (profession, trade, craft, pursuit), **region**, **era**,
**institution**, and **stance**. A document carries a primary parlance
and may carry secondary ones, stated as an ordered stack. A parlance is
realized as a library file; a parlance named without a file resolves at
the intuition tier.

Each parlance has a **role**: `affiliate`, whose markers are used, or
`displace`, whose markers are replaced.

### Marker

The atomic unit: any form whose selection indexes a parlance. Six
classes.

| class | unit | template example |
|---|---|---|
| `lexical` | word, jargon, slang | *86* --- kitchen, out of stock |
| `phraseological` | idiom, collocation, formula | *the cut of his jib* --- nautical |
| `syntactic` | a habit of construction | object deletion in recipe imperatives: *bake until set* |
| `orthographic` | abbreviation, capitalization, spelling | trade abbreviations; house spellings |
| `figurative` | analogy, simile, metaphor chosen by source domain | *trim the sails* for adjusting plans to conditions |
| `allusive` | reference to a shared text, event, or figure | *a pound of flesh* |

Figurative and allusive markers are also **bridges**, defined below.

**Syntactic habits are discovered, not presumed.** Registers documented
densely in the literature --- legal drafting, radio procedure, recipes,
academic hedging --- can be derived from a named domain with reasonable
reliability[^4]. For thinly documented domains, derivation from the
name alone is guesswork presenting as knowledge. A syntactic habit is
therefore specifiable only where the library holds it for the parlance,
and the library acquires it through the discover disposition.

### Salience

A property of a marker: how widely it is recognized as belonging to its
parlance. At 0.0 the marker is **operative**, used unremarked by members
and unnoticed by others. At 1.0 it is **emblematic**, recognized by
anyone as the parlance's own[^2][^3]. Salience is stored per entry, and
the `emblematic` key selects against it.

**Patina's bias is emblematic.** The aim is genuine affiliation within
the reader's reach, not membership that survives an insider's scrutiny.
The content of the prose carries more of the placement than any
operative marker could, and emblems reach the goal more directly.

### Steep

A property of a marker: the time steeped into it. It runs from **new**
(recent in the English print corpus), through **longstanding** (long
attested and still current), to **antique** (long attested, carrying its
age audibly). Steep is stored per entry as attestation and status, and
the `steep` key selects against it, as a value or as a band.

Steep is measured in print, over long baselines. Usage emerging only in
speech or social media lies outside the instrument's evidence and
outside its intent.

### Cast

The light in which the subject is to be received. The vocabulary is
open; examples are reverent, homely, wry, convivial, heroic, elegiac,
urgent, austere, and comic. Cast is a property of the document (and of a
region under local override), and it appears as affinity tags on
library entries.

**The cast is chosen before any marker or bridge is selected**, because
everything selected afterward carries it. It is either stated or
inferred from the material; when inferred, it is reported as a claim for
correction.

*Terminology.* "Disposition" stays reserved for the operating mode
(compose, revoice, discover), following the convention of the instrument
family. The subject's received light is named `cast`.

### Bridge

A figurative or allusive marker that asserts an association between the
subject and something the reader already holds. A bridge has three
parts, in rhetoric's standard terms[^1]:

- **tenor**: the subject carried.
- **vehicle**: the familiar thing that carries it.
- **ground**: what the two share.

A bridge has one further property, **attestation**. It is `attested`
where the vehicle or allusion exists in the culture as stated, and
`invented` where synthesis made it. Invented bridges are listed in the
report as candidates for the library.

**Bridges are the instrument's strongest device and the chief return on
synthesis.** A reader accepts the unfamiliar by association with the
familiar more easily than an author can justify the unfamiliar directly.
Bridges therefore assert couplings the source did not make. That is
their purpose, not a defect.

### Association

The transfer a bridge performs. **The mapping is never one to one; the
association always is.** Readers know an analogy is partial and forgive
a thin ground. What they transfer whole is the vehicle's standing --- its
familiarity, its acceptability, its cast --- to the tenor. If the
vehicle is accepted, the subject is accepted by connection.

Two consequences govern both admission and amplification:

- A marginal analogy in the right cast outperforms a fidelity that
  leaves the subject without flavor.
- An exact analogy in the wrong cast carries the subject into a light
  it should not be received in, however sound its ground.

More bridges are preferred wherever they align with the cast. None are
admitted where they do not.

### Membership Warrant

The outcome the instrument exists to confer; the credential of
belonging. It accumulates across every marker and bridge the reader
accepts. It is settled at reading, never issued by the author, and
withdrawn retroactively when the reader recognizes a foreign parlance
--- most catastrophically the synthetic one. When membership warrant is
withheld, nothing else in the document can fully redeem it. When it is
conferred, the subject arrives already half accepted.

### Displacement Parlance

A parlance whose markers are replaced rather than used. The principal
case is `synthetic`: the vocabulary, phrasing, and constructions by
which readers recognize model-synthesized prose[^5]. A displacement
parlance is an ordinary library file with `role: displace`, and the
`displace` key names which such parlances run.

Displacement is the other half of affiliation, not a rule ranked above
it. The prose moves from one parlance to another: the machine's markers
leave as the culture's arrive.

### Library and Evidence

The library is the set of per-parlance YAML files, held in the skill's
`library/` directory or attached to a session. Evidence is ranked in
four tiers:

1. a library entry carrying an evidence block, such as Ngram series
   supplied as YAML;
2. a library entry without evidence;
3. dated external evidence supplied in session;
4. model intuition.

The model's own sense of currency ranks lowest because its training
distribution carries the biases the instrument works against[^6]:

- **visibility**: emblems are what gets written about;
- **temporal lag**: knowledge anchored at a training cutoff;
- **institutional density**: print and web registers overweighted
  against speech.

Tiers are applied silently, and the calibration report counts them.

### Purpose

The document class, naming a roster entry that resolves every scalar.
Where a class overlaps a sibling instrument's class, the sibling's name
is reused.

### Disposition

The operating mode, derived from the request and never declared:

- `compose`: no draft is present.
- `revoice`: a draft is present.
- `discover`: an attached corpus is mined for library entries.

**Harvest** is a request, not a disposition. It asks for library
entries covering the markers a compose or revoice used, for manual
inclusion or exclusion in future rounds.

---

## Relations

| subject | relation | object |
|---|---|---|
| parlance | holds | markers |
| parlance | has role | `affiliate` or `displace` |
| marker | has | class, salience, steep, cast affinities |
| bridge | is a | marker of class `figurative` or `allusive` |
| bridge | joins | tenor to vehicle over a ground |
| bridge | has | attestation |
| document | has | purpose, cast, parlance stack |
| purpose | resolves | every scalar setting |
| cast | governs | admission of bridges; selection of markers by affinity |
| `emblematic` | selects against | salience |
| `steep` | selects against | attestation and status |
| displacement parlance | supplies | markers to replace |
| library entry | carries | evidence at a tier |
| accepted markers and bridges | confer | membership warrant |
| recognized foreign parlance | withdraws | membership warrant, retroactively |

---

## Keys

**Direction.** Each scale is stated per key; no global direction is
assumed. Values read by position, not by scale: `35`, `3.5`, `0.35`,
and `7/20` place a setting identically. A setting names a region to
occupy, not a limit not to exceed, and a region name may stand in
place of a numeral.

**Two kinds of scalar.** *Intensity* scalars measure how much. Each has
a **patina pole**, the end at which the key adds affiliation, and
yields toward it under conflict (see [Yield](#yield)); their tolerance
is 0.10. *Polar* scalars name which kind, not how much, and have no
patina pole; a conflict between them is resolved by local override,
never by moving toward a pole. Their tolerance is 0.20. A polar key may
be stated as a band, `a:b`, meaning the selection ranges across it.

| key | kind | 0.0 | 1.0 | patina pole | regions |
|---|---|---|---|---|---|
| `neutral` | intensity | saturated with the parlance | no markers added | 0.0 | `saturated` .00-.25, `marked` .25-.55, `tinted` .55-.85, `neutral` .85-1.0 |
| `emblematic` | polar | operative: used unremarked by members | emblematic: recognized by anyone | --- | `operative` .00-.35, `mixed` .35-.65, `emblematic` .65-1.0 |
| `steep` | polar | new in print | antique | --- | `new` .00-.30, `longstanding` .30-.70, `antique` .70-1.0 |
| `gloss` | intensity | markers left for the reader to decode | every marker decoded in context | 0.0 | `undecoded` .00-.30, `contextual` .30-.65, `glossed` .65-1.0 |
| `cited` | polar | inhabited: the author speaks the parlance | cited: the parlance held at quotation distance | --- | `inhabited` .00-.35, `mixed` .35-.65, `cited` .65-1.0 |
| `truss` | intensity | no bridges, or minimal | heavy use of bridges | 1.0 | `minimal` .00-.20, `measured` .20-.50, `frequent` .50-.80, `abundant` .80-1.0 |
| `poetic` | intensity | literal: tight ground, attested allusion only | free: loose ground, invented vehicles and allusions, license to the hallucinogenic | 1.0 | `literal` .00-.20, `grounded` .20-.50, `loose` .50-.80, `free` .80-1.0 |

`truss` takes its name from the bridge: each analogy or allusion is a
supporting member, and toward 1.0 the members multiply until the
subject is carried on a full framework of support.

**Bridge keys.** `truss` sets how many bridges appear; `poetic` sets
how freely they are made. `poetic` **tracks** `truss`: where an
invocation states `truss` and not `poetic`, `poetic` moves by the same
amount from its default, clamped to 0.0-1.0; where the invocation
states `poetic`, it holds. Heavy bridging generally wants a looser
license, and sparse bridging a tighter one.

`neutral` and `truss` are independent. A document may saturate its
bridges while its lexical markers stay light, or the reverse.

| key | values | what it does |
|---|---|---|
| `purpose` | a roster name | resolves every scalar |
| `cast` | open vocabulary | the subject's received light; inferred and reported when unstated |
| `parlance` | `[name, name:secondary]` | stack of affiliating parlances, primary first |
| `markers` | subset of the six classes | classes admitted; default is every class the library holds for the parlance |
| `displace` | `[name]` | displacement parlances; default `[synthetic]` where that file is present |
| `span` | integer | target extent in words; reports rather than binds |

**Invocation.** A purpose and a parlance form a complete invocation;
everything else perturbs. Full per-purpose settings appear in the
[Roster](#roster).

    /patina essay parlance=[kitchen]
    /patina letter parlance=[nautical] cast=homely steep=0.60:0.95
    /patina memo parlance=[unix-admin] markers=[lexical,figurative] poetic=grounded
    /patina fiction parlance=[kitchen] neutral=saturated emblematic=0.90 truss=abundant poetic=free
    /patina essay parlance=[commons] cast=wry cited=0.75 truss=0.80

The last line is satire, reached by perturbing `essay`: a wry cast and
the parlance held at quotation distance.

**Local override.** Any setting may be overridden for a declared region,
for example dialogue against narration, or a quoted passage. The
override is declared as an exception. A setting wanting override
everywhere is a document setting stated wrongly.

---

## Couplings

1. **`neutral` with `emblematic` --- the caricature register.** Where
   `neutral` is at or below 0.25 and `emblematic` is at or above 0.75,
   the render occupies `caricature`: a portrait of the parlance with its
   features simplified or exaggerated, and humor available. The register
   is named and reported, and never capped. Nothing in the instrument
   limits the saturation of emblematic markers, and `gloss` holds its
   setting inside the register, where a gloss may be the only means of
   amplification.

2. **`cast` with every bridge.** Each vehicle carries the cast. A
   vehicle misaligned with the cast is not admitted at any `poetic`
   setting. This is the instrument's one admission rule, and it follows
   from [Association](#association).

3. **`poetic` with attestation.** At `literal`, only attested allusion
   is admitted, over a tight ground. At `grounded`, invented analogies
   are admitted, while allusions stay attested. At `loose` and `free`,
   invented vehicles and allusions are both admitted. Every invented
   bridge is marked and located in the report.

4. **`truss` with `poetic` --- tracking.** Unless stated, `poetic`
   moves with `truss` by the same amount, as defined under
   [Keys](#keys).

5. **`truss` with `cast`.** `truss` sets how many bridges appear;
   the cast sets which bridges may. Amplification never relaxes
   alignment.

6. **`steep` with evidence.** `steep` filters by the attestation and
   status recorded in the library. Where only intuition supplies a date,
   the selection is counted at the intuition tier.

---

## Yield

**Intensity scalars yield toward patina**: `neutral` and `gloss`
toward 0.0, `truss` and `poetic` toward 1.0. The asymmetry is the
inverse of the other instruments' and rests on the same ground: which
failure is silent, and which is visible.

- **Sterility fails silently and catastrophically.** The reader
  recognizes the synthetic parlance, withdraws membership warrant
  retroactively, and says nothing.
- **Excess fails visibly and recoverably.** It is caught in proofreading
  and corrected at revision, before it has consequence.

Yield governs uncertainty, not knowledge. Where a setting is stated or
resolved by the roster, the center holds.

---

## Dispositions

### Compose and revoice

1. **Read the material** --- the brief or the draft, entire. Infer
   `purpose` and `cast`, and report both as claims.
2. **Resolve** the purpose roster entry, the parlance stack, and any
   explicit keys, then apply the couplings.
3. **Fix the cast.** It precedes every selection.
4. **Gather associations.** Collect candidate vehicles and allusions
   from the parlance library that align with the cast, as many as
   `truss` admits, within the license `poetic` allows.
5. **Identify displacement**: the markers of every parlance named in
   `displace` present in the draft, or likely to arise in synthesis.
6. **Draft or revoice.** Place lexical, phraseological, syntactic, and
   orthographic markers at the `neutral` density, the `emblematic`
   salience, and the `steep` band. Place bridges at the sites where the
   subject needs carrying.
7. **Proof for alignment.** Read every bridge against the cast.
8. **Report.**

**Preservation under revoice.** Every proposition in the source draft
survives, and new figurative material is admitted. Bridges may assert
associations the source did not make; that is their purpose. What may
not move: a claim's content, its hedging or force, its attribution, or
its presence. The delta reports propositions moved (none expected) and
the count of bridges added; invented bridges are located in the report.

### Discover

The input is an attached corpus. The output is candidate library
entries.

1. Name the parlance the corpus is taken to represent.
2. Measure marker frequency in the corpus against a baseline: library
   evidence where present, then session-supplied evidence, then model
   intuition. Forms markedly more frequent than in ordinary English are
   candidates.
3. Classify each candidate by class, estimate its salience, and record
   its steep from evidence where available.
4. Detect syntactic habits by construction frequency --- sentence
   length, imperative rate, article deletion, passive rate, and the like
   --- and record them as `syntactic` entries.
5. Emit the entries as YAML under the [Library](#library) schema, for
   amendment by the operator.

### Harvest (request)

After a compose or revoice, emit library entries for the markers and
bridges used, located, for manual inclusion or exclusion. These entries
are emitted only on request, never by default.

---

## Library

### Layout

    patina/
      SKILL.md
      library/
        kitchen.yml
        nautical.yml
        synthetic.yml      # role: displace
        ...

Files are added to the skill directory by hand or attached to a
session. Ngram development arrives as evidence blocks inside library
files.

### File header

```yaml
parlance:
  name: kitchen
  title: Kitchen and cookery
  role: affiliate          # affiliate | displace
  axes: {domain: cookery}
  sources: [ngram, operator]
  revised: 20260919
```

### Entry schema

| field | type | required | meaning |
|---|---|---|---|
| `marker` | string | yes | the form as written |
| `class` | enum | yes | `lexical`, `phraseological`, `syntactic`, `orthographic`, `figurative`, `allusive` |
| `salience` | 0.0-1.0 | yes | operative to emblematic |
| `steep` | map | yes | `attested` (year, decade, or century: `1597`, `1930s`, `c19`); `status` (`new`, `longstanding`, `antique`) |
| `cast` | list | no | affinity tags |
| `gloss` | string | no | decoding, for use under `gloss` |
| `tenor` | list | bridges | kinds of subject the vehicle can carry |
| `ground` | string | bridges | what vehicle and tenor share |
| `attestation` | enum | bridges | `attested` or `invented` |
| `displaces` | list | no | forms this marker replaces, synthetic markers included |
| `admit` / `forbid` | list | no | purposes that license or exclude the marker |
| `evidence` | map | no | see below; absent means tier two |
| `notes` | string | no | free text |

### Evidence block

```yaml
evidence:
  source: ngram            # ngram | study | operator | intuition
  corpus: en               # en | en-US | en-GB | en-fiction, with version
  span: <start>-<end>
  smoothing: <n>
  case_insensitive: true
  retrieved: <yyyymmdd>
  trend: steady            # rising | steady | falling | revived
  series: {}               # optional: decade -> relative frequency
```

### Template spectrum

These entries are illustrative. Their evidence is marked `intuition`
and must be replaced in research sessions; no numeric series is supplied
here, because a fabricated series is worse than none.

```yaml
# kitchen.yml
entries:
  - marker: "86"
    class: lexical
    salience: 0.70
    steep: {attested: c20, status: longstanding}
    cast: [convivial, urgent]
    gloss: "out of stock; take it off the menu"
    displaces: ["no longer available"]
    forbid: ["null"]
    evidence: {source: intuition}
  - marker: "<verb> until <state>"      # bake until set
    class: syntactic
    salience: 0.60
    steep: {attested: c19, status: longstanding}
    cast: [homely]
    notes: "object deletion in imperatives; procedural passages only"
    evidence: {source: intuition}

# nautical.yml
entries:
  - marker: "the cut of his jib"
    class: phraseological
    salience: 0.75
    steep: {attested: c19, status: antique}
    cast: [wry, homely]
    gloss: "a person's look or manner"
    evidence: {source: intuition}
  - marker: "trim the sails"
    class: figurative
    salience: 0.80
    steep: {attested: c19, status: longstanding}
    cast: [pragmatic, austere]
    tenor: [budget cuts, plan adjusted to conditions]
    ground: "adjustment to forces one cannot change"
    attestation: attested
    evidence: {source: intuition}

# commons.yml --- allusion held in common by English readers
entries:
  - marker: "a pound of flesh"
    class: allusive
    salience: 0.85
    steep: {attested: 1597, status: antique}
    cast: [austere, adversarial]
    tenor: [a harsh demand exacted to the letter]
    ground: "a lawful claim pressed past mercy"
    attestation: attested
    notes: "Shakespeare, The Merchant of Venice"
    evidence: {source: intuition}

# software.yml
entries:
  - marker: "technical debt"
    class: phraseological
    salience: 0.70
    steep: {attested: 1992, status: new}
    cast: [urgent, sober]
    gloss: "future cost incurred by an expedient choice now"
    evidence: {source: intuition}

# synthetic.yml --- role: displace
entries:
  - marker: "delve into"
    class: phraseological
    salience: 0.90
    steep: {attested: c19, status: longstanding}
    evidence: {source: study}           # excess-vocabulary finding, note 5
  - marker: "it is important to note"
    class: phraseological
    salience: 0.80
    steep: {attested: c20, status: longstanding}
    evidence: {source: intuition}
```

**Precedence.** An attached file supplements a directory file of the
same parlance, and replaces it entry by entry where a marker appears in
both.

---

## Report

**Every invocation emits the calibration report in the response body,
never inside the artifact.** Library entries used are not listed.
Invented bridges are listed, each located and given its vehicle, tenor,
and cast, as candidates for library calibration uplift. Full library
entries appear only on a harvest request, or as the product of
`discover`.

    patina    essay (inferred)    cast=convivial (inferred)    revoice

    affiliate   parlance=[kitchen, nautical:secondary]   markers=all
                displace=[synthetic]   register=none
    select      neutral=0.45 <p>    emblematic=0.65 <p>    steep=0.40:0.85 <p>
                gloss=0.40 <p>    cited=0.25 <p>
    bridge      truss=0.60 <p>    poetic=0.50 <p>    placed=7    invented=2
    evidence    library=11    session=0    intuition=3
    displaced   4
    delta       propositions: none moved    bridges added: 7
    invented    P3 S1   stockpot left on the back burner -> the deferred backlog    cast=homely
                P5 S2   the ticket rail at the Friday rush -> the release queue      cast=convivial

Marks: `<p>` purpose, `<x>` explicit, `<c>` coupling, `<o>` local
override, `<t>` tracking. The report also carries the region of any
override, and the caricature register wherever it is entered.

---

## Roster

**These are demonstration settings only.** The skill carries the actual
defaults; the two are identical at the outset and may diverge as the
skill is tuned by use.

Each line is a complete invocation, ready to copy and adjust. Change a
value to perturb it; delete a key to return it to the skill's default;
delete `poetic` to let it track `truss`. Replace `name` with a library
parlance. `cast`, `markers`, `displace`, and `span` belong to the
document rather than the purpose, and are omitted.

```
/patina essay    neutral=0.45 emblematic=0.65 steep=0.40:0.85 gloss=0.40 cited=0.25 truss=0.60 poetic=0.50 parlance=[name]
/patina fiction  neutral=0.30 emblematic=0.60 steep=0.30:0.90 gloss=0.20 cited=0.15 truss=0.65 poetic=0.70 parlance=[name]
/patina oration  neutral=0.35 emblematic=0.80 steep=0.50:0.90 gloss=0.30 cited=0.20 truss=0.75 poetic=0.55 parlance=[name]
/patina letter   neutral=0.45 emblematic=0.65 steep=0.40:0.80 gloss=0.35 cited=0.20 truss=0.50 poetic=0.45 parlance=[name]
/patina memo     neutral=0.65 emblematic=0.70 steep=0.30:0.70 gloss=0.55 cited=0.30 truss=0.35 poetic=0.30 parlance=[name]
/patina article  neutral=0.50 emblematic=0.70 steep=0.30:0.75 gloss=0.60 cited=0.35 truss=0.55 poetic=0.40 parlance=[name]
/patina manual   neutral=0.70 emblematic=0.55 steep=0.20:0.60 gloss=0.70 cited=0.25 truss=0.25 poetic=0.15 parlance=[name]
/patina recruit  neutral=0.30 emblematic=0.85 steep=0.20:0.80 gloss=0.25 cited=0.20 truss=0.80 poetic=0.65 parlance=[name]
/patina null     neutral=1.00 truss=0.00 poetic=0.00
```

At `null`, `emblematic`, `steep`, `gloss`, and `cited` are inert.

`essay`, `fiction`, `oration`, `letter`, and `recruit` are shared with
the sibling instruments. `null` is total abstention; `spec` and `record`
resolve to `null` as aliases, so a layered invocation reads
consistently across instruments. Satire is reached by perturbing
`essay`, chiefly through `cast` and `cited`: satire works on ideas,
while the caricature register works on patina. The cast is never a
roster value; it belongs to the subject.

---

## Decision Record

Round 1 was the prototype; round 2 the first review; round 3 the second
review, which produced the first ontology; round 4 the ontology review,
which produced the second; round 5 the key-name review, which produced
the third; round 6 the crafting of the skill, whose extensions this
revision records.

- **Name.** R1 proposed `logopoeia`, after Pound's third mode[^7]. R2
  judged it too academic for the power intended, and adopted `affiliate`
  as the working name for its simplicity. R2 proposed `seasoned` and
  `patina`. R3 rejected `season` for its weather association and
  adopted **patina**.
- **Operative against emblematic.** R1 weighted operative markers
  (members recognize members by the unremarkable). R2 reversed this:
  bias toward emblematic, for genuine affiliation rather than
  scrutiny-proof membership, calibrated against performative
  caricature. R3 affirmed caricature as a legitimate register and
  retained the density coupling without limiting emblem saturation. R4
  struck the coupling's connotation sentence, and struck its clause
  yielding `glossed` low inside the register, since a gloss may be the
  register's only means of amplification.
- **`relation` key.** R1 proposed `member | observer | bridge`. R2
  removed it.
- **Misfire law.** R1 proposed it. R2 removed it: parameter performance
  is tuned by use and proofreading, which keeps the solution space open.
- **Subtraction.** R1 ranked subtraction above addition. R2 asked for
  refactor, and the R2 response recast it as displacement of the
  synthetic parlance, affiliation's other half. R3 affirmed the premise
  that no prose is unaffiliated. R4 confirmed the `displace` default of
  `[synthetic]`.
- **Evidence.** R1's asymmetry paragraph, emergent-usage concerns, and
  insider-departure hypothesis were removed in R2. The English print
  corpus over long baselines is the evidence of credibility; social
  emergence is out of scope. Ranking is library, then dated external
  evidence, then intuition, applied silently.
- **Audit disposition.** R1 proposed it. R2 refactored it as
  **discover**, a library-entry generator from an attached corpus.
- **Disqualifying applications.** Enumerated in R1. R2 directed that
  they not be restated in the skill.
- **Time key.** R1 proposed `established` and `era`. R2 proposed a single
  polar key, `steeped`, with bands, folding in `era`. R3 accepted it and
  renamed it **`steep`**.
- **Preservation.** R2 proposed admitting figurative material only
  where it asserts nothing new. R3 reversed this: bridges assert
  associations the source did not make, and that is their purpose. The
  cast is chosen first, and bridges are amplified wherever aligned.
- **Bridge keys.** R3 proposed `sparing`, running from abundant at 0.0
  to rare at 1.0, and `literal`, with poetic license as its `licensed`
  region. R4 retired `literal`, which had no use case, inverted
  `sparing` to run from none at 0.0 to heavy at 1.0, and introduced
  **`poetic`**, running from literal at 0.0 to free at 1.0, tracking
  `sparing` unless stated. With the patina pole now differing by key,
  R4 replaced the single direction convention with a patina pole
  declared per intensity key. R5 renamed `sparing` to **`truss`**:
  analogy as the truss of a bridge, its supporting members multiplying
  toward 1.0, so the name now designates its own high pole.
- **Report.** R1: always emitted. R2: on request. R3 reversed to
  **always emitted**, with library entries only on harvest. R4: invented
  bridges listed and located for library calibration uplift; library
  entries used are not listed.
- **Library.** R2: populated in dedicated sessions, with template
  examples only in the skill. R3: per-parlance YAML files, in the skill
  directory or attached; Ngram development supplied as YAML. R4
  confirmed precedence: attached files supplement directory files and
  replace them entry by entry.
- **Roster.** R3 accepted the candidate set, reused sibling names where
  classes overlap, and adopted `letter` and `null`. R4 presented the
  roster as copy-ready invocations of demonstration settings, with the
  actual defaults held in the skill; moved `recruit` to `neutral=0.30`,
  so the caricature register is entered by choice rather than by
  default; and placed satire as a perturbation of `essay`. The sibling
  instruments will adopt `letter`.
- **Yield.** R3 proposed yield toward patina, the inverse of the sibling
  instruments. R4 confirmed it.
- **Spelling.** R3: `revoice`, not "re-voice". R5: the key `glossed`
  became **`gloss`**; `glossed` survives as the name of its high region.
- **Credential.** R2: membership credential is this instrument's
  outcome. A coinage revision is expected to separate or retire its
  `credential` register.
- **License.** R2: private development for public release; no
  organization-internal vocabulary in the skill. Internal libraries are
  the operator's concern; the license needs no extension.
- **Crafting extensions.** R6 built `SKILL.md` and a seed library from
  this ontology, and made these additions for verification:
  - the parlance may be inferred from the subject and reported as a
    claim, as `purpose` and `cast` are;
  - compose and revoice run two passes, truss before surface, since
    bridges reshape sentences and markers substitute within them; under
    compose, the truss pass runs at the outline;
  - vehicles are drawn from the parlance stack first and a `commons`
    library after; stock vehicles are markers of the synthetic parlance;
  - library entries whose cast tags oppose the cast are passed over
    while an aligned entry exists;
  - `truss` is inert, and reported, when `markers` excludes both
    `figurative` and `allusive`;
  - under revoice, no claim about the subject may appear outside a
    bridge;
  - a displaced form is replaced by the affiliating marker that
    `displaces` it, else by the plainest form the parlance would use;
  - harvest emits every form placed: library entries with current
    values, new forms as new entries;
  - library files beginning with `_` are documentation, never loaded;
    the seed library ships `_schema.yml`, `commons.yml`, and
    `synthetic.yml`;
  - the purpose name `null` is quoted in YAML, where a bare `null`
    parses as an empty value.
- **`cast`.** Introduced in R3, to keep "disposition" for the operating
  mode while naming the subject's received light. R4 confirmed it.

---

## Open Items

1. **Caricature thresholds** of 0.25 and 0.75.
2. **Roster values**: demonstration only, to be tuned by use.
3. **Crafting extensions** listed under R6 in the decision record.
4. **Exemplars**: one constant source rendered across purposes, once
   a parlance library holds researched entries.

---

## Notes

[^1]: I. A. Richards, *The Philosophy of Rhetoric* (New York: Oxford
University Press, 1936). Source of *tenor* and *vehicle*; *ground* is
the customary third term.

[^2]: Asif Agha, *Language and Social Relations* (Cambridge: Cambridge
University Press, 2007). Source of *enregisterment*, the process by
which forms come to be recognized as belonging to a social type.

[^3]: Michael Silverstein, "Indexical order and the dialectics of
sociolinguistic life," *Language &amp; Communication* 23 (2003):
193--229, <https://doi.org/10.1016/S0271-5309(03)00013-2>

[^4]: Douglas Biber, *Variation across Speech and Writing* (Cambridge:
Cambridge University Press, 1988). Multidimensional register analysis;
the basis for discovering syntactic habits from a corpus.

[^5]: Dmitry Kobak et al., "Delving into ChatGPT usage in academic
writing through excess vocabulary," *arXiv* 2406.07016 (2024), <https://arxiv.org/abs/2406.07016>

[^6]: Jean-Baptiste Michel et al., "Quantitative Analysis of Culture
Using Millions of Digitized Books," *Science* 331 (2011): 176--182,
<https://doi.org/10.1126/science.1199644>; Eitan Pechenick, Christopher
Danforth, and Peter Dodds, "Characterizing the Google Books Corpus,"
*PLoS ONE* 10(10) (2015): e0137041,
<https://doi.org/10.1371/journal.pone.0137041>. Viewer:
<https://books.google.com/ngrams/>

[^7]: Ezra Pound, *How to Read* (1929); *ABC of Reading* (London:
Routledge, 1934).
<https://en.wikipedia.org/wiki/Ezra_Pound%27s_Three_Kinds_of_Poetry>
