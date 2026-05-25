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
    L_Runtime_Snapshot_Skew : UDINT;
    L_Runtime_Commit_Skew : UDINT;
    L_Runtime_Output_Skew : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Semantic_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Phase_Stall_Detected := FALSE;
GVL_SEMANTIC_PROGRESS.Semantic_Output_Stall_Detected := FALSE;

GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Barrier_Epoch := ULINT_TO_UDINT(GVL_RUNTIME_EPOCH.Runtime_Epoch);
GVL_SEMANTIC_PROGRESS.Semantic_Runtime_Snapshot_Epoch := ULINT_TO_UDINT(GVL_RUNTIME_SNAPSHOT.Snapshot_Epoch);
GVL_SEMANTIC_PROGRESS.Semantic_Distributed_Commit_Epoch := ULINT_TO_UDINT(GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Epoch);
GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Epoch := ULINT_TO_UDINT(GVL_OUTPUT_EPOCH.Output_Publication_Epoch);

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
    GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Valid AND
    GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed AND
    NOT GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch AND
    NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active AND
    NOT GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired;

GVL_SEMANTIC_PROGRESS.Semantic_Output_Publication_Evidence_OK :=
    GVL_OUTPUT_EPOCH.Output_Publication_Valid AND
    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid AND
    NOT GVL_OUTPUT_EPOCH.Output_Lease_Expired AND
    NOT GVL_OUTPUT_EPOCH.Output_Stale_Detected AND
    NOT GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay;

END_PROGRAM