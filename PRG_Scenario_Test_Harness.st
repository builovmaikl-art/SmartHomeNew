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

// ============================================================
// SCENARIO SWITCH APPLY / RESET
// ============================================================

IF GVL_TEST_PANEL.G_Scenario_Run AND ((NOT GVL_TEST_PANEL.G_Scenario_Active) OR (GVL_TEST_PANEL.G_Last_Scenario_ID <> GVL_TEST_PANEL.G_Scenario_ID)) THEN
    // reset scenario inputs before applying selected preset
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
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled := TRUE;
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost := 2;

        2:
            GVL_TEST_PANEL.G_Input_Circuit_Enable[1] := TRUE;
            GVL_TEST_PANEL.G_Input_Circuit_Bias[1] := 1;
            GVL_TEST_PANEL.G_Input_Circuit_Guest_Preheat[1] := TRUE;
            GVL_TEST_PANEL.G_Input_Circuit_Enable[2] := TRUE;
            GVL_TEST_PANEL.G_Input_Circuit_Bias[2] := 2;

        3:
            GVL_TEST_PANEL.G_Selected_Circuit := 1;
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Request := TRUE;
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled := TRUE;
            GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost := 2;

        4:
            GVL_TEST_PANEL.G_Input_Max_Thermal_Budget := 1.0;
            GVL_TEST_PANEL.G_Input_Circuit_Enable[1] := TRUE;
            GVL_TEST_PANEL.G_Input_Circuit_Bias[1] := 5;
            GVL_TEST_PANEL.G_Input_Circuit_Enable[2] := TRUE;
            GVL_TEST_PANEL.G_Input_Circuit_Bias[2] := 1;

        5:
            GVL_TEST_PANEL.G_Input_Block_Heating := TRUE;

        6:
            GVL_TEST_PANEL.G_Input_Safety_Stop := TRUE;
    END_CASE;

    GVL_TEST_PANEL.G_Scenario_Active := TRUE;
END_IF;

IF (NOT GVL_TEST_PANEL.G_Scenario_Run) AND GVL_TEST_PANEL.G_Scenario_Active THEN
    // return scenario inputs to neutral defaults
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

    GVL_TEST_PANEL.G_Scenario_Active := FALSE;
END_IF;

// Common scan reset
GVL_TEST_PANEL.G_Result_Passed := TRUE;
GVL_TEST_PANEL.G_Result_Status_Msg := 'OK';
GVL_TEST_PANEL.G_Result_Fail_Code := 0;
GVL_TEST_PANEL.G_Result_Budget_Exceeded := FALSE;
GVL_TEST_PANEL.G_Run_Counter := GVL_TEST_PANEL.G_Run_Counter + 1;
GVL_TEST_PANEL.G_Last_Scenario_ID := GVL_TEST_PANEL.G_Scenario_ID;

IF GVL_TEST_PANEL.G_Reset_Results_Request THEN
    GVL_TEST_PANEL.G_Result_Mapped_Manifold := 0;
    GVL_TEST_PANEL.G_Result_Base_Priority := 0;
    GVL_TEST_PANEL.G_Result_Expected_Adjusted_Priority := 0;
    GVL_TEST_PANEL.G_Result_Actual_Adjusted_Priority := 0;
    GVL_TEST_PANEL.G_Result_Delta := 0;
    GVL_TEST_PANEL.G_Result_Used_Thermal_Budget := 0.0;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_TEST_PANEL.G_Result_Manifold_Base_Priority[L_i] := 0;
        GVL_TEST_PANEL.G_Result_Manifold_Expected_Priority[L_i] := 0;
        GVL_TEST_PANEL.G_Result_Manifold_Actual_Priority[L_i] := 0;
        GVL_TEST_PANEL.G_Result_Manifold_Delta[L_i] := 0;
        GVL_TEST_PANEL.G_Result_Manifold_Allowed[L_i] := FALSE;
        GVL_TEST_PANEL.G_Result_Manifold_Enabled[L_i] := FALSE;
    END_FOR;

    GVL_TEST_PANEL.G_Reset_Results_Request := FALSE;
END_IF;

IF GVL_TEST_PANEL.G_Reset_Inputs_Request THEN
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

    GVL_TEST_PANEL.G_Reset_Inputs_Request := FALSE;
END_IF;

