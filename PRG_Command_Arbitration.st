PROGRAM PRG_Command_Arbitration
VAR
    L_i : INT;
END_VAR

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

// User intent pass-through into the shadow operational layer
GVL_COMMAND_SHADOW.G_Gate_Open := GVL_INTENT_USER.I_Gate_Open_Request;
GVL_COMMAND_SHADOW.G_Wicket_Open := GVL_INTENT_USER.I_Wicket_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_1_Open := GVL_INTENT_USER.I_Lock_1_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_1_Close := GVL_INTENT_USER.I_Lock_1_Close_Request;
GVL_COMMAND_SHADOW.G_Lock_2_Open := GVL_INTENT_USER.I_Lock_2_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_2_Close := GVL_INTENT_USER.I_Lock_2_Close_Request;

// Safety and system arbitration into the shadow operational layer
IF GVL_INTENT_SAFETY.I_Fire_Alarm_Active THEN
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
    GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
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
END_IF;

IF GVL_INTENT_SYSTEM.I_Mode_Degraded_Active THEN
    GVL_COMMAND_SHADOW.G_Supply_80_Req := TRUE;
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

// =============================
// POLICY INTENT (Step 1.1 wiring only)
// =============================

IF GVL_INTENT_POLICY.G_Preheat_Request THEN
    ; // placeholder, no logic yet
END_IF;

IF GVL_INTENT_POLICY.G_Freeze_Request THEN
    ; // placeholder
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    IF GVL_INTENT_POLICY.G_Zone_Heating_Request[L_i] THEN
        ; // placeholder
    END_IF;
END_FOR;

END_PROGRAM
