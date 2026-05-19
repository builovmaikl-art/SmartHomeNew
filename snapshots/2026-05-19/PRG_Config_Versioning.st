PROGRAM PRG_Config_Versioning
VAR
    L_i : INT;
    L_Config_Error : BOOL;
END_VAR

// Detect config error from validation layer
L_Config_Error := GVL_STATUS.G_Diagnostics.Sensor_Fault OR GVL_STATUS.G_Diagnostics.Subsystem_Degraded;

// --- Save snapshot when system is healthy ---
IF NOT L_Config_Error THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        GVL_CONFIG_BACKUP.G_Backup_FloorHeating_Configs[L_i] := GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i];
    END_FOR;

    GVL_CONFIG_BACKUP.G_Backup_Max_Active_Manifolds := GVL_CONFIG.G_Max_Active_Manifolds;
    GVL_CONFIG_BACKUP.G_Backup_Max_Thermal_Budget := GVL_CONFIG.G_Max_Thermal_Budget;

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

        GVL_STATUS.G_System_Mode_Text := 'CONFIG ROLLBACK';
    ELSE
        GVL_STATUS.G_System_Mode_Text := 'CONFIG INVALID - NO BACKUP';
    END_IF;
END_IF;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_Config_Versioning <<<
