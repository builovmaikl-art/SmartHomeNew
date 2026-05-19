FUNCTION_BLOCK FB_Distributed_Runtime_Continuity
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Node : ST_Distributed_Runtime_Node_State;

    L_Any_Offline : BOOL;
    L_Any_Degraded : BOOL;
    L_Split_Brain : BOOL;

    L_Finalized_Runtime_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Distributed_Runtime.G_Runtime_Valid := FALSE;
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

// Local node authoritative runtime state.
GVL_Distributed_Runtime.G_Local_Node_State.Runtime_Valid := TRUE;
GVL_Distributed_Runtime.G_Local_Node_State.Runtime_System_Time_MS :=
    VI_System_Time_MS;

GVL_Distributed_Runtime.G_Local_Node_State.Node_Online :=
    L_Finalized_Runtime_Continuity;

GVL_Distributed_Runtime.G_Local_Node_State.Restart_Continuity_Valid :=
    GVL_Runtime_Restart_Continuity.G_Runtime_Valid
    AND L_Finalized_Runtime_Continuity;

GVL_Distributed_Runtime.G_Local_Node_State.Quarantine_State_Replicated :=
    NOT GVL_Config_Activation.G_Config_Quarantine_Active
    AND L_Finalized_Runtime_Continuity;

GVL_Distributed_Runtime.G_Local_Node_State.Recovery_State_Replicated :=
    GVL_Water_Recovery_Runtime.G_Runtime_Valid
    AND L_Finalized_Runtime_Continuity;

GVL_Distributed_Runtime.G_Local_Node_State.Authority_Allowed :=
    NOT GVL_COMMAND_VERIFY.PreOutput_Block_IO
    AND L_Finalized_Runtime_Continuity;

GVL_Distributed_Runtime.G_Local_Node_State.Replication_Healthy :=
    L_Finalized_Runtime_Continuity;

FOR L_i := 1 TO 8 DO

    L_Node := GVL_Distributed_Runtime.G_Remote_Node_State[L_i];

    IF L_Node.Runtime_Valid THEN

        IF NOT L_Node.Node_Online THEN
            L_Any_Offline := TRUE;
        END_IF;

        IF L_Node.Node_Degraded
           OR L_Node.Node_Quarantined THEN

            L_Any_Degraded := TRUE;

        END_IF;

        IF L_Node.Authority_Master
           AND GVL_Distributed_Runtime.G_Local_Node_State.Authority_Master THEN

            L_Split_Brain := TRUE;

        END_IF;

    END_IF;

END_FOR;

IF NOT L_Finalized_Runtime_Continuity THEN
    L_Any_Degraded := TRUE;
END_IF;

GVL_Distributed_Runtime.G_Any_Remote_Node_Offline :=
    L_Any_Offline;

GVL_Distributed_Runtime.G_Any_Remote_Node_Degraded :=
    L_Any_Degraded;

GVL_Distributed_Runtime.G_Split_Brain_Suspected :=
    L_Split_Brain;

GVL_Distributed_Runtime.G_Distributed_Replication_Healthy :=
    NOT L_Any_Offline
    AND L_Finalized_Runtime_Continuity;

GVL_Distributed_Runtime.G_Distributed_Authority_Healthy :=
    NOT L_Split_Brain
    AND L_Finalized_Runtime_Continuity;

GVL_Distributed_Runtime.G_Runtime_Valid := TRUE;
GVL_Distributed_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF NOT L_Finalized_Runtime_Continuity THEN
    GVL_Distributed_Runtime.G_Status_Code := 4;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed finalized continuity invalid';
ELSIF L_Split_Brain THEN
    GVL_Distributed_Runtime.G_Status_Code := 3;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed split-brain suspected';
ELSIF L_Any_Degraded THEN
    GVL_Distributed_Runtime.G_Status_Code := 2;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed degraded node detected';
ELSIF L_Any_Offline THEN
    GVL_Distributed_Runtime.G_Status_Code := 1;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed offline node detected';
ELSE
    GVL_Distributed_Runtime.G_Status_Code := 0;
    GVL_Distributed_Runtime.G_Status_Text :=
        'Distributed runtime continuity healthy';
END_IF;

END_FUNCTION_BLOCK