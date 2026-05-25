PROGRAM PRG_Config_Manager
VAR
    L_Error : BOOL;
    L_Staged_Error : BOOL;
    L_Index : INT;
END_VAR

L_Error := FALSE;
L_Staged_Error := FALSE;
GVL_CONFIG_VALIDATION.G_Config_Auto_Corrected := FALSE;
GVL_CONFIG_CONTROL.G_Apply_Done := FALSE;
GVL_CONFIG_CONTROL.G_Rollback_Done := FALSE;

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

// ===== EXISTING ACTIVE VALIDATION =====
IF GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate < 0.0 OR GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate > 1.0 THEN
    GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := 0.05;
    L_Error := TRUE;
END_IF;

// ===== APPLY STAGED CONFIG =====
IF GVL_CONFIG_CONTROL.G_Apply_Request AND GVL_CONFIG_CONTROL.G_Apply_Confirm THEN
    L_Staged_Error := FALSE;

    IF (GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate < 0.0) OR (GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate > 1.0) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG_CONTROL.STG_Reputation_Recovery_Decay < 0.0) OR (GVL_CONFIG_CONTROL.STG_Reputation_Recovery_Decay > 1.0) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG_CONTROL.STG_Min_Sensor_Confidence < 0.0) OR (GVL_CONFIG_CONTROL.STG_Min_Sensor_Confidence > 1.0) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG_CONTROL.STG_Bad_Spike_Confidence < 0.0) OR (GVL_CONFIG_CONTROL.STG_Bad_Spike_Confidence > 1.0) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG_CONTROL.STG_Default_Confidence < 0.0) OR (GVL_CONFIG_CONTROL.STG_Default_Confidence > 1.0) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG_CONTROL.STG_Night_Start_Hour < 0) OR (GVL_CONFIG_CONTROL.STG_Night_Start_Hour > 23) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG_CONTROL.STG_Night_End_Hour < 0) OR (GVL_CONFIG_CONTROL.STG_Night_End_Hour > 23) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF (GVL_CONFIG_CONTROL.STG_VentBoost_Humidity_Threshold < 0.0) OR (GVL_CONFIG_CONTROL.STG_VentBoost_Humidity_Threshold > 100.0) THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF GVL_CONFIG_CONTROL.STG_Stabilization_Delay_MS < 1000 THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF NOT GVL_CONFIG_SIMULATION.G_Simulation_Result_OK THEN
        L_Staged_Error := TRUE;
    END_IF;

    IF L_Staged_Error THEN
        L_Index := GVL_CONFIG_HISTORY.G_History_Index;
        GVL_CONFIG_HISTORY.G_History_Version[L_Index] := GVL_CONFIG_CONTROL.G_Config_Version;
        GVL_CONFIG_HISTORY.G_History_Time_MS[L_Index] := GVL_TIME_SERVICE.G_Now_MS;
        GVL_CONFIG_HISTORY.G_History_Action[L_Index] := 'APPLY_REJECTED';
        GVL_CONFIG_HISTORY.G_Last_Action_Text := 'CONFIG APPLY REJECTED';

        L_Index := L_Index + 1;
        IF L_Index > 5 THEN L_Index := 1; END_IF;
        GVL_CONFIG_HISTORY.G_History_Index := L_Index;

        GVL_CONFIG_VALIDATION.G_Config_Last_Error_Text := 'STAGED CONFIG INVALID';
    ELSE
        // Backup current active values before applying staged values.
        GVL_CONFIG_CONTROL.BCK_Reputation_Learning_Rate := GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate;
        GVL_CONFIG_CONTROL.BCK_Reputation_Recovery_Decay := GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Recovery_Decay;
        GVL_CONFIG_CONTROL.BCK_Min_Sensor_Confidence := GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence;
        GVL_CONFIG_CONTROL.BCK_Bad_Spike_Confidence := GVL_INPUT_VALIDATION_CONFIG.G_Bad_Spike_Confidence;
        GVL_CONFIG_CONTROL.BCK_Default_Confidence := GVL_INPUT_VALIDATION_CONFIG.G_Default_Confidence;

        GVL_CONFIG_CONTROL.BCK_Night_Start_Hour := GVL_SCENARIO_CONFIG.G_Night_Start_Hour;
        GVL_CONFIG_CONTROL.BCK_Night_End_Hour := GVL_SCENARIO_CONFIG.G_Night_End_Hour;
        GVL_CONFIG_CONTROL.BCK_VentBoost_Humidity_Threshold := GVL_SCENARIO_CONFIG.G_VentBoost_Humidity_Threshold;

        GVL_CONFIG_CONTROL.BCK_Stabilization_Delay_MS := GVL_SAFETY_RECOVERY_CONFIG.G_Stabilization_Delay_MS;

        GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Close_Gas := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Close_Gas;
        GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Stop_Boiler := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Boiler;
        GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Block_Heating := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Heating;
        GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Stop_Vent := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Vent;
        GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Block_Water := GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Water;

        // Apply staged input config.
        GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate;
        GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Recovery_Decay := GVL_CONFIG_CONTROL.STG_Reputation_Recovery_Decay;
        GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence := GVL_CONFIG_CONTROL.STG_Min_Sensor_Confidence;
        GVL_INPUT_VALIDATION_CONFIG.G_Bad_Spike_Confidence := GVL_CONFIG_CONTROL.STG_Bad_Spike_Confidence;
        GVL_INPUT_VALIDATION_CONFIG.G_Default_Confidence := GVL_CONFIG_CONTROL.STG_Default_Confidence;

        // Apply staged scenario config.
        GVL_SCENARIO_CONFIG.G_Night_Start_Hour := GVL_CONFIG_CONTROL.STG_Night_Start_Hour;
        GVL_SCENARIO_CONFIG.G_Night_End_Hour := GVL_CONFIG_CONTROL.STG_Night_End_Hour;
        GVL_SCENARIO_CONFIG.G_VentBoost_Humidity_Threshold := GVL_CONFIG_CONTROL.STG_VentBoost_Humidity_Threshold;

        // Apply staged recovery config.
        GVL_SAFETY_RECOVERY_CONFIG.G_Stabilization_Delay_MS := GVL_CONFIG_CONTROL.STG_Stabilization_Delay_MS;

        // Apply staged command-policy critical config.
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Close_Gas := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Close_Gas;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Boiler := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Boiler;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Heating := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Heating;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Vent := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Vent;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Water := GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Water;

        GVL_CONFIG_CONTROL.G_Config_Version := GVL_CONFIG_CONTROL.G_Config_Version + 1;
        GVL_CONFIG_CONTROL.G_Last_Good_Version := GVL_CONFIG_CONTROL.G_Config_Version;
        GVL_CONFIG_CONTROL.G_Backup_Valid := TRUE;
        GVL_CONFIG_CONTROL.G_Apply_Done := TRUE;

        L_Index := GVL_CONFIG_HISTORY.G_History_Index;
        GVL_CONFIG_HISTORY.G_History_Version[L_Index] := GVL_CONFIG_CONTROL.G_Config_Version;
        GVL_CONFIG_HISTORY.G_History_Time_MS[L_Index] := GVL_TIME_SERVICE.G_Now_MS;
        GVL_CONFIG_HISTORY.G_History_Action[L_Index] := 'APPLY';
        GVL_CONFIG_HISTORY.G_Last_Action_Text := 'CONFIG APPLY';

        L_Index := L_Index + 1;
        IF L_Index > 5 THEN L_Index := 1; END_IF;
        GVL_CONFIG_HISTORY.G_History_Index := L_Index;
    END_IF;

    GVL_CONFIG_CONTROL.G_Apply_Request := FALSE;
    GVL_CONFIG_CONTROL.G_Apply_Confirm := FALSE;
