PROGRAM PRG_Scenario_Test_Harness
VAR
    L_circuit : INT;
    L_manifold : INT;
    L_base : INT;
    L_adjusted : INT;
END_VAR

IF NOT GVL_TEST_PANEL.G_Enable THEN
    RETURN;
END_IF;

CASE GVL_TEST_PANEL.G_Scenario_ID OF

    // =========================
    // Scenario 1: HP priority calc
    // =========================
    1:
        L_circuit := GVL_TEST_PANEL.G_Selected_Circuit;

        // bounds protection
        IF (L_circuit < 1) OR (L_circuit > GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Invalid circuit index';
            RETURN;
        END_IF;

        L_manifold := TO_INT(GVL_CONFIG.G_HMI_FloorHeating_Configs[L_circuit].manifold_id);

        IF (L_manifold < 1) OR (L_manifold > GVL_CONSTANTS.C_MAX_MANIFOLDS) THEN
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Invalid manifold mapping';
            RETURN;
        END_IF;

        L_base := GVL_CONFIG.G_Manifold_Priority[L_manifold];
        L_adjusted := L_base;

        // apply manual bias
        L_adjusted := L_adjusted + GVL_TEST_PANEL.G_Input_Policy_Bias;

        // apply guest preheat
        IF GVL_TEST_PANEL.G_Input_Guest_Preheat_Enabled AND GVL_TEST_PANEL.G_Input_Guest_Preheat_Request THEN
            L_adjusted := L_adjusted + GVL_TEST_PANEL.G_Input_Guest_Preheat_Boost;
        END_IF;

        // lower bound
        IF L_adjusted < 1 THEN
            L_adjusted := 1;
        END_IF;

        // write results
        GVL_TEST_PANEL.G_Result_Mapped_Manifold := L_manifold;
        GVL_TEST_PANEL.G_Result_Base_Priority := L_base;
        GVL_TEST_PANEL.G_Result_Adjusted_Priority := L_adjusted;
        GVL_TEST_PANEL.G_Result_Delta := L_adjusted - L_base;

        GVL_TEST_PANEL.G_Result_Passed := TRUE;
        GVL_TEST_PANEL.G_Result_Status_Msg := 'OK';

END_CASE;
