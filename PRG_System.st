PROGRAM PRG_System
VAR
    fbPersistBuilder : FB_Persist_Builder;
    fbSnapshotMgr : FB_State_Snapshot_Manager;

// === SENSOR PROCESSING (SHADOW) ===
fbSensorCO : FB_Sensor_Analog_Processing;
fbCalibGasFamily : ARRAY[1..2] OF FB_Sensor_Calibration_Processor;
fbSensorMethane : FB_Sensor_Analog_Processing;
fbCalibVerifyGasFamily : ARRAY[1..2] OF FB_Calibration_Manager;
fbCalibTempFamily : ARRAY[1..3] OF FB_Sensor_Calibration_Processor;
fbCalibVerifyTempFamily : ARRAY[1..3] OF FB_Calibration_Manager;
fbCalibHumidityFamily : ARRAY[1..1] OF FB_Sensor_Calibration_Processor;
fbCalibPressureFamily : ARRAY[1..1] OF FB_Sensor_Calibration_Processor;
fbCalibVerifyPressureFamily : ARRAY[1..1] OF FB_Calibration_Manager;
fbSmokeDetector : FB_Smoke_Detector;
fbFreezeProtection : FB_FloorHeating_Freeze_Protection;
fbOverheatProtection : FB_FloorHeating_Overheat_Protection;
L_CO_Processed : REAL;
L_CO_Calibrated : REAL;
L_Safety_Selector_i : INT;
L_Methane_Processed : REAL;
L_Methane_Calibrated : REAL;
L_GasFamily_Processed : REAL;
L_GasFamily_Calibrated : ARRAY[1..2] OF REAL;
L_FloorTemp1_Calibrated : REAL;
L_FloorTemp2_Calibrated : REAL;
L_OutdoorTemp_Calibrated : REAL;
L_RoomHum1_Calibrated : REAL;
L_HumidityFamily_Raw : REAL;
L_HumidityFamily_Calibrated : ARRAY[1..1] OF REAL;
L_DHWPressure_Calibrated : REAL;
L_PressureFamily_Raw : REAL;
L_PressureFamily_Calibrated : ARRAY[1..1] OF REAL;
L_TempFamily_Raw : REAL;
L_TempFamily_Calibrated : ARRAY[1..3] OF REAL;
L_Smoke_Detected : BOOL;
L_Window_Hours : REAL;
L_Snapshot : ST_State_Snapshot;
L_Snapshot_Trigger_Prev : BOOL;
L_Snapshot_Fallback_Prev : BOOL;
L_Snapshot_Recovery_Prev : BOOL;
L_Heating_Pump_Force_Bridge_Prev : BOOL;
L_Heating_Zone_Lock_Bridge_Prev : BOOL;
L_Heating_Pump_Force_Hold_MS : UDINT;
L_Heating_Zone_Lock_Hold_MS : UDINT;
L_GasFamily_Calib_TS_Prev : ARRAY[1..2] OF UDINT;
L_GasFamily_Verification_Active_Prev : ARRAY[1..2] OF BOOL;
L_TempFamily_Calib_TS_Prev : ARRAY[1..3] OF UDINT;
L_TempFamily_Verification_Active_Prev : ARRAY[1..3] OF BOOL;
L_Snapshot_Last_Event_MS : UDINT;
L_Snapshot_Min_Interval_MS : UDINT;



// === LIFETIME MANAGERS ===
fbLifetimePump : FB_Lifetime_Manager;
fbLifetimeFan  : FB_Lifetime_Manager;


    // === TREND WRITE CONTROL ===
    L_Trend_Write : BOOL;
    L_Trend_Write_Prev : BOOL;

    // === TREND → HISTORY BRIDGE ===
    L_Trend_Event : ST_History_Record;

    // === TREND SYSTEM (MVP) ===
    L_Trend_Logger : FB_Trend_Logger;
    L_Trend_Data : ST_Trend_Data;
    L_Trend_Adapter : FB_Trend_Adapter;
    L_Trend_Avg : REAL;
    L_Trend_Min : REAL;
    L_Trend_Max : REAL;
    L_Trend_Up : BOOL;
    L_Trend_Down : BOOL;
    L_Trend_Last_Write_MS : UDINT;
    L_Trend_Last_Written_Avg : REAL;
    L_Trend_Write_Allowed : BOOL;
    L_i : INT;
    L_TempFamily_i : INT;
    L_GasFamily_i : INT;
    L_PressureFamily_i : INT;
    L_HumidityFamily_i : INT;
    // === CALIBRATION CONFIG-DRIVEN MAPPING (STAGE 1) ===
    L_GasFamily_Record_Index : ARRAY[1..2] OF INT := [1, 2];
    L_TempFamily_Record_Index : ARRAY[1..3] OF INT := [3, 4, 5];
    L_PressureFamily_Record_Index : ARRAY[1..1] OF INT := [7];
    L_HumidityFamily_Record_Index : ARRAY[1..1] OF INT := [6];
    L_PressureFamily_Calib_TS_Prev : ARRAY[1..1] OF UDINT;
    L_PressureFamily_Verification_Active_Prev : ARRAY[1..1] OF BOOL;
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
    fbScenarioGuard : FB_Scenario_Transition_Guard;
    fbSimulationManager : FB_Simulation_Manager;
    fbRuleEngine : FB_Rule_Engine;
    fbPersistPipeline : FB_Persist_Pipeline;

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
    L_Last_Maintenance_Action_Code : UDINT;
    L_Last_Event_Code : UDINT;
    L_Last_Event_Value : REAL;
    L_Last_Event_Time_MS : UDINT;
    L_Gateway_Writes_Allowed : BOOL;
    L_Last_Policy_Event_Time_MS : UDINT;

    L_Scenario_Req_Operator : E_SCENARIO_TYPE;
    L_Scenario_Req_Gateway  : E_SCENARIO_TYPE;
    L_Scenario_Req_Rule     : E_SCENARIO_TYPE;
    L_Scenario_Req_Final    : E_SCENARIO_TYPE; // TRACE ONLY: arbitration result before policy
    L_Scenario_Intent       : E_SCENARIO_TYPE;
L_Scenario_Source       : E_SCENARIO_SOURCE;

L_IO_Fault_Prev : BOOL;
L_Watchdog_Fault_Prev : BOOL;
L_Comm_Fault_Prev : BOOL;
L_Sensor_Fault_Prev : BOOL;
L_Subsystem_Fault_Prev : BOOL;
L_Mode_Prev : E_System_Operating_Mode;
L_User_Access_Denied_Prev : BOOL;
L_Dangerous_Action_Request_Prev : BOOL;

L_Shadow_CO_Enabled_Prev : BOOL;
L_Shadow_Methane_Enabled_Prev : BOOL;
L_Shadow_Smoke_Enabled_Prev : BOOL;

    L_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Last_Written_Persist_Buffer : ARRAY[0..4] OF BYTE;
    L_Last_Persist_Write_MS : UDINT;
    L_Recovery_Done : BOOL;
    L_Persist_Struct : ST_Persist;
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

// === NVRAM RECOVERY (ONCE AFTER BOOT) ===
IF NOT L_Recovery_Done THEN
    IF GVL_PERSISTENT.P_Valid THEN
        GVL_STATE.G_Safety_Gas_Latched := GVL_PERSISTENT.P_Safety_Gas_Latched;
        GVL_STATE.G_Safety_Smoke_Latched := GVL_PERSISTENT.P_Safety_Smoke_Latched;
        GVL_STATE.G_Safety_Leak_Latched := GVL_PERSISTENT.P_Safety_Leak_Latched;
        GVL_STATE.G_System_Mode := GVL_PERSISTENT.P_System_Mode;

    // restore DHW pump state (symmetry with persist builder)
    GVL_STATE.G_DHW_Heating_Pump := GVL_PERSISTENT.P_DHW_Heating_Active;

    END_IF;

    L_Recovery_Done := TRUE;
