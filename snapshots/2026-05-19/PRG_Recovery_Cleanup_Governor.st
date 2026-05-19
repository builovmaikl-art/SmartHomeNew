PROGRAM PRG_Recovery_Cleanup_Governor
VAR
    L_Now_MS : UDINT;
    L_Recovery_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';

    L_Distributed_Recovery_Allowed : BOOL;
    L_Cluster_Recovery_Lock : BOOL;
    L_Cluster_Quarantine : BOOL;

    L_Finalized_Publication_Continuity : BOOL;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Recovery_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

GVL_RECOVERY_GOVERNANCE.Recovery_Semantic_Residue_Detected := FALSE;
GVL_RECOVERY_GOVERNANCE.Recovery_Degraded_State_Residual := FALSE;
GVL_RECOVERY_GOVERNANCE.Recovery_Retained_State_Residual := FALSE;

L_Distributed_Recovery_Allowed :=
    GVL_Distributed_Execution_Gates.G_Can_Recover;

L_Cluster_Recovery_Lock :=
    GVL_Cluster_Runtime_FSM.G_State_Recovery_Lock;

L_Cluster_Quarantine :=
    GVL_Cluster_Runtime_FSM.G_State_Quarantine;

// Finalized publication continuity.
L_Finalized_Publication_Continuity :=
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent
    AND GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid
    AND NOT GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired
    AND GVL_OUTPUT_EPOCH.Output_Publication_Valid
    AND GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid
    AND NOT GVL_OUTPUT_EPOCH.Output_Lease_Expired
    AND NOT GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay;

IF NOT GVL_TIME_MONOTONIC.Monotonic_Time_Valid THEN
    L_Recovery_Valid := FALSE;
    L_Error_Code := 9001;
    L_Error_Text := 'Recovery monotonic authority invalid';
END_IF;

IF L_Recovery_Valid
   AND NOT L_Distributed_Recovery_Allowed THEN

    L_Recovery_Valid := FALSE;

    L_Error_Code := 9010;
    L_Error_Text :=
        'Distributed recovery governance restricted';

END_IF;

IF L_Recovery_Valid
   AND L_Cluster_Recovery_Lock THEN

    L_Recovery_Valid := FALSE;

    L_Error_Code := 9011;
    L_Error_Text :=
        'Cluster recovery-lock active';

END_IF;

IF L_Recovery_Valid
   AND L_Cluster_Quarantine THEN

    L_Recovery_Valid := FALSE;

    L_Error_Code := 9012;
    L_Error_Text :=
        'Cluster quarantine active';

END_IF;

IF GVL_SAFETY_RECOVERY.G_Recovery_Active THEN
    GVL_RECOVERY_GOVERNANCE.Recovery_Quarantine_Active := TRUE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Cleanup_Start_MS := L_Now_MS;

    L_Recovery_Valid := FALSE;

    IF L_Error_Code = 0 THEN
        L_Error_Code := 9002;
        L_Error_Text := 'Recovery quarantine active';
    END_IF;
END_IF;

IF L_Recovery_Valid AND GVL_DEGRADED.G_System_Degraded THEN
    L_Recovery_Valid := FALSE;
    L_Error_Code := 9003;
    L_Error_Text := 'Residual degraded state detected';

    GVL_RECOVERY_GOVERNANCE.Recovery_Degraded_State_Residual := TRUE;
END_IF;

IF L_Recovery_Valid AND GVL_TIME_MONOTONIC.Retained_Time_Invalid THEN
    L_Recovery_Valid := FALSE;
    L_Error_Code := 9004;
    L_Error_Text := 'Retained state residue detected';

    GVL_RECOVERY_GOVERNANCE.Recovery_Retained_State_Residual := TRUE;
END_IF;

IF L_Recovery_Valid THEN
    GVL_RECOVERY_GOVERNANCE.Recovery_Epoch := GVL_RECOVERY_GOVERNANCE.Recovery_Epoch + 1;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Epoch := GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Epoch + 1;

    GVL_RECOVERY_GOVERNANCE.Recovery_Governance_Valid := TRUE;

    // Cleanup release requires finalized publication continuity.
    IF GVL_CONVERGENCE.Convergence_Release_Allowed
       AND L_Finalized_Publication_Continuity THEN

        GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Completed := TRUE;
        GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Verified := TRUE;
        GVL_RECOVERY_GOVERNANCE.Recovery_Quarantine_Active := FALSE;
        GVL_RECOVERY_GOVERNANCE.Recovery_Forced_Safe_Mode := FALSE;
        GVL_RECOVERY_GOVERNANCE.Recovery_Last_Cleanup_End_MS := L_Now_MS;

        GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Code := 0;
        GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Text := '';
    ELSE
        GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Completed := FALSE;
        GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Verified := FALSE;
        GVL_RECOVERY_GOVERNANCE.Recovery_Quarantine_Active := TRUE;
        GVL_RECOVERY_GOVERNANCE.Recovery_Forced_Safe_Mode := TRUE;

        GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Code := 9005;
        GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Text := 'Recovery cleanup waiting for finalized publication continuity';
    END_IF;
ELSE
    GVL_RECOVERY_GOVERNANCE.Recovery_Governance_Valid := FALSE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Completed := FALSE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Cleanup_Verified := FALSE;

    GVL_RECOVERY_GOVERNANCE.Recovery_Semantic_Residue_Detected := TRUE;
    GVL_RECOVERY_GOVERNANCE.Recovery_Forced_Safe_Mode := TRUE;

    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Code := L_Error_Code;
    GVL_RECOVERY_GOVERNANCE.Recovery_Last_Error_Text := L_Error_Text;

    GVL_RECOVERY_GOVERNANCE.Recovery_Invalidation_Count := GVL_RECOVERY_GOVERNANCE.Recovery_Invalidation_Count + 1;
END_IF;
END_PROGRAM