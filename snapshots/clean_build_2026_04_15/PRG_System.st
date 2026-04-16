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
    
    L_Time_Diff : UDINT;
    L_Local_State : ST_System_State_Snapshot;
    L_Remote_State : ST_System_State_Snapshot;
    L_Config_Loaded : BOOL;
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
END_VAR

// 0. Инициализация RETAIN переменных при первом запуске
IF NOT GVL_Retain.G_Initialized THEN
    FOR L_i := 0 TO GVL_CONSTANTS.C_MAX_PRESENCE_HISTORY - 1 DO
        GVL_Retain.G_Presence_History[L_i] := 0;
    END_FOR;
    
    GVL_Retain.G_History_Write_Idx := 1;
    GVL_Retain.G_History_Total_Events := 0;
    
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        GVL_Retain.G_Boiler_Accumulated_MS[L_i] := 0;
        GVL_Retain.G_Boiler_Work_Seconds[L_i] := 0;
    END_FOR;
    
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_Retain.G_Valve_Test_Results[L_i] := FALSE;
    END_FOR;
    
    L_Local_State.Version := 0;
    L_Remote_State.Version := 0;
    
    GVL_Retain.G_Initialized := TRUE;
END_IF;

// 1. Обновление системного времени
GVL_STATUS.G_System_Time_MS := TIME_TO_UDINT(TIME());
L_Time_Diff := (SEL(GVL_STATUS.G_System_Time_MS >= GVL_STATUS.G_Last_System_Time_MS, GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Last_System_Time_MS, (4294967295 - GVL_STATUS.G_Last_System_Time_MS) + GVL_STATUS.G_System_Time_MS + 1));
GVL_STATUS.G_Time_Of_Day_MS := (GVL_STATUS.G_Time_Of_Day_MS + L_Time_Diff) MOD 86400000;

IF GVL_STATUS.G_Time_Of_Day_MS < L_Time_Diff THEN
    GVL_STATUS.G_Current_Day := (GVL_STATUS.G_Current_Day MOD 7) + 1;
    GVL_STATUS.G_Day_Of_Year := (GVL_STATUS.G_Day_Of_Year MOD 365) + 1;
END_IF;

GVL_STATUS.G_Last_System_Time_MS := GVL_STATUS.G_System_Time_MS;
GVL_STATUS.G_Current_TOD := UDINT_TO_TOD(GVL_STATUS.G_Time_Of_Day_MS);

// Формирование локального состояния для репликации
L_Local_State.System_Time_MS := GVL_STATUS.G_System_Time_MS;
L_Local_State.Current_Scenario := GVL_STATUS.G_Current_Scenario;
L_Local_State.Security_Armed := GVL_ALARM.G_Security_Armed;
L_Local_State.Active_Alarms := GVL_ALARM.G_Active_Alarm_Count;
L_Local_State.Zone_Valves := GVL_STATE.G_Zone_Valves;
L_Local_State.Manifold_Pumps := GVL_STATE.G_Manifold_Pumps;
L_Local_State.Lighting_States := GVL_STATE.G_Lighting_Levels;
L_Local_State.Blinds_Positions := GVL_STATE.G_Blinds_Positions;
L_Local_State.Socket_States := GVL_STATE.G_Socket_States;
L_Local_State.Gas_Valve_Closed := GVL_COMMAND.G_Gas_Valve_Close;
L_Local_State.Water_Valves_Closed := GVL_COMMAND.G_Close_Valve_36;
L_Local_State.Version := L_Local_State.Version + 1;

