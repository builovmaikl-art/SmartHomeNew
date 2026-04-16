# FB INVENTORY AUDIT — BATCH 02

Status: Confirmed review findings from actual code reading
Purpose: Preserve ongoing Stage 0 audit progress in step-by-step form
Related:
- `docs/FB_INVENTORY_AUDIT.md`
- `docs/REFACTOR_PLAN_ARCH_ALIGNMENT.md`
- `AGENTS.md`

---

## Reviewed blocks in this batch

### 1. `FB_CO_Detector`
Review status: `REVIEWED`
Primary role: `Detector`
Current reality:
- compares CO level against warning/alarm thresholds
- emits `VO_Warning_Active`
- emits `VO_Alarm_Active`

Confirmed violations:
- local warning ownership inside detector
- local alarm ownership inside detector
- health qualification is not centralized

Disposition:
- `Split / Rewrite`

Required follow-up:
- reduce block to signal/level output only
- move warning/alarm qualification to `FB_System_Health`

---

### 2. `FB_Gas_Smoke_Manager`
Review status: `REVIEWED`
Primary role: `Mixed legacy block`
Current reality:
- aggregates methane, CO, and smoke sensors
- contains threshold logic
- contains hysteresis logic
- contains timer-based health qualification
- directly issues gas valve close command
- directly issues boiler stop command
- directly issues ventilation requests/stops
- directly controls siren behavior and mute handling
- emits global gas/fire alarm outputs

Confirmed violations:
- Detector + Health + Policy + Actuation merged in one block
- direct safety actuation from subsystem block
- local global alarm ownership
- local warning/alarm timing and qualification
- direct mode-bypass behavior through outputs

Disposition:
- `Split / Rewrite`

Required follow-up:
- extract detector-level methane/CO/smoke inputs
- move qualification to `FB_System_Health`
- move behavior decisions to explicit Policy layer
- keep actuator execution outside this block
- review mute/siren handling as separate policy/service concern

---

### 3. `FB_Water_Valve_Controller`
Review status: `REVIEWED`
Primary role: `Actuator (impure)`
Current reality:
- exposes valve open/close methods
- also closes valve directly from `VI_Flood_Alarm`
- stores user-facing status string

Confirmed violations:
- actuator contains policy shortcut (`VI_Flood_Alarm` directly drives closure)
- actuator is not command-only
- flood reaction path bypasses explicit Policy layer

Disposition:
- `Keep with constraints / Rewrite`

Required follow-up:
- remove direct alarm-driven closure from actuator internals
- make command input explicit
- keep only execution + feedback responsibilities

---

### 4. `FB_Gas_Valve_Controller`
Review status: `REVIEWED`
Primary role: `Actuator (impure)`
Current reality:
- exposes valve open/close methods
- also closes valve directly from `VI_Gas_Alarm`
- stores user-facing status string

Confirmed violations:
- actuator contains policy shortcut (`VI_Gas_Alarm` directly drives closure)
- actuator is not command-only
- gas reaction path bypasses explicit Policy layer

Disposition:
- `Keep with constraints / Rewrite`

Required follow-up:
- remove direct alarm-driven closure from actuator internals
- convert to command-execution block only
- route execution faults/feedback separately

---

## Updated priority queue after Batch 02

Next review order:
1. `FB_State_Manager`
2. `FB_Rule_Engine`
3. `FB_Scenario_Manager`
4. `FB_Security_System_Manager`
5. `FB_Heating_System_Manager`
6. `FB_Ventilation_System_Manager`
7. `FB_Emergency_Valve_Open`
8. `FB_Manual_Valve_Control`
9. `FB_FloorHeating_Controller`
10. `FB_Supply_Ventilation_Controller`

---

## Temporary deletion-watch list

Not deletion-approved yet, but marked as high-risk architecture-bypass candidates:
- `FB_Gas_Smoke_Manager`
- current form of `FB_Water_Leakage_Manager`
- detector blocks that emit global alarm ownership
- actuator blocks that react directly to alarm inputs

---

## Stage 0 progress note

Confirmed pattern across reviewed safety-related code:
- detector and manager blocks often own warning/alarm qualification
- subsystem blocks directly command actuators
- actuator blocks contain policy shortcuts
- implementation remains ahead-of-docs misaligned with target architecture

This confirms the need to continue Stage 0 before any large code refactor.

---

End of batch 02.
