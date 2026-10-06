# Transmission Configurations

### A Reference Roster

Companion appendix to *The Transmission Layer*. Twenty-one worked
configurations, grouped by the five categories the essay names. Written
for lookup rather than for reading through.

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

---

## Contents

- Reading an Entry
- Setting Reference
- Compact and High-Pressure --- entries 1 to 5
- Executive and Institutional --- entries 6 to 11
- State-Sensitive --- entries 12 to 16
- Instructional --- entries 17 and 18
- Popular --- entries 19 to 21
- The Extremal Pairs

---

## Reading an Entry

Each entry carries four parts. **Posture** names the reader. **Config**
gives the invocation line. **Specimen** shows the same underlying claim
rendered at that configuration. **Consequence** states what the reader
does differently.

Six entries run long: 1, 3, 7, 12, 19, 21. These sit at the extremes of
the space. The other fifteen sit between them and run short.

Specimens across the roster carry a common underlying claim wherever the
scenario permits: a system was reachable, nobody intended harm, the
reachability was sufficient, and something must change. Holding content
constant makes the delivery differences legible.

## Setting Reference

Direction is uniform. **0.0 is compact, mobile, forceful. 1.0 is steady,
gradual, low-pressure.** Values read by position, not scale: 35, 3.5,
0.35 are one setting.

`transmission-vantage` --- nesting, dwell, meta, attribution
(`agent` | `artifact` | `impersonal`), bridging

`transmission-load` --- peak, onset, consolidation, cadence
(`staccato` | `misura` | `legato`)

`transmission-landing` --- placement (`early` | `deferred` | `coda` |
`frame` | `sentence`), sanction, recurrence, affect

---

## Compact and High-Pressure

### 1. Expert reference card

**Posture.** Peer specialist. Fluency high, appetite high, tolerance
high. Consults rather than reads. Returns to the card repeatedly and
wants the same information found faster each time.

**Config.** `/transmission-vantage 0.15 attribution=impersonal`
`/transmission-load 0.1 cadence=staccato consolidation=0.0`
`/transmission-landing placement=sentence sanction=0.15 recurrence=0.9
affect=0.9`

**Specimen.**

> Reachability, not intent, is the enabling condition. Any agent that
> can address a resource can act on it. Deny by default; permit by
> exception; log the exceptions.

**Notes.** Every device the essay warns against is correct here. The
negated antithesis lands in four words. Attribution vanishes entirely
because provenance costs space and this reader supplies it. Consolidation
is off: terms arrive unestablished because the reader established them
years ago. Recurrence runs high for a different reason than usual, since
a card is scanned rather than read and consistent vocabulary is what
makes the scan land.

Affect at 0.9 despite maximum pressure elsewhere. Pressure and heat are
separate settings. The card is intense and completely calm.

**Consequence.** The reader finds the rule in under two seconds and
stops reading.

---

### 2. Prompt artifact for a language model

**Posture.** Machine consumer.

**Config.** `/transmission-vantage 0.1 attribution=impersonal meta=1.0`
`/transmission-load 0.0 cadence=staccato consolidation=0.0`
`/transmission-landing placement=early sanction=0.0 recurrence=1.0
affect=1.0`

**Specimen.**

> Enabling condition: reachability. Intent: not required. Rule: deny
> unless explicitly permitted. Log every exception with actor, resource,
> timestamp.

**Notes.** Sanction at mandate, since a consuming model has no standing
to negotiate. Affect flat because affect is pure token cost here.

**Consequence.** Instruction followed without interpretation drift.

---

### 3. Specification where no prior detail existed

**Posture.** Mixed and adversarial over time. Written for implementers
today and for the person in three years who must determine what was
meant. Nobody is present to answer questions.

**Config.** `/transmission-vantage 0.25 nesting=0.15 meta=0.3
attribution=impersonal dwell=0.7`
`/transmission-load peak=0.2 onset=0.1 consolidation=1.0
cadence=staccato`
`/transmission-landing placement=early sanction=0.0 recurrence=1.0
affect=1.0`

**Specimen.**

