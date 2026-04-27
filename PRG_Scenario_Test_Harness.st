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

// RESULT panel is the operator control surface
GVL_TEST_PANEL.G_Enable := GVL_TEST_PANEL_RESULT.G_Enable;
GVL_TEST_PANEL.G_Scenario_ID := GVL_TEST_PANEL_RESULT.G_Scenario_ID;
GVL_TEST_PANEL.G_Scenario_Run := GVL_TEST_PANEL_RESULT.G_Scenario_Run;

IF NOT GVL_TEST_PANEL.G_Enable THEN
    RETURN;
END_IF;

// ============================================================
// HOLD-PRESET SCENARIO MODE
// ============================================================

IF GVL_TEST_PANEL.G_Scenario_Run THEN
    GVL_TEST_PANEL.G_Selected_Circuit := 1;
    GVL_TEST_PANEL.G_Input_Policy_Bias := 0;
    GVL_TEST_PANEL.G_Input_Guest_Preheat_Request := FALSE;
    GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled := TRUE;
    GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost := 2;
    GVL_TEST_PANEL.G_Input_Max_Thermal_Budget := 2.0;
    GVL_TEST_PANEL.G_Input_Block_Heating := FALSE;
    GVL_TEST_PANEL.G_Input_Safety_Stop := FALSE;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        GVL_TEST_PANEL.G_Input_Circuit_Enable[L_i] := FALSE;
        GVL_TEST_PANEL.G_Input_Circuit_Bias[L_i] := 0;
        GVL_TEST_PANEL.G_Input_Circuit_Guest_Preheat[L_i] := FALSE;
    END_FOR;

    CASE GVL_TEST_PANEL.G_Scenario_ID OF
        1:
            GVL_TEST_PANEL.G_Selected_Circuit := 1;
            GVL_TEST_PANEL.G_Input_Policy_Bias := 1;
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Request := TRUE;
        2:
            GVL_TEST_PANEL.G_Input_Circuit_Enable[1] := TRUE;
            GVL_TEST_PANEL.G_Input_Circuit_Bias[1] := 1;
            GVL_TEST_PANEL.G_Input_Circuit_Enable[2] := TRUE;
            GVL_TEST_PANEL.G_Input_Circuit_Bias[2] := 2;
        3:
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Request := TRUE;
        4:
            GVL_TEST_PANEL.G_Input_Max_Thermal_Budget := 1.0;
        5:
            GVL_TEST_PANEL.G_Input_Block_Heating := TRUE;
        6:
            GVL_TEST_PANEL.G_Input_Safety_Stop := TRUE;
        7:
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Request := TRUE;
            GVL_TEST_PANEL.G_Input_Block_Heating := TRUE;
            GVL_TEST_PANEL.G_Input_Safety_Stop := TRUE;
    END_CASE;

    GVL_TEST_PANEL.G_Scenario_Active := TRUE;
ELSE
    GVL_TEST_PANEL.G_Scenario_Active := FALSE;
END_IF;

// === minimal result marker ===
GVL_TEST_PANEL.G_Result_Status_Msg := 'RUNNING';
