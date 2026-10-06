---
name: transmission-land
description: Positions where a document spends the reader's marked attention and what survives the reading. Governs affective steadiness, the force of the ask, recurrence discipline, and message placement. Apply when a message must land at a chosen weight on a chosen reader---from a mandate delivered to a settled executive without alarm, to a single recruiting sentence aimed at attention not yet won.
---

# Transmission Land

Salience comes out of uniformity, and the companion instruments supply
the uniformity this one draws on. A document emphatic everywhere
emphasizes nothing. A document uniform anywhere, at any pressure, with
one placed event, emphasizes exactly that event.

The message need not be a directive. It is whatever the reader should
carry away: an ask, a finding, a warning, a single idea.

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

    version 1.2 --- 2026-08-22

    1.1 --- renamed from transmission-landing, the house convention
    excluding -ing forms from names and keys; records the sequent trade.

    1.2 --- transactional vocabulary resolves into the rated-systems
    register; cron becomes office; adds the template.

## Reading the Settings

**0.0 is the forceful, dramatic pole; 1.0 is the steady, low-pressure
pole.** Each setting is named for the quality maximal at 1.0. At 1.0 the
prose is steady and single, and the ask arrives with maximum deference.

A setting names a region to occupy, not a limit not to exceed.

Values read by position, not by scale: `35`, `3.5`, `0.35`, and `7/20`
place a setting identically.

Where a conflict forces a setting off center it yields high, toward the
light pole. An ask pitched above the writer's standing converts a
receptive reader into an evaluating one and is not recoverable within
the document; an ask pitched below it is ignored as optional and is
recoverable by a follow-up.

## Template

```
land        steady=0.85  deference=0.35  single=0.50  placement=deferred
```

```
placement    early        stated in the opening, developed after
             deferred     arrives once the development has earned it
             coda         deferred, and the message restates the development
             frame        early, with a coda return
             sentence     the whole document is the message
```

Values are the settled-professional default. The full calibration, with
the other two instruments and the document-side declarations, is in the
`transmission` skill and in the roster.

## Invocation

`/transmission-land 0.35` sets all scalars to that band.
`/transmission-land placement=deferred deference=0.35 steady=0.9`
overrides individually. Bare invocation defaults to 0.5.

Ordinarily the configuration arrives from the `transmission` transform
rather than by direct setting.

## Settings

### steady --- affective weather

How far valence moves across the document. Alarm, urgency spikes, and
tonal whiplash convert a settled reader into a vigilant one, and
vigilant readers evaluate defensively rather than receive. But valence
movement is also the recruitment instrument for attention not yet won.

- **1.0** Flat. Gravity carried entirely by content and placement, never
  by tonal signaling. A document calm about serious things signals
  command of the situation.
- **0.5** Gradual movement. Urgency may build across sections and never
  spikes within one. No oscillation between alarm and reassurance.
- **0.0** Valence unrestricted. Dramatic register: genuine emergency,
  recruitment, popular writing that must earn its reader's presence.

Headroom and scrutiny set this for a reader who must read, and the
professional range holds it above 0.80 throughout. What decides whether
that reader exists is `obligation`: a reader present by choice departs
the moment the prose asks for effort, and valence movement is the
instrument that keeps them. This is the setting where popular and
professional cases invert outright, and the movement that recruits a
casual reader puts a settled one on alert.

Genuine emergency overrides all of it. That is a fact about the
situation, not about the audience, and no assessment of the reader
detects it.

Failure high: applied to a real emergency, steadiness reads as
negligence; applied to an audience whose attention had to be won first,
it registers as absence and the readers never arrive.

### deference --- the force of the ask

Named positions along a scalar.

- **1.0** *invitation* --- maximum reader autonomy, minimum delivered
  force. Upward influence without standing; ideas offered to mature as
  the reader's own.
- **0.7** *option-framing* --- structured alternatives whose ordering
  does the persuading.
- **0.5** *recommendation* --- the ask carried by evidence weight, the
  reader's authority to decide explicitly preserved.
- **0.3** *directive* --- obligation stated as fact about the situation
  rather than as command at the reader. Depersonalized, firm without
  confrontation, and frequently the executive optimum.
- **0.0** *mandate* --- obligation stated as command. Compliance
  contexts where the authority is the writer's to invoke.

Deference and placement multiply rather than add. A mandate placed early
reads as command; the same mandate deferred reads as a conclusion the
reader arrived at independently. Soft registers tolerate early
placement; forceful asks want deferral, and the more force an ask
carries the more the development preceding it repays.

Failure low: the ask sits above the writer's actual standing, reads as
overreach, and converts a receptive reader into an evaluating one.
Failure high: a necessary instruction reads as an optional suggestion.

### single --- recurrence discipline

How nearly the document's recurring vocabulary reduces to one phrase.

Recurrence is a document's highlighting system: whatever recurs, the
reader retains, and the mechanism operates on whatever happens to recur.
Unbudgeted, a document highlights by accident---a subsidiary phrase that
fits well gets used four times while the message is stated once with
great care, and the reader leaves carrying the subsidiary phrase. It
gets quoted back in a meeting, and the writer experiences a small
mystery in place of the predictable outcome it was.

