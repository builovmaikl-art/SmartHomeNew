PROGRAM PRG_Governance_Observer_Consensus_Governor
VAR
    L_Now_MS : UDINT;
    L_Consensus_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Consensus_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Valid := FALSE;
GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Granted := FALSE;
GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Quarantine_Active := TRUE;

GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Distributed_Governance_Projection_Consistent := FALSE;
GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Observer_Semantic_Consensus_Valid := FALSE;
GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.CrossNode_Authority_Interpretation_Aligned := FALSE;
GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Reality_Canonical := FALSE;
GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Observer_Projection_Lineage_Coherent := FALSE;

// Semantic epoch invariance required.
IF NOT GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Granted THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50000;
    L_Error_Text := 'Semantic epoch invariance not granted';
END_IF;

// Governance observer split-brain detectors.
IF GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Observer_Governance_Divergence_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50001;
    L_Error_Text := 'Observer governance divergence detected';
END_IF;

IF GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.CrossNode_Authority_Interpretation_Fork THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50002;
    L_Error_Text := 'Cross-node authority interpretation fork detected';
END_IF;

IF GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Semantic_Projection_Mismatch_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50003;
    L_Error_Text := 'Semantic projection mismatch detected';
END_IF;

IF GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Canonical_Governance_Reality_Lost THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50004;
    L_Error_Text := 'Canonical governance reality lost';
END_IF;

IF GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Observer_Projection_Lineage_Drift_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50005;
    L_Error_Text := 'Observer projection lineage drift detected';
END_IF;

IF GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Distributed_Governance_Reality_Fork_Detected THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50006;
    L_Error_Text := 'Distributed governance reality fork detected';
END_IF;

// Observer consensus validation.
IF L_Consensus_Valid
AND NOT GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Canonical_Projection_Vector_Stable THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50010;
    L_Error_Text := 'Canonical projection vector invalid';
END_IF;

IF L_Consensus_Valid
AND NOT GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Distributed_Interpretation_Equivalence_Valid THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50011;
    L_Error_Text := 'Distributed interpretation equivalence invalid';
END_IF;

IF L_Consensus_Valid
AND NOT GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Projection_Causality_Grounded THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50012;
    L_Error_Text := 'Governance projection causality invalid';
END_IF;

IF L_Consensus_Valid
AND NOT GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Observer_Timeline_Consensus_Monotonic THEN
    L_Consensus_Valid := FALSE;
    L_Error_Code := 50013;
    L_Error_Text := 'Observer timeline consensus monotonicity invalid';
END_IF;

IF L_Consensus_Valid THEN
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Valid := TRUE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Granted := TRUE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Quarantine_Active := FALSE;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Distributed_Governance_Projection_Consistent := TRUE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Observer_Semantic_Consensus_Valid := TRUE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.CrossNode_Authority_Interpretation_Aligned := TRUE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Reality_Canonical := TRUE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Observer_Projection_Lineage_Coherent := TRUE;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Epoch :=
        GVL_SEMANTIC_EPOCH_INVARIANCE_FABRIC.Semantic_Epoch_Invariance_Epoch;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Epoch_Coherent := TRUE;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Last_Update_MS :=
        L_Now_MS;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Lease_Expired := FALSE;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Last_Error_Code := 0;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Last_Error_Text := '';
ELSE
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Valid := FALSE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Granted := FALSE;
    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Quarantine_Active := TRUE;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Lease_Expired := TRUE;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Last_Error_Code :=
        L_Error_Code;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Last_Error_Text :=
        L_Error_Text;

    GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Invalidation_Count :=
        GVL_GOVERNANCE_OBSERVER_CONSENSUS_FABRIC.Governance_Observer_Consensus_Invalidation_Count + 1;
END_IF;

END_PROGRAM