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

## Heating Root-Cause Diagnostics

FB_Heating_RootCause_Diagnostics has been rewritten from an extracted prototype into a read-only diagnostics observer.

Current role:
- pure diagnostics / explainability layer
- no control authority
- no output ownership
- reads safety, cascade and transport semantic state
- writes heating root-cause / confidence fields

Produces:
- G_Heating_RootCause
- G_Heating_RootConfidence
- G_Heating_Confidence
- G_Heating_Error_Score
- G_Heating_Confidence_Reason_Code
- G_Heating_Confidence_Reason_Text

Connected from:
- PRG_Heating

Integration point:
- after heating state/status publication
- before domain output projection

Status:
- VERIFIED LIVE
- diagnostics producer now exists
- not a disconnected orphan anymore

---

## Explainability Integration

PRG_Explainability now consumes heating root-cause outputs.

Current public explainability fields:
- GVL_EXPLAINABILITY.G_Heating_Why_Blocked
- GVL_EXPLAINABILITY.G_Reason_Chain_Full

Status:
- VERIFIED LIVE
- heating diagnostics are visible in explainability chain
- no runtime behavior change

---

## HMI Projection

GVL_HMI and PRG_HMI_Dashboard now expose:
- heating confidence
- heating root-cause reason text/code
- cascade semantic diagnostics
- OpenTherm semantic diagnostics
- heartbeat/command age telemetry
- adapter/error enum states

Status:
- VERIFIED LIVE
- operator-facing diagnostics available
- read-only projection only

---

# REMAINING ARCHITECTURAL BLOCKS

## GROUP A — ORCHESTRATION LAYER

Blocks:
- FB_Heating_Orchestration
- FB_Heating_Execution_Core
- FB_Heating_Override_Layer

Interpretation:
- alternative orchestration shell
- wrapper around current heating runtime
- candidate future replacement for oversized PRG_Heating

Current status:
- NOT runtime active
- partially valid architecture
- do NOT delete blindly
- do NOT integrate as-is
- requires redesign before integration

Decision:
- keep for future orchestration refactor review

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

## GROUP C — LEGACY ROOT-CAUSE CORE

Blocks:
- FB_Diagnostics_RootCause
- E_Heating_RootCause

Interpretation:
- older low-level root-cause inference block and enum
- enum is still live because FB_Heating_RootCause_Diagnostics uses E_Heating_RootCause
- FB_Diagnostics_RootCause is currently NOT required by live observer

Current status:
- E_Heating_RootCause is LIVE
- FB_Diagnostics_RootCause remains unresolved legacy diagnostic core

Decision:
- do NOT delete E_Heating_RootCause
- review FB_Diagnostics_RootCause separately after stabilization

---

## GROUP D — HEATING DIAGNOSTICS EXTRACTION

Block:
- FB_Heating_Diagnostics

Interpretation:
- extracted heating diagnostics candidate
- event/text diagnostics around service/freeze/subsystem degradation

Current status:
- NOT runtime active
- may overlap with newly live root-cause/explainability pipeline
- requires separate comparison before integration or deletion

Decision:
- keep for next audit pass

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

The heating architecture now has a live read-only explainability pipeline:
- OpenTherm transport observability
- boiler semantic status
- cascade semantic aggregate state
- heating root-cause diagnostics
- explainability chain integration
- HMI projection

The remaining unresolved items are architectural, not cosmetic.

---

# NEXT REVIEW TARGETS

Recommended next audit order:

1. FB_Diagnostics_RootCause
   - compare with live FB_Heating_RootCause_Diagnostics
   - decide whether to merge, rewrite, or delete

2. FB_Heating_Diagnostics
   - compare with current explainability/HMI pipeline
   - decide whether it adds event logging value or duplicates live diagnostics

3. Orchestration layer
   - FB_Heating_Orchestration
   - FB_Heating_Execution_Core
   - FB_Heating_Override_Layer

4. Thermal policy layer
   - FB_Heating_Decision_Context
   - FB_Heating_Thermal_Allocation

5. FB_State_Snapshot_Manager
   - decide future blackbox/snapshot architecture