END_IF;

// NVRAM CONTROLLED WRITE ENABLED (step 8B)

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

// ================= COMMAND GATE (FINAL) =================
IF GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN

    // Блокируем ВСЕ опасные команды после Gateway
    GVL_COMMAND.G_Scenario_Request_Operator := 0;

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

            IF (L_Last_Policy_Event_Time_MS = 0) OR
               ((GVL_STATUS.G_System_Time_MS - L_Last_Policy_Event_Time_MS) >= 5000) THEN
                fbLogEvent(
                    VI_Event_Type := 5,
                    VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                    VI_Param1 := TO_UDINT(L_Scenario_Source),
                    VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
                );
                L_Last_Policy_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
            END_IF;
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

                IF (L_Last_Policy_Event_Time_MS = 0) OR
                   ((GVL_STATUS.G_System_Time_MS - L_Last_Policy_Event_Time_MS) >= 5000) THEN
                    fbLogEvent(
                        VI_Event_Type := 6,
                        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                        VI_Param1 := TO_UDINT(L_Scenario_Source),
                        VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_AWAY)
                    );
                    L_Last_Policy_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                END_IF;
            END_IF;

        ELSIF L_Scenario_Intent = E_SCENARIO_TYPE.SCENARIO_PRESENCE THEN
            IF L_Scenario_Intent <> E_SCENARIO_TYPE.SCENARIO_SLEEP THEN
                L_Scenario_Intent := E_SCENARIO_TYPE.SCENARIO_SLEEP;
                L_Scenario_Source := SRC_POLICY;

                IF (L_Last_Policy_Event_Time_MS = 0) OR
                   ((GVL_STATUS.G_System_Time_MS - L_Last_Policy_Event_Time_MS) >= 5000) THEN
                    fbLogEvent(
                        VI_Event_Type := 7,
                        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
                        VI_Param1 := TO_UDINT(L_Scenario_Source),
                        VI_Param2 := TO_UDINT(E_SCENARIO_TYPE.SCENARIO_SLEEP)
                    );
                    L_Last_Policy_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                END_IF;
            END_IF;
        END_IF;
    END_IF;
END_IF;

fbScenarioGuard(
    VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Target_Scenario := L_Scenario_Intent
);

IF NOT fbScenarioGuard.VO_Transition_Allowed THEN
    GVL_GATEWAY.G_Gateway_HMI_Status_Message := CONCAT('Scenario guard: ', fbScenarioGuard.VO_Reason);
    L_Scenario_Intent := GVL_STATUS.G_Current_Scenario;
END_IF;

fbScenarioManager(
        VI_Preheat_Request := fbRuleEngine.VO_Preheat_Request,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Activate_Request := L_Scenario_Intent,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VO_Current_Scenario => GVL_STATUS.G_Current_Scenario
);



// 14. Менеджер NVRAM
// Pack persistent snapshot into compact byte buffer for controlled NVRAM mirroring
fbPersistBuilder(
    VIO_PersistStruct := L_Persist_Struct
);

fbPersistPipeline(
    VI_PersistStruct := L_Persist_Struct,
    VIO_Apply_Settings := GVL_CONFIG.G_HMI_Apply_Settings,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VIO_Persist_Buffer := L_Persist_Buffer,
    VIO_Last_Written_Persist_Buffer := L_Last_Written_Persist_Buffer,
    VIO_Last_Persist_Write_MS := L_Last_Persist_Write_MS
);

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

    fbLogEvent(
        VI_Event_Type := 1,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := TO_UDINT(L_Scenario_Source),
        VI_Param2 := TO_UDINT(GVL_STATUS.G_Current_Scenario)
    );

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
IF GVL_COMMAND.CMD_Dangerous_Action_Request AND
   NOT L_Dangerous_Action_Request_Prev AND
   (GVL_COMMAND.CMD_User_Access_Level >= 2) THEN

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
    L_Maintenance_Apply_Intent := FALSE;
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
IF L_Maintenance_Apply_Intent AND
   ((GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_NORMAL) OR
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED)) THEN
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
GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := FALSE;
GVL_STATUS.G_Diagnostics.Operator_Block_Reason := '';
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
        L_Dangerous_Action_Armed := FALSE;
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
        GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Доступ запрещён: требуется уровень ENGINEER';
    END_IF;
END_IF;

L_User_Access_Denied_Prev := GVL_STATUS.G_Diagnostics.User_Access_Denied;
L_Dangerous_Action_Request_Prev := GVL_COMMAND.CMD_Dangerous_Action_Request;

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
    IF GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС возвращён из ТО';
        IF L_Last_Maintenance_Action_Code <> 1101 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1101;
        END_IF;
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос загрузки ГВС выведен в ТО';
        IF L_Last_Maintenance_Action_Code <> 1102 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1102;
        END_IF;
    END_IF;
END_IF;
L_Last_DHW_Heating_In_Service := GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service <> L_Last_DHW_Circ_In_Service THEN
    IF GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС возвращён из ТО';
        IF L_Last_Maintenance_Action_Code <> 1201 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1201;
        END_IF;
    ELSE
        GVL_STATUS.G_Diagnostics.Maintenance_Last_Action := 'Насос рециркуляции ГВС выведен в ТО';
        IF L_Last_Maintenance_Action_Code <> 1202 THEN
            GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq + 1;
            L_Last_Maintenance_Action_Code := 1202;
        END_IF;
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





// === TREND EXECUTION (SAFE MVP) ===
L_Trend_Data.config.param_type := 1;
L_Trend_Data.config.zone_id := 0;
L_Trend_Data.config.enabled := TRUE;
L_Trend_Data.config.deviation_threshold_percent := 1.0;
L_Trend_Data.config.history_days := 1;

L_Trend_Logger(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Config := L_Trend_Data.config,
    VI_Current_Value := GVL_STATE.G_Outdoor_Temp
);

L_Trend_Data := L_Trend_Logger.VO_Data;

// === TREND ANALYSIS VIA ADAPTER ===
L_Trend_Adapter(
    VI_Data := L_Trend_Data,
    VO_Average => L_Trend_Avg,
    VO_Min => L_Trend_Min,
    VO_Max => L_Trend_Max,
    VO_Trend_Up => L_Trend_Up,
    VO_Trend_Down => L_Trend_Down
);




// === TREND MULTI-SIGNAL FOUNDATION ===
// Channel 1 is currently active (Outdoor Temp / TEMP_AIR).
// Channel 2 reserved for future integration.
// HMI may use GVL_Trend.G_Trend_Selected_Channel to switch active graph source.

// === TREND → GVL FOR HMI ===

// === TREND BUFFER UPDATE ===

// === TREND CHANNEL 2 (FLOOR TEMP, SHARED INDEX) ===
IF GVL_Trend.G_Trend_Channel2_Enabled THEN

    GVL_Trend.G_Trend_Buffer_2_Index := GVL_Trend.G_Trend_Buffer_Index;
    GVL_Trend.G_Trend_Buffer_2[GVL_Trend.G_Trend_Buffer_2_Index] := L_FloorTemps_8[1];
    GVL_Trend.G_Trend_Buffer_2_Timestamps[GVL_Trend.G_Trend_Buffer_2_Index] := GVL_STATUS.G_System_Time_MS;

    IF GVL_Trend.G_Trend_Buffer_2_Valid_Count < 50 THEN
        GVL_Trend.G_Trend_Buffer_2_Valid_Count := GVL_Trend.G_Trend_Buffer_2_Valid_Count + 1;
    ELSE
        GVL_Trend.G_Trend_Buffer_2_Is_Wrapped := TRUE;
    END_IF;

    GVL_Trend.G_Trend_Channel2_Param_Type := 2; // TEMP_FLOOR

END_IF;


