# 2026-04-29 — IMPLEMENTATION PLAN (STRICT)

Mode: Controlled Execution Plan

Principle:

NO deviations.
NO parallel changes.
NO opportunistic refactoring.

Only sequential controlled fixes.

---

## STEP STATUS REGISTER

### Step 1.1 — Policy → Arbitration wiring

Status: CLEAN

---

### Step 1.2 — Remove IO → Command direct writes

Status: CLEAN WITH DOCUMENTED TEMPORARY EXCEPTION

---

### Step 1.3 — Enforce single command path

Status: PARTIAL / WITH TAILS

---

### Step 2.1 — Define priority

Status: CLEAN

---

### Step 2.2 — Implement priority in Command Arbitration

Status: CLEAN

---

### Step 3.1 — Active PLC gating

Status: CLEAN

Result:

- `PRG_Command_Arbitration` exits immediately on standby PLC
- standby PLC does not generate shadow commands

---

### Step 3.2 — Standby behavior

Status: CLEAN WITH TAILS

Result:

- `PRG_IO_Write` now forces physical outputs to safe-off on standby PLC and returns
- standby cannot drive field outputs through `GVL_STATE` or `GVL_COMMAND_SHADOW`

Tails:

- exact per-output safe state must be reviewed later against electrical design
- this is safe-off behavior, not full hot-standby output ownership design

---

## REMAINING PLAN

PHASE 4 → TIME
PHASE 5 → PRG_System
PHASE 6 → Verifier

---

END OF PLAN
