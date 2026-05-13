PROGRAM PRG_Distributed_Commit_Publication
// ======================================================
// DISTRIBUTED COMMIT PUBLICATION
// ======================================================
// Canonical local distributed commit export into the
// HA replication boundary.
//
// Purpose:
// publish normalized deterministic commit handshake state
// into the dedicated HA boundary before commit ingestion.
//
// This layer does NOT:
// - perform reconciliation
// - validate peer acknowledgements
// - arbitrate publication authority
//
// Disabled HA replication must not leave stale commit mirrors.
// ======================================================

IF NOT GVL_HA_SESSION_REPLICATION.HA_Replication_Enabled THEN
    GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Commit_Epoch := 0;
    GVL_HA_SESSION_REPLICATION.HA_Remote_Prepare_Epoch := 0;
    GVL_HA_SESSION_REPLICATION.HA_Remote_Commit_Ack_Valid := FALSE;
    GVL_HA_SESSION_REPLICATION.HA_Remote_Commit_Last_Refresh_MS := 0;
    RETURN;
END_IF;

GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Commit_Epoch :=
    GVL_DISTRIBUTED_COMMIT.Local_Publication_Commit_Epoch;

GVL_HA_SESSION_REPLICATION.HA_Remote_Prepare_Epoch :=
    GVL_DISTRIBUTED_COMMIT.Local_Prepare_Epoch;

GVL_HA_SESSION_REPLICATION.HA_Remote_Commit_Ack_Valid :=
    GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed;

GVL_HA_SESSION_REPLICATION.HA_Remote_Commit_Last_Refresh_MS :=
    GVL_STATUS.G_System_Time_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Distributed_Commit_Publication <<<
END_PROGRAM