// === TREND META UPDATE ===
GVL_Trend.G_Trend_Last_Update_MS := GVL_STATUS.G_System_Time_MS;
GVL_Trend.G_Trend_Param_Type := 1; // TEMP_AIR (пока фикс)

IF GVL_Trend.G_Trend_Valid_Count < 50 THEN
    GVL_Trend.G_Trend_Valid_Count := GVL_Trend.G_Trend_Valid_Count + 1;
ELSE
    GVL_Trend.G_Trend_Is_Wrapped := TRUE;
END_IF;

GVL_Trend.G_Trend_Buffer_Index := GVL_Trend.G_Trend_Buffer_Index + 1;
IF GVL_Trend.G_Trend_Buffer_Index > 50 THEN
    GVL_Trend.G_Trend_Buffer_Index := 1;
END_IF;

GVL_Trend.G_Trend_Buffer[GVL_Trend.G_Trend_Buffer_Index] := L_Trend_Avg;
GVL_Trend.G_Trend_Buffer_Timestamps[GVL_Trend.G_Trend_Buffer_Index] := GVL_STATUS.G_System_Time_MS;

GVL_Trend.G_Trend_Avg := L_Trend_Avg;
GVL_Trend.G_Trend_Min := L_Trend_Min;
GVL_Trend.G_Trend_Max := L_Trend_Max;
GVL_Trend.G_Trend_Up := L_Trend_Up;
GVL_Trend.G_Trend_Down := L_Trend_Down;


// === TREND HMI NORMALIZATION ===
IF GVL_Trend.G_Trend_Selected_Channel = 2 AND GVL_Trend.G_Trend_Channel2_Enabled THEN
    GVL_Trend.G_Trend_Active_Param_Type := GVL_Trend.G_Trend_Channel2_Param_Type;
    GVL_Trend.G_Trend_Active_Label := GVL_Trend.G_Trend_Channel2_Label;
ELSE
    GVL_Trend.G_Trend_Active_Param_Type := GVL_Trend.G_Trend_Param_Type;
    GVL_Trend.G_Trend_Active_Label := GVL_Trend.G_Trend_Channel1_Label;
END_IF;


// === TREND ACTIVE VIEW FOR HMI ===
IF GVL_Trend.G_Trend_Selected_Channel = 2 AND GVL_Trend.G_Trend_Channel2_Enabled THEN
    GVL_Trend.G_Trend_Active_Index := GVL_Trend.G_Trend_Buffer_2_Index;
    GVL_Trend.G_Trend_Active_Valid_Count := GVL_Trend.G_Trend_Buffer_2_Valid_Count;
    GVL_Trend.G_Trend_Active_Is_Wrapped := GVL_Trend.G_Trend_Buffer_2_Is_Wrapped;

    IF GVL_Trend.G_Trend_Buffer_2_Index >= 1 AND GVL_Trend.G_Trend_Buffer_2_Index <= 50 THEN
        GVL_Trend.G_Trend_Active_Value := GVL_Trend.G_Trend_Buffer_2[GVL_Trend.G_Trend_Buffer_2_Index];
        GVL_Trend.G_Trend_Active_Timestamp := GVL_Trend.G_Trend_Buffer_2_Timestamps[GVL_Trend.G_Trend_Buffer_2_Index];
    END_IF;
ELSE
    GVL_Trend.G_Trend_Active_Index := GVL_Trend.G_Trend_Buffer_Index;
    GVL_Trend.G_Trend_Active_Valid_Count := GVL_Trend.G_Trend_Valid_Count;
    GVL_Trend.G_Trend_Active_Is_Wrapped := GVL_Trend.G_Trend_Is_Wrapped;

    IF GVL_Trend.G_Trend_Buffer_Index >= 1 AND GVL_Trend.G_Trend_Buffer_Index <= 50 THEN
        GVL_Trend.G_Trend_Active_Value := GVL_Trend.G_Trend_Buffer[GVL_Trend.G_Trend_Buffer_Index];
        GVL_Trend.G_Trend_Active_Timestamp := GVL_Trend.G_Trend_Buffer_Timestamps[GVL_Trend.G_Trend_Buffer_Index];
    END_IF;
END_IF;


// === SENSOR PROCESSING (SHADOW EXEC) ===
fbSensorCO(
    VI_Raw_Value := REAL_TO_WORD(GVL_STATE.G_CO_Sensors[1]),
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);
L_CO_Processed := fbSensorCO.VO_Value;

// === SHADOW EXPORT ===
GVL_Sensor_Shadow.G_CO_Raw := GVL_STATE.G_CO_Sensors[1];
GVL_Sensor_Shadow.G_CO_Processed := L_CO_Processed;
GVL_Sensor_Shadow.G_CO_Error := fbSensorCO.VO_Error;
GVL_Sensor_Shadow.G_CO_Diag_Code := fbSensorCO.VO_Diag_Code;


// === METHANE SHADOW EXEC ===
fbSensorMethane(
    VI_Raw_Value := REAL_TO_WORD(GVL_STATE.G_Methane_Sensors[1]),
    VI_Sensor_Type := 0,
    VI_Min_Scale := 0.0,
    VI_Max_Scale := 100.0,
    VI_Offset := 0.0,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);
L_Methane_Processed := fbSensorMethane.VO_Value;

// === CALIBRATION CONFIG-DRIVEN MAPPING STAGE 1 ===
// === GAS FAMILY CALIBRATION GENERIC LOOP ===
// Mapping:
// 1 -> CO, calibration record 1
// 2 -> Methane, calibration record 2
FOR L_GasFamily_i := 1 TO 2 DO
    CASE L_GasFamily_i OF
        1:
            L_GasFamily_Processed := L_CO_Processed;
        2:
            L_GasFamily_Processed := L_Methane_Processed;
    ELSE
        L_GasFamily_Processed := 0.0;
    END_CASE;

    fbCalibGasFamily[L_GasFamily_i](
        VI_Raw_Value := L_GasFamily_Processed,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]]
    );
    L_GasFamily_Calibrated[L_GasFamily_i] := fbCalibGasFamily[L_GasFamily_i].VO_Calibrated_Value;

    fbCalibVerifyGasFamily[L_GasFamily_i](
        VI_Raw_Value := L_GasFamily_Processed,
        VI_Type := 3,
        VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Start_Verification := (
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].last_calibration_timestamp <> 0 AND
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].last_calibration_timestamp <> L_GasFamily_Calib_TS_Prev[L_GasFamily_i]
        )
    );

    CASE L_GasFamily_i OF
        1:
            L_CO_Calibrated := L_GasFamily_Calibrated[1];
            GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Deviation_Percent;

        2:
            L_Methane_Calibrated := L_GasFamily_Calibrated[2];
            GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent :=
                fbCalibVerifyGasFamily[L_GasFamily_i].VO_Deviation_Percent;
    END_CASE;

    IF L_GasFamily_Verification_Active_Prev[L_GasFamily_i] AND
       (NOT fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active) THEN
        GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].verification_passed :=
            NOT fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed;

        CASE L_GasFamily_i OF
            1:
                GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count :=
                    GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Event_Count + 1;
                GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                IF fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed THEN
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification failed';
                ELSE
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'CO verification passed';
                END_IF;

            2:
                GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count :=
                    GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Event_Count + 1;
                GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
                IF fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Failed THEN
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification failed';
                ELSE
                    GVL_STATUS.G_Diagnostics.Calibration_Last_Event_Text := 'Methane verification passed';
                END_IF;
        END_CASE;
    END_IF;

    L_GasFamily_Verification_Active_Prev[L_GasFamily_i] := fbCalibVerifyGasFamily[L_GasFamily_i].VO_Verification_Active;
    L_GasFamily_Calib_TS_Prev[L_GasFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_GasFamily_Record_Index[L_GasFamily_i]].last_calibration_timestamp;
END_FOR;

IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'CO calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Methane calibration verification failed';
ELSIF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification active';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Verification_Summary_Text := 'Calibration verification idle';
END_IF;

// === METHANE/CO SHADOW EXPORT ===
GVL_Sensor_Shadow.G_CO_Calibrated := L_CO_Calibrated;
GVL_Sensor_Shadow.G_Methane_Raw := GVL_STATE.G_Methane_Sensors[1];
GVL_Sensor_Shadow.G_Methane_Processed := L_Methane_Processed;
GVL_Sensor_Shadow.G_Methane_Calibrated := L_Methane_Calibrated;
GVL_Sensor_Shadow.G_Methane_Error := fbSensorMethane.VO_Error;
GVL_Sensor_Shadow.G_Methane_Diag_Code := fbSensorMethane.VO_Diag_Code;

// === TEMPERATURE FAMILY CALIBRATION GENERIC LOOP ===
// Mapping:
// 1 -> FloorTemp1, calibration record 3
// 2 -> FloorTemp2, calibration record 4
// 3 -> OutdoorTemp, calibration record 5
FOR L_TempFamily_i := 1 TO 3 DO
    CASE L_TempFamily_i OF
        1:
            L_TempFamily_Raw := GVL_STATE.G_Floor_Temps[1];
        2:
            L_TempFamily_Raw := GVL_STATE.G_Floor_Temps[2];
        3:
            L_TempFamily_Raw := GVL_STATE.G_Outdoor_Temp;
    ELSE
        L_TempFamily_Raw := 0.0;
    END_CASE;

    fbCalibTempFamily[L_TempFamily_i](
        VI_Raw_Value := L_TempFamily_Raw,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]]
    );
    L_TempFamily_Calibrated[L_TempFamily_i] := fbCalibTempFamily[L_TempFamily_i].VO_Calibrated_Value;

    fbCalibVerifyTempFamily[L_TempFamily_i](
        VI_Raw_Value := L_TempFamily_Raw,
        VI_Type := 1,
        VI_Calib_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]],
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Start_Verification := (
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].last_calibration_timestamp <> 0 AND
            GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].last_calibration_timestamp <> L_TempFamily_Calib_TS_Prev[L_TempFamily_i]
        )
    );

    CASE L_TempFamily_i OF
        1:
            L_FloorTemp1_Calibrated := L_TempFamily_Calibrated[1];

            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Summary_Text := 'FloorTemp1 verification idle';
            END_IF;

        2:
            L_FloorTemp2_Calibrated := L_TempFamily_Calibrated[2];

            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Summary_Text := 'FloorTemp2 verification idle';
            END_IF;

        3:
            L_OutdoorTemp_Calibrated := L_TempFamily_Calibrated[3];

            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Active := TRUE;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
            GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent :=
                fbCalibVerifyTempFamily[L_TempFamily_i].VO_Deviation_Percent;

            IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification failed';
            ELSIF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification active';
            ELSE
                GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Summary_Text := 'OutdoorTemp verification idle';
            END_IF;
    END_CASE;

    IF L_TempFamily_Verification_Active_Prev[L_TempFamily_i] AND
       (NOT fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active) THEN
        GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].verification_passed :=
            NOT fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Failed;
    END_IF;

    L_TempFamily_Verification_Active_Prev[L_TempFamily_i] := fbCalibVerifyTempFamily[L_TempFamily_i].VO_Verification_Active;
    L_TempFamily_Calib_TS_Prev[L_TempFamily_i] := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_TempFamily_Record_Index[L_TempFamily_i]].last_calibration_timestamp;
END_FOR;

// === HUMIDITY FAMILY GENERIC LOOP ===
// Mapping:
// 1 -> RoomHum1 (record[6])
FOR L_HumidityFamily_i := 1 TO 1 DO

    L_HumidityFamily_Raw := GVL_STATE.G_Room_Hum[1];

    fbCalibHumidityFamily[L_HumidityFamily_i](
        VI_Raw_Value := L_HumidityFamily_Raw,
        VI_Record := GVL_CONFIG.G_HMI_Sensor_Calibrations[L_HumidityFamily_Record_Index[L_HumidityFamily_i]]
    );

    L_HumidityFamily_Calibrated[L_HumidityFamily_i] :=
        fbCalibHumidityFamily[L_HumidityFamily_i].VO_Calibrated_Value;

    L_RoomHum1_Calibrated := L_HumidityFamily_Calibrated[1];

    GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Active := TRUE;
    GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Calibrated_Value := L_RoomHum1_Calibrated;
    GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Summary_Text :=
        'RoomHum1 calibration (generic loop)';

END_FOR;

// === CALIBRATION STATUS AGGREGATOR ===
// Status codes:
// 0 = OK
// 1 = IN_PROGRESS
// 2 = WARNING
// 3 = ERROR

// Gas family
IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed OR
   GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 3;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 1;
ELSIF (GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent > 2.0) OR
      (GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent > 2.0) THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 2;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Gas := 0;
END_IF;

// Temperature family
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed OR
   GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed OR
   GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 3;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active OR
      GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 1;
ELSIF (GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent > 2.0) OR
      (GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent > 2.0) OR
      (GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent > 2.0) THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 2;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature := 0;
END_IF;

// Pressure family
IF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 3;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 1;
ELSIF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent > 2.0 THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 2;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure := 0;
END_IF;

// Humidity family
IF GVL_STATUS.G_Diagnostics.Calibration_RoomHum1_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity := 0;
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity := 2;
END_IF;

// Global
GVL_STATUS.G_Diagnostics.Calibration_Status_Global := 0;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity;
END_IF;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure;
END_IF;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
END_IF;

IF GVL_STATUS.G_Diagnostics.Calibration_Status_Gas > GVL_STATUS.G_Diagnostics.Calibration_Status_Global THEN
    GVL_STATUS.G_Diagnostics.Calibration_Status_Global := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
END_IF;

CASE GVL_STATUS.G_Diagnostics.Calibration_Status_Global OF
    3:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: ERROR';
    2:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: WARNING';
    1:
        GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: IN_PROGRESS';
ELSE
    GVL_STATUS.G_Diagnostics.Calibration_Status_Summary_Text := 'Calibration status: OK';
END_CASE;

// === CALIBRATION FAMILY/SENSOR SUMMARY RECORDS ===
// Families
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.sensor_count := 2;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.verification_active_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.failed_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.max_deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent;
IF GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent >
   GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.max_deviation_percent THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.max_deviation_percent :=
        GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Gas.summary_text := 'Gas family';

GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.sensor_count := 3;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.verification_active_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count + 1;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count :=
        GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.failed_count + 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent;
IF GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent >
   GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent :=
        GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent;
END_IF;
IF GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent >
   GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.max_deviation_percent :=
        GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Temperature.summary_text := 'Temperature family';

GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.sensor_count := 1;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.verification_active_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.verification_active_count := 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.failed_count := 0;
IF GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed THEN
    GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.failed_count := 1;
END_IF;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.max_deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Family_Pressure.summary_text := 'Pressure family';

GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.sensor_count := 1;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.verification_active_count := 0;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.failed_count := 0;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.max_deviation_percent := 0.0;
GVL_STATUS.G_Diagnostics.Calibration_Family_Humidity.summary_text := 'Humidity family';

