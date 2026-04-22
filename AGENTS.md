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

"Read `docs/MASTER_GUIDE.md` first, then follow the repository workflow described there and in `docs/WORKFLOW.md`. Use `docs/CHANGELOG_WORK.md`, `docs/ARCHITECTURE_NOTES.md`, `docs/EQUIPMENT_DECISIONS.md`, and `docs/IO_MAPPING_CONCEPT.md` as supporting project memory. Work only from the current repository state, choose the correct verification and application mode, and verify every step against actual repository evidence before continuing."