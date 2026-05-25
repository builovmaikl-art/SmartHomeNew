PROGRAM PRG_Semantic_Preservation_Governor
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
GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Valid := FALSE;
GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Granted := FALSE;
GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Quarantine_Active := TRUE;

GVL_SEMANTIC_PRESERVATION_FABRIC.Declared_System_Intent_Coherent := FALSE;
GVL_SEMANTIC_PRESERVATION_FABRIC.Adaptive_Policy_Bounded := FALSE;
GVL_SEMANTIC_PRESERVATION_FABRIC.Cross_Domain_Intent_Aligned := FALSE;
GVL_SEMANTIC_PRESERVATION_FABRIC.Optimization_Goals_Coherent := FALSE;
GVL_SEMANTIC_PRESERVATION_FABRIC.Behavioral_Evolution_Stable := FALSE;

// Runtime sustainability required.
IF NOT GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Granted THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39000;
    L_Error_Text := 'Runtime sustainability authority not granted';
END_IF;

// Semantic drift detectors.
IF GVL_SEMANTIC_PRESERVATION_FABRIC.Adaptive_Policy_Drift_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39001;
    L_Error_Text := 'Adaptive policy drift detected';
END_IF;

IF GVL_SEMANTIC_PRESERVATION_FABRIC.Optimization_Semantic_Erosion_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39002;
    L_Error_Text := 'Optimization semantic erosion detected';
END_IF;

IF GVL_SEMANTIC_PRESERVATION_FABRIC.CrossDomain_Intent_Divergence_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39003;
    L_Error_Text := 'Cross-domain intent divergence detected';
END_IF;

IF GVL_SEMANTIC_PRESERVATION_FABRIC.LongTerm_Objective_Mutation_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39004;
    L_Error_Text := 'Long-term objective mutation detected';
END_IF;

IF GVL_SEMANTIC_PRESERVATION_FABRIC.Behavior_Learning_Instability_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39005;
    L_Error_Text := 'Behavior learning instability detected';
END_IF;

IF GVL_SEMANTIC_PRESERVATION_FABRIC.Silent_Governance_Reinterpretation_Detected THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39006;
    L_Error_Text := 'Silent governance reinterpretation detected';
END_IF;

// Immutable semantic intent validation.
IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_PRESERVATION_FABRIC.Objective_Boundaries_Immutable THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39010;
    L_Error_Text := 'Objective boundaries immutability invalid';
END_IF;

IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Governance_Coherent THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39011;
    L_Error_Text := 'Semantic governance coherence invalid';
END_IF;

IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_PRESERVATION_FABRIC.Adaptive_Runtime_Intent_Stable THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39012;
    L_Error_Text := 'Adaptive runtime intent unstable';
END_IF;

IF L_Semantic_Valid
AND NOT GVL_SEMANTIC_PRESERVATION_FABRIC.LongTerm_Semantic_Evolution_Valid THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 39013;
    L_Error_Text := 'Long-term semantic evolution invalid';
END_IF;

IF L_Semantic_Valid THEN
    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Valid := TRUE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Granted := TRUE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Quarantine_Active := FALSE;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Declared_System_Intent_Coherent := TRUE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Adaptive_Policy_Bounded := TRUE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Cross_Domain_Intent_Aligned := TRUE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Optimization_Goals_Coherent := TRUE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Behavioral_Evolution_Stable := TRUE;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Epoch :=
        GVL_RUNTIME_SUSTAINABILITY_FABRIC.Runtime_Sustainability_Epoch;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Epoch_Coherent := TRUE;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Last_Update_MS :=
        L_Now_MS;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Lease_Expired := FALSE;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Last_Error_Code := 0;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Last_Error_Text := '';
ELSE
    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Valid := FALSE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Granted := FALSE;
    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Quarantine_Active := TRUE;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Lease_Expired := TRUE;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Last_Error_Code :=
        L_Error_Code;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Last_Error_Text :=
        L_Error_Text;

    GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Invalidation_Count :=
        GVL_SEMANTIC_PRESERVATION_FABRIC.Semantic_Preservation_Invalidation_Count + 1;
END_IF;

END_PROGRAM