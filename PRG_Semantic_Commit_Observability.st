PROGRAM PRG_Semantic_Commit_Observability
VAR
    L_Visibility_Required : BOOL := FALSE;
END_VAR

// ======================================================
// SEMANTIC PUBLICATION COMMIT OBSERVABILITY
// ======================================================
// Isolated downstream semantic checkpoint visibility layer.
// Publication continuity visibility only.
// Does not invalidate runtime barrier, PLC fencing,
// immutable snapshots, distributed commit or IO authority.
// ======================================================

L_Visibility_Required := FALSE;

// ------------------------------------------------------
// Semantic commit visibility.
// ------------------------------------------------------

IF NOT GVL_SEMANTIC_COMMIT.Semantic_Commit_Valid THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_COMMIT.Semantic_Commit_Quarantine_Active THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_COMMIT.Semantic_Commit_Forced_Safe_Mode THEN
    L_Visibility_Required := TRUE;
END_IF;

// ------------------------------------------------------
// Semantic checkpoint anomaly visibility.
// ------------------------------------------------------

IF GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Mismatch THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_COMMIT.Semantic_Commit_Mismatch THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_COMMIT.Semantic_Rollback_Detected THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_COMMIT.Semantic_Replay_Fenced THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_COMMIT.Semantic_Checkpoint_Missing THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_COMMIT.Semantic_Commit_Lease_Expired THEN
    L_Visibility_Required := TRUE;
END_IF;

// ------------------------------------------------------
// Downstream-only observability escalation.
// ------------------------------------------------------

IF L_Visibility_Required THEN
    GVL_OBSERVABILITY_AUTHORITY.Emergency_Visibility_Required := TRUE;
    GVL_OBSERVABILITY_AUTHORITY.Unsafe_State_Published := TRUE;
END_IF;
END_PROGRAM
