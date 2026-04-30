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
    fbSystemHealthOrchestrator : FB_System_Health_Orchestrator;
    fbSystemIntentPublisher : FB_System_Intent_Publisher; // legacy kept but NOT USED
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

fbSystemHealthOrchestrator(
    VO_First_Fault_Active => L_First_Fault_Active,
    VO_First_Fault_Type => L_First_Fault_Type,
    VO_First_Fault_Source => L_First_Fault_Source,
    VO_System_Severity => L_System_Severity,
    VO_Root_Cause => L_Root_Cause,
    VO_Watchdog_Fault => L_Watchdog_Fault
);

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

IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
    L_Scenario_Req_Operator := GVL_COMMAND.G_Scenario_Request_Operator;
ELSE
    L_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;
L_Scenario_Req_Gateway := 0;
L_Scenario_Req_Rule := 0;

L_Scenario_Idx := TO_INT(GVL_STATUS.G_Current_Scenario);
IF L_Scenario_Idx < 0 OR L_Scenario_Idx > 7 THEN
    L_Scenario_Idx := 0;
END_IF;

fbSystemScenarioArb(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VIO_Scenario_Req_Operator := L_Scenario_Req_Operator,
    VIO_Scenario_Req_Gateway := L_Scenario_Req_Gateway,
    VIO_Scenario_Req_Rule := L_Scenario_Req_Rule,
    VIO_Scenario_Req_Final := L_Scenario_Req_Final,
    VIO_Scenario_Intent := L_Scenario_Intent,
    VIO_Scenario_Source := L_Scenario_Source
);

fbSimulationManager(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC AND (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL),
    VI_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Config := GVL_CONFIG.G_HMI_Scenario_Configs[L_Scenario_Idx],
    VO_Sim_Lights => GVL_STATE.G_Sim_Lights,
    VO_Sim_Active => GVL_STATUS.G_Sim_Active
);

fbRuleEngine(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Rules := GVL_CONFIG.G_HMI_User_Rules,
    VI_Indoor_Temps := GVL_STATE.G_Room_Temps,
    VI_Floor_Temps := L_FloorTemps_8,
    VI_Humidities := GVL_STATE.G_Room_Hum,
    VI_CO2_Levels := GVL_STATE.G_Room_CO2,
    VI_Motion_Sensors := L_Motion_Sensors_16,
    VI_Door_Sensors := GVL_STATE.G_Door_Sensors,
    VI_Window_Sensors := GVL_STATE.G_Window_Sensors,
    VI_Water_Sensors := GVL_STATE.G_Water_Sensors,
    VI_Smoke_Sensors := GVL_STATE.G_Smoke_Sensors,
    VI_Methane_Sensors := GVL_STATE.G_Methane_Sensors,
    VI_CO_Sensors := GVL_STATE.G_CO_Sensors,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VI_Current_Time := GVL_TIME_SERVICE.G_Current_TOD,
    VI_Day_Of_Week := GVL_TIME_SERVICE.G_Day_Of_Week,
    VO_Actions => GVL_STATE.G_Rule_Actions
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
    IF GVL_STATE.G_Rule_Actions[L_i].Active AND GVL_STATE.G_Rule_Actions[L_i].Action_Type = E_Rule_Action_Type.ACTION_ACTIVATE_SCENARIO THEN
        L_Scenario_Req_Rule := TO_BYTE(GVL_STATE.G_Rule_Actions[L_i].Value);
    END_IF;
END_FOR;

fbSystemAlarmOrchestrator(
    VI_First_Fault_Active := L_First_Fault_Active,
    VI_First_Fault_Type := L_First_Fault_Type,
    VI_First_Fault_Source := L_First_Fault_Source
);

fbSystemGatewayIntent(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Gateway_Writes_Allowed := L_Gateway_Writes_Allowed,
    VIO_FloorHeating_Temps := L_FloorTemps_8,
    VIO_Zone_Valve_States := L_Zone_Valves_8,
    VIO_Lighting_Base_Levels := L_Lighting_32,
    VIO_Scenario_Req_Gateway := L_Scenario_Req_Gateway
);

END_PROGRAM