// 2. Определение роли ПЛК (Active/Standby)
fbRedundancy(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Local_PLC_ID := GVL_STATUS.G_PLC_ID,
    VI_Remote_Pulse := GVL_IO.DI_Partner_Pulse,
    VI_Remote_Is_Active := GVL_IO.DI_Partner_Active,
    VI_Gateway_Ping_OK := GVL_GATEWAY.G_Gateway_Ping_OK,
    VI_Local_State := L_Local_State,
    VI_Remote_State := L_Remote_State
);
GVL_STATUS.G_Is_Active_PLC := (fbRedundancy.VO_Local_Role = E_PLC_ROLE.ROLE_ACTIVE);
GVL_IO.DO_Heartbeat_Pulse := fbRedundancy.VO_Local_Pulse;
GVL_IO.DO_Active_Status := GVL_STATUS.G_Is_Active_PLC;

// 3. Синхронизация состояния (применение полученного состояния)
IF fbRedundancy.VO_State_Updated THEN
    GVL_STATUS.G_Current_Scenario := fbRedundancy.VO_Synced_State.Current_Scenario;
    GVL_ALARM.G_Security_Armed := fbRedundancy.VO_Synced_State.Security_Armed;
    GVL_STATE.G_Zone_Valves := fbRedundancy.VO_Synced_State.Zone_Valves;
    GVL_STATE.G_Manifold_Pumps := fbRedundancy.VO_Synced_State.Manifold_Pumps;
    GVL_STATE.G_Lighting_Levels := fbRedundancy.VO_Synced_State.Lighting_States;
    GVL_STATE.G_Blinds_Positions := fbRedundancy.VO_Synced_State.Blinds_Positions;
    GVL_STATE.G_Socket_States := fbRedundancy.VO_Synced_State.Socket_States;
    GVL_COMMAND.G_Gas_Valve_Close := fbRedundancy.VO_Synced_State.Gas_Valve_Closed;
    GVL_COMMAND.G_Close_Valve_36 := fbRedundancy.VO_Synced_State.Water_Valves_Closed;
    L_Local_State.Version := fbRedundancy.VO_Synced_State.Version;
END_IF;

fbSafety(
    VI_Gas_Alarm := GVL_STATE.G_Safety_Gas_Alarm,
    VI_Leak_Alarm := GVL_STATE.G_Safety_Leak_Alarm,
    VI_Smoke_Alarm := GVL_STATE.G_Safety_Smoke_Alarm,
    VI_Reset := GVL_COMMAND.G_Reset_Errors,
    VO_Gas_Latched => GVL_STATE.G_Safety_Gas_Latched,
    VO_Leak_Latched => GVL_STATE.G_Safety_Leak_Latched,
    VO_Smoke_Latched => GVL_STATE.G_Safety_Smoke_Latched,
    VO_Emergency_Stop => GVL_STATE.G_Safety_Emergency_Stop
);

// 3.4. Агрегация состояния anti-freeze hardware
GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;

