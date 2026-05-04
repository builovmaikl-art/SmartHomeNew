PROGRAM PRG_System_Init
VAR
    L_i : INT;
    L_Init_Done : BOOL := FALSE;
    L_Active_Zones_Count : INT;
    L_Zone_Index : INT;
END_VAR

IF L_Init_Done THEN
    RETURN;
END_IF;

L_Active_Zones_Count := GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits;

IF (L_Active_Zones_Count < 1) OR (L_Active_Zones_Count > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) THEN
    GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    GVL_STATUS.G_System_Mode_Text := 'CONFIG ERROR: invalid active heating circuits';
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    L_Active_Zones_Count := GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS;
END_IF;

FOR L_i := 1 TO L_Active_Zones_Count DO
    L_Zone_Index := GVL_CONFIG.G_Heating_Circuit_To_Zone[L_i];
    IF (L_Zone_Index < 1) OR (L_Zone_Index > GVL_CONSTANTS.C_MAX_ZONES) THEN
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
        GVL_STATUS.G_System_Mode_Text := CONCAT('CONFIG ERROR CIRCUIT ', INT_TO_STRING(L_i));
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    END_IF;
END_FOR;

L_Init_Done := TRUE;

// >>> BULK_SYNC_ANCHOR: PRG_System_Init <<<
