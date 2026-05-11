// ==============================================================================
// Heating runtime observability layer
//
// Projection/publication layer only.
//
// IMPORTANT:
// - does NOT own outputs;
// - does NOT control pumps/valves;
// - does NOT modify demand;
// - does NOT participate in runtime authority.
//
// Responsibility:
// - allocation snapshot publication;
// - policy diagnostics projection;
// - freeze/DHW bypass visibility;
// - runtime explainability;
// - bounded policy bridge visibility.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Observability
VAR_INPUT
    VI_Policy_Active : BOOL;
    VI_Freeze_Bypass_Active : BOOL;
    VI_DHW_Bypass_Active : BOOL;

    VI_Budget_Max : REAL;
    VI_Budget_Used : REAL;

    VI_Requested : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Allowed : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Filtered : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    VI_Block_Reason : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF E_Heating_Allocation_Block_Reason;
    VI_Effective_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;

    VI_Priority_Bridge_Active : BOOL;
    VI_Priority_Bias_Applied : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Priority_Effective : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
END_VAR
VAR
    L_i : INT;
    L_Policy_Target_Adjustment : REAL;
    L_Policy_Priority_Multiplier : REAL;
END_VAR

GVL_STATE.G_Allocation_Policy_Active := VI_Policy_Active;
GVL_STATE.G_Allocation_Freeze_Bypass_Active := VI_Freeze_Bypass_Active;
GVL_STATE.G_Allocation_DHW_Bypass_Active := VI_DHW_Bypass_Active;

GVL_STATE.G_Allocation_Budget_Max := VI_Budget_Max;
GVL_STATE.G_Allocation_Budget_Used := VI_Budget_Used;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATE.G_Allocation_Requested[L_i] := VI_Requested[L_i];
    GVL_STATE.G_Allocation_Allowed[L_i] := VI_Allowed[L_i];
    GVL_STATE.G_Allocation_Filtered[L_i] := VI_Filtered[L_i];

    GVL_STATE.G_Allocation_Block_Reason[L_i] := VI_Block_Reason[L_i];
    GVL_STATE.G_Allocation_Effective_Priority[L_i] := VI_Effective_Priority[L_i];

    GVL_STATE.G_Policy_Priority_Bias_Applied[L_i] := VI_Priority_Bias_Applied[L_i];
    GVL_STATE.G_Policy_Priority_Effective[L_i] := VI_Priority_Effective[L_i];
END_FOR;

GVL_STATE.G_Policy_Priority_Bridge_Active := VI_Priority_Bridge_Active;

// Bounded policy target bridge visibility.
// Mirrors the same clamp used by FB_Heating_System_Manager.
L_Policy_Target_Adjustment := GVL_HEATING_POLICY.G_Policy_Target_Adjustment;
IF L_Policy_Target_Adjustment > REAL#5.0 THEN
    L_Policy_Target_Adjustment := REAL#5.0;
ELSIF L_Policy_Target_Adjustment < REAL#-3.0 THEN
    L_Policy_Target_Adjustment := REAL#-3.0;
END_IF;

L_Policy_Priority_Multiplier := GVL_HEATING_POLICY.G_Policy_Priority_Multiplier;
IF L_Policy_Priority_Multiplier < REAL#0.3 THEN
    L_Policy_Priority_Multiplier := REAL#0.3;
ELSIF L_Policy_Priority_Multiplier > REAL#1.0 THEN
    L_Policy_Priority_Multiplier := REAL#1.0;
END_IF;

GVL_STATE.G_Policy_Target_Adjustment_Applied := L_Policy_Target_Adjustment;
GVL_STATE.G_Policy_Target_Adjustment_Active := ABS(L_Policy_Target_Adjustment) > REAL#0.001;
GVL_STATE.G_Policy_Priority_Multiplier_Applied := L_Policy_Priority_Multiplier;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observability <<<