// Sensors
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.calibrated_value := L_CO_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_CO_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.verification_active := GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_CO_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.record_index := 1;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.label := 'CO';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_CO.summary_text := 'CO sensor';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Gas;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.calibrated_value := L_Methane_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_Methane_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.verification_active := GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_Methane_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.record_index := 2;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.label := 'Methane';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_Methane.summary_text := 'Methane sensor';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.calibrated_value := L_FloorTemp1_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.verification_active := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp1_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.record_index := 3;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.label := 'FloorTemp1';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp1.summary_text := 'Floor temperature 1';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.calibrated_value := L_FloorTemp2_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.verification_active := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_FloorTemp2_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.record_index := 4;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.label := 'FloorTemp2';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_FloorTemp2.summary_text := 'Floor temperature 2';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Temperature;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.calibrated_value := L_OutdoorTemp_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.verification_active := GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_OutdoorTemp_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.record_index := 5;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.label := 'OutdoorTemp';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_OutdoorTemp.summary_text := 'Outdoor temperature';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Humidity;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.calibrated_value := L_RoomHum1_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.deviation_percent := 0.0;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.verification_active := FALSE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.verification_failed := FALSE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.record_index := 6;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.label := 'RoomHum1';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_RoomHum1.summary_text := 'Room humidity 1';

GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.active := TRUE;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.status := GVL_STATUS.G_Diagnostics.Calibration_Status_Pressure;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.calibrated_value := L_DHWPressure_Calibrated;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.deviation_percent := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Deviation_Percent;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.verification_active := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Active;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.verification_failed := GVL_STATUS.G_Diagnostics.Calibration_DHWPressure_Verification_Failed;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.record_index := 7;
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.label := 'DHWPressure';
GVL_STATUS.G_Diagnostics.Calibration_Sensor_DHWPressure.summary_text := 'DHW pressure';

// === SMOKE SHADOW EXEC ===
fbSmokeDetector(
    VI_Smoke_Signal := GVL_STATE.G_Smoke_Sensors[1]
);
L_Smoke_Detected := fbSmokeDetector.VO_Smoke_Detected;

// === SMOKE SHADOW EXPORT ===
GVL_Sensor_Shadow.G_Smoke_Raw := GVL_STATE.G_Smoke_Sensors[1];
GVL_Sensor_Shadow.G_Smoke_Detected := L_Smoke_Detected;

// === SAFETY SHADOW VS RUNTIME BRIDGE ===

// CO
GVL_Safety_Bridge.G_CO_Runtime := GVL_STATE.G_CO_Sensors[1];
GVL_Safety_Bridge.G_CO_Shadow  := GVL_Sensor_Shadow.G_CO_Calibrated;
GVL_Safety_Bridge.G_CO_Diff    := ABS(GVL_Safety_Bridge.G_CO_Runtime - GVL_Safety_Bridge.G_CO_Shadow);

// METHANE
GVL_Safety_Bridge.G_Methane_Runtime := GVL_STATE.G_Methane_Sensors[1];
GVL_Safety_Bridge.G_Methane_Shadow  := GVL_Sensor_Shadow.G_Methane_Calibrated;
GVL_Safety_Bridge.G_Methane_Diff    := ABS(GVL_Safety_Bridge.G_Methane_Runtime - GVL_Safety_Bridge.G_Methane_Shadow);

// SMOKE
GVL_Safety_Bridge.G_Smoke_Runtime := GVL_STATE.G_Smoke_Sensors[1];
GVL_Safety_Bridge.G_Smoke_Shadow  := GVL_Sensor_Shadow.G_Smoke_Detected;
GVL_Safety_Bridge.G_Smoke_Diff    := GVL_Safety_Bridge.G_Smoke_Runtime XOR GVL_Safety_Bridge.G_Smoke_Shadow;

// === SAFETY SELECTOR LAYER ===
GVL_Safety_Selector.G_Use_Shadow_Methane := TRUE;
GVL_Safety_Selector.G_Use_Shadow_Smoke := TRUE;
GVL_Safety_Selector.G_Use_Shadow_CO := TRUE;

// base copy from runtime arrays
FOR L_Safety_Selector_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    GVL_Safety_Selector.G_CO_Effective_Array[L_Safety_Selector_i] := GVL_STATE.G_CO_Sensors[L_Safety_Selector_i];
END_FOR;

FOR L_Safety_Selector_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    GVL_Safety_Selector.G_Methane_Effective_Array[L_Safety_Selector_i] := GVL_STATE.G_Methane_Sensors[L_Safety_Selector_i];
END_FOR;

FOR L_Safety_Selector_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    GVL_Safety_Selector.G_Smoke_Effective_Array[L_Safety_Selector_i] := GVL_STATE.G_Smoke_Sensors[L_Safety_Selector_i];
END_FOR;

// CO
IF GVL_Safety_Selector.G_Use_Shadow_CO THEN
    GVL_Safety_Selector.G_CO_Effective := GVL_Sensor_Shadow.G_CO_Calibrated;
    GVL_Safety_Selector.G_CO_Effective_Array[1] := GVL_Sensor_Shadow.G_CO_Calibrated;
ELSE
    GVL_Safety_Selector.G_CO_Effective := GVL_STATE.G_CO_Sensors[1];
END_IF;

// METHANE
IF GVL_Safety_Selector.G_Use_Shadow_Methane THEN
    GVL_Safety_Selector.G_Methane_Effective := GVL_Sensor_Shadow.G_Methane_Calibrated;
    GVL_Safety_Selector.G_Methane_Effective_Array[1] := GVL_Sensor_Shadow.G_Methane_Calibrated;
ELSE
    GVL_Safety_Selector.G_Methane_Effective := GVL_STATE.G_Methane_Sensors[1];
END_IF;

// SMOKE
IF GVL_Safety_Selector.G_Use_Shadow_Smoke THEN
    GVL_Safety_Selector.G_Smoke_Effective := GVL_Sensor_Shadow.G_Smoke_Detected;
    GVL_Safety_Selector.G_Smoke_Effective_Array[1] := GVL_Sensor_Shadow.G_Smoke_Detected;
ELSE
    GVL_Safety_Selector.G_Smoke_Effective := GVL_STATE.G_Smoke_Sensors[1];
END_IF;


// === SHADOW METHANE/SMOKE DIAGNOSTIC EXPORT ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Active := GVL_Safety_Selector.G_Use_Shadow_Methane;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Diff := GVL_Safety_Bridge.G_Methane_Diff;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Active := GVL_Safety_Selector.G_Use_Shadow_Smoke;

IF GVL_Safety_Selector.G_Use_Shadow_Methane THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Status_Text := 'Methane shadow ACTIVE';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Status_Text := 'Methane shadow OFF';
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_Smoke THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Status_Text := 'Smoke shadow ACTIVE';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Status_Text := 'Smoke shadow OFF';
END_IF;

// === SHADOW CO DIAGNOSTIC EXPORT ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Active := GVL_Safety_Selector.G_Use_Shadow_CO;
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Diff := GVL_Safety_Bridge.G_CO_Diff;

IF GVL_Safety_Selector.G_Use_Shadow_CO THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Status_Text := 'CO shadow ACTIVE';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Status_Text := 'CO shadow OFF';
END_IF;

// === SHADOW SAFETY QUALITY FLAGS ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable :=
    GVL_Safety_Bridge.G_CO_Diff > GVL_Safety_Selector.G_CO_Shadow_Max_Diff;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable :=
    GVL_Safety_Bridge.G_Methane_Diff > GVL_Safety_Selector.G_Methane_Shadow_Max_Diff;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch :=
    GVL_Safety_Bridge.G_Smoke_Diff;

// === SHADOW SAFETY POLICY (DEBOUNCE + RECOVERY) ===

// --- UNSTABLE COUNTERS ---
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable THEN
    GVL_Safety_Selector.G_CO_Unstable_Counter := GVL_Safety_Selector.G_CO_Unstable_Counter + 1;
    GVL_Safety_Selector.G_CO_Stable_Counter := 0;
ELSE
    GVL_Safety_Selector.G_CO_Unstable_Counter := 0;
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable THEN
    GVL_Safety_Selector.G_Methane_Unstable_Counter := GVL_Safety_Selector.G_Methane_Unstable_Counter + 1;
    GVL_Safety_Selector.G_Methane_Stable_Counter := 0;
