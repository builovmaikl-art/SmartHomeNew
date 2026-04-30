# HEATING — Final Architecture & Pending Items

Date: 2026-04-30

---

# 1. FINAL ARCHITECTURE

## Execution pipeline (current)

1. FB_Heating_Local_Context
2. FB_Heating_Thermal_Allocation
3. FB_Heating_Orchestration
4. FB_Heating_Diagnostics
5. FB_Heating_Maintenance_Gating
6. FB_Heating_Freeze_Hardware
7. FB_Heating_Adapter_CopyOut
8. FB_Heating_RootCause_Diagnostics

---

## Responsibility split

### Context layer
- FB_Heating_Local_Context

Responsibilities:
- safety projection (local)
- dhw demand preparation
- mode hold
- target temperature

---

### Decision layer
- FB_Heating_Thermal_Allocation

Responsibilities:
- priority calculation
- thermal allocation
- manifold enable decision

---

### Execution layer
- FB_Heating_Orchestration

Responsibilities:
- call heating manager
- call dhw manager
- apply allocation
- apply block
- write actuator proposal

---

### Post-processing
- Diagnostics
- Maintenance
- Freeze
- Adapter
- RootCause

---

# 2. COMMAND ARCHITECTURE

## Flow

INTENT → PRG_Command_Arbitration → GVL_COMMAND_SHADOW → PRG_Heating

---

## Current commands

- G_Heating_Block
- G_Heating_DHW_Block

---

## What is already correct

- heating no longer reads coordinator directly
- safety partially moved to command layer
- execution is separated from decision

---

# 3. CRITICAL BEHAVIOR (MUST NOT BREAK)

## DHW feedback delay

S1 reads:

GVL_STATE.G_DHW_Heating_Pump

S2 writes it later in the same cycle

Meaning:

→ previous-cycle dependency

This MUST be preserved.

---

# 4. REMAINING PROBLEMS (REAL ONES)

## 4.1 DHW block duplication

Currently:

- Local context blocks DHW
- Arbitration also blocks DHW

Problem:

→ duplicated responsibility

Target:

→ only command layer decides

---

## 4.2 Safety split

Currently:

- Part in Local Context
- Part in Arbitration

Problem:

→ inconsistent authority

---

## 4.3 Orchestration is still "fat"

FB_Heating_Orchestration:
- execution
- override
- partial decision

---

## 4.4 GVL coupling still present

Execution still writes directly into:

GVL_STATE

---

# 5. NEXT STEPS (STRICT ORDER)

## STEP 1 — unify DHW block

- remove DHW block from Local Context
- use G_Heating_DHW_Block only

---

## STEP 2 — finalize safety in command layer

- move Emergency/Gas logic into arbitration fully
- Local Context becomes passive

---

## STEP 3 — slim orchestration

Split FB_Heating_Orchestration into:

- Execution core (manager calls)
- Override layer

---

## STEP 4 — prepare IO layer for commands

Allow command override over state:

COMMAND > STATE

---

## STEP 5 — remove legacy GVL dependencies

Gradual replacement:

STATE → structured outputs

---

# 6. WHAT WE DO NOT TOUCH YET

- Test scenarios
- IO refactor
- full removal of GVL

---

# 7. STATUS

System is now:

- decomposed
- structured
- command-driven (partial)

Not yet:

- fully deterministic
- fully decoupled

---

# FINAL NOTE

System reached architectural transition point.

Further work is NOT refactoring.

It is SYSTEM DESIGN.
