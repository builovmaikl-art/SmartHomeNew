// ==============================================================================
// Heating allocation filter
// Bounded policy filter between demand map and manifold control.
//
// Purpose:
// - preserve current runtime ownership;
// - avoid reconnecting legacy orchestration wrappers;
// - provide a safe insertion point for selective thermal allocation logic;
// - keep default behavior transparent when disabled.
//
// This FB does NOT own:
// - heating orchestration;
// - boiler control;
// - valve control;
// - pump control;
// - safety state;
// - output projection.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Allocation_Filter
VAR_INPUT
    VI_Enable : BOOL;

    // Current demand from FB_Heating_Demand_Map.
    VI_Manifold_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // Availability must come from current active owners / diagnostics.
    // TRUE means the manifold is allowed to receive demand.
    VI_Manifold_Available : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR
VAR_OUTPUT
    // Demand forwarded to FB_Heating_Manifold_Control.
    VO_Manifold_Demand_Filtered : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // TRUE when at least one demanded manifold was blocked by availability.
    VO_Allocation_Degraded : BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

// ======================================================
// DEFAULT / TRANSPARENT MODE
// ======================================================
VO_Allocation_Degraded := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Demand_Filtered[L_i] := VI_Manifold_Demand_Map[L_i];
END_FOR;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// SAFE AVAILABILITY FILTER
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Manifold_Demand_Map[L_i] AND NOT VI_Manifold_Available[L_i] THEN
        VO_Manifold_Demand_Filtered[L_i] := FALSE;
        VO_Allocation_Degraded := TRUE;
    END_IF;
END_FOR;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Allocation_Filter <<<
