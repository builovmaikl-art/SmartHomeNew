PROGRAM PRG_Config_Manager
VAR
    L_Error : BOOL;
    L_Index : INT;
END_VAR

L_Error := FALSE;
GVL_CONFIG_VALIDATION.G_Config_Auto_Corrected := FALSE;
GVL_CONFIG_CONTROL.G_Apply_Done := FALSE;
GVL_CONFIG_CONTROL.G_Rollback_Done := FALSE;

// ================= VALIDATION =================
IF GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate < 0.0 OR GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate > 1.0 THEN
    GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := 0.05;
    L_Error := TRUE;
END_IF;

// integrity: invalid time window
IF GVL_SCENARIO_CONFIG.G_Night_Start_Hour = GVL_SCENARIO_CONFIG.G_Night_End_Hour THEN
    GVL_SCENARIO_CONFIG.G_Night_Start_Hour := 22;
    GVL_SCENARIO_CONFIG.G_Night_End_Hour := 6;
    L_Error := TRUE;
END_IF;

IF GVL_SAFETY_RECOVERY_CONFIG.G_Stabilization_Delay_MS < 1000 THEN
    GVL_SAFETY_RECOVERY_CONFIG.G_Stabilization_Delay_MS := 5000;
    L_Error := TRUE;
END_IF;

// fail-safe guarantee
IF NOT (
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Close_Gas OR
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Boiler OR
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Heating OR
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Vent OR
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Water
) THEN
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Close_Gas := TRUE;
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Boiler := TRUE;
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Heating := TRUE;
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Stop_Vent := TRUE;
    GVL_COMMAND_POLICY_CONFIG.G_PLC_Inactive_Block_Water := TRUE;
    L_Error := TRUE;
END_IF;

// ================= APPLY =================
IF GVL_CONFIG_CONTROL.G_Apply_Request AND GVL_CONFIG_CONTROL.G_Apply_Confirm THEN

    // backup
    GVL_CONFIG_CONTROL.BCK_Reputation_Learning_Rate := GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate;

    // apply staged
    GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate;

    // version
    GVL_CONFIG_CONTROL.G_Config_Version := GVL_CONFIG_CONTROL.G_Config_Version + 1;
    GVL_CONFIG_CONTROL.G_Last_Good_Version := GVL_CONFIG_CONTROL.G_Config_Version;

    // history
    L_Index := GVL_CONFIG_HISTORY.G_History_Index;
    GVL_CONFIG_HISTORY.G_History_Version[L_Index] := GVL_CONFIG_CONTROL.G_Config_Version;
    GVL_CONFIG_HISTORY.G_History_Time_MS[L_Index] := GVL_TIME_SERVICE.G_Now_MS;
    GVL_CONFIG_HISTORY.G_History_Action[L_Index] := 'APPLY';

    GVL_CONFIG_HISTORY.G_Last_Changed_By_Level := GVL_INTENT_USER.I_User_Access_Level;
    GVL_CONFIG_HISTORY.G_Last_Action_Text := 'Config applied';

    L_Index := L_Index + 1;
    IF L_Index > 5 THEN L_Index := 1; END_IF;
    GVL_CONFIG_HISTORY.G_History_Index := L_Index;

    GVL_CONFIG_CONTROL.G_Backup_Valid := TRUE;
    GVL_CONFIG_CONTROL.G_Apply_Done := TRUE;
END_IF;

// ================= ROLLBACK =================
IF GVL_CONFIG_CONTROL.G_Rollback_Request AND GVL_CONFIG_CONTROL.G_Rollback_Confirm AND GVL_CONFIG_CONTROL.G_Backup_Valid THEN

    GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := GVL_CONFIG_CONTROL.BCK_Reputation_Learning_Rate;

    L_Index := GVL_CONFIG_HISTORY.G_History_Index;
    GVL_CONFIG_HISTORY.G_History_Version[L_Index] := GVL_CONFIG_CONTROL.G_Config_Version;
    GVL_CONFIG_HISTORY.G_History_Time_MS[L_Index] := GVL_TIME_SERVICE.G_Now_MS;
    GVL_CONFIG_HISTORY.G_History_Action[L_Index] := 'ROLLBACK';

    GVL_CONFIG_HISTORY.G_Last_Changed_By_Level := GVL_INTENT_USER.I_User_Access_Level;
    GVL_CONFIG_HISTORY.G_Last_Action_Text := 'Rollback executed';

    L_Index := L_Index + 1;
    IF L_Index > 5 THEN L_Index := 1; END_IF;
    GVL_CONFIG_HISTORY.G_History_Index := L_Index;

    GVL_CONFIG_CONTROL.G_Rollback_Done := TRUE;
END_IF;

// ================= RESET =================
IF GVL_CONFIG_CONTROL.G_Reset_Default_Request AND GVL_CONFIG_CONTROL.G_Reset_Default_Confirm THEN

    GVL_INPUT_VALIDATION_CONFIG.G_Reputation_Learning_Rate := 0.05;

    L_Index := GVL_CONFIG_HISTORY.G_History_Index;
    GVL_CONFIG_HISTORY.G_History_Version[L_Index] := GVL_CONFIG_CONTROL.G_Config_Version;
    GVL_CONFIG_HISTORY.G_History_Time_MS[L_Index] := GVL_TIME_SERVICE.G_Now_MS;
    GVL_CONFIG_HISTORY.G_History_Action[L_Index] := 'RESET';

    GVL_CONFIG_HISTORY.G_Last_Changed_By_Level := GVL_INTENT_USER.I_User_Access_Level;
    GVL_CONFIG_HISTORY.G_Last_Action_Text := 'Reset to default';

    L_Index := L_Index + 1;
    IF L_Index > 5 THEN L_Index := 1; END_IF;
    GVL_CONFIG_HISTORY.G_History_Index := L_Index;

    GVL_CONFIG_VALIDATION.G_Config_Reset_To_Default_Done := TRUE;
END_IF;

// ================= FINAL =================
GVL_CONFIG_VALIDATION.G_Config_Valid := NOT L_Error;
GVL_CONFIG_VALIDATION.G_Config_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Config_Manager <<<
