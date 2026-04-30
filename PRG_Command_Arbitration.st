PROGRAM PRG_Command_Arbitration
VAR
    L_Mode : E_Safety_Mode;
END_VAR

IF NOT GVL_STATUS.G_Is_Active_PLC THEN
    RETURN;
END_IF;

// RESET
GVL_COMMAND_SHADOW.G_Heating_Block := FALSE;
GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Vent_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Vent_Block := FALSE;
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

// Recovery gating (partial lock during recovery)
IF GVL_SAFETY_RECOVERY.G_Recovery_Active THEN
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
END_IF;

CASE L_Mode OF

    FIRE:
        GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;
        GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;

    GAS:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;

    WATER_LEAK:
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;

    GLOBAL_STOP:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;

    EVACUATION:
        GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Gate_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Wicket_Open := TRUE;

    NORMAL:
        GVL_COMMAND_SHADOW.G_Gate_Open := GVL_INTENT_USER.I_Gate_Open_Request;
        GVL_COMMAND_SHADOW.G_Wicket_Open := GVL_INTENT_USER.I_Wicket_Open_Request;
        GVL_COMMAND_SHADOW.G_Lock_1_Open := GVL_INTENT_USER.I_Lock_1_Open_Request;
        GVL_COMMAND_SHADOW.G_Lock_1_Close := GVL_INTENT_USER.I_Lock_1_Close_Request;
        GVL_COMMAND_SHADOW.G_Lock_2_Open := GVL_INTENT_USER.I_Lock_2_Open_Request;
        GVL_COMMAND_SHADOW.G_Lock_2_Close := GVL_INTENT_USER.I_Lock_2_Close_Request;

END_CASE;

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration <<<
