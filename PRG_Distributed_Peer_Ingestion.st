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
// normalize remote PLC liveness/session visibility into
// distributed peer-input fields consumed by distributed governors.
//
// This layer does NOT:
// - perform reconciliation/quarantine decisions
// - perform split-brain detection
// - validate peer publication correctness
// - mutate local runtime authority
//
// Current implementation status:
// peer epoch/token values are projected from currently available
// remote PLC runtime visibility until a richer transport/session
// contract is implemented.
// ======================================================

L_Now_MS := GVL_STATUS.G_System_Time_MS;

// ------------------------------------------------------
// Peer session freshness projection.
// ------------------------------------------------------

GVL_DISTRIBUTED_EPOCH.Peer_Last_Refresh_MS :=
    GVL_STATUS.G_Remote_PLC_Last_Seen_MS;

GVL_DISTRIBUTED_EPOCH.Peer_Lease_Active :=
    GVL_STATUS.G_Remote_PLC_Alive;

// ------------------------------------------------------
// Peer runtime visibility projection.
// ------------------------------------------------------

IF GVL_STATUS.G_Remote_PLC_Alive THEN
    // Transitional projection model:
    // until explicit remote epoch transport exists,
    // peer visibility mirrors current known remote-active session.

    GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Epoch :=
        GVL_RUNTIME_EPOCH.Runtime_Epoch;

    GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Epoch :=
        GVL_RUNTIME_SNAPSHOT.Runtime_Snapshot_Epoch;

    GVL_DISTRIBUTED_EPOCH.Peer_Boot_Generation :=
        GVL_STATUS.G_Active_PLC_ID;

    // Transitional fencing projection.
    // Explicit remote fencing-token exchange is not yet implemented.
    GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Token :=
        GVL_STATUS.G_Active_PLC_ID;
ELSE
    GVL_DISTRIBUTED_EPOCH.Peer_Lease_Active := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Distributed_Peer_Ingestion <<<
END_PROGRAM