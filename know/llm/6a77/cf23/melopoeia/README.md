# Melopoeia

Every document already sounds like something. Written without attention,
it sounds like the week it was drafted---the author's own register,
carried into a grief passage composed on a bright afternoon. The reader
receives it either way, through an organ so tactile that the eardrum
answers to pressures below the width of an atom, and answers before the
sentence has finished parsing.

Melopoeia is a skill for taking that channel out of default. Name the
moments the sound must carry, set the vowel color and the consonant grain
and the rhythm, hand it to a language model with a draft, and the reading
experience the reader has is the one you chose.

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

    org 6a93c973 20260829 231059 PDT Sat 11:10 PM 29 Aug 2026

---

## The Documents

- [Melopoeia: The Music Beneath Prose](./melopoeia-essay.md) --- the
  source essay, for the reasoning the skill formalizes: the two channels,
  the haptic ear, the eight dimensions, and what does and does not survive
  translation.

- [Model Ontology](./melopoeia-ontology.md) --- fixes what a melopoeia
  instrument is: the two scalar kinds, the parameter set, the traverse
  form, the coordination law. Nothing here composes prose; it says what
  the things that compose prose are.

- [Development Record](./melopoeia-development.md) --- naming collisions
  yielded to companion instruments, decisions taken with the alternatives
  they displaced, and optimizations deferred until the whole instrument
  set is tuned together. Read before changing a key name.

- [Melopoeia](./melopoeia-SKILL.md) --- the instrument. Apply it when
  prose must be composed for the ear as well as the mind, or when an
  existing composition is to be examined for what its sound is carrying.
  - **Roster** --- fifty-one entries in three tiers, carried inside the
    skill rather than beside it, since the roster is the first line of
    configuration and the entries are what the invocation names.

A first invocation needs nothing but a purpose name; the entry resolves
every setting. Add a `voice` when a document should sound like a known
practice, a `figure` when one passage should sound unlike the rest, and a
`perform` list when the sound has a job at a specific moment.

    /melopoeia essay
    /melopoeia fiction voice=[morrison] figure=[fracture@ch9]
    /melopoeia liturgy perform=[the entrance, the dismissal]

**Every invocation reports its calibration in the response, never in the
artifact.** The artifact carries prose; the response carries the settings
that produced it, so the next request names a setting instead of
describing a symptom.

---

## Quick Reference

### The two scalar kinds

**Intensity** --- `divergent`, `incidental`, `transparent`, `monodic`.
0.0 is scored and audible; 1.0 is incidental and transparent. Named for
the quality maximal at 1.0. Yield runs high.

**Polar** --- `dark`, `flowing`, `rough`, `sustained`, `suspended`,
`modulated`. Bipolar. **No light pole and no yield direction**: they name
*which* sound, not how much. Resolve a conflict with a traverse or a local
override, never by moving toward a pole.

Values read by position: `35`, `3.5`, `0.35`, `7/20` place a setting
identically. Tolerance is 0.10 on intensities, 0.20 on polars.

### Keys

| group | key | kind | 0.0 | 1.0 |
|---|---|---|---|---|
| document | `purpose` | roster | --- | --- |
| document | `span` | integer | --- | --- |
| document | `divergent` | intensity | sound answers to content | sound and sense run apart |
| grain | `dark` | polar | front vowels: bright, edged, forward | back vowels: deep, grave, enclosed |
| grain | `flowing` | polar | interrupted: each word a strike | continuous: voicing carried across |
| grain | `rough` | polar | euphonious: no friction | cacophonous: rough terrain |
| measure | `sustained` | polar | clipped declaratives | long-breath periods |
| measure | `suspended` | polar | loose: main clause first | periodic: completion withheld |
| measure | `modulated` | polar | uniform pulse | continuous modulation |
| carry | `incidental` | intensity | sound is a selection criterion | sound is a byproduct |
| carry | `transparent` | intensity | dense phonemic motif | no relation across sentences |
| carry | `monodic` | intensity | counterpoint | one line, unopposed |

