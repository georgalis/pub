---
name: transmission
description: Reader-first delivery control. Assess a reader's posture---fluency, stamina, appetite, scrutiny, triage, obligation---declare the document's office, and resolve both into a configuration for the load, land, and vantage instruments before any prose is composed. Apply when a document's delivery should be set deliberately rather than by instinct, when the same content must reach two different audiences, or when a draft has been received badly and the cause must be located rather than guessed at.
---

# Transmission

Delivery is the manner in which finished content reaches a particular
reader, and it moves independently of what is being said. This skill
holds the reader model and the transform. The three instruments hold the
settings.

Assess the reader. Resolve the configuration. Then compose.

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

    version 1.2 --- 2026-08-22

    1.1 --- adds the office declaration and its settings iuxta and
    sequent; renames the landing instrument to land; corrects the
    posture count from five to six.

    1.2 --- credit becomes headroom and the transactional vocabulary
    resolves into the rated-systems register the rest of the framework
    was already using; cron becomes office; adds the template; gives
    obligation a continuous derivation, deference an off-grid curve,
    and every scalar a floor as well as a ceiling.

## Direction and Naming

**0.0 is the compact, mobile, forceful pole; 1.0 is the steady, gradual,
low-pressure pole.** Equivalently: 0.0 is heavy on the reader, 1.0
is light.

Every scalar setting is named for the quality maximal at 1.0, so a
configuration reads without consultation. Categorical settings come last
within each instrument, so a block scans as numbers and then modes. At 1.0 the prose is settled,
linked, flat, bare, spread, sparse, plain, grounded, steady, and single;
every claim stands iuxta its moment, the composition runs sequent with
the chronology, and the ask arrives with maximum deference.

Values read by position, not by scale. `75`, `7.5`, `0.75`, and `3/4`
place a setting identically.

A setting names a region to occupy, not a limit not to exceed. Each
resolves to a **center**, a **tolerance** band around it, and a
**yield** direction for conflict.

## Template

Two forms. The first is what a writer states; the second is the full
calibration, for overriding a setting during revision.

```
/transmission
  fluency=0.60  stamina=0.50  appetite=0.40  scrutiny=0.15
  triage=full   obligation=0.90
  office=constructive  cadence=misura  priority=content  span=
```

```
posture     fluency=0.60  stamina=0.50  appetite=0.40  scrutiny=0.15
            triage=full   obligation=0.90
document    office=constructive  cadence=misura  priority=content  span=
load        spread=0.53   sparse=0.50   plain=0.42   grounded=0.65
land        steady=0.85   deference=0.35  single=0.50  placement=deferred
vantage     settled=0.50  linked=0.50   flat=0.85    bare=0.90
            iuxta=0.20    sequent=0.30  attribution=artifact
```

The values shown are the settled-professional default, which is roster
entry C2-S1-T1 computed rather than chosen. Any key left unstated resolves
to the value above and widens its tolerance, so an under-specified request
looks under-specified rather than average. Overwrite what should move.

The categorical options, in the order they appear above:

```
triage       full         reads it through
             scan         reads headings, descends selectively
             decide       reads the opening and decides
             sentence     meets one sentence in passing
office       constructive facts are inventory for what to build next
             judicial     facts are evidence about decisions already taken
cadence      staccato     short declaratives dominant
             misura       medium sentences, short ones as punctuation
             legato       long-breath sentences, each resolving in turn
priority     content      length floats, detail is preserved
             balanced     the shortfall is distributed
             extent       the span holds, content is cut
placement    early        stated in the opening, developed after
             deferred     arrives once the development has earned it
             coda         deferred, and the message restates the development
             frame        early, with a coda return
             sentence     the whole document is the message
attribution  agent        claims anchored to persons
             artifact     claims anchored to documents
             impersonal   claims anchored to conditions
```

## Posture

Six components. Each states what the reader **has or does**, never what
the reader needs, so the inference stays in the transform where it can
be audited.

- **fluency** --- vocabulary and conceptual holdings in this domain.
- **stamina** --- assembly rate available now: fatigue, time pressure,
  position in the day.
- **appetite** --- desire for compression, as against capacity for it.
- **scrutiny** --- degree to which the reader evaluates the writer
  alongside the content. Settled, guarded, adversarial by role.
- **triage** --- `full`, `scan`, `decide`, `sentence`. What the reader
  does with the document physically.
