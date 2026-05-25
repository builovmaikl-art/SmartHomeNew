PROGRAM PRG_Config_Versioning
VAR
    L_i : INT;
    L_Config_Error : BOOL;
END_VAR

// Detect config error from validation layer.
// Calibration processor faults are surfaced through Sensor_Fault, so the
// configuration rollback snapshot must include calibration records too.
L_Config_Error := GVL_STATUS.G_Diagnostics.Sensor_Fault OR GVL_STATUS.G_Diagnostics.Subsystem_Degraded;

// --- Save snapshot when system is healthy ---
IF NOT L_Config_Error THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        GVL_CONFIG_BACKUP.G_Backup_FloorHeating_Configs[L_i] := GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i];
    END_FOR;

    GVL_CONFIG_BACKUP.G_Backup_Max_Active_Manifolds := GVL_CONFIG.G_Max_Active_Manifolds;
    GVL_CONFIG_BACKUP.G_Backup_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget;

    GVL_CONFIG_BACKUP.G_Backup_Calib_Outdoor_Temp := GVL_CONFIG.G_Calib_Outdoor_Temp;
    GVL_CONFIG_BACKUP.G_Backup_Calib_Ambient_Lux := GVL_CONFIG.G_Calib_Ambient_Lux;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS DO
        GVL_CONFIG_BACKUP.G_Backup_Calib_Supply_Temps[L_i] := GVL_CONFIG.G_Calib_Supply_Temps[L_i];
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
        GVL_CONFIG_BACKUP.G_Backup_Calib_Room_Temps[L_i] := GVL_CONFIG.G_Calib_Room_Temps[L_i];
        GVL_CONFIG_BACKUP.G_Backup_Calib_Floor_Temps[L_i] := GVL_CONFIG.G_Calib_Floor_Temps[L_i];
        GVL_CONFIG_BACKUP.G_Backup_Calib_CO2[L_i] := GVL_CONFIG.G_Calib_CO2[L_i];
        GVL_CONFIG_BACKUP.G_Backup_Calib_Humidity[L_i] := GVL_CONFIG.G_Calib_Humidity[L_i];
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_CONFIG_BACKUP.G_Backup_Calib_Manifold_T_Supply[L_i] := GVL_CONFIG.G_Calib_Manifold_T_Supply[L_i];
        GVL_CONFIG_BACKUP.G_Backup_Calib_Manifold_T_Return[L_i] := GVL_CONFIG.G_Calib_Manifold_T_Return[L_i];
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
        GVL_CONFIG_BACKUP.G_Backup_Calib_Methane[L_i] := GVL_CONFIG.G_Calib_Methane[L_i];
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
        GVL_CONFIG_BACKUP.G_Backup_Calib_CO[L_i] := GVL_CONFIG.G_Calib_CO[L_i];
    END_FOR;

    GVL_CONFIG_BACKUP.G_Backup_Valid := TRUE;
END_IF;

// --- Rollback if config invalid ---
IF L_Config_Error THEN

    // Freeze system via command layer
    GVL_COMMAND_SHADOW.G_Heating_Block := TRUE;
    GVL_COMMAND_SHADOW.G_Boiler_Stop := TRUE;

    // Restore snapshot only if valid
    IF GVL_CONFIG_BACKUP.G_Backup_Valid THEN
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
            GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i] := GVL_CONFIG_BACKUP.G_Backup_FloorHeating_Configs[L_i];
        END_FOR;

        GVL_CONFIG.G_Max_Active_Manifolds := GVL_CONFIG_BACKUP.G_Backup_Max_Active_Manifolds;
        GVL_CONFIG.G_Max_Thermal_Budget := GVL_CONFIG_BACKUP.G_Backup_Max_Thermal_Budget;

        GVL_CONFIG.G_Calib_Outdoor_Temp := GVL_CONFIG_BACKUP.G_Backup_Calib_Outdoor_Temp;
        GVL_CONFIG.G_Calib_Ambient_Lux := GVL_CONFIG_BACKUP.G_Backup_Calib_Ambient_Lux;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS DO
            GVL_CONFIG.G_Calib_Supply_Temps[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_Supply_Temps[L_i];
        END_FOR;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
            GVL_CONFIG.G_Calib_Room_Temps[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_Room_Temps[L_i];
            GVL_CONFIG.G_Calib_Floor_Temps[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_Floor_Temps[L_i];
            GVL_CONFIG.G_Calib_CO2[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_CO2[L_i];
            GVL_CONFIG.G_Calib_Humidity[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_Humidity[L_i];
        END_FOR;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_CONFIG.G_Calib_Manifold_T_Supply[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_Manifold_T_Supply[L_i];
            GVL_CONFIG.G_Calib_Manifold_T_Return[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_Manifold_T_Return[L_i];
        END_FOR;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
            GVL_CONFIG.G_Calib_Methane[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_Methane[L_i];
        END_FOR;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
            GVL_CONFIG.G_Calib_CO[L_i] := GVL_CONFIG_BACKUP.G_Backup_Calib_CO[L_i];
        END_FOR;

        GVL_STATUS.G_System_Mode_Text := 'CONFIG ROLLBACK';
    ELSE
        GVL_STATUS.G_System_Mode_Text := 'CONFIG INVALID - NO BACKUP';
    END_IF;
END_IF;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_Config_Versioning <<<
