PROGRAM PRG_Distributed_Snapshot_Publication
// ======================================================
// DISTRIBUTED SNAPSHOT PUBLICATION
// ======================================================
// Canonical local distributed snapshot export into the
// HA replication boundary.
//
// Purpose:
// publish normalized immutable snapshot/publication state
// into the dedicated HA boundary before snapshot ingestion.
//
// This layer does NOT:
// - perform reconciliation
// - validate peer snapshot state
// - arbitrate distributed publication authority
//
// Disabled HA replication must not leave stale snapshot mirrors.
// ======================================================

IF NOT GVL_HA_SESSION_REPLICATION.HA_Replication_Enabled THEN
    GVL_HA_SESSION_REPLICATION.HA_Remote_Distributed_Snapshot_Epoch := 0;
    GVL_HA_SESSION_REPLICATION.HA_Remote_Runtime_Snapshot_Epoch := 0;
    GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Epoch := 0;
    GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Immutable := FALSE;
    GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Last_Refresh_MS := 0;
    RETURN;
END_IF;

GVL_HA_SESSION_REPLICATION.HA_Remote_Distributed_Snapshot_Epoch :=
    GVL_DISTRIBUTED_SNAPSHOT.Local_Distributed_Snapshot_Epoch;

GVL_HA_SESSION_REPLICATION.HA_Remote_Runtime_Snapshot_Epoch :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch;

GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Epoch :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Epoch;

GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Immutable :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid;

GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Last_Refresh_MS :=
    GVL_STATUS.G_System_Time_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Distributed_Snapshot_Publication <<<
END_PROGRAM