> **3.2 Reachability.** A resource is *reachable* by an agent when the
> agent can address it over any transport, with or without credentials.
> Reachability is established by network topology, not by
> authorization state. An unreachable resource is out of scope for
> sections 4 through 7.
>
> **3.3 Enabling condition.** Reachability alone establishes the
> enabling condition. Intent is not an element. A specification claiming
> conformance shall deny by default and permit by exception.

**Notes.** The one place in the compact category where consolidation
runs to maximum. Terms are defined formally, on their own line, before
any use --- because there is no author present to be asked, and every
undefined term becomes a dispute. The setting looks contradictory next
to peak 0.2 and is not: definitions are established once, at length, and
thereafter invoked at full compression.

Onset 0.1 for the opposite reason to a primer. Concepts arrive in
parallel because a specification is a lattice rather than a path, and
the reader enters at an arbitrary section.

Nesting low, meta at 0.3. Provenance and scope qualification are
load-bearing under later challenge. Attribution impersonal because the
document speaks as the standard, not as its authors.

**Consequence.** Two implementers who never meet produce compatible
systems, and a dispute three years later resolves by reading 3.2.

---

### 4. Research abstract

**Posture.** Peer specialist, deciding in fifteen seconds whether to
read the paper.

**Config.** `/transmission-vantage 0.3 attribution=impersonal`
`/transmission-load peak=0.15 onset=0.0 consolidation=0.2
cadence=misura`
`/transmission-landing placement=frame sanction=0.5 recurrence=0.7
affect=0.7`

**Specimen.**

> Reachability, rather than adversarial intent, is shown to be the
> sufficient enabling condition for lateral movement in agentic systems.
> We formalize the condition, prove sufficiency under three transport
> models, and report a topology audit of 40 deployments in which 31
> exhibited the condition without any credential compromise.

**Notes.** Onset at parallel: five concepts in three sentences, which is
the form. Frame placement compresses to almost nothing, the claim
opening and the finding closing.

**Consequence.** The specialist decides to read the paper, or not, and
either decision is correct.

---

### 5. Peer technical review

**Posture.** Peer specialist. Distributed explanation of familiar
material lands as an imposition.

**Config.** `/transmission-vantage 0.3 attribution=agent meta=0.5`
`/transmission-load peak=0.25 onset=0.2 consolidation=0.2
cadence=misura`
`/transmission-landing placement=deferred sanction=0.5 recurrence=0.4
affect=0.6`

**Specimen.**

> Section 3 treats reachability and intent as jointly necessary. The
> sufficiency argument in 3.4 does not survive that assumption --- if
> intent is necessary, the 31 uncompromised deployments fall outside the
> claim, and the audit loses its force. Either the assumption goes or
> the audit does.

**Notes.** Attribution at agent because a review is a person's judgment
and hiding it in the passive costs credibility with this reader.
Sanction at recommendation, not mandate, since a reviewer advises.

**Consequence.** The author knows exactly which paragraph to fix.

---

## Executive and Institutional

### 6. Flag-officer memo

**Posture.** Settled executive. Reads through, delegates, does not scan.

**Config.** `/transmission-vantage 0.85 attribution=artifact meta=1.0`
`/transmission-load peak=0.8 onset=0.7 consolidation=0.7
cadence=legato`
`/transmission-landing placement=coda sanction=0.3 recurrence=0.6
affect=0.9`

**Specimen.**

> The review found no evidence of malicious action at any point in the
> chain. What it found instead was that one system could address another
> without any requirement to prove it should, and that this alone was
> sufficient for the failure to occur. The condition remains present in
> eleven other pairings. Closing it requires a default-deny posture on
> internal transport, which the enterprise architecture board is
> positioned to direct.

**Notes.** The essay's origin case. Nothing detonates, nothing shifts,
and the required action arrives last, after the development that makes
it obvious.

**Consequence.** The officer directs the action without having felt
directed.

---

### 7. Compliance gate schedule

**Posture.** Fatigued reviewer, plus an auditor eighteen months later.
Two readers, opposite needs, one document.

**Config.** `/transmission-vantage 0.5 attribution=impersonal meta=0.4
dwell=0.8`
`/transmission-load peak=0.35 onset=0.3 consolidation=0.9
cadence=staccato`
`/transmission-landing placement=early sanction=0.1 recurrence=1.0
affect=1.0`

