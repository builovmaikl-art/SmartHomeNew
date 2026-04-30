# PRG_Heating S1 Local Context Decomposition

Date: 2026-04-30

## Scope

This document decomposes `PRG_Heating` section:

```text
HEATING_S1_INPUTS_LOCAL_CONTEXT
```

Donor code remains unchanged during this stage.

## Current S1 responsibilities

Current S1 contains several responsibilities mixed together:

```text
1. Boiler modulation adapter
2. Safety-to-heating local context
3. DHW demand gating
4. Degraded-mode DHW gating
5. Mode hold timing
6. Freeze/preheat/normal heating mode selection
7. Target temperature selection
8. Policy target adjustment
9. Target clamp
```

This is not pure domain execution. It is a local context builder with policy/safety/mode influence.

## Target interpretation

S1 should become a local heating context builder:

```text
inputs from Safety / Mode / Policy / DHW feedback
→ local heating execution context
```

It must not become the global decision owner.

## Proposed FB

```text
FB_Heating_Local_Context
```

## Target responsibility

`FB_Heating_Local_Context` owns only local heating context preparation:

- copy/adapt boiler modulation inputs;
- derive local heating emergency flag;
- derive local gas-safety stop flag;
- derive local DHW demand allowed flag;
- apply freeze/preheat/normal hold timing;
- calculate local target temperature;
- apply policy target adjustment;
- clamp local target temperature.

## Explicit non-responsibilities

`FB_Heating_Local_Context` must NOT:

- write physical outputs;
- decide global system mode;
- own final safety enforcement;
- own command arbitration;
- publish diagnostics events;
- write to `GVL_IO`;
- replace `PRG_Command_Arbitration`.

## Inputs

Preferred interface:

```text
VI_System_Time_MS : UDINT
VI_Safety_Emergency_Stop : BOOL
VI_Safety_Gas_Latched : BOOL
VI_System_Mode : E_System_Operating_Mode
VI_Freeze_Request : BOOL
VI_Preheat_Request : BOOL
VI_DHW_Heating_Pump_Feedback : BOOL
VI_Policy_Target_Adjustment : REAL
VI_Boiler_Modulation_Raw : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF INT
```

Note: raw boiler modulation type follows current source expression:

```text
GVL_IO.AI_Boiler_Modulation[i]
```

If the real type is not `INT`, adjust before activation.

## Outputs

```text
VO_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL
VO_Heating_Emergency_Stop : BOOL
VO_Heating_Gas_Safety_Stop : BOOL
VO_Heating_DHW_Demand : BOOL
VO_Target_Temperature : REAL
VO_Local_Mode : INT
```

## Internal state

```text
L_Last_Mode : INT := 0
L_Mode_Hold_Timer : FB_System_Timer
L_i : INT
```

## Target behavior copied from donor

### Safety/DHW gating

```text
VO_Heating_Emergency_Stop := VI_Safety_Emergency_Stop;
VO_Heating_Gas_Safety_Stop := VI_Safety_Gas_Latched;
VO_Heating_DHW_Demand := VI_DHW_Heating_Pump_Feedback;

IF VO_Heating_Emergency_Stop THEN
    VO_Heating_Gas_Safety_Stop := FALSE;
    VO_Heating_DHW_Demand := FALSE;
ELSIF VO_Heating_Gas_Safety_Stop THEN
    VO_Heating_DHW_Demand := FALSE;
ELSIF VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    VO_Heating_DHW_Demand := FALSE;
END_IF;
```

### Mode hold

```text
L_Mode_Hold_Timer(
    IN := TRUE,
    PT := T#30s,
    VI_System_Time_MS := VI_System_Time_MS
);

IF L_Mode_Hold_Timer.Q THEN
    IF VI_Freeze_Request THEN
        L_Last_Mode := 2;
    ELSIF VI_Preheat_Request THEN
        L_Last_Mode := 1;
    ELSE
        L_Last_Mode := 0;
    END_IF;
END_IF;
```

### Target selection

```text
CASE L_Last_Mode OF
    2: VO_Target_Temperature := 5.0;
    1: VO_Target_Temperature := 22.0;
    ELSE VO_Target_Temperature := 20.0;
END_CASE;

VO_Target_Temperature := VO_Target_Temperature + VI_Policy_Target_Adjustment;

IF VO_Target_Temperature < 5.0 THEN
    VO_Target_Temperature := 5.0;
ELSIF VO_Target_Temperature > 26.0 THEN
    VO_Target_Temperature := 26.0;
END_IF;
```

## Activation strategy

Do not connect immediately.

Order:

```text
1. Create FB candidate
2. Keep donor S1 unchanged
3. Extract S1.5 and S2 candidates
4. Only then clean donor and connect extracted FBs together
```

## Risk note

S1 currently writes directly to:

```text
GVL_STATE.G_Target_Temperature
```

Target design should route this through `VO_Target_Temperature` first, then assign during controlled donor cleanup.

## Status

Design ready for candidate FB creation.
