PROGRAM PRG_Distributed_Commit_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Commit_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Peer_Session_Active : BOOL := FALSE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Commit_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// DISTRIBUTED PUBLICATION COMMIT GOVERNOR
// ======================================================
// Governs deterministic peer publication commit continuity.
// Publication-authoritative only.
// Does not invalidate runtime barrier,
// PLC fencing or immutable snapshot authority.
//
// Current implementation mode:
// peer-optional foundation mode.
//
// Missing peer topology is NOT treated as divergence.
// Peer validation activates only after real peer
// synchronization state exists.
// ======================================================

GVL_DISTRIBUTED_COMMIT.Peer_Commit_Ack_Expired := FALSE;
GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch := FALSE;
GVL_DISTRIBUTED_COMMIT.Peer_Commit_Replay_Detected := FALSE;
GVL_DISTRIBUTED_COMMIT.Peer_Commit_Missing := FALSE;
GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired := FALSE;

// ------------------------------------------------------
// Local publication projection.
// ------------------------------------------------------

GVL_DISTRIBUTED_COMMIT.Local_Publication_Commit_Epoch := GVL_OUTPUT_EPOCH.Output_Publication_Epoch;
GVL_DISTRIBUTED_COMMIT.Local_Prepare_Epoch := GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Epoch;

// ------------------------------------------------------
// Immutable publication preparation validation.
// ------------------------------------------------------

IF GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled
AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid
AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent
THEN
    GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Active := TRUE;
    GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Valid := TRUE;
ELSE
    GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Active := FALSE;
    GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Valid := FALSE;

    L_Commit_Valid := FALSE;
    L_Error_Code := 15000;
    L_Error_Text := 'Distributed immutable publication prepare invalid';
END_IF;

// ------------------------------------------------------
// Peer session detection.
// ------------------------------------------------------
// Peer synchronization becomes authoritative only after
// real peer epochs or acknowledgements exist.
// ------------------------------------------------------

IF GVL_DISTRIBUTED_COMMIT.Peer_Publication_Commit_Epoch > 0 THEN
    L_Peer_Session_Active := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Prepare_Epoch > 0 THEN
    L_Peer_Session_Active := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Ack_Valid THEN
    L_Peer_Session_Active := TRUE;
END_IF;

// ------------------------------------------------------
// Commit lease freshness validation.
// ------------------------------------------------------
// Lease validation is peer-authoritative only after
// peer session establishment.
// ------------------------------------------------------

IF L_Commit_Valid AND L_Peer_Session_Active THEN
    L_Delta_MS := L_Now_MS - GVL_DISTRIBUTED_COMMIT.Peer_Commit_Last_Refresh_MS;

    IF GVL_DISTRIBUTED_COMMIT.Commit_Lease_Active THEN
        IF L_Delta_MS > GVL_DISTRIBUTED_COMMIT.Commit_Timeout_MS THEN
            GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired := TRUE;

            L_Commit_Valid := FALSE;
            L_Error_Code := 15001;
            L_Error_Text := 'Distributed commit lease expired';
        END_IF;
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer commit acknowledgement validation.
// ------------------------------------------------------
// Missing peer acknowledgement is not treated as
// divergence until peer session exists.
// ------------------------------------------------------

IF L_Commit_Valid AND L_Peer_Session_Active THEN
    IF NOT GVL_DISTRIBUTED_COMMIT.Peer_Commit_Ack_Valid THEN
        GVL_DISTRIBUTED_COMMIT.Peer_Commit_Missing := TRUE;

        L_Commit_Valid := FALSE;
        L_Error_Code := 15002;
        L_Error_Text := 'Peer commit acknowledgement missing';
    END_IF;
END_IF;

// ------------------------------------------------------
// Deterministic commit epoch continuity.
// ------------------------------------------------------

IF L_Commit_Valid AND L_Peer_Session_Active THEN
    IF GVL_DISTRIBUTED_COMMIT.Peer_Publication_Commit_Epoch < GVL_DISTRIBUTED_COMMIT.Local_Publication_Commit_Epoch THEN
        GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch := TRUE;

        L_Commit_Valid := FALSE;
        L_Error_Code := 15003;
        L_Error_Text := 'Peer commit epoch mismatch';
    END_IF;
END_IF;

// ------------------------------------------------------
// Replay protection foundation.
// ------------------------------------------------------

IF L_Commit_Valid AND L_Peer_Session_Active THEN
    IF GVL_DISTRIBUTED_COMMIT.Peer_Prepare_Epoch < GVL_DISTRIBUTED_COMMIT.Local_Prepare_Epoch THEN
        GVL_DISTRIBUTED_COMMIT.Peer_Commit_Replay_Detected := TRUE;

        L_Commit_Valid := FALSE;
        L_Error_Code := 15004;
        L_Error_Text := 'Peer commit replay detected';
    END_IF;
END_IF;

// ------------------------------------------------------
// Publish deterministic distributed commit state.
// ------------------------------------------------------

IF L_Commit_Valid THEN
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Epoch := GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Epoch + 1;
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Reconciliation_Epoch := GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Reconciliation_Epoch + 1;

    GVL_DISTRIBUTED_COMMIT.Publication_Commit_Requested := TRUE;

    IF L_Peer_Session_Active THEN
        GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed := TRUE;
        GVL_DISTRIBUTED_COMMIT.Commit_Lease_Active := TRUE;
    ELSE
        GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed := FALSE;
        GVL_DISTRIBUTED_COMMIT.Commit_Lease_Active := FALSE;
    END_IF;

    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid := TRUE;
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active := FALSE;
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Forced_Safe_Mode := FALSE;

    GVL_DISTRIBUTED_COMMIT.Commit_Last_Reconciliation_MS := L_Now_MS;

    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Last_Error_Code := 0;
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Last_Error_Text := '';
ELSE
    GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed := FALSE;

    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid := FALSE;
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active := TRUE;
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Forced_Safe_Mode := TRUE;

    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Last_Error_Code := L_Error_Code;
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Last_Error_Text := L_Error_Text;

    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Invalidation_Count := GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Invalidation_Count + 1;
END_IF;
END_PROGRAM