**Specimen.**

> **Gate 3 --- Transport Authorization.** Required before Gate 4.
>
> Entry criteria: topology inventory complete; every agent-to-resource
> path enumerated.
>
> Exit criteria: default-deny enforced on all enumerated paths;
> exceptions documented with owner, justification, and review date.
>
> Evidence: exception register, signed by the system owner.
>
> Slip consequence: Gate 4 does not open. Authorization to operate is
> not extended.

**Notes.** The most instructive entry in the category, because it serves
two postures that want opposite things and resolves the conflict
structurally rather than by compromise. The fatigued reviewer scans
labels; the auditor reads the same labels as a checklist eighteen months
later. Uniform structure serves both.

Recurrence at maximum, which for a schedule means every gate uses the
identical field set in the identical order. Variation here reads as
substantive difference and generates audit findings.

Sanction near mandate because the consequence clause is the document's
purpose. Affect flat: the slip consequence is severe and stated without
a single word of pressure, since the severity is in the fact.

Consolidation 0.9 despite the compact register. Every term in the
exception register must mean in month eighteen what it meant in month
one.

**Consequence.** The reviewer knows this week's obligation in ten
seconds; the auditor reconstructs the whole program from the same page.

---

### 8. Executive summary of a long report

**Posture.** Settled executive who scans. Triage behavior diverges from
the rest of the posture.

**Config.** `/transmission-vantage 0.8 attribution=artifact`
`/transmission-load peak=0.7 onset=0.6 consolidation=0.6
cadence=misura`
`/transmission-landing placement=frame sanction=0.3 recurrence=0.8
affect=0.85`

**Specimen.**

> **The finding requires a default-deny posture on internal transport.**
> The review examined 40 deployments and found that reachability alone
> was sufficient for the failure in every case, with no evidence of
> malicious action anywhere. Eleven pairings remain in the same
> condition. The full report details each. **Directing default-deny at
> the architecture board closes all eleven.**

**Notes.** Frame placement, which spends double recurrence deliberately.
Both brackets carry the same action in the same words.

**Consequence.** A reader who stops after the first sentence still has
the message.

---

### 9. Standards proposal

**Posture.** Guarded evaluator, in numbers. A committee.

**Config.** `/transmission-vantage 0.8 attribution=impersonal meta=0.6`
`/transmission-load peak=0.7 onset=0.6 consolidation=0.8
cadence=legato`
`/transmission-landing placement=deferred sanction=0.7 recurrence=0.6
affect=0.9`

**Specimen.**

> Three postures are available for internal transport. Permit-by-default
> preserves current operation and leaves the enabling condition in place.
> Permit-with-monitoring detects the condition after use. Deny-by-default
> removes it, at the cost of an exception process the operations group
> would own. The third alone addresses the condition the audit
> identified.

**Notes.** Sanction at option-framing, which persuades through ordering.
The committee chooses, and the ordering has already chosen.

**Consequence.** The committee adopts the third option and experiences
the adoption as its own.

---

### 10. Vendor negotiation letter

**Posture.** Counterparty. Attentive, interested, adversarial in
interest rather than in role.

**Config.** `/transmission-vantage 0.85 attribution=artifact meta=0.7`
`/transmission-load peak=0.75 onset=0.7 consolidation=0.6
cadence=legato`
`/transmission-landing placement=deferred sanction=0.0 recurrence=0.7
affect=0.95`

**Specimen.**

> Our review of the integration identified a condition in which your
> agent can address our resources without an authorization step. The
> contract's security exhibit at 7.3 requires default-deny on all
> integration transport. We are requesting a remediation plan within
> thirty days, as the exhibit provides.

**Notes.** Mandate register with maximum steadiness, which is force
without heat. The contractual citation carries the sanction; the prose
carries none.

**Consequence.** The vendor responds to the requirement rather than to
the tone.

---

### 11. Request directed upward without standing

**Posture.** Settled executive, senior to the writer, with no obligation
to act.

**Config.** `/transmission-vantage 0.9 attribution=artifact meta=1.0`
`/transmission-load peak=0.8 onset=0.75 consolidation=0.7
cadence=legato`
`/transmission-landing placement=deferred sanction=1.0 recurrence=0.5
affect=0.9`

