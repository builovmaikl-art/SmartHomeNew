FUNCTION_BLOCK FB_Cluster_Runtime_FSM
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Finalized_Runtime_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Cluster_Runtime_FSM.G_Runtime_Valid := FALSE;
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

// Reset runtime states.
GVL_Cluster_Runtime_FSM.G_State_Startup := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Discovery := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Synchronization := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Operational := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Degraded := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Observer_Only := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Recovery_Lock := FALSE;
GVL_Cluster_Runtime_FSM.G_State_Quarantine := FALSE;

// Startup state.
IF NOT GVL_Distributed_Runtime.G_Runtime_Valid THEN

    GVL_Cluster_Runtime_FSM.G_State_Startup := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 1;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime startup';

ELSIF GVL_Runtime_Discovery.G_Runtime_Valid
   AND NOT GVL_Runtime_Discovery.G_Any_Discovery_Rejected THEN

    GVL_Cluster_Runtime_FSM.G_State_Discovery := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 2;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime discovery';

END_IF;

// Synchronization state.
IF GVL_Runtime_Bus.G_TX_Healthy
   AND GVL_Runtime_Bus.G_RX_Healthy THEN

    GVL_Cluster_Runtime_FSM.G_State_Synchronization := TRUE;

END_IF;

// Operational state.
IF GVL_Distributed_Execution_Gates.G_Can_Execute
   AND GVL_Distributed_Execution_Gates.G_Can_Orchestrate
   AND L_Finalized_Runtime_Continuity THEN

    GVL_Cluster_Runtime_FSM.G_State_Operational := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 0;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime operational';

END_IF;

// Degraded state.
IF GVL_Cluster_Safety_Barrier.G_Cluster_Execution_Blocked THEN

    GVL_Cluster_Runtime_FSM.G_State_Degraded := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 10;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime degraded';

END_IF;

// Observer-only state.
IF GVL_Distributed_Authority.G_Authority_State.Authority_Observer_Only THEN

    GVL_Cluster_Runtime_FSM.G_State_Observer_Only := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 11;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime observer-only';

END_IF;

// Recovery lock state.
IF GVL_Distributed_Recovery_Lock.G_Recovery_Execution_Blocked THEN

    GVL_Cluster_Runtime_FSM.G_State_Recovery_Lock := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 12;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime recovery-locked';

END_IF;

// Quarantine state.
IF GVL_Runtime_Discovery.G_Any_Node_Quarantined THEN

    GVL_Cluster_Runtime_FSM.G_State_Quarantine := TRUE;

    GVL_Cluster_Runtime_FSM.G_Status_Code := 13;
    GVL_Cluster_Runtime_FSM.G_Status_Text :=
        'Cluster runtime quarantined';

END_IF;

GVL_Cluster_Runtime_FSM.G_Runtime_Valid := TRUE;
GVL_Cluster_Runtime_FSM.G_Last_Update_MS := VI_System_Time_MS;

END_FUNCTION_BLOCK