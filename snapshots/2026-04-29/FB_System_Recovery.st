// ==============================================================================
// System recovery helper
//
// Internal helper for PRG_System.
// Owns one-shot recovery of persistent safety/system state after boot.
// ==============================================================================
FUNCTION_BLOCK FB_System_Recovery
VAR_IN_OUT
    VIO_Recovery_Done : BOOL;
END_VAR

IF NOT VIO_Recovery_Done THEN
    IF GVL_PERSISTENT.P_Valid THEN
        GVL_STATE.G_Safety_Gas_Latched := GVL_PERSISTENT.P_Safety_Gas_Latched;
        GVL_STATE.G_Safety_Smoke_Latched := GVL_PERSISTENT.P_Safety_Smoke_Latched;
        GVL_STATE.G_Safety_Leak_Latched := GVL_PERSISTENT.P_Safety_Leak_Latched;
        GVL_STATE.G_System_Mode := GVL_PERSISTENT.P_System_Mode;
    END_IF;

    VIO_Recovery_Done := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_System_Recovery <<<
