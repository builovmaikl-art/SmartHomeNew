# AGENTS.md — SmartHomeNew entry instructions

## Mandatory first step
Before doing any analysis, planning, coding, or proposing changes for this repository, read:

1. `docs/MASTER_GUIDE.md`
2. `docs/WORKFLOW.md`
3. `docs/CHANGELOG_WORK.md`
4. `docs/ARCHITECTURE_NOTES.md`
5. `docs/EQUIPMENT_DECISIONS.md`
6. `docs/IO_MAPPING_CONCEPT.md`

If there is a conflict between documents:
- implemented code in the repository = current fact of implementation
- `docs/MASTER_GUIDE.md` = governing workflow and design principles
- architecture/equipment/changelog docs = supporting context

## Core control hierarchy

For all runtime-affecting logic, preserve this hierarchy:

```text
Safety
  > Coordinator
    > Budget / eligibility
      > Priority / policy bias / guest preheat
        > Domain control
```

Rules:

- Safety has the highest priority and must not be bypassed by comfort, policy, preheat, budget, or coordinator logic.
- Coordinator is a constraint/blocking layer, not an actuator owner.
- Budget / eligibility decides which requests can be served with available resources.
- Priority / policy bias / guest preheat may influence allocation, but must not directly control pumps, valves, relays, or physical outputs.
- Domain programs remain responsible for domain actuation after safety and coordinator constraints are applied.
- Any change that weakens this hierarchy must be treated as a high-risk architecture change and documented before code changes.

## Scenario test panel principle

The repository uses an internal scenario test panel approach for logic verification:

```text
GVL_TEST_PANEL + PRG_Scenario_Test_Harness
```

Rules:

- All new logic should be verifiable via scenario-based tests when possible.
- Scenario tests should allow manual input changes and expose expected vs actual values.
- Prefer single-screen verification to avoid multi-window/manual inspection errors.
- Scenario tests act as a pre-hardware commissioning layer.
- Scenario tests must not write into:
  - `GVL_STATE`
  - `GVL_IO`
  - actuator outputs

Purpose:

```text
reduce manual inspection
reduce integration risk
allow fast behavioral validation before hardware is available
```

## FILE INTEGRITY RULE (MANDATORY)

After ANY repository modification:

```text
1. Immediately re-read the modified file from the repository
2. Verify:
   - full structure is present
   - no truncated logic blocks
   - no missing CASE branches / functions
   - no accidental overwrites
3. Only AFTER this verification proceed to the next change
```

Strictly forbidden:

```text
multiple sequential modifications without intermediate verification
assuming logic "remains unchanged"
continuing work if file integrity is not confirmed
```

Rationale:

```text
prevents silent logic loss
prevents partial overwrites
ensures deterministic engineering workflow
```

## ANCHOR-BASED SAFE EDITING RULE (MANDATORY)

All non-trivial code modifications must use anchor-based editing.

### Definition

Anchors are explicit named markers in code:

```text
// === BEGIN BLOCK_NAME ===
// === END BLOCK_NAME ===
```

### Purpose

```text
- ensure deterministic insertion points
- avoid accidental overwrite of unrelated logic
- allow safe partial modifications inside large PRG files
- eliminate ambiguity of repeated lines (END_IF, END_CASE, etc.)
```

### Rules

```text
1. Never rely on single-line matches (e.g. END_IF, END_CASE)
2. Always target a named anchor block when modifying code
3. Only modify content BETWEEN BEGIN/END markers
4. Do not modify code outside the target anchor block
5. If no anchors exist → add anchors first, then modify
```

### Required workflow

```text
1. fetch full file
2. locate BEGIN/END anchor
3. modify ONLY inside anchor
4. update full file
5. re-fetch file
6. verify:
   - anchors still exist
   - surrounding code intact
   - change applied correctly
```

### Forbidden patterns

```text
modifying code based on first match
partial file replacement
"rest unchanged" assumptions
editing without anchors in large files
```

### Example

Correct:

```st
// === BEGIN RESULT_MIRROR ===
... modified logic ...
// === END RESULT_MIRROR ===
```

Incorrect:

```text
find "END_IF" → insert after
```

### Status in repository

```text
PRG_Scenario_Test_Harness.st is already anchor-enabled
```

All future changes must follow this model.

## Working rules
- Treat this repository as an engineering system, not a collection of isolated features.
- Safety has priority over comfort, but false escalation must be avoided.
- Do not blindly replay old step scripts as the main integration mechanism.
- New work should be integrated against the current repository state.
- Accepted decisions must be reflected in the relevant docs before or together with code changes.
- Preserve fail-safe behavior.
- Distinguish between:
  - авария from sensors
  - отказ исполнительного механизма / feedback fault
- Prefer addressable IO / mapping architecture over hard coupling to physical PLC channels.

