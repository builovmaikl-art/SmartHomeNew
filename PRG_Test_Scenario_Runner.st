PROGRAM PRG_Test_Scenario_Runner
VAR
    L_Expected : E_SCENARIO_TYPE;
END_VAR

IF NOT GVL_TEST.G_Test_Enable THEN
    RETURN;
END_IF;

IF NOT GVL_TEST_INJECTION.G_Scenario_Enable THEN
    RETURN;
END_IF;

IF GVL_TEST_INJECTION.G_Scenario_Reset_Request THEN
    GVL_TEST_INJECTION.G_Scenario_Step := 0;
    GVL_TEST_INJECTION.G_Scenario_Done := FALSE;
    GVL_TEST_INJECTION.G_Scenario_Failed := FALSE;
    GVL_TEST_INJECTION.G_Scenario_Last_Result_Code := 0;
    GVL_TEST_INJECTION.G_Scenario_Reset_Request := FALSE;
END_IF;

CASE GVL_TEST_INJECTION.G_Scenario_Current OF

1:
    L_Expected := E_SCENARIO_TYPE.SCENARIO_MORNING;
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_COMMAND.G_Scenario_Request_Operator := L_Expected;
        GVL_INTENT_USER.I_Scenario_Request := E_SCENARIO_TYPE.SCENARIO_AWAY;
        GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 1: operator priority';
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        IF GVL_STATUS.G_Current_Scenario = L_Expected THEN
            GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Last_Result_Code := 101;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 1 passed';
        ELSE
            GVL_TEST_INJECTION.G_Scenario_Failed := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Last_Result_Code := 1001;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 1 failed';
        END_IF;
    END_CASE;

2:
    L_Expected := E_SCENARIO_TYPE.SCENARIO_AWAY;
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_COMMAND.G_Scenario_Request_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_INTENT_USER.I_Scenario_Request := L_Expected;
        GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 2: gateway fallback';
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        IF GVL_STATUS.G_Current_Scenario = L_Expected THEN
            GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Last_Result_Code := 102;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 2 passed';
        ELSE
            GVL_TEST_INJECTION.G_Scenario_Failed := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Last_Result_Code := 1002;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 2 failed';
        END_IF;
    END_CASE;

3:
    L_Expected := E_SCENARIO_TYPE.SCENARIO_SLEEP;
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_COMMAND.G_Scenario_Request_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_INTENT_USER.I_Scenario_Request := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_CONFIG.G_HMI_User_Rules[1].Enabled := TRUE;
        GVL_CONFIG.G_HMI_User_Rules[1].Condition_Type := E_Rule_Condition_Type.COND_TIME_OF_DAY;
        GVL_CONFIG.G_HMI_User_Rules[1].Condition_Op := E_Rule_Comparison.COMP_GE;
        GVL_CONFIG.G_HMI_User_Rules[1].Condition_Target_ID := 0;
        GVL_CONFIG.G_HMI_User_Rules[1].Condition_Value := REAL#0.0;
        GVL_CONFIG.G_HMI_User_Rules[1].Action_Type := E_Rule_Action_Type.ACTION_ACTIVATE_SCENARIO;
        GVL_CONFIG.G_HMI_User_Rules[1].Action_Value := TO_REAL(TO_INT(L_Expected));
        GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 3: rule fallback';
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        IF GVL_STATUS.G_Current_Scenario = L_Expected THEN
            GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Last_Result_Code := 103;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 3 passed';
        ELSE
            GVL_TEST_INJECTION.G_Scenario_Failed := TRUE;
            GVL_TEST_INJECTION.G_Scenario_Last_Result_Code := 1003;
            GVL_TEST_INJECTION.G_Scenario_Status_Msg := 'Scenario test 3 failed';
        END_IF;
    END_CASE;

END_CASE;

IF GVL_TEST_INJECTION.G_Scenario_Done AND GVL_TEST_INJECTION.G_Scenario_Auto_Run THEN
    GVL_TEST_INJECTION.G_Scenario_Current := GVL_TEST_INJECTION.G_Scenario_Current + 1;
    GVL_TEST_INJECTION.G_Scenario_Reset_Request := TRUE;
END_IF;
