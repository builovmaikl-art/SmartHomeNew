PROGRAM PRG_Distributed_Commit_Observability
VAR
END_VAR

// ======================================================
// DISTRIBUTED COMMIT OBSERVABILITY GOVERNOR
// ======================================================
// Isolated downstream observability projection layer.
// Publication visibility only.
// Does not invalidate runtime barrier,
// PLC fencing, immutable snapshots or IO directly.
//
// Visibility ownership rule:
// this layer publishes only dedicated distributed
// visibility fields.
//
// Global observability escalation ownership remains
// inside PRG_Observability_Governor.
// ======================================================

GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Quarantine_Visible := FALSE;

GVL_OBSERVABILITY_AUTHORITY.Publication_Prepare_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Publication_Commit_Visible := FALSE;

GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Ack_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Mismatch_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Replay_Visible := FALSE;
GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Missing_Visible := FALSE;

GVL_OBSERVABILITY_AUTHORITY.Commit_Lease_Expired_Visible := FALSE;

// ------------------------------------------------------
// Distributed commit validity visibility.
// ------------------------------------------------------

IF NOT GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Distributed_Commit_Quarantine_Active THEN
    GVL_OBSERVABILITY_AUTHORITY.Distributed_Commit_Quarantine_Visible := TRUE;
END_IF;

// ------------------------------------------------------
// Publication lifecycle visibility.
// ------------------------------------------------------

IF GVL_DISTRIBUTED_COMMIT.Publication_Prepare_Active THEN
    GVL_OBSERVABILITY_AUTHORITY.Publication_Prepare_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Publication_Commit_Confirmed THEN
    GVL_OBSERVABILITY_AUTHORITY.Publication_Commit_Visible := TRUE;
END_IF;

// ------------------------------------------------------
// Peer commit continuity visibility.
// ------------------------------------------------------

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Ack_Valid THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Ack_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Mismatch THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Mismatch_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Replay_Detected THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Replay_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Peer_Commit_Missing THEN
    GVL_OBSERVABILITY_AUTHORITY.Peer_Commit_Missing_Visible := TRUE;
END_IF;

IF GVL_DISTRIBUTED_COMMIT.Commit_Lease_Expired THEN
    GVL_OBSERVABILITY_AUTHORITY.Commit_Lease_Expired_Visible := TRUE;
END_IF;
END_PROGRAM
