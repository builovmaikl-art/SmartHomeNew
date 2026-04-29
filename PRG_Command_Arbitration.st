PROGRAM PRG_Command_Arbitration
VAR
    L_i : INT;
END_VAR

// ============================================================
// COMMAND PRIORITY MODEL (Step 2.2)
// ============================================================
// Explicit deterministic priority:
//   1. Safety  (highest)
//   2. System
//   3. Policy
//   4. User    (lowest)
//
// Implementation strategy:
//   - reset shadow commands
//   - apply User baseline
//   - apply Policy requests
//   - apply System overrides
//   - apply Safety overrides last
//
// Protective TRUE wins over lower priority permissive/user commands.
// ============================================================

// Reset shadow operational commands before each arbitration cycle
GVL_COMMAND_SHADOW.G_Gas_Valve_Close := FALSE;
GVL_COMMAND_SHADOW.G_Boiler_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Supply_100_Req := FALSE;
GVL_COMMAND_SHADOW.G_Supply_80_Req := FALSE;
GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := FALSE;
GVL_COMMAND_SHADOW.G_Exhaust_100_Req := FALSE;
GVL_COMMAND_SHADOW.G_Vent_Stop := FALSE;

GVL_COMMAND_SHADOW.G_Close_Valve_35 := FALSE;
GVL_COMMAND_SHADOW.G_Close_Valve_36 := FALSE;

GVL_COMMAND_SHADOW.G_Lock_1_Open := FALSE;
GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
GVL_COMMAND_SHADOW.G_Lock_2_Open := FALSE;
GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
GVL_COMMAND_SHADOW.G_Gate_Open := FALSE;
GVL_COMMAND_SHADOW.G_Wicket_Open := FALSE;

// ============================================================
// 4. USER BASELINE (lowest priority)
// ============================================================
GVL_COMMAND_SHADOW.G_Gate_Open := GVL_INTENT_USER.I_Gate_Open_Request;
GVL_COMMAND_SHADOW.G_Wicket_Open := GVL_INTENT_USER.I_Wicket_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_1_Open := GVL_INTENT_USER.I_Lock_1_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_1_Close := GVL_INTENT_USER.I_Lock_1_Close_Request;
GVL_COMMAND_SHADOW.G_Lock_2_Open := GVL_INTENT_USER.I_Lock_2_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_2_Close := GVL_INTENT_USER.I_Lock_2_Close_Request;

// ============================================================
// 3. POLICY REQUESTS
// ============================================================
// Step 2.2 only makes priority explicit. Current policy intents do not
// directly map to actuator shadow fields yet. They remain wired for later
// domain-specific mapping without bypassing the priority model.
IF GVL_INTENT_POLICY.G_Preheat_Request THEN
    ;
END_IF;

IF GVL_INTENT_POLICY.G_Freeze_Request THEN
    ;
END_IF;

IF GVL_INTENT_POLICY.G_Eco_Mode_Request THEN
    ;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF GVL_INTENT_POLICY.G_Zone_Heating_Request[L_i] THEN
        ;
    END_IF;
END_FOR;

// ============================================================
// 2. SYSTEM OVERRIDES
// ============================================================
IF GVL_INTENT_SYSTEM.I_Mode_Degraded_Active THEN
    GVL_COMMAND_SHADOW.G_Supply_80_Req := TRUE;
END_IF;

// ============================================================
// 1. SAFETY OVERRIDES (highest priority, applied last)
// ============================================================
IF GVL_INTENT_SAFETY.I_Fire_Alarm_Active THEN
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
    GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
END_IF;

IF GVL_INTENT_SAFETY.I_Gas_Close_Required THEN
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost THEN
    GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 THEN
    GVL_COMMAND_SHADOW.G_Supply_100_Req := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Vent_Force_Supply_80 THEN
    GVL_COMMAND_SHADOW.G_Supply_80_Req := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Vent_Stop_Required THEN
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Supply_100_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Supply_80_Req := FALSE;
    GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := FALSE;
    GVL_COMMAND_SHADOW.G_Exhaust_100_Req := FALSE;
END_IF;

IF GVL_INTENT_SAFETY.I_Water_Main_Close_Required THEN
    GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
    GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;
END_IF;

FOR L_i := 1 TO 32 DO
    IF GVL_INTENT_SAFETY.I_Water_Zone_Close_Required[L_i] THEN
        ;
    END_IF;
END_FOR;

END_PROGRAM
