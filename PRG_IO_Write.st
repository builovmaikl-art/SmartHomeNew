PROGRAM PRG_IO_Write
VAR
    L_i : INT;
    L_Heating_Forced_Off : BOOL;
    L_Vent_Forced_Off : BOOL;
    L_Water_Forced_Off : BOOL;
    fbTrace : FB_Trace_Write;
END_VAR

IF NOT GVL_STATUS.G_Is_Active_PLC THEN RETURN; END_IF;

L_Heating_Forced_Off := GVL_COMMAND_SHADOW.G_Heating_Block OR GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop;
L_Vent_Forced_Off := GVL_COMMAND_SHADOW.G_Vent_Stop OR GVL_COMMAND_SHADOW.G_Vent_Block;
L_Water_Forced_Off := GVL_COMMAND_SHADOW.G_Close_Valve_35 OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

FOR L_i := 1 TO 8 DO
    IF L_Heating_Forced_Off THEN
        GVL_IO.DO_Zone_Valves[L_i] := FALSE;
    ELSE
        GVL_IO.DO_Zone_Valves[L_i] := GVL_HEATING_OUTPUT.DO_Zone_Valves[L_i];
    END_IF;
END_FOR;

fbTrace(iLayer:=TRACE_IO,iSource:=SRC_IO,iReason:=REASON_DOMAIN_PROJECTION,iValueBool:=TRUE,iValueReal:=0.0,iText:='IO write executed');

// >>> BULK_SYNC_ANCHOR: PRG_IO_Write <<<
