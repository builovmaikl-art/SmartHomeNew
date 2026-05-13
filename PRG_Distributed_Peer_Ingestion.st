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
// normalize explicit remote PLC session contract state into
// distributed peer-input fields consumed by distributed governors.
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
    GVL_PEER_SESSION.Remote_Last_Refresh_MS;

GVL_DISTRIBUTED_EPOCH.Peer_Lease_Active :=
    GVL_PEER_SESSION.Remote_Session_Valid;

// ------------------------------------------------------
// Explicit remote session ingestion.
// ------------------------------------------------------

IF GVL_PEER_SESSION.Remote_Session_Valid THEN
    GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Epoch :=
        GVL_PEER_SESSION.Remote_Runtime_Epoch;

    GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Epoch :=
        GVL_PEER_SESSION.Remote_Snapshot_Epoch;

    GVL_DISTRIBUTED_EPOCH.Peer_Boot_Generation :=
        GVL_PEER_SESSION.Remote_Boot_Generation;

    GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Token :=
        GVL_PEER_SESSION.Remote_Fencing_Token;
ELSE
    GVL_DISTRIBUTED_EPOCH.Peer_Lease_Active := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Distributed_Peer_Ingestion <<<
END_PROGRAM