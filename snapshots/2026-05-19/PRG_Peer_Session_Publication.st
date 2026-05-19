PROGRAM PRG_Peer_Session_Publication
// ======================================================
// PEER SESSION PUBLICATION
// ======================================================
// Canonical local PLC session export.
//
// Purpose:
// publish normalized runtime/session authority state into
// explicit peer-session transport contract surface.
//
// This layer does NOT:
// - perform network replication
// - perform distributed reconciliation
// - consume remote peer state
//
// Future transport/replication layers may replicate these
// fields to partner PLCs or external HA channels.
// ======================================================

GVL_PEER_SESSION.Remote_Session_Valid :=
    GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK
    AND GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed;

GVL_PEER_SESSION.Remote_Last_Refresh_MS :=
    GVL_STATUS.G_System_Time_MS;

GVL_PEER_SESSION.Remote_Runtime_Epoch :=
    GVL_RUNTIME_EPOCH.Runtime_Epoch;

GVL_PEER_SESSION.Remote_Snapshot_Epoch :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch;

GVL_PEER_SESSION.Remote_Boot_Generation :=
    GVL_TIME_MONOTONIC.Boot_Generation_ID;

GVL_PEER_SESSION.Remote_Fencing_Token :=
    GVL_PLC_FENCING.PLC_Fencing_Token;

GVL_PEER_SESSION.Remote_Publication_Allowed :=
    GVL_OUTPUT_EPOCH.Output_Publication_Valid
    AND NOT GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay;

GVL_PEER_SESSION.Remote_Runtime_Healthy :=
    GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK;

// >>> BULK_SYNC_ANCHOR: PRG_Peer_Session_Publication <<<
END_PROGRAM