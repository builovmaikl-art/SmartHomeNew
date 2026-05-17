PROGRAM PRG_Compliance_Federation_Governor
VAR
    L_Now_MS : UDINT;
    L_Compliance_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Compliance_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Valid := FALSE;
GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Granted := FALSE;
GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Quarantine_Active := TRUE;

GVL_COMPLIANCE_FEDERATION_FABRIC.Regulatory_Semantics_Coherent := FALSE;
GVL_COMPLIANCE_FEDERATION_FABRIC.Certification_Boundary_Valid := FALSE;
GVL_COMPLIANCE_FEDERATION_FABRIC.Regional_Safety_Envelope_Aligned := FALSE;
GVL_COMPLIANCE_FEDERATION_FABRIC.Governance_Trust_Boundary_Stable := FALSE;
GVL_COMPLIANCE_FEDERATION_FABRIC.Policy_Compliance_Coherent := FALSE;

// Semantic federation required.
IF NOT GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Granted THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42000;
    L_Error_Text := 'Semantic federation authority not granted';
END_IF;

// Regulatory semantic split-brain detectors.
IF GVL_COMPLIANCE_FEDERATION_FABRIC.CrossJurisdiction_Semantic_Drift_Detected THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42001;
    L_Error_Text := 'Cross-jurisdiction semantic drift detected';
END_IF;

IF GVL_COMPLIANCE_FEDERATION_FABRIC.Certification_Boundary_Violation_Detected THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42002;
    L_Error_Text := 'Certification boundary violation detected';
END_IF;

IF GVL_COMPLIANCE_FEDERATION_FABRIC.Policy_Compliance_Divergence_Detected THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42003;
    L_Error_Text := 'Policy compliance divergence detected';
END_IF;

IF GVL_COMPLIANCE_FEDERATION_FABRIC.Regional_Safety_Envelope_Mismatch_Detected THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42004;
    L_Error_Text := 'Regional safety envelope mismatch detected';
END_IF;

IF GVL_COMPLIANCE_FEDERATION_FABRIC.Regulatory_Trust_Corruption_Detected THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42005;
    L_Error_Text := 'Regulatory trust corruption detected';
END_IF;

IF GVL_COMPLIANCE_FEDERATION_FABRIC.Governance_Authority_Leakage_Detected THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42006;
    L_Error_Text := 'Governance authority leakage detected';
END_IF;

// Compliance federation validation.
IF L_Compliance_Valid
AND NOT GVL_COMPLIANCE_FEDERATION_FABRIC.CrossJurisdiction_Authority_Aligned THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42010;
    L_Error_Text := 'Cross-jurisdiction authority alignment invalid';
END_IF;

IF L_Compliance_Valid
AND NOT GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Runtime_Projection_Stable THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42011;
    L_Error_Text := 'Compliance runtime projection unstable';
END_IF;

IF L_Compliance_Valid
AND NOT GVL_COMPLIANCE_FEDERATION_FABRIC.External_Governance_Interpretation_Valid THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42012;
    L_Error_Text := 'External governance interpretation invalid';
END_IF;

IF L_Compliance_Valid
AND NOT GVL_COMPLIANCE_FEDERATION_FABRIC.Certified_Operational_Semantics_Valid THEN
    L_Compliance_Valid := FALSE;
    L_Error_Code := 42013;
    L_Error_Text := 'Certified operational semantics invalid';
END_IF;

IF L_Compliance_Valid THEN
    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Valid := TRUE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Granted := TRUE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Quarantine_Active := FALSE;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Regulatory_Semantics_Coherent := TRUE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Certification_Boundary_Valid := TRUE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Regional_Safety_Envelope_Aligned := TRUE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Governance_Trust_Boundary_Stable := TRUE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Policy_Compliance_Coherent := TRUE;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Epoch :=
        GVL_SEMANTIC_FEDERATION_FABRIC.Semantic_Federation_Epoch;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Epoch_Coherent := TRUE;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Last_Update_MS :=
        L_Now_MS;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Lease_Expired := FALSE;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Last_Error_Code := 0;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Last_Error_Text := '';
ELSE
    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Valid := FALSE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Granted := FALSE;
    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Quarantine_Active := TRUE;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Lease_Expired := TRUE;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Last_Error_Code :=
        L_Error_Code;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Last_Error_Text :=
        L_Error_Text;

    GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Invalidation_Count :=
        GVL_COMPLIANCE_FEDERATION_FABRIC.Compliance_Federation_Invalidation_Count + 1;
END_IF;

END_PROGRAM