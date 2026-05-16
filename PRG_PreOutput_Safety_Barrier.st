PROGRAM PRG_PreOutput_Safety_Barrier
VAR
    L_i : INT;
    L_Now_MS : UDINT;
    L_Block_IO : BOOL := FALSE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
    L_Any_Manifold_Pump_On : BOOL := FALSE;
    L_Prev_Block_IO : BOOL;

    L_Selective_Projection_Active : BOOL;
    L_Global_Fallback_Active : BOOL;
    L_Runtime_Projection_Healthy : BOOL;

    L_Finalized_Publication_Continuity : BOOL;
    L_Physical_Causality_Healthy : BOOL;

    fbLog : FB_LogEvent;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Block_IO := FALSE;
L_Error_Code := 0;
L_Error_Text := '';
L_Any_Manifold_Pump_On := FALSE;
L_Prev_Block_IO := GVL_COMMAND_VERIFY.PreOutput_Block_IO;

L_Selective_Projection_Active :=
    GVL_Water_Isolation_Authority.G_Any_Selective_Authority_Allowed;

L_Global_Fallback_Active :=
    GVL_Water_Isolation_Authority.G_Any_Global_Fallback_Required;

L_Runtime_Projection_Healthy :=
    GVL_Water_Output_Reconciliation.G_Runtime_Valid
    AND NOT GVL_Water_Output_Reconciliation.G_Any_Conflict_Detected;

// Physical causality evidence.
// Introduces mandatory telemetry acknowledgment layer.
L_Physical_Causality_Healthy :=
    GVL_TELEMETRY.Telemetry_Runtime_Valid
    AND GVL_TELEMETRY.Telemetry_Freshness_Valid
    AND NOT GVL_TELEMETRY.Telemetry_Lease_Expired
    AND NOT GVL_TELEMETRY.Telemetry_Quarantine_Active
    AND GVL_TELEMETRY.Command_Telemetry_Causality_Valid
    AND NOT GVL_TELEMETRY.Command_Telemetry_Divergence_Detected
    AND GVL_TELEMETRY.Actuator_Feedback_Valid
    AND GVL_TELEMETRY.Actuator_Feedback_Fresh
    AND GVL_TELEMETRY.Physical_Effect_Confirmed;

// Finalized publication continuity proof chain.
L_Finalized_Publication_Continuity :=
    GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid
    AND GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected
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
    AND NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active
    AND NOT GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired
    AND GVL_OUTPUT_EPOCH.Output_Publication_Valid
    AND GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid
    AND NOT GVL_OUTPUT_EPOCH.Output_Lease_Expired
    AND NOT GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay;

IF (NOT L_Block_IO)
   AND (NOT L_Finalized_Publication_Continuity) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 3999;
    L_Error_Text := 'PreOutput finalized publication continuity invalid';
END_IF;

IF (NOT L_Block_IO)
   AND (NOT L_Physical_Causality_Healthy) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 3998;
    L_Error_Text := 'Physical causality evidence invalid';
END_IF;

IF (NOT L_Block_IO) AND (NOT GVL_STATUS.G_Is_Active_PLC) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 4000;
    L_Error_Text := 'PreOutput inactive PLC';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Gas_Valve_Close <> GVL_COMMAND_SHADOW.G_Gas_Valve_Close) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 4001;
    L_Error_Text := 'PreOutput gas command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Boiler_Stop <> GVL_COMMAND_SHADOW.G_Boiler_Stop) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 4002;
    L_Error_Text := 'PreOutput boiler command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Vent_Stop <> GVL_COMMAND_SHADOW.G_Vent_Stop) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 4003;
    L_Error_Text := 'PreOutput vent command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Close_Valve_35 <> GVL_COMMAND_SHADOW.G_Close_Valve_35) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 4004;
    L_Error_Text := 'PreOutput valve 35 command mismatch';
END_IF;

IF (NOT L_Block_IO)
   AND (GVL_COMMAND.G_Close_Valve_36 <> GVL_COMMAND_SHADOW.G_Close_Valve_36) THEN
    L_Block_IO := TRUE;
    L_Error_Code := 4005;
    L_Error_Text := 'PreOutput valve 36 command mismatch';
END_IF;

GVL_COMMAND_VERIFY.PreOutput_Physical_Causality_Valid :=
    L_Physical_Causality_Healthy;

GVL_COMMAND_VERIFY.PreOutput_Barrier_OK := NOT L_Block_IO;
GVL_COMMAND_VERIFY.PreOutput_Block_IO := L_Block_IO;
GVL_COMMAND_VERIFY.PreOutput_Last_Error_Code := L_Error_Code;
GVL_COMMAND_VERIFY.PreOutput_Last_Error_Text := L_Error_Text;

IF L_Block_IO THEN
    GVL_COMMAND_VERIFY.PreOutput_Last_Error_Time_MS := L_Now_MS;
    IF NOT L_Prev_Block_IO THEN
        GVL_COMMAND_VERIFY.PreOutput_Block_Count :=
            GVL_COMMAND_VERIFY.PreOutput_Block_Count + 1;
        fbLog(
            VI_Event_Type := 1002,
            VI_Timestamp := L_Now_MS,
            VI_Param1 := L_Error_Code,
            VI_Param2 := GVL_COMMAND_VERIFY.PreOutput_Block_Count
        );
    END_IF;
END_IF;

END_PROGRAM