// 3.6. Health manager: новая интеграция safety + diagnostics + watchdog
fbWatchdog(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

fbSystemHealth(
    VI_Smoke_Detected := GVL_HEALTH_BRIDGE.G_Smoke_Detected OR GVL_STATE.G_Safety_Smoke_Latched,
    VI_Gas_Detected := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_STATE.G_Safety_Gas_Latched,
    VI_CO_Warning_Level := GVL_HEALTH_BRIDGE.G_CO_Warning_Level,
    VI_CO_Alarm_Level := GVL_HEALTH_BRIDGE.G_CO_Alarm_Level,
    VI_Leak_Detected := GVL_HEALTH_BRIDGE.G_Leak_Detected OR GVL_STATE.G_Safety_Leak_Latched,
    VI_Sensor_Fault := GVL_STATE.G_Heating_Sensor_Fault OR GVL_STATE.G_DHW_Sensor_Fault,
    VI_IO_Offline := GVL_STATE.G_Heating_IO_Fault OR GVL_STATE.G_DHW_IO_Fault OR GVL_STATE.G_Ventilation_IO_Fault OR GVL_STATE.G_Lighting_IO_Fault,
    VI_Comm_Fault := GVL_STATE.G_Access_Comm_Fault,
    VI_Watchdog_Fault := fbWatchdog.VO_Watchdog_Fault,
    VI_Subsystem_Fault := GVL_STATE.G_Heating_Subsystem_Degraded OR GVL_STATE.G_DHW_Subsystem_Degraded OR GVL_STATE.G_Ventilation_Subsystem_Degraded
);

// 3.6. State manager: агрегированная логика режима работы
fbStateManager(
    VI_System_Severity := fbSystemHealth.VO_System_Severity,
    VI_Root_Cause := fbSystemHealth.VO_Root_Cause,
    VI_Freeze_Risk := GVL_STATE.G_Safety_Freeze_Risk
);

fbHMIInterface(
    VI_Severity := fbSystemHealth.VO_System_Severity,
    VI_RootCause := fbSystemHealth.VO_Root_Cause,
    VI_Status_Msg := fbStateManager.VO_Status_Msg
);

fbFaultLogger(
    VI_Severity := fbSystemHealth.VO_System_Severity,
    VI_RootCause := fbSystemHealth.VO_Root_Cause,
    VI_Time_MS := GVL_STATUS.G_System_Time_MS
);

// publish integrated outputs
GVL_STATUS.G_System_Mode_Msg := fbStateManager.VO_Status_Msg;

// === DIAGNOSTIC FLAGS (export) ===
GVL_STATUS.G_Diagnostics.Sensor_Fault :=
    GVL_STATE.G_Heating_Sensor_Fault OR
    GVL_STATE.G_DHW_Sensor_Fault;

GVL_STATUS.G_Diagnostics.IO_Offline :=
    GVL_STATE.G_Heating_IO_Fault OR
    GVL_STATE.G_DHW_IO_Fault OR
    GVL_STATE.G_Ventilation_IO_Fault OR
    GVL_STATE.G_Lighting_IO_Fault;

GVL_STATUS.G_Diagnostics.Subsystem_Degraded :=
    GVL_STATE.G_Heating_Subsystem_Degraded OR
    GVL_STATE.G_DHW_Subsystem_Degraded OR
    GVL_STATE.G_Ventilation_Subsystem_Degraded;

GVL_GATEWAY.G_Gateway_HMI_Status_Message := fbHMIInterface.VO_HMI_Status_Text;
IF fbFaultLogger.VO_Last_Event_Text <> '' THEN
    GVL_HEALTH_BRIDGE.G_Last_Fault_Event_Text := fbFaultLogger.VO_Last_Event_Text;
END_IF;

// 3.7. Применение вычисленного режима системы
GVL_STATE.G_System_Mode := fbStateManager.VO_System_Mode;

CASE GVL_STATE.G_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        GVL_STATE.G_System_Mode_Text := 'SAFE_STOP';

    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        GVL_STATE.G_System_Mode_Text := 'FREEZE_PROTECTION';

    E_System_Operating_Mode.MODE_DEGRADED:
        GVL_STATE.G_System_Mode_Text := 'DEGRADED';

    ELSE
        GVL_STATE.G_System_Mode_Text := 'NORMAL';
END_CASE;

CASE fbSystemHealth.VO_Root_Cause OF
    E_System_Root_Cause.ROOT_FIRE:
        GVL_STATUS.G_System_Mode_Cause := 'Пожар/дым';
    E_System_Root_Cause.ROOT_GAS_LEAK:
        GVL_STATUS.G_System_Mode_Cause := 'Утечка газа';
    E_System_Root_Cause.ROOT_CO_CRITICAL:
        GVL_STATUS.G_System_Mode_Cause := 'Критический CO';
    E_System_Root_Cause.ROOT_CO_WARNING:
        GVL_STATUS.G_System_Mode_Cause := 'Повышенный CO';
    E_System_Root_Cause.ROOT_WATER_LEAK:
        GVL_STATUS.G_System_Mode_Cause := 'Протечка воды';
    E_System_Root_Cause.ROOT_WATCHDOG_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка watchdog';
    E_System_Root_Cause.ROOT_IO_OFFLINE:
        GVL_STATUS.G_System_Mode_Cause := 'Недоступен модуль IO';
    E_System_Root_Cause.ROOT_COMM_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка связи';
    E_System_Root_Cause.ROOT_SENSOR_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка датчика';
    E_System_Root_Cause.ROOT_SUBSYSTEM_FAULT:
        GVL_STATUS.G_System_Mode_Cause := 'Ошибка подсистемы';
    ELSE
        GVL_STATUS.G_System_Mode_Cause := 'Аварийные режимы отсутствуют';
END_CASE;

// final status text comes from State_Manager
GVL_STATUS.G_System_Mode_Msg := fbStateManager.VO_Status_Msg;

// 3.6a. Расчёт направленной эвакуации
FOR L_i := 1 TO 32 DO
    GVL_STATE.G_Evac_Guidance[L_i] := 0;

    IF GVL_STATE.G_Evac_Hazard_Zone[L_i] THEN
        GVL_STATE.G_Evac_Guidance[L_i] := -1;
    END_IF;

    IF GVL_CONFIG.G_Evac_Exit_Zones[L_i] AND NOT GVL_STATE.G_Evac_Hazard_Zone[L_i] THEN
        GVL_STATE.G_Evac_Guidance[L_i] := 1;
    END_IF;
END_FOR;

// 3.5a. Вычисление человекочитаемых имён зон эвакуации для HMI
GVL_STATUS.G_Evac_Target_Zone_Name := '';
GVL_STATUS.G_Evac_Hazard_Zone_Name := '';

FOR L_i := 1 TO 32 DO
    IF (GVL_STATUS.G_Evac_Hazard_Zone_Name = '') AND GVL_STATE.G_Evac_Hazard_Zone[L_i] THEN
        GVL_STATUS.G_Evac_Hazard_Zone_Name := GVL_CONFIG.G_Evac_Zone_Names[L_i];
        IF GVL_STATUS.G_Evac_Hazard_Zone_Name = '' THEN
            GVL_STATUS.G_Evac_Hazard_Zone_Name := CONCAT('Zone ', INT_TO_STRING(L_i));
        END_IF;
    END_IF;

    IF (GVL_STATUS.G_Evac_Target_Zone_Name = '') AND (GVL_STATE.G_Evac_Guidance[L_i] = 1) THEN
        GVL_STATUS.G_Evac_Target_Zone_Name := GVL_CONFIG.G_Evac_Zone_Names[L_i];
        IF GVL_STATUS.G_Evac_Target_Zone_Name = '' THEN
            GVL_STATUS.G_Evac_Target_Zone_Name := CONCAT('Zone ', INT_TO_STRING(L_i));
        END_IF;
    END_IF;
END_FOR;

// 3.6. Активация световой эвакуации
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP AND GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_STATE.G_Evacuation_Lighting_Active := TRUE;
ELSE
    GVL_STATE.G_Evacuation_Lighting_Active := FALSE;
END_IF;

// 4. Астрономический таймер
fbAstroTimer(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Latitude := 55.75,
    VI_Longitude := 37.61,
    VI_Day_Of_Year := GVL_STATUS.G_Day_Of_Year,
    VO_Is_Night => GVL_STATUS.G_Is_Night
);

// 5. Управление сценариями
fbScenarioManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Activate_Request := GVL_COMMAND.G_Scenario_Request,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VO_Current_Scenario => GVL_STATUS.G_Current_Scenario
);

