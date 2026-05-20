FUNCTION_BLOCK FB_Water_Output_Projection
VAR_INPUT
    VI_Zone_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_WATER_ZONES] OF BOOL;

    // Common inlet valves: 35 = ХВС, 36 = ГВС.
    VI_Valve_35_Open : BOOL;
    VI_Valve_35_Close : BOOL;
    VI_Valve_36_Open : BOOL;
    VI_Valve_36_Close : BOOL;

    // Local riser valves: 1/2 riser 1, 3/4 riser 2, 5/6 riser 3.
    VI_Local_Valve_Open : ARRAY[1..6] OF BOOL;
    VI_Local_Valve_Close : ARRAY[1..6] OF BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WATER_ZONES DO
    GVL_WATER_OUTPUT.DO_Water_Zone_Enable[L_i] := VI_Zone_Enable[L_i];
END_FOR;

GVL_WATER_OUTPUT.DO_Water_Valve_35_Open := VI_Valve_35_Open;
GVL_WATER_OUTPUT.DO_Water_Valve_35_Close := VI_Valve_35_Close;
GVL_WATER_OUTPUT.DO_Water_Valve_36_Open := VI_Valve_36_Open;
GVL_WATER_OUTPUT.DO_Water_Valve_36_Close := VI_Valve_36_Close;

FOR L_i := 1 TO 6 DO
    GVL_WATER_OUTPUT.DO_Water_Local_Valve_Open[L_i] := VI_Local_Valve_Open[L_i];
    GVL_WATER_OUTPUT.DO_Water_Local_Valve_Close[L_i] := VI_Local_Valve_Close[L_i];
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Water_Output_Projection <<<