PROGRAM PRG_Semantic_Continuity_Authority_Governor
VAR
    L_Now_MS : UDINT;
    L_Semantic_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Semantic_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Valid := FALSE;
GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Granted := FALSE;
GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Quarantine_Active := TRUE;

GVL_SEMANTIC_CONTINUITY.Operator_Intent_Coherent := FALSE;
GVL_SEMANTIC_CONTINUITY.Policy_Intent_Coherent := FALSE;
GVL_SEMANTIC_CONTINUITY.Adaptive_Behavior_Coherent := FALSE;
GVL_SEMANTIC_CONTINUITY.Recovery_Intent_Coherent := FALSE;
GVL_SEMANTIC_CONTINUITY.Distributed_Semantic_Coherent := FALSE;

// Runtime resource authority required.
IF NOT GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Granted THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31000;
    L_Error_Text := 'Runtime resource authority not granted';
END_IF;

// Semantic drift detectors.
IF GVL_SEMANTIC_CONTINUITY.Goal_Drift_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31001;
    L_Error_Text := 'Goal drift detected';
END_IF;

IF GVL_SEMANTIC_CONTINUITY.Policy_Divergence_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31002;
    L_Error_Text := 'Policy divergence detected';
END_IF;

IF GVL_SEMANTIC_CONTINUITY.Adaptive_Learning_Semantic_Skew THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31003;
    L_Error_Text := 'Adaptive semantic skew detected';
END_IF;

IF GVL_SEMANTIC_CONTINUITY.Recovery_Intent_Mismatch_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31004;
    L_Error_Text := 'Recovery intent mismatch detected';
END_IF;

IF GVL_SEMANTIC_CONTINUITY.Optimization_Authority_Corruption_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31005;
    L_Error_Text := 'Optimization authority corruption detected';
END_IF;

IF GVL_SEMANTIC_CONTINUITY.Distributed_Semantic_Fragmentation_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31006;
    L_Error_Text := 'Distributed semantic fragmentation detected';
END_IF;

// Intent continuity validation.
IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_CONTINUITY.Declared_System_Intent_Valid THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31010;
    L_Error_Text := 'Declared system intent invalid';
END_IF;

IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_CONTINUITY.Runtime_Goal_Alignment_Valid THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31011;
    L_Error_Text := 'Runtime goal alignment invalid';
END_IF;

IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_CONTINUITY.Optimization_Boundary_Valid THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31012;
    L_Error_Text := 'Optimization boundary invalid';
END_IF;

IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_CONTINUITY.Autonomous_Adjustment_Valid THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 31013;
    L_Error_Text := 'Autonomous adjustment invalid';
END_IF;

IF L_Semantic_Valid THEN
    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Valid := TRUE;
    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Granted := TRUE;
    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Quarantine_Active := FALSE;

    GVL_SEMANTIC_CONTINUITY.Operator_Intent_Coherent := TRUE;
    GVL_SEMANTIC_CONTINUITY.Policy_Intent_Coherent := TRUE;
    GVL_SEMANTIC_CONTINUITY.Adaptive_Behavior_Coherent := TRUE;
    GVL_SEMANTIC_CONTINUITY.Recovery_Intent_Coherent := TRUE;
    GVL_SEMANTIC_CONTINUITY.Distributed_Semantic_Coherent := TRUE;

    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Epoch :=
        GVL_RUNTIME_RESOURCE_AUTHORITY.Runtime_Resource_Authority_Epoch;

    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Epoch_Coherent := TRUE;

    GVL_SEMANTIC_CONTINUITY.Semantic_Last_Update_MS := L_Now_MS;
    GVL_SEMANTIC_CONTINUITY.Semantic_Lease_Expired := FALSE;

    GVL_SEMANTIC_CONTINUITY.Semantic_Last_Error_Code := 0;
    GVL_SEMANTIC_CONTINUITY.Semantic_Last_Error_Text := '';
ELSE
    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Valid := FALSE;
    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Granted := FALSE;
    GVL_SEMANTIC_CONTINUITY.Semantic_Continuity_Quarantine_Active := TRUE;

    GVL_SEMANTIC_CONTINUITY.Semantic_Lease_Expired := TRUE;

    GVL_SEMANTIC_CONTINUITY.Semantic_Last_Error_Code :=
        L_Error_Code;

    GVL_SEMANTIC_CONTINUITY.Semantic_Last_Error_Text :=
        L_Error_Text;

    GVL_SEMANTIC_CONTINUITY.Semantic_Invalidation_Count :=
        GVL_SEMANTIC_CONTINUITY.Semantic_Invalidation_Count + 1;
END_IF;

END_PROGRAM