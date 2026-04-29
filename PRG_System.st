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
    fbSystemInit : FB_System_Init;
    fbSystemRecovery : FB_System_Recovery;
    fbTimebase : FB_System_Timebase;
    fbSystemRedundancy : FB_System_Redundancy_Orchestrator;
    fbSystemHealthOrchestrator : FB_System_Health_Orchestrator;
    fbSystemIntentPublisher : FB_System_Intent_Publisher;
    fbSystemEvacuation : FB_System_Evacuation;
    fbSystemAlarmOrchestrator : FB_System_Alarm_Orchestrator;
    
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

// 0. Инициализация RETAIN переменных при первом запуске
fbSystemInit(
    VIO_Local_State := L_Local_State,
    VIO_Remote_State := L_Remote_State
);

// === NVRAM RECOVERY (ONCE AFTER BOOT) ===
fbSystemRecovery(
    VIO_Recovery_Done := L_Recovery_Done
);

// NVRAM CONTROLLED WRITE ENABLED (step 8B)

// 1. Обновление системного времени
fbTimebase();

// 2-3. Redundancy / state sync
fbSystemRedundancy(
    VIO_Local_State := L_Local_State,
    VIO_Remote_State := L_Remote_State
);

// 3.4-3.7. Safety / health / state mode
fbSystemHealthOrchestrator(
    VO_First_Fault_Active => L_First_Fault_Active,
    VO_First_Fault_Type => L_First_Fault_Type,
    VO_First_Fault_Source => L_First_Fault_Source,
    VO_System_Severity => L_System_Severity,
    VO_Root_Cause => L_Root_Cause,
    VO_Watchdog_Fault => L_Watchdog_Fault
);

// === STAGE G2b: SYSTEM GATE PUBLICATION ===
fbSystemIntentPublisher(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Gateway_Writes_Allowed := L_Gateway_Writes_Allowed
);

// 3.6a. Эвакуация
fbSystemEvacuation();

// 4. Астрономический таймер
fbAstroTimer(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Latitude := 55.75,
    VI_Longitude := 37.61,
    VI_Day_Of_Year := GVL_STATUS.G_Day_Of_Year,
    VO_Is_Night => GVL_STATUS.G_Is_Night
);


// 5. Управление сценариями
// Scenario request (direct + early operator gate)
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
    L_Scenario_Req_Operator := GVL_COMMAND.G_Scenario_Request_Operator;
ELSE
    L_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;
L_Scenario_Req_Gateway := 0;
L_Scenario_Req_Rule := 0;







// Синхронизируем request с фактически активным сценарием


L_Scenario_Idx := TO_INT(GVL_STATUS.G_Current_Scenario);
IF L_Scenario_Idx < 0 OR L_Scenario_Idx > 7 THEN
    L_Scenario_Idx := 0;
END_IF;

// 6. Симуляция присутствия
fbSimulationManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC AND (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL),
    VI_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Config := GVL_CONFIG.G_HMI_Scenario_Configs[L_Scenario_Idx],
    VO_Sim_Lights => GVL_STATE.G_Sim_Lights,
    VO_Sim_Active => GVL_STATUS.G_Sim_Active
);

// 6.5. Пользовательские правила (Rule Engine)
fbRuleEngine(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
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
    VI_Current_Time := GVL_STATUS.G_Current_TOD,
    VI_Day_Of_Week := TO_INT(GVL_STATUS.G_Current_Day),
    VO_Actions => GVL_STATE.G_Rule_Actions
);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
    IF GVL_STATE.G_Rule_Actions[L_i].Active AND GVL_STATE.G_Rule_Actions[L_i].Action_Type = E_Rule_Action_Type.ACTION_ACTIVATE_SCENARIO THEN
        L_Scenario_Req_Rule := TO_BYTE(GVL_STATE.G_Rule_Actions[L_i].Value);
    END_IF;
END_FOR;



// 8.5 Менеджер тревог
fbSystemAlarmOrchestrator(
    VI_First_Fault_Active := L_First_Fault_Active,
    VI_First_Fault_Type := L_First_Fault_Type,
    VI_First_Fault_Source := L_First_Fault_Source
);

