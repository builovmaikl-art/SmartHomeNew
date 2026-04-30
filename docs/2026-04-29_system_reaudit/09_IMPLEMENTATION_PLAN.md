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

### Step 1.2 — Remove IO → Command direct writes
Status: CLEAN WITH DOCUMENTED TEMPORARY EXCEPTION

### Step 1.3 — Enforce single command path
Status: PARTIAL / WITH TAILS

### Step 2.1 — Define priority
Status: CLEAN

### Step 2.2 — Implement priority in Command Arbitration
Status: CLEAN

### Step 3.1 — Active PLC gating
Status: CLEAN

### Step 3.2 — Standby behavior
Status: CLEAN WITH TAILS

### Step 4.1 — PRG_Time_Service
Status: CLEAN WITH TAIL

### Step 4.2 — Replace time usage
Status: CLEAN WITH STRATEGIC BRIDGE

---

## PHASE 5 — PRG_System DECOMPOSITION STRATEGY

Execution mode:

SAFE TWO-CONTOUR EXTRACTION

Rule:

Do NOT clean or cut PRG_System first.

Order:

1. Identify visible blocks inside PRG_System
2. Create external PRG/FB blocks with required corrections
3. Verify external blocks compile structurally
4. Connect external blocks in MAIN / orchestration layer
5. Verify behavior by code inspection
6. Only then remove old duplicated logic from PRG_System

Allowed first extraction targets:

- Time: already extracted to PRG_Time_Service
- Health / state aggregation
- Gateway/system intent publication
- Scenario/rule handling
- History/logging
- Persistence/recovery

Hard constraints:

- no large PRG_System rewrite
- no placeholder truncation
- no manual "rest unchanged"
- each extraction must have its own status: CLEAN / CLEAN WITH TAILS / PARTIAL

Reason:

PRG_System is high-risk and was previously damaged by large replacement.

---

## REMAINING PLAN

PHASE 5 → PRG_System safe extraction
PHASE 6 → Verifier

---

END OF PLAN
