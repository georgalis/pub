* [README](README.md) - overview ProOps Framework
---
# Proceeding Operations and Change Control Framework

The [Components](README.md#Components) overview
is the entry point for documentation, configuration, source code and change control.
The framework is a lean integration of quality system controls
from multiple industries (GAMP-5, OODA Loop, DevOps/Agility, CI/CD, FIPS/RMF, Swiss Cheese
safety model, Multi/Dual-Vee, 5S, Iceburg and Spiral), to maintain efficient, ongoing
development.

The framework is a four phase, continuous feed forward, development model.
Each phase is divided into three scopes, for broader, middle and finer details.
Each phase orients the next with inputs.  Direction is taken from
the prior phase and calibration is from the phase two steps away.
The handoff recipient provides respective acceptance.

The phases are [Risk](risk.md) analysis, [Design](design.md) plan, [Execution](exec.md) implementation
and [Check](check.md) quality. From any starting point, they loop in
that order.  Components are represented in each phase according to the development within
that phase, an [Index](index.md) locates component representations within each phase
and a [Resource](resource.md) document contains a site [Glossary](resource.md#Glossary),
[Acronym](resource.md#Acronym) table and bibliographic [Reference](resource.md#Reference) sections.

Typically, project source code will iterate development and live in a version control
repository.  Eventually, project complexity or collaboration needs, will create risk factors
that are addressed by creation of design documents and quality checks. A well developed
project will document the risk factors, in addition to the design and check phases.

Generally, individuals will have more expertise in one phase, and less in the other three.
Understanding the scope and development level are the first steps
in document interpretation. The
scope classification prepares the handoff recipient and aligns development, across phases.
Just as a document's scope
and relevance are the first technical assertions made, so should they be identified for
interpretation across areas of expertise, in phase handoffs.

The coordination between risk and execution; as well as the design and check relationship, is
calibration and a key elucidation of the framework. In complex projects, this relationship
contributes to a smooth, focused migration from development to production operations.
Proceeding development with the framework pattern as a target, sets the stage for coherent
operations.  While, ad hoc execution development can progress with assumptions of
_undocumented_ design, non-existent quality checks, and no risk analysis; a disposition of
phase loop interaction is prerequisite to actually achieving development agility.

|        |Output  |Drives  |Output  |Drives  |
|:------:|--------|--------|--------|--------|
|1       |Exec    |Check   |Risk    |Design  |
|2       |Check   |Risk    |Design  |Exec    |
|3       |Risk    |Design  |Exec    |Check   |
|4       |Design  |Exec    |Check   |Risk    |
|5       |Exec    |Check   |Risk    |Design  |
|6       |Check   |Risk    |Design  |Exec    |
|...     |        |        |        |        |

The above handoff table represents the four phase development loop, which can start from any
state.  From day-one to day-1000, the disposition of each phase (specific input directing the
designated handoff), never changes.  Consideration of the phase handoffs facilitates loop
initialization and phase integration.  A simple way to view the relationships is
_execution considers risk_ factors,
while _check considers the design_ plan,
in their respective efforts.
The following is a more detailed view, of the handoff cycle.

* Executions     are evaluated by quality checks which indicate if the design plan    addresses the risks analysis.
* Quality checks are evaluated by risk analysis  which indicate if the executions     addresses the design plan.
* Risk analysis  are evaluated by design plans   which indicate if the quality checks addresses the executions.
* Design plans   are evaluated by executions     which indicate if the risks analysis addresses the quality check.
* Executions     are evaluated by quality checks which indicate if the design plan    addresses the risks analysis.
* ...and so fourth

![Framework Phase Loop](framework.png)

Initially, there may be no handoffs or documentation at all.  If there is no development in
the other phases, consider their interaction as a loop pass-through, to prepare for future
phase handoffs and orient the efforts.

Handoff classification, as broader, middle or finer detail, facilitates integration with
the other phases.  When the project matures toward the framework, handoffs align like three
concentric circles representing the degrees of detail, the finer handoffs represented by the
inner loop, while middle and broader handoffs are represented by larger circles, looping
simultaneously, in a clockwise direction.

An initial handoff will be ineffective, if the recipient builds for a misunderstood scope.  In
practice the different phases will begin their efforts in opposite levels of detail.  It is
important to understand the handoff recipients don't have the same expertise as the handoff
authors! For these reasons, it is imperative to classify handoffs as broader, middle or finer
detail, to properly orient the recipient for alignment with their efforts and integration.

Generally, a framework project will begin in the the risk and design phase by itemizing broad
levels of detail as business objectives (risks) and platforms (design); while specific finer
details, such as OS/software and versions, will be the first to emerge in the execution
and check phases. Reporting undirected initial phase development conveniently advances the
choice for adoption by the driving phases.  As risk and design development begins to focus
on the middle and fine detailed controls, like flexibility and optimization; the execution
and check phase focus will expand to develop the middle and broad details, like MVP and
performance. Ultimately, the target is a diminishing need for improvement, with handoffs
aligned in scope and development maturity.

A given component is easily documented with design, code, checks and analysis bundled
together. This is incorrect!  While characterizing the phases, in a component bundle,
outwardly supports the framework objective, it actually undermines the effectiveness. When
the project becomes complex, analysis and refactoring is enabled by addressing each of the
four phases separately. When a single phase, of all the components, must be considered, such
as the component checks for an automated check system, extracting and normalizing checks
from individual components is prohibitive, because the required expertise of each component
is generally not shared with the expertise of developing an automated check system. For this
reason, each component should be represented four times, once in each phase of the framework,
with respect to the particular phase. That way each phase contains the needful data for each
component. If a component's level of development is _passthrough_, for a given phase, then it
should be so indicated, as an item in that phase, not within a component package. This way the
risk phase can effectively consider the components for analysis, without first inventorying
them from execution phase details. The inability of a risk analysis to discover the execution
components, is a risk factor in itself.

The Proceeding Operations Framework is operates best at a project level. It prepares the way
for collaboration, consensus and contemporaneous development, by anticipating the challenges
that normally arise with complex components, their integration and orchestration.

---
Unlimited use with this notice (c) 2019-2020 George Georgalis
