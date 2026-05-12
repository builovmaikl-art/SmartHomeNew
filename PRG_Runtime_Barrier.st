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
//
// Runtime authority remains:
// - monotonic-time authoritative;
// - PLC fencing authoritative;
// - transport freshness authoritative.
//
// Recovery cleanup, command verification and observability
// remain downstream-oriented. Diagnostics/explainability
// synchronization must not become upstream runtime authority.
// ======================================================

GVL_RUNTIME_EPOCH.Runtime_Cycle_Start_MS := L_Now_MS;
GVL_RUNTIME_EPOCH.Runtime_Snapshot_Published := FALSE;
GVL_RUNTIME_EPOCH.Runtime_Impossible_State_Detected := FALSE;
GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed := FALSE;

// ------------------------------------------------------
// Monotonic time authority validation.
// ------------------------------------------------------

IF NOT GVL_TIME_MONOTONIC.Monotonic_Time_Initialized THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 4900;
    L_Error_Text := 'Monotonic time not initialized';
END_IF;

IF L_Runtime_OK AND (NOT GVL_TIME_MONOTONIC.Monotonic_Time_Valid) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 4901;
    L_Error_Text := 'Monotonic time invalid';
END_IF;

IF L_Runtime_OK AND GVL_TIME_MONOTONIC.Startup_Quarantine_Active THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 4902;
    L_Error_Text := 'Startup quarantine active';
END_IF;

IF L_Runtime_OK AND GVL_TIME_MONOTONIC.Time_Rollback_Detected THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 4903;
    L_Error_Text := 'Monotonic rollback detected';
END_IF;

IF L_Runtime_OK AND GVL_TIME_MONOTONIC.Retained_Time_Invalid THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 4904;
    L_Error_Text := 'Retained monotonic time invalid';
END_IF;

IF L_Runtime_OK AND (GVL_TIME_MONOTONIC.Boot_Generation_ID = 0) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 4905;
    L_Error_Text := 'Boot generation missing';
END_IF;

// ------------------------------------------------------
// Base PLC/runtime authority validation.
// ------------------------------------------------------

IF L_Runtime_OK AND (NOT GVL_STATUS.G_Is_Active_PLC) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5000;
    L_Error_Text := 'Runtime barrier inactive PLC';
END_IF;

// ------------------------------------------------------
// PLC fencing authority validation.
// ------------------------------------------------------

IF L_Runtime_OK AND (NOT GVL_PLC_FENCING.PLC_Ownership_Valid) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5010;
    L_Error_Text := 'PLC ownership invalid';
END_IF;

IF L_Runtime_OK AND (NOT GVL_PLC_FENCING.PLC_Semantic_Authority_Valid) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5011;
    L_Error_Text := 'PLC semantic authority invalid';
END_IF;

IF L_Runtime_OK AND GVL_PLC_FENCING.PLC_Forced_Safe_Quarantine THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5012;
    L_Error_Text := 'PLC fencing quarantine active';
END_IF;

IF L_Runtime_OK AND GVL_PLC_FENCING.PLC_Lease_Expired THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5013;
    L_Error_Text := 'PLC authority lease expired';
END_IF;

IF L_Runtime_OK AND (GVL_PLC_FENCING.PLC_Fencing_Token = 0) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5014;
    L_Error_Text := 'PLC fencing token missing';
END_IF;

// ------------------------------------------------------
// Transport freshness validation.
// ------------------------------------------------------

IF L_Runtime_OK AND (NOT GVL_TRANSPORT_FRESHNESS.Transport_Freshness_Valid) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5200;
    L_Error_Text := 'Transport freshness invalid';
END_IF;

IF L_Runtime_OK AND (NOT GVL_TRANSPORT_FRESHNESS.Transport_Publication_Allowed) THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5201;
    L_Error_Text := 'Transport publication blocked';
END_IF;

IF L_Runtime_OK AND GVL_TRANSPORT_FRESHNESS.Transport_Quarantine_Active THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5202;
    L_Error_Text := 'Transport quarantine active';
END_IF;

IF L_Runtime_OK AND GVL_TRANSPORT_FRESHNESS.Transport_Lease_Expired THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5203;
    L_Error_Text := 'Transport lease expired';
END_IF;

IF L_Runtime_OK AND GVL_TRANSPORT_FRESHNESS.Transport_Snapshot_Invalid THEN
    L_Runtime_OK := FALSE;
    L_Error_Code := 5204;
    L_Error_Text := 'Transport snapshot invalid';
END_IF;

// ------------------------------------------------------
// Impossible-state rejection.
// ------------------------------------------------------

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

// ------------------------------------------------------
// Authoritative runtime publication.
// ------------------------------------------------------

GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK := L_Runtime_OK;
GVL_RUNTIME_EPOCH.Runtime_Snapshot_Valid := L_Runtime_OK;
GVL_RUNTIME_EPOCH.Runtime_PLC_Authority_Valid :=
    GVL_STATUS.G_Is_Active_PLC
    AND GVL_PLC_FENCING.PLC_Semantic_Authority_Valid
    AND GVL_PLC_FENCING.PLC_Ownership_Valid
    AND GVL_TIME_MONOTONIC.Monotonic_Time_Valid
    AND GVL_TRANSPORT_FRESHNESS.Transport_Freshness_Valid;

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
