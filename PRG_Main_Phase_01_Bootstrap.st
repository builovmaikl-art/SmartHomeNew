PROGRAM PRG_Main_Phase_01_Bootstrap
// MAIN PHASE 01/02 — time, configuration and canonical runtime baseline.
// Critical: yes. Called every PLC scan.

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 1;

PRG_Time_Service();
PRG_Time_Monotonic_Governor();
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
