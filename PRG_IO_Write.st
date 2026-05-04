PROGRAM PRG_IO_Write
VAR
    L_i : INT;
    L_Heating_Forced_Off : BOOL;
    L_Vent_Forced_Off : BOOL;
    L_Water_Forced_Off : BOOL;
    L_Access_Forced_Off : BOOL;
    L_Global_Hard_Stop : BOOL;
    L_Gas_Safety_Stop : BOOL;
    L_Freeze_Active : BOOL;
    fbTrace : FB_Trace_Write;
END_VAR

L_Global_Hard_Stop :=
    GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop OR
    GVL_COMMAND_SHADOW.G_Gas_Valve_Close;

L_Gas_Safety_Stop :=
    GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop OR
    GVL_COMMAND_SHADOW.G_Boiler_Stop;

L_Freeze_Active := GVL_STATE.G_Safety_Freeze_Risk;

IF NOT GVL_STATUS.G_Is_Active_PLC OR L_Global_Hard_Stop THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_IO.AO_Lighting_Levels[L_i] := 0;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
        GVL_IO.AO_Blinds_Positions[L_i] := 1000;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
        GVL_IO.DO_Sockets[L_i] := FALSE;
    END_FOR;

    GVL_IO.DO_Gas_Siren := GVL_ALARM.G_Gas_Fire_Siren;
    GVL_IO.DO_Fire_Siren := GVL_ALARM.G_Fire_Alarm_Active;
    GVL_IO.DO_Security_Siren := GVL_ALARM.G_Security_Siren;

    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    GVL_IO.AO_Lighting_Levels[L_i] := BYTE_TO_UINT(GVL_STATE.G_Lighting_Levels[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    GVL_IO.AO_Blinds_Positions[L_i] := BYTE_TO_UINT(GVL_STATE.G_Blinds_Positions[L_i]) * 10;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    GVL_IO.DO_Sockets[L_i] := GVL_STATE.G_Socket_States[L_i];
END_FOR;

GVL_IO.DO_Gas_Siren := GVL_ALARM.G_Gas_Fire_Siren;
GVL_IO.DO_Fire_Siren := GVL_ALARM.G_Fire_Alarm_Active;
GVL_IO.DO_Security_Siren := GVL_ALARM.G_Security_Siren;

fbTrace(
    iLayer := TRACE_IO,
    iSource := SRC_IO,
    iReason := REASON_DOMAIN_PROJECTION,
    iValueBool := TRUE,
    iValueReal := 0.0,
    iText := 'IO write projection executed'
);

END_PROGRAM
