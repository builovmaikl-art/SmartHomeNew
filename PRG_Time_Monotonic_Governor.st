PROGRAM PRG_Time_Monotonic_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Time_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Time_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// MONOTONIC TIME GOVERNOR
// ======================================================
// Creates monotonic time authority semantics.
// Prevents rollback/reboot resurrection.
// ======================================================

// First initialization.
IF NOT GVL_TIME_MONOTONIC.Monotonic_Time_Initialized THEN
    GVL_TIME_MONOTONIC.Monotonic_Time_Initialized := TRUE;
    GVL_TIME_MONOTONIC.Boot_Generation_ID := GVL_TIME_MONOTONIC.Boot_Generation_ID + 1;
    GVL_TIME_MONOTONIC.Startup_Quarantine_Active := TRUE;
    GVL_TIME_MONOTONIC.Startup_Quarantine_Start_MS := L_Now_MS;
    GVL_TIME_MONOTONIC.Last_Monotonic_Time_MS := L_Now_MS;
END_IF;

GVL_TIME_MONOTONIC.Time_Rollback_Detected := FALSE;
GVL_TIME_MONOTONIC.Time_Overflow_Detected := FALSE;
GVL_TIME_MONOTONIC.Retained_Time_Invalid := FALSE;
GVL_TIME_MONOTONIC.Startup_Quarantine_Release_Allowed := FALSE;

// Rollback detection.
IF L_Now_MS < GVL_TIME_MONOTONIC.Last_Monotonic_Time_MS THEN
    L_Time_Valid := FALSE;
    L_Error_Code := 8000;
    L_Error_Text := 'Monotonic rollback detected';

    GVL_TIME_MONOTONIC.Time_Rollback_Detected := TRUE;
    GVL_TIME_MONOTONIC.Retained_Time_Invalid := TRUE;
END_IF;

// Overflow / invalid delta detection.
L_Delta_MS := L_Now_MS - GVL_TIME_MONOTONIC.Last_Monotonic_Time_MS;

IF L_Time_Valid AND (L_Delta_MS > 60000) THEN
    L_Time_Valid := FALSE;
    L_Error_Code := 8001;
    L_Error_Text := 'Monotonic delta overflow';

    GVL_TIME_MONOTONIC.Time_Overflow_Detected := TRUE;
END_IF;

// Startup quarantine governance.
IF GVL_TIME_MONOTONIC.Startup_Quarantine_Active THEN
    IF (L_Now_MS - GVL_TIME_MONOTONIC.Startup_Quarantine_Start_MS) >= GVL_TIME_MONOTONIC.Startup_Quarantine_Timeout_MS THEN
        GVL_TIME_MONOTONIC.Startup_Quarantine_Active := FALSE;
        GVL_TIME_MONOTONIC.Startup_Quarantine_Release_Allowed := TRUE;
    ELSE
        L_Time_Valid := FALSE;

        IF L_Error_Code = 0 THEN
            L_Error_Code := 8002;
            L_Error_Text := 'Startup quarantine active';
        END_IF;
    END_IF;
END_IF;

// Publish monotonic authority state.
IF L_Time_Valid THEN
    GVL_TIME_MONOTONIC.Monotonic_Epoch := GVL_TIME_MONOTONIC.Monotonic_Epoch + 1;
    GVL_TIME_MONOTONIC.Monotonic_Time_Valid := TRUE;
    GVL_TIME_MONOTONIC.Last_Validated_Time_MS := L_Now_MS;
    GVL_TIME_MONOTONIC.Last_Monotonic_Time_MS := L_Now_MS;

    GVL_TIME_MONOTONIC.Monotonic_Last_Error_Code := 0;
    GVL_TIME_MONOTONIC.Monotonic_Last_Error_Text := '';
ELSE
    GVL_TIME_MONOTONIC.Monotonic_Time_Valid := FALSE;
    GVL_TIME_MONOTONIC.Monotonic_Last_Error_Code := L_Error_Code;
    GVL_TIME_MONOTONIC.Monotonic_Last_Error_Text := L_Error_Text;

    GVL_TIME_MONOTONIC.Monotonic_Invalidation_Count := GVL_TIME_MONOTONIC.Monotonic_Invalidation_Count + 1;
END_IF;
END_PROGRAM
