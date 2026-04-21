PROGRAM PRG_Command_Arbitration
VAR
    L_i : INT;
END_VAR

// =====================================================
// STAGE B: SHADOW ARBITRATION (SAFETY ONLY)
// Reads GVL_INTENT_SAFETY and produces shadow commands
// into GVL_COMMAND_SHADOW. No connection to IO.
// =====================================================

// === RESET SHADOW COMMANDS ===
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

// =====================================================
// SAFETY PRIORITY (ABSOLUTE)
// =====================================================

// FIRE / SMOKE
IF GVL_INTENT_SAFETY.I_Fire_Alarm_Active THEN
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;

    // Evacuation
    GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
    GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
END_IF;

// GAS
IF GVL_INTENT_SAFETY.I_Gas_Close_Required THEN
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
END_IF;

// VENTILATION FORCED MODES
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

// WATER
IF GVL_INTENT_SAFETY.I_Water_Main_Close_Required THEN
    GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
    GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;
END_IF;

FOR L_i := 1 TO 32 DO
    IF GVL_INTENT_SAFETY.I_Water_Zone_Close_Required[L_i] THEN
        // future: zone-specific routing
    END_IF;
END_FOR;

// =====================================================
// NOTES
// =====================================================
// - No system/user arbitration yet
// - No IO binding
// - Used for verification vs legacy behavior
