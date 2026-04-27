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

GVL_TEST_PANEL.G_Result_Passed := TRUE;
GVL_TEST_PANEL.G_Result_Status_Msg := 'OK';
GVL_TEST_PANEL.G_Result_Fail_Code := 0;

CASE GVL_TEST_PANEL.G_Scenario_ID OF

    4:
        GVL_TEST_PANEL.G_Test_Description := 'Budget vs priority conflict';
        GVL_TEST_PANEL.G_Test_What_To_Change := 'Enable circuits and reduce budget';
        GVL_TEST_PANEL.G_Test_Expected_Text := 'Only highest priority manifolds stay enabled within budget';

        // build adjusted priorities
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

        // decision context
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

        IF L_Used > (GVL_TEST_PANEL.G_Input_Max_Thermal_Budget + 0.001) THEN
            GVL_TEST_PANEL.G_Result_Budget_Exceeded := TRUE;
            GVL_TEST_PANEL.G_Result_Passed := FALSE;
            GVL_TEST_PANEL.G_Result_Status_Msg := 'Budget exceeded';
            GVL_TEST_PANEL.G_Result_Fail_Code := 3001;
        ELSE
            GVL_TEST_PANEL.G_Result_Budget_Exceeded := FALSE;
        END_IF;

END_CASE;
