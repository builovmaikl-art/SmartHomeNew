PROGRAM PRG_Runtime_Snapshot_Governor
VAR
    L_Now_MS : UDINT;
    L_Snapshot_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Snapshot_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// IMMUTABLE RUNTIME SNAPSHOT GOVERNOR
// ======================================================
// Governs immutable publication snapshot semantics.
// Prevents mutable runtime publication leakage.
//
// Runtime snapshot is upstream of output freshness.
// It must not depend on downstream output decay state.
// ======================================================

GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected := FALSE;
GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed := FALSE;
GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen := FALSE;

// ------------------------------------------------------
// Runtime authority linkage.
// ------------------------------------------------------

IF NOT GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK THEN
    L_Snapshot_Valid := FALSE;
    L_Error_Code := 12000;
    L_Error_Text := 'Runtime authority invalid';
END_IF;

// ------------------------------------------------------
// Mutation detection foundation.
// ------------------------------------------------------

IF L_Snapshot_Valid
AND GVL_RUNTIME_EPOCH.Runtime_Impossible_State_Detected
THEN
    L_Snapshot_Valid := FALSE;
    L_Error_Code := 12003;
    L_Error_Text := 'Runtime mutation anomaly detected';

    GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected := TRUE;
END_IF;

// ------------------------------------------------------
// Immutable snapshot freeze semantics.
// ------------------------------------------------------

IF L_Snapshot_Valid THEN
    GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen := TRUE;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed := TRUE;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid := TRUE;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid := TRUE;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Runtime_Authority_Valid := TRUE;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Freeze_Start_MS := L_Now_MS;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Last_Publication_MS := L_Now_MS;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch := GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch + 1;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Epoch := GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Epoch + 1;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Last_Error_Code := 0;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Last_Error_Text := '';
ELSE
    GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen := FALSE;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed := FALSE;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid := FALSE;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid := FALSE;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Runtime_Authority_Valid := FALSE;

    GVL_RUNTIME_SNAPSHOT.Snapshot_Last_Error_Code := L_Error_Code;
    GVL_RUNTIME_SNAPSHOT.Snapshot_Last_Error_Text := L_Error_Text;
END_IF;
END_PROGRAM
