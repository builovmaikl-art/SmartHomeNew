PROGRAM PRG_Governance_Validator_Integrity_Governor
VAR
    L_Now_MS : UDINT;
    L_Integrity_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Integrity_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Valid := FALSE;
GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Granted := FALSE;
GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Quarantine_Active := TRUE;

GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Semantics_Immutable := FALSE;
GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.CrossEpoch_Validation_Equivalence_Stable := FALSE;
GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Distributed_Validator_Consensus_Valid := FALSE;
GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Rule_Integrity_Canonical := FALSE;
GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Lineage_Coherent := FALSE;

// Governance feedback integrity required.
IF NOT GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Granted THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53000;
    L_Error_Text := 'Governance feedback integrity not granted';
END_IF;

// Validator self-corruption detectors.
IF GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Semantic_Drift_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53001;
    L_Error_Text := 'Validator semantic drift detected';
END_IF;

IF GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.CrossNode_Validation_Fork THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53002;
    L_Error_Text := 'Cross-node validation fork detected';
END_IF;

IF GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Rule_Mutation_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53003;
    L_Error_Text := 'Governance rule mutation detected';
END_IF;

IF GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.SelfReferential_Validator_Corruption THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53004;
    L_Error_Text := 'Self-referential validator corruption detected';
END_IF;

IF GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Lineage_Drift_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53005;
    L_Error_Text := 'Validator lineage drift detected';
END_IF;

IF GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Distributed_Validator_Reality_Fork_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53006;
    L_Error_Text := 'Distributed validator reality fork detected';
END_IF;

// Validator integrity validation.
IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Causality_Grounded THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53010;
    L_Error_Text := 'Validator causality invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Rule_Evolution_Governed THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53011;
    L_Error_Text := 'Governance rule evolution invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Distributed_Validation_Timeline_Monotonic THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53012;
    L_Error_Text := 'Distributed validation timeline monotonicity invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Interpretation_Equivalence_Valid THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 53013;
    L_Error_Text := 'Validator interpretation equivalence invalid';
END_IF;

IF L_Integrity_Valid THEN
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Valid := TRUE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Granted := TRUE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Quarantine_Active := FALSE;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Semantics_Immutable := TRUE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.CrossEpoch_Validation_Equivalence_Stable := TRUE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Distributed_Validator_Consensus_Valid := TRUE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Rule_Integrity_Canonical := TRUE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Validator_Lineage_Coherent := TRUE;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Epoch :=
        GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Epoch;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Epoch_Coherent := TRUE;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Last_Update_MS :=
        L_Now_MS;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Lease_Expired := FALSE;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Last_Error_Code := 0;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Last_Error_Text := '';
ELSE
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Valid := FALSE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Granted := FALSE;
    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Quarantine_Active := TRUE;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Lease_Expired := TRUE;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Last_Error_Code :=
        L_Error_Code;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Last_Error_Text :=
        L_Error_Text;

    GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Invalidation_Count :=
        GVL_GOVERNANCE_VALIDATOR_INTEGRITY_FABRIC.Governance_Validator_Integrity_Invalidation_Count + 1;
END_IF;

END_PROGRAM