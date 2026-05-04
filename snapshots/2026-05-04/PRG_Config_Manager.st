PROGRAM PRG_Config_Manager
VAR
    L_Error : BOOL;
    L_Index : INT;
END_VAR

L_Error := FALSE;
GVL_CONFIG_VALIDATION.G_Config_Auto_Corrected := FALSE;
GVL_CONFIG_CONTROL.G_Apply_Done := FALSE;
GVL_CONFIG_CONTROL.G_Rollback_Done := FALSE;

IF NOT GVL_CONFIG_SIMULATION.G_Simulation_Result_OK THEN
    GVL_CONFIG_CONTROL.G_Apply_Request := FALSE;
END_IF;

// ===== SIZE VALIDATION =====
IF GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits < 1 OR GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS THEN
    GVL_SYSTEM_SIZE_CONFIG.G_Active_Heating_Circuits := GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS;
    L_Error := TRUE;
END_IF;

IF GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones < 1 OR GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones > GVL_CONSTANTS.C_MAX_WATER_ZONES THEN
    GVL_SYSTEM_SIZE_CONFIG.G_Active_Water_Zones := GVL_CONSTANTS.C_MAX_WATER_ZONES;
    L_Error := TRUE;
END_IF;

IF GVL_SYSTEM_SIZE_CONFIG.G_Active_Light_Zones < 1 OR GVL_SYSTEM_SIZE_CONFIG.G_Active_Light_Zones > GVL_CONSTANTS.C_MAX_LIGHT_ZONES THEN
    GVL_SYSTEM_SIZE_CONFIG.G_Active_Light_Zones := GVL_CONSTANTS.C_MAX_LIGHT_ZONES;
    L_Error := TRUE;
END_IF;

// ===== EXISTING VALIDATION =====
IF GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate < 0.0 OR GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate > 1.0 THEN
    GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := 0.05;
    L_Error := TRUE;
END_IF;

// ===== APPLY (unchanged) =====
IF GVL_CONFIG_CONTROL.G_Apply_Request AND GVL_CONFIG_CONTROL.G_Apply_Confirm THEN
    GVL_CONFIG_CONTROL.BCK_Reputation_Learning_Rate := GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate;
    GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate;

    GVL_CONFIG_CONTROL.G_Config_Version := GVL_CONFIG_CONTROL.G_Config_Version + 1;

    L_Index := GVL_CONFIG_HISTORY.G_History_Index;
    GVL_CONFIG_HISTORY.G_History_Version[L_Index] := GVL_CONFIG_CONTROL.G_Config_Version;
    GVL_CONFIG_HISTORY.G_History_Time_MS[L_Index] := GVL_TIME_SERVICE.G_Now_MS;
    GVL_CONFIG_HISTORY.G_History_Action[L_Index] := 'APPLY';

    L_Index := L_Index + 1;
    IF L_Index > 5 THEN L_Index := 1; END_IF;
    GVL_CONFIG_HISTORY.G_History_Index := L_Index;

    GVL_CONFIG_CONTROL.G_Backup_Valid := TRUE;
    GVL_CONFIG_CONTROL.G_Apply_Done := TRUE;
END_IF;

GVL_CONFIG_VALIDATION.G_Config_Valid := NOT L_Error;
GVL_CONFIG_VALIDATION.G_Config_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Config_Manager <<<
