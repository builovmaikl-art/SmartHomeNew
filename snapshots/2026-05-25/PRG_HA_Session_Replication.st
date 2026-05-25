PROGRAM PRG_HA_Session_Replication
// ======================================================
// HA SESSION REPLICATION
// ======================================================
// Dedicated HA/session replication boundary.
//
// Purpose:
// replicate canonical peer-session state through isolated
// HA replication surface.
//
// Current implementation:
// bounded loopback foundation.
//
// Future implementations may replace this with:
// - SysCom HA channel
// - shared-memory replication
// - dedicated Ethernet HA link
// - deterministic fieldbus synchronization
//
// without changing distributed governors.
// ======================================================

IF NOT GVL_HA_SESSION_REPLICATION.HA_Replication_Enabled THEN
    GVL_HA_SESSION_REPLICATION.HA_Channel_Healthy := FALSE;
    RETURN;
END_IF;

// ------------------------------------------------------
// Canonical session export replication.
// ------------------------------------------------------

GVL_HA_SESSION_REPLICATION.HA_Remote_Session_Valid :=
    GVL_PEER_SESSION.Remote_Session_Valid;

GVL_HA_SESSION_REPLICATION.HA_Remote_Last_Refresh_MS :=
    GVL_PEER_SESSION.Remote_Last_Refresh_MS;

GVL_HA_SESSION_REPLICATION.HA_Remote_Runtime_Epoch :=
    GVL_PEER_SESSION.Remote_Runtime_Epoch;

GVL_HA_SESSION_REPLICATION.HA_Remote_Snapshot_Epoch :=
    GVL_PEER_SESSION.Remote_Snapshot_Epoch;

GVL_HA_SESSION_REPLICATION.HA_Remote_Boot_Generation :=
    GVL_PEER_SESSION.Remote_Boot_Generation;

GVL_HA_SESSION_REPLICATION.HA_Remote_Fencing_Token :=
    GVL_PEER_SESSION.Remote_Fencing_Token;

GVL_HA_SESSION_REPLICATION.HA_Remote_Publication_Allowed :=
    GVL_PEER_SESSION.Remote_Publication_Allowed;

GVL_HA_SESSION_REPLICATION.HA_Remote_Runtime_Healthy :=
    GVL_PEER_SESSION.Remote_Runtime_Healthy;

GVL_HA_SESSION_REPLICATION.HA_Last_TX_MS :=
    GVL_STATUS.G_System_Time_MS;

GVL_HA_SESSION_REPLICATION.HA_Last_RX_MS :=
    GVL_STATUS.G_System_Time_MS;

GVL_HA_SESSION_REPLICATION.HA_Channel_Healthy := TRUE;

// >>> BULK_SYNC_ANCHOR: PRG_HA_Session_Replication <<<
END_PROGRAM