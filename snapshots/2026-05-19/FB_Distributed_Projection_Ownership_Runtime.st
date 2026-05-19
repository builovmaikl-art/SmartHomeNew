FUNCTION_BLOCK FB_Distributed_Projection_Ownership_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Ownership : ST_Distributed_Projection_Ownership;

    L_Any_Conflict : BOOL;
    L_Any_Stale : BOOL;
    L_Any_Blocked : BOOL;

    L_Finalized_Runtime_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Projection_Ownership.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

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

FOR L_i := 1 TO 128 DO

    L_Ownership :=
        GVL_Distributed_Projection_Ownership.G_Projection_Ownership[L_i];

    IF L_Ownership.Ownership_Valid THEN

        L_Ownership.Runtime_System_Time_MS :=
            VI_System_Time_MS;

        // Ownership becomes stale if runtime sessions unhealthy.
        IF GVL_Runtime_Sessions.G_Any_Stale_Session THEN

            L_Ownership.Ownership_Stale := TRUE;
            L_Any_Stale := TRUE;

        END_IF;

        // Finalized continuity loss invalidates ownership.
        IF NOT L_Finalized_Runtime_Continuity THEN

            L_Ownership.Ownership_Stale := TRUE;
            L_Ownership.Projection_Blocked := TRUE;

            L_Any_Stale := TRUE;
            L_Any_Blocked := TRUE;

        END_IF;

        // Hard conflict prevention.
        IF GVL_Distributed_Runtime.G_Split_Brain_Suspected THEN

            L_Ownership.Ownership_Conflict := TRUE;
            L_Ownership.Projection_Blocked := TRUE;

            L_Any_Conflict := TRUE;
            L_Any_Blocked := TRUE;

        END_IF;

        // Distributed execution authority.
        IF GVL_Distributed_Authority.G_Authority_State.Authority_Master_Elected
           AND NOT L_Ownership.Ownership_Conflict
           AND NOT L_Ownership.Ownership_Stale
           AND L_Finalized_Runtime_Continuity THEN

            L_Ownership.Ownership_Granted := TRUE;
            L_Ownership.Distributed_Execution_Allowed := TRUE;
            L_Ownership.Distributed_Recovery_Allowed := TRUE;

            L_Ownership.Status_Code := 0;
            L_Ownership.Status_Text :=
                'Distributed projection ownership granted';

        ELSE

            L_Ownership.Ownership_Revoked := TRUE;
            L_Ownership.Projection_Blocked := TRUE;

            L_Any_Blocked := TRUE;

            L_Ownership.Status_Code := 2;
            L_Ownership.Status_Text :=
                'Distributed projection ownership blocked';

        END_IF;

        GVL_Distributed_Projection_Ownership.G_Projection_Ownership[L_i] :=
            L_Ownership;

    END_IF;

END_FOR;

GVL_Distributed_Projection_Ownership.G_Any_Ownership_Conflict :=
    L_Any_Conflict;

GVL_Distributed_Projection_Ownership.G_Any_Ownership_Stale :=
    L_Any_Stale;

GVL_Distributed_Projection_Ownership.G_Any_Projection_Blocked :=
    L_Any_Blocked;

GVL_Distributed_Projection_Ownership.G_Runtime_Valid := TRUE;
GVL_Distributed_Projection_Ownership.G_Last_Update_MS :=
    VI_System_Time_MS;

IF L_Any_Conflict THEN
    GVL_Distributed_Projection_Ownership.G_Status_Code := 3;
    GVL_Distributed_Projection_Ownership.G_Status_Text :=
        'Distributed projection ownership conflict detected';
ELSIF L_Any_Stale THEN
    GVL_Distributed_Projection_Ownership.G_Status_Code := 2;
    GVL_Distributed_Projection_Ownership.G_Status_Text :=
        'Distributed projection ownership stale';
ELSIF L_Any_Blocked THEN
    GVL_Distributed_Projection_Ownership.G_Status_Code := 1;
    GVL_Distributed_Projection_Ownership.G_Status_Text :=
        'Distributed projection ownership blocked';
ELSE
    GVL_Distributed_Projection_Ownership.G_Status_Code := 0;
    GVL_Distributed_Projection_Ownership.G_Status_Text :=
        'Distributed projection ownership healthy';
END_IF;

END_FUNCTION_BLOCK