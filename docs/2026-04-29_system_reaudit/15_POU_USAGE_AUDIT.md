# POU Usage Audit Before Scenario Runtime Tests

Date: 2026-04-30

## Purpose

Before runtime scenario testing, classify POU objects into:

1. Executed directly from MAIN.
2. Used indirectly by executed PRGs/FBs.
3. Test/harness blocks.
4. PLC shell blocks intentionally ignored.
5. Candidate dead/legacy blocks.

## Important Rule

CODESYS blue/grey visual state is not sufficient to classify a block.

A grey FB may still be used if it is instantiated inside an executed PRG/FB.
Example: FB_Rule_Engine is used by PRG_System_Scenario_Rules.

## MAIN execution root

Current MAIN root calls:

- PRG_Time_Service
- PRG_IO_Read
- PRG_Safety
- PRG_System_Intent
- PRG_System_Health
- PRG_System_Alarm_Gateway
- PRG_System_Scenario_Rules
- PRG_System_Access_Maintenance
- PRG_System_BlackBox
- PRG_System_History
- PRG_System_Runtime_Base
- PRG_Presence_Manager
- PRG_Heating_Policy_Manager
- PRG_Heating_Policy_Observer
- PRG_Mode_Manager
- PRG_System_Coordinator
- PRG_Policy
- PRG_Command_Arbitration
- PRG_Command_Verifier
- PRG_Security
- PRG_Heating
- PRG_Ventilation
- PRG_Lighting
- PRG_IO_Write

## Explicitly ignored by instruction

- PLC_PRG
- PRG_PLC_A
- PRG_PLC_B

## Confirmed live examples

- FB_Rule_Engine: used by PRG_System_Scenario_Rules.
- FB_System_Gateway_Intent: used by PRG_System_Alarm_Gateway.
- FB_Gateway_Interface: used by FB_System_Gateway_Intent.
- FB_System_Health_Orchestrator: used by PRG_System_Health.
- FB_CRC32_Calculator: used by FB_Gateway_Interface.

## First pass over visually grey FBs

| FB | Status | Decision |
|---|---|---|
| FB_Rule_Engine | LIVE | Already confirmed used |
| FB_Gateway_Interface | LIVE_BUT_BROKEN | Must restore full logic before tests |
| FB_Command_Deduplication | UNKNOWN | Blocked by broken gateway |
| FB_Astro_Timer | LIKELY_DEAD | No references found |
| FB_Simulation_Manager | LIKELY_DEAD | No references found |
| FB_Maintenance_Access | UNKNOWN | Needs compare with PRG_System_Access_Maintenance |
| FB_Presence_Playback | UNKNOWN | Possibly used by presence subsystem |
| FB_Random_Generator | UNKNOWN | Possibly used by playback/simulation |
| FB_State_Snapshot_Manager | UNKNOWN | Possibly used in runtime base |
| FB_System_Evacuation | LIKELY_UNWIRED | Not in pipeline |
| FB_State_Trace_Log | LIKELY_DIAGNOSTIC | Not in runtime pipeline |
| FB_System_Diagnostics | LIKELY_DIAGNOSTIC | Not in runtime pipeline |

## Critical note

Gateway logic is currently degraded (CRC stub only).

This distorts dependency analysis and must be fixed before final cleanup.

## Current status

Dependency classification started.

No deletion allowed yet.
