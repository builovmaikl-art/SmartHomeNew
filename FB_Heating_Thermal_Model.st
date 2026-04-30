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

    L_DeltaT := GVL_STATE.G_Room_Temps[L_i] - L_Outdoor;

    L_Loss := L_DeltaT * 0.01 * GVL_HEATING_POLICY.G_Zone_Thermal_Inertia[L_i];

    L_Gain := (GVL_STATE.G_Floor_Temps[L_i] - GVL_STATE.G_Room_Temps[L_i]) * 0.05;

    GVL_HEATING_POLICY.G_Zone_Heat_Loss_Rate[L_i] := L_Loss;
    GVL_HEATING_POLICY.G_Zone_Heat_Gain_Rate[L_i] := L_Gain;

    GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i] := L_Gain - L_Loss;

    GVL_HEATING_POLICY.G_Zone_Thermal_Demand[L_i] := 
        GVL_STATE.G_Target_Temperature - GVL_STATE.G_Room_Temps[L_i];

    IF ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i]) > 0.01 THEN
        GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] := 
            REAL_TO_UDINT(ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Demand[L_i] /
                  GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i]) * 60000.0);
    ELSE
        GVL_HEATING_POLICY.G_Zone_Time_To_Heat_MS[L_i] := 0;
    END_IF;

    GVL_HEATING_POLICY.G_Zone_Predicted_Temp_30m[L_i] :=
        GVL_STATE.G_Room_Temps[L_i] + 
        GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i] * 30.0;

    GVL_HEATING_POLICY.G_Zone_Thermal_Model_Confidence[L_i] :=
        LIMIT(0.0, 1.0, ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Response[L_i]));

END_FOR;

END_FUNCTION_BLOCK
