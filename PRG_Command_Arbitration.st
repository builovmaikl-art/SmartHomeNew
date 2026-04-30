PROGRAM PRG_Command_Arbitration
VAR
    L_i : INT;
END_VAR

IF NOT GVL_STATUS.G_Is_Active_PLC THEN
    RETURN;
END_IF;

// ============================================================
// RESET COMMAND SHADOW
// ============================================================
GVL_COMMAND_SHADOW.G_Gas_Valve_Close := FALSE;
GVL_COMMAND_SHADOW.G_Boiler_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Supply_100_Req := FALSE;
GVL_COMMAND_SHADOW.G_Supply_80_Req := FALSE;
GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := FALSE;
GVL_COMMAND_SHADOW.G_Exhaust_100_Req := FALSE;
GVL_COMMAND_SHADOW.G_Vent_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Vent_Block := FALSE;

GVL_COMMAND_SHADOW.G_Heating_Block := FALSE;
GVL_COMMAND_SHADOW.G_Heating_DHW_Block := FALSE;
GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := FALSE;

GVL_COMMAND_SHADOW.G_Water_Block := FALSE;
GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Close_Valve_35 := FALSE;
GVL_COMMAND_SHADOW.G_Close_Valve_36 := FALSE;

GVL_COMMAND_SHADOW.G_Lock_1_Open := FALSE;
GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
GVL_COMMAND_SHADOW.G_Lock_2_Open := FALSE;
GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
GVL_COMMAND_SHADOW.G_Gate_Open := FALSE;
GVL_COMMAND_SHADOW.G_Wicket_Open := FALSE;

// ============================================================
// USER COMMANDS
// ============================================================
GVL_COMMAND_SHADOW.G_Gate_Open := GVL_INTENT_USER.I_Gate_Open_Request;
GVL_COMMAND_SHADOW.G_Wicket_Open := GVL_INTENT_USER.I_Wicket_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_1_Open := GVL_INTENT_USER.I_Lock_1_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_1_Close := GVL_INTENT_USER.I_Lock_1_Close_Request;
GVL_COMMAND_SHADOW.G_Lock_2_Open := GVL_INTENT_USER.I_Lock_2_Open_Request;
GVL_COMMAND_SHADOW.G_Lock_2_Close := GVL_INTENT_USER.I_Lock_2_Close_Request;

// ============================================================
// SYSTEM COMMANDS
// ============================================================
IF GVL_INTENT_SYSTEM.I_Mode_Degraded_Active THEN
    GVL_COMMAND_SHADOW.G_Heating_DHW_Block := TRUE;
END_IF;

IF GVL_SYSTEM_COORDINATION.G_Block_Ventilation THEN
    GVL_COMMAND_SHADOW.G_Vent_Block := TRUE;
END_IF;

// ============================================================
// SAFETY COMMANDS
// ============================================================
IF GVL_INTENT_SAFETY.I_Fire_Alarm_Active OR GVL_INTENT_SAFETY.I_System_Safe_Stop_Required THEN
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Gas_Close_Required THEN
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Vent_Stop_Required THEN
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
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

IF GVL_INTENT_SAFETY.I_Vent_Force_Exhaust_100 THEN
    GVL_COMMAND_SHADOW.G_Exhaust_100_Req := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Water_Main_Close_Required THEN
    GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
    GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;
END_IF;

// Evacuation access commands override close requests.
IF GVL_INTENT_SAFETY.I_Lock_1_Force_Open THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
END_IF;
IF GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
END_IF;
IF GVL_INTENT_SAFETY.I_Lock_2_Force_Open THEN
    GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
END_IF;
IF GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block THEN
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
END_IF;

END_PROGRAM
