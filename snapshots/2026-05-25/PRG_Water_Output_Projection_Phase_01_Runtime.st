PROGRAM PRG_Water_Output_Projection_Phase_01_Runtime
VAR
    fbWaterOutputProjector : FB_Water_Output_Projector;
    fbWaterOutputReconciliation : FB_Water_Output_Reconciliation;
    fbWaterValveFeedback : FB_Water_Valve_Feedback_Runtime;
    fbWaterPhysicalRuntime : FB_Water_Physical_Runtime;
    fbWaterRuntimeHardening : FB_Water_Runtime_Hardening;
    fbWaterRecoveryRuntime : FB_Water_Recovery_Runtime;
END_VAR

// Critical deterministic water output runtime path.
// Must run every PLC scan while water projection is enabled.

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

// >>> BULK_SYNC_ANCHOR: PRG_Water_Output_Projection_Phase_01_Runtime <<<
END_PROGRAM
