# FB USAGE AUDIT CURRENT

Date: 2026-05-06
Scope: blocks listed in `замечания.txt`

## Purpose

This audit checks whether the FB blocks listed in `замечания.txt` are actually part of the current runtime execution chain.

The visual colour/state in CODESYS is treated only as a warning signal. It is not proof that a block is unused.

A block is considered runtime-used only if it is reachable from:

```text
MAIN
  -> called PRG
     -> instantiated FB
        -> nested instantiated FB
```

## Important rule

No FB from this audit may be deleted only because it is grey/blue/inactive-looking in the CODESYS UI.

Allowed conclusions:

- `LIVE_DIRECT` — directly instantiated by a PRG called from `MAIN`.
- `LIVE_INDIRECT` — instantiated inside another live FB.
- `LEGACY_OR_ALTERNATIVE_CHAIN` — real FB exists and may represent an older/newer chain, but current `MAIN` path does not call it.
- `DIAGNOSTIC_OR_TEST_CANDIDATE` — diagnostic/test/support FB exists, but current runtime path was not confirmed.
- `ORPHAN_CANDIDATE` — only file/docs/snapshots found; no current live reference confirmed.
- `NEEDS_DEEPER_AUDIT` — current evidence is not sufficient for a safe decision.

Deletion is allowed only after:

1. Current-reference search.
2. Current `MAIN -> PRG -> FB` chain check.
3. Compile check after removal or isolation.
4. Runtime-regression checklist update.

## Current MAIN execution root

The current `MAIN.st` calls these major runtime PRGs:

```text
PRG_Time_Service
PRG_System_Init
PRG_Config_Manager
PRG_Config_Validation
PRG_Config_Versioning
PRG_System_Runtime_Base
PRG_PLC_Arbitration
PRG_IO_Read
PRG_Input_Processing
PRG_Mode_Manager
PRG_Presence_Manager
PRG_Safety
PRG_Safety_Operator
PRG_Safety_Shutdown
PRG_Safety_Recovery
PRG_System_Intent
PRG_Security
PRG_System_Access_Maintenance
PRG_User_Adapt_Control
PRG_Behavior_Adapt_Profile
PRG_Scenario_Engine
PRG_System_Scenario_Rules
PRG_System_Evacuation
PRG_Policy
PRG_Heating_Policy_Manager
PRG_Heating_Policy_Observer
PRG_System_Coordinator
PRG_Command_Arbitration
PRG_Modbus_Master
PRG_Modbus_RTU_Bridge
PRG_Modbus_RTU_Driver
PRG_Modbus_RTU_SysCom_Backend
PRG_Modbus_RTU_SysCom_Transport
PRG_Modbus_Register_Scan
PRG_OpenTherm_Transport
PRG_OpenTherm_Adapter_Status
PRG_Heating
PRG_Ventilation
PRG_Water
PRG_Access
PRG_Lighting
PRG_IO_Write
PRG_Command_Verifier
PRG_Explainability
PRG_System_Health
PRG_System_Alarm_Gateway
PRG_System_Diagnostics
PRG_System_Diagnostics_Ext
PRG_System_History
PRG_System_BlackBox
PRG_System_Trend
PRG_System_Simulation
PRG_HMI_Dashboard
PRG_Debug_View
```

## Confirmed live chains found during this pass

### Security

`MAIN -> PRG_Security -> FB_Security_System_Manager`

`FB_Security_System_Manager` internally uses:

```text
FB_AccessCode_Manager
FB_TwoFactor_Auth
FB_System_Timer
```

Therefore nested FBs inside this live security manager may be grey visually but still active.

### Heating

`MAIN -> PRG_Heating -> FB_Heating_System_Manager`

Current `PRG_Heating` directly instantiates:

```text
FB_Heating_System_Manager
FB_DHW_Manager
FB_Heating_Output_Projection
```

The newer/alternative heating split-chain blocks listed in `замечания.txt` were not confirmed as the active runtime path in this pass.

### Diagnostics / history / blackbox

Current live PRGs instantiate:

```text
PRG_System_Diagnostics -> FB_System_Diagnostics
PRG_System_Diagnostics -> FB_State_Trace_Log
PRG_System_Diagnostics -> FB_Behavior_Adapt
PRG_System_History -> FB_History_Manager
PRG_System_BlackBox -> FB_BlackBox_Recorder
```

The listed blocks `FB_Diagnostics_RootCause`, `FB_Trace_Logger`, `FB_State_Snapshot_Manager`, `FB_Test_Result_Handler` were not confirmed as live through these PRGs during this pass.

### Scenario

Current live scenario PRGs instantiate:

```text
PRG_System_Scenario_Rules -> FB_System_Scenario_Arbitration
PRG_System_Scenario_Rules -> FB_Rule_Engine
PRG_Scenario_Engine -> FB_Trace_Write
```