- **obligation** --- how far the reader is obliged to read at all. High:
  attention secured by role or relationship. Low: a reader present by
  choice, who departs the moment the prose asks for effort, quietly and
  without complaint.

**headroom** is how much difficulty this reader takes before the prose
starts to distort. It is bounded by the weaker of
fluency and stamina---a specialist at the end of a hard week holds
everything and can assemble nothing---and it is spent to the degree
appetite permits. Three components compose the headroom; scrutiny, triage,
and obligation condition how it may be spent.

Headroom runs opposite to the settings: the more a reader can carry, the
more the document may ask, and asking is the heavy pole. High headroom
produces low numbers. The transform carries this inversion; the writer
never performs it.

## Invocation

    /transmission posture: fluency=0.8 stamina=0.3 appetite=0.7
      scrutiny=0.2 triage=scan obligation=0.9
      office=constructive cadence=misura priority=content

Stage one emits the resolved configuration---centers, tolerances, yield
directions, couplings applied---and stops. Stage two composes against
it, on confirmation or amendment.

Emitting the configuration visibly is not ceremony. It makes the
inference correctable at the posture rather than the prose, it makes the
configuration reusable, and it gives the trial procedure structure.

Partial posture is legitimate. Unstated components resolve to the
settled-professional default and widen their tolerance, so an
under-specified request looks under-specified rather than average.

A named roster archetype may be invoked in place of a posture and
perturbed from there.

## Resolution

1. Read the six components. Compute capacity as the lower of fluency
   and stamina.
2. Set the stamina-governed and fluency-governed settings from capacity,
   inverted: low capacity produces high settings.
3. Apply appetite to `spread` and `plain`. Appetite overrides fluency
   where they disagree, since a reader who wants compression is asked
   even where capacity would permit indulgence.
4. Apply scrutiny to `bare`, `flat`, `attribution`, and `deference`.
5. Apply triage to `placement`, `priority`, and `single`.
6. Apply obligation to `steady`, `settled`, and `deference`.
7. Resolve any setting that received two answers by the disagreement
   rule below, then apply the couplings.
8. Take the four document-side inputs from the writer, not from the
   posture. `office` sets floors under `iuxta` and `sequent` before the
   couplings run.
9. Clamp every scalar to the range 0.0 to 1.0. High fluency together
   with high appetite drives `plain` and `spread` below zero if they are
   left unbounded, and a floor is as necessary as a ceiling.
10. Emit. Default tolerance is plus or minus 0.10, widening to 0.20
    wherever the components governing one setting differ by more than
    0.30.

### Governance

| Component | Type | Less of it calls for more |
|---|---|---|
| fluency | scalar | `plain`, `grounded` |
| stamina | scalar | `spread`, `sparse`, `settled`, `linked`, `grounded`, `sequent` |
| appetite | scalar | `spread`, `plain` --- and appetite outranks fluency |
| scrutiny | scalar | `bare`, `flat`, `iuxta`; `attribution` and `deference` below |
| triage | categorical | sets `placement`, `priority`, `single` |
| obligation | scalar | runs the other way; see below |

The column reads one way for five components and that is not a
coincidence. Capacity and the settings are opposed by construction---the
more a reader can carry, the more the document may ask, and asking is
the heavy pole---so a component that names something the reader *has*
will always call for higher settings as it falls. Read the table as a
single sentence with five subjects, and any row that seems to need its
own sign is a row to check.

All four stamina-governed settings reduce the cost of assembly, and the
condition that raises one raises the rest. `sequent` is the fifth and
takes the base less a declared 0.20, chronological order being a weaker
call on the same fact: re-timing cost is real but smaller than
reorientation cost, and topical order supplies an economy of its own.
`iuxta` is the one setting scrutiny raises rather than lowers, since an
adversarial reader re-times the material whether or not invited. `grounded` answers to both
fluency and stamina and resolves by the disagreement rule. Triage governs `single`
because the less of a document a reader consumes, the more the recurring
vocabulary must reduce to the message; where `linked` sits at 0.70 or
above, `single` rises a further 0.15, contiguous prose having
surrendered the cuts that would otherwise carry emphasis.

**Obligation decides whether the reader exists, and it is the one
component that moves with its settings rather than against them.** Headroom
and scrutiny set `steady` for a reader who must read. A reader who may
leave is recruited by valence movement and by a mobile viewpoint, and
cannot be mandated at all: as obligation falls, `steady` falls hard and
`settled` falls with it, while `deference` rises. Nothing else moves, because voluntariness changes the reader's
terms rather than the reader's capacity.

