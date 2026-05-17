PROGRAM PRG_Governance_Publication_Binding_Governor
VAR
    L_Now_MS : UDINT;
    L_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Valid := FALSE;
GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Granted := FALSE;
GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Quarantine_Active := TRUE;

GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Observability_Publication_Causality_Valid := FALSE;
GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Upstream_Governance_Lease_Fresh := FALSE;
GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Epoch_Coherent := FALSE;
GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Publication_Quarantine_Propagation_Valid := FALSE;
GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Canonical_Observability_Reality_Consistent := FALSE;

// Governance liveness integrity required.
IF NOT GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Granted THEN
    L_Valid := FALSE;
    L_Error_Code := 55000;
    L_Error_Text := 'Governance liveness integrity not granted';
END_IF;

// Publication binding detectors.
IF GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Stale_Valid_Publication_Detected THEN
    L_Valid := FALSE;
    L_Error_Code := 55001;
    L_Error_Text := 'Stale valid publication detected';
END_IF;

IF GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.LeaseExpired_Governance_Published_As_Healthy THEN
    L_Valid := FALSE;
    L_Error_Code := 55002;
    L_Error_Text := 'Lease-expired governance published as healthy';
END_IF;

IF GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Quarantine_State_Publication_Bypass THEN
    L_Valid := FALSE;
    L_Error_Code := 55003;
    L_Error_Text := 'Quarantine state publication bypass';
END_IF;

IF GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Invalidation_Hidden_From_Observability THEN
    L_Valid := FALSE;
    L_Error_Code := 55004;
    L_Error_Text := 'Governance invalidation hidden from observability';
END_IF;

IF GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Distributed_Publication_State_Fork_Detected THEN
    L_Valid := FALSE;
    L_Error_Code := 55005;
    L_Error_Text := 'Distributed publication state fork detected';
END_IF;

IF GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Historical_Invalidation_Causality_Lost THEN
    L_Valid := FALSE;
    L_Error_Code := 55006;
    L_Error_Text := 'Historical invalidation causality lost';
END_IF;

// Publication validation.
IF L_Valid
AND NOT GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Diagnostics_Publication_Consistency_Valid THEN
    L_Valid := FALSE;
    L_Error_Code := 55010;
    L_Error_Text := 'Diagnostics publication consistency invalid';
END_IF;

IF L_Valid
AND NOT GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.HMI_Publication_State_Aligned THEN
    L_Valid := FALSE;
    L_Error_Code := 55011;
    L_Error_Text := 'HMI publication state alignment invalid';
END_IF;

IF L_Valid
AND NOT GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Blackbox_Invalidation_Lineage_Valid THEN
    L_Valid := FALSE;
    L_Error_Code := 55012;
    L_Error_Text := 'Blackbox invalidation lineage invalid';
END_IF;

IF L_Valid
AND NOT GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Distributed_Publication_Consensus_Valid THEN
    L_Valid := FALSE;
    L_Error_Code := 55013;
    L_Error_Text := 'Distributed publication consensus invalid';
END_IF;

IF L_Valid THEN
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Valid := TRUE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Granted := TRUE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Quarantine_Active := FALSE;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Observability_Publication_Causality_Valid := TRUE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Upstream_Governance_Lease_Fresh := TRUE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Epoch_Coherent := TRUE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Publication_Quarantine_Propagation_Valid := TRUE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Canonical_Observability_Reality_Consistent := TRUE;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Epoch :=
        GVL_GOVERNANCE_LIVENESS_INTEGRITY_FABRIC.Governance_Liveness_Integrity_Epoch;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Epoch_Coherent_Runtime := TRUE;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Last_Update_MS :=
        L_Now_MS;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Lease_Expired := FALSE;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Last_Error_Code := 0;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Last_Error_Text := '';
ELSE
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Valid := FALSE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Granted := FALSE;
    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Quarantine_Active := TRUE;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Lease_Expired := TRUE;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Last_Error_Code :=
        L_Error_Code;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Last_Error_Text :=
        L_Error_Text;

    GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Invalidation_Count :=
        GVL_GOVERNANCE_PUBLICATION_BINDING_FABRIC.Governance_Publication_Binding_Invalidation_Count + 1;
END_IF;

END_PROGRAM