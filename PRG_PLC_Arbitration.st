PROGRAM PRG_PLC_Arbitration
// Local-only PLC authority for the cold-spare architecture.
//
// Hot A/B failover and lowest-ID arbitration are intentionally disabled.
// The reserve PLC is not expected to be connected to the same physical outputs
// during normal runtime.

GVL_STATUS.G_Is_Active_PLC := TRUE;
GVL_STATUS.G_Other_PLC_Is_Active := FALSE;
GVL_STATUS.G_Remote_PLC_Alive := FALSE;
GVL_STATUS.G_Active_PLC_ID := GVL_STATUS.G_Local_PLC_ID;

// Keep remote visibility fields reset so old partner pulses cannot resurrect a
// standby/active split-brain path.
GVL_STATUS.G_Remote_PLC_Pulse := FALSE;
GVL_STATUS.G_Remote_PLC_Last_Seen_MS := 0;

// >>> BULK_SYNC_ANCHOR: PRG_PLC_Arbitration <<<
END_PROGRAM