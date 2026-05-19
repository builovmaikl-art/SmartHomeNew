PROGRAM PRG_PLC_Arbitration

// Update heartbeat
IF GVL_STATUS.G_Remote_PLC_Pulse THEN
    GVL_STATUS.G_Remote_PLC_Last_Seen_MS := GVL_TIME_SERVICE.G_Now_MS;
END_IF;

// Alive check (3s)
GVL_STATUS.G_Remote_PLC_Alive :=
    (GVL_TIME_SERVICE.G_Now_MS - GVL_STATUS.G_Remote_PLC_Last_Seen_MS) < 3000;

// Deterministic arbitration.
// If remote is not alive, local PLC owns runtime.
// If remote is alive, the lowest PLC ID wins; equality keeps local active
// because G_Active_PLC_ID defaults to the configured local owner ID.
IF NOT GVL_STATUS.G_Remote_PLC_Alive THEN
    GVL_STATUS.G_Is_Active_PLC := TRUE;
    GVL_STATUS.G_Active_PLC_ID := GVL_STATUS.G_Local_PLC_ID;
ELSE
    IF GVL_STATUS.G_Local_PLC_ID <= GVL_STATUS.G_Active_PLC_ID THEN
        GVL_STATUS.G_Is_Active_PLC := TRUE;
        GVL_STATUS.G_Active_PLC_ID := GVL_STATUS.G_Local_PLC_ID;
    ELSE
        GVL_STATUS.G_Is_Active_PLC := FALSE;
    END_IF;
END_IF;

GVL_STATUS.G_Other_PLC_Is_Active :=
    GVL_STATUS.G_Remote_PLC_Alive AND NOT GVL_STATUS.G_Is_Active_PLC;

// >>> BULK_SYNC_ANCHOR: PRG_PLC_Arbitration <<<
END_PROGRAM