### Denoted options

| key | options | what it sets |
|---|---|---|
| `family` | `plosive`, `fricative`, `liquid`, `nasal` | Dominant consonant family. Combine with `+`, dominant first. Independent of `flowing`. |
| `band` | `phonemic`, `lexical`, `sentential`, `paragraph`, `movement` | Active sonic unit, stated as a range. `phonemic` and `lexical` do not survive translation; the rest do. |
| `channel` | `haptic`, `mimetic`, `architectonic` | What the sound is for: a touch quality, a performance of the content, or a structural marker. |
| `ear` | `silent`, `aloud`, `memory` | Reception mode. `aloud` makes breath a hard constraint on `sustained`. |

### Lists

| key | holds |
|---|---|
| `perform` | Content events the sound must carry. Names the *event*, not the technique. |
| `mute` | Regions where the channel stands down: quotations, catalogs, apparatus. |
| `voice` | Author overlays, applied in order. Two is a blend; three is a smear. |
| `figure` | Passage overlays, sited with `@`. A sited figure is also a `perform` entry. |

### Traverse

`key=a>b@site` states a movement rather than a position. `dark=0.80>0.15@opening`
is a dawn. The polar scalars normally take this form; a color held is a
palette, a color moved is the event.

### Resolution order

`purpose` resolves everything, then `voice` overlays in order, then
`figure` overlays at their sites, then explicit keys, then the `divergent`
cap. A capped value is reported as capped, never silently moved.

---

## Roster

**Purpose** --- the base entry, resolving every key. Exactly one applies.

| | |
|---|---|
| `essay` | literary non-fiction; the primary entry |
| `fiction` | narrative prose; expect a figure per scene |
| `poetry` | the line does what prose distributes across paragraphs |
| `drama` | counterpoint as the native mode; rhythm as characterization |
| `memoir` | retrospect in the first person; warm, continuous, slow |
| `liturgy` | the voice in a room; recurrence over variance |
| `oration` | one voice to many; the periodic sentence as held attention |
| `criticism` | prose about art, staying out of its subject's way |
| `correspondence` | letters; conversational rhythm, no movement structure |
| `translation` | the structural stack only; grain settings struck out |
| `instrument` | frameworks and methodologies; sound at the junctures |
| `brief` | decision documents; the channel mostly withheld |
| `spec` | standards and schemas; precision governs |
| `record` | total abstention, named so it can be invoked |

**Voice** --- author overlays, perturbing a named subset.

| | |
|---|---|
| `hawthorne` | suspension as the sole emotional instrument |
| `shakespeare` | counterpoint; speech rhythm against metrical ground |
| `woolf` | continuous modulation; sentences that resolve and reopen |
| `morrison` | alignment at maximum; the fragmentation is the content |
| `conrad` | accumulation without suspension; ambient sibilance |
| `mccarthy` | polysyndeton; flow at the clause, hardness at the consonant |
| `robinson` | pianissimo; the quietness is the music |
| `joyce` | formal musical structure imposed on narrative |
| `hemingway` | uniformity as composed ground |
| `hopkins` | consonant engineering; substitution damages audibly |
| `thomas` | vowel surge; sequences that crest and break |
| `bulgakov` | harmonic density as world-marker |
| `whitman` | catalog and anaphora; accumulation by parallel |

**Figure** --- passage overlays, sited with `@`.

| | |
|---|---|
| vowel | `bright`, `gloom`, `dawn`, `dusk`, `monochrome` |
| texture | `percussion`, `ambience`, `laminar`, `hinge` |
| rhythm | `alternation`, `period`, `respiration`, `polysyndeton`, `fracture` |
| recurrence | `motif`, `refrain`, `clarity` |
| composite | `mimesis`, `crest`, `procession`, `hush`, `grief`, `confrontation`, `threshold` |

Full perturbations for every entry are tabled in the skill.

