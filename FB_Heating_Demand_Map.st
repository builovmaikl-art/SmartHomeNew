FUNCTION_BLOCK FB_Heating_Demand_Map
VAR_INPUT
    VI_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;
END_VAR
VAR_OUTPUT
    VO_Manifold_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR
VAR
    L_i : INT;
    L_Manifold_ID : INT;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Demand_Map[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF VI_Zone_Valves[L_i] THEN
        L_Manifold_ID := VI_Zone_Configs[L_i].manifold_id;
        IF L_Manifold_ID >= 1 AND L_Manifold_ID <= GVL_CONSTANTS.C_MAX_MANIFOLDS THEN
            VO_Manifold_Demand_Map[L_Manifold_ID] := TRUE;
        END_IF;
    END_IF;
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Demand_Map <<<
