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
// Optional responsibility when explicitly enabled:
// - priority-based allocation;
// - thermal budget limiting.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Allocation_Filter
VAR_INPUT
    // Master runtime enable.
    // FALSE = strict passthrough.
    VI_Enable : BOOL;

    // Optional policy layer.
    // FALSE = only availability/service/degraded gate is active.
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

    // Policy inputs from active configuration.
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

    // Policy diagnostics.
    VO_Manifold_Priority_Effective : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF INT;
    VO_Thermal_Budget_Used : REAL;
END_VAR
VAR
    L_i : INT;
    L_CurrentPriority : INT;
    L_MaxPriority : INT;
    L_Used : REAL;
    L_Weight : REAL;
    L_AnyPolicyBlock : BOOL;
END_VAR

// ======================================================
// DEFAULT STATE
// ======================================================
VO_Allocation_Degraded := FALSE;
VO_Thermal_Budget_Used := REAL#0.0;
L_AnyPolicyBlock := FALSE;

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
// service gating and policy throttling.
// ======================================================
IF VI_Freeze_Mode_Active THEN
    RETURN;
END_IF;

// ======================================================
// DHW PRIORITY GATE
//
// Manifold_Control already owns DHW shutdown.
// Keep this filter transparent during DHW hold to avoid
// creating duplicate DHW authority here.
// ======================================================
IF VI_DHW_Heating_Demand THEN
    RETURN;
END_IF;

// ======================================================
// MANIFOLD AUTHORIZATION FILTER
// ======================================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO

    IF NOT VI_Manifold_Available[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
        VO_Manifold_Block_Reason[L_i] := 1;
    END_IF;

    IF NOT VI_Manifold_In_Service[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
        VO_Manifold_Block_Reason[L_i] := 2;
    END_IF;

    IF VI_Manifold_Subsystem_Degraded[L_i] THEN
        VO_Manifold_Allowed[L_i] := FALSE;
        VO_Manifold_Block_Reason[L_i] := 3;
    END_IF;

    IF VI_Manifold_Demand_Map[L_i] AND NOT VO_Manifold_Allowed[L_i] THEN
        VO_Manifold_Demand_Filtered[L_i] := FALSE;
        VO_Allocation_Degraded := TRUE;
    END_IF;

END_FOR;

// ======================================================
// OPTIONAL POLICY LAYER
//
// This layer can only reduce demand that is already
// authorized by availability/service/degraded checks.
// It never creates new demand and never writes outputs.
// ======================================================
IF NOT VI_Enable_Policy_Allocation THEN
    RETURN;
END_IF;

// Invalid or unset budget means no policy throttling.
IF VI_Max_Thermal_Budget <= REAL#0.0 THEN
    RETURN;
END_IF;

// Rebuild output demand from allowed candidates only.
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Manifold_Demand_Filtered[L_i] := FALSE;
END_FOR;

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
                L_AnyPolicyBlock := TRUE;
                IF VO_Manifold_Block_Reason[L_i] = 0 THEN
                    VO_Manifold_Block_Reason[L_i] := 4;
                END_IF;
            END_IF;
        END_IF;
    END_FOR;
END_FOR;

VO_Thermal_Budget_Used := L_Used;

IF L_AnyPolicyBlock THEN
    VO_Allocation_Degraded := TRUE;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Allocation_Filter <<<
