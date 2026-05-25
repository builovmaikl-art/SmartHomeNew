FUNCTION_BLOCK FB_Heating_Optimizer
VAR
    L_i : INT;
    L_Load : REAL;
    L_Total_Demand : REAL;
END_VAR

// ==============================================================================
// Ownership note
// ------------------------------------------------------------------------------
// This block calculates optimization diagnostics only.
// It does NOT modify thermal demand.
//
// Thermal demand ownership remains in:
// FB_Heating_Thermal_Model.
// ==============================================================================

L_Total_Demand := 0.0;

// Aggregate thermal load estimate.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Total_Demand := L_Total_Demand + ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Demand[L_i]);
END_FOR;

GVL_HEATING_POLICY.G_Optimization_Load_Index := L_Total_Demand;
GVL_HEATING_POLICY.G_Optimization_Energy_Saving_Active := FALSE;

// Zone optimization diagnostics.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO

    IF L_Total_Demand > 0.01 THEN
        L_Load := ABS(GVL_HEATING_POLICY.G_Zone_Thermal_Demand[L_i]) / L_Total_Demand;
    ELSE
        L_Load := 0.0;
    END_IF;

    GVL_HEATING_POLICY.G_Zone_Optimization_Score[L_i] :=
        L_Load +
        ((1.0 - GVL_HEATING_POLICY.G_Zone_Thermal_Model_Confidence[L_i]) * 0.2);

    // Advisory energy-saving indication only.
    IF L_Total_Demand > 5.0 THEN
        GVL_HEATING_POLICY.G_Optimization_Energy_Saving_Active := TRUE;
    END_IF;

END_FOR;

END_FUNCTION_BLOCK
