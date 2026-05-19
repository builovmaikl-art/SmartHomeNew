PROGRAM PRG_PLC_Fencing_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Authority_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Authority_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// PLC FENCING GOVERNOR
// ======================================================
// Governs distributed PLC ownership semantics.
// Prevents stale-owner resurrection and split-brain.
// ======================================================

GVL_PLC_FENCING.PLC_Split_Brain_Detected := FALSE;
GVL_PLC_FENCING.PLC_Stale_Owner_Detected := FALSE;
GVL_PLC_FENCING.PLC_Asymmetric_Partition_Detected := FALSE;
GVL_PLC_FENCING.PLC_Forced_Safe_Quarantine := FALSE;

// Active PLC ownership validation.
IF L_Authority_Valid AND (NOT GVL_STATUS.G_Is_Active_PLC) THEN
    L_Authority_Valid := FALSE;
    L_Error_Code := 7001;
    L_Error_Text := 'PLC ownership inactive';
END_IF;

// Lease freshness validation.
L_Delta_MS := L_Now_MS - GVL_PLC_FENCING.PLC_Last_Lease_Refresh_MS;

IF L_Authority_Valid AND GVL_PLC_FENCING.PLC_Lease_Active THEN
    IF L_Delta_MS > GVL_PLC_FENCING.PLC_Lease_Timeout_MS THEN
        L_Authority_Valid := FALSE;
        L_Error_Code := 7002;
        L_Error_Text := 'PLC lease expired';
    END_IF;
END_IF;

// Heartbeat-only ownership is unsafe.
IF L_Authority_Valid AND GVL_PLC_FENCING.PLC_Heartbeat_Only_Mode THEN
    L_Authority_Valid := FALSE;
    L_Error_Code := 7003;
    L_Error_Text := 'Heartbeat-only ownership rejected';
END_IF;

// Publish authoritative fencing state.
IF L_Authority_Valid THEN
    GVL_PLC_FENCING.PLC_Ownership_Epoch := GVL_PLC_FENCING.PLC_Ownership_Epoch + 1;
    GVL_PLC_FENCING.PLC_Fencing_Token := GVL_PLC_FENCING.PLC_Ownership_Epoch;

    GVL_PLC_FENCING.PLC_Ownership_Valid := TRUE;
    GVL_PLC_FENCING.PLC_Semantic_Authority_Valid := TRUE;

    GVL_PLC_FENCING.PLC_Lease_Active := TRUE;
    GVL_PLC_FENCING.PLC_Lease_Expired := FALSE;

    GVL_PLC_FENCING.PLC_Last_Lease_Refresh_MS := L_Now_MS;
    GVL_PLC_FENCING.PLC_Last_Authority_Validation_MS := L_Now_MS;

    GVL_PLC_FENCING.PLC_Last_Error_Code := 0;
    GVL_PLC_FENCING.PLC_Last_Error_Text := '';
ELSE
    GVL_PLC_FENCING.PLC_Ownership_Valid := FALSE;
    GVL_PLC_FENCING.PLC_Semantic_Authority_Valid := FALSE;

    GVL_PLC_FENCING.PLC_Lease_Expired := TRUE;
    GVL_PLC_FENCING.PLC_Forced_Safe_Quarantine := TRUE;

    GVL_PLC_FENCING.PLC_Last_Error_Code := L_Error_Code;
    GVL_PLC_FENCING.PLC_Last_Error_Text := L_Error_Text;

    IF L_Error_Code = 7002 THEN
        GVL_PLC_FENCING.PLC_Stale_Owner_Detected := TRUE;
    END_IF;

    IF L_Error_Code = 7003 THEN
        GVL_PLC_FENCING.PLC_Split_Brain_Detected := TRUE;
        GVL_PLC_FENCING.PLC_Asymmetric_Partition_Detected := TRUE;
    END_IF;

    GVL_PLC_FENCING.PLC_Fencing_Invalidation_Count := GVL_PLC_FENCING.PLC_Fencing_Invalidation_Count + 1;
END_IF;
END_PROGRAM
