PROGRAM PRG_Authority_Provenance_Governor
VAR
    L_Now_MS : UDINT;
    L_Provenance_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Provenance_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Valid := FALSE;
GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Granted := FALSE;
GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Quarantine_Active := TRUE;

GVL_AUTHORITY_PROVENANCE_FABRIC.Bootstrap_Authority_Authentic := FALSE;
GVL_AUTHORITY_PROVENANCE_FABRIC.Commissioning_Lineage_Traceable := FALSE;
GVL_AUTHORITY_PROVENANCE_FABRIC.Trust_Seed_Integrity_Valid := FALSE;
GVL_AUTHORITY_PROVENANCE_FABRIC.Root_Authority_Attribution_Coherent := FALSE;
GVL_AUTHORITY_PROVENANCE_FABRIC.Provenance_Causality_Grounded := FALSE;

// Meta-governance required.
IF NOT GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Granted THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46000;
    L_Error_Text := 'Meta-governance authority not granted';
END_IF;

// Authority-origin split-brain detectors.
IF GVL_AUTHORITY_PROVENANCE_FABRIC.Bootstrap_Identity_Corruption_Detected THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46001;
    L_Error_Text := 'Bootstrap identity corruption detected';
END_IF;

IF GVL_AUTHORITY_PROVENANCE_FABRIC.Forged_Authority_Root_Detected THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46002;
    L_Error_Text := 'Forged authority root detected';
END_IF;

IF GVL_AUTHORITY_PROVENANCE_FABRIC.Commissioning_Provenance_Gap_Detected THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46003;
    L_Error_Text := 'Commissioning provenance gap detected';
END_IF;

IF GVL_AUTHORITY_PROVENANCE_FABRIC.Trust_Seed_Impersonation_Detected THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46004;
    L_Error_Text := 'Trust seed impersonation detected';
END_IF;

IF GVL_AUTHORITY_PROVENANCE_FABRIC.Origin_Authenticity_Erosion_Detected THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46005;
    L_Error_Text := 'Origin authenticity erosion detected';
END_IF;

IF GVL_AUTHORITY_PROVENANCE_FABRIC.Root_Lineage_Tampering_Detected THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46006;
    L_Error_Text := 'Root lineage tampering detected';
END_IF;

// Provenance integrity validation.
IF L_Provenance_Valid
AND NOT GVL_AUTHORITY_PROVENANCE_FABRIC.Historical_Origin_Lineage_Valid THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46010;
    L_Error_Text := 'Historical origin lineage invalid';
END_IF;

IF L_Provenance_Valid
AND NOT GVL_AUTHORITY_PROVENANCE_FABRIC.Distributed_Trust_Chain_Coherent THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46011;
    L_Error_Text := 'Distributed trust chain coherence invalid';
END_IF;

IF L_Provenance_Valid
AND NOT GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Origin_Continuity_Stable THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46012;
    L_Error_Text := 'Authority origin continuity invalid';
END_IF;

IF L_Provenance_Valid
AND NOT GVL_AUTHORITY_PROVENANCE_FABRIC.Root_Identity_Cryptographic_Validity THEN
    L_Provenance_Valid := FALSE;
    L_Error_Code := 46013;
    L_Error_Text := 'Root identity cryptographic validity invalid';
END_IF;

IF L_Provenance_Valid THEN
    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Valid := TRUE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Granted := TRUE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Quarantine_Active := FALSE;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Bootstrap_Authority_Authentic := TRUE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Commissioning_Lineage_Traceable := TRUE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Trust_Seed_Integrity_Valid := TRUE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Root_Authority_Attribution_Coherent := TRUE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Provenance_Causality_Grounded := TRUE;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Epoch :=
        GVL_META_GOVERNANCE_FABRIC.Meta_Governance_Epoch;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Epoch_Coherent := TRUE;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Last_Update_MS :=
        L_Now_MS;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Lease_Expired := FALSE;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Last_Error_Code := 0;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Last_Error_Text := '';
ELSE
    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Valid := FALSE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Granted := FALSE;
    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Quarantine_Active := TRUE;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Lease_Expired := TRUE;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Last_Error_Code :=
        L_Error_Code;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Last_Error_Text :=
        L_Error_Text;

    GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Invalidation_Count :=
        GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Invalidation_Count + 1;
END_IF;

END_PROGRAM