// Command arbitration: OPERATOR > GATEWAY
L_Gateway_Writes_Allowed :=
    NOT GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm AND
    NOT GVL_STATUS.G_Diagnostics.Operator_Action_Blocked AND
    NOT GVL_STATUS.G_Diagnostics.User_Access_Denied;

// 13. Интерфейс шлюза (Modbus TCP)
fbGateway(
    
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Local_PLC_Role := SEL(GVL_STATUS.G_Is_Active_PLC, E_PLC_ROLE.ROLE_STANDBY, E_PLC_ROLE.ROLE_ACTIVE),
    VI_Incoming_Command := GVL_GATEWAY.G_Gateway_Command,
    VI_Command_Received := GVL_GATEWAY.G_Gateway_Command_Received,
    VI_FloorHeating_Temps := L_FloorTemps_8,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
    VI_Zone_Valve_States := L_Zone_Valves_8,
    VI_Manifold_Pressures := GVL_STATE.G_Manifold_Pressures,
    VI_Manifold_Pump_States := GVL_STATE.G_Manifold_Pumps,
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VI_Flood_Alarm_Active := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Gas_Alarm_Active := GVL_ALARM.G_Gas_Alarm_Active,
    VI_Fire_Alarm_Active := GVL_ALARM.G_Fire_Alarm_Active,
    VI_Methane_Concentration := GVL_STATE.G_Methane_Sensors[1],
    VI_Lighting_Base_Levels := L_Lighting_32,
    VI_Socket_States := GVL_STATE.G_Socket_States,
    VI_Blinds_Positions := GVL_STATE.G_Blinds_Positions,
    VI_Active_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Send_2FA_Req := GVL_COMMAND.G_Send_2FA_Req,
    VI_2FA_Code := GVL_COMMAND.G_2FA_Code_Out,
    VI_Allowed_IPs := GVL_CONFIG.G_Allowed_IPs,
    VO_Telegram_Msg => GVL_GATEWAY.G_Gateway_Telegram_Msg,
    VO_Send_Telegram => GVL_GATEWAY.G_Gateway_Send_Telegram,
    VO_HMI_Status_Message => GVL_GATEWAY.G_Gateway_HMI_Status_Message,
    
    VO_Data_Ready => GVL_GATEWAY.G_Gateway_Data_Ready,
    VO_Modbus_Registers => GVL_GATEWAY.G_Gateway_Modbus_Registers,
    VO_Arm_Req => GVL_COMMAND.G_Arm_Req,
    VO_Disarm_Req => GVL_COMMAND.G_Disarm_Req,
    VO_PIN_Code => GVL_COMMAND.G_PIN_Code,
    VO_RFID_Tag => GVL_COMMAND.G_RFID_Tag,
    VO_2FA_Code_In => GVL_COMMAND.G_2FA_Code_In,
    VO_Lighting_Override => GVL_COMMAND.G_Lighting_Override,
    VO_Blinds_Override => GVL_COMMAND.G_Blinds_Override,
    VO_Socket_Override => GVL_COMMAND.G_Socket_Override,
    VO_Reset_Errors_Req => GVL_COMMAND.G_Reset_Errors
);

