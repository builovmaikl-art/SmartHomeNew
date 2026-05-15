PROGRAM PRG_Water_Output_Projection
VAR
    fbWaterOutputProjector : FB_Water_Output_Projector;
    fbWaterOutputReconciliation : FB_Water_Output_Reconciliation;
END_VAR

// Deterministic output projection runtime boundary.
// Single projection owner.
// No semantic/runtime authority.
// Existing global safety path preserved.

fbWaterOutputProjector(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

// Projection/runtime/confirmation reconciliation.
fbWaterOutputReconciliation(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

// Runtime bridge integrated in PRG_Water.
// This PRG remains the deterministic projection boundary.

END_PROGRAM