ELSE
    GVL_Safety_Selector.G_Methane_Unstable_Counter := 0;
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_Safety_Selector.G_Smoke_Unstable_Counter := GVL_Safety_Selector.G_Smoke_Unstable_Counter + 1;
    GVL_Safety_Selector.G_Smoke_Stable_Counter := 0;
ELSE
    GVL_Safety_Selector.G_Smoke_Unstable_Counter := 0;
END_IF;

// --- STABLE COUNTERS (for recovery) ---
IF NOT GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable AND
   GVL_Safety_Bridge.G_CO_Diff < GVL_Safety_Selector.G_CO_Shadow_Recovery_Diff THEN
    GVL_Safety_Selector.G_CO_Stable_Counter := GVL_Safety_Selector.G_CO_Stable_Counter + 1;
END_IF;

IF NOT GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable AND
   GVL_Safety_Bridge.G_Methane_Diff < GVL_Safety_Selector.G_Methane_Shadow_Recovery_Diff THEN
    GVL_Safety_Selector.G_Methane_Stable_Counter := GVL_Safety_Selector.G_Methane_Stable_Counter + 1;
END_IF;

IF NOT GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_Safety_Selector.G_Smoke_Stable_Counter := GVL_Safety_Selector.G_Smoke_Stable_Counter + 1;
END_IF;

// --- FALLBACK ---
IF GVL_Safety_Selector.G_Block_Shadow_On_Mismatch THEN

    IF GVL_Safety_Selector.G_CO_Unstable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
        GVL_Safety_Selector.G_Use_Shadow_CO := FALSE;
    END_IF;

    IF GVL_Safety_Selector.G_Methane_Unstable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
        GVL_Safety_Selector.G_Use_Shadow_Methane := FALSE;
    END_IF;

    IF GVL_Safety_Selector.G_Smoke_Unstable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
        GVL_Safety_Selector.G_Use_Shadow_Smoke := FALSE;
    END_IF;

END_IF;

// --- RECOVERY ---
IF GVL_Safety_Selector.G_CO_Stable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
    GVL_Safety_Selector.G_Use_Shadow_CO := TRUE;
END_IF;

IF GVL_Safety_Selector.G_Methane_Stable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
    GVL_Safety_Selector.G_Use_Shadow_Methane := TRUE;
END_IF;

IF GVL_Safety_Selector.G_Smoke_Stable_Counter >= GVL_Safety_Selector.G_Shadow_Unstable_Cycles_Limit THEN
    GVL_Safety_Selector.G_Use_Shadow_Smoke := TRUE;
END_IF;


IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Mismatch THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Smoke shadow mismatch';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Unstable THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Methane shadow unstable';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Unstable THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'CO shadow unstable';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Quality_Text := 'Shadow safety quality OK';
END_IF;

// === SHADOW POLICY EVENT LOGGING ===
// Event codes:
// 2101 CO shadow fallback
// 2102 CO shadow recovery
// 2111 Methane shadow fallback
// 2112 Methane shadow recovery
// 2121 Smoke shadow fallback
// 2122 Smoke shadow recovery

IF (NOT GVL_Safety_Selector.G_Use_Shadow_CO) AND L_Shadow_CO_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 21,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2101,
        VI_Param2 := 0
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Fallback_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_CO AND (NOT L_Shadow_CO_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 22,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2102,
        VI_Param2 := 1
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Recovery_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

IF (NOT GVL_Safety_Selector.G_Use_Shadow_Methane) AND L_Shadow_Methane_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 23,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2111,
        VI_Param2 := 0
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Fallback_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_Methane AND (NOT L_Shadow_Methane_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 24,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2112,
        VI_Param2 := 1
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Recovery_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

IF (NOT GVL_Safety_Selector.G_Use_Shadow_Smoke) AND L_Shadow_Smoke_Enabled_Prev THEN
    fbLogEvent(
        VI_Event_Type := 25,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2121,
        VI_Param2 := 0
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Fallback_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

IF GVL_Safety_Selector.G_Use_Shadow_Smoke AND (NOT L_Shadow_Smoke_Enabled_Prev) THEN
    fbLogEvent(
        VI_Event_Type := 26,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 2122,
        VI_Param2 := 1
    );
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count + 1;
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Recovery_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

L_Shadow_CO_Enabled_Prev := GVL_Safety_Selector.G_Use_Shadow_CO;
L_Shadow_Methane_Enabled_Prev := GVL_Safety_Selector.G_Use_Shadow_Methane;
L_Shadow_Smoke_Enabled_Prev := GVL_Safety_Selector.G_Use_Shadow_Smoke;

// === SHADOW POLICY STATS SUMMARY ===
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count <=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recovery_Count;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count <=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recovery_Count;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count <=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recovery_Count;

// dominant channel by fallback count
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel := 'CO';

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count >
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel := 'Methane';
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count >
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count AND
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count >
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel := 'Smoke';
END_IF;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count = 0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'No shadow fallback events';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count =
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'Shadow policy balanced';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count >
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'Fallbacks exceed recoveries';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text := 'Recoveries exceed fallbacks';
END_IF;

// === SHADOW POLICY RECENT ACTIVITY WINDOW ===
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS = 0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS := 3600000; // 1 hour default
END_IF;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Fallback :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Fallback_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Fallback_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Recovery :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Recovery_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Last_Recovery_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Fallback :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Fallback_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Fallback_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Recovery :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Recovery_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Last_Recovery_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Fallback :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Fallback_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Fallback_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Recovery :=
    (GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Recovery_MS > 0) AND
    ((GVL_STATUS.G_System_Time_MS - GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Last_Recovery_MS) <=
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS);

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Fallback OR
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Fallback OR
   GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Fallback THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text := 'Recent shadow fallback activity';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Recent_Recovery OR
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Recent_Recovery OR
      GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Recent_Recovery THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text := 'Recent shadow recovery activity';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text := 'No recent shadow policy activity';
END_IF;

// === SHADOW POLICY RATE METRICS ===
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS > 0 THEN
    L_Window_Hours :=
        TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Window_MS) / 3600000.0;
ELSE
    L_Window_Hours := 1.0;
END_IF;

// total rates
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour :=
    TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count) / L_Window_Hours;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour :=
    TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count) / L_Window_Hours;

// per-channel fallback rates
GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Fallback_Per_Hour :=
    TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Fallback_Count) / L_Window_Hours;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Fallback_Per_Hour :=
    TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Fallback_Count) / L_Window_Hours;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Fallback_Per_Hour :=
    TO_REAL(GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Fallback_Count) / L_Window_Hours;

// simple activity classification
GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_High_Activity :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_High_Activity THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text := 'High shadow fallback rate';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 0.0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text := 'Moderate shadow activity';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text := 'No shadow fallback activity';
END_IF;

// === SHADOW POLICY RATE ALERTS ===
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour <= 0.0 THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour := 10.0;
END_IF;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Fallback_Per_Hour >
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Fallback_Per_Hour >
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Fallback_Per_Hour >
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Threshold_Per_Hour;

GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Alert_Active OR
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Alert_Active OR
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Alert_Active;

IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Rate_Alert_Active THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'Smoke fallback rate alert';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Rate_Alert_Active THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'Methane fallback rate alert';
ELSIF GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Rate_Alert_Active THEN
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'CO fallback rate alert';
ELSE
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text := 'No shadow rate alerts';
END_IF;

// === EXTERNAL MONITORING EXPORT ===
// === GATEWAY SHADOW EXPORT BRIDGE ===
GVL_GATEWAY.G_Shadow_Alert_Active :=
    GVL_External_Monitoring.G_Shadow_Any_Alert_Active;

GVL_GATEWAY.G_Shadow_Dominant_Channel :=
    GVL_External_Monitoring.G_Shadow_Dominant_Channel;

