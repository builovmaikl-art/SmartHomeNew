PROGRAM PRG_Test_Scenario_Runner

IF NOT GVL_TEST.G_Test_Enable THEN
    RETURN;
END_IF;

IF NOT GVL_TEST_INJECTION.G_Scenario_Enable THEN
    RETURN;
END_IF;

// Reset
IF GVL_TEST_INJECTION.G_Scenario_Reset_Request THEN
    GVL_TEST_INJECTION.G_Scenario_Step := 0;
    GVL_TEST_INJECTION.G_Scenario_Done := FALSE;
    GVL_TEST_INJECTION.G_Scenario_Failed := FALSE;
    GVL_TEST_INJECTION.G_Scenario_Result_Passed := TRUE;
    GVL_TEST_INJECTION.G_Scenario_Checks_Total := 0;
    GVL_TEST_INJECTION.G_Scenario_Checks_Failed := 0;
    GVL_TEST_INJECTION.G_Scenario_Reset_Request := FALSE;
END_IF;

CASE GVL_TEST_INJECTION.G_Scenario_Current OF

// =========================
// SCENARIO 1: OPERATOR PRIORITY
// =========================
1:
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_INTENT.G_Scenario_Request_Operator := E_SCENARIO_TYPE.SCENARIO_HOME;
        GVL_TEST_INJECTION.G_Scenario_Expected := E_SCENARIO_TYPE.SCENARIO_HOME;
        GVL_TEST_INJECTION.G_Scenario_Source_Expected := SRC_OPERATOR;
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        GVL_TEST_INJECTION.G_Scenario_Checks_Total := GVL_TEST_INJECTION.G_Scenario_Checks_Total + 1;
        GVL_TEST_INJECTION.G_Scenario_Observed := GVL_STATUS.G_Current_Scenario;

        IF GVL_STATUS.G_Current_Scenario <> GVL_TEST_INJECTION.G_Scenario_Expected THEN
            GVL_TEST_INJECTION.G_Scenario_Checks_Failed := GVL_TEST_INJECTION.G_Scenario_Checks_Failed + 1;
            GVL_TEST_INJECTION.G_Scenario_Result_Passed := FALSE;
        END_IF;

        GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
    END_CASE;

// =========================
// SCENARIO 2: GATEWAY FALLBACK
// =========================
2:
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_INTENT.G_Scenario_Request_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_INTENT.G_Scenario_Request_Gateway := E_SCENARIO_TYPE.SCENARIO_AWAY;
        GVL_TEST_INJECTION.G_Scenario_Expected := E_SCENARIO_TYPE.SCENARIO_AWAY;
        GVL_TEST_INJECTION.G_Scenario_Source_Expected := SRC_GATEWAY;
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        GVL_TEST_INJECTION.G_Scenario_Checks_Total := GVL_TEST_INJECTION.G_Scenario_Checks_Total + 1;
        IF GVL_STATUS.G_Current_Scenario <> GVL_TEST_INJECTION.G_Scenario_Expected THEN
            GVL_TEST_INJECTION.G_Scenario_Checks_Failed := GVL_TEST_INJECTION.G_Scenario_Checks_Failed + 1;
            GVL_TEST_INJECTION.G_Scenario_Result_Passed := FALSE;
        END_IF;

        GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
    END_CASE;

// =========================
// SCENARIO 3: RULE FALLBACK
// =========================
3:
    CASE GVL_TEST_INJECTION.G_Scenario_Step OF
    0:
        GVL_INTENT.G_Scenario_Request_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_INTENT.G_Scenario_Request_Gateway := E_SCENARIO_TYPE.SCENARIO_NONE;
        GVL_INTENT.G_Scenario_Request_Rule := E_SCENARIO_TYPE.SCENARIO_SLEEP;
        GVL_TEST_INJECTION.G_Scenario_Expected := E_SCENARIO_TYPE.SCENARIO_SLEEP;
        GVL_TEST_INJECTION.G_Scenario_Source_Expected := SRC_RULE;
        GVL_TEST_INJECTION.G_Scenario_Step := 1;

    1:
        GVL_TEST_INJECTION.G_Scenario_Checks_Total := GVL_TEST_INJECTION.G_Scenario_Checks_Total + 1;
        IF GVL_STATUS.G_Current_Scenario <> GVL_TEST_INJECTION.G_Scenario_Expected THEN
            GVL_TEST_INJECTION.G_Scenario_Checks_Failed := GVL_TEST_INJECTION.G_Scenario_Checks_Failed + 1;
            GVL_TEST_INJECTION.G_Scenario_Result_Passed := FALSE;
        END_IF;

        GVL_TEST_INJECTION.G_Scenario_Done := TRUE;
    END_CASE;

END_CASE;

// Auto next
IF GVL_TEST_INJECTION.G_Scenario_Done AND GVL_TEST_INJECTION.G_Scenario_Auto_Run THEN
    GVL_TEST_INJECTION.G_Scenario_Current := GVL_TEST_INJECTION.G_Scenario_Current + 1;
    GVL_TEST_INJECTION.G_Scenario_Reset_Request := TRUE;
END_IF;
