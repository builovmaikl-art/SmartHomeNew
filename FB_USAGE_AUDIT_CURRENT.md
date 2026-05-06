# FB_USAGE_AUDIT_CURRENT.md

## Status

This document reflects the CURRENT runtime state after live verification against:
- MAIN execution chain
- active PRG calls
- active FB instantiations
- IO pipeline
- diagnostics pipeline
- persistence pipeline
- OpenTherm adapter pipeline
- heating explainability pipeline
- HMI projection pipeline

The audit intentionally ignores:
- snapshots/
- archive logs
- export sandboxes
- historical XML exports
- disconnected test harnesses

---

# REPOSITORY EDITING RULE

NO PARTIAL FILE PATCHING.

All future file modifications must:
- fully rewrite the file
- from first line to last line
- with complete regenerated content

Reason:
partial edits corrupt repository structure and break internal consistency.

---

# REMOVED DURING CLEANUP

The following blocks were verified as orphaned / disconnected / replaced and were removed.

## Removed FB

- FB_Astro_Timer
- FB_Calibration_Manager
- FB_Maintenance_Access
- FB_Random_Generator
- FB_Trace_Logger
- FB_Test_Result_Handler
- FB_Persist_Builder
- FB_Persist_Pipeline
- FB_Scenario_Transition_Guard
- FB_Sensor_Calibration
- FB_CoreKernel_Live_Observer
- FB_Smoke_Detector
- FB_Lifetime_Manager
- FB_Heating_Adapter_CopyOut
- FB_Heating_Maintenance_Gating
- FB_Heating_Freeze_Hardware
- FB_Heating_Local_Context

## Removed PRG

- PRG_System_Test_Harness

## Removed DUT / ENUM

- ST_Persist
- E_SCENARIO_TYPE
- ST_Lifetime_Status

---

# VERIFIED REPLACEMENTS

## Calibration

Legacy calibration chain removed.

Current live implementation:
- FB_Sensor_Calibration_Processor
- integrated directly inside PRG_IO_Read

Status:
- VERIFIED LIVE
- replacement confirmed

---

## Persistence

Legacy persistence pipeline removed.

Current live implementation:
- FB_System_Persist_Manager
- FB_NVRAM_Manager

Status:
- VERIFIED LIVE
- replacement confirmed

---

## Scenario Engine

Transition guard architecture removed.

Current live implementation:
- PRG_Scenario_Engine
- scoring/intent based logic

Status:
- VERIFIED LIVE
- enum-state transition model abandoned

---

## Smoke / Gas Handling

Legacy smoke detector removed.

Current live implementation:
- FB_Gas_Smoke_Manager

Status:
- VERIFIED LIVE
- replacement confirmed

---

# CURRENT HEATING / OPENTHERM ARCHITECTURE STATUS

## Live Runtime Path

Current active heating path:
- PRG_Heating
- FB_DHW_Manager
- FB_Heating_System_Manager
- FB_Heating_Boiler_Control
- FB_Boiler_Cascade_Manager
- FB_Boiler_OpenTherm_Interface
- FB_Heating_Output_Projection

Status:
- VERIFIED LIVE
- heating control behavior preserved
- diagnostics/explainability added as read-only projection

Critical runtime ordering:
1. DHW manager executes FIRST
2. heating manager executes SECOND
3. diagnostics/explainability executes AFTER state publication
4. output projection executes LAST

This ordering is now considered part of the live runtime contract.

---

## OpenTherm Transport Observability

Implemented and live:
- stable command sequence semantics in FB_Boiler_OpenTherm_Interface
- command sequence increments only on actual command image change
- adapter ACK validation is now stable across PLC cycles
- heartbeat age telemetry
- command age telemetry
- last ACK sequence telemetry
- semantic adapter state
- semantic adapter error state

Public state now available through GVL_STATE:
- G_Boiler_OT_Online
- G_Boiler_OT_Command_Ack
- G_Boiler_OT_Command_Timeout
- G_Boiler_OT_Heartbeat_Timeout
- G_Boiler_OT_Adapter_Error
- G_Boiler_OT_Heartbeat_Age_MS
- G_Boiler_OT_Command_Age_MS
- G_Boiler_OT_Adapter_State
- G_Boiler_OT_Error_State