CASE GVL_TEST_PANEL.G_Scenario_ID OF

    // =========================
    // Scenario 1: single circuit
    // =========================
    1:
        GVL_TEST_PANEL.G_Test_Description := 'Single circuit priority';
        GVL_TEST_PANEL.G_Current_Test_Name := 'TEST 1 - Single circuit priority';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Change circuit, bias, preheat request/enabled/boost';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Adjusted = base + bias + preheat boost, lower bound >= 1';
        GVL_TEST_PANEL.G_Expected_Summary := 'Expected single adjusted priority';

        L_circuit := GVL_TEST_PANEL.G_Selected_Circuit;

        IF (L_circuit < 1) OR (L_circuit > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Invalid circuit index';
            GVL_TEST_PANEL.G_Result_Fail_Code := 2001;
            RETURN;
        END_IF;

        L_manifold := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_circuit].manifold_id);

        IF (L_manifold < 1) OR (L_manifold > GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Invalid manifold mapping';
            GVL_TEST_PANEL.G_Result_Fail_Code := 2002;
            RETURN;
        END_IF;

        L_base := GVL_CONFIG.G_Manifold_Priority[L_manifold];
        L_expected := L_base + GVL_TEST_PANEL.G_Input_Policy_Bias;

        IF GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled AND GVL_TEST_PANEL.G_Input_Guest_Preheat_Request THEN
            L_expected := L_expected + GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost;
        END_IF;

        IF L_expected < 1 THEN
            L_expected := 1;
        END_IF;

        L_actual := L_expected;

        GVL_TEST_PANEL.G_Result_Mapped_Manifold := L_manifold;
        GVL_TEST_PANEL.G_Result_Base_Priority := L_base;
        GVL_TEST_PANEL.G_Result_Expected_Adjusted_Priority := L_expected;
        GVL_TEST_PANEL.G_Result_Actual_Adjusted_Priority := L_actual;
        GVL_TEST_PANEL.G_Result_Delta := L_actual - L_base;
        GVL_TEST_PANEL.G_Actual_Summary := 'Actual single adjusted priority calculated';

        IF L_actual <> L_expected THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Expected/actual mismatch';
            GVL_TEST_PANEL.G_Result_Fail_Code := 2003;
        END_IF;

    // =========================
    // Scenario 2: multi-zone aggregation
    // =========================
    2:
        GVL_TEST_PANEL.G_Test_Description := 'Multi-zone aggregation';
        GVL_TEST_PANEL.G_Current_Test_Name := 'TEST 2 - Multi-zone aggregation';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Enable circuit array entries and set bias/preheat arrays';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Each manifold receives summed contributions from mapped circuits';
        GVL_TEST_PANEL.G_Expected_Summary := 'Expected priorities per manifold';

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            L_Manifold_Calc[L_i] := GVL_CONFIG.G_Manifold_Priority[L_i];
            GVL_TEST_PANEL.G_Result_Manifold_Base_Priority[L_i] := L_Manifold_Calc[L_i];
        END_FOR;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
            IF GVL_TEST_PANEL.G_Input_Circuit_Enable[L_i] THEN
                L_j := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].manifold_id);

                IF (L_j >= 1) AND (L_j <= GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
                    L_tmp := GVL_TEST_PANEL.G_Input_Circuit_Bias[L_i];

                    IF GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled AND GVL_TEST_PANEL.G_Input_Circuit_Guest_Preheat[L_i] THEN
                        L_tmp := L_tmp + GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost;
                    END_IF;

                    L_Manifold_Calc[L_j] := L_Manifold_Calc[L_j] + L_tmp;
                END_IF;
            END_IF;
        END_FOR;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            IF L_Manifold_Calc[L_i] < 1 THEN
                L_Manifold_Calc[L_i] := 1;
            END_IF;

            GVL_TEST_PANEL.G_Result_Manifold_Expected_Priority[L_i] := L_Manifold_Calc[L_i];
            GVL_TEST_PANEL.G_Result_Manifold_Actual_Priority[L_i] := L_Manifold_Calc[L_i];
            GVL_TEST_PANEL.G_Result_Manifold_Delta[L_i] := L_Manifold_Calc[L_i] - GVL_CONFIG.G_Manifold_Priority[L_i];
        END_FOR;

        GVL_TEST_PANEL.G_Actual_Summary := 'Actual per-manifold aggregation calculated';

    // =========================
    // Scenario 3: preheat influence
    // =========================
    3:
        GVL_TEST_PANEL.G_Test_Description := 'Preheat influence';
        GVL_TEST_PANEL.G_Current_Test_Name := 'TEST 3 - Preheat influence';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Toggle guest preheat request/enabled/boost';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Priority increases only when preheat enabled and requested';
        GVL_TEST_PANEL.G_Expected_Summary := 'Expected delta equals boost when active';

        L_circuit := GVL_TEST_PANEL.G_Selected_Circuit;
        L_manifold := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_circuit].manifold_id);
        L_base := GVL_CONFIG.G_Manifold_Priority[L_manifold];
        L_expected := L_base;

        IF GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled AND GVL_TEST_PANEL.G_Input_Guest_Preheat_Request THEN
            L_expected := L_expected + GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost;
        END_IF;

        GVL_TEST_PANEL.G_Result_Mapped_Manifold := L_manifold;
        GVL_TEST_PANEL.G_Result_Base_Priority := L_base;
        GVL_TEST_PANEL.G_Result_Expected_Adjusted_Priority := L_expected;
        GVL_TEST_PANEL.G_Result_Actual_Adjusted_Priority := L_expected;
        GVL_TEST_PANEL.G_Result_Delta := L_expected - L_base;
        GVL_TEST_PANEL.G_Actual_Summary := 'Preheat delta calculated';

    // =========================
    // Scenario 4: budget vs priority
    // =========================
    4:
        GVL_TEST_PANEL.G_Test_Description := 'Budget vs priority';
        GVL_TEST_PANEL.G_Current_Test_Name := 'TEST 4 - Budget vs priority';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Enable circuits, set bias/preheat, reduce budget';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Enabled manifolds must not exceed budget';
        GVL_TEST_PANEL.G_Expected_Summary := 'Used budget <= max budget';

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            L_Manifold_Calc[L_i] := GVL_CONFIG.G_Manifold_Priority[L_i];
        END_FOR;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
            IF GVL_TEST_PANEL.G_Input_Circuit_Enable[L_i] THEN
                L_j := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].manifold_id);

                IF (L_j >= 1) AND (L_j <= GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
                    L_tmp := GVL_TEST_PANEL.G_Input_Circuit_Bias[L_i];

                    IF GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled AND GVL_TEST_PANEL.G_Input_Circuit_Guest_Preheat[L_i] THEN
                        L_tmp := L_tmp + GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost;
                    END_IF;

                    L_Manifold_Calc[L_j] := L_Manifold_Calc[L_j] + L_tmp;
                END_IF;
            END_IF;
        END_FOR;

        fbDecisionScenario(
            VI_Manifold_Pump_In_Service := GVL_CONFIG.G_Manifold_Pump_In_Service,
            VI_Manifold_Pressure_Fault := GVL_STATUS.G_Diagnostics.Manifold_Pressure_Fault,
            VI_Manifold_Current_Fault := GVL_STATUS.G_Diagnostics.Manifold_Current_Fault,
            VI_Manifold_Thermal_Weight := GVL_CONFIG.G_Manifold_Thermal_Weight,
            VI_Manifold_Priority := L_Manifold_Calc,
            VI_Max_Thermal_Budget := GVL_TEST_PANEL.G_Input_Max_Thermal_Budget
        );

        L_Used := 0.0;

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_TEST_PANEL.G_Result_Manifold_Allowed[L_i] := fbDecisionScenario.VO_Manifold_Allowed[L_i];
            GVL_TEST_PANEL.G_Result_Manifold_Enabled[L_i] := fbDecisionScenario.VO_Manifold_Enabled[L_i];

            IF fbDecisionScenario.VO_Manifold_Enabled[L_i] THEN
                L_Used := L_Used + GVL_CONFIG.G_Manifold_Thermal_Weight[L_i];
            END_IF;
        END_FOR;

        GVL_TEST_PANEL.G_Result_Used_Thermal_Budget := L_Used;
        GVL_TEST_PANEL.G_Actual_Summary := 'Budget allocation calculated';

        IF L_Used > (GVL_TEST_PANEL.G_Input_Max_Thermal_Budget + 0.001) THEN
            GVL_TEST_PANEL.G_Result_Budget_Exceeded := TRUE;
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Budget exceeded';
            GVL_TEST_PANEL.G_Result_Fail_Code := 3001;
        ELSE
            GVL_TEST_PANEL.G_Result_Budget_Exceeded := FALSE;
        END_IF;

    // =========================
    // Scenario 5: coordinator override
    // =========================
    5:
        GVL_TEST_PANEL.G_Test_Description := 'Coordinator override';
        GVL_TEST_PANEL.G_Current_Test_Name := 'TEST 5 - Coordinator override';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Set G_Input_Block_Heating TRUE';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'All manifolds disabled regardless of priority';
        GVL_TEST_PANEL.G_Expected_Summary := 'Enabled[] all FALSE when block active';

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_TEST_PANEL.G_Result_Manifold_Enabled[L_i] := FALSE;
            GVL_TEST_PANEL.G_Result_Manifold_Allowed[L_i] := FALSE;
        END_FOR;

        IF NOT GVL_TEST_PANEL.G_Input_Block_Heating THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Block not enabled';
            GVL_TEST_PANEL.G_Result_Fail_Code := 4001;
        ELSE
            GVL_TEST_PANEL.G_Actual_Summary := 'Coordinator block model disables all manifolds';
        END_IF;

    // =========================
    // Scenario 6: safety dominance
    // =========================
    6:
        GVL_TEST_PANEL.G_Test_Description := 'Safety dominance';
        GVL_TEST_PANEL.G_Current_Test_Name := 'TEST 6 - Safety dominance';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Set G_Input_Safety_Stop TRUE';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'All manifolds disabled regardless of priority/budget/coordinator';
        GVL_TEST_PANEL.G_Expected_Summary := 'Enabled[] all FALSE when safety active';

        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_TEST_PANEL.G_Result_Manifold_Enabled[L_i] := FALSE;
            GVL_TEST_PANEL.G_Result_Manifold_Allowed[L_i] := FALSE;
        END_FOR;

        IF NOT GVL_TEST_PANEL.G_Input_Safety_Stop THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Safety not active';
            GVL_TEST_PANEL.G_Result_Fail_Code := 5001;
        ELSE
            GVL_TEST_PANEL.G_Actual_Summary := 'Safety model disables all manifolds';
        END_IF;

ELSE
    GVL_TEST_PANEL.G_Result_Passed := FALSE;
    GVL_TEST_PANEL.G_Result_Status_Msg := 'Unknown scenario';
    GVL_TEST_PANEL.G_Result_Fail_Code := 9001;
END_CASE;

GVL_TEST_PANEL.G_Last_Result_Passed := GVL_TEST_PANEL.G_Result_Passed;
GVL_TEST_PANEL.G_Last_Fail_Code := GVL_TEST_PANEL.G_Result_Fail_Code;
GVL_TEST_PANEL.G_System_State_Line := 'Check Safety/Block/Budget/Preheat inputs and result arrays';

IF GVL_TEST_PANEL.G_Result_Passed THEN
    GVL_TEST_PANEL.G_Error_Text := '';
    CASE GVL_TEST_PANEL.G_Scenario_ID OF
        1: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 1 | Single circuit | PASS';
        2: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 2 | Multi-zone aggregation | PASS';
        3: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 3 | Preheat influence | PASS';
        4: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 4 | Budget vs priority | PASS';
        5: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 5 | Coordinator override | PASS';
        6: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 6 | Safety dominance | PASS';
    ELSE
        GVL_TEST_PANEL.G_Test_Result_Line := 'UNKNOWN TEST | PASS';
    END_CASE;
ELSE
    GVL_TEST_PANEL.G_Error_Text := GVL_TEST_PANEL.G_Result_Status_Msg;
    CASE GVL_TEST_PANEL.G_Scenario_ID OF
        1: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 1 | Single circuit | FAIL';
        2: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 2 | Multi-zone aggregation | FAIL';
        3: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 3 | Preheat influence | FAIL';
        4: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 4 | Budget vs priority | FAIL';
        5: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 5 | Coordinator override | FAIL';
        6: GVL_TEST_PANEL.G_Test_Result_Line := 'TEST 6 | Safety dominance | FAIL';
    ELSE
        GVL_TEST_PANEL.G_Test_Result_Line := 'UNKNOWN TEST | FAIL';
    END_CASE;
END_IF;

GVL_TEST_PANEL.G_UI_01_Test := GVL_TEST_PANEL.G_Current_Test_Name;
GVL_TEST_PANEL.G_UI_02_Change := GVL_TEST_PANEL.G_Test_What_To_Change;
GVL_TEST_PANEL.G_UI_03_Expected := GVL_TEST_PANEL.G_Test_Expected_Text;
GVL_TEST_PANEL.G_UI_04_Result := GVL_TEST_PANEL.G_Test_Result_Line;

IF GVL_TEST_PANEL.G_Result_Passed THEN
    GVL_TEST_PANEL.G_UI_05_Error := 'ERROR: -';
ELSE
    GVL_TEST_PANEL.G_UI_05_Error := GVL_TEST_PANEL.G_Error_Text;
END_IF;

GVL_TEST_PANEL.G_UI_06_Actual := GVL_TEST_PANEL.G_Actual_Summary;
GVL_TEST_PANEL.G_Last_Result_Line := GVL_TEST_PANEL.G_Test_Result_Line;
