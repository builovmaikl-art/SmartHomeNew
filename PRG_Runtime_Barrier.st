PROGRAM PRG_Runtime_Barrier
VAR
    L_Now_MS : UDINT;
    L_Runtime_OK : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Runtime_OK := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// AUTHORITATIVE RUNTIME BARRIER
// ======================================================
// Creates authoritative runtime publication semantics.
// Rejects impossible runtime states before physical publication.
// ======================================================

GVL_RUNTIME_EPOCH.Runtime_Cycle_Start_MS := L_Now_MS;
GVL_RUNTIME_EPOCH.Runtime_Snapshot_Published := FALSE;
GVL_RUNTIME_EPOCH.Runtime_Impossible_State_Detected := FALSE;
GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed := FALSE;

IF NOT GVL_STATUS.G_Is_Active_PLC THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5000;
    L_Error_Text := 'Runtime barrier inactive PLC';
END_IF;

IF L_Runtime_OK AND (NOT GVL_CONFIG_VALIDATION.G_Runtime_Sanity_OK) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5001;
    L_Error_Text := 'Runtime sanity invalid';
END_IF;

IF L_Runtime_OK AND GVL_COMMAND_VERIFY.PreOutput_Block_IO THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5002;
    L_Error_Text := 'Runtime blocked by pre-output barrier';
END_IF;

IF L_Runtime_OK THEN
    IF (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE)
    AND (GVL_COMMAND_SHADOW.G_Vent_Stop)
    THEN
        L_Runtime_OK := FALSE;
        L_Error_Code := 5003;
        L_Error_Text := 'Impossible fire ventilation state';
    END_IF;
END_IF;

IF L_Runtime_OK THEN
    IF (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS)
    AND (NOT GVL_COMMAND_SHADOW.G_Gas_Valve_Close)
    THEN
        L_Runtime_OK := FALSE;
        L_Error_Code := 5004;
        L_Error_Text := 'Impossible gas valve state';
    END_IF;
END_IF;

GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK := L_Runtime_OK;
GVL_RUNTIME_EPOCH.Runtime_Snapshot_Valid := L_Runtime_OK;
GVL_RUNTIME_EPOCH.Runtime_PLC_Authority_Valid := GVL_STATUS.G_Is_Active_PLC;
GVL_RUNTIME_EPOCH.Runtime_Last_Validation_Time_MS := L_Now_MS;

IF L_Runtime_OK THEN
    GVL_RUNTIME_EPOCH.Runtime_Epoch := GVL_RUNTIME_EPOCH.Runtime_Epoch + 1;
    GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed := TRUE;
    GVL_RUNTIME_EPOCH.Runtime_Snapshot_Published := TRUE;
    GVL_RUNTIME_EPOCH.Runtime_Last_Error_Code := 0;
    GVL_RUNTIME_EPOCH.Runtime_Last_Error_Text := '';
ELSE
    GVL_RUNTIME_EPOCH.Runtime_Impossible_State_Detected := TRUE;
    GVL_RUNTIME_EPOCH.Runtime_Last_Error_Code := L_Error_Code;
    GVL_RUNTIME_EPOCH.Runtime_Last_Error_Text := L_Error_Text;
    GVL_RUNTIME_EPOCH.Runtime_Barrier_Block_Count := GVL_RUNTIME_EPOCH.Runtime_Barrier_Block_Count + 1;
END_IF;

GVL_RUNTIME_EPOCH.Runtime_Cycle_End_MS := L_Now_MS;
END_PROGRAM
