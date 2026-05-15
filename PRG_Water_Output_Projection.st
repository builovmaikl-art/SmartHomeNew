PROGRAM PRG_Water_Output_Projection
VAR
    fbWaterOutputProjector : FB_Water_Output_Projector;
    fbWaterOutputReconciliation : FB_Water_Output_Reconciliation;
    fbWaterValveFeedback : FB_Water_Valve_Feedback_Runtime;
    fbWaterPhysicalRuntime : FB_Water_Physical_Runtime;
    fbWaterRuntimeHardening : FB_Water_Runtime_Hardening;
    fbWaterRecoveryRuntime : FB_Water_Recovery_Runtime;
    fbPredictiveDiagnostics : FB_Predictive_Diagnostics_Runtime;
    fbForensicJournal : FB_Forensic_Journal_Runtime;
END_VAR

// Deterministic output projection runtime boundary.
//
// Runtime chain:
// output projection
//   -> reconciliation
//   -> valve feedback
//   -> physical convergence runtime
//   -> runtime hardening
//   -> recovery governance
//   -> predictive diagnostics
//   -> forensic journal
//
// No semantic/runtime authority.
// Existing global safety path preserved.

fbWaterOutputProjector(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterOutputReconciliation(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterValveFeedback(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterPhysicalRuntime(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterRuntimeHardening(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbWaterRecoveryRuntime(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbPredictiveDiagnostics(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbForensicJournal(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

// Runtime bridge integrated in PRG_Water.
// This PRG remains the deterministic projection boundary.

END_PROGRAM