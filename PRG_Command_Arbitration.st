PROGRAM PRG_Command_Arbitration
VAR
    L_Mode : E_Safety_Mode;
    fbTrace : FB_Trace_Write;
END_VAR

IF NOT GVL_STATUS.G_Is_Active_PLC THEN RETURN; END_IF;

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
        fbTrace(iLayer:=TRACE_COMMAND,iSource:=SRC_SAFETY,iReason:=REASON_FIRE,iValueBool:=TRUE,iValueReal:=0.0,iText:='Fire override');

    GAS:
        GVL_COMMAND_SHADOW.G_Gas_Valve_Close := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := TRUE;
        GVL_COMMAND_SHADOW.G_Supply_100_Req := TRUE;
        fbTrace(iLayer:=TRACE_COMMAND,iSource:=SRC_SAFETY,iReason:=REASON_GAS,iValueBool:=TRUE,iValueReal:=0.0,iText:='Gas override');

    WATER_LEAK:
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_35 := TRUE;
        GVL_COMMAND_SHADOW.G_Close_Valve_36 := TRUE;
        fbTrace(iLayer:=TRACE_COMMAND,iSource:=SRC_SAFETY,iReason:=REASON_WATER_LEAK,iValueBool:=TRUE,iValueReal:=0.0,iText:='Water leak override');

    GLOBAL_STOP:
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Water_Emergency_Stop := TRUE;
        fbTrace(iLayer:=TRACE_COMMAND,iSource:=SRC_SAFETY,iReason:=REASON_GLOBAL_STOP,iValueBool:=TRUE,iValueReal:=0.0,iText:='Global stop override');

    NORMAL:
        IF GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost THEN
            GVL_COMMAND_SHADOW.G_Vent_PV3_Boost := TRUE;
            fbTrace(iLayer:=TRACE_COMMAND,iSource:=SRC_SCENARIO,iReason:=REASON_SCENARIO_VENT_BOOST,iValueBool:=TRUE,iValueReal:=0.0,iText:='Vent boost allowed');
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

// Safety-access coupling: force-open and close-block always win over user close.
IF GVL_INTENT_SAFETY.I_Evacuation_Mode_Active THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
    GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
    GVL_COMMAND_SHADOW.G_Gate_Open := TRUE;
    GVL_COMMAND_SHADOW.G_Wicket_Open := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Lock_1_Force_Open THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Lock_2_Force_Open THEN
    GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
END_IF;

IF GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block OR GVL_INTENT_SAFETY.I_Lock_1_Force_Open OR GVL_INTENT_SAFETY.I_Evacuation_Mode_Active THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
END_IF;

IF GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block OR GVL_INTENT_SAFETY.I_Lock_2_Force_Open OR GVL_INTENT_SAFETY.I_Evacuation_Mode_Active THEN
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
END_IF;

// ========================================
// USER ACCESS PASS-THROUGH (NORMAL CONTROL PATH)
// ========================================
IF (L_Mode = NORMAL) AND NOT GVL_SAFETY_RECOVERY.G_Recovery_Active THEN

    IF GVL_INTENT_USER.I_Gate_Open_Request THEN
        GVL_COMMAND_SHADOW.G_Gate_Open := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Wicket_Open_Request THEN
        GVL_COMMAND_SHADOW.G_Wicket_Open := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Lock_1_Open_Request THEN
        GVL_COMMAND_SHADOW.G_Lock_1_Open := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Lock_1_Close_Request THEN
        GVL_COMMAND_SHADOW.G_Lock_1_Close := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Lock_2_Open_Request THEN
        GVL_COMMAND_SHADOW.G_Lock_2_Open := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Lock_2_Close_Request THEN
        GVL_COMMAND_SHADOW.G_Lock_2_Close := TRUE;
    END_IF;

END_IF;

// Re-apply safety close blocks after user pass-through.
IF GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block OR GVL_INTENT_SAFETY.I_Lock_1_Force_Open OR GVL_INTENT_SAFETY.I_Evacuation_Mode_Active THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
END_IF;

IF GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block OR GVL_INTENT_SAFETY.I_Lock_2_Force_Open OR GVL_INTENT_SAFETY.I_Evacuation_Mode_Active THEN
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
END_IF;

// ========================================
// RECOVERY CLAMP
// ========================================
IF GVL_SAFETY_RECOVERY.G_Recovery_Active THEN
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Vent_Stop := TRUE;
    GVL_COMMAND_SHADOW.G_Water_Block := TRUE;
END_IF;

// ========================================
// COMMAND SANITY
// ========================================
IF GVL_COMMAND_SHADOW.G_Lock_1_Open AND GVL_COMMAND_SHADOW.G_Lock_1_Close THEN
    GVL_COMMAND_SHADOW.G_Lock_1_Close := FALSE;
END_IF;

IF GVL_COMMAND_SHADOW.G_Lock_2_Open AND GVL_COMMAND_SHADOW.G_Lock_2_Close THEN
    GVL_COMMAND_SHADOW.G_Lock_2_Close := FALSE;
END_IF;

IF (L_Mode <> NORMAL) AND NOT GVL_INTENT_SAFETY.I_Evacuation_Mode_Active THEN
    GVL_COMMAND_SHADOW.G_Gate_Open := FALSE;
    GVL_COMMAND_SHADOW.G_Wicket_Open := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration <<<
