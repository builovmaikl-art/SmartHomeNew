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

## Removed PRG

- PRG_System_Test_Harness

## Removed DUT / ENUM

- ST_Persist
- E_SCENARIO_TYPE

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

# REMAINING BLOCKS

## GROUP A — HEATING SPLIT ARCHITECTURE (DO NOT DELETE)

These blocks are NOT simple garbage.

They represent a partially disconnected alternative orchestration architecture.

Current live heating path:
- PRG_Heating
- FB_Heating_System_Manager

Alternative disconnected chain:
- FB_Heating_Orchestration
- FB_Heating_Execution_Core
- FB_Heating_Override_Layer
- FB_Heating_Decision_Context
- FB_Heating_Local_Context
- FB_Heating_Thermal_Allocation
- FB_Heating_Maintenance_Gating
- FB_Heating_Adapter_CopyOut
- FB_Heating_Diagnostics
- FB_Heating_RootCause_Diagnostics
- FB_Heating_Freeze_Hardware

Status:
- NOT runtime active
- NOT safe to delete blindly
- requires architectural decision

Required future decision:
- migrate to orchestration architecture
OR
- fully remove split-chain

---

## GROUP B — DIAGNOSTICS / HEALTH / OBSERVER

Requires deeper audit.

Blocks:
- FB_CoreKernel_Live_Observer
- FB_Diagnostics_RootCause
- FB_Lifetime_Manager
- FB_Smoke_Detector

Status:
- unresolved
- possible dormant diagnostics architecture
- possible legacy detectors

Deletion currently NOT approved.

---

## GROUP C — SNAPSHOT / BLACKBOX PROTOTYPE

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
