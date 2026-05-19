FUNCTION_BLOCK FB_Distributed_Execution_Gates_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Allow : BOOL;
    L_Observer_Only : BOOL;

    L_Semantic_Continuity_Valid : BOOL;
    L_Finalized_Publication_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Execution_Gates.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

// Observer-only runtime semantics.
// Observer nodes may:
//   - observe runtime state;
//   - receive publications;
//   - participate in diagnostics.
//
// Observer nodes must NEVER:
//   - execute orchestration;
//   - own projections;
//   - execute recovery;
//   - publish physical outputs.
L_Observer_Only :=
    GVL_Distributed_Authority.G_Authority_State.Authority_Observer_Only;

// Semantic continuity authority.
L_Semantic_Continuity_Valid :=
    GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid
    AND GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected;

// Finalized publication proof chain.
L_Finalized_Publication_Continuity :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen
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

L_Allow :=
    NOT GVL_Cluster_Safety_Barrier.G_Cluster_Execution_Blocked
    AND GVL_Distributed_Authority.G_Authority_State.Authority_Master_Elected
    AND NOT GVL_Distributed_Runtime.G_Split_Brain_Suspected
    AND NOT GVL_Distributed_Projection_Ownership.G_Any_Ownership_Conflict
    AND NOT GVL_Runtime_Sessions.G_Any_Stale_Session
    AND L_Semantic_Continuity_Valid
    AND L_Finalized_Publication_Continuity
    AND NOT L_Observer_Only;

GVL_Distributed_Execution_Gates.G_Can_Replicate :=
    GVL_Runtime_Bus.G_TX_Healthy
    AND GVL_Runtime_Bus.G_RX_Healthy;

GVL_Distributed_Execution_Gates.G_Can_Execute :=
    L_Allow;

GVL_Distributed_Execution_Gates.G_Can_Orchestrate :=
    L_Allow
    AND GVL_Distributed_Orchestration.G_Distributed_Scheduler_Healthy;

GVL_Distributed_Execution_Gates.G_Can_Recover :=
    L_Allow
    AND NOT GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked;

GVL_Distributed_Execution_Gates.G_Can_Rollback :=
    L_Allow
    AND NOT GVL_Distributed_Recovery_Lock.G_Rollback_Execution_Blocked;

GVL_Distributed_Execution_Gates.G_Can_Own_Projection :=
    L_Allow
    AND NOT GVL_Distributed_Projection_Ownership.G_Any_Projection_Blocked;

GVL_Distributed_Execution_Gates.G_Runtime_Valid := TRUE;
GVL_Distributed_Execution_Gates.G_Last_Update_MS :=
    VI_System_Time_MS;

IF L_Observer_Only THEN

    GVL_Distributed_Execution_Gates.G_Status_Code := 2;
    GVL_Distributed_Execution_Gates.G_Status_Text :=
        'Distributed runtime observer-only';

ELSIF L_Allow THEN

    GVL_Distributed_Execution_Gates.G_Status_Code := 0;
    GVL_Distributed_Execution_Gates.G_Status_Text :=
        'Distributed execution gates open';

ELSE

    GVL_Distributed_Execution_Gates.G_Status_Code := 1;
    GVL_Distributed_Execution_Gates.G_Status_Text :=
        'Distributed execution gates restricted';

END_IF;

END_FUNCTION_BLOCK