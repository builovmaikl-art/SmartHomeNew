FUNCTION_BLOCK FB_Heating_Adapter_CopyOut
VAR_INPUT
    VI_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR
VAR_IN_OUT
    VIO_Zone_Valves_State : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

// Extracted candidate from PRG_Heating S6.
// Not connected yet.
// No global switching yet.

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    VIO_Zone_Valves_State[L_i] := VI_Zone_Valves[L_i];
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Adapter_CopyOut <<<
