FUNCTION_BLOCK FB_Distributed_Recovery_Lock_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Lock : ST_Distributed_Recovery_Lock;
    L_Finalized_Runtime_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Recovery_Lock.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Lock := GVL_Distributed_Recovery_Lock.G_Recovery_Lock;

L_Lock.Runtime_System_Time_MS := VI_System_Time_MS;
L_Lock.Lock_Valid := TRUE;

// Finalized runtime continuity proof chain.
L_Finalized_Runtime_Continuity :=
    GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid
    AND GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid
    AND NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent
    AND GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid
    AND GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Valid
    AND GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed
    AND NOT GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch
    AND NOT GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired
    AND GVL_OUTPUT_EPOCH.Output_Publication_Valid
    AND GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid
    AND NOT GVL_OUTPUT_EPOCH.Output_Lease_Expired
    AND NOT GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay
    AND GVL_COMMAND_VERIFY.PreOutput_Barrier_OK
    AND NOT GVL_COMMAND_VERIFY.PreOutput_Block_IO;

// Cluster-exclusive recovery execution lock.
IF GVL_Distributed_Runtime.G_Split_Brain_Suspected
   OR GVL_Distributed_Projection_Ownership.G_Any_Ownership_Conflict
   OR GVL_Runtime_Sessions.G_Any_Stale_Session
   OR NOT L_Finalized_Runtime_Continuity THEN

    L_Lock.Lock_Conflict := TRUE;
    L_Lock.Distributed_Execution_Allowed := FALSE;

    GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked := TRUE;
    GVL_Distributed_Recovery_Lock.G_Rollback_Execution_Blocked := TRUE;
    GVL_Distributed_Recovery_Lock.G_Reopen_Execution_Blocked := TRUE;

    L_Lock.Status_Code := 3;
    L_Lock.Status_Text :=
        'Distributed recovery execution locked';

ELSE

    L_Lock.Recovery_Lock_Active := TRUE;
    L_Lock.Distributed_Execution_Allowed := TRUE;

    GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked := FALSE;
    GVL_Distributed_Recovery_Lock.G_Rollback_Execution_Blocked := FALSE;
    GVL_Distributed_Recovery_Lock.G_Reopen_Execution_Blocked := FALSE;

    L_Lock.Status_Code := 0;
    L_Lock.Status_Text :=
        'Distributed recovery lock healthy';

END_IF;

GVL_Distributed_Recovery_Lock.G_Recovery_Lock := L_Lock;

GVL_Distributed_Recovery_Lock.G_Runtime_Valid := TRUE;
GVL_Distributed_Recovery_Lock.G_Last_Update_MS :=
    VI_System_Time_MS;

GVL_Distributed_Recovery_Lock.G_Status_Code :=
    L_Lock.Status_Code;

GVL_Distributed_Recovery_Lock.G_Status_Text :=
    L_Lock.Status_Text;

END_FUNCTION_BLOCK