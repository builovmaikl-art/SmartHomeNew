PROGRAM PRG_PLC_Arbitration

// Update heartbeat
IF GVL_STATUS.G_Remote_PLC_Pulse THEN
    GVL_STATUS.G_Remote_PLC_Last_Seen_MS := GVL_TIME_SERVICE.G_Now_MS;
END_IF;

// Alive check (3s)
GVL_STATUS.G_Remote_PLC_Alive :=
    (GVL_TIME_SERVICE.G_Now_MS - GVL_STATUS.G_Remote_PLC_Last_Seen_MS) < 3000;

// Arbitration
IF NOT GVL_STATUS.G_Remote_PLC_Alive THEN
    GVL_STATUS.G_Is_Active_PLC := TRUE;
ELSE
    IF GVL_STATUS.G_Local_PLC_ID < GVL_STATUS.G_Active_PLC_ID THEN
        GVL_STATUS.G_Is_Active_PLC := TRUE;
    ELSE
        GVL_STATUS.G_Is_Active_PLC := FALSE;
    END_IF;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_PLC_Arbitration <<<
