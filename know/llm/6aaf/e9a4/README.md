### LLM-Synthesized Essay
## [Curated Presentation](../../)
# [The Patina Catalog](./)


Patina is an LLM skill to establish a warrant to communicate. Patina
affiliates---words, phrases, habits of construction, analogies,
allusions---so that a reader places the author inside a parlance and
receives the subject in the light the author intends. Every text sounds
like it comes from somewhere, and patina makes that a choice: the
writing reads as coming from a community of people rather than from a
machine.

*(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution.*

An introductory essay demonstrates the skill in three degrees
[natural](./patina-essay-natural.md) 1317 words,
[brief](./patina-essay-brief.md) 678 words,
and an exaggerated [vivid](./patina-essay-vivid.md) style of 1785 words.
The three carry the same argument from the same parlance; what differs
is the calibration, so reading any two together shows what a setting
does.

The [ontology](./patina-ontology.md)
is the foundational document used to develop the skill which is defined in a single file and leverages library files containing markers [words and phrases]
to affiliate or displace, within a given parlance. It also carries the
decision record, including the reversals, so a later revision can see
what was tried and why it was set aside.


- [patina-essay-brief.md](./patina-essay-brief.md) --- short form, for a
  scanning reader ([settings](./patina-essay-brief-setting.txt))
- [patina-essay-natural.md](./patina-essay-natural.md) --- the reference
  rendering ([settings](./patina-essay-natural-setting.txt))
- [patina-essay-vivid.md](./patina-essay-vivid.md) --- pressed toward
  saturation ([settings](./patina-essay-vivid-setting.txt))

- [patina-SKILL.md](./patina-SKILL.md) --- the skill entire
  - [patina-lib-commons.yml](./patina-lib-commons.yml) --- allusion
    English readers share
  - [patina-lib-synthetic.yml](./patina-lib-synthetic.yml) --- the
    machine's markers, displaced by default

- [patina-ontology.md](./patina-ontology.md) --- entities, laws,
  decision record
- [_schema.yml](./_schema.yml) --- library file template

The library files published here are seeds; a working installation adds
one per parlance, built by the harvest and discover workflows below. The
printed settings are likewise a starting point. The effective
configuration is synthesized per use and confirmed by fine tuning:
render, read the calibration report, move one key, render again.


## Quick Reference

**Invocation.** A purpose and a parlance are a complete invocation;
everything else perturbs. The purpose may be omitted where the material
shows it, and the parlance where the subject implies one.

    /patina essay parlance=[kitchen]
    /patina letter parlance=[nautical] cast=homely steep=antique
    /patina memo parlance=[unix-admin] markers=[lexical,figurative] truss=0.30
    /patina fiction parlance=[kitchen] neutral=saturated emblematic=0.90 poetic=free

Values read by position: `35`, `3.5`, `0.35`, and `7/20` are the same
setting. A region name may stand in place of a numeral, and a polar key
may take a band, `a:b`.

**Dispositions**, derived from the request and never declared: `compose`
with no draft, `revoice` with a draft, `discover` with an attached
corpus. Harvest is a request, not a disposition.

| key | 0.0 | 1.0 | regions |
|---|---|---|---|
| `neutral` | saturated with the parlance | no markers added | `saturated` `marked` `tinted` `neutral` |
| `emblematic` | operative, noticed by members | emblematic, recognized by anyone | `operative` `mixed` `emblematic` |
| `steep` | new in print | antique | `new` `longstanding` `antique` |
| `gloss` | left for the reader to decode | decoded in context | `undecoded` `contextual` `glossed` |
| `cited` | the author speaks the parlance | the parlance quoted at a distance | `inhabited` `mixed` `cited` |
| `truss` | no bridges, or minimal | heavy use of bridges | `minimal` `measured` `frequent` `abundant` |
| `poetic` | tight ground, attested allusion | invented vehicles, loose ground | `literal` `grounded` `loose` `free` |

Denoted settings: `purpose`, `cast`, `parlance`, `markers`, `displace`,
`span`. The **cast** is the light the subject is received in, and it is
fixed before any figure is chosen; no vehicle out of cast is admitted at
any setting. `poetic` tracks `truss` unless stated. Every invocation
emits a calibration report in the response body, never in the artifact,
so a revision names a key rather than describing a symptom.

## Harvest Workflow

The skill is built to be fed. It reads whatever library it is given and
never writes to one, so every entry arrives by the author's decision;
harvest is the mechanism that makes those decisions cheap.

1. **Render**, then read the report. The invented bridges are listed
   with their locations, vehicles, tenors, and casts; library entries
   used are not listed.
2. **Ask for the harvest.** The response returns library entries for
   every marker and bridge placed, each located, in the schema of
   [_schema.yml](./_schema.yml). Forms already held come back with their
   current values, for amendment or exclusion.
3. **Amend by hand.** Correct `salience` and the `steep` attestation,
   add `cast` tags and a `gloss`, set `admit` or `forbid` where a
   purpose should license or exclude the form, and delete what proved
   operative rather than emblematic.
4. **Research the evidence.** Replace intuition-tier entries with an
   `evidence` block from the English print record; Ngram development
   arrives as YAML, never as a fabricated series.
5. **File it** as one file per parlance, the file name matching
   `parlance.name`. An attached file supplements a directory file of the
   same name and replaces it entry by entry, so a session may carry
   amendments without disturbing what is installed.
6. **Re-render** the same material against the grown library. The
   report's evidence line shows the intuition count falling as the
   library takes over.

For a parlance with a body of writing behind it, the `discover`
disposition inverts the order: attach a corpus, and the skill measures
form and construction frequency against a baseline and emits candidate
entries, syntactic habits included, for the same amendment pass.
