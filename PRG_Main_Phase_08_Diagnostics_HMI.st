PROGRAM PRG_Main_Phase_08_Diagnostics_HMI
// MAIN PHASE 13 — verification, explainability, diagnostics, history, simulation, HMI and debug.
// Critical: mixed. Command verification and alarms are high priority; simulation/debug are later shedding candidates.

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 8;

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

GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Valid := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Status_Text := 'Diagnostics/HMI phase executed';

GVL_MAIN_PHASE_FEEDBACK.G_Critical_Path_Executed :=
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Executed
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Executed
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Executed
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Executed;

GVL_MAIN_PHASE_FEEDBACK.G_Critical_Path_Valid :=
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Valid
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Valid
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Valid
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Valid;

GVL_MAIN_PHASE_FEEDBACK.G_Observability_Path_Executed :=
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Executed
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Executed;

GVL_MAIN_PHASE_FEEDBACK.G_Observability_Path_Valid :=
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Valid
    AND GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Valid;

GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Invalid :=
    NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Valid
    OR NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Valid
    OR NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Valid
    OR NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_04_Transport_Distributed_Valid
    OR NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Valid
    OR NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_06_PostOutput_Authority_Valid
    OR NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Valid
    OR NOT GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Valid;

IF GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Invalid THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Code := 1;
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Text := 'MAIN phase feedback degraded';
ELSE
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Code := 0;
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Text := 'MAIN phase feedback nominal';
END_IF;

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 0;
GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_08_Diagnostics_HMI <<<
END_PROGRAM
