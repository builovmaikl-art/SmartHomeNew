PROGRAM PRG_Observability_Governor
VAR
    L_Now_MS : UDINT;

    L_Runtime_Authority_Valid : BOOL;
    L_Publication_Authority_Valid : BOOL;
    L_Recovery_Authority_Valid : BOOL;
    L_Distributed_Authority_Valid : BOOL;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

GVL_OBSERVABILITY_AUTHORITY.Runtime_Failure_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Output_Decay_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Transport_Failure_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Recovery_Failure_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Fencing_Failure_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Monotonic_Failure_Visible := FALSE;

GVL_OBSERVABILITY_AUTHORITY.Distributed_Failure_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Distributed_Quarantine_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Runtime_Stale_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Snapshot_Stale_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Boot_Mismatch_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Fencing_Conflict_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Semantic_Continuity_Lost_Visible := FALSE;

GVL_OBSERVABILITY_AUTHORITY.Distributed_Publication_Reconciliation_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Distributed_Publication_Freeze_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Distributed_Snapshot_Consistency_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Publication_Stale_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Publication_Divergence_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Publication_Reconciliation_Lost_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Snapshot_Not_Immutable_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Distributed_Immutable_Snapshot_Quarantine_Visible := FALSE;

GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Quarantine_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Publication_Prepare_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Publication_Commit_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Ack_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Mismatch_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Replay_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Missing_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Commit_Lease_Expired_Visible := FALSE;

GVL_OBSERVABILITY_AUTHORITY.Unsafe_State_Published := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := FALSE;

L_Runtime_Authority_Valid :=
    GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Publication_Allowed
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Copy_Valid
    AND GVL_RUNTIME_SNAPSHOT.Snapshot_Isolation_Valid
    AND NOT GVL_RUNTIME_SNAPSHOT.Snapshot_Mutation_Detected;

// Finalized publication authority.
L_Publication_Authority_Valid :=
    GVL_OUTPUT_EPOCH.Output_Publication_Allowed
    AND GVL_OUTPUT_EPOCH.Output_Publication_Valid
    AND GVL_OUTPUT_EPOCH.Output_Runtime_Epoch_Valid
    AND NOT GVL_OUTPUT_EPOCH.Output_Lease_Expired
    AND NOT GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay
    AND GVL_TRANSPORT_FRESHNESS.Transport_Freshness_Valid;

L_Recovery_Authority_Valid :=
    GVL_RECOVERY_GOVERNANCE.Recovery_Governance_Valid
    AND NOT GVL_RECOVERY_GOVERNANCE.Recovery_Quarantine_Active
    AND GVL_CONVERGENCE.Convergence_Release_Allowed;

L_Distributed_Authority_Valid :=
    GVL_DISTRIBUTED_EPOCH.Distributed_Reconciliation_Valid
    AND NOT GVL_DISTRIBUTED_EPOCH.Distributed_Quarantine_Active
    AND GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent
    AND GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid
    AND GVL_Distributed_Execution_Gates.G_Runtime_Valid;

GVL_OBSERVABILITY_AUTHORITY.Publication_Runtime_Valid :=
    L_Runtime_Authority_Valid
    AND L_Publication_Authority_Valid
    AND L_Recovery_Authority_Valid
    AND L_Distributed_Authority_Valid;

IF NOT L_Publication_Authority_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Output_Decay_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

GVL_OBSERVABILITY_AUTHORITY.Observability_Epoch := GVL_OBSERVABILITY_AUTHORITY.Observability_Epoch + 1;
GVL_OBSERVABILITY_AUTHORITY.Observability_Snapshot_Epoch := GVL_OBSERVABILITY_AUTHORITY.Observability_Snapshot_Epoch + 1;

GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Publication_MS := L_Now_MS;

GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Code := 0;
GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Text := '';
END_PROGRAM