## Repository execution discipline
- Work is performed against the current observable repository state only.
- The source of truth is:
  - repository files
  - current `git diff`
  - execution logs and errors
- Do not rely on chat memory, assumptions, or expected repository state.
- Treat this repository as a controlled engineering system state, not as a free-form coding workspace.

## Verification Modes

The repository supports three verification modes depending on environment constraints.

### 1. Full Verification Mode (default)

This is the primary and required engineering mode.

Verification is performed using:
- terminal execution
- actual `git diff`
- execution logs

Rules:
- only this mode produces engineering-confirmed results
- a change is considered real only after:
  1. repair execution
  2. `git diff`
  3. verification via logs

### 2. Analytical Verification Mode (assistant-driven)

Used when terminal execution is not available.

Allowed:
- inspection of actual repository files
- structural and architectural validation
- cross-file dependency checks
- consistency checks against docs

Not allowed:
- claiming changes as applied
- treating analysis as execution result
- marking tasks as completed

Rules:
- results must be explicitly marked as analytical
- repository state is considered unmodified unless proven otherwise
- transition to Full Verification Mode is mandatory for final confirmation

### 3. Direct Repository Modification Mode (assistant-operated)

Used when the assistant can directly modify repository files through an available repository tool.

Allowed:
- direct repository updates performed by the assistant
- immediate verification against resulting repository files
- GitHub-visible commit / file-state confirmation

Restrictions:
- use only for documentation, workflow, metadata, and other low-runtime-risk repository changes unless broader use is explicitly approved
- must not be described as terminal-executed verification
- must not fabricate execution logs or runtime confirmation

Rules:
- the resulting repository state is real once the repository mutation succeeds
- verification must explicitly state that confirmation was performed against repository file state, not terminal execution
- if a change affects runtime behavior, safety logic, build process, or deployment semantics, Full Verification Mode remains preferred

### Direct Modification Transparency Rule

For every direct repository modification:
- the assistant must explicitly state:
  - what was changed
  - where the change was made
  - why the change was made
- the change must be fully observable in repository state
- no hidden or implicit modifications are allowed

### Mandatory Post-Change Verification Rule

After any change (in any mode):
- the assistant must verify the resulting repository state
- verification must confirm that:
  - the intended change is present
  - no unintended changes were introduced
- verification must be explicitly stated in the response

For runtime-affecting logic, verification should include scenario test panel validation when applicable.

## Change application rules
- Do not make manual in-editor fixes as the primary integration path.
- Every non-trivial change should be materialized as a reproducible repair step in:
  - `steps/<date>_<context>/<nn>_<name>.py`
- Each repair step should be:
  - deterministic
  - idempotent
  - minimally invasive
  - scoped to a single responsibility
- For runtime-affecting repository changes, a change is considered engineering-confirmed only after:
  1. repair execution
  2. `git diff`
  3. verification of the resulting repository state
- For direct assistant-operated repository mutations explicitly allowed by the workflow, the resulting file state is real after successful repository update, but runtime confirmation is still separate if applicable.

## Consistency and failure rules
- If a repair script fails, the repository must be treated as being in an inconsistent intermediate state until verified otherwise.
- Partial application is not considered success.
- Do not continue with the next repair until the current repository state is checked.
- Do not repair broken intermediate state manually; use a new deterministic repair step.
- If a tool or repair depends on guessed filenames, guessed locations, or guessed type names, it must be treated as unreliable and replaced with a more deterministic approach.

## Pre-step checklist
Before any next repair / change step:
1. inspect current repository state
2. inspect current execution errors, if any
3. confirm repository consistency
4. define one concrete target problem
5. choose the correct application mode
6. apply one scoped change
7. inspect resulting repository state
8. verify no unintended side effects

## Documentation and result preservation
- Result preservation means preserving reproducible repository state, not preserving chat text.
- Logs are part of the engineering evidence for each step.
- Documentation updates must be merged with existing repository guidance, not replace it blindly.
- New guidance must not conflict with `docs/MASTER_GUIDE.md` and `docs/WORKFLOW.md`.

## New chat / new session bootstrap prompt
Recommended opening instruction for any new assistant session:

"Read `docs/MASTER_GUIDE.md` first, then follow the repository workflow described there and in `docs/WORKFLOW.md`. Use `docs/CHANGELOG_WORK.md`, `docs/ARCHITECTURE_NOTES.md`, `docs/EQUIPMENT_DECISIONS.md`, and `docs/IO_MAPPING_CONCEPT.md` as supporting project memory. Work only from the current repository state, choose the correct verification and application mode, preserve the control hierarchy Safety > Coordinator > Budget / eligibility > Priority / policy > Domain control, and verify every step against actual repository evidence before continuing."
