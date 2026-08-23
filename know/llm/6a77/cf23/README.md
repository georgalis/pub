# [LLM-Synthesized Essay](https://pub.iuxta.com/know/llm/)
## [Curated Presentation](../../)
## [The Transmission Layer Catalog](./)

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

Two documents can say the exact same thing and land differently on the same
reader---because content is one thing to shape, and how it reaches the reader
is another: the vocabulary it draws on, the weight it carries at the close,
and the viewpoint it holds through the middle.

The Transmission Layer is a set of skills for making delivery deliberate.
Describe the reader, name the configuration, hand it to a language model with
a draft, and synthesis delivers the same content with different reception.

---

The [Transmission Layer essay](./transmission_layer-essay.md.html) is a good
place to start. A quick read is enough to begin experimenting with the skills
and configurations, and to try re-voicing an existing composition.

- [Transmission](./transmission-SKILL.md.html) --- when delivery should be set
  deliberately rather than by instinct, or when the same content needs to reach
  a different audience than it was written for
  - [Load](./transmission-load-SKILL.md.html) --- for smooth development under
    fatigue or unfamiliarity, or for compact expert reference, specification,
    and prompt artifacts where compression is the deliverable
  - [Land](./transmission-land-SKILL.md.html) --- when a message must land at
    a chosen weight on a chosen reader
  - [Vantage](./transmission-vantage-SKILL.md.html) --- viewpoint persistence,
    sentence contiguity, perspectival layering, unrequested justification, and
    attribution mode

- [Model Ontology](./transmission_layer-ontology.md.html) ---
  fixes what a transmission instrument is; nothing here composes prose, it
  says what the things that compose prose are
  - [Roster Generator](./transmission_layer-roster-gen.py) --- Python
    source; generates the roster grid from the transform, an ontology validation matrix
  - [Roster](./transmission_layer-roster.md.html) --- thirty-six sample
    audience configurations across the professional range, from six reader
    posture components through three instruments; a foundation for precision
    audience calibration

The roster is a selection of worked examples, settings resolved
for various audiences, and validating the ontology range accessibility.
Also, a guide for finding a configuration nearest your reader.
Use the settings beside a profile, or craft settings to match
a specific individual or demographic.

---

**Quick reference** --- the components and what they govern.

- **document** --- purpose, situational context
  - **office** --- reader disposition
  <br>`construct` facts are inventory for what to build next, <br>`judicial` evidence about decisions already taken
  - **priority** --- document length scheme
  <br>`content` length floats, detail is preserved, <br>`balance` shortfall is distributed, <br>`extent` word span holds, content is cut
  - **span** --- target word count, if known

- **posture** --- six things that are true of the reader right now
  - **fluency** --- vocabulary and conceptual holdings in this domain
  - **stamina** --- assembly rate available now: fatigue, time pressure,
    position in the day
  - **appetite** --- desire for compression, as against capacity for it
  - **scrutiny** --- how far the reader is evaluating the writer alongside the
    content
  - **oblige** --- how far the reader is obliged to read at all
  - **triage** --- `full`, `scan`, `decide`, `sentence` --- what the reader
    physically does with the document

- **load** --- cost of the reader's understanding; the pace and weight of what
  arrives
  - **spread** --- contrasts distributed across a span rather than packed into
    a clause
  - **sparse** --- one new load-bearing concept per section; subsequent
    material develops it before another opens
  - **plain** --- plain equivalents substituted wherever one exists at the same
    register
  - **ground** --- foundation laid before the document depends on a
    compressed form
  - **cadence** --- sentence rhythm: `staccato`, `misura`, `legato`

- **land** --- what the reader carries out; where emphasis falls and how hard
  the ask arrives
  - **steady** --- flat; gravity carried by content and placement, not tonal
    signaling
  - **invite** --- invitation; ideas offered to mature as the reader's own
  - **single** --- only the message recurs; one memorable phrase, chosen
    beforehand
  - **place** --- where the message sits: `sentence`, `frame`, `coda`,
    `defer`, `early`

- **vantage** --- cost of knowing where a statement stands; who speaks, from
  what position, as of when
  - **settled** --- one viewpoint per section; shifts only at announced
    structural boundaries
  - **linked** --- every sentence opens on ground the previous one prepared
  - **flat** --- one perspectival layer; framing collapsed into direct
    predication
  - **bare** --- no unrequested justification; sources identified by function,
    never defended
  - **iuxta** --- every claim carries the knowledge state it belonged to; an
    unestablished moment is declared rather than supplied
  - **sequent** --- composition tracks chronology throughout; departures
    announced
  - **attribute** --- where claims anchor: `agent`, `artifact`, `impersonal`

---

The default below is the settled-professional starting point: a capable
reader, moderate stamina, settled scrutiny, reading it through.

```
/transmission
  office=construct  cadence=misura  priority=content  span=
  fluency=0.60  stamina=0.50  appetite=0.40  scrutiny=0.15
  oblige=0.90   triage=full
```

The `=` are optional, and null values broaden acceptable range, vs (unset) default.


---
