PROGRAM PRG_Water_Output_Projection_Phase_02_Observability
VAR
    fbPredictiveDiagnostics : FB_Predictive_Diagnostics_Runtime;
    fbForensicJournal : FB_Forensic_Journal_Runtime;
END_VAR

// Non-authoritative water runtime observability path.
// Does not write physical outputs or command shadow.

fbPredictiveDiagnostics(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbForensicJournal(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

// >>> BULK_SYNC_ANCHOR: PRG_Water_Output_Projection_Phase_02_Observability <<<
END_PROGRAM
