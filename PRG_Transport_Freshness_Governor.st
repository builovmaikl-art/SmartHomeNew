PROGRAM PRG_Transport_Freshness_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Transport_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Transport_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// TRANSPORT FRESHNESS GOVERNOR
// ======================================================
// Governs transport freshness semantics.
// Prevents stale transport semantic publication.
//
// Transport freshness is upstream of runtime barrier in MAIN.
// It must not consume runtime barrier or downstream recovery
// governance state, because runtime barrier consumes transport
// freshness state later in the same scan-cycle.
// ======================================================

GVL_TRANSPORT_FRESHNESS.Transport_Stale_Frame_Detected := FALSE;
GVL_TRANSPORT_FRESHNESS.Transport_Transaction_Mismatch := FALSE;
GVL_TRANSPORT_FRESHNESS.Transport_Snapshot_Invalid := FALSE;

// Monotonic authority linkage.
IF L_Transport_Valid AND (NOT GVL_TIME_MONOTONIC.Monotonic_Time_Valid) THEN
    L_Transport_Valid := FALSE;
    L_Error_Code := 10001;
    L_Error_Text := 'Transport monotonic authority invalid';
END_IF;

// Transport reconnect quarantine.
IF GVL_TRANSPORT_FRESHNESS.Transport_Reconnect_Stabilizing THEN
    GVL_TRANSPORT_FRESHNESS.Transport_Quarantine_Active := TRUE;

    L_Transport_Valid := FALSE;

    IF L_Error_Code = 0 THEN
        L_Error_Code := 10003;
        L_Error_Text := 'Transport reconnect stabilization active';
    END_IF;
END_IF;

// Lease freshness validation.
L_Delta_MS := L_Now_MS - GVL_TRANSPORT_FRESHNESS.Transport_Last_Refresh_MS;

IF L_Transport_Valid AND GVL_TRANSPORT_FRESHNESS.Transport_Lease_Valid THEN
    IF L_Delta_MS > GVL_TRANSPORT_FRESHNESS.Transport_Lease_Timeout_MS THEN
        L_Transport_Valid := FALSE;
        L_Error_Code := 10004;
        L_Error_Text := 'Transport lease expired';

        GVL_TRANSPORT_FRESHNESS.Transport_Lease_Expired := TRUE;
    END_IF;
END_IF;

// Publish authoritative transport freshness state.
IF L_Transport_Valid THEN
    GVL_TRANSPORT_FRESHNESS.Transport_Epoch := GVL_TRANSPORT_FRESHNESS.Transport_Epoch + 1;
    GVL_TRANSPORT_FRESHNESS.Transport_Publication_Epoch := GVL_TRANSPORT_FRESHNESS.Transport_Publication_Epoch + 1;

    GVL_TRANSPORT_FRESHNESS.Transport_Freshness_Valid := TRUE;
    GVL_TRANSPORT_FRESHNESS.Transport_Publication_Allowed := TRUE;

    GVL_TRANSPORT_FRESHNESS.Transport_Lease_Valid := TRUE;
    GVL_TRANSPORT_FRESHNESS.Transport_Lease_Expired := FALSE;

    GVL_TRANSPORT_FRESHNESS.Transport_Quarantine_Active := FALSE;

    GVL_TRANSPORT_FRESHNESS.Transport_Last_Refresh_MS := L_Now_MS;
    GVL_TRANSPORT_FRESHNESS.Transport_Last_Publication_MS := L_Now_MS;

    GVL_TRANSPORT_FRESHNESS.Transport_Last_Error_Code := 0;
    GVL_TRANSPORT_FRESHNESS.Transport_Last_Error_Text := '';
ELSE
    GVL_TRANSPORT_FRESHNESS.Transport_Freshness_Valid := FALSE;
    GVL_TRANSPORT_FRESHNESS.Transport_Publication_Allowed := FALSE;

    GVL_TRANSPORT_FRESHNESS.Transport_Snapshot_Invalid := TRUE;

    GVL_TRANSPORT_FRESHNESS.Transport_Last_Error_Code := L_Error_Code;
    GVL_TRANSPORT_FRESHNESS.Transport_Last_Error_Text := L_Error_Text;

    GVL_TRANSPORT_FRESHNESS.Transport_Invalidation_Count := GVL_TRANSPORT_FRESHNESS.Transport_Invalidation_Count + 1;
END_IF;
END_PROGRAM
