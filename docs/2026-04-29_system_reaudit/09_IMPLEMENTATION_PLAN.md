# 2026-04-29 — IMPLEMENTATION PLAN (STRICT)

Mode: Controlled Execution Plan

Principle:

NO deviations.
NO parallel changes.
NO opportunistic refactoring.

Only sequential controlled fixes.

---

## Global rules

1. One step = one change set
2. After each step:
   - compile
   - minimal runtime check
3. No mixing layers in one step
4. All side ideas → backlog (NOT implemented)

---

## PHASE 1 — CLOSE CONTROL PIPELINE (CRITICAL)

### Step 1.1 — Connect Policy → Command Arbitration

Goal:

Policy must influence commands

Action:

- Add Policy intent structure (GVL_INTENT_POLICY)
- Feed it into PRG_Command_Arbitration

Do NOT change logic yet — only wiring

---

### Step 1.2 — Remove IO → Command direct writes

Goal:

Eliminate architectural bypass

Action:

- In PRG_IO_Read:
  remove direct writes to GVL_COMMAND
  replace with IO fault flags only

---

### Step 1.3 — Enforce single command path

Final path must be:

Intent → Arbitration → Shadow → IO

Validation:

- search for any direct GVL_COMMAND writes
- eliminate all except arbitration layer

---

## PHASE 2 — PRIORITY MODEL

### Step 2.1 — Define priority

Safety > System > Policy > User

### Step 2.2 — Implement in Command Arbitration

Explicit resolution, not order-based

---

## PHASE 3 — ACTIVE/STANDBY ENFORCEMENT

### Step 3.1 — Global gating

Wrap ALL logic blocks:

IF GVL_STATUS.G_Is_Active_PLC THEN
   execute
END_IF


### Step 3.2 — Standby behavior

Standby:
- no command generation
- only state sync

---

## PHASE 4 — TIME ARCHITECTURE

### Step 4.1 — Introduce PRG_Time_Service

Placed BEFORE PRG_IO_Read

### Step 4.2 — Replace all time usage

Replace:
GVL_STATUS.G_System_Time_MS

With:
GVL_TIME_SERVICE.G_Now_MS

---

## PHASE 5 — PRG_System DECOMPOSITION

Do NOT refactor fully.

Only isolate:

- Time
- Health
- State aggregation

---

## PHASE 6 — COMMAND VERIFIER UPGRADE

Add:

- mismatch → alarm
- optional fail-safe reaction

---

## BACKLOG (DO NOT TOUCH NOW)

- Thermal model improvements
- Predictive enhancements
- Optimization tuning
- IO mapping cleanup
- Diagnostics redesign

---

## SUCCESS CRITERIA

System must:

- have single command pipeline
- have deterministic priority
- have active PLC control only
- have no IO bypass

---

END OF PLAN
