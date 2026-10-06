---
name: patina
description: Give prose the patina of a parlance --- a trade, region, era, institution, or stance --- so readers place the author inside a culture rather than recognizing synthesized prose. Selects inherited idiom, jargon, and habits of construction, displaces machine-typical phrasing, and trusses the subject with analogy and allusion aligned to the light it should be received in, drawing on per-parlance YAML libraries with Ngram evidence. Apply when a draft reads as sterile or synthesized, when prose must sound as though it comes from a particular community, when a subject needs carrying to its reader through the familiar, or when an attached corpus is to be mined for library entries.
---

# Patina

No prose is unaffiliated. Prose that sounds like nowhere sounds, to a
reader who has learned the machine's parlance, like the machine. This
instrument chooses the affiliation.

**The success condition is placement.** A reader, unprompted, places the
author inside the specified parlance and accepts the subject in the cast
in which it was presented. No internal criterion outranks that one.

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

    org 6aaf8486 20260920 000022 PDT Sun 12:00 AM 20 Sep 2026

---

## Contents

[Activation](#activation) --- [Office](#office) ---
[Invocation](#invocation) --- [Disposition](#disposition) ---
[Compose and Revoice](#compose-and-revoice) ---
[Preservation](#preservation) --- [Cast](#cast) --- [Truss](#truss) ---
[Markers](#markers) --- [Keys](#keys) --- [Resolution](#resolution) ---
[Yield](#yield) --- [Library](#library) --- [Discover](#discover) ---
[Harvest](#harvest) --- [Report](#report) --- [Roster](#roster) ---
[Reverse Diagnosis](#reverse-diagnosis) --- [Notes](#notes)

---

## Activation

Any one condition is sufficient.

- Prose should read as coming from a particular parlance: a trade, a
  region, an era, an institution, a stance.
- A draft reads as sterile, or as synthesized.
- A subject needs carrying to its reader through analogy or allusion the
  reader already holds.
- An attached corpus is to be mined for library entries.

Self-contained: no prior session, no companion instrument, and no
vocabulary beyond what is current in rhetoric and sociolinguistics.

---

## Office

**Patina affiliates.** It selects forms already in circulation ---
words, phrases, habits of construction, analogies, allusions --- so that
a reader places the author inside a parlance and receives the subject in
the light the author intends. It mints nothing. Every form it places was
in use before the document, and its value is that the reader has met it
elsewhere.

**Membership warrant** is the outcome: the reader's unreflective
inference that the author belongs. It accumulates across every marker
and bridge the reader accepts. It is settled at reading speed and
withdrawn the same way --- retroactively, across everything already
read --- when the reader recognizes a foreign parlance. The synthetic
parlance is the commonest foreign parlance, and recognizing it is the
costliest: a reader who has placed prose with the machine returns no
membership warrant for anything the machine appears to have said.

Patina therefore works in two directions at once. **Displacement**
removes the markers of the parlance the prose is leaving; **affiliation**
places the markers of the parlance it is joining. Neither ranks above
the other; they are one move.

**The name.** Bronze leaves the foundry bright and uniform, and weather
and handling give it, over decades, the surface that makes it look as
though it has always stood where it stands. Founders do not wait for
that. They patinate --- heat, chemical washes, wax --- depositing
deliberately what time would deposit slowly, and the practice is a
finishing art rather than a counterfeit of age. The instrument is that
craft applied to prose.

**Emblematic by bias.** The aim is genuine affiliation within the
reader's reach, not membership that survives an insider's audit. Members
recognize one another by operative markers, forms used unremarked;
readers at large recognize a parlance by its emblems. The content of the
prose carries more of the placement than any operative marker can, so
selection leans emblematic. Saturation is the author's to choose, up to
**caricature**: a portrait of the parlance with its features simplified
or exaggerated, and humor available. Caricature is a register, not a
fault.

---

## Invocation

**Tier one --- a purpose and a parlance.** Complete; nothing else is
required.

    /patina essay parlance=[kitchen]

The purpose may be omitted where the material shows it, and the parlance
where the subject implies one. Either inference, and the `cast`, are
reported as claims for correction.

**Tier two --- what an operator says next.**

    /patina essay parlance=[kitchen] cast=wry
    /patina letter parlance=[nautical, commons:secondary] truss=0.80
    /patina memo parlance=[unix-admin] markers=[lexical,figurative] steep=new
    /patina fiction parlance=[kitchen] displace=[synthetic, legalese]

`cast` names the light the subject is received in; `truss` how heavily
the subject is carried by analogy and allusion; `steep` the time in the
forms; `markers` the classes admitted; `displace` the parlances replaced.

**Tier three --- region names on keys**, tabled under [Keys](#keys). A
region resolves to its center, with its width as tolerance.

    /patina letter parlance=[nautical] neutral=marked truss=frequent poetic=loose steep=antique

**Tier four --- numerals and bands.** A polar key may take a band,
`a:b`, and selection then ranges across it.

    /patina essay parlance=[kitchen] neutral=0.35 emblematic=0.80 steep=0.40:0.90

Values read by position: `35`, `3.5`, `0.35`, and `7/20` place a setting
identically. A setting names a region to occupy, not a limit not to
exceed. Numerals are the report's language, and an operator at tier four
is normally answering a report just read.

**Roster lines are complete invocations.** Copy one from the
[Roster](#roster), change a value to perturb it, and delete a key to
return it to its default.

---

## Disposition

**Derived from the request, never declared.**

- `revoice` --- a draft is present.
- `compose` --- no draft; a brief, an outline, or a subject.
- `discover` --- an attached corpus, with a request to build or extend a
  library.

**Harvest** is a request, not a disposition. After a compose or revoice,
the operator asks for library entries covering the forms placed.

---

## Compose and Revoice

Passes one and two run separately over the whole document and are not
interleaved.

1. **Read the material entire.** Infer `purpose`, the parlance where
   unstated, and `cast`; report each inference.
2. **Resolve** per [Resolution](#resolution).
3. **Fix the cast.** It precedes every selection, since everything
   selected afterward carries it.
4. **Pass one --- truss.** Find the sites where the subject needs
   carrying: the unfamiliar concept, the abstract claim, the point where
   the reader must assent. Gather vehicles and allusions aligned with the
   cast, from the parlance stack first and the commons after, as many as
   `truss` admits and as freely as `poetic` allows. Place them. Bridges
   reshape sentences and paragraphs, so they go in first.
5. **Pass two --- surface.** Displace the markers of every parlance in
   `displace`. Place lexical, phraseological, syntactic, and orthographic
   markers at the `neutral` density, the `emblematic` salience, and the
   `steep` band, under the `gloss` and `cited` settings. Markers
   substitute within sentences the first pass has already built.
6. **Proof for alignment.** Read every bridge against the cast. A bridge
   in the wrong cast is removed or replaced, never kept for its ground.
7. **Check the delta** (revoice) per [Preservation](#preservation), then
   **report** per [Report](#report).

Under compose, pass one runs at the outline, siting bridges before
sentences exist, and pass two runs at the draft.

---

## Preservation

Applies under revoice. **Every proposition in the source draft
survives.**

May move: diction, idiom, sentence boundaries, clause order, paragraph
rhythm.

May be added: bridges. An analogy, simile, or allusion asserts an
association the source did not make, and that is the device's purpose.

May not move: a claim's content, its hedging or force, its attribution,
or its presence. No claim about the subject may appear outside a bridge.

**The delta is a report line, present whether or not it is empty**:
propositions moved, each located (none expected), and the count of
bridges added. An empty delta is stated rather than omitted, since a line
appearing only on failure trains the operator to read for its absence.

---

## Cast

The light in which the subject is to be received. The vocabulary is
open; common casts include reverent, homely, wry, convivial, heroic,
elegiac, urgent, austere, pragmatic, and comic. The cast is stated or
inferred, and when inferred it is reported as a claim. A region may carry
its own cast by local override.

**The cast is the one property no roster supplies**: it belongs to the
subject. It governs bridge admission absolutely, and marker selection by
affinity. Library entries carry cast tags, and an entry whose tags oppose
the cast is passed over while an aligned one exists.

---

## Truss

A **bridge** is a figurative or allusive form that asserts an
association between the subject and something the reader already holds.
It has three parts[^1]:

- the **tenor**, the subject carried;
- the **vehicle**, the familiar thing that carries it;
- the **ground**, what the two share.

Each bridge is **attested**, existing in the culture as stated, or
**invented**, made by synthesis.

**The mapping is never one to one; the association always is.** Readers
know an analogy is partial and forgive a thin ground. What they transfer
whole is the vehicle's standing --- its familiarity, its acceptability,
its cast --- to the tenor. If the vehicle is accepted, the subject is
accepted by connection. A reader accepts the unfamiliar through the
familiar more easily than an author can justify the unfamiliar directly,
and this is the chief return on synthesis: the bridges no source
supplied.

Two consequences govern both admission and amplification:

- A marginal analogy in the right cast outperforms a fidelity that leaves
  the subject without flavor.
- An exact analogy in the wrong cast carries the subject into a light it
  should not be received in, however sound its ground.

**The admission rule.** A vehicle misaligned with the cast is not
admitted at any setting. Wherever bridges align, more are preferred, up
to the density `truss` sets. The key takes its name from the bridge:
each analogy or allusion is a supporting member, and toward 1.0 the
members multiply until the subject rests on a full framework of support.

**Vehicles from the parlance do double work.** A vehicle drawn from the
parlance stack carries the subject and affiliates the author in one
form. The commons --- allusion held by English readers generally ---
supplies the rest. The most frequent vehicles in synthesized prose, the
double-edged sword and the well-oiled machine among them, are markers of
the synthetic parlance, and are displaced like any other.

**`poetic` sets how freely bridges are made.**

- At `literal`, only attested allusion is admitted, over a tight ground.
- At `grounded`, invented analogies are admitted, while allusions stay
  attested.
- At `loose` and `free`, invented vehicles and allusions are both
  admitted, and the ground may run thin. At `free`, the figure may run to
  the hallucinogenic.

Every invented bridge is listed in the report, located, as a candidate
for the library.

---

## Markers

A **marker** is any form whose selection indexes a parlance.

| class | unit | example |
|---|---|---|
| `lexical` | word, jargon, slang | *86* --- kitchen, out of stock |
| `phraseological` | idiom, collocation, formula | *the cut of his jib* --- nautical |
| `syntactic` | a habit of construction | object deletion in recipe imperatives: *bake until set* |
| `orthographic` | abbreviation, capitalization, spelling | trade abbreviations; house spellings |
| `figurative` | analogy, simile, metaphor chosen by source domain | *trim the sails* for adjusting plans to conditions |
| `allusive` | reference to a shared text, event, or figure | *a pound of flesh* |

Figurative and allusive markers are also bridges, governed by
[Truss](#truss).

**Salience** runs from operative, used unremarked by members, to
emblematic, recognized by anyone as the parlance's own[^2]. **Steep**
runs from new in print, through longstanding, to antique. Both are
recorded per library entry; `emblematic` selects against salience and
`steep` selects against steep.

**Syntactic habits are discovered, not presumed.** Registers documented
densely --- legal drafting, radio procedure, recipes, academic hedging
--- can be derived from a named domain[^3]. For a thinly documented
domain, derivation from the name alone is guesswork presenting as
knowledge. `syntactic` is therefore admitted only where the library
holds habits for the parlance, and `discover` is how the library comes
to hold them.

**Displacement.** A parlance with `role: displace` supplies markers to
replace. The replacement is the affiliating parlance's marker wherever
an entry `displaces` the form; otherwise it is the plainest form the
parlance would use. `synthetic`, the forms by which readers recognize
model-synthesized prose[^4], is the principal case and the default.

---

## Keys

Seven scalars and six denoted settings. **Two kinds of scalar.**

**Intensity** --- `neutral`, `gloss`, `truss`, `poetic`. Each has a
**patina pole**, the end at which the key adds affiliation, and yields
toward it under conflict. Tolerance 0.10.

**Polar** --- `emblematic`, `steep`, `cited`. These name which kind, not
how much. They have no patina pole and no yield direction; a conflict
resolves by local override, never by moving toward a pole. A polar key
may be stated as a band. Tolerance 0.20.

| key | kind | 0.0 | 1.0 | patina pole | regions |
|---|---|---|---|---|---|
| `neutral` | intensity | saturated with the parlance | no markers added | 0.0 | `saturated` .00-.25, `marked` .25-.55, `tinted` .55-.85, `neutral` .85-1.0 |
| `emblematic` | polar | operative: used unremarked by members | emblematic: recognized by anyone | --- | `operative` .00-.35, `mixed` .35-.65, `emblematic` .65-1.0 |
| `steep` | polar | new in print | antique | --- | `new` .00-.30, `longstanding` .30-.70, `antique` .70-1.0 |
| `gloss` | intensity | markers left for the reader to decode | every marker decoded in context | 0.0 | `undecoded` .00-.30, `contextual` .30-.65, `glossed` .65-1.0 |
| `cited` | polar | inhabited: the author speaks the parlance | cited: the parlance held at quotation distance | --- | `inhabited` .00-.35, `mixed` .35-.65, `cited` .65-1.0 |
| `truss` | intensity | no bridges, or minimal | heavy use of bridges | 1.0 | `minimal` .00-.20, `measured` .20-.50, `frequent` .50-.80, `abundant` .80-1.0 |
| `poetic` | intensity | literal: tight ground, attested allusion only | free: loose ground, invented vehicles and allusions | 1.0 | `literal` .00-.20, `grounded` .20-.50, `loose` .50-.80, `free` .80-1.0 |

`truss` and `neutral` are independent. A document may be heavily trussed
while its lexical surface stays light, or the reverse.

**`poetic` tracks `truss`.** Where an invocation states `truss` and not
`poetic`, `poetic` moves by the same amount from its default, clamped to
0.0-1.0. Where the invocation states `poetic`, it holds. Heavy bridging
generally wants a looser license, and sparse bridging a tighter one.

| key | values | what it does |
|---|---|---|
| `purpose` | a roster name, positional | resolves every scalar |
| `cast` | open vocabulary | the subject's received light; inferred and reported when unstated |
| `parlance` | `[name, name:secondary]` | stack of affiliating parlances, primary first; inferred and reported when unstated |
| `markers` | subset of the six classes | classes admitted; default is every class the library holds for the parlance |
| `displace` | `[name]` | displacement parlances; default `[synthetic]` where that file is present |
| `span` | integer | target extent in words; reports rather than binds |

---

## Resolution

1. **`purpose`** --- stated, or inferred from the material. Resolves
   every scalar.
2. **`parlance`** --- stated, or inferred from the subject. Each
   parlance's library file is loaded; an attached file supplements a
   directory file of the same name and replaces it entry by entry. A
   parlance with no file resolves at the intuition tier and is reported
   so.
3. **`cast`** --- stated, or inferred.
4. **Explicit keys** --- override the roster.
5. **Tracking** --- `poetic` follows a stated `truss` unless `poetic` is
   itself stated.
6. **Couplings** --- applied last, and reported rather than applied
   silently.

**Couplings.**

- **The caricature register.** Where `neutral` is at or below 0.25 and
  `emblematic` is at or above 0.75, the render occupies `caricature`.
  The register is named and reported, and never capped. Nothing in the
  instrument limits the saturation of emblematic markers, and `gloss`
  holds its setting inside the register, where a gloss may be the only
  means of amplification.
- **Cast with every bridge.** This is the admission rule under
  [Truss](#truss); no setting relaxes it.
- **`truss` with `markers`.** `truss` requires `figurative` or `allusive`
  among the admitted classes. With both excluded, `truss` is inert, and
  the report says so.
- **`steep` with evidence.** `steep` filters by the attestation and
  status recorded in the library. Where only intuition supplies a date,
  the selection counts at the intuition tier.

**Evidence.** Four tiers, in rank order:

1. a library entry carrying an evidence block;
2. a library entry without one;
3. dated external evidence supplied in session;
4. model intuition.

Intuition ranks lowest because the model's sense of what is current
carries the biases the instrument works against: emblems are what gets
written about, knowledge anchors at a training cutoff, and print and web
registers outweigh speech[^5]. Tiers apply silently, and the report
counts them. The instrument never fabricates a frequency series, and it
never claims a trajectory the evidence does not show.

**Local override.** Any setting, the cast included, may be overridden
for a declared region: dialogue against narration, a quoted passage, a
section with a cast of its own. The override is declared as an
exception. A setting wanting override everywhere is a document setting
stated wrongly.

---

## Yield

**Intensity scalars yield toward patina**: `neutral` and `gloss` toward
0.0, `truss` and `poetic` toward 1.0. The reason is which failure is
silent and which is visible.

- **Sterility fails silently and catastrophically.** The reader
  recognizes the synthetic parlance, withdraws membership warrant
  retroactively, and says nothing.
- **Excess fails visibly and recoverably.** It is caught in proofreading
  and corrected at revision, before it has consequence.

Yield governs uncertainty, not knowledge. Where a setting is stated or
resolved, the center holds.

---

## Library

One YAML file per parlance, in the skill's `library/` directory or
attached to a session. Files whose names begin with `_` are
documentation and are never loaded as parlances. Ngram development
arrives as evidence blocks inside library files.

    patina/
      SKILL.md
      library/
        _schema.yml        # annotated schema and one entry per class
        commons.yml        # allusion held by English readers generally
        synthetic.yml      # role: displace
        <parlance>.yml

```yaml
parlance:
  name: kitchen
  title: Kitchen and cookery
  role: affiliate          # affiliate | displace
  axes: {domain: cookery}  # domain, region, era, institution, stance
  sources: [ngram, operator]
  revised: 20260920
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
```

| field | type | required | meaning |
|---|---|---|---|
| `marker` | string | yes | the form as written; a pattern in angle brackets for syntactic habits |
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

---

## Discover

The input is an attached corpus. The output is candidate library
entries.

1. **Name the parlance** the corpus is taken to represent.
2. **Measure form frequency against a baseline**: library evidence where
   present, then session evidence, then intuition. Forms markedly more
   frequent than in ordinary English are candidates.
3. **Classify** each candidate, estimate its salience, and record its
   steep from evidence where available, marking the tier.
4. **Measure construction frequency** --- sentence length, imperative
   rate, article deletion, passive rate, and the like --- and record the
   habits found as `syntactic` entries.
5. **Tag** cast affinities, glosses, and, for figurative candidates, the
   tenors each vehicle can carry.
6. **Emit** the entries as YAML under the [Library](#library) schema,
   for amendment by the operator.

---

## Harvest

On request, after a compose or revoice: emit library entries for every
marker and bridge placed, each located. An entry already in the library
is emitted with its current values, for amendment or exclusion. A form
not yet in the library is emitted as a new entry, marked with its tier.
Harvest is the only occasion on which library entries appear in a
response, apart from the product of `discover`.

---

## Report

**Every invocation emits the calibration report in the response body,
never inside the artifact.** The artifact carries prose. The response
carries the settings, so a revision request names a key rather than
describing a symptom.

**Library entries used are not listed.** Invented bridges are listed,
each located and given its vehicle, tenor, and cast, as candidates for
library calibration uplift.

    patina    essay (inferred)    cast=convivial (inferred)    revoice

    affiliate   parlance=[kitchen, nautical:secondary]   markers=all
                displace=[synthetic]   register=none
    select      neutral=0.45 <p>    emblematic=0.65 <p>    steep=0.40:0.85 <p>
                gloss=0.40 <p>      cited=0.25 <p>
    bridge      truss=0.60 <p>      poetic=0.50 <p>    placed=7    invented=2
    evidence    library=11    session=0    intuition=3
    displaced   4
    delta       propositions: none moved    bridges added: 7
    invented    P3 S1   stockpot left on the back burner -> the deferred backlog    cast=homely
                P5 S2   the ticket rail at the Friday rush -> the release queue      cast=convivial

Marks: `<p>` purpose, `<x>` explicit, `<t>` tracking, `<c>` coupling,
`<o>` local override. The report also carries every inference as a
claim, the region and settings of any override, the caricature register
wherever it is entered, any parlance resolved at the intuition tier, and
`truss` inert where the markers exclude bridges.

---

## Roster

Defaults by purpose. Each line is a complete invocation, ready to copy
and adjust: change a value to perturb it, delete a key to return it to
this default, and delete `poetic` to let it track `truss`. Replace `name`
with a library parlance. `cast`, `markers`, `displace`, and `span`
belong to the document rather than the purpose, and are omitted.

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

At `null`, `emblematic`, `steep`, `gloss`, and `cited` are inert. `null`
is total abstention, named so it can be invoked, and `spec` and `record`
resolve to it as aliases.

Where inference is likely to go wrong:

- `oration` reaches for the antique band, where proverb and scripture
  carry a room.
- `manual` keeps bridges few and literal, because its reader acts on
  every sentence.
- `recruit` sits just outside the caricature register, so a recruiting
  voice enters it only by choice.
- Satire is not a purpose. It is `essay` perturbed, chiefly through
  `cast` and `cited`: satire works on ideas, and caricature works on
  patina.

---

## Reverse Diagnosis

- "This reads like AI" ---> displacement did not run, or the `synthetic`
  library is thin; check `displace`, then `neutral`. Check the bridges
  too: stock vehicles are the machine's markers.
- Correct, competent, anonymous ---> `neutral` too high. The synthetic
  parlance holds by default, and no reader will name the loss.
- Costume, trying too hard ---> the caricature register was entered
  without being chosen; read the `register` line and lower `emblematic`
  or raise `neutral`.
- "I couldn't follow the jargon" ---> `gloss` too low for this reader,
  or `emblematic` too low, so that operative markers only members read
  are being placed.
- Dated, a period piece ---> `steep` too high for the purpose, or its
  band too narrow at the antique end.
- The analogy cheapened the subject ---> the cast is wrong, or a bridge
  escaped the alignment proof. Correct at the cast, never by stripping
  bridges.
- The subject is lost among its figures ---> `truss` too high for the
  subject's weight, or `poetic` rose with it by tracking. State `poetic`
  to hold it.
- A reader challenges an allusion's source ---> an invented allusion
  under `loose` or `free` where the reader expected attestation. Read the
  invented list; lower `poetic` for this document.
- The right parlance, the wrong community within it ---> the stack is
  under-specified; add a secondary parlance or a region axis.
- Accurate markers, and still the prose reads translated ---> syntactic
  habits are absent; the library lacks them, so run `discover`.
- Ironic where sincerity was intended ---> `cited` too high.
- A claim moved, dropped, or appeared outside a bridge ---> preservation
  violated. Correct the render, not the setting, and carry the finding
  into the delta.

---

## Notes

[^1]: I. A. Richards, *The Philosophy of Rhetoric* (New York: Oxford
University Press, 1936). Source of *tenor* and *vehicle*; *ground* is the
customary third term.

[^2]: Asif Agha, *Language and Social Relations* (Cambridge: Cambridge
University Press, 2007), source of *enregisterment*; Michael Silverstein,
"Indexical order and the dialectics of sociolinguistic life," *Language
&amp; Communication* 23 (2003): 193--229,
<https://doi.org/10.1016/S0271-5309(03)00013-2>

[^3]: Douglas Biber, *Variation across Speech and Writing* (Cambridge:
Cambridge University Press, 1988). Multidimensional register analysis;
the basis for discovering syntactic habits from a corpus.

[^4]: Dmitry Kobak et al., "Delving into ChatGPT usage in academic
writing through excess vocabulary," *arXiv* 2406.07016 (2024),
<https://arxiv.org/abs/2406.07016>

[^5]: Jean-Baptiste Michel et al., "Quantitative Analysis of Culture
Using Millions of Digitized Books," *Science* 331 (2011): 176--182,
<https://doi.org/10.1126/science.1199644>; Eitan Pechenick, Christopher
Danforth, and Peter Dodds, "Characterizing the Google Books Corpus,"
*PLoS ONE* 10(10) (2015): e0137041,
<https://doi.org/10.1371/journal.pone.0137041>. Viewer:
<https://books.google.com/ngrams/>