**Specimen.**

> The audit turned up something that may be worth a few minutes of your
> time. Eleven system pairings can reach each other without an
> authorization step, which is how the March failure occurred, and the
> condition sits above the level where our group can address it. If it
> would be useful, I can put the eleven on one page.

**Notes.** Sanction at invitation, the furthest soft position. The ask is
for attention, not for action, and the action becomes the reader's idea.

**Consequence.** The senior reader asks for the page.

---

## State-Sensitive

### 12. Bad news to a person it affects

**Posture.** Attentive, personally exposed, and about to be in distress.
Arrival state changes during reading, which no other entry in the roster
faces.

**Config.** `/transmission-vantage 0.95 attribution=artifact meta=1.0
dwell=1.0 bridging=1.0`
`/transmission-load peak=0.9 onset=0.9 consolidation=0.8
cadence=legato`
`/transmission-landing placement=early sanction=0.4 recurrence=0.3
affect=1.0`

**Specimen.**

> The board decided this morning not to continue the program past
> September. Your position ends with it.
>
> The decision was about the program's funding line and not about your
> work, which the review described as the strongest in the group. You
> stay on payroll through the end of September, benefits continue
> through December, and the transition group has been asked to work with
> you starting whenever you are ready --- there is no schedule you need
> to meet this week.
>
> I would rather tell you the rest of what I know in person. I am free
> the rest of today.

**Notes.** The only entry that pairs `early` placement with maximum
affect stability, and the pairing is deliberate. Withholding the news
while building toward it makes a reader search the paragraphs for what
is coming, and the search is worse than the news. State it, then stay
still.

Everything after the first line runs at maximum steadiness. One
viewpoint, no compression, nothing that asks the reader to assemble
anything, because assembly capacity is gone.

Recurrence at 0.3, which is unusually low. A phrase repeated to someone
in distress reads as a script.

Sanction 0.4, softer than the situation's authority would allow. The
writer holds every card and shows none.

**Consequence.** The reader hears the news once, retains the practical
facts, and can come back later for the rest.

---

### 13. Incident notification, hour one

**Posture.** Operational staff. Attention immediate, action required
now, uncertainty high.

**Config.** `/transmission-vantage 0.6 attribution=impersonal meta=1.0`
`/transmission-load peak=0.3 onset=0.4 consolidation=0.5
cadence=staccato`
`/transmission-landing placement=early sanction=0.0 recurrence=0.8
affect=0.0`

**Specimen.**

> **Active incident. Internal transport compromise suspected.**
>
> Disable agent-to-agent transport on segments 4, 7, and 9 now. Do not
> wait for confirmation.
>
> Scope unknown. Cause unknown. Next update at 1400.

**Notes.** The one entry where affect at the dramatic pole is correct.
Urgency is the message, and steadiness here would read as a failure to
understand the situation.

**Consequence.** Segments are down in four minutes.

---

### 14. All-hands change announcement

**Posture.** Mixed. Everyone from the settled executive to the reader
who will scan the subject line and delete.

**Config.** `/transmission-vantage 0.8 attribution=artifact meta=0.9`
`/transmission-load peak=0.75 onset=0.7 consolidation=0.7
cadence=misura`
`/transmission-landing placement=frame sanction=0.3 recurrence=0.8
affect=0.6`

**Specimen.**

> **Starting 1 October, internal systems will require explicit
> authorization to reach each other.** Most of you will notice nothing.
> Teams running scheduled jobs across segments will need an exception
> filed by 15 September, and the form takes about five minutes. **The
> deadline for exceptions is 15 September.**

**Notes.** Frame placement for unknown triage behavior. Affect at 0.6
permits the mild reassurance that keeps a mixed audience from inventing
alarm.

**Consequence.** The affected minority acts; the unaffected majority
stops reading after sentence two, correctly.

---

### 15. Audit response

**Posture.** Auditor. Adversarial by role, predictable, present to
challenge.

**Config.** `/transmission-vantage 0.35 nesting=0.2 meta=0.0
attribution=agent`
`/transmission-load peak=0.5 onset=0.5 consolidation=0.8
cadence=misura`
`/transmission-landing placement=early sanction=0.4 recurrence=0.9
affect=0.9`

