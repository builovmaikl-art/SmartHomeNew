// ==============================================================================
// Heating allocation filter
// Runtime decision gate between Demand_Map and Manifold_Control.
//
// IMPORTANT:
// This FB is NOT a second runtime owner.
// This FB is NOT an orchestration layer.
//
// Actual ownership remains in:
// PRG_Heating
// → FB_Heating_System_Manager
// → active subsystem owners.
//
// Current responsibility:
// - manifold availability gating;
// - service-state filtering;
// - freeze-mode exceptions;
// - bounded demand authorization.
//
// Future optional responsibility:
// - thermal budget allocation;
// - priority weighting.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Allocation_Filter
VAR_INPUT
    // Master runtime enable.
    // FALSE = strict passthrough.
    VI_Enable : BOOL;

    // Optional future policy layer.
    VI_Enable_Policy_Allocation : BOOL := FALSE;

    // System-level context.
    VI_Freeze_Mode_Active : BOOL;
    VI_DHW_Heating_Demand : BOOL;

    // Current manifold demand.
    VI_Manifold_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // Runtime/service availability.
    VI_Manifold_Available : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_In_Service : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Subsystem_Degraded : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // Future policy placeholders.
    VI_Manifold_Base_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VI_Manifold_Thermal_Weight : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Max_Thermal_Budget : REAL := REAL#0.0;
END_VAR
VAR_OUTPUT
    // Authorized demand.
    VO_Manifold_Demand_Filtered : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // Runtime degraded indicator.
    VO_Allocation_Degraded : BOOL;

    // Explainability/diagnostics.
    VO_Manifold_Allowed : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Manifold_Block_Reason : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;

    // Future policy outputs.
    VO_Manifold_Priority_Effective : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VO_Thermal_Budget_Used : REAL;
END_VAR
VAR
    L_i : INT;
END_VAR

// ======================================================
// DEFAULT STATE
// ======================================================
VO_Allocation_Degraded := FALSE;
VO_Thermal_Budget_Used := REAL#0.0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Demand_Filtered[L_i] := VI_Manifold_Demand_Map[L_i];
    VO_Manifold_Allowed[L_i] := TRUE;
    VO_Manifold_Block_Reason[L_i] := 0;
    VO_Manifold_Priority_Effective[L_i] := VI_Manifold_Base_Priority[L_i];
END_FOR;

// ======================================================
// STRICT PASSTHROUGH MODE
// ======================================================
IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// FREEZE EXCEPTION MODE
//
// Freeze protection has higher authority than
// service gating and degraded filtering.
// ======================================================
IF VI_Freeze_Mode_Active THEN
    RETURN;
END_IF;

// ======================================================
// DHW PRIORITY GATE
//
// Heating demand is irrelevant during DHW hold.
// We intentionally keep the filter transparent here
// because Manifold_Control already owns DHW shutdown.
// ======================================================
IF VI_DHW_Heating_Demand THEN
    RETURN;
END_IF;

// ======================================================
// MANIFOLD AUTHORIZATION FILTER
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO

    // --------------------------------------------------
    // Runtime availability.
    // --------------------------------------------------
    IF NOT VI_Manifold_Available[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
        VO_Manifold_Block_Reason[L_i] := 1;
    END_IF;

    // --------------------------------------------------
    // Service state.
    // --------------------------------------------------
    IF NOT VI_Manifold_In_Service[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
        VO_Manifold_Block_Reason[L_i] := 2;
    END_IF;

    // --------------------------------------------------
    // Existing runtime degraded state.
    // --------------------------------------------------
    IF VI_Manifold_Subsystem_Degraded[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
        VO_Manifold_Block_Reason[L_i] := 3;
    END_IF;

    // --------------------------------------------------
    // Final authorization.
    // --------------------------------------------------
    IF VI_Manifold_Demand_Map[L_i] AND NOT VO_Manifold_Allowed[L_i] THEN
        VO_Manifold_Demand_Filtered[L_i] := FALSE;
        VO_Allocation_Degraded := TRUE;
    END_IF;

END_FOR;

// ======================================================
// FUTURE POLICY LAYER
// ======================================================
IF NOT VI_Enable_Policy_Allocation THEN
    RETURN;
END_IF;

// Future thermal budget / priority allocation intentionally disabled.
// Runtime behavior must first stabilize around explicit authorization semantics.

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Allocation_Filter <<<
