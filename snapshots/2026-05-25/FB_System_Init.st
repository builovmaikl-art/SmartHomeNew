// ==============================================================================
// System init helper
//
// Internal helper for PRG_System.
// Owns first-boot initialization of RETAIN runtime state.
// ==============================================================================
FUNCTION_BLOCK FB_System_Init
VAR_IN_OUT
    VIO_Local_State : ST_System_State_Snapshot;
    VIO_Remote_State : ST_System_State_Snapshot;
END_VAR

VAR
    L_i : INT;
END_VAR

IF NOT GVL_Retain.G_Initialized THEN
    FOR L_i := 0 TO GVL_CONSTANTS.C_MAX_PRESENCE_HISTORY - 1 DO
        GVL_Retain.G_Presence_History[L_i] := 0;
    END_FOR;

    GVL_Retain.G_History_Write_Idx := 1;
    GVL_Retain.G_History_Total_Events := 0;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        GVL_Retain.G_Boiler_Accumulated_MS[L_i] := 0;
        GVL_Retain.G_Boiler_Work_Seconds[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_Retain.G_Valve_Test_Results[L_i] := FALSE;
    END_FOR;

    VIO_Local_State.Version := 0;
    VIO_Remote_State.Version := 0;

    GVL_Retain.G_Initialized := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_System_Init <<<
END_FUNCTION_BLOCK
