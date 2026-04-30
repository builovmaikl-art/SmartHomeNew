# Audit Method — Top-Down Then Bottom-Up

Date: 2026-04-30

## Goal

Perform a full behavioral and architectural audit of the current compiled SmartHomeNew project.

This is not a syntax or compilation audit. The project is known to compile successfully.

The objective is to find possible behavioral problems, documentation gaps, engineering risks, and user-facing situations that require explicit instructions.

## Global approach

The audit is performed in two passes, repeated for every system layer:

1. Top-down pass:
   - start from `MAIN.st`;
   - follow actual execution order;
   - identify what each PRG is expected to own;
   - identify data produced and consumed in the same PLC cycle;
   - identify direct actuation paths and blocking paths.

2. Bottom-up pass:
   - start from physical outputs and domain outputs;
   - trace back who can write or affect them;
   - identify all competing owners;
   - identify whether safety/coordinator/policy hierarchy is preserved.

## Source of truth

The source of truth is current repository implementation.

Old documentation is treated as historical unless revalidated against current files.

## Control hierarchy to preserve

The governing hierarchy is:

```text
Safety
  > Coordinator
    > Budget / eligibility
      > Priority / policy bias / guest preheat
        > Domain control
```

A potential issue is recorded whenever:

- a lower layer can bypass a higher layer;
- multiple blocks write equivalent state without a clear owner;
- a block combines ownership roles that should be separated;
- an output can be driven through multiple independent routes;
- behavior depends on execution order but this is not documented;
- user/engineer instructions cannot clearly explain what happens.

## Audit depth levels

### Level 1 — Pipeline and ownership map

Scope:

- `MAIN.st` order;
- PRG-to-FB call map;
- major GVL write/read ownership;
- layer classification.

Output:

- execution pipeline document;
- system layer model;
- initial risk register.

### Level 2 — Axis audit

Each axis is audited end-to-end:

1. Time and cycle base.
2. IO read and sensor normalization.
3. Safety intent and hazard projection.
4. System intent / health / alarm / gateway.
5. Scenario / policy / mode / coordinator.
6. Command arbitration and command verification.
7. Security and access control.
8. Heating domain.
9. Ventilation domain.
10. Lighting/socket/blinds domain.
11. IO write and physical actuation.
12. Diagnostics/history/blackbox/trend/simulation.

### Level 3 — Deep block audit

For each PRG/FB/GVL cluster:

- responsibility;
- inputs;
- outputs;
- internal state;
- persistent/latching behavior;
- reset behavior;
- fail-safe behavior;
- HMI/user behavior;
- commissioning implications;
- test scenario requirements.

## Risk classes

### SAFETY_BYPASS

A lower layer can weaken, ignore, or override safety intent.

### OWNERSHIP_CONFLICT

Two or more blocks appear to own the same state, decision, or output.

### ORDER_DEPENDENCY

Correct behavior depends on execution order in `MAIN.st` but is not documented or enforced locally.

### SHADOW_LEGACY_CONFLICT

A new command/intent/shadow path coexists with a legacy path and mismatch handling is incomplete.

### OBSERVABILITY_GAP

The system can enter a meaningful state that is not clearly visible to user/operator/engineer.

### USER_INSTRUCTION_GAP

User-facing behavior exists but lacks clear operating instructions.

### ENGINEER_INSTRUCTION_GAP

Commissioning, troubleshooting, or maintenance behavior exists but lacks engineer instructions.

### TEST_GAP

A meaningful behavior has no clear scenario/runtime validation plan.

## Report status values

- HYPOTHESIS — suspected from static inspection.
- CONFIRMED_STATIC — confirmed by repository file analysis.
- CONFIRMED_RUNTIME — confirmed by execution/scenario test.
- FIXED — fixed in repository and verified.
- OBSOLETE — no longer applicable after code changes.

## Current operating mode

Mode: Direct Repository Modification Mode for documentation creation.

No runtime code is changed by this audit initialization.

Runtime claims require Full Verification Mode or explicit scenario test evidence.