The magnitudes are continuous rather than a switch. Take the shortfall
against the obliged professional case, which is `(0.90 - obligation)`
divided by 0.90 and clamped to the unit range, and apply it to the
full-scale deltas: `steady` less 0.60, `settled` less 0.35, `deference`
plus 0.30. At a shortfall of 0.60 or more, `placement` moves to `early`,
a reader who may leave rarely reaching a deferred message. A reader at
obligation 0.70 is neither the voluntary case nor the obliged one, and
this rule is what makes that reader computable.

### Where two components disagree

Take the value nearer the light pole, conceding a step toward the
stronger pull.

`flat` is the case that shows it. An adversarial reader wants
perspectival layers carrying the provenance of every claim; a depleted
reader cannot hold three anchors open to the end of a sentence. Resolve
high with a concession downward, and move the provenance out of syntax
and into structure---named attribution in the sentence, an explicit
apparatus beside it. `bare` resolves the same way: pre-emptive defense
is itself load, and a depleted reader cannot carry it however
adversarial the setting.

### Four inputs the reader does not supply

**cadence** is declared from document kind. The same reader takes
different rhythms for a catalog and an argument. One constraint is
enforced regardless: `spread` at 0.70 and above excludes `staccato`,
since distribution needs span. Below that, cadence is free.

**steady** takes an override from genuine emergency, which no assessment
of the reader detects.

**priority** takes an override wherever extent is fixed externally, by a
form, a limit, or a house standard.

**office** declares what the document does with its facts.
`constructive`: the facts are
inventory for what to build next, sequence largely arbitrary, and the
question is what is now true and what follows from it. `judicial`: the
facts are evidence about decisions already taken, sequence load-bearing,
and the question is not what is reasonable altogether but what was
reasonable at each point in time. Default `constructive`, safe in one
direction only---a constructive document delivered judicially is merely
costly, while a judicial document delivered constructively is wrong.
The declaration sets floors under `iuxta` and `sequent`: 0.20 and 0.20
constructive, 0.85 and 0.70 judicial.

**Scrutiny is not monotone.** A settled reader wants `bare` high and
`attribution` at `artifact`. A guarded reader, evaluating the writer's
claim to authority, wants `deference` conspicuously above what standing
would justify and `bare` only moderately lowered. An adversarial reader
expects assertion and is served by low `bare`, low `flat`, `attribution`
at `agent`, and `deference` set by actual standing. Deference rises in
the middle of the scrutiny range and falls again at its end, and the peak
sits at scrutiny 0.50 exactly. Off-grid values interpolate along three
points: 0.15 to 0.35, 0.50 to 0.65, 0.85 to 0.30. This is the only
setting whose curve is not monotone, and therefore the only one whose
midpoint cannot be reasoned to from its ends.

**Triage governs placement absolutely.** `full` takes `deferred` or
`coda`; `scan` takes `frame`; `decide` takes `early` or `frame`;
`sentence` takes `sentence`. Unknown triage takes `frame`. Triage also
sets which term of the length relation tends to bind: a scanning or
single-sentence reader makes extent the constraint, a full reader lets
content float.

## Yield

**Yield runs high across every setting.** Where a conflict forces a
setting off center, it moves toward the light pole.

The asymmetry is uniform and worth stating once. Asking too much of a reader
fails silently---the reader experiences difficulty without being able to
name its source, reports the writing as poor, and does not return.
Asking too little fails visibly and recoverably---the reader is mildly patronized
and says so, and a second document corrects it.

Two exceptions. Where appetite is confidently high, `spread` yields low:
distribution offered to a reader who wanted compression registers as
time spent without consent, and that failure is not mild. And the
judicial `office` floors do not yield at all: below them the document does
not become costly, it becomes false, which puts `office` in the same
class as the `steady` emergency override rather than in the ordinary
conflict economy.

Yield governs uncertainty, not knowledge. Where the posture is known,
set the center.

## Couplings

Seven interactions survive the reader-first reorganization and belong
here rather than to any one instrument.

- `deference` and `placement` multiply rather than add. A forceful ask
  placed early reads as command; deferred, as a conclusion the reader
  arrived at.
- `spread` and `cadence` can contradict. Full distribution in a clipped
  register has no span to distribute across. Lengthen the sentences,
  lower spread, or declare a local override.
- `linked` and `single` both produce coherence. Where every sentence
  opens on prepared ground, the whole burden of emphasis falls on which
  vocabulary recurs, and `single` becomes load-bearing.
