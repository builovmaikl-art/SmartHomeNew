PROGRAM PRG_Distributed_Snapshot_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Distributed_Snapshot_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Distributed_Snapshot_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// DISTRIBUTED IMMUTABLE SNAPSHOT GOVERNOR
// ======================================================
// Governs immutable peer publication snapshot exchange.
// Publication-authoritative only.
// Does not invalidate runtime barrier, PLC fencing
// or local immutable snapshot freeze.
// ======================================================

GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Stale := FALSE;
GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Not_Immutable := FALSE;
GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Divergence := FALSE;
GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Reconciliation_Lost := FALSE;
GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Lease_Expired := FALSE;

// ------------------------------------------------------
// Local immutable publication projection.
// ------------------------------------------------------

GVL_DISTRIBUTED_SNAPSHOT.Local_Distributed_Snapshot_Epoch := GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Epoch;
GVL_DISTRIBUTED_SNAPSHOT.Local_Runtime_Snapshot_Epoch := GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch;
GVL_DISTRIBUTED_SNAPSHOT.Local_Publication_Epoch := GVL_OUTPUT_EPOCH.Output_Publication_Epoch;

// ------------------------------------------------------
// Local immutable publication freeze semantics.
// ------------------------------------------------------

IF GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen
AND GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed
AND GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid
AND GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid
THEN
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Frozen := TRUE;
ELSE
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Frozen := FALSE;

    L_Distributed_Snapshot_Valid := FALSE;
    L_Error_Code := 14000;
    L_Error_Text := 'Local immutable snapshot not frozen';
END_IF;

// ------------------------------------------------------
// Peer snapshot lease validation.
// ------------------------------------------------------

L_Delta_MS := L_Now_MS - GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Last_Refresh_MS;

IF L_Distributed_Snapshot_Valid
AND GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Lease_Active
THEN
    IF L_Delta_MS > GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Lease_Timeout_MS THEN
        GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Lease_Expired := TRUE;

        L_Distributed_Snapshot_Valid := FALSE;
        L_Error_Code := 14001;
        L_Error_Text := 'Peer snapshot lease expired';
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer immutable snapshot semantics.
// ------------------------------------------------------

IF L_Distributed_Snapshot_Valid THEN
    IF NOT GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Immutable THEN
        GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Not_Immutable := TRUE;

        L_Distributed_Snapshot_Valid := FALSE;
        L_Error_Code := 14002;
        L_Error_Text := 'Peer snapshot not immutable';
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer publication continuity.
// ------------------------------------------------------

IF L_Distributed_Snapshot_Valid THEN
    IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Epoch > 0 THEN
        IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Epoch < GVL_DISTRIBUTED_SNAPSHOT.Local_Publication_Epoch THEN
            GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Stale := TRUE;
        END_IF;
    END_IF;
END_IF;

// ------------------------------------------------------
// Peer publication reconciliation continuity.
// ------------------------------------------------------

IF L_Distributed_Snapshot_Valid THEN
    IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Runtime_Snapshot_Epoch > 0 THEN
        IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Runtime_Snapshot_Epoch <> GVL_DISTRIBUTED_SNAPSHOT.Local_Runtime_Snapshot_Epoch THEN
            GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Divergence := TRUE;
        END_IF;
    END_IF;
END_IF;

IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Stale
OR GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Divergence
OR GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Not_Immutable
THEN
    GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Reconciliation_Lost := TRUE;
END_IF;

// ------------------------------------------------------
// Publish authoritative distributed snapshot state.
// ------------------------------------------------------

IF L_Distributed_Snapshot_Valid THEN
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Epoch := GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Epoch + 1;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Reconciliation_Epoch := GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Reconciliation_Epoch + 1;

    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled := TRUE;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid := TRUE;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent := TRUE;

    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Quarantine_Active := FALSE;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Forced_Safe_Mode := FALSE;

    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Last_Error_Code := 0;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Last_Error_Text := '';
ELSE
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled := FALSE;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid := FALSE;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent := FALSE;

    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Quarantine_Active := TRUE;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Forced_Safe_Mode := TRUE;

    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Last_Error_Code := L_Error_Code;
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Last_Error_Text := L_Error_Text;

    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Invalidation_Count := GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Invalidation_Count + 1;
END_IF;
END_PROGRAM
