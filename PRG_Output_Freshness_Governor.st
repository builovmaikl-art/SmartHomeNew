PROGRAM PRG_Output_Freshness_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Output_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Output_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// OUTPUT FRESHNESS GOVERNOR
// ======================================================
// Governs physical output publication freshness.
// Prevents stale output survivability.
// ======================================================

GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay := FALSE;
GVL_OUTPUT_EPOCH.Output_Stale_Detected := FALSE;

// Runtime authority linkage.
IF NOT GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6000;
    L_Error_Text := 'Output runtime authority invalid';
END_IF;

IF L_Output_Valid AND (NOT GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6001;
    L_Error_Text := 'Output publication not allowed';
END_IF;

// Epoch linkage validation.
IF L_Output_Valid THEN
    IF GVL_OUTPUT_EPOCH.Output_Runtime_Epoch > GVL_RUNTIME_EPOCH.Runtime_Epoch THEN
        L_Output_Valid := FALSE;
        L_Error_Code := 6002;
        L_Error_Text := 'Output epoch ahead of runtime epoch';
    END_IF;
END_IF;

// Lease freshness validation.
L_Delta_MS := L_Now_MS - GVL_OUTPUT_EPOCH.Output_Last_Refresh_MS;

IF L_Output_Valid AND GVL_OUTPUT_EPOCH.Output_Lease_Active THEN
    IF L_Delta_MS > GVL_OUTPUT_EPOCH.Output_Lease_Timeout_MS THEN
        L_Output_Valid := FALSE;
        L_Error_Code := 6003;
        L_Error_Text := 'Output lease expired';
    END_IF;
END_IF;

// Publish authoritative output freshness state.
IF L_Output_Valid THEN
    GVL_OUTPUT_EPOCH.Output_Publication_Epoch := GVL_OUTPUT_EPOCH.Output_Publication_Epoch + 1;
    GVL_OUTPUT_EPOCH.Output_Publication_Valid := TRUE;
    GVL_OUTPUT_EPOCH.Output_Lease_Active := TRUE;
    GVL_OUTPUT_EPOCH.Output_Lease_Expired := FALSE;

    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch := GVL_RUNTIME_EPOCH.Runtime_Epoch;
    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid := TRUE;

    GVL_OUTPUT_EPOCH.Output_Last_Publication_MS := L_Now_MS;
    GVL_OUTPUT_EPOCH.Output_Last_Refresh_MS := L_Now_MS;

    GVL_OUTPUT_EPOCH.Output_Last_Error_Code := 0;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Text := '';
ELSE
    GVL_OUTPUT_EPOCH.Output_Publication_Valid := FALSE;
    GVL_OUTPUT_EPOCH.Output_Lease_Expired := TRUE;
    GVL_OUTPUT_EPOCH.Output_Stale_Detected := TRUE;
    GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay := TRUE;

    GVL_OUTPUT_EPOCH.Output_Last_Invalidation_MS := L_Now_MS;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Code := L_Error_Code;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Text := L_Error_Text;

    GVL_OUTPUT_EPOCH.Output_Invalidation_Count := GVL_OUTPUT_EPOCH.Output_Invalidation_Count + 1;
END_IF;
END_PROGRAM