Status:
- VERIFIED LIVE
- read-only observability boundary created
- no change to control authority

---

## Boiler Setpoint Semantics

Boiler setpoint is now treated as primary-circuit heat-carrier target.

Important physical interpretation:
- boilers heat the primary circuit
- consumer-side limiting is owned downstream
- floor heating regulation belongs to manifolds / mixing layer
- DHW regulation belongs to the DHW heat exchanger / DHW subsystem

Status:
- primary-circuit setpoint semantics corrected
- old universal 55C clamp no longer treated as consumer protection
- process control intent preserved

---

## Boiler Semantic Status

ST_Boiler_Status now includes diagnostic semantics:
- OT_Online
- OT_Command_Valid
- OT_Transport_Degraded
- OT_Adapter_Error
- Available
- Selected_By_Cascade
- Flame_Missing
- Transport_Missing
- Ignition_Timeout
- Degraded

Status:
- VERIFIED LIVE through FB_Heating_Boiler_Control
- no change to cascade selection behavior
- diagnostic-only semantics

---

## Cascade Semantic Aggregate State

Implemented and live in GVL_STATE:
- G_Heating_Cascade_Available
- G_Heating_Cascade_Degraded
- G_Heating_Cascade_Partial_Capacity
- G_Heating_Cascade_No_Flame
- G_Heating_Cascade_Transport_Degraded
- G_Heating_Cascade_Ignition_Timeout
- G_Heating_Cascade_Active_Boilers
- G_Heating_Cascade_Available_Boilers

Status:
- VERIFIED LIVE through FB_Heating_Boiler_Control
- aggregate diagnostics only
- no change to cascade runtime decisions

---

## Heating Diagnostics Layering

Current diagnostics architecture is now layered.

### Layer 1 — Semantic Runtime State

Produced by:
- FB_Boiler_OpenTherm_Interface
- FB_Heating_Boiler_Control

Purpose:
- transport semantics
- boiler semantics
- cascade semantics

Ownership:
- runtime state only

---

### Layer 2 — Inference Engine

Block:
- FB_Diagnostics_RootCause

Purpose:
- hydraulic reasoning
- thermal transfer reasoning
- OpenTherm transport reasoning
- cascade inference

Ownership:
- inference only
- NO explainability publication
- NO runtime authority

---

### Layer 3 — Explainability Observer

Block:
- FB_Heating_RootCause_Diagnostics

Purpose:
- state collection
- demand map generation
- explainability publication
- confidence publication

Ownership:
- public diagnostics projection only

---

### Layer 4 — Event Projection

Block:
- FB_Heating_Diagnostics

Purpose:
- service events
- out-of-service events
- freeze hardware event projection

Ownership:
- diagnostics event stream only

---

### Layer 5 — Explainability / HMI

Blocks:
- PRG_Explainability
- PRG_HMI_Dashboard

Purpose:
- operator projection
- reason chain publication
- HMI diagnostics projection

Ownership:
- presentation only

---

# REMAINING ARCHITECTURAL BLOCKS

## GROUP A — ORCHESTRATION LAYER

Blocks:
- FB_Heating_Orchestration
- FB_Heating_Execution_Core
- FB_Heating_Override_Layer

Interpretation:
- obsolete orchestration prototype
- older attempt to split oversized PRG_Heating
- not synchronized with current live runtime semantics

Current status:
- NOT runtime active
- NOT equivalent to live runtime
- requires full redesign before ANY integration
- unsafe to connect directly

---

### VERIFIED DESIGN MISMATCHES

#### Execution ordering mismatch

Current live runtime contract:
1. DHW first
2. Heating second
3. Diagnostics after state publication
4. Output projection last

FB_Heating_Execution_Core violates this contract:
- heating manager executes BEFORE DHW manager
- diagnostics layer absent
- explainability layer absent
- HMI projection absent

Result:
- non-equivalent cascade demand semantics
- DHW demand timing mismatch
- possible incorrect boiler arbitration

Status:
- redesign required

