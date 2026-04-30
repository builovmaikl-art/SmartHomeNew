# PRG_Heating S2 Orchestration Decomposition

Date: 2026-04-30

## Scope

This document decomposes `PRG_Heating` section:

```text
HEATING_S2_ORCHESTRATION_CALLS
```

Donor code remains unchanged during this stage.

## Current S2 responsibilities

Current S2 contains:

```text
1. Heating manager orchestration call
2. DHW manager orchestration call
3. Heating/DHW interaction through local DHW demand
4. Output publication into GVL_STATE and GVL_STATUS
5. Coordinator heating block application
6. Thermal allocation result application through fbDecision.VO_Manifold_Enabled
7. Manifold pump/valve forcing
8. Zone valve forcing for disabled manifolds
```

This section is not a pure FB call wrapper. It is a mixed orchestration/execution/override block.

## Target interpretation

S2 should become a heating execution orchestrator candidate:

```text
local context + allocation result + configuration + state inputs
→ domain actuator state proposal
```

It should not be the final global decision owner.

## Proposed FB

```text
FB_Heating_Orchestration
```

## Target responsibility

`FB_Heating_Orchestration` owns only:

- calling `FB_Heating_System_Manager`;
- applying heating block / allocation result to local actuator proposal;
- calling `FB_DHW_Manager`;
- returning local zone valve proposal;
- publishing current legacy-compatible outputs during transition.

## Explicit non-responsibilities

`FB_Heating_Orchestration` must NOT:

- decide global policy;
- own final safety enforcement;
- write physical IO;
- own command arbitration;
- create diagnostics events;
- change global scenario/mode.

## Inputs

Preferred interface:

```text
VI_System_Time_MS : UDINT
VI_Current_TOD : TOD
VI_IsActivePLC : BOOL
VI_Outdoor_Temp : REAL
VI_Floor_Temps : ARRAY[1..C_MAX_HEATING_CIRCUITS] OF REAL
VI_Room_Temps : ARRAY[1..C_MAX_ZONES] OF REAL
VI_Heating_Config : ST_Heating_Config
VI_Zone_Configs : ARRAY[1..C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config
VI_Tariff : ST_Tariff_Config
VI_Time_Of_Day_MS : UDINT
VI_Manifold_Pressures : ARRAY[1..C_MAX_MANIFOLDS] OF REAL
VI_Manifold_Currents : ARRAY[1..C_MAX_MANIFOLDS] OF REAL
VI_Manifold_Temps_Supply : ARRAY[1..C_MAX_MANIFOLDS] OF REAL
VI_Manifold_Temps_Return : ARRAY[1..C_MAX_MANIFOLDS] OF REAL
VI_Boiler_Flame_Status : ARRAY[1..C_MAX_BOILERS] OF BOOL
VI_Boiler_Error_Status : ARRAY[1..C_MAX_BOILERS] OF BOOL
VI_Boiler_OT_Online : BOOL
VI_Boiler_Modulation : ARRAY[1..C_MAX_BOILERS] OF REAL
VI_Rule_Actions : ARRAY[1..C_MAX_RULES] OF ST_Rule_Action
VI_IO_Modules_Online : ARRAY[...] OF BOOL
VI_DHW_Heating_Demand : BOOL
VI_DHW_Target_Temp : REAL
VI_System_Mode : E_System_Operating_Mode
VI_Emergency_Stop : BOOL
VI_Gas_Safety_Stop : BOOL
VI_Manifold_End_Switches : ARRAY[1..C_MAX_MANIFOLDS] OF BOOL
VI_Valve_Test_Config : ARRAY[1..C_MAX_MANIFOLDS] OF ST_Valve_Test_Config
VI_Block_Heating : BOOL
VI_Manifold_Enabled : ARRAY[1..C_MAX_MANIFOLDS] OF BOOL
```

Some exact array types should be verified before final activation because the donor currently passes existing GVL fields directly.

## Outputs / in-out during transition

Because S2 currently writes many GVL state/status fields, the transition candidate may initially keep legacy-compatible `VAR_IN_OUT` outputs:

```text
VIO_Manifold_Valves
VIO_Manifold_Pumps
VIO_Zone_Valves
VIO_Boiler_OT_Enable
VIO_Boiler_OT_Setpoint
VIO_Backup_Circulation_Pump
VIO_Electric_Heater_Enable
VIO_Freeze_Risk_Status
VIO_Manifold_Status
VIO_Boiler_Status
VIO_DHW_Heating_Pump
VIO_DHW_Circ_Pump
VIO_DHW_Status
```

Final target may later route these through a cleaner actuator-state structure, but this is not required for the extraction stage.

## Internal FBs

```text
fbHeatingManager : FB_Heating_System_Manager
fbDHWManager : FB_DHW_Manager
```

## Activation strategy

Do not connect immediately.

Order:

```text
1. Create FB candidate
2. Keep donor S2 unchanged
3. Verify compile types when integration begins
4. Clean donor only after all S1/S1.5/S2 candidates exist
5. Switch PRG_Heating from inline sections to FB calls in one controlled pass
```

## Risk note

S2 currently uses `fbDHWManager.VO_Heating_Pump` indirectly in S1 before the `fbDHWManager` call in S2.

During final cleanup this dependency must be handled explicitly:

```text
previous-cycle DHW heating pump feedback
or
reordered DHW context calculation
```

This is a real order-dependency and must not be hidden during refactor.

## Status

Design ready for candidate FB creation, but exact type verification may be needed before activation.
