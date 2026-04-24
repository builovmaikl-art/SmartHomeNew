FUNCTION_BLOCK FB_Heating_Decision_Context
VAR_INPUT
    VI_Manifold_Pump_In_Service : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Pressure_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Current_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Max_Active_Manifolds : INT;
    VI_Max_Thermal_Budget : REAL;
END_VAR
VAR_OUTPUT
    VO_Manifold_Allowed : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Heating_Degraded : BOOL;
    VO_Available_Manifold_Count : INT;
    VO_Capacity_Factor : REAL;
    VO_Effective_Max_Active_Manifolds : INT;
    VO_Effective_Thermal_Budget : REAL;
END_VAR
VAR
    L_i : INT;
END_VAR

VO_Heating_Degraded := FALSE;
VO_Available_Manifold_Count := 0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Allowed[L_i] := TRUE;

    IF NOT VI_Manifold_Pump_In_Service[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
    END_IF;

    IF VI_Manifold_Pressure_Fault[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
    END_IF;

    IF VI_Manifold_Current_Fault[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
    END_IF;

    IF VO_Manifold_Allowed[L_i] THEN
        VO_Available_Manifold_Count := VO_Available_Manifold_Count + 1;
    ELSE
        VO_Heating_Degraded := TRUE;
    END_IF;
END_FOR;

IF GVL_CONSTANTS.C_MAX_MANIFOLDS > 0 THEN
    VO_Capacity_Factor := INT_TO_REAL(VO_Available_Manifold_Count) / INT_TO_REAL(GVL_CONSTANTS.C_MAX_MANIFOLDS);
ELSE
    VO_Capacity_Factor := 0.0;
END_IF;

IF VO_Capacity_Factor < 0.0 THEN
    VO_Capacity_Factor := 0.0;
ELSIF VO_Capacity_Factor > 1.0 THEN
    VO_Capacity_Factor := 1.0;
END_IF;

VO_Effective_Max_Active_Manifolds := VI_Max_Active_Manifolds;
IF VO_Effective_Max_Active_Manifolds > VO_Available_Manifold_Count THEN
    VO_Effective_Max_Active_Manifolds := VO_Available_Manifold_Count;
END_IF;
IF VO_Effective_Max_Active_Manifolds < 0 THEN
    VO_Effective_Max_Active_Manifolds := 0;
END_IF;

VO_Effective_Thermal_Budget := VI_Max_Thermal_Budget * VO_Capacity_Factor;