**Specimen.**

> Finding 3 is accepted. The system owner (J. Reyes, ISSO) confirms that
> default-deny was not enforced on segments 4, 7, and 9 as of the audit
> date, per the topology inventory dated 12 March, which the audit team
> received on 14 March. Remediation was directed by the architecture
> board on 2 April (minutes attached, item 7) and is scheduled for
> completion by 30 June. Evidence of completion will be the exception
> register, signed.

**Notes.** Meta at 0.0 and nesting at 0.2, both the opposite of every
executive entry. Every claim carries its provenance because every claim
will be tested. Attribution at agent because accountability is the
subject.

**Consequence.** The finding closes without a follow-up request.

---

### 16. Finding that counsel may read

**Posture.** Unknown future adversary. Written today, read under
subpoena.

**Config.** `/transmission-vantage 0.3 nesting=0.1 meta=0.0
attribution=agent dwell=0.7`
`/transmission-load peak=0.5 onset=0.5 consolidation=1.0
cadence=misura`
`/transmission-landing placement=early sanction=0.6 recurrence=0.9
affect=1.0`

**Specimen.**

> Based on the topology inventory dated 12 March and on interviews
> conducted 14 to 19 March, the review team concluded that segments 4,
> 7, and 9 permitted agent-to-agent transport without authorization. The
> team did not examine intent and makes no finding as to it. This
> conclusion is limited to the three segments named and to the period
> covered by the inventory.

**Notes.** Every hedge preserved, scope stated explicitly, sanction
raised toward recommendation because a finding that overstates its
authority becomes a liability. The one entry where the essay's smoothing
advice is set aside entirely.

**Consequence.** The document survives hostile reading with its claims
intact.

---

## Instructional

### 17. Onboarding primer

**Posture.** Learner. Consented to work, acquiring vocabulary.

**Config.** `/transmission-vantage 0.9 attribution=artifact meta=1.0
dwell=1.0`
`/transmission-load peak=1.0 onset=1.0 consolidation=1.0
cadence=legato`
`/transmission-landing placement=coda sanction=0.5 recurrence=0.7
affect=0.7`

**Specimen.**

> When one system can send a message to another and the second system
> accepts it, we say the second is *reachable* from the first.
> Reachability is a fact about the network, and it holds whether or not
> the sender has permission to be there. A resource can be reachable and
> still be properly protected; it can also be reachable and protected by
> nothing but the assumption that no one will try.

**Notes.** Maximum on every gradual setting. One concept, defined, held
still, and turned over twice before anything is built on it.

**Consequence.** The term is available for compressed use in every later
chapter.

---

### 18. Teaching essay that must also persuade

**Posture.** Interested professional. Willing to learn, deciding whether
to change practice.

**Config.** `/transmission-vantage 0.85 attribution=artifact meta=1.0`
`/transmission-load peak=0.75 onset=0.5 consolidation=0.7
cadence=legato`
`/transmission-landing placement=coda sanction=0.7 recurrence=0.5
affect=0.35`

**Specimen.**

> Which leaves the question the audit could not answer at the outset and
> can now: whether a network should be arranged so that permission is
> the exception, or so that permission is the rule. Every deployment
> examined had answered it already, without noticing the question had
> been asked.

**Notes.** The configuration of the essay this roster accompanies. Coda
placement, option-framing sanction, affect permitting enough movement to
motivate practice change.

**Consequence.** The reader changes something on Monday.

---

## Popular

### 19. Explainer for the interested non-specialist

**Posture.** Casual reader. Present voluntarily, interested in novelty,
willing to be delighted, unwilling to work. Leaves quietly.

**Config.** `/transmission-vantage 0.35 dwell=0.3 attribution=agent
meta=1.0 bridging=0.5`
`/transmission-load peak=0.6 onset=0.55 consolidation=0.4
cadence=misura`
`/transmission-landing placement=deferred sanction=0.9 recurrence=0.5
affect=0.15`

**Specimen.**

