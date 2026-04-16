# FB INVENTORY AUDIT — BATCH 03

Status: Confirmed audit of core logic and rule engine
Purpose: Continue Stage 0 inventory with verified findings

---

## 1. FB_State_Manager

Review status: REVIEWED
Primary role: State (impure)

Current reality:
- computes system mode (correct responsibility)
- BUT consumes mixed inputs:
  - direct latched inputs (Smoke/Leak/Gas)
  - raw faults (Sensor_Fault, IO_Fault...)
  - duplicated "Health_*" inputs
  - uses VI_Current_State (already aggregated alarms)

Confirmed violations:
- ❌ multiple sources of truth
- ❌ consumes non-Health inputs
- ❌ depends on VI_Current_State (should not exist in this role)
- ❌ mixes legacy and new architecture simultaneously

Architecture conflict:
- must use ONLY FB_System_Health outputs

Disposition:
- Rewrite (critical)

Required follow-up:
- remove all non-health inputs
- define strict Health → State contract
- remove VI_Current_State dependency

---

## 2. FB_Rule_Engine

Review status: REVIEWED
Primary role: Policy (dangerous)

Current reality:
- reads RAW sensor data directly:
  - smoke
  - gas
  - CO
  - water
- evaluates conditions
- produces actions

Confirmed violations:
- ❌ direct access to sensors (bypasses Detector layer)
- ❌ can react to safety conditions directly
- ❌ no system mode awareness
- ❌ potential bypass of Policy layer separation

Architecture conflict:
- Rule engine must NOT evaluate raw safety signals
- must operate on safe abstractions / policy inputs

Disposition:
- Rewrite / Restrict

Required follow-up:
- remove direct sensor access for safety signals
- restrict to non-safety automation OR
- force dependency on Health/State

---

## 3. Global pattern confirmed

Across all reviewed batches:

1. Multiple sources of truth exist
2. Safety logic duplicated in many places
3. Rule engine bypasses architecture
4. State manager is partially migrated but not clean

---

## 4. Critical conclusion (Stage 0)

The system is currently in a transitional inconsistent state:

- new architecture defined in docs
- partial migration in State_Manager
- legacy logic still active in subsystems

This creates:
- race conditions
- conflicting decisions
- undefined behavior in edge cases

---

## 5. Updated risk ranking

Critical blocks (must be fixed first):
1. FB_System_Health (missing)
2. FB_State_Manager
3. FB_Gas_Smoke_Manager
4. FB_Water_Leakage_Manager

High-risk blocks:
5. FB_Rule_Engine
6. Valve controllers

---

## 6. Next audit targets

Continue with:
- FB_Scenario_Manager
- FB_Security_System_Manager
- FB_Heating_System_Manager
- FB_Ventilation_System_Manager

---

End of batch 03
