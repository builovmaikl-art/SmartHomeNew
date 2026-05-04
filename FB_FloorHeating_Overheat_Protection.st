FUNCTION_BLOCK FB_FloorHeating_Overheat_Protection
VAR_INPUT
    VI_Threshold : REAL := 45.0;
END_VAR
VAR_IN_OUT
    VI_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
END_VAR
VAR_OUTPUT
    VO_Overheat_Detected : BOOL;
    VO_Locked_Circuits : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

VO_Overheat_Detected := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF VI_Temps[L_i] > VI_Threshold THEN
        VO_Overheat_Detected := TRUE;
        VO_Locked_Circuits[L_i] := TRUE;
    END_IF;
END_FOR;
END_FUNCTION_BLOCK