GVL_INTENT_USER.I_Source_Valid := TRUE;
GVL_INTENT_USER.I_Last_Update_MS := GVL_STATUS.G_System_Time_MS;
GVL_INTENT_USER.I_Arm_Request := GVL_COMMAND.G_Arm_Req;
GVL_INTENT_USER.I_Disarm_Request := GVL_COMMAND.G_Disarm_Req;
GVL_INTENT_USER.I_PIN_Code := GVL_COMMAND.G_PIN_Code;
GVL_INTENT_USER.I_RFID_Tag := GVL_COMMAND.G_RFID_Tag;
GVL_INTENT_USER.I_2FA_Code_In := GVL_COMMAND.G_2FA_Code_In;  
GVL_INTENT_USER.I_Lighting_Override_32 := GVL_COMMAND.G_Lighting_Override;
GVL_INTENT_USER.I_Blinds_Override_32 := GVL_COMMAND.G_Blinds_Override;
GVL_INTENT_USER.I_Socket_Override_32 := GVL_COMMAND.G_Socket_Override;
GVL_INTENT_USER.I_Reset_Errors := GVL_COMMAND.G_Reset_Errors;
GVL_INTENT_USER.I_Set_Temp_Req := fbGateway.VO_Set_Temp_Req;
GVL_INTENT_USER.I_Target_Zone := fbGateway.VO_Target_Zone;
GVL_INTENT_USER.I_Target_Temperature := fbGateway.VO_Target_Temp;
GVL_INTENT_USER.I_Set_Vent_Req := fbGateway.VO_Set_Vent_Req;
GVL_INTENT_USER.I_Target_Vent_Speed := fbGateway.VO_Target_Vent_Speed;
GVL_INTENT_USER.I_Set_Config_Req := fbGateway.VO_Set_Config_Req;
GVL_INTENT_USER.I_Time_Sync_Req := fbGateway.VO_Sync_Time_Req;
GVL_INTENT_USER.I_New_Time_MS := fbGateway.VO_New_Time_MS;

IF L_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Scenario_Req AND
   ((GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) OR
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED)) THEN
    L_Scenario_Req_Gateway := fbGateway.VO_Target_Scenario;
END_IF;

IF L_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Temp_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_CONFIG.G_HMI_FloorHeating_Configs[fbGateway.VO_Target_Zone].design_temp := fbGateway.VO_Target_Temp;
END_IF;

IF L_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Vent_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_CONFIG.G_HMI_Vent_Global_Config.default_supply_speed := fbGateway.VO_Target_Vent_Speed;
END_IF;

IF L_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Config_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_CONFIG.G_HMI_Apply_Settings := TRUE;
END_IF;

IF L_Gateway_Writes_Allowed AND
   fbGateway.VO_Sync_Time_Req AND
   (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) THEN
    GVL_STATUS.G_Time_Of_Day_MS := fbGateway.VO_New_Time_MS;
END_IF;


// === STAGE I2b: FINAL USER INTENT PUBLICATION ===
GVL_INTENT_USER.I_Scenario_Request := L_Scenario_Req_Gateway;
GVL_INTENT_USER.I_Gate_Open_Request := GVL_COMMAND.G_Gate_Open;
GVL_INTENT_USER.I_Wicket_Open_Request := GVL_COMMAND.G_Wicket_Open;
GVL_INTENT_USER.I_Lock_1_Open_Request := GVL_COMMAND.G_Lock_1_Open;
GVL_INTENT_USER.I_Lock_1_Close_Request := GVL_COMMAND.G_Lock_1_Close;
GVL_INTENT_USER.I_Lock_2_Open_Request := GVL_COMMAND.G_Lock_2_Open;
GVL_INTENT_USER.I_Lock_2_Close_Request := GVL_COMMAND.G_Lock_2_Close;
GVL_INTENT_USER.I_Dangerous_Action_Request := GVL_COMMAND.CMD_Dangerous_Action_Request;
GVL_INTENT_USER.I_Dangerous_Action_Confirm := GVL_COMMAND.CMD_Dangerous_Action_Confirm;
GVL_INTENT_USER.I_User_Access_Level := GVL_COMMAND.CMD_User_Access_Level;
GVL_INTENT_USER.I_Water_Selective_Recover := GVL_COMMAND.CMD_Water_Selective_Recover;
GVL_INTENT_USER.I_Gas_Selective_Recover := GVL_COMMAND.CMD_Gas_Selective_Recover;

// === SCENARIO REQUEST VALIDATION ===
// Normalize invalid values to NONE to avoid corrupt inputs.
// Actual enum range in E_SCENARIO_TYPE is 0..7.
IF TO_USINT(L_Scenario_Req_Operator) > 7 THEN
    L_Scenario_Req_Operator := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;

IF TO_USINT(L_Scenario_Req_Gateway) > 7 THEN
    L_Scenario_Req_Gateway := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;

IF TO_USINT(L_Scenario_Req_Rule) > 7 THEN
    L_Scenario_Req_Rule := E_SCENARIO_TYPE.SCENARIO_NONE;
