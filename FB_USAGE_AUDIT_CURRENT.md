# FB_USAGE_AUDIT_CURRENT.md

## Status

This document reflects the CURRENT runtime state after live verification against:
- MAIN execution chain
- active PRG calls
- active FB instantiations
- IO pipeline
- diagnostics pipeline
- persistence pipeline

The audit intentionally ignores:
- snapshots/
- archive logs
- export sandboxes
- historical XML exports
- disconnected test harnesses

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

# REMAINING BLOCKS

## GROUP A — HEATING SPLIT ARCHITECTURE

This group is NOT dead garbage.

It is a partially disconnected alternative orchestration architecture extracted from PRG_Heating.

Current live runtime path:
- PRG_Heating
- FB_Heating_System_Manager
- FB_DHW_Manager
- FB_Heating_Output_Projection

The following remaining blocks are architectural candidates and MUST NOT be blindly deleted.

### ORCHESTRATION LAYER

- FB_Heating_Orchestration
- FB_Heating_Execution_Core
- FB_Heating_Override_Layer

Interpretation:
- alternative orchestration shell
- wrapper around current heating runtime
- disconnected from MAIN
- candidate future replacement for oversized PRG_Heating

Current status:
- NOT runtime active
- partially valid architecture
- requires redesign before integration

---

### THERMAL POLICY / ALLOCATION LAYER

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

---

### HEATING DIAGNOSTICS EXTRACTION

- FB_Heating_Diagnostics
- FB_Heating_RootCause_Diagnostics
- FB_Diagnostics_RootCause
- E_Heating_RootCause

Interpretation:
- unfinished heating explainability subsystem
- heating-specific root cause analysis
- freeze hardware diagnostics
- manifold demand explanation
- boiler/offline/no-transfer inference

Current status:
- disconnected from MAIN
- NOT production ready
- NOT synchronized with current OpenTherm/DHW architecture
- architecturally valuable

Important:
FB_Heating_RootCause_Diagnostics already integrates:
- FB_Diagnostics_RootCause
- FB_Heating_Demand_Map
- G_Heating_RootCause
- G_Heating_RootConfidence

This is NOT a random orphan FB.

Required future decision:
- either evolve into full heating explainability subsystem
OR
- remove entire diagnostics branch together

---

### REMOVED WEAK EXTRACTION FRAGMENTS

The following blocks were reviewed and intentionally removed because they were weak extracted fragments rather than viable architecture:

- FB_Heating_Adapter_CopyOut
- FB_Heating_Maintenance_Gating
- FB_Heating_Freeze_Hardware
- FB_Heating_Local_Context

Reasons:
- duplicated runtime logic
- direct GVL mutation
- weak abstraction boundaries
- incomplete extraction
- unsafe integration semantics
- inferior to current PRG_Heating implementation

---

## GROUP B — SNAPSHOT / BLACKBOX PROTOTYPE

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

# CURRENT CLEANUP RESULT

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

The remaining unresolved items are now mostly architectural, not cosmetic.

---

# IMPORTANT REPOSITORY RULE

NO PARTIAL FILE PATCHING.

All future file modifications must:
- fully rewrite the file
- from first line to last line
- with complete regenerated content

Reason:
partial edits corrupt repository structure and break internal consistency.
