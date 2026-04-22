PROGRAM PRG_System
VAR
    L_i : INT;
    L_Motion_Sensors_16 : ARRAY[1..16] OF BOOL;
    // --- ADAPTER LAYER ---
    L_Zone_Valves_8 : ARRAY[1..8] OF BOOL;
    L_Lighting_32   : ARRAY[1..32] OF BYTE;
    L_Lighting_Bool_32 : ARRAY[1..32] OF BOOL;
    L_FloorTemps_8  : ARRAY[1..8] OF REAL;
    fbCoreKernelObserver : FB_CoreKernel_Live_Observer;
    fbSystemHealth : FB_System_Health;
    fbRedundancy : FB_Redundancy_Manager;
    fbGateway : FB_Gateway_Interface;
    fbScenarioManager : FB_Scenario_Manager;
    fbSimulationManager : FB_Simulation_Manager;
    fbRuleEngine : FB_Rule_Engine;
    fbNVRAMManager : FB_NVRAM_Manager;

    fbBlackBox : FB_BlackBox_Recorder;
    fbAstroTimer : FB_Astro_Timer;
    fbAlarmManager : FB_Alarm_Manager;
    fbHistoryManager : FB_History_Manager;
    fbSafety : FB_Safety_Manager;
    fbStateManager : FB_State_Manager;
    fbWatchdog : FB_Watchdog;
    fbHMIInterface : FB_HMI_Interface;
    fbFaultLogger : FB_Fault_Logger;
    fbLogEvent : FB_LogEvent;
    
    L_Time_Diff : UDINT;
    L_Local_State : ST_System_State_Snapshot;
    L_Remote_State : ST_System_State_Snapshot;
    L_NVRAM_Cmd : BYTE;
    L_NVRAM_Offset : UDINT;
    L_NVRAM_Done : BOOL;
    L_NVRAM_Err : BOOL;
    L_NVRAM_ErrID : UDINT;
    L_BB_Record : ST_BlackBox_Record;
    L_BB_Freeze : BOOL;
    L_Scenario_Idx : INT;
        L_Last_Operator_Blocked : BOOL;
    L_Last_DHW_Heating_In_Service : BOOL;
    L_Last_DHW_Circ_In_Service : BOOL;
    L_Dangerous_Action_Armed : BOOL;
    L_Dangerous_Action_Deadline_MS : UDINT;
    L_Maintenance_Apply_Intent : BOOL;
    L_Last_System_Mode : E_System_Operating_Mode;
    L_Last_First_Fault_Type : INT;
    L_Last_First_Fault_Source : INT;
    L_Last_Root_Cause : E_System_Root_Cause;
    L_History_Event : ST_History_Record;
    L_History_Write_Event : BOOL;
    L_Last_Operator_Journal_Seq : UDINT;
    L_Last_Event_Code : UDINT;
    L_Last_Event_Value : REAL;
    L_Last_Event_Time_MS : UDINT;
    L_Gateway_Writes_Allowed : BOOL;

    L_Scenario_Req_Operator : E_SCENARIO_TYPE;
    L_Scenario_Req_Gateway  : E_SCENARIO_TYPE;
    L_Scenario_Req_Rule     : E_SCENARIO_TYPE;
    L_Scenario_Req_Final    : E_SCENARIO_TYPE; // TRACE ONLY: arbitration result before policy
    L_Scenario_Intent       : E_SCENARIO_TYPE;
L_Scenario_Source       : E_SCENARIO_SOURCE;
L_Scenario_Changed      : BOOL;
L_Last_Scenario_Change_Time : UDINT;

L_IO_Fault_Prev : BOOL;
L_Comm_Fault_Prev : BOOL;
L_Sensor_Fault_Prev : BOOL;
L_Subsystem_Fault_Prev : BOOL;
L_Mode_Prev : E_System_Operating_Mode;
L_User_Access_Denied_Prev : BOOL;

    L_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Last_Written_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Persist_Buffer_Changed : BOOL;
    L_Last_Persist_Write_MS : UDINT;
    L_Recovery_Done : BOOL;
    L_Persist_Struct : ST_Persist;
END_VAR

// ... (content unchanged until target section)

// === STAGE I2b: FINAL USER INTENT PUBLICATION ===
GVL_INTENT_USER.I_Scenario_Request := L_Scenario_Req_Gateway;
GVL_INTENT_USER.I_Dangerous_Action_Request := GVL_COMMAND.CMD_Dangerous_Action_Request;
GVL_INTENT_USER.I_Dangerous_Action_Confirm := GVL_COMMAND.CMD_Dangerous_Action_Confirm;
GVL_INTENT_USER.I_User_Access_Level := GVL_COMMAND.CMD_User_Access_Level;
GVL_INTENT_USER.I_Water_Valve_Test_Open := GVL_COMMAND.CMD_Water_Valve_Test_Open;
GVL_INTENT_USER.I_Water_Valve_Test_Close := GVL_COMMAND.CMD_Water_Valve_Test_Close;
GVL_INTENT_USER.I_Water_Valve_Test_Confirm := GVL_COMMAND.CMD_Water_Valve_Test_Confirm;
GVL_INTENT_USER.I_Gas_Valve_Test_Open := GVL_COMMAND.CMD_Gas_Valve_Test_Open;
GVL_INTENT_USER.I_Gas_Valve_Test_Close := GVL_COMMAND.CMD_Gas_Valve_Test_Close;
GVL_INTENT_USER.I_Gas_Valve_Test_Confirm := GVL_COMMAND.CMD_Gas_Valve_Test_Confirm;
GVL_INTENT_USER.I_Water_Selective_Recover := GVL_COMMAND.CMD_Water_Selective_Recover;
GVL_INTENT_USER.I_Gas_Selective_Recover := GVL_COMMAND.CMD_Gas_Selective_Recover;

// >>> BULK_SYNC_ANCHOR: PRG_System <<<
