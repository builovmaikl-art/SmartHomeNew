PROGRAM PRG_Semantic_Commit_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Commit_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Commit_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// SEMANTIC PUBLICATION COMMIT GOVERNOR
// ======================================================
// Governs semantic publication checkpoint coherence.
// Downstream/publication continuity only.
// Does not invalidate runtime barrier, PLC fencing,
// immutable snapshots, distributed commit or IO authority.
// ======================================================

GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Mismatch := FALSE;
GVL_SEMANTIC_COMMIT.Semantic_Commit_Mismatch := FALSE;
GVL_SEMANTIC_COMMIT.Semantic_Rollback_Detected := FALSE;
GVL_SEMANTIC_COMMIT.Semantic_Replay_Fenced := FALSE;
GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Missing := FALSE;
GVL_SEMANTIC_COMMIT.Semantic_Commit_Lease_Expired := FALSE;

// ------------------------------------------------------
// Semantic checkpoint epoch progression.
// ------------------------------------------------------

GVL_SEMANTIC_COMMIT.Local_Semantic_Checkpoint_Epoch :=
    GVL_SEMANTIC_COMMIT.Local_Semantic_Checkpoint_Epoch + 1;

GVL_SEMANTIC_COMMIT.Local_Semantic_Commit_Epoch :=
    GVL_SEMANTIC_COMMIT.Local_Semantic_Commit_Epoch + 1;

// ------------------------------------------------------
// Rollback/replay fencing foundation.
// ------------------------------------------------------

IF GVL_SEMANTIC_COMMIT.Peer_Semantic_Checkpoint_Epoch
< GVL_SEMANTIC_COMMIT.Local_Semantic_Checkpoint_Epoch THEN
    GVL_SEMANTIC_COMMIT.Semantic_Rollback_Detected := TRUE;
    GVL_SEMANTIC_COMMIT.Semantic_Replay_Fenced := TRUE;

    L_Commit_Valid := FALSE;
    L_Error_Code := 18000;
    L_Error_Text := 'Semantic rollback detected';
END_IF;

// ------------------------------------------------------
// Checkpoint acknowledgement foundation.
// ------------------------------------------------------

IF L_Commit_Valid THEN
    IF NOT GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Ack_Valid THEN
        GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Missing := TRUE;

        L_Commit_Valid := FALSE;
        L_Error_Code := 18001;
        L_Error_Text := 'Semantic checkpoint acknowledgement missing';
    END_IF;
END_IF;

// ------------------------------------------------------
// Semantic checkpoint mismatch foundation.
// ------------------------------------------------------

IF L_Commit_Valid THEN
    IF GVL_SEMANTIC_COMMIT.Peer_Semantic_Commit_Epoch
    <> GVL_SEMANTIC_COMMIT.Local_Semantic_Commit_Epoch THEN
        GVL_SEMANTIC_COMMIT.Semantic_Commit_Mismatch := TRUE;

        L_Commit_Valid := FALSE;
        L_Error_Code := 18002;
        L_Error_Text := 'Semantic commit mismatch detected';
    END_IF;
END_IF;

// ------------------------------------------------------
// Semantic commit lease freshness.
// ------------------------------------------------------

L_Delta_MS :=
    L_Now_MS - GVL_SEMANTIC_COMMIT.Semantic_Commit_Last_Refresh_MS;

IF L_Commit_Valid
AND GVL_SEMANTIC_COMMIT.Semantic_Commit_Lease_Active THEN
    IF L_Delta_MS > GVL_SEMANTIC_COMMIT.Semantic_Commit_Timeout_MS THEN
        GVL_SEMANTIC_COMMIT.Semantic_Commit_Lease_Expired := TRUE;

        L_Commit_Valid := FALSE;
        L_Error_Code := 18003;
        L_Error_Text := 'Semantic commit lease expired';
    END_IF;
END_IF;

// ------------------------------------------------------
// Publish semantic commit coherence foundation.
// ------------------------------------------------------

IF L_Commit_Valid THEN
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Epoch :=
        GVL_SEMANTIC_COMMIT.Semantic_Commit_Epoch + 1;

    GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Epoch :=
        GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Epoch + 1;

    GVL_SEMANTIC_COMMIT.Semantic_Publication_Commit_Epoch :=
        GVL_SEMANTIC_COMMIT.Semantic_Publication_Commit_Epoch + 1;

    GVL_SEMANTIC_COMMIT.Semantic_Commit_Valid := TRUE;
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Lease_Active := TRUE;
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Lease_Expired := FALSE;

    GVL_SEMANTIC_COMMIT.Semantic_Commit_Quarantine_Active := FALSE;
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Forced_Safe_Mode := FALSE;

    GVL_SEMANTIC_COMMIT.Semantic_Commit_Last_Refresh_MS := L_Now_MS;

    GVL_SEMANTIC_COMMIT.Semantic_Commit_Last_Error_Code := 0;
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Last_Error_Text := '';
ELSE
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Valid := FALSE;
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Quarantine_Active := TRUE;
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Forced_Safe_Mode := TRUE;

    GVL_SEMANTIC_COMMIT.Semantic_Commit_Last_Error_Code := L_Error_Code;
    GVL_SEMANTIC_COMMIT.Semantic_Commit_Last_Error_Text := L_Error_Text;

    GVL_SEMANTIC_COMMIT.Semantic_Commit_Invalidation_Count :=
        GVL_SEMANTIC_COMMIT.Semantic_Commit_Invalidation_Count + 1;
END_IF;
END_PROGRAM
