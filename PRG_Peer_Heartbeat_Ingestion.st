PROGRAM PRG_Peer_Heartbeat_Ingestion
VAR
    L_Now_MS : UDINT;
END_VAR

// ======================================================
// PEER HEARTBEAT INGESTION
// ======================================================
// Bounded transport/heartbeat ingestion bridge.
//
// Purpose:
// map physical partner heartbeat inputs into runtime-visible
// remote PLC liveness state consumed by arbitration layers.
//
// This layer does NOT:
// - perform distributed epoch reconciliation
// - publish peer fencing tokens
// - mutate distributed authority state
// - participate in runtime/output hard-stop governance
//
// Ownership:
// physical partner inputs  -> GVL_IO
// heartbeat ingestion      -> this PRG
// arbitration/governance   -> downstream consumers only
// ======================================================

L_Now_MS := GVL_STATUS.G_System_Time_MS;

// ------------------------------------------------------
// Physical heartbeat ingestion.
// ------------------------------------------------------

GVL_STATUS.G_Remote_PLC_Pulse := GVL_IO.DI_Partner_Pulse;

// ------------------------------------------------------
// Partner active visibility projection.
// ------------------------------------------------------

IF GVL_IO.DI_Partner_Active THEN
    GVL_STATUS.G_Remote_PLC_Last_Seen_MS := L_Now_MS;
END_IF;

// ------------------------------------------------------
// Optional pulse freshness refresh.
// ------------------------------------------------------

IF GVL_IO.DI_Partner_Pulse THEN
    GVL_STATUS.G_Remote_PLC_Last_Seen_MS := L_Now_MS;
END_IF;

// ------------------------------------------------------
// Remote liveness projection.
// ------------------------------------------------------

GVL_STATUS.G_Remote_PLC_Alive :=
    (L_Now_MS - GVL_STATUS.G_Remote_PLC_Last_Seen_MS) < 3000;

// >>> BULK_SYNC_ANCHOR: PRG_Peer_Heartbeat_Ingestion <<<
END_PROGRAM