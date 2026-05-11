// ==============================================================================
// Heating policy priority bridge
//
// Bounded mapper from advisory zone policy to manifold allocation priority.
//
// IMPORTANT:
// - does NOT own demand;
// - does NOT create demand;
// - does NOT control pumps/valves;
// - does NOT write outputs;
// - does NOT bypass safety or service gates.
//
// Responsibility:
// - map circuit->zone policy bias into manifold effective priority;
// - keep the result bounded and deterministic;
// - provide a safe input for FB_Heating_Allocation_Filter.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Policy_Priority_Bridge
VAR_INPUT
    VI_Enable : BOOL;

    VI_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config;

    VI_Manifold_Base_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VI_Zone_Priority_Bias : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    VI_Policy_Priority_Multiplier : REAL;
END_VAR
VAR_OUTPUT
    VO_Manifold_Effective_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VO_Manifold_Priority_Bias_Applied : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VO_Bridge_Active : BOOL;
END_VAR
VAR
    L_i : INT;
    L_Manifold_ID : INT;
    L_Zone_ID : INT;
    L_Multiplier : REAL;
    L_Bias : REAL;
    L_Score : REAL;
    L_MaxScore : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
END_VAR

// Default passthrough state.
VO_Bridge_Active := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Effective_Priority[L_i] := VI_Manifold_Base_Priority[L_i];
    VO_Manifold_Priority_Bias_Applied[L_i] := REAL#1.0;
    L_MaxScore[L_i] := TO_REAL(VI_Manifold_Base_Priority[L_i]);
END_FOR;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

L_Multiplier := VI_Policy_Priority_Multiplier;
IF L_Multiplier < REAL#0.3 THEN
    L_Multiplier := REAL#0.3;
ELSIF L_Multiplier > REAL#1.0 THEN
    L_Multiplier := REAL#1.0;
END_IF;

IF ABS(L_Multiplier - REAL#1.0) > REAL#0.001 THEN
    VO_Bridge_Active := TRUE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF VI_Zone_Valves[L_i] THEN
        L_Manifold_ID := TO_INT(VI_Zone_Configs[L_i].manifold_id);
        L_Zone_ID := TO_INT(VI_Zone_Configs[L_i].zone);

        IF (L_Manifold_ID >= 1)
           AND (L_Manifold_ID <= GVL_CONSTANTS.C_MAX_MANIFOLDS)
           AND (L_Zone_ID >= 1)
           AND (L_Zone_ID <= GVL_CONSTANTS.C_MAX_ZONES) THEN

            L_Bias := VI_Zone_Priority_Bias[L_Zone_ID];
            IF L_Bias < REAL#0.3 THEN
                L_Bias := REAL#0.3;
            ELSIF L_Bias > REAL#1.5 THEN
                L_Bias := REAL#1.5;
            END_IF;

            IF ABS(L_Bias - REAL#1.0) > REAL#0.001 THEN
                VO_Bridge_Active := TRUE;
            END_IF;

            IF L_Bias > VO_Manifold_Priority_Bias_Applied[L_Manifold_ID] THEN
                VO_Manifold_Priority_Bias_Applied[L_Manifold_ID] := L_Bias;
            END_IF;

            L_Score := TO_REAL(VI_Manifold_Base_Priority[L_Manifold_ID]) * L_Multiplier * L_Bias;

            IF L_Score > L_MaxScore[L_Manifold_ID] THEN
                L_MaxScore[L_Manifold_ID] := L_Score;
            END_IF;
        END_IF;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF L_MaxScore[L_i] >= REAL#3.5 THEN
        VO_Manifold_Effective_Priority[L_i] := 4;
    ELSIF L_MaxScore[L_i] >= REAL#2.5 THEN
        VO_Manifold_Effective_Priority[L_i] := 3;
    ELSIF L_MaxScore[L_i] >= REAL#1.5 THEN
        VO_Manifold_Effective_Priority[L_i] := 2;
    ELSIF L_MaxScore[L_i] >= REAL#0.5 THEN
        VO_Manifold_Effective_Priority[L_i] := 1;
    ELSE
        VO_Manifold_Effective_Priority[L_i] := 0;
    END_IF;
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Policy_Priority_Bridge <<<
