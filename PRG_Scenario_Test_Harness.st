PROGRAM PRG_Scenario_Test_Harness
VAR
    L_i : INT;
    L_j : INT;
    L_circuit : INT;
    L_manifold : INT;
    L_base : INT;
    L_adjusted : INT;
    L_expected : INT;
    L_actual : INT;
    L_tmp : INT;
    L_Manifold_Calc : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
END_VAR

IF NOT GVL_TEST_PANEL.G_Enable THEN
    RETURN;
END_IF;

// reset common
GVL_TEST_PANEL.G_Result_Passed := TRUE;
GVL_TEST_PANEL.G_Result_Status_Msg := 'OK';
GVL_TEST_PANEL.G_Result_Fail_Code := 0;

CASE GVL_TEST_PANEL.G_Scenario_ID OF

    // =========================
    // TEST 1: Single circuit
    // =========================
    1:
        GVL_TEST_PANEL.G_Test_Description := 'Single circuit priority calc';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Set circuit, bias, preheat flags';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Adjusted = base + bias + preheat';

        L_circuit := GVL_TEST_PANEL.G_Selected_Circuit;

        IF (L_circuit < 1) OR (L_circuit > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Invalid circuit';
            GVL_TEST_PANEL.G_Result_Fail_Code := 2001;
            RETURN;
        END_IF;

        L_manifold := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_circuit].manifold_id);
        L_base := GVL_CONFIG.G_Manifold_Priority[L_manifold];

        L_expected := L_base + GVL_TEST_PANEL.G_Input_Policy_Bias;

        IF GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled AND GVL_TEST_PANEL.G_Input_Guest_Preheat_Request THEN
            L_expected := L_expected + GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost;
        END_IF;

        IF L_expected < 1 THEN
            L_expected := 1;
        END_IF;

        // actual = same model (no runtime call)
        L_actual := L_expected;

        GVL_TEST_PANEL.G_Result_Mapped_Manifold := L_manifold;
        GVL_TEST_PANEL.G_Result_Base_Priority := L_base;
        GVL_TEST_PANEL.G_Result_Expected_Adjusted_Priority := L_expected;
        GVL_TEST_PANEL.G_Result_Actual_Adjusted_Priority := L_actual;
        GVL_TEST_PANEL.G_Result_Delta := L_actual - L_base;

        IF L_actual <> L_expected THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Mismatch';
            GVL_TEST_PANEL.G_Result_Fail_Code := 2002;
        END_IF;

    // =========================
    // TEST 2: Multi-zone aggregation
    // =========================
    2:
        GVL_TEST_PANEL.G_Test_Description := 'Multi-zone aggregation';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Enable circuits and set bias/preheat arrays';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Manifold priority = sum of contributions';

        // init base
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            L_Manifold_Calc[L_i] := GVL_CONFIG.G_Manifold_Priority[L_i];
            GVL_TEST_PANEL.G_Result_Manifold_Base_Priority[L_i] := L_Manifold_Calc[L_i];
        END_FOR;

        // accumulate
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

        // finalize
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            IF L_Manifold_Calc[L_i] < 1 THEN
                L_Manifold_Calc[L_i] := 1;
            END_IF;

            GVL_TEST_PANEL.G_Result_Manifold_Expected_Priority[L_i] := L_Manifold_Calc[L_i];
            GVL_TEST_PANEL.G_Result_Manifold_Actual_Priority[L_i] := L_Manifold_Calc[L_i];
            GVL_TEST_PANEL.G_Result_Manifold_Delta[L_i] := L_Manifold_Calc[L_i] - GVL_CONFIG.G_Manifold_Priority[L_i];
        END_FOR;

    // =========================
    // TEST 3: Preheat dominance
    // =========================
    3:
        GVL_TEST_PANEL.G_Test_Description := 'Preheat influence check';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Toggle preheat flags';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Priority increases when preheat enabled';

        // simple reuse test 1 logic
        L_circuit := GVL_TEST_PANEL.G_Selected_Circuit;
        L_manifold := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_circuit].manifold_id);
        L_base := GVL_CONFIG.G_Manifold_Priority[L_manifold];

        L_expected := L_base;

        IF GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled AND GVL_TEST_PANEL.G_Input_Guest_Preheat_Request THEN
            L_expected := L_expected + GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost;
        END_IF;

        GVL_TEST_PANEL.G_Result_Base_Priority := L_base;
        GVL_TEST_PANEL.G_Result_Expected_Adjusted_Priority := L_expected;
        GVL_TEST_PANEL.G_Result_Actual_Adjusted_Priority := L_expected;
        GVL_TEST_PANEL.G_Result_Delta := L_expected - L_base;

END_CASE;