END_IF;

// === SCENARIO PRIORITY RESOLUTION ===
// Produces L_Scenario_Req_Final (TRACE ONLY, not executed directly)
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN
    L_Scenario_Req_Final := 0;
    L_Scenario_Source := SRC_SAFETY;
ELSIF L_Scenario_Req_Operator <> 0 THEN
    L_Scenario_Req_Final := L_Scenario_Req_Operator;
    L_Scenario_Source := SRC_OPERATOR;
ELSIF L_Scenario_Req_Gateway <> 0 THEN
    L_Scenario_Req_Final := L_Scenario_Req_Gateway;
    L_Scenario_Source := SRC_GATEWAY;
ELSIF L_Scenario_Req_Rule <> 0 THEN
    L_Scenario_Req_Final := L_Scenario_Req_Rule;
    L_Scenario_Source := SRC_RULE;
ELSE
    L_Scenario_Req_Final := GVL_STATUS.G_Current_Scenario;
    L_Scenario_Source := SRC_NONE;
END_IF;

L_Scenario_Intent := L_Scenario_Req_Final;

// === FAIL-SAFE SCENARIO CLAMP ===
CASE GVL_STATE.G_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        L_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;

    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        L_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;

    E_System_Operating_Mode.MODE_DEGRADED:
        CASE L_Scenario_Intent OF
            E_SCENARIO_TYPE.SCENARIO_NONE,
            E_SCENARIO_TYPE.SCENARIO_PRESENCE,
            E_SCENARIO_TYPE.SCENARIO_AWAY,
            E_SCENARIO_TYPE.SCENARIO_SLEEP:
                ; // allowed in degraded
        ELSE
            L_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_NONE;
        END_CASE;
END_CASE;