GVL_GATEWAY.G_Shadow_Policy_Summary_Text :=
    GVL_External_Monitoring.G_Shadow_Policy_Summary_Text;

GVL_GATEWAY.G_Shadow_Recent_Activity_Text :=
    GVL_External_Monitoring.G_Shadow_Recent_Activity_Text;

GVL_GATEWAY.G_Shadow_Rate_Summary_Text :=
    GVL_External_Monitoring.G_Shadow_Rate_Summary_Text;

GVL_GATEWAY.G_Shadow_Total_Fallback_Count :=
    GVL_External_Monitoring.G_Shadow_Total_Fallback_Count;

GVL_GATEWAY.G_Shadow_Total_Recovery_Count :=
    GVL_External_Monitoring.G_Shadow_Total_Recovery_Count;


GVL_External_Monitoring.G_Shadow_Any_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;

GVL_External_Monitoring.G_Shadow_CO_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Active;
GVL_External_Monitoring.G_Shadow_Methane_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Active;
GVL_External_Monitoring.G_Shadow_Smoke_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Active;

GVL_External_Monitoring.G_Shadow_CO_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_CO_Healthy;
GVL_External_Monitoring.G_Shadow_Methane_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Methane_Healthy;
GVL_External_Monitoring.G_Shadow_Smoke_Healthy :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Smoke_Healthy;

GVL_External_Monitoring.G_Shadow_Dominant_Channel :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Dominant_Channel;
GVL_External_Monitoring.G_Shadow_Policy_Summary_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Policy_Summary_Text;
GVL_External_Monitoring.G_Shadow_Recent_Activity_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Recent_Activity_Text;
GVL_External_Monitoring.G_Shadow_Rate_Summary_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Summary_Text;
GVL_External_Monitoring.G_Shadow_Rate_Alert_Text :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Text;

GVL_External_Monitoring.G_Shadow_Total_Fallback_Count :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Fallback_Count;
GVL_External_Monitoring.G_Shadow_Total_Recovery_Count :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Total_Recovery_Count;

GVL_External_Monitoring.G_Shadow_Rate_Fallback_Per_Hour :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour;
GVL_External_Monitoring.G_Shadow_Rate_Recovery_Per_Hour :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour;

GVL_External_Monitoring.G_Shadow_Rate_Alert_Active :=
    GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;

// === HEATING PROTECTION OBSERVER ===
fbFreezeProtection(
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
    VI_Floor_Temps := L_FloorTemps_8
);

fbOverheatProtection(
    VI_Temps := L_FloorTemps_8
);

GVL_STATUS.G_Diagnostics.Heating_Freeze_Alert := fbFreezeProtection.VO_Freeze_Alert;
GVL_STATUS.G_Diagnostics.Heating_Freeze_Pump_Force_Request := fbFreezeProtection.VO_Pump_Force_On;
GVL_STATUS.G_Diagnostics.Heating_Overheat_Detected := fbOverheatProtection.VO_Overheat_Detected;
GVL_STATUS.G_Diagnostics.Heating_Overheat_Locked_Circuits := fbOverheatProtection.VO_Locked_Circuits;

IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Detected THEN
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating overheat detected';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Freeze_Alert THEN
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating freeze protection alert';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Freeze_Pump_Force_Request THEN
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating anti-freeze pump request';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Protection_Summary_Text := 'Heating protection normal';
END_IF;

// === HEATING ENFORCEMENT REQUEST LAYER ===
GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active :=
    GVL_STATUS.G_Diagnostics.Heating_Freeze_Pump_Force_Request;

GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active :=
    GVL_STATUS.G_Diagnostics.Heating_Overheat_Detected;

IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Enforcement_Request_Text := 'Request: lock overheated circuits';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Enforcement_Request_Text := 'Request: force heating pump';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Enforcement_Request_Text := 'No heating enforcement requests';
END_IF;

// === HEATING PRIORITY ARBITRATION ===
// Safe policy:
// - pump force is blocked in SAFE_STOP and on emergency stop
// - overheated circuit lock remains allowed as a protective restriction
GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Allowed :=
    (GVL_STATE.G_System_Mode <> E_System_Operating_Mode.MODE_SAFE_STOP) AND
    (NOT GVL_STATE.G_Safety_Emergency_Stop);

GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Allowed := TRUE;

IF NOT GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Allowed THEN
    GVL_STATUS.G_Diagnostics.Heating_Arbitration_Text := 'Pump force blocked by mode/safety';
ELSIF NOT GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Allowed THEN
    GVL_STATUS.G_Diagnostics.Heating_Arbitration_Text := 'Zone lock blocked by arbitration';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Arbitration_Text := 'Heating arbitration allows enforcement';
END_IF;

// === HEATING ENFORCEMENT COOLDOWN ===
IF L_Heating_Pump_Force_Hold_MS = 0 THEN
    L_Heating_Pump_Force_Hold_MS := 30000;
END_IF;

IF L_Heating_Zone_Lock_Hold_MS = 0 THEN
    L_Heating_Zone_Lock_Hold_MS := 60000;
END_IF;

// start/refresh holds from active requests
IF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Until_MS :=
        GVL_STATUS.G_System_Time_MS + L_Heating_Pump_Force_Hold_MS;
END_IF;

IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Until_MS :=
        GVL_STATUS.G_System_Time_MS + L_Heating_Zone_Lock_Hold_MS;
END_IF;

GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Active :=
    (GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Until_MS > 0) AND
    (GVL_STATUS.G_System_Time_MS < GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Until_MS);

GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Active :=
    (GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Until_MS > 0) AND
    (GVL_STATUS.G_System_Time_MS < GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Until_MS);

IF GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Cooldown_Text := 'Zone lock hold active';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Cooldown_Text := 'Pump force hold active';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Cooldown_Text := 'No heating cooldown hold active';
END_IF;

// === HEATING REAL ENFORCEMENT BRIDGE ===
GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active := FALSE;
GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active := FALSE;

// real bridge: force manifold pumps if freeze protection requests pump support
IF (GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Request_Active OR
    GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Hold_Active) AND
   GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Allowed THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
            GVL_STATE.G_Manifold_Pumps[L_i] := TRUE;
            GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active := TRUE;
        END_IF;
    END_FOR;
END_IF;

// real bridge: close overheated floor-heating circuits
IF (GVL_STATUS.G_Diagnostics.Heating_Overheat_Enforcement_Request_Active OR
    GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Hold_Active) AND
   GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Allowed THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF GVL_STATUS.G_Diagnostics.Heating_Overheat_Locked_Circuits[L_i] THEN
            GVL_STATE.G_Zone_Valves[L_i] := FALSE;
            GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active := TRUE;
        END_IF;
    END_FOR;
END_IF;

IF GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Real_Enforcement_Text := 'Applied: overheated circuits locked';
ELSIF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active THEN
    GVL_STATUS.G_Diagnostics.Heating_Real_Enforcement_Text := 'Applied: heating pumps forced on';
ELSE
    GVL_STATUS.G_Diagnostics.Heating_Real_Enforcement_Text := 'No real heating enforcement applied';
END_IF;

// === HEATING ENFORCEMENT TELEMETRY ===
IF GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active AND
   (NOT L_Heating_Pump_Force_Bridge_Prev) THEN
    GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Event_Count :=
        GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Text := 'Pump force bridge activated';
END_IF;

IF GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active AND
   (NOT L_Heating_Zone_Lock_Bridge_Prev) THEN
    GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Event_Count :=
        GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Event_Count + 1;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Time_MS := GVL_STATUS.G_System_Time_MS;
    GVL_STATUS.G_Diagnostics.Heating_Last_Event_Text := 'Zone lock bridge activated';
END_IF;

L_Heating_Pump_Force_Bridge_Prev := GVL_STATUS.G_Diagnostics.Heating_Pump_Force_Bridge_Active;
L_Heating_Zone_Lock_Bridge_Prev := GVL_STATUS.G_Diagnostics.Heating_Zone_Lock_Bridge_Active;

