FUNCTION_BLOCK FB_Heating_Output_Projection
VAR_INPUT
    VI_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VI_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_DHW_Heating_Pump : BOOL;
    VI_DHW_Circ_Pump : BOOL;
    VI_Backup_Circulation_Pump : BOOL;
    VI_Electric_Heater_Enable : BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_HEATING_OUTPUT.DO_Zone_Valves[L_i] := VI_Zone_Valves[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i] := VI_Manifold_Pumps[L_i];
    GVL_HEATING_OUTPUT.AO_Manifold_Valves[L_i] := REAL_TO_UINT(VI_Manifold_Valves[L_i] * 1000.0);
END_FOR;

GVL_HEATING_OUTPUT.DO_DHW_Heating_Pump := VI_DHW_Heating_Pump;
GVL_HEATING_OUTPUT.DO_DHW_Circ_Pump := VI_DHW_Circ_Pump;
GVL_HEATING_OUTPUT.DO_Backup_Circulation_Pump := VI_Backup_Circulation_Pump;
GVL_HEATING_OUTPUT.DO_Electric_Heater_Enable := VI_Electric_Heater_Enable;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Output_Projection <<<
