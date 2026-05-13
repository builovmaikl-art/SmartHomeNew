PROGRAM PRG_Distributed_Commit_Ingestion
// ======================================================
// DISTRIBUTED COMMIT INGESTION
// ======================================================
// Explicit peer distributed commit ingestion layer.
//
// Purpose:
// normalize replicated peer commit-handshake state into
// distributed commit peer-input fields.
//
// This layer does NOT:
// - perform commit reconciliation
// - validate replay continuity
// - validate peer acknowledgements
// ======================================================

IF GVL_HA_SESSION_REPLICATION.HA_Remote_Session_Valid THEN
    GVL_DISTRIBUTED_COMMIT.Peer_Publication_Commit_Epoch :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Commit_Epoch;

    GVL_DISTRIBUTED_COMMIT.Peer_Prepare_Epoch :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Prepare_Epoch;

    GVL_DISTRIBUTED_COMMIT.Peer_Commit_Ack_Valid :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Commit_Ack_Valid;

    GVL_DISTRIBUTED_COMMIT.Peer_Commit_Last_Refresh_MS :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Commit_Last_Refresh_MS;
ELSE
    GVL_DISTRIBUTED_COMMIT.Peer_Publication_Commit_Epoch := 0;
    GVL_DISTRIBUTED_COMMIT.Peer_Prepare_Epoch := 0;
    GVL_DISTRIBUTED_COMMIT.Peer_Commit_Ack_Valid := FALSE;
    GVL_DISTRIBUTED_COMMIT.Peer_Commit_Last_Refresh_MS := 0;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Distributed_Commit_Ingestion <<<
END_PROGRAM