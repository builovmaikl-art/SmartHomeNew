PROGRAM PRG_Governance_Feedback_Integrity_Governor
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
GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Valid := FALSE;
GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Granted := FALSE;
GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Quarantine_Active := TRUE;

GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Execution_Feedback_Causality_Isolated := FALSE;
GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Derivation_Inputs_Canonical := FALSE;
GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Telemetry_To_Authority_Lineage_Valid := FALSE;
GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Feedback_Epoch_Integrity_Stable := FALSE;
GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Lineage_Coherent := FALSE;

// Execution projection integrity required.
IF NOT GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Granted THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52000;
    L_Error_Text := 'Execution projection integrity not granted';
END_IF;

// Governance feedback poisoning detectors.
IF GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Poisoning_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52001;
    L_Error_Text := 'Governance feedback poisoning detected';
END_IF;

IF GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Execution_Telemetry_Authority_Corruption THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52002;
    L_Error_Text := 'Execution telemetry authority corruption detected';
END_IF;

IF GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.CrossEpoch_Feedback_Lineage_Drift THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52003;
    L_Error_Text := 'Cross-epoch feedback lineage drift detected';
END_IF;

IF GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Retroactive_Governance_Mutation_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52004;
    L_Error_Text := 'Retroactive governance mutation detected';
END_IF;

IF GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Distributed_Feedback_Fork_Detected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52005;
    L_Error_Text := 'Distributed feedback fork detected';
END_IF;

IF GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Untrusted_Execution_Observation_Injected THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52006;
    L_Error_Text := 'Untrusted execution observation injected';
END_IF;

// Governance feedback validation.
IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Authenticated_Execution_Observation_Valid THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52010;
    L_Error_Text := 'Authenticated execution observation invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.CrossEpoch_Feedback_Continuity_Stable THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52011;
    L_Error_Text := 'Cross-epoch feedback continuity invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Input_Causality_Grounded THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52012;
    L_Error_Text := 'Governance input causality invalid';
END_IF;

IF L_Integrity_Valid
AND NOT GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Distributed_Feedback_Consensus_Valid THEN
    L_Integrity_Valid := FALSE;
    L_Error_Code := 52013;
    L_Error_Text := 'Distributed feedback consensus invalid';
END_IF;

IF L_Integrity_Valid THEN
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Valid := TRUE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Granted := TRUE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Quarantine_Active := FALSE;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Execution_Feedback_Causality_Isolated := TRUE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Derivation_Inputs_Canonical := TRUE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Telemetry_To_Authority_Lineage_Valid := TRUE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Feedback_Epoch_Integrity_Stable := TRUE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Lineage_Coherent := TRUE;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Epoch :=
        GVL_EXECUTION_PROJECTION_INTEGRITY_FABRIC.Execution_Projection_Integrity_Epoch;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Epoch_Coherent := TRUE;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Last_Update_MS :=
        L_Now_MS;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Lease_Expired := FALSE;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Last_Error_Code := 0;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Last_Error_Text := '';
ELSE
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Valid := FALSE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Granted := FALSE;
    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Quarantine_Active := TRUE;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Lease_Expired := TRUE;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Last_Error_Code :=
        L_Error_Code;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Last_Error_Text :=
        L_Error_Text;

    GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Invalidation_Count :=
        GVL_GOVERNANCE_FEEDBACK_INTEGRITY_FABRIC.Governance_Feedback_Integrity_Invalidation_Count + 1;
END_IF;

END_PROGRAM