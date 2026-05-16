FUNCTION_BLOCK FB_Runtime_Node_Discovery
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_State : ST_Runtime_Node_Discovery_State;

    L_Any_Quarantine : BOOL;
    L_Any_Rejected : BOOL;

    L_Finalized_Runtime_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Runtime_Discovery.G_Runtime_Valid := FALSE;
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

FOR L_i := 1 TO 32 DO

    L_State := GVL_Runtime_Discovery.G_Discovery_State[L_i];

    IF L_State.Discovery_Active THEN

        L_State.Runtime_Valid := TRUE;
        L_State.Runtime_System_Time_MS := VI_System_Time_MS;

        L_State.Node_Discovered := TRUE;

        IF GVL_Distributed_Authority.G_Distributed_Safety_Barrier_OK
           AND NOT GVL_Runtime_Sessions.G_Any_Stale_Session
           AND L_Finalized_Runtime_Continuity THEN

            L_State.Node_Validated := TRUE;
            L_State.Node_Authorized := TRUE;

            L_State.Capability_Validated := TRUE;
            L_State.Execution_Domain_Assigned := TRUE;
            L_State.Deployment_Assigned := TRUE;

            L_State.Status_Code := 0;
            L_State.Status_Text :=
                'Runtime node discovery healthy';

        ELSE

            L_State.Node_Quarantined := TRUE;
            L_State.Discovery_Rejected := TRUE;

            L_Any_Quarantine := TRUE;
            L_Any_Rejected := TRUE;

            L_State.Status_Code := 2;
            L_State.Status_Text :=
                'Runtime node discovery rejected';

        END_IF;

        GVL_Runtime_Discovery.G_Discovery_State[L_i] :=
            L_State;

    END_IF;

END_FOR;

GVL_Runtime_Discovery.G_Any_Node_Quarantined :=
    L_Any_Quarantine;

GVL_Runtime_Discovery.G_Any_Discovery_Rejected :=
    L_Any_Rejected;

GVL_Runtime_Discovery.G_Runtime_Valid := TRUE;
GVL_Runtime_Discovery.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Rejected THEN
    GVL_Runtime_Discovery.G_Status_Code := 2;
    GVL_Runtime_Discovery.G_Status_Text :=
        'Runtime discovery rejection detected';
ELSIF L_Any_Quarantine THEN
    GVL_Runtime_Discovery.G_Status_Code := 1;
    GVL_Runtime_Discovery.G_Status_Text :=
        'Runtime discovery quarantine active';
ELSE
    GVL_Runtime_Discovery.G_Status_Code := 0;
    GVL_Runtime_Discovery.G_Status_Text :=
        'Runtime discovery governance healthy';
END_IF;

END_FUNCTION_BLOCK