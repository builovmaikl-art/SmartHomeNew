PROGRAM PRG_Explainability
VAR
    L_Mode : E_Safety_Mode;
    L_Recovery : E_Recovery_Phase;
END_VAR

L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
L_Recovery := GVL_SAFETY_RECOVERY.G_Recovery_Phase;

GVL_EXPLAINABILITY.G_Last_Safety_Mode := L_Mode;
GVL_EXPLAINABILITY.G_Last_Recovery_Phase := L_Recovery;
GVL_EXPLAINABILITY.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// ============================================================
// GLOBAL REASON (Safety / Recovery)
// ============================================================
CASE L_Mode OF
    FIRE:
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Code := REASON_FIRE;
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Text := 'Fire safety mode active';
    GAS:
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Code := REASON_GAS;
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Text := 'Gas safety mode active';
    WATER_LEAK:
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Code := REASON_WATER_LEAK;
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Text := 'Water leak detected';
    GLOBAL_STOP:
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Code := REASON_GLOBAL_STOP;
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Text := 'Global stop active';
    EVACUATION:
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Code := REASON_EVACUATION;
        GVL_EXPLAINABILITY.G_Last_Global_Reason_Text := 'Evacuation mode active';
    NORMAL:
        IF GVL_SAFETY_RECOVERY.G_Recovery_Active THEN
            GVL_EXPLAINABILITY.G_Last_Global_Reason_Code := REASON_RECOVERY_ACTIVE;
            GVL_EXPLAINABILITY.G_Last_Global_Reason_Text := 'System in recovery phase';
        ELSE
            GVL_EXPLAINABILITY.G_Last_Global_Reason_Code := REASON_NONE;
            GVL_EXPLAINABILITY.G_Last_Global_Reason_Text := 'System in normal operation';
        END_IF;
END_CASE;

// ============================================================
// BEHAVIOR REASON
// ============================================================
GVL_EXPLAINABILITY.G_Behavior_Why_Active := GVL_INTENT_BEHAVIOR.I_Reason_Text;

// ============================================================
// DOMAIN EXPLANATIONS
// ============================================================
IF GVL_COMMAND_SHADOW.G_Heating_Block THEN
    GVL_EXPLAINABILITY.G_Heating_Why_Blocked := 'Heating blocked (safety / recovery / behavior)';
ELSE
    GVL_EXPLAINABILITY.G_Heating_Why_Blocked := '';
END_IF;

IF GVL_COMMAND_SHADOW.G_Vent_Stop THEN
    GVL_EXPLAINABILITY.G_Vent_Why_Stopped := 'Ventilation stopped (safety / recovery)';
ELSE
    GVL_EXPLAINABILITY.G_Vent_Why_Stopped := '';
END_IF;

IF GVL_COMMAND_SHADOW.G_Close_Valve_35 OR GVL_COMMAND_SHADOW.G_Close_Valve_36 THEN
    GVL_EXPLAINABILITY.G_Water_Why_Closed := 'Water valves closed (safety command)';
ELSE
    GVL_EXPLAINABILITY.G_Water_Why_Closed := '';
END_IF;

IF GVL_COMMAND_SHADOW.G_Lock_1_Open OR GVL_COMMAND_SHADOW.G_Lock_2_Open THEN
    GVL_EXPLAINABILITY.G_Access_Why_Opened := 'Access opened (evacuation / override)';
ELSE
    GVL_EXPLAINABILITY.G_Access_Why_Opened := '';
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Explainability <<<