`FB_Scenario_Transition_Guard` was not confirmed as live through the current scenario path during this pass.

### Access maintenance

`MAIN -> PRG_System_Access_Maintenance -> FB_LogEvent`

`FB_Maintenance_Access` was not confirmed as live in the current maintenance path during this pass.

### Simulation

`MAIN -> PRG_System_Simulation -> FB_Simulation_Manager`

`MAIN -> PRG_System_Simulation -> FB_Presence_Playback`

`FB_Random_Generator` was not confirmed as directly live from this PRG during this pass.

## Audit table

| FB | Current status | Evidence / reasoning | Decision |
|---|---|---|---|
| FB_Astro_Timer | ORPHAN_CANDIDATE | File exists; previous audit already marked it likely dead; current runtime uses time service / `GVL_STATUS.G_Current_TOD` paths instead of direct `FB_Astro_Timer` call in checked PRGs. | Do not delete yet. Confirm no current references outside snapshots/docs. |
| FB_Calibration_Manager | ORPHAN_CANDIDATE | File/docs/snapshots found; no live `MAIN -> PRG -> FB_Calibration_Manager` path confirmed in this pass. | Candidate for isolation after reference search. |
| FB_CoreKernel_Live_Observer | NEEDS_DEEPER_AUDIT | Listed in remarks; no live chain confirmed during this pass. Kernel/core observers can be diagnostic support and should not be removed without checking core PRGs. | Open file and search exact references before decision. |
| FB_Diagnostics_RootCause | DIAGNOSTIC_OR_TEST_CANDIDATE | Current live diagnostics path uses `FB_System_Diagnostics`, `FB_State_Trace_Log`, `FB_Behavior_Adapt`; this block was not confirmed in live diagnostics path. | Review against `PRG_System_Health` and root-cause GVL before deletion. |
| FB_FloorHeating_Freeze_Protection | LEGACY_OR_ALTERNATIVE_CHAIN | Current `PRG_Heating` delegates to `FB_Heating_System_Manager`; no direct live use confirmed. Function may be absorbed by current heating manager / safety logic. | Compare with active freeze protection in `FB_Heating_System_Manager` before deleting. |
| FB_FloorHeating_Overheat_Protection | LEGACY_OR_ALTERNATIVE_CHAIN | Current `PRG_Heating` delegates to `FB_Heating_System_Manager`; no direct live use confirmed. | Compare with active overheat limits before deleting. |
| FB_Heating_Adapter_CopyOut | LEGACY_OR_ALTERNATIVE_CHAIN | Current `PRG_Heating` performs copy-out directly to `GVL_STATE` and uses `FB_Heating_Output_Projection`; no live adapter copy-out FB confirmed. | Likely replaced by current `PRG_Heating` copy-out and projection. Confirm before isolation. |
| FB_Heating_Decision_Context | LEGACY_OR_ALTERNATIVE_CHAIN | Part of newer split heating architecture naming, but current live path uses `FB_Heating_System_Manager`. | Keep as candidate for future split architecture, not active runtime. |
| FB_Heating_Diagnostics | LEGACY_OR_ALTERNATIVE_CHAIN | Current live diagnostics/status in `PRG_Heating` writes `GVL_STATUS.G_Diagnostics` and status structs; no direct live `FB_Heating_Diagnostics` confirmed. | Compare with current diagnostics fields before deleting. |
| FB_Heating_Execution_Core | LEGACY_OR_ALTERNATIVE_CHAIN | Search found the FB and relation to `FB_Heating_Orchestration`, but current `PRG_Heating` does not instantiate orchestration/core; it instantiates `FB_Heating_System_Manager`. | Alternative chain. Do not delete until heating architecture decision. |
| FB_Heating_Freeze_Hardware | LEGACY_OR_ALTERNATIVE_CHAIN | Current freeze hardware gating is implemented in `PRG_Heating` with backup pump/electric heater service checks; no live FB confirmed. | Compare behavior before removal. |
| FB_Heating_Local_Context | LEGACY_OR_ALTERNATIVE_CHAIN | Split architecture naming; no current live path confirmed from `PRG_Heating`. | Keep only if planned orchestration-chain migration. |
| FB_Heating_Maintenance_Gating | LEGACY_OR_ALTERNATIVE_CHAIN | Current maintenance gating is implemented directly in `PRG_Heating`; no live FB confirmed. | Candidate for replacement/isolation after behavior diff. |
| FB_Heating_Orchestration | LEGACY_OR_ALTERNATIVE_CHAIN | File exists and references split heating chain, but current runtime path is `PRG_Heating -> FB_Heating_System_Manager`. | Architecture decision required: migrate to orchestration chain or archive it. |
| FB_Heating_Override_Layer | LEGACY_OR_ALTERNATIVE_CHAIN | Split-chain naming; no current live path confirmed. | Needs behavior comparison before deletion. |
| FB_Heating_RootCause_Diagnostics | LEGACY_OR_ALTERNATIVE_CHAIN | No current live path confirmed; may overlap with system health/root cause. | Check against `PRG_System_Health` before decision. |
| FB_Heating_Thermal_Allocation | LEGACY_OR_ALTERNATIVE_CHAIN | Current allocation appears inside `FB_Heating_System_Manager`; no direct live path confirmed. | Candidate for future extraction or archive. |
| FB_Lifetime_Manager | DIAGNOSTIC_OR_TEST_CANDIDATE | No live chain confirmed during this pass. May overlap with predictive/lifetime diagnostics. | Needs file-level audit before any action. |
| FB_Maintenance_Access | ORPHAN_CANDIDATE | Current live access maintenance path is `PRG_System_Access_Maintenance -> FB_LogEvent`; no live use of `FB_Maintenance_Access` confirmed. | Candidate for archive after comparison. |
| FB_Persist_Builder | NEEDS_DEEPER_AUDIT | Previous inventory audit says keep with constraints, but current `PRG_System_Runtime_Base` uses `FB_System_Persist_Manager`; direct live use of `FB_Persist_Builder` was not confirmed in this pass. | Must inspect `FB_System_Persist_Manager` before classification. |
| FB_Persist_Pipeline | NEEDS_DEEPER_AUDIT | Previous inventory audit says keep, but direct live use was not confirmed from checked PRGs. | Must inspect `FB_System_Persist_Manager` before classification. |
| FB_Random_Generator | NEEDS_DEEPER_AUDIT | Current simulation path uses `FB_Simulation_Manager` and `FB_Presence_Playback`; direct use was not confirmed from `PRG_System_Simulation`. | Search inside simulation/playback FBs before decision. |
| FB_Scenario_Transition_Guard | ORPHAN_CANDIDATE | Current scenario path uses `FB_System_Scenario_Arbitration`, `FB_Rule_Engine`, `FB_Trace_Write`; no live transition guard confirmed. | Candidate for archive after scenario behavior comparison. |
| FB_Sensor_Calibration | NEEDS_DEEPER_AUDIT | Sensor calibration pipeline exists in config/state, but no direct live path confirmed during this pass. | Check `PRG_Input_Processing`, calibration PRGs/FBs before decision. |
| FB_Smoke_Detector | NEEDS_DEEPER_AUDIT | Previous inventory audit marks it reviewed with architectural violation, not safe deletion. Current live safety/fire path was not fully traced in this pass. | Must audit `PRG_Safety`, fire/smoke manager chain before action. |
| FB_State_Snapshot_Manager | DIAGNOSTIC_OR_TEST_CANDIDATE | Current runtime base uses `FB_System_Init`, `FB_System_Recovery`, `FB_System_Persist_Manager`, `FB_System_Redundancy_Orchestrator`; no direct snapshot manager confirmed. | Check nested system persistence/redundancy FBs before action. |
| FB_Test_Result_Handler | DIAGNOSTIC_OR_TEST_CANDIDATE | Current simulation PRG writes test state directly; no live handler confirmed. | Candidate test harness block; do not delete until simulation report flow is checked. |
| FB_Trace_Logger | DIAGNOSTIC_OR_TEST_CANDIDATE | Current scenario path uses `FB_Trace_Write`, diagnostics uses `FB_State_Trace_Log`; no direct `FB_Trace_Logger` confirmed. | Candidate for archive/merge after trace subsystem review. |

## Summary

The statement from `замечания.txt` is partly fair:

- several listed FBs are not confirmed in the active runtime chain;
- however, visual CODESYS colouring alone is not a safe proof;
- some FBs are alternative architecture blocks, not simple dead code;
- some FBs were previously marked as keep/needs audit and must not be deleted automatically.

## Safe next step

Recommended next stage:

1. Create a second-pass exact-reference checklist for all `ORPHAN_CANDIDATE` and `LEGACY_OR_ALTERNATIVE_CHAIN` rows.
2. For each deletion/isolation candidate, search current root files only, excluding `docs/`, `snapshots/`, `migration_logs/`, `компилятор/logs/`.
3. Move candidates to an archive namespace or folder only after compile check.
4. Do not delete heating split-chain FBs until deciding whether to migrate from `FB_Heating_System_Manager` to `FB_Heating_Orchestration` architecture.

## No-action list until deeper audit

These blocks must not be deleted in the first cleanup pass:

```text
FB_Persist_Builder
FB_Persist_Pipeline
FB_Smoke_Detector
FB_Sensor_Calibration
FB_State_Snapshot_Manager
FB_Random_Generator
```

Reason: each may be indirect, diagnostic, migration-related, or previously marked as requiring deeper audit.
