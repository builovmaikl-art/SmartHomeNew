# PRG_Heating S1.5 Thermal Allocation Decomposition

Date: 2026-04-30

## Scope

This document decomposes `PRG_Heating` section:

```text
HEATING_S15_DECISION_CONTEXT_THERMAL_ALLOCATION
```

Donor code remains unchanged during this stage.

## Current S1.5 responsibilities

Current S1.5 contains:

```text
1. Base manifold priority copy
2. Circuit-to-manifold / circuit-to-zone adaptation
3. Zone policy priority bias application
4. Guest preheat priority boost
5. Zone target adjustment priority influence
6. Self-tune level priority influence
7. Policy multiplier application
8. Minimum priority clamp
9. Thermal decision context call
```

This is a decision/allocation preparation layer.

## Target interpretation

S1.5 should become a dedicated thermal allocation context builder:

```text
policy/config/diagnostics inputs
→ adjusted manifold priorities
→ allowed/enabled manifold set
```

It should not own physical actuator state.

## Proposed FB

```text
FB_Heating_Thermal_Allocation
```

## Target responsibility

`FB_Heating_Thermal_Allocation` owns only:

- adjusted manifold priority calculation;
- thermal allocation through existing `FB_Heating_Decision_Context`;
- publication of allocation result through outputs.

## Explicit non-responsibilities

`FB_Heating_Thermal_Allocation` must NOT:

- write pumps or valves;
- write `GVL_STATE.G_Manifold_Pumps`;
- write `GVL_STATE.G_Manifold_Valves`;
- decide global heating block;
- perform safety shutdown;
- emit diagnostics events.

## Inputs

Preferred interface:

```text
VI_Zone_Configs : ARRAY[1..C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config
VI_Circuit_To_Zone : ARRAY[1..C_MAX_HEATING_CIRCUITS] OF INT
VI_Manifold_Base_Priority : ARRAY[1..C_MAX_MANIFOLDS] OF INT
VI_Zone_Priority_Bias : ARRAY[1..C_MAX_ZONES] OF REAL
VI_Guest_Preheat_Enabled : BOOL
VI_Zone_Guest_Preheat_Request : ARRAY[1..C_MAX_ZONES] OF BOOL
VI_Guest_Preheat_Priority_Boost : INT
VI_Zone_Target_Adjustment : ARRAY[1..C_MAX_ZONES] OF REAL
VI_Zone_Self_Level : ARRAY[1..C_MAX_ZONES] OF INT
VI_Policy_Priority_Multiplier : REAL
VI_Manifold_Pump_In_Service : ARRAY[1..C_MAX_MANIFOLDS] OF BOOL
VI_Manifold_Pressure_Fault : ARRAY[1..C_MAX_MANIFOLDS] OF BOOL
VI_Manifold_Current_Fault : ARRAY[1..C_MAX_MANIFOLDS] OF BOOL
VI_Manifold_Thermal_Weight : ARRAY[1..C_MAX_MANIFOLDS] OF REAL
VI_Max_Thermal_Budget : REAL
```

## Outputs

```text
VO_Manifold_Adjusted_Priority : ARRAY[1..C_MAX_MANIFOLDS] OF INT
VO_Manifold_Allowed : ARRAY[1..C_MAX_MANIFOLDS] OF BOOL
VO_Manifold_Enabled : ARRAY[1..C_MAX_MANIFOLDS] OF BOOL
VO_Heating_Degraded : BOOL
```

## Activation strategy

Do not connect immediately.

Order:

```text
1. Create FB candidate
2. Keep donor S1.5 unchanged
3. Decompose S2
4. Only then clean donor and connect extracted FBs together
```

## Risk note

S1.5 currently feeds `fbDecision.VO_Manifold_Enabled` used later in S2.

During final cleanup, S2 must be changed to consume:

```text
FB_Heating_Thermal_Allocation.VO_Manifold_Enabled
```

instead of donor-local `fbDecision.VO_Manifold_Enabled`.

## Status

Design ready for candidate FB creation.