// Синхронизируем request с фактически активным сценарием
GVL_COMMAND.G_Scenario_Request := GVL_STATUS.G_Current_Scenario;

L_Scenario_Idx := TO_INT(GVL_STATUS.G_Current_Scenario);
IF L_Scenario_Idx < 1 OR L_Scenario_Idx > 6 THEN
    L_Scenario_Idx := 1;
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
        GVL_COMMAND.G_Scenario_Request := TO_BYTE(GVL_STATE.G_Rule_Actions[L_i].Value);
    END_IF;
END_FOR;

// 8.5 Менеджер тревог (Сбор всех аварий)
fbAlarmManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Gas_Alarm := GVL_ALARM.G_Gas_Alarm_Active,
    VI_Fire_Alarm := GVL_ALARM.G_Fire_Alarm_Active,
    VI_Flood_Alarm := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Security_Alarm := GVL_ALARM.G_Security_Alarm,
    VI_First_Fault_Active := fbSystemHealth.VO_First_Fault_Active,
    VI_First_Fault_Type := fbSystemHealth.VO_First_Fault_Type,
    VI_First_Fault_Source := fbSystemHealth.VO_First_Fault_Source,
    VI_Boiler_Errors := GVL_STATE.G_Boiler_Error,
    VI_Security_Msg := GVL_STATUS.G_Security_Status_Msg,
    VI_Acknowledge_All := GVL_CONFIG.G_HMI_Ack_Alarms OR GVL_COMMAND.G_Reset_Errors,
    VI_Mute_Siren := GVL_CONFIG.G_HMI_Mute_Alarm,
    VIO_Next_Alarm_ID := GVL_ALARM.G_Next_Alarm_ID,
    VO_Global_Critical => GVL_ALARM.G_Global_Critical,
    VO_Global_Warning => GVL_ALARM.G_Global_Warning,
    VO_Siren_Active => GVL_ALARM.G_Global_Siren,
    VO_Active_Count => GVL_ALARM.G_Active_Alarm_Count,
    VO_Unacked_Count => GVL_ALARM.G_Unacked_Alarm_Count,
    VO_Event_Pulse => GVL_STATUS.G_Diagnostics.Alarm_Event_Pulse,
    VO_Event_Code => GVL_STATUS.G_Diagnostics.Alarm_Event_Code,
    VO_Event_Value => GVL_STATUS.G_Diagnostics.Alarm_Event_Value,
    VO_Alarm_List => GVL_ALARM.G_Alarm_List
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

