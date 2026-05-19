PROGRAM PRG_Main_Phase_01_Bootstrap
// MAIN PHASE 01/02 — time, configuration and canonical runtime baseline.
// Critical: yes. Called every PLC scan.

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 1;

// Reset observational phase feedback at the beginning of every PLC scan.
GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_02_Redundancy_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Phase_04_Transport_Distributed_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_04_Transport_Distributed_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_04_Transport_Distributed_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_05_Domain_Output_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Phase_06_PostOutput_Authority_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_06_PostOutput_Authority_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_06_PostOutput_Authority_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Status_Text := '';

GVL_MAIN_PHASE_FEEDBACK.G_Critical_Path_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Critical_Path_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Observability_Path_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Observability_Path_Valid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Invalid := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Status_Code := 0;
GVL_MAIN_PHASE_FEEDBACK.G_Status_Text := 'MAIN phase feedback reset';

PRG_Time_Service();
PRG_Time_Monotonic_Governor();

GVL_MAIN_PHASE_FEEDBACK.G_Cycle_Start_MS := GVL_TIME_SERVICE.G_Now_MS;

PRG_System_Init();
PRG_Config_Manager();
PRG_Config_Validation();
PRG_Config_Versioning();
PRG_System_Runtime_Base();

PRG_Temporal_Domain();
PRG_Runtime_Core_Domain();
PRG_Safety_Domain();
PRG_Recovery_Domain();
PRG_Distributed_Domain();
PRG_Verification_Domain();
PRG_Semantic_Commit_Governor();

GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Valid := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_01_Bootstrap_Status_Text := 'Bootstrap/runtime baseline executed';
GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_01_Bootstrap <<<
END_PROGRAM
