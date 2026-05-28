PROGRAM PRG_Main_Phase_08_Diagnostics_HMI
// MAIN PHASE 13 — verification, explainability, diagnostics, history, simulation, HMI and debug.
// Critical: mixed. Command verification, health, alarm and debug summary remain active.
// History/trend/blackbox/simulation are shed when runtime budget asks for reduced work.
VAR
    L_Run_Extended_Diagnostics : BOOL;
    L_Run_Extended_Observability : BOOL;
    L_Run_Simulation : BOOL;
    L_Simulation_Context_Active : BOOL;
END_VAR

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 8;

L_Run_Extended_Diagnostics :=
    NOT GVL_FABRIC_LIFECYCLE_REGISTRY.Diagnostics_Degradation_Recommended;

L_Run_Extended_Observability :=
    (GVL_FABRIC_LIFECYCLE_REGISTRY.Runtime_Adaptive_Mode = FULL_SEMANTIC_MODE)
    AND NOT GVL_FABRIC_LIFECYCLE_REGISTRY.Extended_Observability_Shedding_Recommended;

L_Simulation_Context_Active :=
    GVL_SIMULATION.G_Test_Scenario_Active
    OR GVL_SIMULATION.G_Test_Start
    OR GVL_ALARM.G_Security_Armed
    OR (GVL_STATUS.G_Current_Scenario = SCENARIO_AWAY);

L_Run_Simulation :=
    GVL_SIMULATION.G_Simulation_Enable
    AND L_Simulation_Context_Active
    AND NOT GVL_FABRIC_LIFECYCLE_REGISTRY.Simulation_Suspension_Recommended;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Diagnostics_Requested := L_Run_Extended_Diagnostics;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Diagnostics_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Diagnostics_Skipped_By_Design := NOT L_Run_Extended_Diagnostics;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Observability_Requested := L_Run_Extended_Observability;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Observability_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Observability_Skipped_By_Design := NOT L_Run_Extended_Observability;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Simulation_Requested := L_Run_Simulation;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Simulation_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Simulation_Skipped_By_Design := NOT L_Run_Simulation;

PRG_Command_Verifier();
PRG_Explainability();
PRG_System_Health();
PRG_System_Alarm_Gateway();
PRG_System_Diagnostics();
PRG_HMI_Config_Workflow_Manager();
PRG_File_Archive_HMI_Applicator();
PRG_File_Archive_Manager();
PRG_HMI_Dashboard();
PRG_HMI_Water_Dashboard();
PRG_HMI_Gas_Smoke_CO_Dashboard();
PRG_HMI_Alarm_Audible_Ack_Dashboard();
PRG_HMI_Access_Dashboard();
PRG_HMI_Security_Dashboard();
PRG_HMI_Security_Access_Intent_Dashboard();
PRG_HMI_Security_IO_Map_Dashboard();
PRG_Debug_View();

IF L_Run_Extended_Diagnostics THEN
    PRG_System_Diagnostics_Ext();
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Diagnostics_Executed := TRUE;
END_IF;

IF L_Run_Extended_Observability THEN
    PRG_System_History();
    PRG_System_BlackBox();
    PRG_System_Trend();
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Observability_Executed := TRUE;
END_IF;

IF L_Run_Simulation THEN
    PRG_System_Simulation();
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Simulation_Executed := TRUE;
END_IF;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Valid := TRUE;

IF L_Run_Extended_Diagnostics AND L_Run_Extended_Observability AND L_Run_Simulation THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Status_Text := 'Diagnostics/HMI phase executed';
ELSE
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Diagnostics_HMI_Status_Text := 'Diagnostics/HMI phase executed with designed shedding';
END_IF;

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

GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Skipped_By_Design :=
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Full_Semantic_Skipped_By_Design
    OR GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Extended_Observability_Skipped_By_Design
    OR GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Analytics_Skipped_By_Design
    OR GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Diagnostics_Skipped_By_Design
    OR GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Extended_Observability_Skipped_By_Design
    OR GVL_MAIN_PHASE_FEEDBACK.G_Phase_08_Simulation_Skipped_By_Design;

IF GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Invalid THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Code := 1;
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Text := 'MAIN phase feedback degraded';
ELSIF GVL_MAIN_PHASE_FEEDBACK.G_Any_Phase_Skipped_By_Design THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Code := 2;
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Text := 'MAIN phase feedback nominal with designed shedding';
ELSE
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Code := 0;
    GVL_MAIN_PHASE_FEEDBACK.G_Status_Text := 'MAIN phase feedback nominal';
END_IF;

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 0;
GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_08_Diagnostics_HMI <<<
END_PROGRAM