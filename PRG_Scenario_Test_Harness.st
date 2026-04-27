// ONLY PATCHED TRIGGER PART

IF GVL_TEST_PANEL.G_Scenario_Run THEN

    // trigger on ID change
    IF GVL_TEST_PANEL.G_Scenario_ID <> GVL_TEST_PANEL.G_Scenario_ID_Prev THEN

        // reset inputs
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

        // apply scenario
        CASE GVL_TEST_PANEL.G_Scenario_ID OF
            1:
                GVL_TEST_PANEL.G_Selected_Circuit := 1;
                GVL_TEST_PANEL.G_Input_Policy_Bias := 1;
                GVL_TEST_PANEL.G_Input_Guest_Preheat_Request := TRUE;

            2:
                GVL_TEST_PANEL.G_Input_Circuit_Enable[1] := TRUE;
                GVL_TEST_PANEL.G_Input_Circuit_Enable[2] := TRUE;

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

        GVL_TEST_PANEL.G_Scenario_ID_Prev := GVL_TEST_PANEL.G_Scenario_ID;

    END_IF;

END_IF;
