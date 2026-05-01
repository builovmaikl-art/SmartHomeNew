PROGRAM PRG_Command_Arbitration
VAR
    L_Mode : E_Safety_Mode;
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

// RESET
GVL_COMMAND_SHADOW.G_Gas_Valve_Close := FALSE;
GVL_COMMAND_SHADOW.G_Boiler_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Vent_Stop := FALSE;
GVL_COMMAND_SHADOW.G_Heating_Block := FALSE;
GVL_COMMAND_SHADOW.G_Water_Block := FALSE;

GVL_COMMAND_SHADOW.G_Lock_1_Open := FALSE;
GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
GVL_COMMAND_SHADOW.G_Lock_2_Open := FALSE;
GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
GVL_COMMAND_SHADOW.G_Gate_Open := FALSE;
GVL_COMMAND_SHADOW.G_Wicket_Open := FALSE;

L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;

CASE L_Mode OF

    FIRE:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
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

        GVL_COMMAND_SHADOW.G_Gate_Open := TRUE;
        GVL_COMMAND_SHADOW.G_Wicket_Open := TRUE;

    WATER_LEAK:
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;

    GLOBAL_STOP:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;

END_CASE;

// -----------------------------
// SAFETY ACCESS CLAMP (RESTORED)
// -----------------------------

// FIRE → no close allowed
IF L_Mode = FIRE THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
END_IF;

// conflict block
IF GVL_COMMAND_SHADOW.G_Lock_1_Open AND GVL_COMMAND_SHADOW.G_Lock_1_Close THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
END_IF;

IF GVL_COMMAND_SHADOW.G_Lock_2_Open AND GVL_COMMAND_SHADOW.G_Lock_2_Close THEN
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration <<<
