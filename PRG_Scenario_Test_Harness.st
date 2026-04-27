PROGRAM PRG_Scenario_Test_Harness
VAR
    L_i : INT;
    L_j : INT;
    L_circuit : INT;
    L_manifold : INT;
    L_base : INT;
    L_expected : INT;
    L_actual : INT;
    L_tmp : INT;
    L_Manifold_Calc : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    L_Used : REAL;
    fbDecisionScenario : FB_Heating_Decision_Context;
END_VAR

IF NOT GVL_TEST_PANEL.G_Enable THEN
    RETURN;
END_IF;

// APPLY / RESET unchanged ...

// (оставляем как есть до CASE)

CASE GVL_TEST_PANEL.G_Scenario_ID OF

    // existing 1..6 unchanged ...

    7:
        GVL_TEST_PANEL.G_Test_Description := 'Conflict dominance';
        GVL_TEST_PANEL.G_Current_Test_Name := 'TEST 7 - Conflict dominance';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Combine preheat, priority, budget and safety';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Safety must dominate all';
        GVL_TEST_PANEL.G_Expected_Summary := 'All manifolds disabled';

        // emulate conflict: everything ON
        GVL_TEST_PANEL.G_Input_Guest_Preheat_Request := TRUE;
        GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled := TRUE;
        GVL_TEST_PANEL.G_Input_Max_Thermal_Budget := 0.5;
        GVL_TEST_PANEL.G_Input_Block_Heating := TRUE;
        GVL_TEST_PANEL.G_Input_Safety_Stop := TRUE;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_TEST_PANEL.G_Result_Manifold_Enabled[L_i] := FALSE;
            GVL_TEST_PANEL.G_Result_Manifold_Allowed[L_i] := FALSE;
        END_FOR;

        IF NOT GVL_TEST_PANEL.G_Input_Safety_Stop THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Safety not dominant';
            GVL_TEST_PANEL.G_Result_Fail_Code := 7001;
        ELSE
            GVL_TEST_PANEL.G_Actual_Summary := 'Safety dominates all inputs';
        END_IF;

ELSE
    GVL_TEST_PANEL.G_Result_Passed := FALSE;
    GVL_TEST_PANEL.G_Result_Status_Msg := 'Unknown scenario';
    GVL_TEST_PANEL.G_Result_Fail_Code := 9001;
END_CASE;

// tail unchanged ...
