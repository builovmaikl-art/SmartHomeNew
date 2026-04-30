PROGRAM PRG_Command_Arbitration
VAR
    L_Mode : E_Safety_Mode;
    fbTrace : FB_Trace_Write;
END_VAR

IF NOT GVL_STATUS.G_Is_Active_PLC THEN RETURN; END_IF;

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

CASE L_Mode OF
    FIRE:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
        fbTrace(iLayer:=TRACE_COMMAND,iSource:=SRC_SAFETY,iReason:=REASON_FIRE,iValueBool:=TRUE,iValueReal:=0.0,iText:='Fire override');

    NORMAL:
        IF GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost THEN
            GVL_COMMAND_SHADOW.G_Vent_Block := FALSE;
            fbTrace(iLayer:=TRACE_COMMAND,iSource:=SRC_SCENARIO,iReason:=REASON_SCENARIO_VENT_BOOST,iValueBool:=TRUE,iValueReal:=0.0,iText:='Vent boost allowed');
        END_IF;
END_CASE;

IF GVL_SAFETY_RECOVERY.G_Recovery_Active THEN
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration <<<
