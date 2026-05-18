FUNCTION_BLOCK FB_Runtime_Bus_Replication
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_Frame : ST_Runtime_Bus_Frame;
    L_TX_Index : UINT;

    L_Finalized_Runtime_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Runtime_Bus.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

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

L_TX_Index := UDINT_TO_UINT(GVL_Runtime_Bus.G_Last_Sequence_Id + 1);

IF L_TX_Index > 128 THEN
    L_TX_Index := 1;
END_IF;

L_Frame.Frame_Valid := TRUE;

L_Frame.Frame_Time_MS := VI_System_Time_MS;
L_Frame.Frame_Id := GVL_Runtime_Bus.G_Last_Frame_Id + 1;

L_Frame.Source_Controller_Id :=
    GVL_Distributed_Runtime.G_Local_Node_State.Controller_Id;

L_Frame.Source_Runtime_Node_Id :=
    GVL_Distributed_Runtime.G_Local_Node_State.Runtime_Node_Id;

L_Frame.Frame_Sequence_Id :=
    GVL_Runtime_Bus.G_Last_Sequence_Id + 1;

L_Frame.Frame_Ack_Required := TRUE;

L_Frame.Authority_State_Frame := TRUE;
L_Frame.Recovery_State_Frame := TRUE;
L_Frame.Quarantine_State_Frame := TRUE;
L_Frame.Topology_State_Frame := TRUE;
L_Frame.Binding_State_Frame := TRUE;
L_Frame.Predictive_State_Frame := TRUE;

IF GVL_Distributed_Authority.G_Distributed_Safety_Barrier_OK
   AND NOT GVL_Distributed_Runtime.G_Split_Brain_Suspected
   AND L_Finalized_Runtime_Continuity THEN

    L_Frame.Replication_Consistent := TRUE;

    L_Frame.Status_Code := 0;
    L_Frame.Status_Text :=
        'Deterministic replication frame accepted';

ELSE

    L_Frame.Replication_Rejected := TRUE;

    L_Frame.Status_Code := 2;
    L_Frame.Status_Text :=
        'Deterministic replication frame rejected';

END_IF;

GVL_Runtime_Bus.G_TX_Frames[L_TX_Index] := L_Frame;

GVL_Runtime_Bus.G_Last_Frame_Id :=
    L_Frame.Frame_Id;

GVL_Runtime_Bus.G_Last_Sequence_Id :=
    L_Frame.Frame_Sequence_Id;

GVL_Runtime_Bus.G_TX_Healthy :=
    L_Frame.Replication_Consistent;

GVL_Runtime_Bus.G_RX_Healthy := TRUE;

GVL_Runtime_Bus.G_Any_Replication_Rejected :=
    L_Frame.Replication_Rejected;

GVL_Runtime_Bus.G_Runtime_Valid := TRUE;
GVL_Runtime_Bus.G_Last_Update_MS := VI_System_Time_MS;

IF L_Frame.Replication_Rejected THEN
    GVL_Runtime_Bus.G_Status_Code := 2;
    GVL_Runtime_Bus.G_Status_Text :=
        'Runtime bus replication rejected';
ELSE
    GVL_Runtime_Bus.G_Status_Code := 0;
    GVL_Runtime_Bus.G_Status_Text :=
        'Runtime bus replication healthy';
END_IF;

END_FUNCTION_BLOCK