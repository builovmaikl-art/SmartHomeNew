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
// - runtime explainability.
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

    VI_Block_Reason : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VI_Effective_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
END_VAR
VAR
    L_i : INT;
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
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observability <<<
