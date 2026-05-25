FUNCTION_BLOCK FB_Heating_Predictive_Controller
VAR
    L_i : INT;
    L_Time_To_Heat : UDINT;
    L_Time_To_Comfort : UDINT;
    L_Now_TOD : UDINT;
END_VAR

// ==============================================================================
// Ownership note
// ------------------------------------------------------------------------------
// This block owns predictive preheat decision only.
// It does NOT modify thermal demand. Thermal demand is owned by
// FB_Heating_Thermal_Model and may be interpreted by downstream advisory layers.
// ==============================================================================

L_Now_TOD := GVL_TIME_SERVICE.G_Time_Of_Day_MS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    L_Time_To_Heat := GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i];
    L_Time_To_Comfort := GVL_HEATING_POLICY.G_Zone_Comfort_Time_MS[L_i];

    // Predictive preheat decision.
    IF GVL_HEATING_POLICY.G_Zone_Schedule_Enabled[L_i] THEN

        IF L_Time_To_Comfort > L_Now_TOD THEN
            IF (L_Time_To_Comfort - L_Now_TOD) <= L_Time_To_Heat THEN
                GVL_HEATING_POLICY.G_Zone_Preheat_Needed[L_i] := TRUE;
            ELSE
                GVL_HEATING_POLICY.G_Zone_Preheat_Needed[L_i] := FALSE;
            END_IF;
        END_IF;

    END_IF;

    // Confidence gating.
    IF GVL_HEATING_POLICY.G_Zone_Thermal_Model_Confidence[L_i] < 0.1 THEN
        GVL_HEATING_POLICY.G_Zone_Preheat_Needed[L_i] := FALSE;
    END_IF;

END_FOR;

END_FUNCTION_BLOCK