- **1.0** Only the vocabulary of the message recurs; competing
  repetition is actively varied away. The document has exactly one
  memorable phrase and it is the one that was chosen.
- **0.5** The message vocabulary receives deliberate recurrence;
  competitors rotate to synonyms past three appearances.
- **0.0** Unmanaged. Natural repetition stands.

Triage governs this setting: the less of a document a reader consumes,
the more the recurring vocabulary must reduce to the message. A further
rise of 0.15 applies wherever `linked` sits at 0.70 or above, contiguous
prose having surrendered the cuts that would otherwise carry emphasis.

The mechanism of establishing a phrase for recurrence belongs to
`transmission-load`; the allocation of the recurring position belongs
here.

Verification, available before anyone else reads the draft: name the
phrase the reader will repeat afterward, and compare it against the
message.

### placement --- where the message sits *(mode)*

Selection follows triage behavior, which varies independently of
everything else about the reader.

- `early` --- stated in the opening, developed after. Suited to readers
  who triage by first paragraph and to documents whose body is reference
  matter. Cost: the message arrives before context has covered its
  weight, so it usually requires restatement.
- `deferred` --- arrives after the development that makes it
  self-evident, the reader reaching the ask already agreeing. Maximum
  weight per statement. Cost: triage readers may never reach it.
- `coda` --- deferred, plus enactment. The message restates the
  document's development in the act of asking. Highest craft cost,
  highest delivered weight.
- `frame` --- early statement with a coda return. Spends double
  recurrence deliberately. Correct for long documents where a single
  placement decays across the span, and for readers whose triage
  behavior is unknown.
- `sentence` --- the entire document is the message. Nothing precedes it
  and nothing follows. Social posts, alerts, subject lines, reference
  card headers. Placement collapses into composition.

Known full readers take `deferred` or `coda`. Unknown or triage-prone
readers take `frame`. One sentence of available attention takes
`sentence`.

`sequent` narrows this choice without overriding it. At 0.70 and above,
composition sequence belongs to the chronology and the build is no longer
the argument's to arrange, so a full reader takes `coda` and not
`deferred`: the message must restate a development the document did not
order for that purpose.

## Composition Order

Decided before drafting, not after. Placement from the triage
assessment, deference from actual standing, the recurring position
awarded to the message vocabulary. Then draft under the companion
instruments, then audit for competing recurrence and unplanned valence
movement.

## Reverse Diagnosis

- "I read the whole thing---what do you want me to do?" --->
  `placement` mismatched to triage behavior, most often `deferred` where
  `frame` was needed.
- "That felt like an order" ---> `deference` too low, or a low-deference
  ask placed early where deferral would have carried it. Attention
  shifted from receiving the message to evaluating the writer.
- "Sure, if you think so" ---> `deference` too high for what the
  situation requires, a necessary instruction reading as optional.
- "So the takeaway is..." followed by the wrong phrase ---> `single` too
  low. The recurring position went to an accidental leitmotif.
- "It's fine, but nothing stuck" ---> `single` too low, or `spread` in
  `transmission-load` too high, or both. Nothing was concentrated enough
  to retain and nothing recurred often enough to be retained anyway.
- "Should I be worried?" ---> `steady` too low. Urgency transmitted
  where gravity was meant, alarm carrying between people more readily
  than seriousness does.
- "You have made your case and I still do not know when you knew that"
  ---> not a setting on this instrument. `iuxta` in
  `transmission-vantage` is too low, and the message landed on a premise
  the reader had to date for himself.
- Silence from an audience that should have engaged ---> `steady` too
  high for a reader whose attention wanted recruiting first, which is
  obligation assessed too high. The costliest misassessment
  available, since it leaves no complaint to diagnose from.

Each corrects one document. The posture component behind it corrects
every document for that reader, and that mapping belongs to the
`transmission` skill.

## Interactions

`transmission-vantage` supplies the smooth medium whose uniformity gives
placement its contrast, and the cut that coincides with the message is
the sanctioned use of a cold opening. Where `linked` runs high, no cuts
remain to carry emphasis and `single` becomes load-bearing rather than
optional.

`transmission-load` supplies the pressure field. Where `spread` runs
high, the message holds the single sanctioned exception; where `spread`
runs low, density is the baseline, contrast is unavailable, and this
instrument works through placement and recurrence alone.

`sequent` withdraws an instrument rather than supplying one. High
`sequent` hands composition sequence to the chronology, which removes
arrangement from this instrument's inventory: `placement` resolves to
`coda` or `frame` and never `deferred`, and `single` rises 0.15 to carry
what arrangement no longer can. The substitution is the one `linked`
already triggers at 0.70, arriving by a different route. At `sequent`
0.0 the full arrangement latitude returns, and with it the capacity for
sequence alone to change what true facts appear to mean, which is why
`office` is declared by the writer rather than derived from the reader.

Artifact self-containment---the discipline that lets a document survive
separation from the conversation that produced it---is a structural
obligation rather than a delivery setting. It composes freely here and
substitutes for nothing.