---

#### Override ownership conflict

FB_Heating_Override_Layer currently overrides:
- zone valves
- manifold pumps
- manifold valves
- boiler enable/setpoints
- backup circulation pump
- electric heater
- DHW heating pump
- DHW circulation pump

Risks:
- conflicts with freeze ownership
- conflicts with gas safety semantics
- conflicts with service-mode semantics
- conflicts with DHW circulation policy
- conflicts with diagnostics assumptions

Current block has:
- no semantic awareness
- no diagnostics awareness
- no explainability awareness
- no safety-priority arbitration

Status:
- HIGH RISK
- redesign mandatory before reuse

---

### ORCHESTRATION REDESIGN DEPENDENCY MAP

Future orchestration redesign MUST preserve ownership boundaries.

#### Runtime ownership

Owned by:
- PRG_Heating
- FB_DHW_Manager
- FB_Heating_System_Manager
- FB_Heating_Boiler_Control

Must remain runtime-authoritative.

---

#### Diagnostics ownership

Owned by:
- FB_Diagnostics_RootCause
- FB_Heating_RootCause_Diagnostics
- FB_Heating_Diagnostics

Must remain read-only.

---

#### Explainability ownership

Owned by:
- PRG_Explainability
- PRG_HMI_Dashboard

Must remain downstream-only.

---

#### Safety ownership

Owned by:
- gas safety chain
- freeze protection chain
- emergency stop chain

Must NEVER be bypassed by orchestration wrappers.

---

### REQUIRED FUTURE ORCHESTRATION MODEL

Future orchestration redesign must become:
- coordinator only
- sequencing layer only
- ownership router only

It must NOT:
- infer diagnostics
- directly override safety
- publish explainability
- duplicate runtime logic
- duplicate cascade logic

---

### CURRENT DECISION

Do NOT:
- integrate orchestration layer
- connect override layer
- migrate runtime into orchestration wrappers
- split PRG_Heating blindly

Allowed next step:
- future controlled extraction only
- after explicit redesign plan

---

## GROUP B — THERMAL POLICY / ALLOCATION LAYER

Blocks:
- FB_Heating_Decision_Context
- FB_Heating_Thermal_Allocation

Interpretation:
- thermal allocation policy prototype
- manifold prioritization logic
- thermal budget distribution
- guest preheat policy seed
- degraded heating allocation model

Current status:
- NOT runtime active
- logic quality acceptable
- possible future extraction candidate

Decision:
- keep for future policy-layer review

---

## GROUP E — SNAPSHOT / BLACKBOX PROTOTYPE

Block:
- FB_State_Snapshot_Manager

Status:
- NOT runtime active
- NOT integrated into MAIN
- NOT integrated into persistence
- NOT integrated into diagnostics
- NOT integrated into recovery
- NOT integrated into trace/history

Interpretation:
- dormant architectural prototype
- unfinished blackbox subsystem seed

Decision:
- KEEP VISIBLE IN ROOT
- do NOT archive
- do NOT integrate yet
- revisit later

Reason:
The block intentionally remains visible to force future architectural review.

---

# CURRENT CLEANUP / ARCHITECTURE RESULT

The repository has already been cleaned from:
- disconnected utility FBs
- dead test harnesses
- abandoned persistence branches
- abandoned transition guards
- duplicated calibration paths
- orphan DUT/ENUM structures
- weak heating extraction fragments
- disconnected observer placeholders
- disconnected legacy detectors

The heating architecture now has a live layered diagnostics/explainability stack:
- OpenTherm transport observability
- boiler semantic status
- cascade semantic aggregate state
- inference engine
- explainability observer
- diagnostics event projection
- explainability chain integration
- HMI projection

The remaining unresolved items are architectural, not cosmetic.

---

# NEXT REVIEW TARGETS

Recommended next audit order:

1. Thermal policy layer
   - FB_Heating_Decision_Context
   - FB_Heating_Thermal_Allocation

2. Future orchestration redesign planning
   - controlled extraction boundaries
   - ownership routing
   - sequencing model

3. FB_State_Snapshot_Manager
   - decide future blackbox/snapshot architecture