IF L_Gateway_Writes_Allowed AND
   fbGateway.VO_Set_Scenario_Req AND
   ((GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) OR
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED)) THEN
    GVL_COMMAND.G_Scenario_Request := fbGateway.VO_Target_Scenario;
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

// ================= COMMAND GATE (FINAL) =================
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN

    // Блокируем ВСЕ опасные команды после Gateway
    GVL_COMMAND.G_Scenario_Request := 0;

    FOR L_i := 1 TO 32 DO
        GVL_COMMAND.G_Lighting_Override[L_i] := BYTE#0;
        GVL_COMMAND.G_Blinds_Override[L_i] := BYTE#0;
        GVL_COMMAND.G_Socket_Override[L_i] := FALSE;
    END_FOR;

    // НЕ блокируем:
    // G_Reset_Errors
    // acknowledge / безопасность

END_IF;
// =======================================================


// 14. Менеджер NVRAM
IF NOT L_Config_Loaded THEN
    L_NVRAM_Cmd := 2; // READ
    L_NVRAM_Offset := 0;
    L_Config_Loaded := TRUE;
ELSIF GVL_CONFIG.G_HMI_Apply_Settings THEN
    L_NVRAM_Cmd := 1; // WRITE
    L_NVRAM_Offset := 0;
    GVL_CONFIG.G_HMI_Apply_Settings := FALSE;
ELSE
    L_NVRAM_Cmd := 0;
END_IF;

