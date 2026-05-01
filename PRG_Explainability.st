PROGRAM PRG_Explainability
VAR
    L_Mode : E_Safety_Mode;
    L_Recovery : E_Recovery_Phase;
    L_Command : STRING(120);
END_VAR

L_Mode := GVL_SAFETY_SHUTDOWN.G_Safety_Mode;
L_Recovery := GVL_SAFETY_RECOVERY.G_Recovery_Phase;

GVL_EXPLAINABILITY.G_Last_Safety_Mode := L_Mode;
GVL_EXPLAINABILITY.G_Last_Recovery_Phase := L_Recovery;
GVL_EXPLAINABILITY.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// SAFETY LEVEL
CASE L_Mode OF
    FIRE: GVL_EXPLAINABILITY.G_Reason_Chain_Safety := 'FIRE';
    GAS: GVL_EXPLAINABILITY.G_Reason_Chain_Safety := 'GAS';
    WATER_LEAK: GVL_EXPLAINABILITY.G_Reason_Chain_Safety := 'WATER';
    GLOBAL_STOP: GVL_EXPLAINABILITY.G_Reason_Chain_Safety := 'GLOBAL_STOP';
    EVACUATION: GVL_EXPLAINABILITY.G_Reason_Chain_Safety := 'EVACUATION';
    ELSE
        IF GVL_SAFETY_RECOVERY.G_Recovery_Active THEN
            GVL_EXPLAINABILITY.G_Reason_Chain_Safety := 'RECOVERY';
        ELSE
            GVL_EXPLAINABILITY.G_Reason_Chain_Safety := 'NORMAL';
        END_IF;
END_CASE;

// BEHAVIOR LEVEL
GVL_EXPLAINABILITY.G_Reason_Chain_Behavior := GVL_INTENT_BEHAVIOR.I_Reason_Text;

// COMMAND LEVEL
IF GVL_COMMAND_SHADOW.G_Heating_Block THEN
    L_Command := 'Heating Blocked';
ELSIF GVL_COMMAND_SHADOW.G_Vent_Stop THEN
    L_Command := 'Vent Stopped';
ELSIF GVL_COMMAND_SHADOW.G_Water_Block THEN
    L_Command := 'Water Blocked';
ELSE
    L_Command := 'Command OK';
END_IF;
GVL_EXPLAINABILITY.G_Reason_Chain_Command := L_Command;

// OUTPUT LEVEL
GVL_EXPLAINABILITY.G_Reason_Chain_Output := 'Outputs Applied';

// FULL CHAIN
GVL_EXPLAINABILITY.G_Reason_Chain_Full := CONCAT(CONCAT(CONCAT(GVL_EXPLAINABILITY.G_Reason_Chain_Safety, ' -> '), CONCAT(GVL_EXPLAINABILITY.G_Reason_Chain_Behavior, ' -> ')), CONCAT(GVL_EXPLAINABILITY.G_Reason_Chain_Command, ' -> Outputs Applied'));

// KEEP OLD FIELDS
GVL_EXPLAINABILITY.G_Behavior_Why_Active := GVL_INTENT_BEHAVIOR.I_Reason_Text;

END_PROGRAM