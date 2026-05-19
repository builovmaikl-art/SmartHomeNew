PROGRAM PRG_Main_Phase_03_Input_Safety_Command
// MAIN PHASE 04/05/06 — input, safety, intent, scenario, policy and command shadow.
// Critical: yes. This is the main control-decision path and must run every PLC scan.

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 3;

PRG_IO_Read();
PRG_Input_Quality_Read();
PRG_Input_Processing();

PRG_Mode_Manager();
PRG_Presence_Manager();
PRG_Safety();
PRG_Safety_Operator();
PRG_Safety_Shutdown();
PRG_Safety_Recovery();
PRG_System_Intent();
PRG_Security();
PRG_System_Access_Maintenance();
PRG_User_Adapt_Control();
PRG_Behavior_Adapt_Profile();

PRG_Scenario_Engine();
PRG_System_Scenario_Rules();
PRG_System_Evacuation();
PRG_Policy();
PRG_Heating_Policy_Manager();
PRG_Heating_Policy_Observer();
PRG_System_Coordinator();
PRG_Command_Arbitration();

GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Valid := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_03_Input_Safety_Command_Status_Text := 'Input/safety/command phase executed';
GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_03_Input_Safety_Command <<<
END_PROGRAM
