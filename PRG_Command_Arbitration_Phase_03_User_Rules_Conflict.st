PROGRAM PRG_Command_Arbitration_Phase_03_User_Rules_Conflict
// Command arbitration phase 03: user intent, automation rules and conflict cleanup.
VAR
    L_i : INT;
END_VAR

GVL_COMMAND_ARBITRATION_BUFFER.B_User_Access_OK :=
    GVL_INTENT_USER.I_Source_Valid
    AND (GVL_INTENT_USER.I_User_Access_Level >= 2);

IF (NOT GVL_COMMAND_ARBITRATION_BUFFER.B_Safety_Active)
   AND GVL_COMMAND_ARBITRATION_BUFFER.B_User_Access_OK THEN

    IF GVL_INTENT_USER.I_Lock_1_Open_Request THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Open := TRUE;
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Close := FALSE;
    ELSIF GVL_INTENT_USER.I_Lock_1_Close_Request THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Open := FALSE;
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Close := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Lock_2_Open_Request THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Open := TRUE;
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Close := FALSE;
    ELSIF GVL_INTENT_USER.I_Lock_2_Close_Request THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Open := FALSE;
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Close := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Gate_Open_Request THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Gate_Open := TRUE;
    END_IF;

    IF GVL_INTENT_USER.I_Wicket_Open_Request THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Wicket_Open := TRUE;
    END_IF;
END_IF;

IF (NOT GVL_COMMAND_ARBITRATION_BUFFER.B_Safety_Active)
   AND GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Request THEN
    GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Open := FALSE;
    GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Close := TRUE;
    GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Open := FALSE;
    GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Close := TRUE;
    GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Accepted_By_Arbitration := TRUE;
    GVL_SECURITY_ACCESS_INTENT.G_Status_Text := 'Security auto-lock accepted by arbitration';
END_IF;

// Dangerous user actions require explicit confirmation and elevated access.
IF (NOT GVL_COMMAND_ARBITRATION_BUFFER.B_Safety_Active)
   AND GVL_INTENT_USER.I_Source_Valid
   AND GVL_INTENT_USER.I_Dangerous_Action_Request
   AND GVL_INTENT_USER.I_Dangerous_Action_Confirm
   AND (GVL_INTENT_USER.I_User_Access_Level >= 2) THEN
    // Reserved for future high-risk manual actions.
    // No direct safety override is allowed here.
END_IF;

IF NOT GVL_COMMAND_ARBITRATION_BUFFER.B_Safety_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF GVL_STATE.G_Rule_Actions[L_i].Active AND GVL_STATE.G_Rule_Actions[L_i].Triggered THEN
            CASE GVL_STATE.G_Rule_Actions[L_i].Action_Type OF

                ACTION_SET_FLOOR_HEATING:
                    IF GVL_STATE.G_Rule_Actions[L_i].Value <= 0.0 THEN
                        GVL_COMMAND_ARBITRATION_BUFFER.B_Heating_Block := TRUE;
                        GVL_COMMAND_ARBITRATION_BUFFER.B_Boiler_Stop := TRUE;
                    END_IF;

                ACTION_SET_VENTILATION:
                    IF GVL_STATE.G_Rule_Actions[L_i].Value <= 0.0 THEN
                        GVL_COMMAND_ARBITRATION_BUFFER.B_Vent_Stop := TRUE;
                    END_IF;

            ELSE
                // Non command-level actions are handled by their own subsystem.
            END_CASE;
        END_IF;
    END_FOR;
END_IF;

IF (GVL_COMMAND_ARBITRATION_BUFFER.B_Mode = FIRE)
   AND GVL_COMMAND_POLICY_CONFIG.G_Fire_Block_Lock_Close THEN
    GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Close := FALSE;
    GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Close := FALSE;
END_IF;

IF GVL_COMMAND_POLICY_CONFIG.G_Block_Close_When_Open_Commanded THEN
    IF GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Open
       AND GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Close THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_1_Close := FALSE;
    END_IF;

    IF GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Open
       AND GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Close THEN
        GVL_COMMAND_ARBITRATION_BUFFER.B_Lock_2_Close := FALSE;
    END_IF;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Command_Arbitration_Phase_03_User_Rules_Conflict <<<
END_PROGRAM