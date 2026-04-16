# RECOVERY STRATEGY (System Integrity Rules)

## Purpose
Defines how to recover system consistency when development or integration goes wrong.

---

## When Recovery is Required

- Inconsistent behavior after steps
- Conflicting logic in subsystems
- Loss of control over priorities
- Unclear system state
- Manual edits causing drift

---

## Core Principle

Stop → Rebuild → Validate → Apply

Never continue development on broken state.

---

## Recovery Workflow

1. STOP all new changes
2. Analyze current repo state
3. Ignore previous step history
4. Reconstruct correct logic
5. Create FINAL_RECOVERY_PACKAGE
6. Apply in one execution
7. Validate system behavior

---

## FINAL_RECOVERY_PACKAGE Requirements

- Must include ALL required changes
- Must be idempotent
- Must contain self-checks
- Must not depend on previous steps

---

## Validation Rules

After recovery:

- No conflicting logic remains
- Policy layer respected
- Priorities work correctly
- System behaves predictably

---

## Anti-Patterns

- Trying to fix issues step-by-step
- Applying partial patches
- Mixing old and new logic

---

## Notes

Recovery is not a failure.
Recovery is controlled system correction.

---

## Status

Version: v1
Based on Ventilation V2 recovery experience
