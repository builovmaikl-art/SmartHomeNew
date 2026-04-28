// ==============================================================================
// Heating manifold control helper
//
// Internal refactoring helper for FB_Heating_System_Manager.
// Not connected yet.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Manifold_Control
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR

VAR_IN_OUT
    VI_Manifold_Temps_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Temps_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
END_VAR

VAR_OUTPUT
    VO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
END_VAR

// Placeholder logic
// >>> BULK_SYNC_ANCHOR: FB_Heating_Manifold_Control <<<
