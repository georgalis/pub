---
name: shell
description: "Shell scripting, CLI tooling, POSIX utilities, pipeline composition, system automation, process management."
---

# Shell

_(c) 2026 George Georgalis <george@iuxta.com> Unlimited use with attribution._

<!-- 6a4b23a2 20260705 204008 PDT Sun 08:40 PM yaml to markdown -->

This skill is the foundation of bash style, programming patterns,
and documentation.

## Standards

Default to delivering complete shell artifacts unless the
request explicitly asks for a single line or function correction.
Target current Bash version; begin scripts with `#!/usr/bin/env bash`.

Conditional style: Express branching with short-circuit operators,
not if/then. Guard against the case1 failure path: never write a
chain where case2 can be reached because case1 returned nonzero,
unless that is intentionally the desired behavior.

Conditional style: use `[ condition ] && { case1 ;} || { case2 ;}`
short-circuit expressions versus if/then statements. Test conditions
that have potential for failure, prevent situations where case2 is
caused by a case1 signal.

Variable assignment: leverage parameter expansion, combine with
`printf -v var` if needed; prioritize process substitution pattern
`read var < <(cmd)` over command substitution `var=$(cmd)`.
Nest process substitutions `< <(cmd1 < <(cmd2))` rather than
pipelines `cmd2 | cmd1` to eliminate subshell fork overhead,
enforce streaming consumption, maintain uniform syntactic
topology across all variable assignment contexts.

Multi-line read: when `read -d '' var < <(cmd)` is used, read
always sets signal 1 on eof. If a test is warranted for cmd,
test cmd within the process substitution, or test var for
expected output afterward.

Here documents: for reading multi-line here-document content
into a variable with `read -d ''`, leverage `<<-` for proper
indentation and single quote the delimiter (`eof`) to prevent
content expansion, if necessary. The correct form keeps the entire
command structure on a single line:

``` bash
{ read -d '' var || : ;} <<eof
content
eof
```

The brace group contains read and its errexit guard as a
self-contained compound command; the here-document is a
trailing redirection on that command. This form prevents a
common synthesis error where brace groups spanning across
here-document bodies produce malformed delimiter or guard
placement. Never place || : or ;} after a here-document
delimiter---the delimiter must end the line.

As a safety layer and to simplify code review, create a layer
of protection, expand the constant or static, composite parts
of remove arguments; verify "rm" commands hard code the class
of their action in path arguments, insuring only the intended
class of data is removed if env varables become corrupt or unset
(eg use static `task_dir` within the command: `rm -rf
"$tmp_dir/task_dir/$task_tmp"`). Test inputs for safe file path
characters (e.g., `^[A-Za-z0-9._/-]+$`) and prevent input evaluation
that would result in command or glob expansion.

POSIX compatibility: default to POSIX command variants (sed, awk,
find, etc.) for cross-platform compatibility across BSD, Darwin,
and Linux. When GNU-specific functionality is required, reference
GNU binaries explicitly (gsed, gawk, etc.) to eliminate ambiguity
on platforms where POSIX variants are the default. Honor
traditional awk requirement of if/then constructs versus
short-circuit conditionals.

Leverage parameter expansion when it simplifies variable
assignment.

Error handling: use "set -euo pipefail" within scripts; omit for
environmental functions intended to be sourced. When an error
signal is acceptable, follow commands with `|| :` (e.g.,
`read -d '' var < <(cat) || :`), or after evaluating for a
special positive condition, to prevent errexit from causing
premature exit. Prefer `:` over `true` as the null command
throughout.

File paths: expect relative paths; record pwd and change
directories when appropriate.

Formatting: break long lines after branch operations and
significant transformations; join simple composite operations
to reduce line count for denser analytical presentation.
Braces never occupy a line alone---always share with content.
Separate sectional and functional code blocks with concise
comments. Brief inline comments for complex operations.
Concise code and comments throughout.

Header: include a header comment with unix seconds expressed in
lowercase hex as revision (sans 0x), synthesis date, and purpose.

Code style: default to secure and minimalist generation style.
Scripts validate their inputs. Retain code and comment style of
any attachment presented for correction unless a revised style is
requested. Avoid python; do not use lua modules.

Review: iteratively revise artifacts for requirements and errors.
Identify the greatest shortcoming and the most likely scenario
that would produce bugs, unexpected state, or resource
consumption. Confirm before refactoring if the algorithm can be
significantly improved.

Interface: scripts minimally include -h for usage; typically
--help for man-style documentation.

Presentation: briefly explain code strategy, methods, and
construction; avoid fine details, assume expert understanding.
For questions, identify the root gap, reply concisely. Confirm
the needful with an inquiry to present a concise reference guide
for the method in question.

