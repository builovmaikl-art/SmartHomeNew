PROGRAM PRG_Distributed_Peer_Ingestion
VAR
    L_Now_MS : UDINT;
END_VAR

// ======================================================
// DISTRIBUTED PEER INGESTION
// ======================================================
// Bounded peer-session ingestion layer.
//
// Purpose:
// normalize replicated HA session state into distributed
// peer-input fields consumed by distributed governors.
//
// This layer does NOT:
// - perform reconciliation/quarantine decisions
// - perform split-brain detection
// - validate peer publication correctness
// - mutate local runtime authority
// ======================================================

L_Now_MS := GVL_STATUS.G_System_Time_MS;

// ------------------------------------------------------
// Peer session freshness projection.
// ------------------------------------------------------

GVL_DISTRIBUTED_EPOCH.Peer_Last_Refresh_MS :=
    GVL_HA_SESSION_REPLICATION.HA_Remote_Last_Refresh_MS;

GVL_DISTRIBUTED_EPOCH.Peer_Lease_Active :=
    GVL_HA_SESSION_REPLICATION.HA_Remote_Session_Valid;

// ------------------------------------------------------
// Replicated remote session ingestion.
// ------------------------------------------------------

IF GVL_HA_SESSION_REPLICATION.HA_Remote_Session_Valid THEN
    GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Epoch :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Runtime_Epoch;

    GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Epoch :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Epoch;

    GVL_DISTRIBUTED_EPOCH.Peer_Boot_Generation :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Boot_Generation;

    GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Token :=
        GVL_HA_SESSION_REPLICATION.HA_Remote_Fencing_Token;
ELSE
    GVL_DISTRIBUTED_EPOCH.Peer_Lease_Active := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Distributed_Peer_Ingestion <<<
END_PROGRAM