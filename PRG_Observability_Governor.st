PROGRAM PRG_Observability_Governor
VAR
    L_Now_MS : UDINT;
    L_Observability_Valid : BOOL := TRUE;
    L_Error_Code : UDINT := 0;
    L_Error_Text : STRING(160) := '';
END_VAR

L_Now_MS := GVL_STATUS.G_System_Time_MS;
L_Observability_Valid := TRUE;
L_Error_Code := 0;
L_Error_Text := '';

// ======================================================
// OBSERVABILITY AUTHORITY GOVERNOR
// ======================================================
// Governs authoritative observability semantics.
// Prevents false-safe visibility windows.
// Distributed reconciliation visibility is downstream-only
// and does not feed back into runtime barrier or PLC fencing.
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

GVL_OBSERVABILITY_AUTHORITY.Unsafe_State_Published := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := FALSE;

// Runtime authority linkage.
IF NOT GVL_RUNTIME_EPOCH.Runtime_Runtime_Barrier_OK THEN
    GVL_OBSERVABILITY_AUTHORITY.Runtime_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

// Output decay visibility linkage.
IF GVL_OUTPUT_EPOCH.Output_Forced_Safe_Decay THEN
    GVL_OBSERVABILITY_AUTHORITY.Output_Decay_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

// Transport visibility linkage.
IF NOT GVL_TRANSPORT_FRESHNESS.Transport_Freshness_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Transport_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

// Recovery visibility linkage.
IF NOT GVL_RECOVERY_GOVERNANCE.Recovery_Governance_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Recovery_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

// Fencing visibility linkage.
IF NOT GVL_PLC_FENCING.PLC_Semantic_Authority_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Fencing_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

// Monotonic visibility linkage.
IF NOT GVL_TIME_MONOTONIC.Monotonic_Time_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Monotonic_Failure_Visible := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

// ======================================================
// DISTRIBUTED RECONCILIATION VISIBILITY
// ======================================================
// Downstream visibility only.
// Does not invalidate runtime barrier or PLC fencing.
// ======================================================

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
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
END_IF;

// Authoritative observability synchronization.
IF GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required THEN
    GVL_OBSERVABILITY_AUTHORITY.Unsafe_State_Published := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.PreActuation_Visibility_Ready := TRUE;
END_IF;

// Observability validity.
IF GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required
AND NOT GVL_OBSERVABILITY_AUTHORITY.PreActuation_Visibility_Ready THEN
    L_Observability_Valid := FALSE;
    L_Error_Code := 11000;
    L_Error_Text := 'Pre-actuation visibility not ready';
END_IF;

// Publish authoritative observability state.
IF L_Observability_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Observability_Epoch := GVL_OBSERVABILITY_AUTHORITY.Observability_Epoch + 1;
    GVL_OBSERVABILITY_AUTHORITY.Observability_Snapshot_Epoch := GVL_OBSERVABILITY_AUTHORITY.Observability_Snapshot_Epoch + 1;

    GVL_OBSERVABILITY_AUTHORITY.Authority_Snapshot_Valid := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Diagnostics_Synchronized := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Explainability_Synchronized := TRUE;

    GVL_OBSERVABILITY_AUTHORITY.Observability_Quarantine_Active := FALSE;
    GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Publication_MS := L_Now_MS;

    GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Code := 0;
    GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Text := '';
ELSE
    GVL_OBSERVABILITY_AUTHORITY.Authority_Snapshot_Valid := FALSE;
    GVL_OBSERVABILITY_AUTHORITY.Diagnostics_Synchronized := FALSE;
    GVL_OBSERVABILITY_AUTHORITY.Explainability_Synchronized := FALSE;

    GVL_OBSERVABILITY_AUTHORITY.Observability_Quarantine_Active := TRUE;

    GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Code := L_Error_Code;
    GVL_OBSERVABILITY_AUTHORITY.Observability_Last_Error_Text := L_Error_Text;

    GVL_OBSERVABILITY_AUTHORITY.Observability_Invalidation_Count := GVL_OBSERVABILITY_AUTHORITY.Observability_Invalidation_Count + 1;
END_IF;
END_PROGRAM
