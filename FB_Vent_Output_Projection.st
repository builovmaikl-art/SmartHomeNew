FUNCTION_BLOCK FB_Vent_Output_Projection
VAR_INPUT
    VI_Supply_Fans : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_FANS] OF REAL;
    VI_Exhaust_Fans : ARRAY[1..GVL_CONSTANTS.C_MAX_EXHAUST_FANS] OF REAL;
END_VAR
VAR
    L_i : INT;
END_VAR

// Convert STATE ventilation outputs into IO-ready format

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    GVL_VENT_OUTPUT.AO_Supply_Fans[L_i] := REAL_TO_UINT(VI_Supply_Fans[L_i] * 100.0);
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    GVL_VENT_OUTPUT.AO_Exhaust_Fans[L_i] := REAL_TO_UINT(VI_Exhaust_Fans[L_i] * 100.0);
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Vent_Output_Projection <<<
