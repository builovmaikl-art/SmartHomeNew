PROGRAM PRG_Observability_Governor
VAR
    L_Now_MS : UDINT;
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;

// ======================================================
// OBSERVABILITY GOVERNOR
// ======================================================
// Pure downstream visibility aggregation layer.
//
// Observability does not:
// - own runtime authority;
// - arbitrate publication;
// - maintain synchronization barriers;
// - participate in quarantine governance.
// ======================================================

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

IF NOT GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK THEN
    GVL_OBSERVABILITY_AUTHORITY.Runtime_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay THEN
    GVL_OBSERVABILITY_AUTHORITY.Output_Decay_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_TRANSPORT_FRESHNESS.Transport_Freshness_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Transport_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_RECOVERY_GOVERNANCE.Recovery_Governance_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Recovery_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_PLC_FENCING.PLC_Semantic_Authority_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Fencing_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_TIME_MONOTONIC.Monotonic_Time_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Monotonic_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_DISTRIBUTED_EPOCH.Distributed_Reconciliation_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Failure_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Distributed_Quarantine_Active THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Quarantine_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Runtime_Stale THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Runtime_Stale_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Snapshot_Stale THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Snapshot_Stale_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Boot_Mismatch THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Boot_Mismatch_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Fencing_Conflict THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Fencing_Conflict_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF GVL_DISTRIBUTED_EPOCH.Peer_Semantic_Continuity_Lost THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Semantic_Continuity_Lost_Visible := TRUE;
END_IF;

IF NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Reconciled THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Publication_Reconciliation_Visible := TRUE;
END_IF;

IF NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Publication_Freeze_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Publication_Freeze_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Consistent THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Snapshot_Consistency_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Stale THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Publication_Stale_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Divergence THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Publication_Divergence_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Publication_Reconciliation_Lost THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Publication_Reconciliation_Lost_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_SNAPSHOT.Peer_Snapshot_Not_Immutable THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Snapshot_Not_Immutable_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_SNAPSHOT.Distributed_Snapshot_Quarantine_Active THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Immutable_Snapshot_Quarantine_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Quarantine_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Publication_Prepare_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Publication_Commit_Requested AND (NOT GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed) THEN
    GVL_OBSERVABILITY_AUTHORITY.Publication_Commit_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Ack_Expired THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Ack_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Mismatch_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Replay_Detected THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Replay_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Missing THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Missing_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired THEN
    GVL_OBSERVABILITY_AUTHORITY.Commit_Lease_Expired_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

IF GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required THEN
    GVL_OBSERVABILITY_AUTHORITY.Unsafe_State_Published := TRUE;
END_IF;

GVL_OBSERVABILITY_AUTHORITY.Observability_Epoch := GVL_OBSERVABILITY_AUTHORITY.Observability_Epoch + 1;
GVL_OBSERVABILITY_AUTHORITY.Observability_Snapshot_Epoch := GVL_OBSERVABILITY_AUTHORITY.Observability_Snapshot_Epoch + 1;

GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Publication_MS := L_Now_MS;

GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Code := 0;
GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Text := '';
END_PROGRAM
