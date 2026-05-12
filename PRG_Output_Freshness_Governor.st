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
// Governs physical output publication freshness.
// Prevents stale output survivability, mutable
// snapshot publication leakage and downstream
// distributed/semantic continuity divergence publication.
// ======================================================

GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay := FALSE;
GVL_OUTPUT_EPOCH.Output_Stale_Detected := FALSE;

// ------------------------------------------------------
// Runtime authority linkage.
// ------------------------------------------------------

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

// ------------------------------------------------------
// Immutable snapshot isolation validation.
// ------------------------------------------------------

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

// ------------------------------------------------------
// Downstream distributed reconciliation quarantine.
// ------------------------------------------------------
// Distributed divergence is publication-authoritative
// only. It does not invalidate runtime barrier,
// PLC fencing or immutable snapshot authority.
// ------------------------------------------------------

IF L_Output_Valid AND GVL_DISTRIBUTED_EPOCH.Distributed_Quarantine_Active THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6200;
    L_Error_Text := 'Distributed reconciliation quarantine active';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Conflict THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6201;
    L_Error_Text := 'Peer fencing conflict detected';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_EPOCH.Peer_Semantic_Continuity_Lost THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6202;
    L_Error_Text := 'Peer semantic continuity lost';
END_IF;

// ------------------------------------------------------
// Distributed immutable publication freeze enforcement.
// ------------------------------------------------------
// Publication-authoritative only.
// Does not invalidate runtime barrier,
// PLC fencing or local immutable snapshot authority.
// ------------------------------------------------------

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

IF L_Output_Valid AND GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Divergence THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6303;
    L_Error_Text := 'Peer publication divergence detected';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Reconciliation_Lost THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6304;
    L_Error_Text := 'Peer publication reconciliation lost';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Not_Immutable THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6305;
    L_Error_Text := 'Peer snapshot immutable contract violated';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Quarantine_Active THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6306;
    L_Error_Text := 'Distributed immutable snapshot quarantine active';
END_IF;

// ------------------------------------------------------
// Deterministic distributed commit decay enforcement.
// ------------------------------------------------------
// Publication continuity governance only.
// Downstream-only. Does not invalidate runtime,
// fencing or immutable snapshot authority.
// ------------------------------------------------------

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

IF L_Output_Valid AND GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6402;
    L_Error_Text := 'Peer commit mismatch detected';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_COMMIT.Peer_Commit_Replay_Detected THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6403;
    L_Error_Text := 'Peer commit replay detected';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_COMMIT.Peer_Commit_Missing THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6404;
    L_Error_Text := 'Peer commit acknowledgement missing';
END_IF;

IF L_Output_Valid AND GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6405;
    L_Error_Text := 'Distributed commit lease expired';
END_IF;

// ------------------------------------------------------
// Semantic continuity publication enforcement.
// ------------------------------------------------------
// Semantic continuity is publication-authoritative only.
// It does not invalidate runtime barrier,
// PLC fencing or immutable snapshot authority.
// ------------------------------------------------------

IF L_Output_Valid AND (NOT GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6500;
    L_Error_Text := 'Semantic forward progress invalid';
END_IF;

IF L_Output_Valid AND (NOT GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK) THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6501;
    L_Error_Text := 'Semantic execution continuity invalid';
END_IF;

IF L_Output_Valid AND GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6502;
    L_Error_Text := 'Semantic stagnation detected';
END_IF;

IF L_Output_Valid AND GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6503;
    L_Error_Text := 'Semantic replay suspected';
END_IF;

IF L_Output_Valid AND GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6504;
    L_Error_Text := 'Semantic livelock suspected';
END_IF;

IF L_Output_Valid AND GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6505;
    L_Error_Text := 'Semantic deadlock suspected';
END_IF;

IF L_Output_Valid AND GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6506;
    L_Error_Text := 'Semantic progress lease expired';
END_IF;

IF L_Output_Valid AND GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active THEN
    L_Output_Valid := FALSE;
    L_Error_Code := 6507;
    L_Error_Text := 'Semantic progress quarantine active';
END_IF;

// ------------------------------------------------------
// Epoch linkage validation.
// ------------------------------------------------------

IF L_Output_Valid THEN
    IF GVL_OUTPUT_EPOCH.Output_Runtime_Epoch > GVL_RUNTIME_EPOCH.Runtime_Epoch THEN
        L_Output_Valid := FALSE;
        L_Error_Code := 6002;
        L_Error_Text := 'Output epoch ahead of runtime epoch';
    END_IF;
END_IF;

// ------------------------------------------------------
// Lease freshness validation.
// ------------------------------------------------------

L_Delta_MS := L_Now_MS - GVL_OUTPUT_EPOCH.Output_Last_Refresh_MS;

IF L_Output_Valid AND GVL_OUTPUT_EPOCH.Output_Lease_Active THEN
    IF L_Delta_MS > GVL_OUTPUT_EPOCH.Output_Lease_Timeout_MS THEN
        L_Output_Valid := FALSE;
        L_Error_Code := 6003;
        L_Error_Text := 'Output lease expired';
    END_IF;
END_IF;

// ------------------------------------------------------
// Publish authoritative output freshness state.
// ------------------------------------------------------

IF L_Output_Valid THEN
    GVL_OUTPUT_EPOCH.Output_Publication_Epoch := GVL_OUTPUT_EPOCH.Output_Publication_Epoch + 1;

    GVL_OUTPUT_EPOCH.Output_Publication_Valid := TRUE;
    GVL_OUTPUT_EPOCH.Output_Lease_Active := TRUE;
    GVL_OUTPUT_EPOCH.Output_Lease_Expired := FALSE;

    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch := GVL_RUNTIME_EPOCH.Runtime_Epoch;
    GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid := TRUE;

    GVL_OUTPUT_EPOCH.Output_Last_Publication_MS := L_Now_MS;
    GVL_OUTPUT_EPOCH.Output_Last_Refresh_MS := L_Now_MS;

    GVL_OUTPUT_EPOCH.Output_Last_Error_Code := 0;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Text := '';
ELSE
    GVL_OUTPUT_EPOCH.Output_Publication_Valid := FALSE;
    GVL_OUTPUT_EPOCH.Output_Lease_Expired := TRUE;
    GVL_OUTPUT_EPOCH.Output_Stale_Detected := TRUE;
    GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay := TRUE;

    GVL_OUTPUT_EPOCH.Output_Last_Invalidation_MS := L_Now_MS;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Code := L_Error_Code;
    GVL_OUTPUT_EPOCH.Output_Last_Error_Text := L_Error_Text;

    GVL_OUTPUT_EPOCH.Output_Invalidation_Count := GVL_OUTPUT_EPOCH.Output_Invalidation_Count + 1;
END_IF;
END_PROGRAM
