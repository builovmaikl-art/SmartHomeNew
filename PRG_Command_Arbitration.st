PROGRAM PRG_Command_Arbitration
VAR
    L_Mode : E_Safety_Mode;
    fbTrace : FB_Trace_Write;
END_VAR

// PLC inactive → force safe commands
IF NOT GVL_STATUS.G_Is_Active_PLC THEN
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
    RETURN;
END_IF;

// ========================================
// FULL COMMAND RESET
// ========================================
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

L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;

// ========================================
// SAFETY / RECOVERY / BEHAVIOR ARBITRATION
// ========================================
CASE L_Mode OF

    FIRE:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Gate_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Wicket_Open := TRUE;

    GAS:
        GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := TRUE;
        GVL_COMMAND_SHADOW.G_Supply_100_Req := TRUE;
        // ensure exits open
        GVL_COMMAND_SHADOW.G_Gate_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Wicket_Open := TRUE;

    WATER_LEAK:
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;

    GLOBAL_STOP:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := TRUE;

    NORMAL:
        IF GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost THEN
            GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := TRUE;
        END_IF;

END_CASE;

// ========================================
// SAFETY INTENT DETAIL PROJECTION
// ========================================
IF GVL_INTENT_SAFETY.I_Gas_Close_Required THEN
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Boiler_Stop_Required THEN
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
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

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration <<<
