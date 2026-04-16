# DEVELOPMENT WORKFLOW — SmartHomeNew

## Purpose
This document defines the practical interaction workflow for developing the project together without losing context, introducing replay errors, or forcing frequent manual edits from the user.

It complements `docs/MASTER_GUIDE.md` and `docs/WORKFLOW.md`.
It does not replace them.

## Compatibility with existing docs
- `docs/MASTER_GUIDE.md` remains the top-level project philosophy and source-of-truth guide.
- `docs/WORKFLOW.md` remains the concise engineering workflow and anti-pattern list.
- This file adds the operational collaboration model:
  - how steps are accumulated,
  - when they are applied,
  - how final packages are assembled,
  - how to work efficiently when the user is often away from the computer.

## Core rule
Do not apply intermediate step files one by one during active development of a subsystem.

Intermediate steps are for:
- reasoning,
- traceability,
- accumulation of decisions,
- preparation of a final package.

The user applies only a final assembled package, unless an explicit exception is agreed.

## Collaboration model

### 1. Discussion first
Before meaningful code changes:
- discuss architecture,
- agree policy/behavior,
- record important decisions.

### 2. Step accumulation mode
During work on a subsystem:
- create step files under `steps/<phase>/`
- each step should be self-descriptive
- steps may include:
  - decisions,
  - rationale,
  - draft scripts,
  - deferred cleanup notes

But:
- steps are not automatically replayed by the user
- steps are not treated as the source of truth once the repository has advanced

### 3. Repository as source of truth
At any moment, the current repository state is the implementation truth.
Previously applied steps must not be blindly replayed.
If a package has already been applied, a new phase folder should be started.

### 4. Finalization trigger
A final package is assembled only when one of the following is true:
- the user explicitly requests it
- work on a concrete subsystem is considered complete enough to package

Examples:
- "собери итог по отоплению"
- "собери мегашаг"
- "готов применить пакет"

### 5. Final package rule
A final package:
- is rebuilt from the current repository state
- takes accumulated steps into account
- does not blindly concatenate all prior scripts
- must be internally consistent
- should minimize user actions

Preferred format:
- `FINAL_<SUBSYSTEM>_PACKAGE.sh`
- or `FINAL_MEGA_STEP.sh`

### 6. Application mode
After the final package is saved into the repository:
- user performs a minimal terminal sequence
- assistant checks the terminal output
- only after a successful check is the subsystem considered finalized

## Phase model
Use separate phase folders to avoid confusion after applied packages.

Example:
- `steps/2026-04-02_phase2/`
- `steps/2026-04-03_phase3/`

Rule:
- once a package is applied and accepted, start a new phase folder
- old phase steps are historical trace only
- new work must not keep mutating old phase assumptions

## Recommended interaction order
For each meaningful step:
1. Assistant prepares and saves the file to the repository first, when possible.
2. Assistant then explains briefly what the step means.
3. Assistant only gives terminal commands when the step is actually meant to be applied.

This minimizes user copy-paste and keeps the interaction predictable.

## Working modes

### A. Accumulation mode
Used most of the time.
- discuss
- create steps
- do not run them yet

### B. Finalization mode
Used only by explicit request or subsystem completion.
- assemble final package
- apply once
- inspect terminal output
- lock in the result
- start new phase

## Heating/Ventilation lessons learned
The following rules were confirmed in practice:
- architecture decisions should be recorded before deep code edits
- policy should be introduced before cleanup/decomposition
- final packages must be rebuilt with awareness of prior steps
- direct step-by-step replay creates avoidable breakage risk

## Documentation rule
Whenever a new collaboration rule proves useful in practice, it should be reflected in docs.

## Anti-patterns
Forbidden or strongly discouraged:
- blind replay of all intermediate step scripts
- treating old phase steps as current truth after package application
- mixing discussion, patching, and finalization in one uncontrolled flow
- forcing the user to manually patch large files repeatedly when a final script can be prepared instead

## Practical summary
- Discuss first.
- Accumulate steps.
- Rebuild final package from repo truth.
- Apply once.
- Verify.
- Start a new phase.
