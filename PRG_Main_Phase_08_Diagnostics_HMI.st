PROGRAM PRG_Main_Phase_08_Diagnostics_HMI
// MAIN PHASE 13 — verification, explainability, diagnostics, history, simulation, HMI and debug.
// Critical: mixed. Command verification and alarms are high priority; simulation/debug are later shedding candidates.

PRG_Command_Verifier();
PRG_Explainability();
PRG_System_Health();
PRG_System_Alarm_Gateway();
PRG_System_Diagnostics();
PRG_System_Diagnostics_Ext();
PRG_System_History();
PRG_System_BlackBox();
PRG_System_Trend();
PRG_System_Simulation();
PRG_HMI_Dashboard();
PRG_Debug_View();

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_08_Diagnostics_HMI <<<
END_PROGRAM