END_IF;

// ===== ROLLBACK TO LAST BACKUP =====
IF GVL_CONFIG_CONTROL.G_Rollback_Request AND GVL_CONFIG_CONTROL.G_Rollback_Confirm THEN
    IF GVL_CONFIG_CONTROL.G_Backup_Valid THEN
        GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := GVL_CONFIG_CONTROL.BCK_Reputation_Learning_Rate;
        GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Recovery_Decay := GVL_CONFIG_CONTROL.BCK_Reputation_Recovery_Decay;
        GVL_INPUT_VALIDATION_CONFIG.G_Min_Sensor_Confidence := GVL_CONFIG_CONTROL.BCK_Min_Sensor_Confidence;
        GVL_INPUT_VALIDATION_CONFIG.G_Bad_Spike_Confidence := GVL_CONFIG_CONTROL.BCK_Bad_Spike_Confidence;
        GVL_INPUT_VALIDATION_CONFIG.G_Default_Confidence := GVL_CONFIG_CONTROL.BCK_Default_Confidence;

        GVL_SCENARIO_CONFIG.G_Night_Start_Hour := GVL_CONFIG_CONTROL.BCK_Night_Start_Hour;
        GVL_SCENARIO_CONFIG.G_Night_End_Hour := GVL_CONFIG_CONTROL.BCK_Night_End_Hour;
        GVL_SCENARIO_CONFIG.G_VentBoost_Humidity_Threshold := GVL_CONFIG_CONTROL.BCK_VentBoost_Humidity_Threshold;

        GVL_SAFETY_RECOVERY_CONFIG.G_Stabilization_Delay_MS := GVL_CONFIG_CONTROL.BCK_Stabilization_Delay_MS;

        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Close_Gas := GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Close_Gas;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Boiler := GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Stop_Boiler;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Heating := GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Block_Heating;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Vent := GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Stop_Vent;
        GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Water := GVL_CONFIG_CONTROL.BCK_PLC_Inactive_Block_Water;

        GVL_CONFIG_CONTROL.G_Config_Version := GVL_CONFIG_CONTROL.G_Config_Version + 1;
        GVL_CONFIG_CONTROL.G_Rollback_Done := TRUE;

        L_Index := GVL_CONFIG_HISTORY.G_History_Index;
        GVL_CONFIG_HISTORY.G_History_Version[L_Index] := GVL_CONFIG_CONTROL.G_Config_Version;
        GVL_CONFIG_HISTORY.G_History_Time_MS[L_Index] := GVL_TIME_SERVICE.G_Now_MS;
        GVL_CONFIG_HISTORY.G_History_Action[L_Index] := 'ROLLBACK';
        GVL_CONFIG_HISTORY.G_Last_Action_Text := 'CONFIG ROLLBACK';

        L_Index := L_Index + 1;
        IF L_Index > 5 THEN L_Index := 1; END_IF;
        GVL_CONFIG_HISTORY.G_History_Index := L_Index;
    ELSE
        GVL_CONFIG_HISTORY.G_Last_Action_Text := 'CONFIG ROLLBACK REJECTED - NO BACKUP';
    END_IF;

    GVL_CONFIG_CONTROL.G_Rollback_Request := FALSE;
    GVL_CONFIG_CONTROL.G_Rollback_Confirm := FALSE;
END_IF;

GVL_CONFIG_VALIDATION.G_Config_Valid := NOT L_Error;
GVL_CONFIG_VALIDATION.G_Config_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Config_Manager <<<
END_PROGRAM
