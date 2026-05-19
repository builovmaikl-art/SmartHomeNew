PROGRAM PRG_Trust_Epoch_Monotonicity_Governor
VAR
    L_Now_MS : UDINT;
    L_Monotonicity_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Monotonicity_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// Fail-safe defaults.
GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Valid := FALSE;
GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Granted := FALSE;
GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Quarantine_Active := TRUE;

GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Global_Trust_Epoch_Monotonic := FALSE;
GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Rollback_Resistant_Authority_Valid := FALSE;
GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Recovery_Epoch_Strictly_Newer := FALSE;
GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Distributed_Trust_Vector_Coherent := FALSE;
GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Irreversible_Trust_Progression_Stable := FALSE;

// Provenance continuity required.
IF NOT GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Granted THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48000;
    L_Error_Text := 'Provenance continuity not granted';
END_IF;

// Temporal trust rollback detectors.
IF GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Temporal_Trust_Rollback_Detected THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48001;
    L_Error_Text := 'Temporal trust rollback detected';
END_IF;

IF GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Replay_Authority_Epoch_Detected THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48002;
    L_Error_Text := 'Replay authority epoch detected';
END_IF;

IF GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.CrossNode_Trust_Vector_Regression THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48003;
    L_Error_Text := 'Cross-node trust vector regression detected';
END_IF;

IF GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Stale_Federation_Epoch_Rejoin THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48004;
    L_Error_Text := 'Stale federation epoch rejoin detected';
END_IF;

IF GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Recovery_Timeline_Fork_Detected THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48005;
    L_Error_Text := 'Recovery timeline fork detected';
END_IF;

IF GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Revoked_Epoch_Resurrection_Detected THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48006;
    L_Error_Text := 'Revoked epoch resurrection detected';
END_IF;

// Monotonic trust validation.
IF L_Monotonicity_Valid
AND NOT GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.CrossNode_Trust_Epoch_Aligned THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48010;
    L_Error_Text := 'Cross-node trust epoch alignment invalid';
END_IF;

IF L_Monotonicity_Valid
AND NOT GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Recovery_Timeline_Dominance_Valid THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48011;
    L_Error_Text := 'Recovery timeline dominance invalid';
END_IF;

IF L_Monotonicity_Valid
AND NOT GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Federation_Epoch_Progression_Coherent THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48012;
    L_Error_Text := 'Federation epoch progression invalid';
END_IF;

IF L_Monotonicity_Valid
AND NOT GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Revocation_History_Monotonic THEN
    L_Monotonicity_Valid := FALSE;
    L_Error_Code := 48013;
    L_Error_Text := 'Trust revocation history monotonicity invalid';
END_IF;

IF L_Monotonicity_Valid THEN
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Valid := TRUE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Granted := TRUE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Quarantine_Active := FALSE;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Global_Trust_Epoch_Monotonic := TRUE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Rollback_Resistant_Authority_Valid := TRUE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Recovery_Epoch_Strictly_Newer := TRUE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Distributed_Trust_Vector_Coherent := TRUE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Irreversible_Trust_Progression_Stable := TRUE;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Epoch :=
        GVL_PROVENANCE_CONTINUITY_FABRIC.Provenance_Continuity_Epoch;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Epoch_Coherent := TRUE;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Last_Update_MS :=
        L_Now_MS;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Lease_Expired := FALSE;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Last_Error_Code := 0;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Last_Error_Text := '';
ELSE
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Valid := FALSE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Granted := FALSE;
    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Quarantine_Active := TRUE;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Lease_Expired := TRUE;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Last_Error_Code :=
        L_Error_Code;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Last_Error_Text :=
        L_Error_Text;

    GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Invalidation_Count :=
        GVL_TRUST_EPOCH_MONOTONICITY_FABRIC.Trust_Epoch_Monotonicity_Invalidation_Count + 1;
END_IF;

END_PROGRAM