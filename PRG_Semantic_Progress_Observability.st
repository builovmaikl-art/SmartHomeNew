PROGRAM PRG_Semantic_Progress_Observability
VAR
    L_Visibility_Required : BOOL := FALSE;
END_VAR

// ======================================================
// SEMANTIC PROGRESS OBSERVABILITY
// ======================================================
// Isolated downstream semantic continuity visibility layer.
// Visibility/publication continuity only.
// Does not invalidate runtime barrier,
// PLC fencing, immutable snapshots or IO authority.
// ======================================================

L_Visibility_Required := FALSE;

// ------------------------------------------------------
// Semantic forward progress visibility.
// ------------------------------------------------------

IF NOT GVL_SEMANTIC_PROGRESS.Semantic_Forward_Progress_Valid THEN
    L_Visibility_Required := TRUE;
END_IF;

IF NOT GVL_SEMANTIC_PROGRESS.Semantic_Execution_Continuity_OK THEN
    L_Visibility_Required := TRUE;
END_IF;

// ------------------------------------------------------
// Semantic anomaly visibility.
// ------------------------------------------------------

IF GVL_SEMANTIC_PROGRESS.Semantic_Stagnation_Detected THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_PROGRESS.Semantic_Replay_Suspected THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_PROGRESS.Semantic_Livelock_Suspected THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_PROGRESS.Semantic_Deadlock_Suspected THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_PROGRESS.Semantic_Progress_Lease_Expired THEN
    L_Visibility_Required := TRUE;
END_IF;

IF GVL_SEMANTIC_PROGRESS.Semantic_Progress_Quarantine_Active THEN
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
