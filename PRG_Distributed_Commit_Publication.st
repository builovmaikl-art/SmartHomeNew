PROGRAM PRG_Distributed_Commit_Publication
// ======================================================
// DISTRIBUTED COMMIT PUBLICATION
// ======================================================
// Canonical local distributed commit export.
//
// Purpose:
// publish normalized deterministic commit handshake state
// into HA replication boundary.
//
// This layer does NOT:
// - perform reconciliation
// - validate peer acknowledgements
// - arbitrate publication authority
// ======================================================

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