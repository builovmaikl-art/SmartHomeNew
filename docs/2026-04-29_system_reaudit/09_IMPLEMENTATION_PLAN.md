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

## STEP STATUS REGISTER

### Step 1.1 — Policy → Arbitration wiring

Status: CLEAN

Result:

- `GVL_INTENT_POLICY.gvl` created
- `PRG_Command_Arbitration` references policy intent placeholders
- No behavior change introduced

---

### Step 1.2 — Remove IO → Command direct writes

Status: CLEAN WITH DOCUMENTED TEMPORARY EXCEPTION

Result:

- Direct `GVL_COMMAND.*` writes removed from `PRG_IO_Read`
- `EXC-01` remains: manifold pumps are still disabled via `GVL_STATE` during Phase 1

---

### Step 1.3 — Enforce single command path

Status: PARTIAL / WITH TAILS

Observed residual direct/legacy command layer usage:

- `PRG_Security.st`
- `PRG_System.st`
- `PRG_Command_Verifier.st` (read-only comparison, allowed for now)

Decision:

- Do NOT mass-refactor in Step 1.3
- Keep residuals documented
- Address them through priority model and later decomposition steps

---

## TEMPORARY EXCEPTIONS (DOCUMENTED)

### EXC-01 — Manifold pumps via GVL_STATE (temporary)

Current behavior:

PRG_IO_Read disables manifold pumps via:

GVL_STATE.G_Manifold_Pumps := FALSE

Status:

✔ Allowed TEMPORARILY during Phase 1

Reason:

- IO → Command path removed (Step 1.2)
- arbitration pipeline not yet fully closed

Constraint:

- MUST be removed after command path is fully closed
- MUST be replaced by Intent → Arbitration → Shadow path

---

### EXC-02 — PRG_System overload (deferred)

Current behavior:

`PRG_System` is overloaded and still contains mixed responsibilities:

- orchestration
- persistence
- gateway intent
- dangerous action confirmation
- maintenance handling
- logging/history
- parts of command/access logic

Status:

✔ Deferred intentionally

Reason:

- PRG_System decomposition is Phase 5
- Refactoring it during Phase 1/2 would violate strict sequencing

Constraint:

- Do NOT refactor `PRG_System` before Phase 5
- During earlier phases, only touch `PRG_System` if required to close a specific planned step

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

Status:

PARTIAL / WITH TAILS

Tails are documented in Step Status Register.

---

## PHASE 2 — PRIORITY MODEL

### Step 2.1 — Define priority

Status: DEFINED

Canonical command priority:

1. Safety
2. System
3. Policy
4. User

Meaning:

- Safety can override every other source
- System can override Policy/User but not Safety
- Policy can override User but not Safety/System
- User is accepted only when not blocked by higher layers

Conflict rule:

Higher-priority TRUE wins for protective commands.
For permissive/open commands, higher-priority BLOCK wins.

Examples:

- Safety gas close beats any user/gateway open or normal state
- Safety vent stop beats policy ventilation request
- System degraded mode can reduce outputs even if policy requests comfort
- User gate/lock requests are ignored if Safety/System blocks them

Allowed implementation target:

`PRG_Command_Arbitration.st`

Not allowed in Step 2.1:

- No code behavior changes
- No IO changes
- No PRG_System decomposition

---

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
- Full PRG_System decomposition beyond Phase 5 scope

---

## SUCCESS CRITERIA

System must:

- have single command pipeline
- have deterministic priority
- have active PLC control only
- have no undocumented IO bypass

---

END OF PLAN
