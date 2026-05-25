PROGRAM PRG_Forensic_Evidence_Governor
VAR
    L_Now_MS : UDINT;
    L_Forensic_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Forensic_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Valid := FALSE;
GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Granted := FALSE;
GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Quarantine_Active := TRUE;

GVL_FORENSIC_EVIDENCE_FABRIC.Authority_Lineage_Reconstructable := FALSE;
GVL_FORENSIC_EVIDENCE_FABRIC.Decision_Causality_Traceable := FALSE;
GVL_FORENSIC_EVIDENCE_FABRIC.Distributed_Evidence_Coherent := FALSE;
GVL_FORENSIC_EVIDENCE_FABRIC.Immutable_Audit_Continuity_Valid := FALSE;
GVL_FORENSIC_EVIDENCE_FABRIC.Recovery_Lineage_Preserved := FALSE;

// Compliance federation required.
IF NOT GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Granted THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43000;
    L_Error_Text := 'Compliance federation authority not granted';
END_IF;

// Forensic split-brain detectors.
IF GVL_FORENSIC_EVIDENCE_FABRIC.Authority_Lineage_Gap_Detected THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43001;
    L_Error_Text := 'Authority lineage gap detected';
END_IF;

IF GVL_FORENSIC_EVIDENCE_FABRIC.NonReconstructable_Decision_Detected THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43002;
    L_Error_Text := 'Non-reconstructable decision detected';
END_IF;

IF GVL_FORENSIC_EVIDENCE_FABRIC.History_Evidence_Divergence_Detected THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43003;
    L_Error_Text := 'History evidence divergence detected';
END_IF;

IF GVL_FORENSIC_EVIDENCE_FABRIC.Causal_Chain_Erosion_Detected THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43004;
    L_Error_Text := 'Causal chain erosion detected';
END_IF;

IF GVL_FORENSIC_EVIDENCE_FABRIC.Distributed_Forensic_Inconsistency_Detected THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43005;
    L_Error_Text := 'Distributed forensic inconsistency detected';
END_IF;

IF GVL_FORENSIC_EVIDENCE_FABRIC.Immutable_Audit_Discontinuity_Detected THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43006;
    L_Error_Text := 'Immutable audit discontinuity detected';
END_IF;

// Forensic reconstruction validation.
IF L_Forensic_Valid
AND NOT GVL_FORENSIC_EVIDENCE_FABRIC.Historical_Proof_Chain_Valid THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43010;
    L_Error_Text := 'Historical proof chain invalid';
END_IF;

IF L_Forensic_Valid
AND NOT GVL_FORENSIC_EVIDENCE_FABRIC.Governance_Event_Lineage_Coherent THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43011;
    L_Error_Text := 'Governance event lineage coherence invalid';
END_IF;

IF L_Forensic_Valid
AND NOT GVL_FORENSIC_EVIDENCE_FABRIC.Semantic_Transition_Traceable THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43012;
    L_Error_Text := 'Semantic transition traceability invalid';
END_IF;

IF L_Forensic_Valid
AND NOT GVL_FORENSIC_EVIDENCE_FABRIC.Physical_Transition_Traceable THEN
    L_Forensic_Valid := FALSE;
    L_Error_Code := 43013;
    L_Error_Text := 'Physical transition traceability invalid';
END_IF;

IF L_Forensic_Valid THEN
    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Valid := TRUE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Granted := TRUE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Quarantine_Active := FALSE;

    GVL_FORENSIC_EVIDENCE_FABRIC.Authority_Lineage_Reconstructable := TRUE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Decision_Causality_Traceable := TRUE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Distributed_Evidence_Coherent := TRUE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Immutable_Audit_Continuity_Valid := TRUE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Recovery_Lineage_Preserved := TRUE;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Epoch :=
        GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Epoch;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Epoch_Coherent := TRUE;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Last_Update_MS :=
        L_Now_MS;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Lease_Expired := FALSE;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Last_Error_Code := 0;
    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Last_Error_Text := '';
ELSE
    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Valid := FALSE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Granted := FALSE;
    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Quarantine_Active := TRUE;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Lease_Expired := TRUE;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Last_Error_Code :=
        L_Error_Code;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Last_Error_Text :=
        L_Error_Text;

    GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Invalidation_Count :=
        GVL_FORENSIC_EVIDENCE_FABRIC.Forensic_Evidence_Invalidation_Count + 1;
END_IF;

END_PROGRAM