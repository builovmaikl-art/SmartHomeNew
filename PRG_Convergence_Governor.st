PROGRAM PRG_Convergence_Governor
VAR
    L_Now_MS : UDINT;
    L_Healthy : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Healthy := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// SYSTEMIC CONVERGENCE GOVERNOR
// ======================================================
// Governs deterministic recovery/convergence semantics.
//
// Prevents one-cycle false recovery by requiring sustained
// healthy evidence before quarantine/degraded release.
//
// Important: convergence lease is derived from underlying
// healthy evidence, not from quarantine/forced-decay flags
// that are themselves released by this lease. This prevents
// circular dependency during recovery.
// ======================================================

// ------------------------------------------------------
// Capture authoritative convergence evidence.
// ------------------------------------------------------

GVL_CONVERGENCE.Convergence_Runtime_Barrier_OK :=
    GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK
    AND GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed;

GVL_CONVERGENCE.Convergence_Runtime_Snapshot_OK :=
    GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Runtime_Authority_Valid
    AND NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected;

GVL_CONVERGENCE.Convergence_Distributed_Snapshot_OK :=
    GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent;

GVL_CONVERGENCE.Convergence_Distributed_Commit_OK :=
    GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid
    AND NOT GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired;

GVL_CONVERGENCE.Convergence_Semantic_Progress_OK :=
    GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid
    AND GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected
    AND NOT GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired;

GVL_CONVERGENCE.Convergence_Output_Freshness_OK :=
    GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK
    AND GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid
    AND NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent
    AND GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid
    AND NOT GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired;

// ------------------------------------------------------
// Aggregate convergence health.
// ------------------------------------------------------

IF NOT GVL_CONVERGENCE.Convergence_Runtime_Barrier_OK THEN
    L_Healthy := FALSE;
    L_Error_Code := 18000;
    L_Error_Text := 'Runtime barrier convergence invalid';
END_IF;

IF L_Healthy AND NOT GVL_CONVERGENCE.Convergence_Runtime_Snapshot_OK THEN
    L_Healthy := FALSE;
    L_Error_Code := 18001;
    L_Error_Text := 'Runtime snapshot convergence invalid';
END_IF;

IF L_Healthy AND NOT GVL_CONVERGENCE.Convergence_Distributed_Snapshot_OK THEN
    L_Healthy := FALSE;
    L_Error_Code := 18002;
    L_Error_Text := 'Distributed snapshot convergence invalid';
END_IF;

IF L_Healthy AND NOT GVL_CONVERGENCE.Convergence_Distributed_Commit_OK THEN
    L_Healthy := FALSE;
    L_Error_Code := 18003;
    L_Error_Text := 'Distributed commit convergence invalid';
END_IF;

IF L_Healthy AND NOT GVL_CONVERGENCE.Convergence_Semantic_Progress_OK THEN
    L_Healthy := FALSE;
    L_Error_Code := 18004;
    L_Error_Text := 'Semantic progress convergence invalid';
END_IF;

IF L_Healthy AND NOT GVL_CONVERGENCE.Convergence_Output_Freshness_OK THEN
    L_Healthy := FALSE;
    L_Error_Code := 18005;
    L_Error_Text := 'Output freshness convergence invalid';
END_IF;

// ------------------------------------------------------
// Sustained convergence accumulation.
// ------------------------------------------------------

IF L_Healthy THEN
    GVL_CONVERGENCE.Convergence_Healthy_Observed := TRUE;

    GVL_CONVERGENCE.Recovery_Stable_Cycle_Count :=
        GVL_CONVERGENCE.Recovery_Stable_Cycle_Count + 1;

    IF GVL_CONVERGENCE.Convergence_Last_Healthy_MS = 0 THEN
        GVL_CONVERGENCE.Convergence_Last_Healthy_MS := L_Now_MS;
    END_IF;

    GVL_CONVERGENCE.Recovery_Stable_Time_MS :=
        L_Now_MS - GVL_CONVERGENCE.Convergence_Last_Healthy_MS;

    IF (GVL_CONVERGENCE.Recovery_Stable_Cycle_Count >= GVL_CONVERGENCE.Convergence_Min_Stable_Cycles)
    AND (GVL_CONVERGENCE.Recovery_Stable_Time_MS >= GVL_CONVERGENCE.Convergence_Min_Stable_Time_MS) THEN
        GVL_CONVERGENCE.Convergence_Lease_OK := TRUE;
        GVL_CONVERGENCE.Convergence_Release_Allowed := TRUE;
    ELSE
        GVL_CONVERGENCE.Convergence_Lease_OK := FALSE;
        GVL_CONVERGENCE.Convergence_Release_Allowed := FALSE;
    END_IF;

    GVL_CONVERGENCE.Convergence_Last_Error_Code := 0;
    GVL_CONVERGENCE.Convergence_Last_Error_Text := '';
ELSE
    GVL_CONVERGENCE.Convergence_Healthy_Observed := FALSE;

    GVL_CONVERGENCE.Recovery_Stable_Cycle_Count := 0;
    GVL_CONVERGENCE.Recovery_Stable_Time_MS := 0;

    GVL_CONVERGENCE.Convergence_Lease_OK := FALSE;
    GVL_CONVERGENCE.Convergence_Release_Allowed := FALSE;

    GVL_CONVERGENCE.Convergence_Last_Healthy_MS := 0;
    GVL_CONVERGENCE.Convergence_Last_Invalidation_MS := L_Now_MS;

    GVL_CONVERGENCE.Convergence_Invalidation_Count :=
        GVL_CONVERGENCE.Convergence_Invalidation_Count + 1;

    GVL_CONVERGENCE.Convergence_Last_Error_Code := L_Error_Code;
    GVL_CONVERGENCE.Convergence_Last_Error_Text := L_Error_Text;
END_IF;

END_PROGRAM
