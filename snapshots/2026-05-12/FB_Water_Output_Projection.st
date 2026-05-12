FUNCTION_BLOCK FB_Water_Output_Projection
VAR_INPUT
    VI_Zone_Enable : ARRAY[1..32] OF BOOL;
    VI_Valve_35_Close : BOOL;
    VI_Valve_36_Close : BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

FOR L_i := 1 TO 32 DO
    GVL_WATER_OUTPUT.DO_Water_Zone_Enable[L_i] := VI_Zone_Enable[L_i];
END_FOR;

GVL_WATER_OUTPUT.DO_Water_Valve_35_Close := VI_Valve_35_Close;
GVL_WATER_OUTPUT.DO_Water_Valve_36_Close := VI_Valve_36_Close;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Water_Output_Projection <<<