// === CONTEXT FAIL-SAFE AUTOMATION ===
// If security is armed and no explicit source is requesting another scenario,
// force safe occupancy context to AWAY while system remains in MODE_NORMAL.
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
    IF GVL_ALARM.G_Security_Armed AND
       (L_Scenario_Req_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (L_Scenario_Req_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (L_Scenario_Req_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (L_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY) THEN

        IF L_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY THEN
            L_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
            L_Scenario_Source := SRC_POLICY;

            fbLogEvent(
                VI_Event_Type := 5,
                VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                VI_Param1 := TO_UDINT(L_Scenario_Source),
                VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
            );
        END_IF;
    END_IF;
END_IF;

// === DEGRADED-AWARE SCENARIO ADAPTATION ===
// Soft adaptation in degraded mode: keep explicit requests intact,
// but if no source is requesting a scenario, move behavior to a safer baseline.
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED THEN
    IF (L_Scenario_Req_Operator = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (L_Scenario_Req_Gateway = E_SCENARIO_TYPE.SCENARIO_NONE) AND
       (L_Scenario_Req_Rule = E_SCENARIO_TYPE.SCENARIO_NONE) THEN

        IF GVL_ALARM.G_Security_Armed THEN
            IF L_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_AWAY THEN
                L_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_AWAY;
                L_Scenario_Source := SRC_POLICY;

                fbLogEvent(
                    VI_Event_Type := 6,
                    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                    VI_Param1 := TO_UDINT(L_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
                );
            END_IF;

        ELSIF L_Scenario_Intent = E_SCENARIO_TYPE.SCENARIO_PRESENCE THEN
            IF L_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_SLEEP THEN
                L_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_SLEEP;
                L_Scenario_Source := SRC_POLICY;

                fbLogEvent(
                    VI_Event_Type := 7,
                    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                    VI_Param1 := TO_UDINT(L_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_SLEEP)
                );
            END_IF;
        END_IF;
    END_IF;
END_IF;

fbScenarioManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Activate_Request := L_Scenario_Intent,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VO_Current_Scenario => GVL_STATUS.G_Current_Scenario
);



// 14. Менеджер NVRAM
// Pack persistent snapshot into compact byte buffer for controlled NVRAM mirroring
L_Persist_Buffer[0] := TO_BYTE(TO_INT(GVL_STATE.G_System_Mode));
IF GVL_PERSISTENT.P_Safety_Gas_Latched THEN
    L_Persist_Buffer[1] := BYTE#1;
ELSE
    L_Persist_Buffer[1] := BYTE#0;
END_IF;
IF GVL_PERSISTENT.P_Safety_Smoke_Latched THEN
    L_Persist_Buffer[2] := BYTE#1;
ELSE
    L_Persist_Buffer[2] := BYTE#0;
END_IF;
IF GVL_PERSISTENT.P_Safety_Leak_Latched THEN
    L_Persist_Buffer[3] := BYTE#1;
ELSE
    L_Persist_Buffer[3] := BYTE#0;
END_IF;
IF GVL_PERSISTENT.P_DHW_Heating_Active THEN
    L_Persist_Buffer[4] := BYTE#1;
ELSE
    L_Persist_Buffer[4] := BYTE#0;
END_IF;

L_Persist_Buffer_Changed :=
    (L_Persist_Buffer[0] <> L_Last_Written_Persist_Buffer[0]) OR
    (L_Persist_Buffer[1] <> L_Last_Written_Persist_Buffer[1]) OR
    (L_Persist_Buffer[2] <> L_Last_Written_Persist_Buffer[2]) OR
    (L_Persist_Buffer[3] <> L_Last_Written_Persist_Buffer[3]) OR
    (L_Persist_Buffer[4] <> L_Last_Written_Persist_Buffer[4]);

L_NVRAM_Cmd := 0;
L_NVRAM_Offset := 0;

IF GVL_CONFIG.G_HMI_Apply_Settings THEN
    // explicit config apply may request a controlled write
    L_NVRAM_Cmd := 1;
    GVL_CONFIG.G_HMI_Apply_Settings := FALSE;

ELSIF L_Persist_Buffer_Changed THEN
    // controlled write: no more often than once per 60 seconds
    IF (L_Last_Persist_Write_MS = 0) OR
       ((GVL_STATUS.G_System_Time_MS - L_Last_Persist_Write_MS) >= 60000) THEN
        L_NVRAM_Cmd := 1;
    END_IF;
END_IF;

fbNVRAMManager(
    VI_Command := L_NVRAM_Cmd,
    VI_Offset := L_NVRAM_Offset,
    VI_DataRef := L_Persist_Buffer[0],
    VI_DataSize := 5,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Operator_ID := 'SYSTEM',
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_TwoPersonConfirmation := FALSE,
    VO_Done => L_NVRAM_Done,
    VO_Error => L_NVRAM_Err,
    VO_ErrorID => L_NVRAM_ErrID
);

IF (L_NVRAM_Cmd = 1) AND L_NVRAM_Done AND NOT L_NVRAM_Err THEN
    L_Last_Written_Persist_Buffer[0] := L_Persist_Buffer[0];
    L_Last_Written_Persist_Buffer[1] := L_Persist_Buffer[1];
    L_Last_Written_Persist_Buffer[2] := L_Persist_Buffer[2];
    L_Last_Written_Persist_Buffer[3] := L_Persist_Buffer[3];
    L_Last_Written_Persist_Buffer[4] := L_Persist_Buffer[4];
    L_Last_Persist_Write_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

// 15. Черный ящик
L_BB_Record.Timestamp := GVL_STATUS.G_System_Time_MS;
L_BB_Record.PLC_Active_ID := GVL_STATUS.G_PLC_ID;
L_BB_Record.Gas_Methane_LEL := GVL_STATE.G_Methane_Sensors[1];
L_BB_Record.Gas_CO_PPM := GVL_STATE.G_CO_Sensors[1];
L_BB_Record.Flood_Active := GVL_ALARM.G_Flood_Alarm_Active;
L_BB_Record.Fire_Active := GVL_ALARM.G_Fire_Alarm_Active;
L_BB_Record.Valve_Gas_Status := SEL(GVL_COMMAND.G_Gas_Valve_Close, BYTE#0, BYTE#1);
L_BB_Record.Valve_Water_Status := SEL((GVL_COMMAND.G_Close_Valve_35 OR GVL_COMMAND.G_Close_Valve_36), BYTE#0, BYTE#1);

L_BB_Record.System_Mode := TO_BYTE(TO_INT(GVL_STATE.G_System_Mode));
L_BB_Record.First_Fault_Type := TO_BYTE(TO_INT(L_First_Fault_Type));
L_BB_Record.First_Fault_Source := TO_BYTE(TO_INT(L_First_Fault_Source));
L_BB_Record.First_Fault_Active := L_First_Fault_Active;
L_BB_Record.System_Severity := TO_BYTE(TO_INT(L_System_Severity));
L_BB_Record.Root_Cause := TO_BYTE(TO_INT(L_Root_Cause));
L_BB_Record.Watchdog_Fault := L_Watchdog_Fault;


L_BB_Freeze := GVL_ALARM.G_Gas_Alarm_Active OR GVL_ALARM.G_Fire_Alarm_Active OR GVL_ALARM.G_Flood_Alarm_Active OR L_First_Fault_Active;

fbBlackBox(
    VI_Current_Data := L_BB_Record,
    VI_Freeze := L_BB_Freeze
);

// 15.1. Менеджер истории / diagnostics bridge
L_History_Write_Event := FALSE;
L_History_Event.timestamp_ms := GVL_STATUS.G_System_Time_MS;
L_History_Event.event_code := 0;
L_History_Event.event_value := 0.0;
L_History_Event.unit := 0;
L_History_Event.zone_id := 0;
L_History_Event.operator_id := 'SYSTEM';
L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;

IF GVL_STATE.G_System_Mode <> L_Last_System_Mode THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1101; // System mode transition
    L_History_Event.event_value := TO_REAL(TO_INT(GVL_STATE.G_System_Mode));
    L_History_Event.unit := 1; // system mode domain
    L_History_Event.zone_id := 0;
    IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL THEN
        L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    ELSE
        L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    END_IF;
    L_Last_System_Mode := GVL_STATE.G_System_Mode;

ELSIF L_Root_Cause <> L_Last_Root_Cause THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1102; // Root cause changed
    L_History_Event.event_value := TO_REAL(TO_INT(L_Root_Cause));
    L_History_Event.unit := 2; // root cause enum domain
    L_History_Event.zone_id := TO_BYTE(L_First_Fault_Source);
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_Root_Cause := L_Root_Cause;

ELSIF L_First_Fault_Source <> L_Last_First_Fault_Source THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1103; // First fault source changed
    L_History_Event.event_value := TO_REAL(L_First_Fault_Source);
    L_History_Event.unit := 3; // root cause source domain
    L_History_Event.zone_id := TO_BYTE(L_First_Fault_Source);
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_First_Fault_Source := L_First_Fault_Source;

ELSIF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1001; // Scenario transition
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Current_Scenario);
    L_History_Event.unit := 4; // scenario domain
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    GVL_STATUS.G_Previous_Scenario := GVL_STATUS.G_Current_Scenario;

ELSIF GVL_STATUS.G_Diagnostics.Alarm_Event_Pulse THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := TO_WORD(GVL_STATUS.G_Diagnostics.Alarm_Event_Code);
    L_History_Event.event_value := GVL_STATUS.G_Diagnostics.Alarm_Event_Value;
    L_History_Event.unit := 10; // alarm lifecycle domain
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;

ELSIF GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq <> L_Last_Operator_Journal_Seq THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1301; // Operator journal event
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq);
    L_History_Event.unit := 20; // operator journal domain
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_Operator_Journal_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq;
END_IF;

// --- History anti-flood / dedup ---
IF L_History_Write_Event THEN
    IF (L_History_Event.event_code = L_Last_Event_Code)
       AND (ABS(L_History_Event.event_value - L_Last_Event_Value) < 0.001)
       AND (GVL_STATUS.G_System_Time_MS - L_Last_Event_Time_MS < 5000) THEN
        L_History_Write_Event := FALSE;
    ELSE
        L_Last_Event_Code := L_History_Event.event_code;
        L_Last_Event_Value := L_History_Event.event_value;
        L_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
    END_IF;
END_IF;

fbHistoryManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Write_Event := L_History_Write_Event,
    VI_Event := L_History_Event
);


L_Maintenance_Apply_Intent := FALSE;

// Dangerous action confirmation flow
IF GVL_COMMAND.CMD_Dangerous_Action_Request AND (GVL_COMMAND.CMD_User_Access_Level >= 2) THEN

    IF NOT L_Dangerous_Action_Armed THEN
        fbLogEvent(
            VI_Event_Type := 8,
            VI_Timestamp := GVL_STATUS.G_System_Time_MS,
            VI_Param1 := TO_UDINT(GVL_COMMAND.CMD_User_Access_Level),
            VI_Param2 := 1
        );
    END_IF;

    L_Dangerous_Action_Armed := TRUE;
    L_Dangerous_Action_Deadline_MS := GVL_STATUS.G_System_Time_MS + 15000;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := TRUE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Deadline_MS := L_Dangerous_Action_Deadline_MS;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Подтвердите опасное действие в течение 15 секунд';
END_IF;
IF L_Dangerous_Action_Armed AND (GVL_STATUS.G_System_Time_MS > L_Dangerous_Action_Deadline_MS) THEN
    L_Dangerous_Action_Armed := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Окно подтверждения истекло';
END_IF;
IF GVL_COMMAND.CMD_Dangerous_Action_Confirm AND
   L_Dangerous_Action_Armed AND
   (GVL_COMMAND.CMD_User_Access_Level >= 2) THEN
    L_Maintenance_Apply_Intent := TRUE;

    fbLogEvent(
        VI_Event_Type := 9,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(GVL_COMMAND.CMD_User_Access_Level),
        VI_Param2 := 1
    );

    L_Dangerous_Action_Armed := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Опасное действие подтверждено оператором';
END_IF;

// HMI maintenance mode control (confirmation-aware)
IF L_Maintenance_Apply_Intent THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] := GVL_COMMAND.CMD_Set_Manifold_Pump_In_Service[L_i];
    END_FOR;
    GVL_CONFIG.G_DHW_Heating_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Heating_Pump_In_Service;
    GVL_CONFIG.G_DHW_Circ_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Circ_Pump_In_Service;
END_IF;

// Access level enforcement for dangerous actions
GVL_STATUS.G_Diagnostics.User_Access_Level_Active := GVL_COMMAND.CMD_User_Access_Level;
GVL_STATUS.G_Diagnostics.User_Access_Denied := FALSE;
GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := '';
IF GVL_COMMAND.CMD_Dangerous_Action_Request OR GVL_COMMAND.CMD_Dangerous_Action_Confirm THEN
    IF GVL_COMMAND.CMD_User_Access_Level < 2 THEN
        IF NOT L_User_Access_Denied_Prev THEN
            fbLogEvent(
                VI_Event_Type := 10,
                VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                VI_Param1 := TO_UDINT(GVL_COMMAND.CMD_User_Access_Level),
                VI_Param2 := 2
            );
        END_IF;

        GVL_STATUS.G_Diagnostics.User_Access_Denied := TRUE;
        GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := 'Недостаточный уровень доступа для опасного действия';
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Требуется уровень ENGINEER для опасного действия';
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Доступ запрещён: требуется уровень ENGINEER';
    END_IF;
END_IF;

L_User_Access_Denied_Prev := GVL_STATUS.G_Diagnostics.User_Access_Denied;

// Hard revert for forbidden operator actions
IF GVL_STATUS.G_Diagnostics.Operator_Action_Blocked THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
            GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] := TRUE;
        END_IF;
    END_FOR;
    IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
        GVL_CONFIG.G_DHW_Heating_Pump_In_Service := TRUE;
    END_IF;
    IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
        GVL_CONFIG.G_DHW_Circ_Pump_In_Service := TRUE;
    END_IF;
    GVL_STATUS.G_Diagnostics.Operator_Last_Forbidden_Action := GVL_STATUS.G_Diagnostics.Operator_Block_Reason;
END_IF;

// Operator action journal
IF GVL_STATUS.G_Diagnostics.Operator_Action_Blocked AND NOT L_Last_Operator_Blocked THEN
    GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
END_IF;
L_Last_Operator_Blocked := GVL_STATUS.G_Diagnostics.Operator_Action_Blocked;
IF GVL_CONFIG.G_DHW_Heating_Pump_In_Service <> L_Last_DHW_Heating_In_Service THEN
    GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
    IF GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС возвращён из ТО';
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС выведен в ТО';
    END_IF;
END_IF;
L_Last_DHW_Heating_In_Service := GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service <> L_Last_DHW_Circ_In_Service THEN
    GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
    IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС возвращён из ТО';
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС выведен в ТО';
    END_IF;
END_IF;
L_Last_DHW_Circ_In_Service := GVL_CONFIG.G_DHW_Circ_Pump_In_Service;
IF GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq <> GVL_STATUS.G_Diagnostics.Operator_Journal_Last_Seq THEN
    GVL_STATUS.G_Diagnostics.Operator_Journal_3 := GVL_STATUS.G_Diagnostics.Operator_Journal_2;
    GVL_STATUS.G_Diagnostics.Operator_Journal_2 := GVL_STATUS.G_Diagnostics.Operator_Journal_1;
    IF GVL_STATUS.G_Diagnostics.Operator_Last_Forbidden_Action <> '' THEN
        GVL_STATUS.G_Diagnostics.Operator_Journal_1 := GVL_STATUS.G_Diagnostics.Operator_Last_Forbidden_Action;
    ELSE
        GVL_STATUS.G_Diagnostics.Operator_Journal_1 := GVL_STATUS.G_Diagnostics.Maintenance_Last_Action;
    END_IF;
    GVL_STATUS.G_Diagnostics.Operator_Journal_Last_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq;
END_IF;

// ========================================
// CoreKernel live observer (diagnostic only)
// ========================================
// fbCoreKernelObserver disabled temporarily


// === NVRAM SNAPSHOT VIA STRUCT ADAPTER ===
L_Persist_Struct.System_Mode := GVL_STATE.G_System_Mode;

L_Persist_Struct.Safety_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched;
L_Persist_Struct.Safety_Smoke_Latched := GVL_STATE.G_Safety_Smoke_Latched;
L_Persist_Struct.Safety_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched;

L_Persist_Struct.DHW_Heating_Pump := GVL_STATE.G_DHW_Heating_Pump;
L_Persist_Struct.Valid := TRUE;

// mirror to legacy persistent variables
GVL_PERSISTENT.P_System_Mode := L_Persist_Struct.System_Mode;

GVL_PERSISTENT.P_Safety_Gas_Latched := L_Persist_Struct.Safety_Gas_Latched;
GVL_PERSISTENT.P_Safety_Smoke_Latched := L_Persist_Struct.Safety_Smoke_Latched;
GVL_PERSISTENT.P_Safety_Leak_Latched := L_Persist_Struct.Safety_Leak_Latched;

GVL_PERSISTENT.P_DHW_Heating_Active := L_Persist_Struct.DHW_Heating_Pump;
GVL_PERSISTENT.P_Valid := L_Persist_Struct.Valid;

// >>> BULK_SYNC_ANCHOR: PRG_System <<<

// === EVENT LOGGING: SCENARIO CHANGE ===
IF L_Scenario_Changed THEN
    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(L_Scenario_Intent)
    );
END_IF;

// === EVENT LOGGING: FAULTS ===

// IO
IF fbSystemHealth.VO_IO_Fault AND NOT L_IO_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 2,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 1
    );
END_IF;

IF NOT fbSystemHealth.VO_IO_Fault AND L_IO_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 3,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 0
    );
END_IF;

L_IO_Fault_Prev := fbSystemHealth.VO_IO_Fault;

// === EVENT LOGGING: MODE CHANGE ===
IF GVL_STATE.G_System_Mode <> L_Mode_Prev THEN
    fbLogEvent(
        VI_Event_Type := 4,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Mode_Prev),
        VI_Param2 := TO_UDINT(GVL_STATE.G_System_Mode)
    );
END_IF;

L_Mode_Prev := GVL_STATE.G_System_Mode;

