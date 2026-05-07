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
//
// Migration source:
// - useful bounded logic from FB_Heating_Thermal_Allocation;
// - useful bounded logic from FB_Heating_Decision_Context.
//
// Explicitly not migrated:
// - FB_Heating_Orchestration wrapper;
// - FB_Heating_Execution_Core wrapper;
// - FB_Heating_Override_Layer hard output authority.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Allocation_Filter
VAR_INPUT
    // Master switch for any filtering.
    // FALSE means strict passthrough: output demand equals input demand.
    VI_Enable : BOOL;

    // Enables optional priority/budget allocation.
    // FALSE means only safe availability filtering may run when VI_Enable is TRUE.
    VI_Enable_Policy_Allocation : BOOL := FALSE;

    // Current demand from FB_Heating_Demand_Map.
    VI_Manifold_Demand_Map : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // Availability must come from current active owners / diagnostics.
    // TRUE means the manifold is allowed to receive demand.
    VI_Manifold_Available : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // Optional policy inputs staged for future activation.
    // They intentionally stay outside existing DUT/GVL contract for now.
    VI_Manifold_Base_Priority : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VI_Manifold_Thermal_Weight : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Max_Thermal_Budget : REAL := REAL#0.0;
END_VAR
VAR_OUTPUT
    // Demand forwarded to FB_Heating_Manifold_Control.
    VO_Manifold_Demand_Filtered : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;

    // TRUE when at least one demanded manifold was blocked by availability or policy.
    VO_Allocation_Degraded : BOOL;

    // Diagnostic outputs for later observation/HMI integration.
    VO_Manifold_Allowed : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Manifold_Priority_Effective : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VO_Thermal_Budget_Used : REAL;
END_VAR
VAR
    L_i : INT;
    L_CurrentPriority : INT;
    L_MaxPriority : INT;
    L_Used : REAL;
    L_Weight : REAL;
END_VAR

// ======================================================
// DEFAULT / TRANSPARENT MODE
// ======================================================
VO_Allocation_Degraded := FALSE;
VO_Thermal_Budget_Used := REAL#0.0;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Demand_Filtered[L_i] := VI_Manifold_Demand_Map[L_i];
    VO_Manifold_Allowed[L_i] := TRUE;
    VO_Manifold_Priority_Effective[L_i] := VI_Manifold_Base_Priority[L_i];
END_FOR;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// SAFE AVAILABILITY FILTER
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Allowed[L_i] := VI_Manifold_Available[L_i];

    IF VI_Manifold_Demand_Map[L_i] AND NOT VO_Manifold_Allowed[L_i] THEN
        VO_Manifold_Demand_Filtered[L_i] := FALSE;
        VO_Allocation_Degraded := TRUE;
    END_IF;
END_FOR;

// ======================================================
// OPTIONAL POLICY / THERMAL BUDGET ALLOCATION
// ======================================================
IF NOT VI_Enable_Policy_Allocation THEN
    RETURN;
END_IF;

// Invalid or unset budget means do not apply budget shedding.
IF VI_Max_Thermal_Budget <= REAL#0.0 THEN
    RETURN;
END_IF;

// Clear filtered demand before rebuilding it by priority and budget.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Demand_Filtered[L_i] := FALSE;
END_FOR;

// Find max priority among demanded and allowed manifolds.
L_MaxPriority := 0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VI_Manifold_Demand_Map[L_i] AND VO_Manifold_Allowed[L_i] THEN
        IF VO_Manifold_Priority_Effective[L_i] > L_MaxPriority THEN
            L_MaxPriority := VO_Manifold_Priority_Effective[L_i];
        END_IF;
    END_IF;
END_FOR;

L_Used := REAL#0.0;

FOR L_CurrentPriority := L_MaxPriority TO 0 BY -1 DO
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF VI_Manifold_Demand_Map[L_i]
           AND VO_Manifold_Allowed[L_i]
           AND (VO_Manifold_Priority_Effective[L_i] = L_CurrentPriority) THEN

            L_Weight := VI_Manifold_Thermal_Weight[L_i];
            IF L_Weight <= REAL#0.0 THEN
                L_Weight := REAL#1.0;
            END_IF;

            IF (L_Used + L_Weight) <= VI_Max_Thermal_Budget THEN
                VO_Manifold_Demand_Filtered[L_i] := TRUE;
                L_Used := L_Used + L_Weight;
            ELSE
                VO_Allocation_Degraded := TRUE;
            END_IF;
        END_IF;
    END_FOR;
END_FOR;

VO_Thermal_Budget_Used := L_Used;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Allocation_Filter <<<
