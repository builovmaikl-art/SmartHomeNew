PROGRAM PRG_Semantic_Progress_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Semantic_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Semantic_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// SEMANTIC PROGRESS GOVERNOR
// ======================================================
// Governs semantic execution continuity foundation.
// Visibility/publication continuity only.
// Does not invalidate runtime barrier,
// PLC fencing, immutable snapshots or IO authority.
// ======================================================

GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired := FALSE;

// ------------------------------------------------------
// Semantic execution continuity projection.
// ------------------------------------------------------

GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter :=
    GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter + 1;

// ------------------------------------------------------
// Replay suspicion foundation.
// ------------------------------------------------------

IF GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter
<= GVL_SEMANTIC_PROGRESS.Semantic_Last_Execution_Counter THEN
    GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := TRUE;

    L_Semantic_Valid := FALSE;
    L_Error_Code := 17000;
    L_Error_Text := 'Semantic replay suspected';
END_IF;

// ------------------------------------------------------
// Lease freshness validation.
// ------------------------------------------------------

L_Delta_MS :=
    L_Now_MS - GVL_SEMANTIC_PROGRESS.Semantic_Progress_Last_Update_MS;

IF L_Semantic_Valid
AND GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Active THEN
    IF L_Delta_MS > GVL_SEMANTIC_PROGRESS.Semantic_Progress_Timeout_MS THEN
        GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired := TRUE;
        GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected := TRUE;

        L_Semantic_Valid := FALSE;
        L_Error_Code := 17001;
        L_Error_Text := 'Semantic progress lease expired';
    END_IF;
END_IF;

// ------------------------------------------------------
// Semantic stagnation detection foundation.
// ------------------------------------------------------

IF L_Semantic_Valid THEN
    IF GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter
    = GVL_SEMANTIC_PROGRESS.Semantic_Last_Execution_Counter THEN
        GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected := TRUE;
        GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected := TRUE;

        L_Semantic_Valid := FALSE;
        L_Error_Code := 17002;
        L_Error_Text := 'Semantic execution stagnation detected';
    END_IF;
END_IF;

// ------------------------------------------------------
// Publish semantic continuity foundation.
// ------------------------------------------------------

IF L_Semantic_Valid THEN
    GVL_SEMANTIC_PROGRESS.Semantic_Progress_Epoch :=
        GVL_SEMANTIC_PROGRESS.Semantic_Progress_Epoch + 1;

    GVL_SEMANTIC_PROGRESS.Semantic_Continuity_Epoch :=
        GVL_SEMANTIC_PROGRESS.Semantic_Continuity_Epoch + 1;

    GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid := TRUE;
    GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK := TRUE;

    GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Active := TRUE;
    GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired := FALSE;
    GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active := FALSE;

    GVL_SEMANTIC_PROGRESS.Semantic_Last_Execution_Counter :=
        GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter;

    GVL_SEMANTIC_PROGRESS.Semantic_Progress_Last_Update_MS := L_Now_MS;

    GVL_SEMANTIC_PROGRESS.Semantic_Last_Error_Code := 0;
    GVL_SEMANTIC_PROGRESS.Semantic_Last_Error_Text := '';
ELSE
    GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid := FALSE;
    GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK := FALSE;

    GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active := TRUE;

    GVL_SEMANTIC_PROGRESS.Semantic_Last_Error_Code := L_Error_Code;
    GVL_SEMANTIC_PROGRESS.Semantic_Last_Error_Text := L_Error_Text;

    GVL_SEMANTIC_PROGRESS.Semantic_Invalidation_Count :=
        GVL_SEMANTIC_PROGRESS.Semantic_Invalidation_Count + 1;
END_IF;
END_PROGRAM
