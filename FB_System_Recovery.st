// ==============================================================================
// System recovery helper
//
// Internal helper for PRG_System.
// Recovery no longer restores authoritative runtime state directly.
// Safety latches and system mode are reconstructed from current
// runtime truth through orchestrators/managers after boot.
// ==============================================================================
FUNCTION_BLOCK FB_System_Recovery
VAR_IN_OUT
    VIO_Recovery_Done : BOOL;
END_VAR

IF NOT VIO_Recovery_Done THEN
    VIO_Recovery_Done := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_System_Recovery <<<
END_FUNCTION_BLOCK