- `spread` low throughout removes contrast as an emphasis mechanism.
  Density is the baseline; emphasis comes from placement and recurrence.
- `sparse` and `grounded` are one operation. Slowing the arrival of
  concepts repays only where the concepts that arrive are founded.
- `iuxta` and `sequent` are generated together. Where `sequent` runs
  more than 0.35 above `iuxta`, raise `iuxta` to close the gap. The
  excluded region is the bare chronology---perfect order carrying no
  epoch---which produces a false verdict more efficiently than any other
  configuration available, precisely because its ordering discipline is
  visible and its epoch silence is not.
- `sequent` and `placement` trade. At 0.70 and above, composition
  sequence belongs to the chronology and can no longer be arranged to
  carry the message: `placement` loses `deferred`, and `single` rises
  0.15 to take the emphasis arrangement drops. The narrowing stays
  inside what triage already allows.

## Length

Precision relocated is not precision removed. Content held fixed,
lowered compression moves that content into more tokens rather than
discarding any of it.

**Content, compression, and length form a triple of which any two may be
chosen. The third follows.** A document required to be short, plain, and
complete is over-specified, and saying so is the correct response.

`priority=content` lets length float, correct wherever vital detail
binds. `priority=extent` holds the span and requires content to be cut,
returning an editorial decision to the writer rather than letting
compression absorb it silently. `priority=balanced` distributes the
shortfall, correct only where no term is genuinely fixed.

`span` may accompany it where a target length is known. Length is
otherwise an output, reported after composition rather than set before
it.

## Report the Calibration

Every invocation emits the fully resolved calibration in the response
body and never inside the artifact. The artifact carries prose; the
response carries the settings that produced it, so that a revision
request names a setting instead of describing a symptom.

Emit the full template from the section above with resolved values in
place of the defaults. Mark any value that was floored by the office,
overridden, moved by a coupling, or set deliberately against its derived
value, and give the reason in the last case. No worked example is given
here, because an example in this position gets copied as though it were
the reference form.

## Local Override

Any setting may be overridden for a declared region---frame prose at one
configuration, catalog or quoted material at another. The override is an
exception to the document's configuration and is declared as such. It is
not a property of the document, since what makes a region exceptional is
that the rest of the document is not like it.

## Diagnosis Returns to Posture

The instruments map a reader's complaint to the setting that produced
it. This skill maps that setting back to the component that was
misassessed, which is where the correction belongs---a configuration
corrected at the setting fixes one document, and a posture corrected
fixes every document for that reader.

- `spread` or `sparse` too low ---> stamina assessed too high. The most
  common error, since writers under pressure compress while readers
  under pressure receive compression poorly, and the two states
  frequently coincide inside one exchange.
- `plain` or `grounded` too low ---> fluency assessed too high, usually
  by taking a job title for a holding. Where the reader clearly holds
  the vocabulary and still asks to be reminded of a term, the error was
  stamina, not fluency.
- `spread` too high with a specialist ---> appetite assessed too low,
  which is the default error, since appetite is assumed more often than
  observed.
- `bare` too low outside an adversarial context ---> scrutiny assessed
  too high. Defending an uncontested claim raises the doubt it
  forestalls.
- `placement` wrong ---> triage assessed wrong, and triage is the one
  component that can simply be asked about.
- `iuxta` or `sequent` wrong ---> not a posture error at all. The
  document's office was declared wrong, and it is the one input no
  assessment of the reader supplies or corrects. A reader who concedes
  every fact and calls the account slanted is reporting this and nothing
  else.
- An audience that should have engaged did not ---> obligation assessed
  too high. The costliest misassessment available, since it costs
  the readership entire rather than degrading it, and it leaves no
  complaint to diagnose from.

## What Stays With the Writer

Diagnosis. Every input here is an assessment of a specific reader in a
specific week, and a confident transform applied to a wrong posture
configures with precision for an audience elsewhere.

Accuracy. A well-configured document delivers a wrong finding
efficiently, and no setting registers anything amiss. `office` is the near
edge of this and not an exception to it: the declaration positions how
much of the epoch record reaches the page, and building that record
belongs to temporal reasoning outside these instruments.

Standing. Low `deference` presupposes an authority held independently.
Configuring a firm ask expresses a right rather than conferring one.

Generative inventory. These settings position prose; they do not stock a
lexicon, and the compact pole of `plain` leaves the writer to supply
what a maximum-density instrument would provide.
