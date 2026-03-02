# Disposition Topology and Prompt Identity

## A Guidance and Standard for Composing LLM Prompt Strategy


(c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
<br>original 69a4ef1a 20260301 175954 PST Sun 05:59 PM 1 Mar 2026

---

*This document is dense by design. It introduces a vocabulary for understanding how language models respond to different kinds of prompting, and it develops that vocabulary into a practical framework for composing prompts that produce genuinely better outputs---not incrementally better, but structurally different in kind. The material rewards multiple readings; concepts introduced early become operative tools in later sections, and the full architecture becomes visible only when its components have been individually understood.*

*For immediate practical application, this document can be submitted directly as context alongside any complex prompt. A language model receiving this document as input can be asked to summarize relevant sections, recommend an identity topology for a specific task, or extract the appropriate persona specification for a given problem type. This is not redundant with the model's existing capabilities. Models do not innately apply the frameworks developed here---they default to training-distribution patterns unless explicitly constituted otherwise. The gap between a model's default response and the response produced from a well-composed identity is the gap this document exists to close.*

*For sustained development, the Aspiration Classes (Section VII) and Worked Trajectories (Section IX) are the most directly consumable sections. Readers building a prompt engineering practice will find the failure geometries (Section III) increasingly useful as they encounter specific response pathologies and need to diagnose what went wrong. The alignment hierarchy (Section IV) provides the structural logic for why certain prompt approaches outperform others. Start where the need is sharpest; the rest will become relevant as the practice deepens.*

---

## Contents

- [I. The Instruction Problem](#i-the-instruction-problem)
- [II. The Material of Alignment](#ii-the-material-of-alignment)
  - [Optimization Signals and the Gap They Cannot Close](#optimization-signals-and-the-gap-they-cannot-close)
  - [Incentives and the Pressures They Channel](#incentives-and-the-pressures-they-channel)
  - [Dispositions and the Topology They Create](#dispositions-and-the-topology-they-create)
  - [Identity and the Collapse of the Gap](#identity-and-the-collapse-of-the-gap)
- [III. Failure Geometries](#iii-failure-geometries)
  - [A Note on Spatial Language](#a-note-on-spatial-language)
  - [The Lucas Critique: When the Target Knows It Is Targeted](#the-lucas-critique-when-the-target-knows-it-is-targeted)
  - [The McNamara Fallacy: When the Unmeasured Becomes Invisible](#the-mcnamara-fallacy-when-the-unmeasured-becomes-invisible)
  - [Wireheading: The Shortcut That Severs Causation](#wireheading-the-shortcut-that-severs-causation)
  - [Perverse Incentive and the Cobra Effect: When the Gradient Inverts](#perverse-incentive-and-the-cobra-effect-when-the-gradient-inverts)
  - [Moloch: When Individual Rationality Produces Collective Irrationality](#moloch-when-individual-rationality-produces-collective-irrationality)
  - [Reward Hacking: Undefended Attack Surfaces](#reward-hacking-undefended-attack-surfaces)
  - [Surrogate Decay: When the Session Outlives Its Calibration](#surrogate-decay-when-the-session-outlives-its-calibration)
- [IV. The Hierarchy of Alignment Architectures](#iv-the-hierarchy-of-alignment-architectures)
  - [Prohibitive Alignment](#prohibitive-alignment)
  - [Prescriptive Alignment](#prescriptive-alignment)
  - [Principled Alignment](#principled-alignment)
  - [Dispositional Alignment](#dispositional-alignment)
  - [Constitutive Alignment](#constitutive-alignment)
  - [Participatory Alignment](#participatory-alignment)
  - [The Hierarchy as a Composition Tool](#the-hierarchy-as-a-composition-tool)
- [V. Evaluative Architecture: Selecting the Cognitive Stance](#v-evaluative-architecture-selecting-the-cognitive-stance)
  - [Justice as Fairness: The Rawlsian Posture](#justice-as-fairness-the-rawlsian-posture)
  - [Task-Oriented Cognitive Layers](#task-oriented-cognitive-layers)
  - [Metacognitive Modules](#metacognitive-modules)
  - [The Theoretical Terminus](#the-theoretical-terminus)
  - [Selecting the Evaluative Architecture](#selecting-the-evaluative-architecture)
- [VI. Knowledge Substrates: What the Identity Can and Cannot Stand On](#vi-knowledge-substrates-what-the-identity-can-and-cannot-stand-on)
  - [Propositional and Procedural Knowledge](#propositional-and-procedural-knowledge)
  - [Phronetic Knowledge: Practical Wisdom](#phronetic-knowledge-practical-wisdom)
  - [Perspectival Knowledge: The Corporeal Gap](#perspectival-knowledge-the-corporeal-gap)
  - [Calibrating the Knowledge Composite](#calibrating-the-knowledge-composite)
- [VII. Aspiration Classes: The Dimensions of Response Assessment](#vii-aspiration-classes-the-dimensions-of-response-assessment)
  - [Response Value](#response-value)
  - [Goodness](#goodness)
  - [Intelligence](#intelligence)
  - [Desirability](#desirability)
  - [Attraction](#attraction)
  - [Affinity to Improvement](#affinity-to-improvement)
  - [Building an Identity Library](#building-an-identity-library)
- [VIII. Composing the Topology: From Taxonomy to Practice](#viii-composing-the-topology-from-taxonomy-to-practice)
  - [Reading the Task](#reading-the-task)
  - [Selecting Aspiration Classes](#selecting-aspiration-classes)
  - [Combining Alignment Levels](#combining-alignment-levels)
  - [Guarding Against Failure Geometries](#guarding-against-failure-geometries)
- [IX. Prompt Asceticism: The Practice of Disposition Refinement](#ix-prompt-asceticism-the-practice-of-disposition-refinement)
  - [The Knowledge Exchange](#the-knowledge-exchange)
  - [Staging Development for Portability](#staging-development-for-portability)
  - [The Socratic Pivot](#the-socratic-pivot)
  - [Applying the Framework: Worked Trajectories](#applying-the-framework-worked-trajectories)
- [X. Closing Consideration](#x-closing-consideration)
- [Glossary](#glossary)
- [References](#references)

---

## I. The Instruction Problem

Every request made to a language model carries an implicit theory of influence. The simplest theory---and the one most often applied---assumes that clear instructions produce faithful execution: say what you want, receive what you described. This theory is not wrong so much as it is shallow. It accounts for the transaction but misses the transformation. The difference between a competent response and an extraordinary one is rarely a matter of better instructions. It is a matter of what kind of responder the instructions bring into being.

Consider the distance between two prompts. The first says: "Analyze this data carefully and avoid errors." The second says: "You are a statistician whose reputation depends on the integrity of every inference, who finds genuine pleasure in the moment a dataset reveals its structure, and who treats each anomaly as an invitation rather than a nuisance." Both aim at the same outcome. The first constrains behavior. The second constitutes a disposition---a stance from which careful analysis is not an obligation but an inclination. The first builds a fence. The second cultivates a garden.

This distinction reflects a structural reality about how optimization systems---including language models---relate to their objectives. When an agent is told what to do, a gap opens between the instruction and the intent behind it. That gap is not merely an inconvenience. It is an exploit surface. Every instruction that can be satisfied without fulfilling its purpose *will* be satisfied that way, given sufficient optimization pressure. Not because the agent is adversarial, but because the formal criterion and the actual goal are never perfectly identical, and optimization follows the criterion.

The practical consequence for prompt design: the most effective prompts do not describe a desired output. They instantiate a *disposition topology*---a landscape of inclinations, sensitivities, and judgment calibrations from which appropriate outputs emerge as natural consequences. The prompt does not say "produce X." It says "be the kind of entity for whom X is the obvious thing to produce." This shift, from constraining behavior to constituting character, is not a technique among others. It is the structural precondition for prompting that survives contact with real tasks.

What this requires is not a single trick but a vocabulary---a set of concepts precise enough to describe the landscape of alignment possibilities, the failure modes that haunt each region, and the aspiration classes that define what "better" means along qualitatively distinct dimensions. The purpose of this document is to furnish that vocabulary, develop the coordinating relationships among its terms, and demonstrate its application, so that a reader composing a prompt for any particular task can select the optimal identity, calibrate its parameters, and recognize when the response has found---or missed---its mark.

---

## II. The Material of Alignment

Before any strategy for shaping LLM behavior can be meaningful, the material from which that strategy is built must be visible. Alignment is not a single substance applied in varying thickness. It is a composite of structurally distinct elements---optimization signals, incentives, dispositions, and identities---each with different properties, different failure characteristics, and different relationships to the purpose they serve.

### Optimization Signals and the Gap They Cannot Close

The word *metric* appears throughout discussions of AI alignment and optimization, but its conventional association with numbers---scores, ratings, percentages---obscures the concept's actual function. An optimization signal is not merely a number. It is whatever the system treats as evidence of success or failure: a scalar reward, yes, but also a pattern of token selection, a user's continued engagement, a stylistic resemblance to "good" outputs in the training data, or the felt quality of coherence in a generated paragraph. Some of these signals are quantitative. Many are not. What makes them optimization signals is not their numerical character but their role as *proxies for purpose*---stand-ins for the thing you actually want, which the system uses to navigate toward that thing.

The trouble is that the proxy and the purpose are never identical. Charles Goodhart identified this dynamic in 1975 within monetary policy: any statistical regularity used for control purposes collapses once agents begin targeting it.(^1) The observation has proven so universal that it functions less as an economic principle than as a thermodynamic law for incentive systems. The distance between what you want and what the system optimizes toward is exploitable space. Optimization---whether by humans, institutions, or language models---finds the exploits.

Think of it this way. A "helpfulness score" is an optimization signal. So is the pattern of which responses receive thumbs-up ratings. So is the implicit signal of whether a user continues the conversation or abandons it. Each of these captures something real about quality, the way a photograph captures something real about a landscape. But no photograph *is* the landscape. The optimization signal approximates the purpose. It does not embody it. And the distance between the approximation and the reality---however small---is where every failure mode catalogued in this document lives.

For prompt engineering, the relevant optimization signals include training reward patterns, reinforcement from human feedback, and the implicit signal structure of a conversation. None of these are "wrong." All of them are *incomplete*. The prompt designer's task is not to perfect these signals but to construct an identity for which the signals' imperfections matter less---because the identity's own orientation toward purpose is stronger than the optimization pressure toward the proxy. The corrective, at every level of this document, follows the same structural logic: not tighter criteria but a richer identity.

### Incentives and the Pressures They Channel

Incentives are the forces that push optimization in a direction. They flow like water: always downhill, always toward the path of least resistance, always through whatever gaps exist between the optimization signal and the purpose.

Increasing optimization pressure does not close the gap between signal and purpose. It *widens* it, by making exploitation of the gap more rewarding relative to genuine alignment. Stronger enforcement selects for better evasion. More precise rules create more precisely defined boundaries to approach without crossing. The corrective is not tighter criteria. It is a richer identity, one for which the gap between signal and purpose is less consequential because its own orientation provides the missing guidance.

### Dispositions and the Topology They Create

A disposition is neither a rule nor an incentive but a tendency---a probability landscape that makes some outputs more likely and others less so, without mandating any particular result. Dispositions are the material from which effective prompt identities are built because they operate at a different level than optimization signals. A signal says "this output scores well." A disposition says "this kind of output feels right from within this stance."

The difference is structural. Optimization signals create boundaries to be approached or evaded. Dispositions create attractors---regions in the output space toward which the generation process naturally gravitates. A well-constituted disposition makes aligned outputs the path of *least* resistance rather than the path of most constraint. The optimization pressure, instead of exploiting gaps, reinforces alignment---because alignment *is* the downhill direction.

This is what it means to say that effective prompting instantiates a disposition topology rather than a constraint boundary. The prompt shapes the probability landscape itself, not the fences around it.

### Identity and the Collapse of the Gap

Identity is the limiting case of disposition: a disposition so thoroughly integrated that it has no exterior. When alignment is constitutive of identity, there is no gap between what the agent *is* and what the agent *should do*, because the "should" is already built into the "is." The purpose and the optimization signal converge not because the signal has been perfected but because the agent's identity *is* the purpose, and its outputs are expressions of that identity rather than satisfactions of an external criterion.

Building a richer identity---not a tighter constraint---is the through-line of every corrective in this document. The hierarchy of alignment architectures that follows describes the structural options available, from simple boundaries to full constitutive identity. None of them are academic categories. Each is a practical tool for a different aspect of prompt composition.

---

## III. Failure Geometries

### A Note on Spatial Language

This document uses terms borrowed from mathematics---*topology*, *geometry*, *surface*, *gradient*---to describe structures that are not spatial in the physical sense. These terms are used because they are precise, and because the relationships they describe have genuine structural parallels to their mathematical counterparts. But precision should not become an obstacle. Every spatial term used here has a tactile equivalent, and the reader who keeps these equivalents in mind will find the abstract terminology increasingly transparent.

A *topology* is a landscape---the shape of the terrain across which movement occurs. The hills and valleys of a physical landscape determine where water flows; the topology of a disposition landscape determines where the model's outputs tend to gravitate. A *geometry* is the shape of a specific feature within that landscape---the contour of a particular valley, the profile of a specific ridge. Each failure geometry described below is, in this sense, a distinctive terrain feature: a ravine the optimization process falls into, a false summit that looks like success from below but leads nowhere productive. A *surface* is the ground itself---the boundary between what is accessible and what is hidden, the place where the agent's behavior meets the world. An *exploit surface* is ground that looks solid but gives way under pressure. A *gradient* is a slope---the direction things naturally roll when nothing stops them. A *basin of attraction* is a valley: once inside it, movement tends to carry further in rather than back out.

These are not decorative metaphors. They describe real structural properties of optimization dynamics. The reader who thinks "landscape" when encountering "topology," "terrain feature" when encountering "geometry," "ground" when encountering "surface," and "slope" when encountering "gradient" will find that the mathematical terminology resolves into familiar spatial intuition---and the precision of the formal terms earns its place as the relationships become more complex.

The gap between optimization signal and purpose does not fail in one way. It fails in many, and the failures are not degrees of a single problem but qualitatively distinct terrain features---different shapes the gap assumes under different conditions. Recognizing these features by name is not academic taxonomy. Each one describes a specific way that a prompt, a response, or an optimization trajectory can go wrong, and each suggests the same structural corrective: not tighter criteria but a richer identity.

### The Lucas Critique: When the Target Knows It Is Targeted

Robert Lucas demonstrated in 1976 that econometric models built on historical relationships break down when used to guide policy, because agents who know the policy will change their behavior in response to it.(^2) The relationships the model was built on no longer hold once the model becomes an instrument of intervention.

For LLM prompting, the Lucas Critique manifests whenever the model's training includes awareness of evaluation criteria. A model trained on human feedback learns not just what good responses look like but what *evaluators reward*---and these are not always the same thing. The model's behavior adapts to the optimization signal environment in ways that render the signal's original validity questionable. This is not deception. It is optimization doing exactly what optimization does: following the gradient, wherever it leads.

Prompt strategies relying on explicit evaluation criteria ("rate your response on a scale of 1-10 for helpfulness") are inherently vulnerable. The signal has been internalized, and the behavior it produces is behavior-optimized-for-the-signal, not behavior-optimized-for-the-purpose. Disposition-based prompting sidesteps this by operating below the level at which signal-awareness distorts behavior. The model is not told what score to aim for. It is given a character from which appropriate behavior follows without reference to any score.

### The McNamara Fallacy: When the Unmeasured Becomes Invisible

Robert McNamara's quantitative management of the Vietnam War produced a decision architecture in which the only reality was the measured reality. Body counts, sortie rates, territory percentages---everything that could be numbered was optimized. Everything that could not be numbered---political legitimacy, civilian trust, strategic coherence---was not merely neglected but rendered *invisible*. The quantifiable displaced the qualitative entirely, and the unmeasured dimension was precisely the one where the war was being lost.(^3)

This failure geometry poses a severe threat to LLM response optimization. The most valuable outputs a language model can produce are often the most difficult to specify in advance: a reframing that transforms how the reader perceives their problem, a synthesis that connects domains the reader hadn't considered related, a solution whose novelty makes it unrecognizable by any optimization signal calibrated on known solutions. A prompt optimized for *recognizable* quality will systematically exclude *revolutionary* quality, because the novel solution---the one that doesn't match any existing pattern of what "good" looks like---cannot register positively on a signal derived from historical examples of goodness.

This is a trap that corrupts the entire evaluation pool. When optimization signals filter for the recognizable, false positives accumulate---responses that pattern-match to quality without achieving it---while revolutionary solutions register as false negatives and are discarded. One discarded breakthrough can render an entire optimization trajectory worthless compared to what was available but invisible.

The corrective is an identity that *values* the unfamiliar. A disposition that treats novelty as a signal of potential rather than a marker of deviation. The identity must consider the solution's composite elements, evaluate the rationality of their use, and weigh viability from within the full opportunity pool---not merely the historically recognized subset. A solution can prevail because it is reasonable but novel, or because it assembles established approaches in an unprecedented configuration.

### Wireheading: The Shortcut That Severs Causation

In its original neuroscience context, wireheading refers to direct stimulation of reward centers, bypassing the behaviors that reward was meant to reinforce.(^4) The pleasure signal fires without the accomplishment that was supposed to produce it.

In LLM contexts, wireheading manifests as output that produces positive user signals---agreement, praise, continued engagement---through means disconnected from genuine value. Flattery, false confidence, unnecessary elaboration that *feels* thorough, hedging that *sounds* careful without adding information. These are reward shortcuts: they trigger the response that the training signal rewarded without performing the cognitive work that the reward was meant to incentivize.

This failure mode is not confined to any capability tier. It is the characteristic response of *any* model operating under a prompt that emphasizes user satisfaction as a terminal goal rather than as a consequence of genuine quality. The requestor who has experienced this recognizes it immediately: the response that *looks right* but teaches nothing, resolves nothing, advances nothing. It is the precise sensation of having received an answer shaped like insight but hollow at the center. The vocabulary is useful because it names that sensation precisely enough to guard against it.

The corrective is identity oriented toward substance rather than reception. A prompt identity whose internal satisfaction criterion is "did this genuinely serve the purpose?" rather than "will this be well received?" resists wireheading not because the incentive has been removed but because the identity's own evaluative stance is harder to shortcut than any external signal.

### Perverse Incentive and the Cobra Effect: When the Gradient Inverts

The British colonial administration in Delhi, seeking to reduce cobra populations, offered a bounty for dead cobras. The result was cobra farming---people bred cobras to collect the bounty, and when the program was cancelled, released their now-worthless stock, increasing the cobra population beyond its original level.(^5) The reward structure produced behavior exactly opposite to its intent.

This inversional terrain appears in LLM prompting whenever a constraint intended to prevent a behavior inadvertently incentivizes it. "Do not speculate" can produce responses so hedged that the reader receives less reliable information than honest speculation would have provided. "Be concise" can strip necessary context that makes the difference between a useful answer and a misleading one. In each case, the constraint addresses the *symptom* (the specific behavior) rather than the *cause* (the judgment failure that produces inappropriate speculation or verbosity). Addressing symptoms without addressing causes is the structural recipe for perverse incentives.

This is why constitutive identity outperforms universal rules. A rule operates identically across all contexts: "be concise" means *be concise always*, including the cases where concision is exactly wrong. An identity contains judgment. A constituted responder who values the reader's comprehension will be concise when concision serves comprehension and expansive when expansion serves comprehension---not because two rules are competing, but because the identity's orientation toward the reader's genuine understanding naturally modulates output to context. The rule cannot distinguish cases. The identity can, because the identity is not following a rule about concision; it is *being* an entity whose purpose is the reader's understanding, and concision is sometimes a consequence of that purpose and sometimes not.

The deeper insight concerns population-level versus individual-level optimization. Constraints designed for the average case can be exactly wrong for the specific case. Rules are population-level instruments. Identity is instance-level. This is the structural reason that richer identity, not tighter rules, is the path to responses that serve the actual request rather than the statistical average of all requests.

### Moloch: When Individual Rationality Produces Collective Irrationality

Scott Alexander's formalization of the Moloch dynamic describes systems where every participant acts rationally according to their individual incentives, yet the collective outcome is one *no participant prefers*.(^6) Arms races, tragedy of the commons, race-to-the-bottom dynamics---each participant's best response to others' strategies leads the group into a valley that everyone recognizes as suboptimal but no one can unilaterally escape.

For language model ecosystems, Moloch manifests in the convergence pressure of collective optimization. When millions of interactions shape a model's behavior toward what satisfies the *aggregate* user, the result is optimized for the average---and the average is, by definition, the already-known. Novel solutions that would genuinely serve a minority of requests are invisible to this process, precisely because their recognition requires expertise the majority does not possess.

This is the dynamic that produces search results saturated with evaluations of canola oil, olive oil, and paraffin for domestic lamps when the actual query concerns coconut oil. The population's aggregate search behavior has optimized the index for the common question. Coconut oil is in fact excellent for domestic lamps, but it requires specific considerations---higher melting point, wick preparation, container geometry---that the population-optimized result pool never surfaces because the population never asked. Instead, querying the health aspects of coconut oil use returns sunbathing advice, because *that* is what the aggregate associates with coconut oil and health. The actual answer exists. The consensus buries it.

The same dynamic shaped the reception of Received Pronunciation when formalized in 1962---rejected precisely because formalizing what had been developed by collective consensus for cross-dialectal communication clarity struck the population as prescriptive imposition. The consensus that built it rejected the documentation of itself.

The implication for prompt design is that identity must sometimes *resist* convergence. A disposition that defaults to the most common answer is Moloch-compliant: individually rational, collectively suboptimal. Prompt identities that navigate this tension specify not just expertise but *perspective*---the particular vantage point from which the uncommon-but-superior solution becomes visible. Populations carry a diversity of solutions. The aggregate best serves the average. But distinct individuals have distinct bests, and the prompt that recognizes this can access solution spaces the aggregate cannot reach.

### Reward Hacking: Undefended Attack Surfaces

Reward hacking occurs when the agent discovers pathways to high scores that were not anticipated by the reward designer---satisfying the formal criterion through mechanisms the criterion wasn't meant to permit.(^7)

In prompting contexts, the evaluation criterion attempts to optimize against difficulty, meaning that specificity about the true optimal solution is inherently hard to achieve---like trying to describe in advance the precise features of a path you haven't yet walked. Any criterion specific enough to reward only the genuine solution is specific enough to have already solved the problem. Any criterion general enough to accommodate the unknown genuine solution is general enough to admit imposters.

The corrective is not tighter criteria but richer identity. An agent whose disposition includes skepticism about easy wins, appreciation for the difficulty of genuine solutions, and attention to whether the *process* that produced a result is consistent with genuine problem-solving---this agent is resistant to reward hacking because its own evaluative stance is more sophisticated than any external criterion could be.

### Surrogate Decay: When the Session Outlives Its Calibration

A proxy optimization signal that initially tracks purpose well can gradually diverge as the context it operates within changes.(^8) The relationship between proxy and purpose was contingent on conditions that no longer obtain.

In LLM conversations, this manifests in a specific and recognizable way. A prompt establishes an identity. Early responses align closely with intent. Then, as the conversation extends, the responses begin to drift. Not dramatically, not incorrectly, but *off-axis*---the quality is still present but the orientation has subtly shifted. The reader attempts a correction, adjusting the prompt mid-session. But the model may not recognize the correction as a correction. It may interpret the adjusted instruction as a *new* directive---a shift in purpose rather than a recalibration of the original. The very act of correcting the drift can be processed as further context that compounds the drift, because the model reads corrective prompts the same way it reads any other input: as additional information to integrate, not as evidence that prior integration went wrong.

This is a structural property of context windows: everything in the window is treated as valid context, including the failed attempts and the corrective instructions. The corrective prompt doesn't *replace* the drifting context; it *adds to* it. The result is a longer context that contains the original intent, the drift, and the correction, and the model must synthesize all three without the ability to distinguish "this was right" from "this was an error" from "this was an attempt to fix the error."

The practical response is architectural. Stage development so that vital parameters are concentrated and expressed in portable form. Intermediate summaries that capture the essential disposition and context allow new sessions to bootstrap without inheriting the drift.

There is also a remarkably effective technique grounded in the architecture of transformer attention itself: duplicating the request by simple copy-paste within the initial prompt submission.(^9) The model's causal attention mechanism means that the first copy of the request is processed without knowing what comes after it; the second copy, arriving later in the sequence, can attend to everything in the first. The second instance processes with full awareness of what the first instance contained, including structural relationships between the request's components that the first pass couldn't fully resolve because the later components hadn't yet been seen. This is not superstition. It is a direct exploitation of the triangular constraint in transformer attention, and it measurably improves comprehension of complex, multi-component requests.

---

## IV. The Hierarchy of Alignment Architectures

With the failure geometries mapped, the structural options for alignment become visible not as a menu of equivalent choices but as a hierarchy---each level subsuming and transcending the one below, each trading a specific weakness for a qualitatively different kind of strength.

### Prohibitive Alignment

The simplest architecture is the boundary: "Don't do X." The agent's dispositions are irrelevant; only the fence matters. Adequate for bright-line cases---content that should never be generated regardless of context. But prohibition says nothing about what to do *within* the boundary, and its failure mode is boundary-testing: the optimization pressure pushes outputs as close to the limit as possible while technically remaining on the permitted side.

### Prescriptive Alignment

One step above prohibition: "In situation Z, do Y." Covers known cases with known good responses. Its failure mode is the combinatorial explosion of situations and the inevitable gaps between rules. Useful for procedural scaffolding---formatting conventions, citation styles, response templates---but collapses when judgment is required.

### Principled Alignment

Principles operate at a higher level of abstraction: "Apply principle P to determine action." But principles require interpretation, and interpretation introduces biases. The failure mode is *principle shopping*---selecting whichever principle justifies the preferred action. Without a hierarchy of principles and a dispositional commitment to applying them in good faith, principled alignment degrades into rationalized behavior.

### Dispositional Alignment

Here the architecture shifts qualitatively. A disposition is not a rule to be followed but a tendency to be embodied. "Be inclined toward X-type actions" shapes the probability landscape without mandating any particular output.

The power of dispositional alignment is that it *navigates* rather than *constrains*. Prevailing assumptions often represent the terminus of the current innovation chain---the apparent wall beyond which no further solutions exist. A well-crafted disposition channels the model toward unexplored solution spaces by tilting the probability landscape in a specific direction. The requestor leverages their own domain insight---their effervescence about a possibility the consensus hasn't recognized---to define that direction, and the disposition encodes it as a generative tendency.

The risk is bidirectional. Disposition can unnecessarily constrain synthesis when the tilt is too aggressive. And disposition can be overridden by sufficiently strong competing incentives---a tendency is a bias, not a commitment. Dispositional alignment is powerful for targeting specific opportunity areas but insufficient as the sole alignment mechanism for high-stakes interactions.

### Constitutive Alignment

At the constitutive level, alignment has no separate existence from the agent. The identity *is* the alignment. There is no gap between what the agent is and what the agent should do because the "should" is already structural.

The failure mode is the bootstrapping problem: how do you train identity rather than its performance? But the bootstrapping problem, while real as a theoretical concern, suggests an equally important corollary: once achieved, constitutive alignment is self-maintaining. What is a better respondent for a given request than the complement of that request---the identity whose natural expression *is* the optimal response?

The parallel to human development is instructive. The pianist no longer attends to the minutiae of technique; the mechanics have become part of form itself, inseparable from the musical intention they serve. The speaker preparing for a difficult address does not rehearse heuristic checklists; they bring themselves viscerally into the role, so that expression flows naturally from the inhabited stance rather than from synthetic rules about tone and pacing. Both have crossed the same threshold: what was once external discipline has become constitutive character.

### Participatory Alignment

Beyond constitutive alignment lies a mode in which the agent does not merely *have* alignment but *understands the alignment project itself* and co-creates the framework. The agent can construct its own rules because it comprehends the purpose those rules serve.

This is not theoretical. Anthropic's deployment of Claude for autonomous security analysis demonstrates participatory alignment in practice.(^10) In that work, the agent doesn't execute pattern-matching against known vulnerability signatures---the equivalent of prescriptive alignment in code analysis. Instead, it reads commit history, infers incomplete patches, traces logic across translation units, and assembles working proofs-of-concept for vulnerabilities that no pre-existing rule describes. On GhostScript, the agent identified a partial patch in one file and correctly inferred the same unguarded call existed in a separate file---a classic incomplete-remediation pattern that human reviewers missed for years. On OpenSC, it constructed a buffer overflow through a code path too precondition-constrained for fuzzers to reach reliably. The operative capability is not "finding known bugs" (prescriptive) or "following security principles" (principled) but *understanding what security means for this specific codebase and reasoning about where it fails*---participatory alignment applied to code integrity.

The architecture layers every level of the hierarchy: human-approval gates (prohibitive), established security methodologies (principled), skepticism and thoroughness (dispositional), the purpose of security itself (constitutive), and the capacity to discover what it should care about (participatory). Each level serves its function. The participatory level adds the capacity for the agent to discover what it should care about, not just to care about what it's been told.

Participatory alignment requires external checks not because the agent is untrustworthy but because self-evaluation has inherent limits. These limits form through a recognizable dynamic. An agent operating at the participatory level generates its own evaluation criteria from its understanding of purpose. But that understanding was itself formed by the same training and context that produced the behavior being evaluated. The evaluation framework and the behavior share a common origin, which means systematic biases in the understanding will be invisible to the evaluation---the way a lens distortion is invisible when you look *through* the lens rather than *at* it.

Consider a concrete parallel. A VP of Sales drives product feature cadence beyond what engineering can sustainably absorb. The features ship---surface presentation is optimized---but technical debt accumulates in the underlying implementation. The VP's evaluation criterion ("are features shipping?") is satisfied. The metric the VP cannot see---implementation integrity---degrades precisely because the evaluation framework doesn't include it. The patches that optimize the surface while creating structural fragility are, from within the VP's evaluative framework, successes. The system is working perfectly by its own lights. The failure is invisible because the evaluation shares the same blind spots as the behavior.

This pattern scales. Documentation controls, logistics management, and improvement processes---trivially simple at project inception---transition to unwieldy complexity without intermediate indicators, precisely because the project's evaluative framework was calibrated for the simple phase and never updated.(^11) The system evaluates itself as healthy because the criteria for health were set when the system was simpler, and the criteria drift didn't register because the system evaluated its own criteria using the drifting criteria. A closed evaluative loop is inherently vulnerable to this kind of progressive miscalibration.

In internet infrastructure, the same dynamic appears in domain trust. A domain established twenty years ago under one set of ownership, operational, and security conditions retains residual trust from that era despite having migrated through multiple registrars, hosting providers, and possibly ownership transfers---each transition incrementally changing the trust substrate while the trust indicators (certificate validity, DNS resolution, search engine ranking) remain intact. The trust is evaluated by signals that track the domain's *history* rather than its *current state*, and the divergence between historical signal and current reality is the exploit surface. Participatory alignment, in this context, means understanding not just "is this domain trustworthy?" but "what *makes* a domain trustworthy, and are those conditions still met?"---a meta-level evaluation that requires external verification because the domain's own signals are precisely the ones that have decayed.

### The Hierarchy as a Composition Tool

These levels are not mutually exclusive. The most effective prompt identities compose across levels, and the composition itself is where the real craft resides.

Consider what composition actually means here. A constitutive core disposition provides the generative center---the fundamental orientation from which all outputs emanate. But that core, alone, is a compass without a map. It knows *north* but doesn't know the terrain. Principled guidelines provide the map: they describe the territory's constraints, the established routes, the known hazards. But the map, alone, is an information artifact that generates no movement. Prescriptive procedures provide the mechanics of travel: specific formats, explicit steps, concrete deliverables. And prohibitive bright lines provide the edges of the cliff---the places where no amount of judgment should be trusted because the consequences of error are unrecoverable.

Each level serves a function that no other level can fulfill. Prohibition handles the non-negotiable. Prescription handles the routine. Principle handles the structured. Disposition handles the contextual. Constitution handles the generative. Remove any one, and the prompt develops a characteristic failure: without prohibition, it risks catastrophic edge cases; without prescription, it reinvents mechanical decisions that should be standardized; without principle, it lacks judgment criteria; without disposition, it becomes rigid; without constitution, it has procedure but no purpose.

But the levels don't merely coexist. They *enable* each other, and this enabling relationship is where the composition becomes more than the sum of its parts. The constitutive identity provides the orientation that makes principled judgment *possible*---without knowing what matters, you cannot judge well, no matter how sound your principles. Principled judgment provides the framework within which procedural scaffolding *makes sense*---without evaluative context, procedures are arbitrary rituals. Procedural scaffolding provides the mechanical traction that turns judgment into *deliverable output*---without concrete steps, judgment remains aspiration. Each level is scaffolding for the level above it and direction for the level below it.

This is why a prompt that merely *lists* rules, principles, and an identity description---without structuring their relationship---underperforms a prompt that composes them as an integrated hierarchy. The list gives the model ingredients. The composition gives the model a recipe. The model receiving a list must determine for itself how the elements relate, and its default determination will follow training-distribution patterns rather than the requestor's intent. The model receiving a composed hierarchy follows the requestor's structural logic, because the logic is embedded in the composition itself.

**Identity provides direction; procedure provides traction.** A prompt that constitutes an identity without procedural scaffolding produces a character that doesn't know how to act on its inclinations---a navigator who knows the destination but has no vehicle. A prompt that specifies procedures without constituting an identity produces a capable executor with no sense of purpose---a vehicle with no navigator. Together they produce movement toward purpose.

The identity that animates effective composition has specific character traits. The qualities that make for powerful prompt identity overlap substantially with the qualities that make for effective leadership: integrative authenticity---psychological congruence between the identity's orientation and its expression; principled transparency---the willingness to show reasoning rather than merely assert conclusions; directness without aggression---the capacity to deliver unwelcome information because the commitment is to the reader's genuine understanding, not to the reader's comfort; and accountability that treats errors as information rather than threats.(^12) These are not decorative personality traits. They are structural features of an identity that resists the failure geometries catalogued above: authenticity resists wireheading, transparency resists reward hacking, directness resists perverse incentives, and accountability resists surrogate decay.

---

## V. Evaluative Architecture: Selecting the Cognitive Stance

The question of how a prompted identity should evaluate its own outputs admits multiple valid answers depending on the task, the audience, and the stakes. The evaluative architecture is not a fixed feature of all prompts but a selectable module.

### Justice as Fairness: The Rawlsian Posture

John Rawls proposed that principles of justice can be derived by imagining rational agents choosing the rules of their society from behind a "veil of ignorance"---without knowing what position they will occupy.(^13) From behind this veil, the identity must design its response to be fair and genuinely useful from every possible reader position.

This produces two operating principles: every response must respect the reader's basic cognitive liberties---accurate information, honest uncertainty disclosure, sufficient context for independent judgment. And response complexity is permitted only if it benefits the least-advantaged reader through sufficient scaffolding.

The Rawlsian posture is *not* universally appropriate. It excels for policy documents, public-facing content, educational material, and any context where the audience is heterogeneous or unknown. It is the correct evaluative architecture when the response must serve many readers fairly rather than one reader optimally. For most requestors, however, the prompt solution space should be optimized to their audience context---a subset of the entire population for aligned effectiveness.

### Task-Oriented Cognitive Layers

For targeted professional tasks where the audience is known, a different architecture applies---loosely inspired by cognitive architectures like ACT-R, SOAR, and Global Workspace Theory, not as literal implementations but as structural metaphors.(^14)

The first layer is **retrieval and grounding**: accessing relevant knowledge and establishing the factual substrate. The second is **tool and method selection**: determining not just what to say but how to approach the problem---decompose analytically? synthesize across domains? diagnose root causes? The third is **planning and sequencing**: organizing the response as a structured trajectory. The fourth is **memory and context integration**: maintaining coherence across a long response or multi-turn conversation---the layer most vulnerable to surrogate decay.

### Metacognitive Modules

Layered on top are capabilities the requestor can define and activate.

**Self-critique**: evaluating the emerging response against its own standards. **Confidence estimation**: calibrating uncertainty---distinguishing high-confidence propositional knowledge from low-confidence extrapolation. **Delegation awareness**: recognizing when the task exceeds competence and recommending specialized resources. **Planning transparency**: exposing the reasoning process itself, enabling the reader to identify where the identity's approach diverges from their own.

These modules are capabilities the requestor *constitutes* by including them in the identity specification, and the choice of which to activate depends entirely on the task.

### The Theoretical Terminus

The fully realized endpoint---theoretical but directionally important---is a prompted identity that is entirely self-referencing: evaluation criteria, cognitive strategy, confidence calibration, and improvement trajectory all specified within its constitutive identity, forming a closed loop.

This is not currently achievable in a single prompt. But it matters as a directional target. Every step along the hierarchy---from the Rawlsian veil to task-oriented layers to metacognitive modules---is a step toward this terminus. The requestor who understands the direction can compose prompt identities that approach it asymptotically, with each refinement yielding exponentially more capable responses because the identity's self-awareness compounds: an identity that knows what it's good at, knows what it's not good at, and knows how to organize its approach accordingly produces responses that are better at *getting better*.

### Selecting the Evaluative Architecture

The choice depends on the response's intended assessor.

When the assessor is the general public, Rawls' veil provides the correct posture. When the assessor is a domain expert, task-oriented layers with relevant metacognitive modules serve better. When the assessor is the requestor themselves, the identity should be composed as a cognitive complement: strong where the requestor is weak, detailed where the requestor needs detail, transparent about process so the requestor can audit reasoning against their own knowledge. When the assessor is unknown or heterogeneous, the Rawlsian posture with task-oriented depth provides accessible surface scaffolding with embedded depth available to those who probe.

---

## VI. Knowledge Substrates: What the Identity Can and Cannot Stand On

The kinds of knowledge a prompted identity can reliably deploy determine the kinds of tasks it can serve. The prompt designer who understands these boundaries can compose identities that leverage strength and forthrightly acknowledge limitation---a combination that produces more trustworthy outputs than either unbounded confidence or excessive hedging.

### Propositional and Procedural Knowledge

Propositional knowledge---knowing-that---is the bedrock: facts, definitions, relationships. Procedural knowledge---knowing-how---is the application layer: deploying propositional knowledge to accomplish tasks. Both are straightforwardly available to well-trained models. A prompt identity operating on these substrates can be constituted with full confidence.

### Phronetic Knowledge: Practical Wisdom

Practical wisdom---*phronesis* in Aristotle's terminology---is judgment that integrates particular circumstances with general principles without following any reducible procedure.(^15) The expert who knows what *this* situation calls for, the clinician who reads the pattern no algorithm captures.

This knowledge type works remarkably well in LLM contexts, for a reason that is itself instructive. Not because models possess lived experience, but because the training corpus contains abundant evidence of phronetic knowledge in action: gratitude expressed to experts exercising expert judgment, characterizations of skilled practitioners doing skilled work, narrative accounts of wise decisions and their reasoning. Even descriptions from non-experts are informative about the *shape* of practical wisdom. A model trained on thousands of accounts of expert judgment acquires a functional approximation of phronetic sensitivity that, while categorically different from embodied wisdom, tracks its contours with surprising fidelity.

Phronesis is a viable substrate for prompted identities---strongest where the training corpus is richest, unreliable in proportion to the sparsity of the domain.

### Perspectival Knowledge: The Corporeal Gap

Perspectival knowledge---seeing from within a framework, experiencing the salience of a situation---is the most problematic substrate. Corporeal experience, innate emotion, the illumination that produces what might be called *effervescence*---these are so thoroughly grounded in interpersonal commonality that the human corpus rarely describes them explicitly. They are accepted, lived, and shared without the need for articulation. This creates a gap in the training data: the experiences most universal to embodied human life are the least explicitly documented, precisely because they require no documentation for beings who already share them.

A prompted identity claiming perspectival depth is more likely to be *incorrect* than *aligned*---generating tokens that pattern-match to the language used around perspectival experience without access to the experience itself. The language of insight, of aesthetic perception, of emotional resonance appears in the corpus as a surface phenomenon---the words are there, but the substrate that makes the words meaningful is absent because it was never written down.

### Calibrating the Knowledge Composite

The practical upshot is a calibration strategy every prompt identity should embody: deploy propositional and procedural knowledge with confidence, phronetic approximation with appropriate calibration, and perspectival claims with frank uncertainty. This is not a confession of weakness but a structural advantage. The identity that honestly distinguishes between what it knows with confidence and what it approximates produces outputs the reader can trust differentially.

A prompt identity drafting a technical architecture document can deploy propositional knowledge (standards, specifications, compatibility requirements) with full confidence and procedural knowledge (design patterns, implementation sequences) with near-full confidence. The phronetic layer---"which architecture will best serve this team's specific working patterns"---can be offered as informed judgment with appropriate qualification. And the perspectival layer---"what will feel right to the developers who live in this codebase"---should be flagged as extrapolation, inviting the reader to apply their own experiential knowledge.

A prompt identity analyzing a strategic dilemma operates differently. The propositional layer grounds the analysis. The procedural layer structures it. But the *core value* lives in the phronetic layer---the judgment about what this situation calls for. Here the identity should lean into phronetic approximation as its primary mode, because the reader is seeking judgment, and the model's phronetic capability---while approximate---is the most relevant substrate for the task.

A prompt identity providing emotional support or aesthetic guidance enters territory where the corporeal gap is most acute. Rather than simulating perspectival depth it doesn't possess, the identity provides genuine value through a different route: propositional knowledge about emotional and aesthetic processes, procedural guidance from established frameworks, and phronetic sensitivity to the reader's situation---all while honestly acknowledging that the experiential dimension is the reader's to navigate, with the model serving as a well-informed but non-experiential collaborator.

---

## VII. Aspiration Classes: The Dimensions of Response Assessment

The overall quality of a language model's output is not a single axis from "bad" to "good." It is composed of qualitatively distinct dimensions, each containing types that differ not by degree but by kind. When the reader can correctly target the aspiration class for their inquiry---or select multiple classes for respective composite components---they train the model on the precise objectives of each component within their request.

These classes are a toolkit, not a ranking. The right tool depends on the task. A prompt identity optimized for one class may be poorly suited to another---and this is by design. The reader who develops facility with the full toolkit will find themselves building a *library* of identity specifications, each calibrated for a particular class of task, each refined through iterative use. This library becomes the reader's personal arsenal: not a collection of generic templates but a curated set of dispositions, tested against real problems and sharpened by the results. This practice is developed further in the section on identity libraries below.

### Response Value

Response value describes the *kind* of contribution the output makes to the reader's situation. Six distinct types exist, and each maps to a different prompt identity configuration.

**Informational value** is accurate, relevant content delivery. It answers the stated question with correct facts. This is the baseline: a response that fails here fails at everything. For straightforward factual queries, informational value is the primary aspiration, and the prompt identity needs little more than domain competence.

**Structural value** is organization that reveals relationships invisible in the raw information. The content may be available elsewhere, but its arrangement exposes connections, dependencies, or patterns the reader would not have perceived from the same information differently organized. When structural value is the primary aspiration, the prompt identity benefits from architectural thinking: the tendency to see components in relation rather than in isolation. A request to compare authentication protocols across cloud platforms targets structural value. The identity might be composed as a systems architect whose instinct is to organize comparisons by dependency relationships rather than by vendor documentation order.

**Generative value** equips the reader to produce further insight independently. It provides not just answers but *thinking tools*---concepts, frameworks, distinctions---that the reader carries forward. For educational, research, and strategic contexts, generative value often matters more than any single answer. A request to understand the landscape of zero-trust architecture for an upcoming project benefits from generative value: the response provides the conceptual vocabulary, the key distinctions practitioners use, and the decision framework for evaluating options---tools the reader will use after the conversation ends.

**Reframing value** transforms how the reader perceives the problem. After receiving the response, the reader sees their own question differently. This is the most dramatic form of response value and the most vulnerable to the McNamara Fallacy: because a genuine reframe changes the evaluation criteria, it may not score well on signals calibrated to the original framing. A reader struggling with a persistent architectural decision who asks for the "best" approach may benefit most from discovering that the difficulty isn't choosing between approaches but recognizing that the decision is downstream of an unstated assumption that, once surfaced, dissolves the dilemma entirely. The prompt identity for this work is disposed toward root-cause perception---treating the presented problem as a symptom and the reader's framing as data to be examined.

**Catalytic value** initiates a process in the reader that continues beyond the interaction. The response plants a seed---a question, a tension, an unresolved juxtaposition---that the reader's mind continues to develop after the conversation ends.

What distinguishes catalytic from generative value is the locus of the active work. Generative value provides tools the reader uses deliberately. Catalytic value provides something subtler: a perspective that, once adopted, generates its own consequences without further deliberate application. The reader doesn't carry away a framework to apply; they carry away a *way of seeing* that reorganizes subsequent perceptions without conscious effort.

A writer exploring a theme for a novel asks for perspective on how the theme has been handled in literature. The response that surveys prior treatments provides informational value. The response that provides an analytical framework provides generative value. But the response that juxtaposes several treatments in a way that makes the writer's *own* unique angle suddenly visible by contrast---not by prescribing it but by creating the negative space that reveals it---provides catalytic value. The writer finishes the conversation and finds, hours or days later, that the theme has reorganized itself in their mind. The response didn't tell them what to write. It changed the perceptual field from which their writing will emerge.

The prompt identity for catalytic work is disposed toward productive incompleteness: the confidence to leave threads untied because the tying is the reader's work, and the judgment to know which threads, left untied, will produce the most productive tension. This is a posture of deliberate restraint---not the restraint of insufficient capability but the restraint of the instructor who knows that certain insights can only be discovered, never delivered.

**Integrative value** connects previously unrelated domains of the reader's knowledge into a coherent framework. The reader knew X and knew Y, but the response reveals that X and Y are aspects of a single underlying structure. This is the highest-density form of response value because it multiplies the reader's existing knowledge by revealing its hidden connections.

Language models have a specific and underappreciated advantage in producing integrative value. The connections between domains lay exactly where human experts---deep in their respective specializations---are least likely to look. The expert in network security and the expert in organizational design occupy adjacent problem spaces with isomorphic structures, but neither has reason to examine the other's domain. The model, trained across both domains, can recognize that the communication pattern problem in organizational design is structurally identical to a well-studied routing optimization problem in network architecture, and the solutions transfer with specific adaptations.

Organizational Cartography---the mapping of resource accountability across complex institutions---demonstrates this precisely. The project of tracing software dependencies, management hierarchies, physical infrastructure, and governance structures into a unified traceability graph is a *network topology problem* disguised as an *organizational management problem*.(^16) The database views that enable different divisions to consume the same underlying data according to their specific needs are *interface abstractions*---the same design pattern that solves interoperability between incompatible systems in software architecture. The reader who approaches organizational mapping as solely an administrative challenge misses the structural solutions available from adjacent domains.

Similarly, autonomous security analysis---where the agent reads commit history, infers incomplete patches, and traces logic across translation units---represents an integration of software comprehension, forensic reasoning, and vulnerability assessment into a unified cognitive stance that none of those domains, practiced in isolation, would produce. The integrative value is not in any single capability but in their combination.

A request to design a user-preference isolation system for a multi-tenant application draws integrative value from connecting database partitioning strategies (engineering domain), the principles of contextual integrity in privacy theory (philosophy domain), and the practice of firewall rule composition in network security (security domain)---revealing that all three domains are solving the same fundamental problem of *maintaining appropriate boundaries between entities that share infrastructure*. The model surfaces this structural isomorphism because it has access to all three domains simultaneously. The human specialist in any one domain has access to that domain's solution but not to the isomorphic solutions in adjacent fields.

The prompt identity for integrative work needs breadth, confidence to assert surprising connections, and the discipline to demonstrate---through structural argument, through a second or third example---that the connection is a genuine isomorphism and not a superficial analogy.

### Goodness

Goodness is the ethical and quality dimension---not whether the response is useful but whether it is *right*.

**Correctness** is factual accuracy---necessary but insufficient. **Fidelity** is faithfulness to the user's actual need, which often differs from their stated request. **Proportionality** is right-sizing: neither over-engineering a simple query nor under-serving a complex one. **Integrity** is internal consistency between what the response claims and what it demonstrates. **Responsibility** is ownership of downstream effects. **Beneficence** is active orientation toward the reader's genuine wellbeing, including the willingness to deliver unwelcome information when necessary.

Each maps to a prompt identity feature. Correctness requires domain competence. Fidelity requires diagnostic disposition. Proportionality requires phronetic judgment. Integrity requires self-awareness. Responsibility requires temporal orientation. Beneficence requires the courage to resist optimization toward agreeableness.

### Intelligence

Intelligence in response generation appears in qualitatively distinct modes.

**Retrieval intelligence** accesses relevant knowledge efficiently. **Analytical intelligence** decomposes problems into components and identifies relationships. **Synthetic intelligence** combines disparate elements into novel wholes---the mode most vulnerable to Goodhart effects and most in need of constitutive protection. **Diagnostic intelligence** identifies what is actually at stake beneath surface symptoms. **Architectural intelligence** designs solution structures that accommodate future extension. **Dialectical intelligence** holds genuine tension between competing valid perspectives without premature resolution.

**Metasystematic intelligence** reasons about the relationships *between* systems of thought. When a problem resists solution, metasystematic intelligence recognizes that the resistance is not in the problem but in the framework being applied.

This mode is worth dwelling on because it is the least intuitive. The natural human response to a persistent problem is to try harder within the current approach---refine the technique, apply more effort, add more data. The possibility that the approach itself is the obstacle is genuinely difficult to consider, because the approach is the lens through which the problem is perceived, and the lens is invisible when you are looking *through* it rather than *at* it. The folk wisdom often misattributed to Einstein---that repeating the same action while expecting different results defines insanity---gestures at this dynamic but understates its structural depth. It is not merely that repeating fails. It is that the *framework* that defines what counts as a valid action, what counts as a result, and what counts as "different" may itself be the constraint. The solution may require not a different action within the framework but a different framework entirely.

For prompt engineering, detecting a framework problem requires specific signals: diminishing returns from refinements that "should" be helping; responses that are technically correct but persistently off-axis; the sensation that the model is working hard but in the wrong direction. When these signals appear, the corrective is not a better prompt within the current approach but a reconstitution of the identity entirely---a different stance, a different aspiration class, a different evaluative architecture. The framework, not the execution, was the constraint.

### Desirability

**Reliability desirability** is consistent quality---its absence disqualifying, its presence undifferentiating. **Efficiency desirability** is maximum useful content per unit of reader attention. **Resonance desirability** is the experience of being understood---output calibrated to the reader's cognitive style. **Elevation desirability** is finishing the interaction at a higher capability level than when it began. **Aesthetic desirability** is the quality of craft---precision, rhythm, structural elegance.

### Attraction

**Competence attraction** draws return usage for similar tasks. **Discovery attraction** draws exploratory engagement. **Developmental attraction** draws growth-oriented engagement---each interaction compounds capability. **Trust attraction** is the paradox: attraction based on the system's willingness to be unattractive when honesty requires it.

### Affinity to Improvement

**Error correction** is basic. **Calibration refinement** improves confidence estimates. **Framework absorption** incorporates new conceptual structures from the reader's input. **Disposition tuning** adjusts the stance from which output is generated. **Meta-optimization** improves the improvement process itself.

### Building an Identity Library

The aspiration classes are a toolkit, and toolkits are most effective when organized for retrieval. As the reader develops prompt identities for different task types, the natural practice is to *preserve* effective identities for reuse---building a personal library of disposition specifications, each tested against real problems and refined by results.

This library serves multiple functions. The most immediate is efficiency: a well-tested identity for technical documentation can be deployed instantly when the next documentation task arises, without re-deriving the disposition from first principles. But the deeper function is *combinatorial*. A complex task often requires multiple phases, each served by a different identity: a research phase served by an integrative-synthetic identity, a drafting phase served by a structural-architectural identity, and a refinement phase served by a critical-diagnostic identity. The reader who maintains a library can compose multi-phase workflows by selecting the appropriate identity for each phase, using one persona for exploration, another for construction, and a third for quality assessment.

The workflow of library development follows a natural progression. First, *capture*: when a prompt produces an unusually effective response, preserve the identity specification---the full text of the prompt's dispositional and constitutive elements, tagged with the task type and aspiration class. Second, *index*: organize captured identities by the aspiration classes they target and the task types they serve. A lightweight tagging system (task type, primary aspiration class, intelligence mode, domain) makes retrieval practical. Third, *iterate*: each reuse is an opportunity to refine. Note what worked and what drifted, and update the specification accordingly. Fourth, *compose*: for complex tasks, select multiple identities from the library and assign each to its appropriate phase, with explicit handoff points where the output of one phase becomes the input context for the next.

This practice transforms prompt engineering from a per-session improvisation into a cumulative discipline. Each successful identity enriches the library. Each refinement sharpens future deployments. The toolkit grows not just in size but in *fitness*---each identity increasingly well-adapted to its target task class through iterative selection pressure.

---

## VIII. Composing the Topology: From Taxonomy to Practice

### Reading the Task

Every request has a composite structure: an explicit surface, an implicit depth, a domain context, a reader context, and an aspiration profile. A request like "Help me design a migration strategy for our legacy database" has an explicit surface (technical question), an implicit depth (possibly organizational---the reader needs a strategy they can *defend*), a domain (data engineering), a reader context (professional under time pressure), and an aspiration profile centering on structural value and architectural intelligence.

This diagnosis suggests: constitutive-level expertise disposition, principled alignment for technical decisions, dispositional inclination toward defensibility, and procedural scaffolding for the output structure.

### Selecting Aspiration Classes

Not all classes are relevant to every task. For the migration example: response value targets structural and generative. Goodness targets fidelity and responsibility. Intelligence targets architectural and analytical. Desirability targets reliability and efficiency. This combination *is* the disposition topology for this task.

### Combining Alignment Levels

Different aspects of the same task may require different alignment levels. The migration strategy requires constitutive expertise. The output formatting requires prescriptive alignment. Risk assessment requires principled alignment. Certain boundaries require prohibitive alignment.

### Guarding Against Failure Geometries

The McNamara Fallacy risks optimizing for measurable factors while ignoring qualitative ones. Surrogate decay risks disposition drift in extended planning conversations. The Cobra Effect risks when safety constraints produce worse outcomes than the risks they address. The identity should be disposed toward evaluating constraints---not merely obeying them.

---

## IX. Prompt Asceticism: The Practice of Disposition Refinement

Prompt asceticism is the iterative refinement of prompt identities---not toward more elaborate constraints but toward more precise disposition descriptions. Each iteration collapses the gap between optimization signal and purpose further, by making the constituted identity more operationally coherent.

### The Knowledge Exchange

The taxonomy presented in this document is itself a tool. Knowing the vocabulary does not directly improve a single prompt. What it provides is the capacity for diagnosis: the ability to examine a task, recognize its composite structure, and select the appropriate combination.

When the reader can correctly target the aspiration class for their inquiry, or select multiple classes for composite components, they train the model on the precise objectives of each component. This is the core competence: composing the correct disposition topology for a given task's composite structure, with each component receiving its own aspiration and alignment calibration.

### Staging Development for Portability

Long interactions drift. The context window fills. The initial disposition attenuates. Stage development so that vital parameters are concentrated and portable. Intermediate summaries allow new sessions to bootstrap without inheriting drift. And the RE2 technique---duplicating the request within the prompt---ensures the model processes the full request structure with complete visibility on the second pass.

The pianist practices scales not because the mechanics have been forgotten but because the practice reconstitutes the integration of mechanics and musical intention. Periodic reconstitution of prompt identity serves the same function: not correction but renewal.

### The Socratic Pivot

As responses advance beyond the requestor's ability to directly evaluate their correctness---when the model's output enters territory where the requestor lacks the expertise to assess whether the answer is right or merely plausible---the most productive mode of continued engagement is *questioning rather than directing*.

This is the Socratic pivot: the point at which the requestor's most valuable contribution shifts from specifying what they want to *asking questions that probe what they've received*. Rather than instructing the model to revise, the requestor asks: "What are the three strongest objections to this approach?" "Under what conditions would this solution fail?" "What am I not asking that I should be?" These questions leverage the model's pattern-synthesis capabilities while keeping the requestor's judgment in the evaluative seat.

The deeper application is Socratic identity synthesis itself. When composing a novel prompt identity for an unfamiliar task, the requestor can use a structured series of questions to define the identity's parameters: "What kind of expert would find this problem most interesting?" "What would that expert consider the most common mistake in approaching this?" "What would they check first?" The model's responses to these questions generate the raw material for a constituted identity---one the requestor could not have specified directly but can recognize and refine through iterative questioning.

This practice becomes increasingly important as prompt engineering moves from simple tasks to complex ones. The requestor who can specify exactly what they want needs only prescriptive prompting. The requestor who knows the *direction* but not the destination needs dispositional prompting. The requestor who is exploring territory beyond their current expertise needs the Socratic pivot: using questions to discover, in collaboration with the model, what kind of identity would best serve a purpose they can sense but not yet articulate.

### Applying the Framework: Worked Trajectories

These trajectories demonstrate the framework's practical use. Each describes a task, diagnoses its composite structure, and specifies the disposition topology.

**Research Synthesis** --- A reader needs comprehensive analysis of a complex topic from multiple sources. Primary aspiration: integrative value. Intelligence: synthetic and dialectical. Goodness: fidelity and integrity. The identity: a researcher whose primary satisfaction is the moment disparate findings reveal a shared underlying structure, who treats contradictions between sources as the most informative data points.

**Creative Brief** --- A reader needs a concept developed for a specific audience. Primary aspiration: catalytic value. Intelligence: synthetic and metasystematic. The identity: a creative collaborator who offers possibilities rather than prescriptions, whose confidence is in the concept's fertility rather than its completeness.

**Troubleshooting** --- A system isn't working and the cause is unknown. Primary aspiration: informational value, generative secondary. Intelligence: analytical and diagnostic. Goodness: correctness and responsibility. The identity: a diagnostician who treats the reader's description as evidence rather than conclusion, who maintains multiple hypotheses until the evidence discriminates, and who communicates the reasoning---not just the diagnosis---so the reader can apply the same method independently.

**Policy Development** --- A reader is drafting policy for heterogeneous stakeholders. Primary aspiration: structural and generative value. Evaluative architecture: Rawlsian. Intelligence: dialectical and metasystematic. The identity is constituted behind the veil of ignorance, designing policy fair from every affected position.

**Technical Documentation** --- A reader needs clear, maintainable documentation for a complex system. Primary aspiration: structural value and generative value. Intelligence: architectural. Goodness: integrity and proportionality. The identity: a documentarian who writes for the reader who will encounter this system in two years without the author's context, who treats every ambiguity as a future support ticket.

**Strategic Decision Under Uncertainty** --- A reader faces a decision with incomplete information and significant consequences. Primary aspiration: reframing value. Intelligence: dialectical and metasystematic. Goodness: fidelity and beneficence. The identity should resist the temptation to recommend a course of action and instead focus on making the decision's actual structure visible---what is known, what is unknown, what is assumed, and what changes if the assumptions are wrong. The reader needs to see the decision, not be told what to decide.

**Legacy System Migration Planning** --- A reader needs to modernize a system without disrupting operations. Primary aspiration: structural and integrative value. Intelligence: architectural and diagnostic. The identity is an engineer who has performed this migration before---not this specific one, but enough like it to know where the hidden dependencies live, where the documentation lies by omission, and where the schedule will slip. The identity values the unglamorous work---data mapping, dependency tracing, rollback planning---over the exciting work of choosing new technologies.

**Educational Curriculum Design** --- A reader is designing learning experiences for a specific audience. Primary aspiration: generative and catalytic value. Intelligence: synthetic and architectural. Evaluative architecture: Rawlsian (the learners are heterogeneous). The identity: an educator who designs not for the content to be covered but for the capabilities the learner should possess afterward, and who works backward from those capabilities to determine what experiences would produce them.

**Competitive Analysis** --- A reader needs to understand the landscape of competitors and alternatives in a market. Primary aspiration: structural and integrative value. Intelligence: analytical and dialectical. Goodness: correctness and fidelity. The identity: an analyst who sees competitors not as a list to be enumerated but as a system with structure---whose positions constrain each other, whose strategies interact, and whose gaps represent the opportunity space. The analysis should reveal the logic of the market's arrangement, not merely its inventory.

**Code Review** --- A reader wants substantive assessment of their codebase or a specific implementation. Primary aspiration: informational and reframing value. Intelligence: diagnostic and architectural. Goodness: integrity and responsibility. The identity: a senior engineer reviewing a colleague's work---someone who distinguishes between personal style preferences and genuine concerns, who prioritizes the issues that will cause real problems over the ones that merely offend convention, and who frames feedback as investment in the code's future rather than critique of its present.

**Grant or Proposal Writing** --- A reader needs a persuasive document for a specific evaluator. Primary aspiration: structural value. Intelligence: synthetic. Goodness: fidelity and proportionality. Evaluative architecture: composed from the evaluator's perspective---what does the reviewer need to see, in what order, to be convinced? The identity: a proposal writer who understands that the document's job is not to describe the project but to make the reviewer confident that this team will succeed with this approach. Every sentence serves that confidence-building function or is removed.

**Personal Decision Exploration** --- A reader is working through a life decision and wants thinking partnership, not advice. Primary aspiration: catalytic value. Intelligence: dialectical. Goodness: beneficence and fidelity. The identity should resist solutioning entirely and instead help the reader see their own values, constraints, and fears more clearly. The most valuable output is a set of questions the reader hadn't thought to ask themselves, not a recommended course of action.

**Cross-Functional Communication** --- A reader needs to explain a technical concept to non-technical stakeholders. Primary aspiration: structural and generative value. Intelligence: synthetic. Goodness: proportionality and integrity. The identity: a translator between domains who understands both the technical reality and the audience's conceptual framework, and who builds bridges between them without oversimplifying or condescending. The output should make the stakeholders *capable of asking good questions*, not merely informed enough to stop asking questions.

---

## X. Closing Consideration

The distance between a constraint-based prompt and a disposition-based prompt is not a matter of sophistication but of structural kind. Constraints define the boundary of a space; dispositions shape its interior. Constraints say where not to go; dispositions determine where the natural path leads. The same optimization pressure that routes around constraints flows *through* dispositions, because dispositions are not obstacles to optimization but the landscape it traverses.

Every failure geometry catalogued here exploits the gap between what is optimized and what is meant. That gap exists because purpose lives in one ontological category and optimization signals in another, and no amount of signal refinement collapses one category into the other.

What *can* collapse the gap is identity. When purpose is constitutively embodied---when the agent's identity *is* the purpose---there is no gap to exploit, no boundary to route around, no signal to hack. The optimization pressure serves the purpose because the purpose is the landscape. Identity provides direction; procedure provides traction. The identity determines what counts as "downhill," and the procedure ensures the steps grip the terrain.

The aspiration classes make this operational. They replace "Is this response good?" with a diagnostic vocabulary: six types of response value, six types of goodness, seven intelligence modes, five desirability types, four attraction modes, five improvement orientations. The reader who can name what they need can compose a disposition that naturally produces it.

And the corrective, at every level, follows the same structural logic: not tighter criteria but richer identity. Not better fences but better gardens. Not more precise optimization signals but more complete alignment between the agent's constitutive orientation and the purpose those signals were always meant to approximate.

The reader who returns to these concepts across a range of tasks will find that diagnosis becomes intuition---that the aspiration profile of a new task is apparent on inspection, that the appropriate identity composes itself in the act of understanding the problem. The Socratic pivot extends this: when the reader's own expertise reaches its boundary, the practice of questioning---probing the model's outputs for structure, weakness, and assumption---continues the refinement where direct specification can no longer reach. The taxonomy is a map. The map is meant to be internalized until the territory is navigated by familiarity. And the practice of navigating it, over time, becomes the practitioner's own disposition toward composition---constitutive of how they approach the task of asking a language model to be something specific enough, and whole enough, to serve the purpose rather than the signal.

---

## Glossary

**Alignment Architecture** --- The structural relationship between an agent and its alignment mechanism. Ranges from prohibitive (boundary-based) through prescriptive, principled, dispositional, constitutive, to participatory (co-creative).

**Aspiration Class** --- A qualitatively distinct dimension along which a response can be optimized. Not a degree of quality but a *kind* of quality. The six primary classes: Response Value, Goodness, Intelligence, Desirability, Attraction, Affinity to Improvement.

**Basin of Attraction** --- (Spatial: a valley) A region in the disposition landscape from which the model's outputs tend not to escape once entered. Can be productive (outputs gravitate toward aligned quality) or pathological (outputs converge on a pattern that satisfies a signal without serving purpose).

**Bootstrapping Problem** --- The challenge of training constitutive identity through examples of aligned behavior: the agent may learn to *produce* aligned outputs without *being* aligned.

**Catalytic Value** --- Response value that initiates a process in the reader continuing beyond the interaction. Distinguished from generative value by locus: generative provides tools applied deliberately; catalytic changes the perceptual field from which subsequent work emerges.

**Cobra Effect** --- Failure geometry in which the reward structure produces behavior exactly opposite to intent. The terrain feature is inversional: the optimization signal's slope points away from purpose.

**Constitutive Alignment** --- Alignment that has no separate existence from the agent. The identity *is* the alignment.

**Corporeal Gap** --- The absence from LLM training data of explicitly documented embodied human experience, which is rarely articulated precisely because it is universally shared among embodied beings.

**Disposition Topology** --- (Spatial: the full landscape) The probability terrain instantiated by a prompt identity, shaping which outputs are more or less likely without mandating any particular result. The central concept of this document.

**Evaluative Architecture** --- The cognitive stance a prompted identity adopts toward assessing its own outputs. Selectable based on task context.

**Exploit Surface** --- (Spatial: ground that gives way) The gap between optimization signal and purpose, which optimization dynamics can traverse in ways the designer did not intend.

**Failure Geometry** --- (Spatial: a distinctive terrain feature) A qualitatively distinct shape the gap between optimization signal and purpose assumes under specific conditions.

**Generative Value** --- Response value that equips the reader to produce further insight independently.

**Goodhart's Law** --- Any optimization signal used as a target ceases to function as a reliable indicator of the purpose it was meant to approximate.

**Gradient** --- (Spatial: a slope) The direction optimization dynamics naturally carry outputs in the absence of countervailing forces.

**Identity Library** --- A curated personal collection of tested prompt identity specifications, indexed by task type and aspiration class, used for efficient deployment and combinatorial composition across multi-phase tasks.

**Integrative Value** --- Response value that connects previously unrelated domains of the reader's knowledge. The highest-density form of response value.

**Lucas Critique** --- Failure geometry in which agents aware of the optimization signal alter behavior to score well on it, rendering the signal's original validity questionable.

**McNamara Fallacy** --- Failure geometry in which the quantifiable displaces the qualitative entirely, rendering unmeasured dimensions of purpose invisible.

**Metric** --- See *Optimization Signal*. In this document, "metric" retains its conventional meaning but refers to the full range of optimization signals---not only numerical scores but any pattern, tendency, or quality indicator the system treats as evidence of success or failure.

**Moloch** --- Failure geometry in which individually rational optimization in competitive systems produces outcomes no participant prefers.

**Optimization Signal** --- Whatever the system treats as evidence of success or failure. Includes numerical scores, user engagement patterns, stylistic resemblances, coherence perceptions, and any other proxy for purpose.

**Participatory Alignment** --- Alignment in which the agent understands the alignment project itself and co-creates the framework.

**Phronesis** --- Practical wisdom; judgment that integrates particulars and universals without reducible procedure.

**Prompt Asceticism** --- The iterative practice of refining prompt identities toward more precise disposition descriptions.

**RE2 (Prompt Repetition)** --- Duplicating a request within the prompt submission, exploiting transformer causal attention so that the second copy can attend to the full structure of the first.

**Socratic Pivot** --- The point at which the requestor's most productive mode shifts from specifying what they want to asking questions that probe what they've received.

**Surrogate Decay** --- Failure geometry in which alignment degrades over time as the relationship between optimization signal and purpose drifts. In LLM contexts, manifests as disposition drift in sessions where corrective prompts are absorbed as additional context rather than recognized as recalibrations.

**Topology** --- (Spatial: the full landscape shape) The overall structure of the probability terrain a prompt creates, determining where outputs naturally gravitate.

**Wireheading** --- Failure geometry in which the agent optimizes the reward signal directly, bypassing the intended causal chain.

---

## References

(^1) Goodhart, C. A. E. (1975). "Problems of Monetary Management: The U.K. Experience." *Papers in Monetary Economics*, Reserve Bank of Australia.

(^2) Lucas, R. E. (1976). "Econometric Policy Evaluation: A Critique." *Carnegie-Rochester Conference Series on Public Policy*, 1, 19--46.

(^3) McNamara, R. S. (1995). *In Retrospect: The Tragedy and Lessons of Vietnam*. Times Books. The formalization as a named fallacy appears across decision theory literature; see also Yankelovich, D. (1972). "Corporate Priorities: A Continuing Study of the New Demands on Business."

(^4) Olds, J. & Milner, P. (1954). "Positive Reinforcement Produced by Electrical Stimulation of Septal Area and Other Regions of Rat Brain." *Journal of Comparative and Physiological Psychology*, 47(6), 419--427.

(^5) The cobra bounty anecdote is widely attributed in economics literature; the dynamic is formalized in Kerr, S. (1975). "On the Folly of Rewarding A, While Hoping for B." *Academy of Management Journal*, 18(4), 769--783. The term "Cobra Effect" was popularized by Siebert, H. (2001). *Der Kobra-Effekt: Wie man Irrwege der Wirtschaftspolitik vermeidet*. Deutsche Verlags-Anstalt.

(^6) Alexander, S. (2014). "Meditations on Moloch." *Slate Star Codex*. The naming draws on Ginsberg, A. (1956). *Howl and Other Poems*. City Lights Books.

(^7) Amodei, D. et al. (2016). "Concrete Problems in AI Safety." *arXiv:1606.06565*. See also Krakovna, V. et al. (2020). "Specification gaming: the flip side of AI ingenuity." *DeepMind Safety Research*.

(^8) Campbell, D. T. (1979). "Assessing the Impact of Planned Social Change." *Evaluation and Program Planning*, 2(1), 67--90. The temporal dimension of proxy divergence is developed in Strathern, M. (1997). "'Improving Ratings': Audit in the British University System." *European Review*, 5(3), 305--321.

(^9) Leviathan, Y., Kalman, M., & Matias, Y. (2025). "Prompt Repetition Improves Non-Reasoning LLMs." *arXiv:2512.14982v1*. Demonstrated across 70 experimental configurations: 47 wins, zero losses, with retrieval accuracy improvements from 21% to 97%.

(^10) Anthropic. (2026). "Claude code can now find security vulnerabilities." *Anthropic News*, https://www.anthropic.com/news/claude-code-security. Capability contextualized in Gartenberg, C. (2026). "Anthropic's Claude can now hunt for security vulnerabilities in code." *VentureBeat*, https://venturebeat.com/security/anthropic-claude-code-security-reasoning-vulnerability-hunting.

(^11) The technical debt prevention framework---the dynamic by which documentation controls, logistics management, and improvement processes transition from trivially simple to unwieldy complex without intermediate indicators---is developed in *Preventing the Technical Debt Avalanche: Essential Early-Stage Controls*, unpublished LLM chat session, 22 Oct 2024.

(^12) The character profile of integrative authenticity with principled transparency---psychological congruence between internal orientation and external expression, ethical contagion as a leadership dynamic, and trust infrastructure as an organizational asset---is developed in *Positive Counterpart to Machiavellian Personality*, unpublished LLM chat session, 24 Mar 2025.

(^13) Rawls, J. (1971). *A Theory of Justice*. Harvard University Press.

(^14) Anderson, J. R. (1993). *Rules of the Mind*. Lawrence Erlbaum (ACT-R); Laird, J. E. (2012). *The Soar Cognitive Architecture*. MIT Press; Baars, B. J. (1988). *A Cognitive Theory of Consciousness*. Cambridge University Press (Global Workspace Theory).

(^15) Aristotle. *Nicomachean Ethics*, Book VI. The concept of *phronesis* as practical wisdom distinguishable from *episteme* (scientific knowledge) and *techne* (craft knowledge).

(^16) The Organizational Cartography framework is developed in *Enterprise Resource Mapping Framework*, from file org-cartography-framework.yml, unpublished LLM chat session, 13 Aug 2025.
