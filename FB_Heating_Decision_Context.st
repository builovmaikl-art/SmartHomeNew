FUNCTION_BLOCK FB_Heating_Decision_Context
VAR_INPUT
    VI_Manifold_Pump_In_Service : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Pressure_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Current_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Thermal_Weight : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VI_Max_Thermal_Budget : REAL;
END_VAR
VAR_OUTPUT
    VO_Manifold_Allowed : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Manifold_Enabled : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Heating_Degraded : BOOL;
END_VAR
VAR
    L_i : INT;
    L_j : INT;
    L_Used : REAL;
    L_Selected : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_MaxPriority : INT;
    L_CurrentPriority : INT;
END_VAR

VO_Heating_Degraded := FALSE;

// STEP 1: Allowed
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

    IF NOT VO_Manifold_Allowed[L_i] THEN
        VO_Heating_Degraded := TRUE;
    END_IF;
END_FOR;

// STEP 2: find max priority
L_MaxPriority := 0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Manifold_Priority[L_i] > L_MaxPriority THEN
        L_MaxPriority := VI_Manifold_Priority[L_i];
    END_IF;
END_FOR;

// STEP 3: allocation by priority + budget
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Enabled[L_i] := FALSE;
END_FOR;

L_Used := 0.0;

FOR L_CurrentPriority := L_MaxPriority TO 1 BY -1 DO

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO

        IF (VI_Manifold_Priority[L_i] = L_CurrentPriority) AND VO_Manifold_Allowed[L_i] THEN

            IF (L_Used + VI_Manifold_Thermal_Weight[L_i]) <= VI_Max_Thermal_Budget THEN
                VO_Manifold_Enabled[L_i] := TRUE;
                L_Used := L_Used + VI_Manifold_Thermal_Weight[L_i];
            END_IF;

        END_IF;

    END_FOR;

END_FOR;
END_FUNCTION_BLOCK
