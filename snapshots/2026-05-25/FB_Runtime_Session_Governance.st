FUNCTION_BLOCK FB_Runtime_Session_Governance
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Session : ST_Runtime_Node_Session;
    L_Any_Stale : BOOL;
    L_Any_Quarantine : BOOL;

    L_Finalized_Runtime_Continuity : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Runtime_Sessions.G_Runtime_Valid := FALSE;
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

GVL_Runtime_Sessions.G_Local_Session.Session_Valid := TRUE;
GVL_Runtime_Sessions.G_Local_Session.Session_Connected := TRUE;
GVL_Runtime_Sessions.G_Local_Session.Last_Heartbeat_MS :=
    VI_System_Time_MS;

GVL_Runtime_Sessions.G_Local_Session.Transport_Healthy :=
    GVL_Runtime_Bus.G_TX_Healthy
    AND L_Finalized_Runtime_Continuity;

GVL_Runtime_Sessions.G_Local_Session.Runtime_Replication_Healthy :=
    GVL_Distributed_Runtime.G_Distributed_Replication_Healthy
    AND L_Finalized_Runtime_Continuity;

GVL_Runtime_Sessions.G_Local_Session.Authority_Granted :=
    GVL_Distributed_Authority.G_Authority_State.Authority_Master_Elected
    AND L_Finalized_Runtime_Continuity;

FOR L_i := 1 TO 16 DO

    L_Session := GVL_Runtime_Sessions.G_Remote_Sessions[L_i];

    IF L_Session.Session_Valid THEN

        IF (VI_System_Time_MS - L_Session.Last_Heartbeat_MS) > 30000 THEN

            L_Session.Session_Stale := TRUE;
            L_Session.Session_Reconnect_Required := TRUE;

            L_Any_Stale := TRUE;

        END_IF;

        IF NOT L_Finalized_Runtime_Continuity THEN

            L_Session.Session_Stale := TRUE;
            L_Session.Session_Quarantined := TRUE;

            L_Any_Stale := TRUE;
            L_Any_Quarantine := TRUE;

        END_IF;

        IF L_Session.Session_Quarantined THEN
            L_Any_Quarantine := TRUE;
        END_IF;

        GVL_Runtime_Sessions.G_Remote_Sessions[L_i] :=
            L_Session;

    END_IF;

END_FOR;

GVL_Runtime_Sessions.G_Any_Stale_Session :=
    L_Any_Stale;

GVL_Runtime_Sessions.G_Any_Quarantined_Session :=
    L_Any_Quarantine;

GVL_Runtime_Sessions.G_Runtime_Valid := TRUE;
GVL_Runtime_Sessions.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Quarantine THEN
    GVL_Runtime_Sessions.G_Status_Code := 2;
    GVL_Runtime_Sessions.G_Status_Text :=
        'Quarantined runtime session detected';
ELSIF L_Any_Stale THEN
    GVL_Runtime_Sessions.G_Status_Code := 1;
    GVL_Runtime_Sessions.G_Status_Text :=
        'Stale runtime session detected';
ELSE
    GVL_Runtime_Sessions.G_Status_Code := 0;
    GVL_Runtime_Sessions.G_Status_Text :=
        'Runtime session governance healthy';
END_IF;

END_FUNCTION_BLOCK