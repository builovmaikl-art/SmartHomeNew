# System Behavior Audit — 2026-04-30

## Purpose

This directory is the working place for a full top-down and bottom-up behavior audit of the current SmartHomeNew repository.

The project currently builds and compiles without errors. Therefore this audit is not a syntax/build audit.

The audit target is behavioral and architectural risk:

- hidden ownership conflicts;
- wrong execution order assumptions;
- stale documentation versus actual runtime pipeline;
- safety/coordinator/policy/domain hierarchy violations;
- cases where a block compiles but may behave unexpectedly;
- situations requiring user instructions;
- situations requiring engineer/commissioning instructions.

## Source of truth

Current repository files are the source of truth.

When documents conflict with code:

1. current implementation wins for actual behavior;
2. `docs/MASTER_GUIDE.md` governs workflow and design principles;
3. other docs provide supporting context only;
4. old audit files must be treated as historical unless revalidated against current code.

## Audit mode

Mode: Direct Repository Modification Mode for documentation creation.

Verification scope:

- GitHub file-state verification only;
- no terminal execution;
- no runtime confirmation;
- no claim that behavioral hypotheses are proven by tests until scenario/runtime verification is added.

## Initial documents

- `01_AUDIT_METHOD.md` — audit method and classification rules.
- `02_MAIN_EXECUTION_PIPELINE.md` — actual top-level execution pipeline from `MAIN.st`.
- `03_INITIAL_RISK_REGISTER.md` — first behavioral risk register found from current top-down inspection.

## Working rule for future reports

Each future report should contain:

1. observed repository evidence;
2. affected PRG/FB/GVL area;
3. expected behavior;
4. potential failure behavior;
5. user-facing implication;
6. engineer-facing implication;
7. recommended verification scenario;
8. status: hypothesis / confirmed / fixed / obsolete.

## Current status

Audit initialized.

No runtime code changed.
