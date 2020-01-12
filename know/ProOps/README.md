# Proceeding Operations Framework
ProOps, a framework for operational development, change control, quality and improvement.

## Process Objectives
Typical software development objectives

* streamline development, on-boarding and integration
  * [Components](#components) (below), the operational control documentation entry point
  * simplify vetting, defined beginning (and end) of documentation and code
* operational framework: development, build, package, product and customer services
  * reproducible deliverable
  * multiple release versions, branching and customization 
  * infrastructure platform for automated QA, unit testing and CI/CD
  * performance benchmark controls, calibration and automation
  * alignment of development, PoC, MVP and QA environment
  * component API and profiling definitions and analysis
  * simplify refactoring
  * simplify integration of new tools and frameworks
* minimize security exposure
  * software version traceability
  * deployment controls
  * comprehensive and streamlined upgrades
  * auditable deployment through design and standards
  * eliminate uncontrolled services
* change control
  * efficient improvement, corrective and preventive actions
  * specification details through automation
  * documentation integrated with code
* eliminate dependence on unwritten information (tribal knowledge)
* data definitions and management (privacy, retention, expiration)
* hygienic systems and environment

## Questions
Typical platform development discovery

* what is the infrastructure?
* hosts? services? vendors?
* design objectives?
* design decisions?
* bootstrap process? (dev, PoC, QA, profiling, benchmark, release)
* tools and dependencies?
* implementation controls?
* configuration management?
* unit testing?
* deployment automation?
* change control?
* access control?
* role based access controls?
* authentication and authorization?

## Proceeding Operations Framework Documentation and Change Control

The components section below
is the entry point for operational documentation, code and change control.
The [framework](framework.md) is a four phase, continuous feed forward, development model.
Each phase is divided into three scopes, for broader, middle and finer details.
Each phase orients the next with inputs.  Direction is taken from
the prior phase and calibration is from the phase two steps away.
The phases are Risk analysis, Design plan, Execution implementation and Check quality.
The following handoffs characterize the feed forward loop cycle.

* Executions     are evaluated by quality checks which indicate if the design plan    addresses the risks analysis.
* Quality checks are evaluated by risk analysis  which indicate if the executions     addresses the design plan.
* Risk analysis  are evaluated by design plans   which indicate if the quality checks addresses the executions.
* Design plans   are evaluated by executions     which indicate if the risks analysis addresses the quality check.
* Executions     are evaluated by quality checks which indicate if the design plan    addresses the risks analysis.
* ...and so fourth

A [Resource](resource.md) document contains a [glossary](resource.md#Glossary), [acronyms](resource.md#Acronym) and [reference](resource.md#Reference) bibliography.

---

## Components
* [README](README.md) - ProOps Framework overview 
  * [Framework](./framework.md)
  * [Resource](resource.md)
  * [Index](index.md)
* [Risk](risk.md) - threshold and barriers impeding goals
  * Viability - effort value, opportunity window, competition, and nefarious analysis (broader barriers)
  * Compliance - complexity, cognition, competence, capability (middle challenges)
  * Improve - optimization, upgrades, new tools (finer enhancements)
* [Exec](exec.md) - instantiation of the implementation (platform, code, config)
  * Administration - accounting and management of the data, platform and interfaces (broader tasks)
  * Registration - design alignment with specific resources (organization, middle scope)
  * [exec](./exec) Integration data, scripts and config for setup and operation of components (finer details)
* [Design](design.md) - the plan, prototype model, twin representation of the implementation
  * Requirement - expectations for acceptance (broader details)
  * Function - implementation primitive components, setup, interaction, mechanisms and algorithm (middle scope)
  * Specification - details, vendors, BOMs, versions, resource provision, interfaces connections and cabling (finer detail)
* [Check](check.md) - monitoring and representational twin alignment
  * Benchmark - performance quantitative analysis (broad scope)
  * Unit - monitoring and functional analysis (middle scope)
  * Profiling - qualitative analysis (finer detail)

---

## Validation
This ProOps framework is a validation plan template. The components, fully developed, represent a validation report.

---
Unlimited use with this notice (c) 2017-2020 George Georgalis
