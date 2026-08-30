### LLM-Synthesized Essay
## [Curated Presentation](../../)
# [The Coinage Catalog](./)

A reader carries out a handful of phrases and forgets the rest---and which
phrases those are is decided long before the draft: by which concepts get
compressed into a form worth carrying, by how often that form returns, and
by how far it changes each time it does.

Coinage is a skill for making that decision deliberate. Name the concepts,
set the compression and the spacing, hand it to a language model with a
draft, and the vocabulary a reader leaves holding is the vocabulary you
chose.

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

    org 6a8ee578 20260826 060912 PDT Wed 06:09 AM 26 Aug 2026

---

- [Coinage](./coinage-SKILL.md) --- the instrument. Apply it when a
  document's vocabulary is part of its deliverable, when recurrence is a
  device rather than a side effect, or when an existing composition is to be
  examined for what it repeats and what that reveals
  - **Roster** --- ten application profiles, settings resolved, from the
    literary `essay` through `spec`, `prompt`, and `record`; carried inside
    the skill rather than as a separate artifact, since the profiles are what
    the invocation names

- [Model Ontology](./coinage-ontology.md) --- fixes what a coinage
  instrument is; nothing here composes prose, it says what the things that
  compose prose are

- Sources, for the reasoning the skill formalizes
  - [Compression Imperative](./compression_imperative-essay.md) --- why
    communication creates atomic forms, and what a compressed phrase does
    that its expansion cannot
  - [Doy Family Expressions](./doy_family_expressions-research.md) --- the
    research finding behind that essay's central example: a form fully
    functional in its community and absent from every corpus that should
    have caught it
  - [Rhetorical Repetition](./rhetorical_repetition-essay.md) --- recurrence
    from the syllable to the corpus, and what accumulates across a form's
    returns

A first invocation needs nothing but a roster name; the profile resolves
every setting, and `strike` is the only component worth adding on round one.
The roster doubles as a set of worked examples validating the ontology's
range, and as a guide to the configuration nearest your document. Use the
settings beside a profile, or perturb one to match a specific work.

---

**Quick reference** --- the configurable keys and the values each takes.

Settings come in two kinds. **Scalars** run `0.0` to `1.0` and are named for
the quality maximal at `1.0`, so a configuration reads without consultation.
**Denoted** settings take a value from a fixed named set. Scalars are tuned;
denoted settings are chosen.

- **document** --- purpose and extent
  - **purpose** *(denoted)* --- roster entry; resolves every other key, so a
    purpose alone is a complete invocation
  <br>`essay` literary prose, fiction and non-fiction and poetry,
  <br>`spec` standards and schemas, terms returning verbatim,
  <br>`instrument` frameworks the reader will operate downstream,
  <br>`prompt` staged model input, the request restated after the corpus,
  <br>`treatise` extended argument, the full scale stack in play,
  <br>`brief` decision documents, one leitmotif and nothing else,
  <br>`primer` teaching material, the reader leaves holding the vocabulary,
  <br>`recruit` material whose audience is reached by being passed along,
  <br>`corpus` multi-document programs under rotation,
  <br>`record` logs and indexes, coin nothing and retrieve reliably
  - **span** --- target word count, or unset to let extent float

- **mint** *(scalars)* --- what the form is, and how much of the concept it
  omits
  - **ambient** --- terms the reader already held on arrival; current in the
    subject matter, not merely current in the draft
  - **expanded** --- content stated in full predication once installed;
    nothing left for the reader's own stock to supply

- **circulate** *(scalars)* --- how the form returns, and how far it changes
  on return
  - **interval** --- wide spacing; one return per major division, the form
    expected to hold without reinforcement
  - **varied** --- every return rotates: syntactic position, modal frame,
    conceptual neighborhood, perspectival angle

- **denote** *(named values)* --- the settings chosen rather than tuned
  - **register** --- what the form trades on
  <br>`somatic` embodied trigger, felt before it is analysed,
  <br>`operational` bundled specification, a phrase-key naming a procedure,
  <br>`credential` membership boundary, decompression capacity marks the line
  - **scale** --- active unit of recurrence, stated as a band such as
    `paragraph:document`; lower scales within the band remain available
  <br>`phonetic` alliterative binding, `sentential` the figures,
  <br>`paragraph` consolidation, `document` leitmotif, `corpus` rotation
  - **reach** --- how far the form is intended to travel
  <br>`passage` expires with it, `document` coordinates it,
  <br>`corpus` crosses documents, `reader` prepared for their own use

- **nominate** *(term lists, `[this, that]`)* --- the author's lists; the
  component extended and corrected each round, before synthesis and again in
  review of it
  - **strike** --- concepts nominated for compression and circulation
  - **anchor** --- established material the struck forms attach to, carried
    across contexts of rising complexity
  - **damp** --- terms whose natural recurrence is varied away, so the
    recurring position stays with the nominated forms

Two further values are computed rather than stated, and so are not keys.
**install** is the number of occurrences a struck form needs before it can be
used at compressed cost --- three at the floor, one more for each of four
conditions. **forms** is how many candidates survive preparation. Together
they bound the vocabulary a document of a given length can carry: forms,
installation, and extent are a triple of which any two may be chosen, and the
third follows.

---

The default below is `essay`, the primary application: literary
communication across prose fiction, prose non-fiction, and poetry, where the
compressed form and the patterned return are the devices themselves rather
than aids to something else.

```
/coinage
  purpose=essay     span=
  ambient=0.35      expanded=0.30
  interval=0.50     varied=0.75
  register=somatic  scale=phonetic:corpus  reach=reader
  strike=[]         anchor=[]              damp=[]
```

The `=` are optional, and null values broaden acceptable range, vs (unset)
default. A roster name alone resolves the whole block, so `/coinage essay`
and the above are the same invocation.

An empty `strike` is legitimate and means the document circulates only
ambient vocabulary---the correct configuration wherever no vocabulary gap is
real. Everything else may be left to the roster; `strike` is the one
component worth stating on the first round and revising on every one after.

---
