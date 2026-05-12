PROGRAM PRG_Distributed_Epoch_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Distributed_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Peer_Session_Active : BOOL := FALSE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Distributed_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// DISTRIBUTED EPOCH GOVERNOR
// ======================================================
// Governs peer epoch reconciliation foundation.
// Prevents distributed stale authority continuity.
//
// Current implementation mode:
// peer-optional foundation mode.
//
// Missing peer topology is NOT treated as divergence.
// Peer validation activates only after real peer
// synchronization state exists.
// ======================================================

GVL_DISTRIBUTED_EPOCH.Peer_Lease_Expired := FALSE;
GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Stale := FALSE;
GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Stale := FALSE;
GVL_DISTRIBUTED_EPOCH.Peer_Boot_Mismatch := FALSE;
GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Conflict := FALSE;
GVL_DISTRIBUTED_EPOCH.Peer_Semantic_Continuity_Lost := FALSE;

// ------------------------------------------------------
// Local authority projection.
// ------------------------------------------------------

GVL_DISTRIBUTED_EPOCH.Local_Runtime_Epoch := GVL_RUNTIME_EPOCH.Runtime_Epoch;
GVL_DISTRIBUTED_EPOCH.Local_Snapshot_Epoch := GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch;
GVL_DISTRIBUTED_EPOCH.Local_Boot_Generation := GVL_TIME_MONOTONIC.Boot_Generation_ID;
GVL_DISTRIBUTED_EPOCH.Local_Fencing_Token := GVL_PLC_FENCING.PLC_Fencing_Token;

// ------------------------------------------------------
// Peer session detection.
// ------------------------------------------------------
// Peer validation becomes authoritative only after
// real peer epoch continuity exists.
// ------------------------------------------------------

IF GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Epoch > 0 THEN
    L_Peer_Session_Active := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Epoch > 0 THEN
    L_Peer_Session_Active := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Boot_Generation > 0 THEN
    L_Peer_Session_Active := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Token > 0 THEN
    L_Peer_Session_Active := TRUE;
END_IF;

// ------------------------------------------------------
// Peer lease validation foundation.
// ------------------------------------------------------

IF L_Peer_Session_Active THEN
    L_Delta_MS := L_Now_MS - GVL_DISTRIBUTED_EPOCH.Peer_Last_Refresh_MS;

    IF GVL_DISTRIBUTED_EPOCH.Peer_Lease_Active THEN
        IF L_Delta_MS > GVL_DISTRIBUTED_EPOCH.Peer_Lease_Timeout_MS THEN
            GVL_DISTRIBUTED_EPOCH.Peer_Lease_Expired := TRUE;

            L_Distributed_Valid := FALSE;
            L_Error_Code := 13000;
            L_Error_Text := 'Peer lease expired';
        END_IF;
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer runtime continuity foundation.
// ------------------------------------------------------

IF L_Distributed_Valid AND L_Peer_Session_Active THEN
    IF GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Epoch < GVL_DISTRIBUTED_EPOCH.Local_Runtime_Epoch THEN
        GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Stale := TRUE;
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer snapshot continuity foundation.
// ------------------------------------------------------

IF L_Distributed_Valid AND L_Peer_Session_Active THEN
    IF GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Epoch < GVL_DISTRIBUTED_EPOCH.Local_Snapshot_Epoch THEN
        GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Stale := TRUE;
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer boot generation continuity foundation.
// ------------------------------------------------------

IF L_Distributed_Valid AND L_Peer_Session_Active THEN
    IF GVL_DISTRIBUTED_EPOCH.Peer_Boot_Generation <> GVL_DISTRIBUTED_EPOCH.Local_Boot_Generation THEN
        GVL_DISTRIBUTED_EPOCH.Peer_Boot_Mismatch := TRUE;
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer fencing continuity foundation.
// ------------------------------------------------------

IF L_Distributed_Valid AND L_Peer_Session_Active THEN
    IF GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Token = GVL_DISTRIBUTED_EPOCH.Local_Fencing_Token THEN
        GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Conflict := TRUE;

        L_Distributed_Valid := FALSE;
        L_Error_Code := 13001;
        L_Error_Text := 'Peer fencing conflict detected';
    END_IF;
END_IF;

// ------------------------------------------------------
// Distributed semantic continuity.
// ------------------------------------------------------

IF GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Stale
OR GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Stale
OR GVL_DISTRIBUTED_EPOCH.Peer_Boot_Mismatch
OR GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Conflict
THEN
    GVL_DISTRIBUTED_EPOCH.Peer_Semantic_Continuity_Lost := TRUE;
END_IF;

// ------------------------------------------------------
// Publish distributed epoch state.
// ------------------------------------------------------

IF L_Distributed_Valid THEN
    GVL_DISTRIBUTED_EPOCH.Distributed_Epoch := GVL_DISTRIBUTED_EPOCH.Distributed_Epoch + 1;
    GVL_DISTRIBUTED_EPOCH.Distributed_Reconciliation_Epoch := GVL_DISTRIBUTED_EPOCH.Distributed_Reconciliation_Epoch + 1;

    GVL_DISTRIBUTED_EPOCH.Distributed_Epoch_Consistent := TRUE;
    GVL_DISTRIBUTED_EPOCH.Distributed_Reconciliation_Valid := TRUE;
    GVL_DISTRIBUTED_EPOCH.Distributed_Publication_Allowed := TRUE;

    GVL_DISTRIBUTED_EPOCH.Distributed_Quarantine_Active := FALSE;
    GVL_DISTRIBUTED_EPOCH.Distributed_Forced_Safe_Mode := FALSE;

    GVL_DISTRIBUTED_EPOCH.Peer_Last_Reconciliation_MS := L_Now_MS;

    GVL_DISTRIBUTED_EPOCH.Distributed_Last_Error_Code := 0;
    GVL_DISTRIBUTED_EPOCH.Distributed_Last_Error_Text := '';
ELSE
    GVL_DISTRIBUTED_EPOCH.Distributed_Epoch_Consistent := FALSE;
    GVL_DISTRIBUTED_EPOCH.Distributed_Reconciliation_Valid := FALSE;
    GVL_DISTRIBUTED_EPOCH.Distributed_Publication_Allowed := FALSE;

    GVL_DISTRIBUTED_EPOCH.Distributed_Quarantine_Active := TRUE;
    GVL_DISTRIBUTED_EPOCH.Distributed_Forced_Safe_Mode := TRUE;

    GVL_DISTRIBUTED_EPOCH.Distributed_Last_Error_Code := L_Error_Code;
    GVL_DISTRIBUTED_EPOCH.Distributed_Last_Error_Text := L_Error_Text;

    GVL_DISTRIBUTED_EPOCH.Distributed_Invalidation_Count := GVL_DISTRIBUTED_EPOCH.Distributed_Invalidation_Count + 1;
END_IF;
END_PROGRAM
