PROGRAM PRG_Output_Freshness_Governor
VAR
    L_Now_MS : UDINT;
    L_Delta_MS : UDINT;
    L_Output_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Output_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// OUTPUT FRESHNESS GOVERNOR
// ======================================================
// Invalid output state escalates immediately.
//
// Recovery/release is convergence-lease based:
// outputs are not released from stale/forced-safe-decay
// on a single healthy scan.
// ======================================================

IF NOT GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6000;
    L_Error_Text := 'Output runtime authority invalid';
END_IF;

IF L_Output_Valid AND (NOT GVL_RUNTIME_EPOCH.Runtime_IO_Publication_Allowed) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6001;
    L_Error_Text := 'Output publication not allowed';
END_IF;

IF L_Output_Valid AND (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Frozen) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6100;
    L_Error_Text := 'Runtime snapshot not frozen';
END_IF;

IF L_Output_Valid AND (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6101;
    L_Error_Text := 'Snapshot publication blocked';
END_IF;

IF L_Output_Valid AND (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6102;
    L_Error_Text := 'Snapshot copy invalid';
END_IF;

IF L_Output_Valid AND (NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6103;
    L_Error_Text := 'Snapshot isolation invalid';
END_IF;

IF L_Output_Valid AND GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6104;
    L_Error_Text := 'Snapshot mutation detected';
END_IF;

// Distributed epoch is the aggregate reconciliation authority.
IF L_Output_Valid AND GVL_DISTRIBUTED_EPOCH.Distributed_Quarantine_Active THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6200;
    L_Error_Text := 'Distributed reconciliation quarantine active';
END_IF;

// Distributed snapshot aggregate publication authority.
IF L_Output_Valid AND (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6300;
    L_Error_Text := 'Distributed publication reconciliation invalid';
END_IF;

IF L_Output_Valid AND (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6301;
    L_Error_Text := 'Distributed publication freeze invalid';
END_IF;

IF L_Output_Valid AND (NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6302;
    L_Error_Text := 'Distributed immutable snapshot inconsistent';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Quarantine_Active THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6306;
    L_Error_Text := 'Distributed immutable snapshot quarantine active';
END_IF;

// Distributed commit aggregate publication-continuity authority.
IF L_Output_Valid AND (NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6400;
    L_Error_Text := 'Distributed commit invalid';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6401;
    L_Error_Text := 'Distributed commit quarantine active';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6405;
    L_Error_Text := 'Distributed commit lease expired';
END_IF;

// Semantic continuity is advisory-only.
GVL_OUTPUT_EPOCH.Output_Semantic_Continuity_Warning :=
    (NOT GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid)
    OR (NOT GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK)
    OR GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected
    OR GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected
    OR GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected
    OR GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected
    OR GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired
    OR GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active;

IF L_Output_Valid THEN
    IF GVL_OUTPUT_EPOCH.Output_Runtime_Epoch > GVL_RUNTIME_EPOCH.Runtime_Epoch THEN
        L_Output_Valid := FALSE;
        L_Error_Code := 6002;
        L_Error_Text := 'Output epoch ahead of runtime epoch';
    END_IF;
END_IF;

L_Delta_MS := L_Now_MS - GVL_OUTPUT_EPOCH.Output_Last_Refresh_MS;

IF L_Output_Valid AND GVL_OUTPUT_EPOCH.Output_Lease_Active THEN
    IF L_Delta_MS > GVL_OUTPUT_EPOCH.Output_Lease_Timeout_MS THEN
        L_Output_Valid := FALSE;
        L_Error_Code := 6003;
        L_Error_Text := 'Output lease expired';
    END_IF;
END_IF;

IF L_Output_Valid THEN
    GVL_OUTPUT_EPOCH.Output_Publication_Epoch := GVL_OUTPUT_EPOCH.Output_Publication_Epoch + 1;

    GVL_OUTPUT_EPOCH.Output_Publication_Valid := TRUE;
    GVL_OUTPUT_EPOCH.Output_Lease_Active := TRUE;
    GVL_OUTPUT_EPOCH.Output_Lease_Expired := FALSE;

    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch := GVL_RUNTIME_EPOCH.Runtime_Epoch;
    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid := TRUE;

    GVL_OUTPUT_EPOCH.Output_Last_Publication_MS := L_Now_MS;
    GVL_OUTPUT_EPOCH.Output_Last_Refresh_MS := L_Now_MS;

    // --------------------------------------------------
    // Lease-based recovery release.
    // --------------------------------------------------
    IF GVL_CONVERGENCE.Convergence_Release_Allowed THEN
        GVL_OUTPUT_EPOCH.Output_Stale_Detected := FALSE;
        GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay := FALSE;
    END_IF;

    GVL_OUTPUT_EPOCH.Output_Last_Error_Code := 0;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Text := '';
ELSE
    // Invalid output state escalates immediately.
    GVL_OUTPUT_EPOCH.Output_Publication_Valid := FALSE;
    GVL_OUTPUT_EPOCH.Output_Lease_Expired := TRUE;
    GVL_OUTPUT_EPOCH.Output_Stale_Detected := TRUE;
    GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay := TRUE;

    GVL_OUTPUT_EPOCH.Output_Last_Invalidation_MS := L_Now_MS;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Code := L_Error_Code;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Text := L_Error_Text;
END_IF;
END_PROGRAM
