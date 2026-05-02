PROGRAM PRG_Config_Validation
VAR
    L_i : INT;
END_VAR

// Reset flags
GVL_DIAGNOSTICS.G_Config_Error := FALSE;
GVL_DIAGNOSTICS.G_Error_Message := '';

// --- Max zones check ---
IF GVL_CONFIG.G_Active_Zones_Count > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS THEN
    GVL_DIAGNOSTICS.G_Config_Error := TRUE;
    GVL_DIAGNOSTICS.G_Error_Message := 'Too many active zones';
END_IF;

// --- Zone sensor presence ---
FOR L_i := 1 TO GVL_CONFIG.G_Active_Zones_Count DO
    IF NOT GVL_CONFIG.G_Zone_Has_Temp_Sensor[L_i] THEN
        GVL_DIAGNOSTICS.G_Config_Error := TRUE;
        GVL_DIAGNOSTICS.G_Error_Message := CONCAT('Zone missing sensor: ', INT_TO_STRING(L_i));
    END_IF;
END_FOR;

// --- Range checks ---
IF GVL_CONFIG.Weather_Coef < 0.0 OR GVL_CONFIG.Weather_Coef > 5.0 THEN
    GVL_DIAGNOSTICS.G_Config_Error := TRUE;
    GVL_DIAGNOSTICS.G_Error_Message := 'Weather coef out of range';
END_IF;

// --- Fail safe ---
IF GVL_DIAGNOSTICS.G_Config_Error THEN
    GVL_SYSTEM_FLAGS.G_System_Stop := TRUE;
END_IF;

END_PROGRAM
