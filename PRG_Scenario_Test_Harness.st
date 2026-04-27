PROGRAM PRG_Scenario_Test_Harness
VAR
    L_i : INT;
    L_j : INT;
    L_circuit : INT;
    L_manifold : INT;
    L_base : INT;
    L_expected : INT;
    L_tmp : INT;
    L_Manifold_Calc : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    L_Used : REAL;
    fbDecisionScenario : FB_Heating_Decision_Context;
END_VAR

IF NOT GVL_TEST_PANEL.G_Enable THEN
    RETURN;
END_IF;

GVL_TEST_PANEL.G_Result_Passed := TRUE;
GVL_TEST_PANEL.G_Result_Status_Msg := 'OK';
GVL_TEST_PANEL.G_Result_Fail_Code := 0;

CASE GVL_TEST_PANEL.G_Scenario_ID OF

    1:
        GVL_TEST_PANEL.G_Test_Description := 'Single circuit';

    2:
        GVL_TEST_PANEL.G_Test_Description := 'Multi-zone aggregation';

    3:
        GVL_TEST_PANEL.G_Test_Description := 'Preheat influence';

    4:
        GVL_TEST_PANEL.G_Test_Description := 'Budget vs priority';

    5:
        GVL_TEST_PANEL.G_Test_Description := 'Coordinator override';

    6:
        GVL_TEST_PANEL.G_Test_Description := 'Safety dominance';

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_TEST_PANEL.G_Result_Manifold_Enabled[L_i] := FALSE;
        END_FOR;

        IF NOT GVL_TEST_PANEL.G_Input_Safety_Stop THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Safety not active';
            GVL_TEST_PANEL.G_Result_Fail_Code := 5001;
        END_IF;

END_CASE;
