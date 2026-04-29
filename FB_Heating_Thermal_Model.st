FUNCTION_BLOCK FB_Heating_Thermal_Model
VAR
    L_i : INT;
    L_DeltaT : REAL;
    L_Loss : REAL;
    L_Gain : REAL;
    L_Outdoor : REAL;
END_VAR

L_Outdoor := GVL_STATE.G_Outdoor_Temp;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    // temperature delta
    L_DeltaT := GVL_STATE.G_Room_Temps[L_i] - L_Outdoor;

    // heat loss proportional to delta
    L_Loss := L_DeltaT * 0.01 * GVL_HEATING_POLICY.G_Zone_Thermal_Inertia[L_i];

    // heat gain approximation (floor vs room)
    L_Gain := (GVL_STATE.G_Floor_Temps[L_i] - GVL_STATE.G_Room_Temps[L_i]) * 0.05;

    // store diagnostics
    GVL_HEATING_POLICY.G_Zone_Heat_Loss_Rate[L_i] := L_Loss;
    GVL_HEATING_POLICY.G_Zone_Heat_Gain_Rate[L_i] := L_Gain;

    // thermal response (net effect)
    GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i] := L_Gain - L_Loss;

    // demand (how far from target)
    GVL_HEATING_POLICY.G_Zone_Thermal_Demand[L_i] := 
        GVL_STATE.G_Target_Temperature - GVL_STATE.G_Room_Temps[L_i];

    // time to heat estimation (simple inverse response)
    IF ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i]) > 0.01 THEN
        GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] := 
            UDINT(ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Demand[L_i] /
                  GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i]) * 60000.0);
    ELSE
        GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] := 0;
    END_IF;

    // predicted temp in 30 min
    GVL_HEATING_POLICY.G_Zone_Predicted_Temp_30m[L_i] :=
        GVL_STATE.G_Room_Temps[L_i] + 
        GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i] * 30.0;

    // confidence (simple heuristic)
    GVL_HEATING_POLICY.G_Zone_Thermal_Model_Confidence[L_i] :=
        LIMIT(0.0, 1.0, ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i]));

END_FOR;

END_FUNCTION_BLOCK
