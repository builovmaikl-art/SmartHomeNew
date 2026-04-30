PROGRAM PRG_System
VAR
    L_i : INT;
    L_Motion_Sensors_16 : ARRAY[1..16] OF BOOL;

    // --- ADAPTER LAYER ---
    L_Zone_Valves_8 : ARRAY[1..8] OF BOOL;
    L_Lighting_32   : ARRAY[1..32] OF BYTE;
    L_FloorTemps_8  : ARRAY[1..8] OF REAL;

    fbSimulationManager : FB_Simulation_Manager;
    fbRuleEngine : FB_Rule_Engine;
    fbBlackBox : FB_BlackBox_Recorder;
    fbAstroTimer : FB_Astro_Timer;
    fbHistoryManager : FB_History_Manager;
    fbLogEvent : FB_LogEvent;

    fbSystemScenarioArb : FB_System_Scenario_Arbitration;
    fbSystemGatewayIntent : FB_System_Gateway_Intent;
    fbSystemPersist : FB_System_Persist_Manager;
    fbSystemInit : FB_System_Init;
    fbSystemRecovery : FB_System_Recovery;
    fbTimebase : FB_System_Timebase;
    fbTime : FB_Time_Service;
    fbSystemRedundancy : FB_System_Redundancy_Orchestrator;
    fbSystemHealthOrchestrator : FB_System_Health_Orchestrator; // legacy not used
    fbSystemIntentPublisher : FB_System_Intent_Publisher;
    fbSystemEvacuation : FB_System_Evacuation;
    fbSystemAlarmOrchestrator : FB_System_Alarm_Orchestrator;
    
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
    L_Last_First_Fault_Source : INT;
    L_First_Fault_Active : BOOL;
    L_First_Fault_Type : INT;
    L_First_Fault_Source : INT;
    L_System_Severity : E_System_Severity;
    L_Root_Cause : E_System_Root_Cause;
    L_Watchdog_Fault : BOOL;
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
    L_Scenario_Req_Final    : E_SCENARIO_TYPE;
    L_Scenario_Intent       : E_SCENARIO_TYPE;
    L_Scenario_Source       : E_SCENARIO_SOURCE;
    L_Scenario_Changed      : BOOL;

    L_IO_Fault_Prev : BOOL;
    L_Mode_Prev : E_System_Operating_Mode;
    L_User_Access_Denied_Prev : BOOL;

    L_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Last_Written_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Persist_Buffer_Changed : BOOL;
    L_Last_Persist_Write_MS : UDINT;
    L_Recovery_Done : BOOL;
    L_Persist_Struct : ST_Persist;
END_VAR

fbSystemInit(
    VIO_Local_State := L_Local_State,
    VIO_Remote_State := L_Remote_State
);

fbSystemRecovery(
    VIO_Recovery_Done := L_Recovery_Done
);

fbTimebase();
fbTime();

fbSystemPersist(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VIO_Persist_Buffer := L_Persist_Buffer,
    VIO_Last_Written_Persist_Buffer := L_Last_Written_Persist_Buffer,
    VIO_Persist_Buffer_Changed := L_Persist_Buffer_Changed,
    VIO_Last_Persist_Write_MS := L_Last_Persist_Write_MS,
    VIO_NVRAM_Cmd := L_NVRAM_Cmd,
    VIO_NVRAM_Offset := L_NVRAM_Offset,
    VIO_NVRAM_Done := L_NVRAM_Done,
    VIO_NVRAM_Err := L_NVRAM_Err,
    VIO_NVRAM_ErrID := L_NVRAM_ErrID
);

fbSystemRedundancy(
    VIO_Local_State := L_Local_State,
    VIO_Remote_State := L_Remote_State
);

// Health moved to PRG_System_Health (MAIN)

L_Gateway_Writes_Allowed :=
    NOT GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm AND
    NOT GVL_STATUS.G_Diagnostics.Operator_Action_Blocked AND
    NOT GVL_STATUS.G_Diagnostics.User_Access_Denied;

fbSystemEvacuation();

fbAstroTimer(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Latitude := 55.75,
    VI_Longitude := 37.61,
    VI_Day_Of_Year := GVL_STATUS.G_Day_Of_Year,
    VO_Is_Night => GVL_STATUS.G_Is_Night
);

END_PROGRAM
