# Actual MAIN Execution Pipeline

Date: 2026-04-30

## Purpose

This document records the actual top-level runtime order from current `MAIN.st`.

This is the baseline for all further top-down and bottom-up audit reports.

## Current top-level pipeline

```text
MAIN
  01 PRG_Time_Service
  02 PRG_IO_Read
  03 PRG_Safety
  04 PRG_System_Intent
  05 PRG_System_Health
  06 PRG_System_Alarm_Gateway
  07 PRG_Test_Scenario_Runner
  08 PRG_System_Scenario_Rules
  09 PRG_System_Access_Maintenance
  10 PRG_System_BlackBox
  11 PRG_System_History
  12 PRG_System_Diagnostics
  13 PRG_System_Evacuation
  14 PRG_System_Trend
  15 PRG_System_Runtime_Base
  16 PRG_Presence_Manager
  17 PRG_System_Simulation
  18 PRG_Heating_Policy_Manager
  19 PRG_Heating_Policy_Observer
  20 PRG_Mode_Manager
  21 PRG_System_Coordinator
  22 PRG_Policy
  23 PRG_Command_Arbitration
  24 PRG_Command_Verifier
  25 PRG_Security
  26 PRG_Heating
  27 PRG_Ventilation
  28 PRG_Lighting
  29 PRG_IO_Write
```

## High-level layer interpretation

```text
Time base
  -> Input acquisition / normalization
    -> Safety intent and hazard projection
      -> System health / gateway / scenario / access / telemetry
        -> Presence / simulation / policy / mode / coordinator
          -> Command arbitration and verification
            -> Domain control
              -> Physical output write
```

## First-order observations

### 1. `PRG_Test_Scenario_Runner` is in live MAIN pipeline

The test runner is executed before scenario rules.

This can be valid if it is explicitly gated by test flags, but it must be documented because it can write scenario-related state during the normal cycle when enabled.

Audit status: HYPOTHESIS / needs deep test-layer review.

### 2. Security is executed after command arbitration

`PRG_Command_Arbitration` runs before `PRG_Security`.

This matters because `PRG_Security` can publish access-control intent such as gate, wicket, and lock requests, while command arbitration consumes user/security intent into shadow commands.

Potential consequence:

- security/access requests produced in the current cycle may not reach `GVL_COMMAND_SHADOW` until the next cycle;
- this may be acceptable but must be documented as one-cycle latency;
- if the system expects same-cycle access actuation, the order is suspicious.

Audit status: CONFIRMED_STATIC order dependency.

### 3. Domain control runs after command arbitration

Heating, ventilation, lighting run after command arbitration and before IO write.

This is structurally reasonable for domain outputs.

However command arbitration also affects outputs later written by `PRG_IO_Write`, so any domain that still writes direct command-like state must be reviewed for bypass risk.

Audit status: HYPOTHESIS.

### 4. Observability blocks run before several behavior blocks

History, diagnostics, evacuation, trend, runtime base run before presence, simulation, heating policy, mode, coordinator, policy, command, security, and domains.

Potential consequence:

- history/diagnostics may observe previous-cycle values for some later-produced decisions;
- this may be acceptable if documented as previous-cycle snapshot;
- if expected to report final state of the current cycle, order should be reviewed.

Audit status: HYPOTHESIS.

### 5. IO write is last

`PRG_IO_Write` is the final actuation projection.

This is correct structurally.

Bottom-up audit must verify that physical outputs are only written here or that any exceptions are intentional and safe.

Audit status: CONFIRMED_STATIC top-level pattern.

## Top-level PRG to FB call map

```text
PRG_Time_Service
  -> FB_System_Timebase
  -> FB_Time_Service

PRG_IO_Read
  -> FB_System_Timer[]
  -> FB_IO_Module_Watchdog
  -> FB_Diagnostics_Event_Manager
  -> FB_Sensor_Calibration_Processor[]
  -> FB_Sensor_Analog_Processing[]

PRG_Safety
  -> FB_Safety_Workflow_Manager
  -> FB_Water_Leakage_Manager
  -> FB_Gas_Smoke_Manager
  -> FB_Ownership_Watchdog

PRG_System_Intent
  -> FB_System_Intent_Publisher

PRG_System_Health
  -> FB_System_Health_Orchestrator

PRG_System_Alarm_Gateway
  -> FB_System_Alarm_Orchestrator
  -> FB_System_Gateway_Intent

PRG_Test_Scenario_Runner
  -> no FB calls

PRG_System_Scenario_Rules
  -> FB_Rule_Engine
  -> FB_System_Scenario_Arbitration

PRG_System_Access_Maintenance
  -> FB_LogEvent

PRG_System_BlackBox
  -> FB_BlackBox_Recorder

PRG_System_History
  -> FB_History_Manager

PRG_System_Diagnostics
  -> FB_System_Diagnostics
  -> FB_State_Trace_Log

PRG_System_Evacuation
  -> FB_System_Evacuation

PRG_System_Trend
  -> FB_Trend_Logger
  -> FB_Trend_Adapter

PRG_System_Runtime_Base
  -> FB_System_Init
  -> FB_System_Recovery
  -> FB_System_Persist_Manager
  -> FB_System_Redundancy_Orchestrator

PRG_Presence_Manager
  -> FB_Presence_Manager

PRG_System_Simulation
  -> FB_Simulation_Manager
  -> FB_Presence_Playback

PRG_Heating_Policy_Manager
  -> FB_Heating_Policy_Manager
  -> FB_Heating_Schedule_Preheat
  -> FB_Heating_Thermal_Model
  -> FB_Heating_Predictive_Controller
  -> FB_Heating_Optimizer
  -> FB_Time_Service

PRG_Heating_Policy_Observer
  -> FB_Heating_Policy_Observer

PRG_Mode_Manager
  -> FB_Mode_Manager

PRG_System_Coordinator
  -> FB_System_Coordinator

PRG_Policy
  -> no FB calls

PRG_Command_Arbitration
  -> no FB calls

PRG_Command_Verifier
  -> no FB calls

PRG_Security
  -> FB_Security_System_Manager
  -> FB_Access_Control

PRG_Heating
  -> FB_System_Timer
  -> FB_Heating_System_Manager
  -> FB_DHW_Manager
  -> FB_Diagnostics_Event_Manager
  -> FB_Heating_Decision_Context
  -> FB_Heating_Demand_Map
  -> FB_Diagnostics_RootCause

PRG_Ventilation
  -> FB_Ventilation_System_Manager

PRG_Lighting
  -> FB_Lighting_Blinds_Manager
  -> FB_Socket_Manager

PRG_IO_Write
  -> no FB calls
```

## Next audit step

Proceed from top to bottom:

1. `PRG_Time_Service`
2. `PRG_IO_Read`
3. `PRG_Safety`
4. system layer blocks
5. policy/coordinator/command/security
6. domains
7. IO write
8. bottom-up output ownership review
