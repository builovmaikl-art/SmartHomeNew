PROGRAM PRG_Semantic_Epoch_Invariance_Governor
VAR
    L_Now_MS : UDINT;
    L_Invariance_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Invariance_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Valid := FALSE;
GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Granted := FALSE;
GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Quarantine_Active := TRUE;

GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Authority_Semantics_Invariant := FALSE;
GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.CrossEpoch_Permission_Mapping_Stable := FALSE;
GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Intent_Continuity_Valid := FALSE;
GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Governance_Meaning_Preservation_Coherent := FALSE;
GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Evolution_Lineage_Traceable := FALSE;

// Trust epoch monotonicity required.
IF NOT GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Granted THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49000;
    L_Error_Text := 'Trust epoch monotonicity not granted';
END_IF;

// Semantic epoch drift detectors.
IF GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Authority_Drift_Detected THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49001;
    L_Error_Text := 'Semantic authority drift detected';
END_IF;

IF GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.CrossEpoch_Permission_Reinterpretation THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49002;
    L_Error_Text := 'Cross-epoch permission reinterpretation detected';
END_IF;

IF GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Intent_To_Authority_Mismatch_Detected THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49003;
    L_Error_Text := 'Intent-to-authority mismatch detected';
END_IF;

IF GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Governance_Semantic_Fork_Detected THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49004;
    L_Error_Text := 'Governance semantic fork detected';
END_IF;

IF GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Migration_Lineage_Gap_Detected THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49005;
    L_Error_Text := 'Semantic migration lineage gap detected';
END_IF;

IF GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Distributed_Semantic_Divergence_Detected THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49006;
    L_Error_Text := 'Distributed semantic divergence detected';
END_IF;

// Semantic invariance validation.
IF L_Invariance_Valid
AND NOT GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Explicit_Semantic_Migration_Governed THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49010;
    L_Error_Text := 'Explicit semantic migration governance invalid';
END_IF;

IF L_Invariance_Valid
AND NOT GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.CrossEpoch_Semantic_Equivalence_Valid THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49011;
    L_Error_Text := 'Cross-epoch semantic equivalence invalid';
END_IF;

IF L_Invariance_Valid
AND NOT GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Distributed_Semantic_Consensus_Stable THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49012;
    L_Error_Text := 'Distributed semantic consensus invalid';
END_IF;

IF L_Invariance_Valid
AND NOT GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Interpretation_Integrity_Valid THEN
    L_Invariance_Valid := FALSE;
    L_Error_Code := 49013;
    L_Error_Text := 'Semantic interpretation integrity invalid';
END_IF;

IF L_Invariance_Valid THEN
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Valid := TRUE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Granted := TRUE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Quarantine_Active := FALSE;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Authority_Semantics_Invariant := TRUE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.CrossEpoch_Permission_Mapping_Stable := TRUE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Intent_Continuity_Valid := TRUE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Governance_Meaning_Preservation_Coherent := TRUE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Evolution_Lineage_Traceable := TRUE;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Epoch :=
        GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Epoch;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Epoch_Coherent := TRUE;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Last_Update_MS :=
        L_Now_MS;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Lease_Expired := FALSE;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Last_Error_Code := 0;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Last_Error_Text := '';
ELSE
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Valid := FALSE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Granted := FALSE;
    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Quarantine_Active := TRUE;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Lease_Expired := TRUE;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Last_Error_Code :=
        L_Error_Code;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Last_Error_Text :=
        L_Error_Text;

    GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Invalidation_Count :=
        GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Invalidation_Count + 1;
END_IF;

END_PROGRAM