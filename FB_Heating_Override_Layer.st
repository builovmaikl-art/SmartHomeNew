FUNCTION_BLOCK FB_Heating_Override_Layer
VAR_INPUT
    VI_Block_Heating : BOOL;
    VI_Manifold_Enabled : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
END_VAR
VAR_IN_OUT
    VIO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VIO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VIO_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR
VAR
    L_i : INT;
    L_j : INT;
END_VAR

// Applies command + allocation overrides to execution outputs.

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Block_Heating OR (NOT VI_Manifold_Enabled[L_i]) THEN
        VIO_Manifold_Pumps[L_i] := FALSE;
        VIO_Manifold_Valves[L_i] := 0.0;

        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
            IF VI_Zone_Configs[L_j].manifold_id = L_i THEN
                VIO_Zone_Valves[L_j] := FALSE;
            END_IF;
        END_FOR;
    END_IF;
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Override_Layer <<<
