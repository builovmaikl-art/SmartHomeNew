PROGRAM MAIN
// ==============================================================================
// MAIN — deterministic PLC scan-cycle phase map.
// ==============================================================================
// Execution order is preserved by PRG_Main_Phase_* programs.
// No phase gating or controlled shedding is applied here yet.
// Compile/runtime validation must confirm that all referenced phase programs are
// linked by the PLC project export.
// ==============================================================================

PRG_Main_Phase_01_Bootstrap();
PRG_Main_Phase_02_Redundancy();
PRG_Main_Phase_03_Input_Safety_Command();

PRG_Main_Phase_04_Transport_Distributed();
PRG_Main_Feedback_Mark_04();

PRG_Main_Phase_05_Domain_Output();
PRG_Main_Feedback_Mark_05();

PRG_Main_Phase_06_PostOutput_Authority();
PRG_Main_Feedback_Mark_06();

PRG_Main_Phase_07_Semantic_Governance();
PRG_Main_Feedback_Mark_07();

PRG_Main_Phase_08_Diagnostics_HMI();

// >>> BULK_SYNC_ANCHOR: MAIN <<<
END_PROGRAM
