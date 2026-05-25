PROGRAM PRG_Distributed_Snapshot_Ingestion
// ======================================================
// DISTRIBUTED SNAPSHOT INGESTION
// ======================================================
// Canonical replicated distributed snapshot ingestion.
//
// Purpose:
// normalize replicated immutable snapshot state from
// HA/session replication boundary into peer snapshot fields.
//
// This layer does NOT:
// - perform distributed reconciliation
// - mutate local runtime snapshot authority
// - mutate output/runtime authority
// ======================================================

IF NOT GVL_HA_SESSION_REPLICATION.HA_Remote_Session_Valid THEN
    GVL_DISTRIBUTED_SNAPSHOT.Peer_Distributed_Snapshot_Epoch := 0;
    GVL_DISTRIBUTED_SNAPSHOT.Peer_Runtime_Snapshot_Epoch := 0;
    GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Epoch := 0;

    GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Immutable := FALSE;
    GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Lease_Active := FALSE;
    GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Last_Refresh_MS := 0;

    RETURN;
END_IF;

GVL_DISTRIBUTED_SNAPSHOT.Peer_Distributed_Snapshot_Epoch :=
    GVL_HA_SESSION_REPLICATION.HA_Remote_Distributed_Snapshot_Epoch;

GVL_DISTRIBUTED_SNAPSHOT.Peer_Runtime_Snapshot_Epoch :=
    GVL_HA_SESSION_REPLICATION.HA_Remote_Runtime_Snapshot_Epoch;

GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Epoch :=
    GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Epoch;

GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Immutable :=
    GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Immutable;

GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Lease_Active := TRUE;

GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Last_Refresh_MS :=
    GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Last_Refresh_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Distributed_Snapshot_Ingestion <<<
END_PROGRAM