> Here is the thing nobody expects about the biggest computer breaches:
> most of them do not involve anyone breaking in.
>
> Picture an office building where every internal door is unlocked. Not
> propped open, not broken --- just unlocked, because everyone inside
> works here and locking them seemed like a nuisance. Now picture one
> person walking in the front door on a visitor badge.
>
> They did not pick a lock. They did not need to. The building was
> arranged so that being inside was the whole permission system, and
> once you are inside, you are inside everywhere.
>
> That is roughly what happened at three of the companies you read about
> last year.

**Notes.** Nearly every setting inverts from entry 1, and the two
entries share a category with nothing else in the roster.

Viewpoint mobile at 0.35, dwell 0.3. The specimen moves from
generalization to image to reader-address in four paragraphs, and the
movement is the entertainment. In an executive memo the same motion
would be a defect.

Affect 0.15, close to the dramatic pole, because attention must be
recruited before it can be spent. The reader owes nothing and leaves
without complaint.

Sanction 0.9, nearly invitation. Nothing is asked. A casual reader who
detects an ask departs.

Peak 0.6 and consolidation 0.4, both mid-range. The analogy carries the
technical content, and analogies want room. Compression here would
produce accuracy the reader cannot use.

Deferred placement with no imperative at the end --- the payload is the
understanding itself, and it arrives when the image completes.

**Consequence.** The reader finishes, tells someone about it at dinner,
and could not reproduce a single technical term.

---

### 20. Newsletter or blog post

**Posture.** Casual reader with a standing subscription. Some goodwill,
low patience.

**Config.** `/transmission-vantage 0.45 attribution=agent meta=1.0`
`/transmission-load peak=0.5 onset=0.45 consolidation=0.4
cadence=misura`
`/transmission-landing placement=early sanction=0.85 recurrence=0.6
affect=0.25`

**Specimen.**

> Most breaches are not break-ins. They are open doors that everyone
> stopped noticing. I spent a week with the numbers and the pattern is
> almost boring, which is what makes it interesting.

**Notes.** Early placement because the subscriber decides in the first
line whether this week's issue gets read.

**Consequence.** The reader continues past the fold.

---

### 21. Social post

**Posture.** Scroller. One sentence of attention, granted or withdrawn
inside it. No triage stage, because there is nothing yet to triage.

**Config.** `/transmission-vantage 0.2 attribution=agent`
`/transmission-load peak=0.05 onset=0.1 consolidation=0.0
cadence=staccato`
`/transmission-landing placement=sentence sanction=1.0 recurrence=0.0
affect=0.0`

**Specimen.**

> Most break-ins are not break-ins. The door was open the whole time.

**Notes.** The roster's second maximum-pressure entry, and its
relationship to entry 1 is the most instructive pairing here.

Placement collapses into composition. The message and the document are
one object, so there is no position to choose.

Affect at the dramatic pole, where the reference card sits at 0.9. This
is the single setting that most separates the two compact-pole entries.
The card is intense and calm; the post is intense and hot.

Recurrence at 0.0, meaningless in a two-sentence document, and included
to show that some settings have no purchase at some scales.

Consolidation at 0.0 for a reason opposite to the card's. The card's
reader holds the vocabulary already; this reader needs no vocabulary at
all, because nothing technical survives.

Sanction at invitation, which looks wrong next to maximum pressure and
is not. Pressure recruits attention. An ask would spend attention that
has not yet been granted.

**Consequence.** The reader stops scrolling. Nothing further is asked of
them, and nothing further would have been granted.

---

## The Extremal Pairs

Two pairings carry more instruction than any single entry.

**Entry 1 and entry 21** both sit at the compact pole of load, and share
no other setting in the roster. The reference card runs calm, impersonal,
and vocabulary-dense; the social post runs hot, personal, and stripped of
vocabulary entirely. Nobody would call them the same kind of good
writing. One property, set to the same place, for opposite reasons.

**Entry 12 and entry 7** sit at opposite ends of nearly every setting and
come from the same apparatus. The bad-news message holds one viewpoint at
maximum steadiness and rations repetition to avoid sounding scripted; the
gate schedule fragments into labeled fields and repeats its structure
without variation because variation would generate findings. Neither
configuration would survive five minutes in the other's context.

Between these four positions lies the whole space the roster covers.

---

*Companion document:* **The Transmission Layer --- For the Reader Already
Paying Attention**