// === SNAPSHOT LAYER (PHASE 1) ===
// safe in-memory snapshot using real ST_State_Snapshot fields
L_Snapshot.timestamp_ms := GVL_STATUS.G_System_Time_MS;
L_Snapshot.operator_id := 'SYSTEM';
L_Snapshot.scenario_id := GVL_STATUS.G_Current_Scenario;
L_Snapshot.lighting_levels := GVL_STATE.G_Lighting_Levels;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Snapshot.floor_heating_setpoints[L_i] := GVL_CONFIG.G_HMI_FloorHeating_Configs[L_i].design_temp;
END_FOR;

L_Snapshot.alarm_active := GVL_ALARM.G_Global_Critical OR GVL_ALARM.G_Global_Warning;
L_Snapshot.crc32 := DWORD#0;

// === SNAPSHOT MULTI EVENT TRIGGER ===
IF L_Snapshot_Min_Interval_MS = 0 THEN
    L_Snapshot_Min_Interval_MS := 5000;
END_IF;

// rate alert
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active AND
   (NOT L_Snapshot_Trigger_Prev) AND
   ((L_Snapshot_Last_Event_MS = 0) OR
    ((GVL_STATUS.G_System_Time_MS - L_Snapshot_Last_Event_MS) >= L_Snapshot_Min_Interval_MS)) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#1,
        VI_Current_State  := L_Snapshot
    );
    L_Snapshot_Last_Event_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

// fallback spike
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0 AND
   (NOT L_Snapshot_Fallback_Prev) AND
   ((L_Snapshot_Last_Event_MS = 0) OR
    ((GVL_STATUS.G_System_Time_MS - L_Snapshot_Last_Event_MS) >= L_Snapshot_Min_Interval_MS)) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#2,
        VI_Current_State  := L_Snapshot
    );
    L_Snapshot_Last_Event_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

// recovery spike
IF GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0 AND
   (NOT L_Snapshot_Recovery_Prev) AND
   ((L_Snapshot_Last_Event_MS = 0) OR
    ((GVL_STATUS.G_System_Time_MS - L_Snapshot_Last_Event_MS) >= L_Snapshot_Min_Interval_MS)) THEN
    fbSnapshotMgr(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_Trigger_Event  := TRUE,
        VI_Event_Code     := WORD#3,
        VI_Current_State  := L_Snapshot
    );
    L_Snapshot_Last_Event_MS := GVL_STATUS.G_System_Time_MS;
END_IF;

// update prev
L_Snapshot_Trigger_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Alert_Active;
L_Snapshot_Fallback_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Fallback_Per_Hour > 10.0;
L_Snapshot_Recovery_Prev := GVL_STATUS.G_Diagnostics.Sensor_Shadow_Rate_Recovery_Per_Hour > 10.0;


// === LIFETIME UPDATE ===

// pump (временно FALSE — до реального сигнала)
fbLifetimePump(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := GVL_PERSISTENT.P_DHW_Heating_Active,
    VI_Device_ID      := GVL_Lifetime.G_Device_Pump,
    VI_Nominal_Hours  := GVL_Lifetime.G_Pump_Nominal_Hours,
    VIO_Status        := GVL_Lifetime.G_Status[1]
);

// fan (временно FALSE — до реального сигнала)
fbLifetimeFan(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Device_Active  := (
        GVL_STATE.G_Supply_Fans[1] > 0 OR
        GVL_STATE.G_Exhaust_Fans[1] > 0
    ),
    VI_Device_ID      := GVL_Lifetime.G_Device_Fan,
    VI_Nominal_Hours  := GVL_Lifetime.G_Fan_Nominal_Hours,
    VIO_Status        := GVL_Lifetime.G_Status[2]
);


// === LIFETIME HMI ACTIVE VIEW ===
IF GVL_Lifetime.G_Active_Device_Index < 1 THEN
    GVL_Lifetime.G_Active_Device_Index := 1;
ELSIF GVL_Lifetime.G_Active_Device_Index > 4 THEN
    GVL_Lifetime.G_Active_Device_Index := 4;
END_IF;

GVL_Lifetime.G_Active_Runtime_Hours := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].runtime_hours;
GVL_Lifetime.G_Active_Remaining_Hours := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].remaining_hours;
GVL_Lifetime.G_Active_Remaining_Percent := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].remaining_percent;
GVL_Lifetime.G_Active_Maintenance_Required := GVL_Lifetime.G_Status[GVL_Lifetime.G_Active_Device_Index].maintenance_required;
GVL_Lifetime.G_Active_Label := GVL_Lifetime.G_Device_Labels[GVL_Lifetime.G_Active_Device_Index];

// === LIFETIME HEALTH SUMMARY ===
GVL_Lifetime.G_Any_Maintenance_Required :=
    GVL_Lifetime.G_Status[1].maintenance_required OR
    GVL_Lifetime.G_Status[2].maintenance_required OR
    GVL_Lifetime.G_Status[3].maintenance_required OR
    GVL_Lifetime.G_Status[4].maintenance_required;

GVL_Lifetime.G_Maintenance_Warning :=
    (GVL_Lifetime.G_Status[1].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[2].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[3].remaining_percent <= 20) OR
    (GVL_Lifetime.G_Status[4].remaining_percent <= 20);

GVL_Lifetime.G_Maintenance_Critical :=
    (GVL_Lifetime.G_Status[1].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[2].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[3].remaining_percent <= 5) OR
    (GVL_Lifetime.G_Status[4].remaining_percent <= 5);

// === TREND → HISTORY WRITE (RATE-LIMITED SAFE MVP) ===
L_Trend_Write := (L_Trend_Data.record_count > 0);
L_Trend_Write_Allowed := FALSE;

IF L_Trend_Write AND NOT L_Trend_Write_Prev THEN
    IF (L_Trend_Last_Write_MS = 0) OR
       ((GVL_STATUS.G_System_Time_MS - L_Trend_Last_Write_MS) >= GVL_CONSTANTS.C_MS_IN_HOUR) THEN
        IF ABS(L_Trend_Avg - L_Trend_Last_Written_Avg) >= 0.5 THEN
            L_Trend_Write_Allowed := TRUE;
        END_IF;
    END_IF;

    IF L_Trend_Write_Allowed THEN
        L_Trend_Event.event_code := 1001;
        L_Trend_Event.event_value := L_Trend_Avg;
        L_Trend_Event.zone_id := 0;
        L_Trend_Event.operator_id := '';
        L_History_Write_Event := TRUE;
        L_History_Event := L_Trend_Event;

        L_Trend_Last_Write_MS := GVL_STATUS.G_System_Time_MS;
        L_Trend_Last_Written_Avg := L_Trend_Avg;
    END_IF;
END_IF;

L_Trend_Write_Prev := L_Trend_Write;

// >>> BULK_SYNC_ANCHOR: PRG_System <<<

// === EVENT LOGGING: FAULTS ===

// WATCHDOG
IF fbWatchdog.VO_Watchdog_Fault AND NOT L_Watchdog_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 11,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 1
    );
END_IF;

IF NOT fbWatchdog.VO_Watchdog_Fault AND L_Watchdog_Fault_Prev THEN
    fbLogEvent(
        VI_Event_Type := 12,
        VI_Timestamp := GVL_STATUS.G_System_Time_MS,
        VI_Param1 := 1,
        VI_Param2 := 0
    );
END_IF;

L_Watchdog_Fault_Prev := fbWatchdog.VO_Watchdog_Fault;

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

// --- HEATING REQUEST LAYER ---
GVL_HEATING_REQUEST.G_Preheat_Request := fbRuleEngine.VO_Preheat_Request;

// --- FREEZE REQUEST ---
GVL_HEATING_REQUEST.G_Freeze_Request :=
    (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
