PROGRAM PRG_System_Init
VAR
    L_i : INT;
    L_Init_Done : BOOL := FALSE;
END_VAR

// Execute only once at startup
IF L_Init_Done THEN RETURN; END_IF;

// Validate zone count
IF GVL_CONFIG.G_Active_Zones_Count > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS THEN
    GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
    GVL_STATUS.G_System_Mode_Text := 'CONFIG ERROR: too many zones';
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
END_IF;

// Validate sensors presence
FOR L_i := 1 TO GVL_CONFIG.G_Active_Zones_Count DO
    IF NOT GVL_CONFIG.G_Zone_Has_Temp_Sensor[L_i] THEN
        GVL_STATUS.G_Diagnostics.Sensor_Fault := TRUE;
        GVL_STATUS.G_System_Mode_Text := CONCAT('CONFIG ERROR ZONE ', INT_TO_STRING(L_i));
        GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
        GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;
    END_IF;
END_FOR;

L_Init_Done := TRUE;

// >>> BULK_SYNC_ANCHOR: PRG_System_Init <<<
