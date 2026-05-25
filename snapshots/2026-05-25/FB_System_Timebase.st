// ==============================================================================
// System timebase helper
//
// Internal helper for PRG_System.
// Owns PLC runtime clock projection into GVL_STATUS:
// - monotonic system milliseconds
// - time-of-day milliseconds
// - day of week / day of year rollover
// - TOD representation
// ==============================================================================
FUNCTION_BLOCK FB_System_Timebase
VAR
    L_Time_Diff : UDINT;
END_VAR

GVL_STATUS.G_System_Time_MS := TIME_TO_UDINT(TIME());

L_Time_Diff := SEL(
    GVL_STATUS.G_System_Time_MS >= GVL_STATUS.G_Last_System_Time_MS,
    GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Last_System_Time_MS,
    (4294967295 - GVL_STATUS.G_Last_System_Time_MS) + GVL_STATUS.G_System_Time_MS + 1
);

GVL_STATUS.G_Time_Of_Day_MS := (GVL_STATUS.G_Time_Of_Day_MS + L_Time_Diff) MOD 86400000;

IF GVL_STATUS.G_Time_Of_Day_MS < L_Time_Diff THEN
    GVL_STATUS.G_Current_Day := (GVL_STATUS.G_Current_Day MOD 7) + 1;
    GVL_STATUS.G_Day_Of_Year := (GVL_STATUS.G_Day_Of_Year MOD 365) + 1;
END_IF;

GVL_STATUS.G_Last_System_Time_MS := GVL_STATUS.G_System_Time_MS;
GVL_STATUS.G_Current_TOD := UDINT_TO_TOD(GVL_STATUS.G_Time_Of_Day_MS);

// >>> BULK_SYNC_ANCHOR: FB_System_Timebase <<<
END_FUNCTION_BLOCK
