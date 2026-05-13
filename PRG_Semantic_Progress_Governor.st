PROGRAM PRG_Semantic_Progress_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Semantic_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Runtime_Epoch_Advanced : BOOL := FALSE;
    L_Snapshot_Epoch_Advanced : BOOL := FALSE;
    L_Distributed_Commit_Epoch_Advanced : BOOL := FALSE;
    L_Output_Epoch_Advanced : BOOL := FALSE;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Semantic_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// SEMANTIC PROGRESS GOVERNOR
// ======================================================
// Governs semantic execution continuity foundation.
// Uses real runtime phase evidence rather than self-generated
// counter progress only.
//
// This layer remains advisory/escalation evidence only:
// it does not directly invalidate runtime barrier,
// PLC fencing, immutable snapshots or IO authority.
// ======================================================

GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Phase_Stall_Detected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Output_Stall_Detected := FALSE;

// ------------------------------------------------------
// Capture real phase evidence from upstream runtime layers.
// ------------------------------------------------------

GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Epoch :=
    GVL_RUNTIME_EPOCH.Runtime_Epoch;

GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Epoch :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch;

GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Epoch :=
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Epoch;

GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Epoch :=
    GVL_OUTPUT_EPOCH.Output_Publication_Epoch;

GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Evidence_OK :=
    GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK AND
    GVL_RUNTIME_EPOCH.Runtime_Snapshot_Published AND
    GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed;

GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Evidence_OK :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen AND
    GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed AND
    GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid AND
    GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid AND
    GVL_RUNTIME_SNAPSHOT.Snapshot_Runtime_Authority_Valid AND
    NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected;

GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Evidence_OK :=
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid AND
    NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active AND
    NOT GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired;

GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Evidence_OK :=
    GVL_OUTPUT_EPOCH.Output_Publication_Valid AND
    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid AND
    NOT GVL_OUTPUT_EPOCH.Output_Lease_Expired AND
    NOT GVL_OUTPUT_EPOCH.Output_Stale_Detected AND
    NOT GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay;

L_Runtime_Epoch_Advanced :=
    GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Epoch >
    GVL_SEMANTIC_PROGRESS.Semantic_Last_Runtime_Barrier_Epoch;

L_Snapshot_Epoch_Advanced :=
    GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Epoch >
    GVL_SEMANTIC_PROGRESS.Semantic_Last_Runtime_Snapshot_Epoch;

L_Distributed_Commit_Epoch_Advanced :=
    GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Epoch >
    GVL_SEMANTIC_PROGRESS.Semantic_Last_Distributed_Commit_Epoch;

L_Output_Epoch_Advanced :=
    GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Epoch >
    GVL_SEMANTIC_PROGRESS.Semantic_Last_Output_Publication_Epoch;

GVL_SEMANTIC_PROGRESS.Semantic_Phase_Evidence_OK :=
    GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Evidence_OK AND
    GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Evidence_OK AND
    GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Evidence_OK AND
    GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Evidence_OK;

// ------------------------------------------------------
// Replay / regression suspicion from real phase epochs.
// ------------------------------------------------------

IF GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Epoch <
GVL_SEMANTIC_PROGRESS.Semantic_Last_Runtime_Barrier_Epoch THEN
    GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := TRUE;
    L_Semantic_Valid := FALSE;
    L_Error_Code := 17010;
    L_Error_Text := 'Runtime barrier epoch replay suspected';
END_IF;

IF L_Semantic_Valid AND
(GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Epoch <
 GVL_SEMANTIC_PROGRESS.Semantic_Last_Runtime_Snapshot_Epoch) THEN
    GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := TRUE;
    L_Semantic_Valid := FALSE;
    L_Error_Code := 17011;
    L_Error_Text := 'Runtime snapshot epoch replay suspected';
END_IF;

IF L_Semantic_Valid AND
(GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Epoch <
 GVL_SEMANTIC_PROGRESS.Semantic_Last_Distributed_Commit_Epoch) THEN
    GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := TRUE;
    L_Semantic_Valid := FALSE;
    L_Error_Code := 17012;
    L_Error_Text := 'Distributed commit epoch replay suspected';
END_IF;

IF L_Semantic_Valid AND
(GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Epoch <
 GVL_SEMANTIC_PROGRESS.Semantic_Last_Output_Publication_Epoch) THEN
    GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := TRUE;
    L_Semantic_Valid := FALSE;
    L_Error_Code := 17013;
    L_Error_Text := 'Output publication epoch replay suspected';
END_IF;

// ------------------------------------------------------
// Required phase evidence validation.
// ------------------------------------------------------

IF L_Semantic_Valid AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Evidence_OK THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 17100;
    L_Error_Text := 'Runtime barrier evidence invalid';
END_IF;

IF L_Semantic_Valid AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Evidence_OK THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 17101;
    L_Error_Text := 'Runtime snapshot evidence invalid';
END_IF;

IF L_Semantic_Valid AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Evidence_OK THEN
    L_Semantic_Valid := FALSE;
    L_Error_Code := 17102;
    L_Error_Text := 'Distributed commit evidence invalid';
END_IF;

// Output evidence is evaluated as warning only here because this governor
// executes before PRG_Output_Freshness_Governor in MAIN. It is still tracked
// for stale output visibility using the previous completed cycle.
IF NOT GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Evidence_OK THEN
    GVL_SEMANTIC_PROGRESS.Semantic_Output_Stall_Detected := TRUE;
END_IF;

// ------------------------------------------------------
// Semantic phase advancement validation.
// ------------------------------------------------------

IF L_Semantic_Valid THEN
    IF NOT (L_Runtime_Epoch_Advanced OR L_Snapshot_Epoch_Advanced OR L_Distributed_Commit_Epoch_Advanced) THEN
        GVL_SEMANTIC_PROGRESS.Semantic_Phase_Stall_Detected := TRUE;
        GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected := TRUE;
        GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected := TRUE;

        L_Semantic_Valid := FALSE;
        L_Error_Code := 17200;
        L_Error_Text := 'Semantic phase evidence stalled';
    END_IF;
END_IF;

// ------------------------------------------------------
// Legacy self-counter continuity remains as secondary evidence.
// ------------------------------------------------------

GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter :=
    GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter + 1;

IF L_Semantic_Valid THEN
    IF GVL_SEMANTIC_PROGRESS.Semantic_Execution_Counter <=
    GVL_SEMANTIC_PROGRESS.Semantic_Last_Execution_Counter THEN
        GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := TRUE;

        L_Semantic_Valid := FALSE;
        L_Error_Code := 17000;
        L_Error_Text := 'Semantic execution counter replay suspected';
    END_IF;
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

    GVL_SEMANTIC_PROGRESS.Semantic_Last_Runtime_Barrier_Epoch :=
        GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Epoch;

    GVL_SEMANTIC_PROGRESS.Semantic_Last_Runtime_Snapshot_Epoch :=
        GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Epoch;

    GVL_SEMANTIC_PROGRESS.Semantic_Last_Distributed_Commit_Epoch :=
        GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Epoch;

    GVL_SEMANTIC_PROGRESS.Semantic_Last_Output_Publication_Epoch :=
        GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Epoch;

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
