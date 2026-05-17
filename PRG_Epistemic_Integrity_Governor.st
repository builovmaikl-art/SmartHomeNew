PROGRAM PRG_Epistemic_Integrity_Governor
VAR
    L_Now_MS : UDINT;
    L_Epistemic_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Epistemic_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Valid := FALSE;
GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Granted := FALSE;
GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Quarantine_Active := TRUE;

GVL_EPISTEMIC_INTEGRITY_FABRIC.Physical_Reality_Model_Coherent := FALSE;
GVL_EPISTEMIC_INTEGRITY_FABRIC.Sensor_Truth_Consensus_Valid := FALSE;
GVL_EPISTEMIC_INTEGRITY_FABRIC.Telemetry_Reality_Alignment_Stable := FALSE;
GVL_EPISTEMIC_INTEGRITY_FABRIC.Distributed_Reality_Model_Consistent := FALSE;
GVL_EPISTEMIC_INTEGRITY_FABRIC.Causal_Model_Physically_Valid := FALSE;

// Forensic evidence required.
IF NOT GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Granted THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44000;
    L_Error_Text := 'Forensic evidence authority not granted';
END_IF;

// Epistemic split-brain detectors.
IF GVL_EPISTEMIC_INTEGRITY_FABRIC.Physically_False_Consensus_Detected THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44001;
    L_Error_Text := 'Physically false consensus detected';
END_IF;

IF GVL_EPISTEMIC_INTEGRITY_FABRIC.Telemetry_Corruption_Coherent_Detected THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44002;
    L_Error_Text := 'Telemetry corruption coherence detected';
END_IF;

IF GVL_EPISTEMIC_INTEGRITY_FABRIC.Historical_Reality_Divergence_Detected THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44003;
    L_Error_Text := 'Historical reality divergence detected';
END_IF;

IF GVL_EPISTEMIC_INTEGRITY_FABRIC.Sensor_Trust_Erosion_Detected THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44004;
    L_Error_Text := 'Sensor trust erosion detected';
END_IF;

IF GVL_EPISTEMIC_INTEGRITY_FABRIC.Causal_Model_Poisoning_Detected THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44005;
    L_Error_Text := 'Causal model poisoning detected';
END_IF;

IF GVL_EPISTEMIC_INTEGRITY_FABRIC.LongTerm_Epistemic_Drift_Detected THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44006;
    L_Error_Text := 'Long-term epistemic drift detected';
END_IF;

// Physical reality anchoring validation.
IF L_Epistemic_Valid
AND NOT GVL_EPISTEMIC_INTEGRITY_FABRIC.Historical_Reality_Anchoring_Valid THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44010;
    L_Error_Text := 'Historical reality anchoring invalid';
END_IF;

IF L_Epistemic_Valid
AND NOT GVL_EPISTEMIC_INTEGRITY_FABRIC.Physical_Truth_Lineage_Coherent THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44011;
    L_Error_Text := 'Physical truth lineage coherence invalid';
END_IF;

IF L_Epistemic_Valid
AND NOT GVL_EPISTEMIC_INTEGRITY_FABRIC.Reality_Model_Drift_Bounded THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44012;
    L_Error_Text := 'Reality model drift bounds invalid';
END_IF;

IF L_Epistemic_Valid
AND NOT GVL_EPISTEMIC_INTEGRITY_FABRIC.Semantic_To_Physical_Causality_Valid THEN
    L_Epistemic_Valid := FALSE;
    L_Error_Code := 44013;
    L_Error_Text := 'Semantic-to-physical causality invalid';
END_IF;

IF L_Epistemic_Valid THEN
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Valid := TRUE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Granted := TRUE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Quarantine_Active := FALSE;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Physical_Reality_Model_Coherent := TRUE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Sensor_Truth_Consensus_Valid := TRUE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Telemetry_Reality_Alignment_Stable := TRUE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Distributed_Reality_Model_Consistent := TRUE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Causal_Model_Physically_Valid := TRUE;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Epoch :=
        GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Epoch;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Epoch_Coherent := TRUE;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Last_Update_MS :=
        L_Now_MS;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Lease_Expired := FALSE;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Last_Error_Code := 0;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Last_Error_Text := '';
ELSE
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Valid := FALSE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Granted := FALSE;
    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Quarantine_Active := TRUE;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Lease_Expired := TRUE;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Last_Error_Code :=
        L_Error_Code;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Last_Error_Text :=
        L_Error_Text;

    GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Invalidation_Count :=
        GVL_EPISTEMIC_INTEGRITY_FABRIC.Epistemic_Integrity_Invalidation_Count + 1;
END_IF;

END_PROGRAM