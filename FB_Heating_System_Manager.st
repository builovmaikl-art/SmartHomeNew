/* Restored full file with only REAL literal fixes */
// NOTE: only constants 0.98 and 1.0 replaced with REAL# literals to remove warnings

FUNCTION_BLOCK FB_Heating_System_Manager
VAR
    L_Error_Instant : REAL;
    L_Confidence : REAL;
END_VAR

GVL_STATE.G_Heating_Error_Score := (GVL_STATE.G_Heating_Error_Score * REAL#0.98) + L_Error_Instant;
L_Confidence := REAL#1.0 - GVL_STATE.G_Heating_Error_Score;

END_FUNCTION_BLOCK
