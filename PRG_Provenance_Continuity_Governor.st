PROGRAM PRG_Provenance_Continuity_Governor
VAR
    L_Now_MS : UDINT;
    L_Continuity_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Continuity_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Valid := FALSE;
GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Granted := FALSE;
GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Quarantine_Active := TRUE;

GVL_PROVENANCE_CONTINUITY_FABRIC.Recovery_Provenance_Reattested := FALSE;
GVL_PROVENANCE_CONTINUITY_FABRIC.Authority_Resurrection_Authentic := FALSE;
GVL_PROVENANCE_CONTINUITY_FABRIC.Federation_Rejoin_Provenance_Valid := FALSE;
GVL_PROVENANCE_CONTINUITY_FABRIC.PostRecovery_TrustSeed_Coherent := FALSE;
GVL_PROVENANCE_CONTINUITY_FABRIC.CrossEpoch_Provenance_Continuity_Stable := FALSE;

// Authority provenance required.
IF NOT GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Granted THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47000;
    L_Error_Text := 'Authority provenance not granted';
END_IF;

// Post-recovery provenance bypass detectors.
IF GVL_PROVENANCE_CONTINUITY_FABRIC.Stale_Provenance_Resurrection_Detected THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47001;
    L_Error_Text := 'Stale provenance resurrection detected';
END_IF;

IF GVL_PROVENANCE_CONTINUITY_FABRIC.Recovered_Authority_Without_Reattestation_Detected THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47002;
    L_Error_Text := 'Recovered authority without re-attestation detected';
END_IF;

IF GVL_PROVENANCE_CONTINUITY_FABRIC.Federation_Rejoin_Without_Provenance_Detected THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47003;
    L_Error_Text := 'Federation rejoin without provenance detected';
END_IF;

IF GVL_PROVENANCE_CONTINUITY_FABRIC.CrossEpoch_Trust_Continuity_Broken THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47004;
    L_Error_Text := 'Cross-epoch trust continuity broken';
END_IF;

IF GVL_PROVENANCE_CONTINUITY_FABRIC.Recovery_Trust_Seed_Drift_Detected THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47005;
    L_Error_Text := 'Recovery trust-seed drift detected';
END_IF;

IF GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Resurrection_Bypass_Detected THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47006;
    L_Error_Text := 'Provenance resurrection bypass detected';
END_IF;

// Provenance continuity validation.
IF L_Continuity_Valid
AND NOT GVL_PROVENANCE_CONTINUITY_FABRIC.Recovery_Epoch_Authenticity_Valid THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47010;
    L_Error_Text := 'Recovery epoch authenticity invalid';
END_IF;

IF L_Continuity_Valid
AND NOT GVL_PROVENANCE_CONTINUITY_FABRIC.Distributed_Rejoin_Attestation_Coherent THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47011;
    L_Error_Text := 'Distributed rejoin attestation invalid';
END_IF;

IF L_Continuity_Valid
AND NOT GVL_PROVENANCE_CONTINUITY_FABRIC.Authority_Restoration_Provenance_Grounded THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47012;
    L_Error_Text := 'Authority restoration provenance invalid';
END_IF;

IF L_Continuity_Valid
AND NOT GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Lease_Continuity_Valid THEN
    L_Continuity_Valid := FALSE;
    L_Error_Code := 47013;
    L_Error_Text := 'Provenance lease continuity invalid';
END_IF;

IF L_Continuity_Valid THEN
    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Valid := TRUE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Granted := TRUE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Quarantine_Active := FALSE;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Recovery_Provenance_Reattested := TRUE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.Authority_Resurrection_Authentic := TRUE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.Federation_Rejoin_Provenance_Valid := TRUE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.PostRecovery_TrustSeed_Coherent := TRUE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.CrossEpoch_Provenance_Continuity_Stable := TRUE;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Epoch :=
        GVL_AUTHORITY_PROVENANCE_FABRIC.Authority_Provenance_Epoch;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Epoch_Coherent := TRUE;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Last_Update_MS :=
        L_Now_MS;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Lease_Expired := FALSE;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Last_Error_Code := 0;
    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Last_Error_Text := '';
ELSE
    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Valid := FALSE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Granted := FALSE;
    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Quarantine_Active := TRUE;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Lease_Expired := TRUE;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Last_Error_Code :=
        L_Error_Code;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Last_Error_Text :=
        L_Error_Text;

    GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Invalidation_Count :=
        GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Invalidation_Count + 1;
END_IF;

END_PROGRAM