// fbNVRAMManager(
//     VI_Command := L_NVRAM_Cmd,
//     VI_Offset := L_NVRAM_Offset,
// // //     VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
//     VI_Operator_ID := 'SYSTEM',
//     VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
//     VI_TwoPersonConfirmation := FALSE,
//     VO_Done => L_NVRAM_Done,
//     VO_Error => L_NVRAM_Err,
//     VO_ErrorID => L_NVRAM_ErrID
// );

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
L_BB_Record.First_Fault_Type := TO_BYTE(TO_INT(fbSystemHealth.VO_First_Fault_Type));
L_BB_Record.First_Fault_Source := TO_BYTE(TO_INT(fbSystemHealth.VO_First_Fault_Source));
L_BB_Record.First_Fault_Active := fbSystemHealth.VO_First_Fault_Active;
L_BB_Record.System_Severity := TO_BYTE(TO_INT(fbSystemHealth.VO_System_Severity));
L_BB_Record.Root_Cause := TO_BYTE(TO_INT(fbSystemHealth.VO_Root_Cause));
L_BB_Record.Watchdog_Fault := fbWatchdog.VO_Watchdog_Fault;


L_BB_Freeze := GVL_ALARM.G_Gas_Alarm_Active OR GVL_ALARM.G_Fire_Alarm_Active OR GVL_ALARM.G_Flood_Alarm_Active OR fbSystemHealth.VO_First_Fault_Active;

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

ELSIF fbSystemHealth.VO_Root_Cause <> L_Last_Root_Cause THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1102; // Root cause changed
    L_History_Event.event_value := TO_REAL(TO_INT(fbSystemHealth.VO_Root_Cause));
    L_History_Event.unit := 2; // root cause enum domain
    L_History_Event.zone_id := TO_BYTE(fbSystemHealth.VO_First_Fault_Source);
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_Root_Cause := fbSystemHealth.VO_Root_Cause;

ELSIF fbSystemHealth.VO_First_Fault_Source <> L_Last_First_Fault_Source THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1103; // First fault source changed
    L_History_Event.event_value := TO_REAL(fbSystemHealth.VO_First_Fault_Source);
    L_History_Event.unit := 3; // root cause source domain
    L_History_Event.zone_id := TO_BYTE(fbSystemHealth.VO_First_Fault_Source);
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_First_Fault_Source := fbSystemHealth.VO_First_Fault_Source;

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

// HMI maintenance mode control (confirmation-aware)
IF GVL_COMMAND.CMD_Dangerous_Action_Confirm THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] := GVL_COMMAND.CMD_Set_Manifold_Pump_In_Service[L_i];
    END_FOR;
    GVL_CONFIG.G_DHW_Heating_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Heating_Pump_In_Service;
    GVL_CONFIG.G_DHW_Circ_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Circ_Pump_In_Service;
END_IF;

// Dangerous action confirmation flow
IF GVL_COMMAND.CMD_Dangerous_Action_Request THEN
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
IF GVL_COMMAND.CMD_Dangerous_Action_Confirm AND L_Dangerous_Action_Armed THEN
    L_Dangerous_Action_Armed := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Опасное действие подтверждено оператором';
END_IF;

// Access level enforcement for dangerous actions
GVL_STATUS.G_Diagnostics.User_Access_Level_Active := GVL_COMMAND.CMD_User_Access_Level;
GVL_STATUS.G_Diagnostics.User_Access_Denied := FALSE;
GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := '';
IF GVL_COMMAND.CMD_Dangerous_Action_Request OR GVL_COMMAND.CMD_Dangerous_Action_Confirm THEN
    IF GVL_COMMAND.CMD_User_Access_Level < 2 THEN
        GVL_STATUS.G_Diagnostics.User_Access_Denied := TRUE;
        GVL_STATUS.G_Diagnostics.User_Access_Deny_Reason := 'Недостаточный уровень доступа для опасного действия';
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Block_Reason := 'Требуется уровень ENGINEER для опасного действия';
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Доступ запрещён: требуется уровень ENGINEER';
    END_IF;
END_IF;

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

// >>> BULK_SYNC_ANCHOR: PRG_System <<<
