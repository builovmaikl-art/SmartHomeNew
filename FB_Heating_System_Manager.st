// ==============================================================================
// Блок управления системой отопления (Heating System Manager)
// Назначение:
// - Управление контурами теплого пола (открытие/закрытие клапанов).
// - Управление насосами коллекторов и смесительными узлами.
// - Управление каскадом котлов (ротация, расчет ресурса).
// - Защита от перегрева и замерзания.
// - Интеграция с Rule Engine.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_System_Manager
VAR_INPUT
    VI_Preheat_Request : BOOL; // preheat scenario trigger
    L_Climate_Zone_ID : INT;

    VI_System_Mode : E_System_Operating_Mode; // System mode from State Manager

    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_Current_TOD : TOD; // Текущее время суток
    VI_IsActivePLC : BOOL; // Флаг: Данный ПЛК является ведущим
    VI_Outdoor_Temp : REAL; // Уличная температура воздуха (°C)
    VI_Config : ST_Heating_Config; // Конфигурация системы отопления
    VI_Tariff : ST_Tariff_Config; // Настройки тарифов
    VI_Current_Hour : UINT; // Текущий час (0-23)
    VI_Boiler_Stop : BOOL; // Команда на остановку котлов (от газовой/пожарной сигнализации); вход сохранён для совместимости, не используется как direct control
    VI_DHW_Heating_Demand : BOOL; // Запрос тепла от бойлера ГВС (приоритет)
    VI_DHW_Target_Temp : REAL; // Целевая температура бойлера ГВС
    VI_Current_Scenario : E_SCENARIO_TYPE; // Текущий сценарий
    VI_Emergency_Stop : BOOL; // Агрегированный аварийный стоп от подсистемы безопасности
    VI_Gas_Safety_Stop : BOOL; // Газовая авария / закрытие газового клапана
    VI_Boiler_Error_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Ошибки котлов / ошибка адаптера
    VI_Boiler_OT_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Признак доступности OpenTherm-канала
    VI_Boiler_Modulation : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL; // Текущая модуляция котлов (%)
END_VAR
VAR_IN_OUT
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL; // Температуры стяжки пола по зонам
    VI_Room_Temps : ARRAY[1..16] OF REAL; // Температуры воздуха в помещениях
    VI_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Давление в коллекторах (бар)
    VI_Manifold_Currents : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Ток насосов коллекторов (мА)
    VI_Manifold_Temps_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Температура подачи на коллекторах
    VI_Manifold_Temps_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Температура обратки на коллекторах
    VI_Boiler_Flame_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Статус наличия пламени в котлах
    VI_Zone_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF ST_FloorHeating_Circuit_Config; // Конфигурации контуров
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action; // Действия от Rule Engine
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL; // Статусы модулей ввода-вывода
    VI_Scenario_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_SCENARIOS] OF ST_Scenario_Config; // Конфигурации сценариев
    VI_Manifold_End_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // Концевики клапанов
    VI_Valve_Test_Config : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Valve_Test_Config; // Конфигурация тестирования клапанов
END_VAR

VAR_OUTPUT
    VO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Выход: Положение клапанов смесителей (0-100%)
    VO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // Выход: Управление насосами коллекторов
    VO_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL; // Выход: Управление клапанами контуров (Зоны 1-16)
    VO_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Физические команды в OpenTherm
    VO_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL; // Физические уставки в OpenTherm
    VO_Backup_Circulation_Pump : BOOL; // Резервный циркуляционный насос в режиме антизамерзания при газовой аварии
    VO_Electric_Heater_Enable : BOOL; // Сухой контакт электрического нагревателя антизамерзания
    VO_Freeze_Risk_Status : BOOL; // Признак риска замерзания при защёлкнутой газовой аварии
    VO_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status; // Сводный статус коллекторных узлов для HMI
    VO_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status; // Сводный статус котлов для HMI
END_VAR

VAR
    L_Lead_Boiler : BYTE := 1; // Номер ведущего котла (1 или 2)
    L_i : INT; // Индекс для циклов
    L_j : INT; // Вспомогательный индекс
    L_Target_Supply_Temp : REAL; // Рассчитанная целевая температура подачи
    L_Demand_Power : REAL; // Суммарный запрос мощности от всех коллекторов
    L_Any_Zone_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // Флаги наличия запроса тепла по коллекторам

    // Плавный переход сценария
    L_Prev_Scenario : E_SCENARIO_TYPE;
    L_Scenario_Adjust : REAL;
    L_Target_Scenario_Adjust : REAL;
    L_Transition_Temp : FB_Scenario_Transition_Controller;

    fbValveTestManager : FB_Valve_Test_Manager; // Менеджер тестирования клапанов
    L_IO_Failsafe_Active : BOOL; // Флаг потери связи с модулями I/O
    L_Freeze_Mode_Active : BOOL; // Флаг антизамерзания по ТЗ
    L_Freeze_Target_Supply : REAL; // Уставка подачи в режиме антизамерзания
    L_Min_Supply_Temp : REAL; // Минимальная температура теплоносителя для антизамерзания
    L_Policy_Normal : BOOL; // Policy: normal operation
    L_Policy_Safe_Stop : BOOL; // Policy: hard safe stop
    L_Policy_Degraded : BOOL; // Policy: limited conservative operation
    L_Policy_Freeze_Protection : BOOL; // Policy: freeze protection mode
    L_Any_Sensor_Error : BOOL;
    L_Any_Subsystem_Degraded : BOOL;
    L_Adaptive_Max_Delta : REAL;
    L_Adaptive_Effective_Delta : REAL;
    L_Adaptive_Correction : REAL;
    fbAdaptiveTarget : FB_Heating_Adaptive_Target; // Extracted adaptive target helper
    fbSafetyGate : FB_Heating_Safety_Gate; // Extracted safety gate helper
    fbCircuitControl : FB_Heating_Circuit_Control; // Extracted circuit control helper
    fbManifoldControl : FB_Heating_Manifold_Control; // Extracted manifold control helper
    fbBoilerControl : FB_Heating_Boiler_Control; // Extracted boiler control helper
END_VAR



// ========================================
// Heating policy layer
// ========================================
L_Policy_Normal := (VI_System_Mode = E_System_Operating_Mode.MODE_NORMAL);
L_Policy_Safe_Stop := (VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
L_Policy_Degraded := (VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED);
L_Policy_Freeze_Protection := (VI_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);

fbSafetyGate(
    VI_System_Mode := VI_System_Mode,
    VI_Emergency_Stop := VI_Emergency_Stop,
    VI_Gas_Safety_Stop := VI_Gas_Safety_Stop,
    VI_IO_Failsafe_Active := FALSE,
    VI_Outdoor_Temp := VI_Outdoor_Temp,
    VI_Freeze_Threshold := VI_Config.Freeze_Threshold,
    VI_Floor_Temps := VI_Floor_Temps,
    VO_Freeze_Mode_Active => L_Freeze_Mode_Active,
    VO_Freeze_Target_Supply => L_Freeze_Target_Supply
);

// ========================================
// Heating freeze policy activation
// ========================================
// Calculated by fbSafetyGate above.

// 0. Агрегация деградации для system mode
GVL_STATE.G_Heating_IO_Fault := FALSE;
GVL_STATE.G_Heating_Sensor_Fault := FALSE;
GVL_STATE.G_Heating_Subsystem_Degraded := FALSE;
L_Any_Sensor_Error := FALSE;
L_Any_Subsystem_Degraded := FALSE;

// 0. Аварийный стоп от подсистемы безопасности
VO_Backup_Circulation_Pump := FALSE;
VO_Electric_Heater_Enable := FALSE;
VO_Freeze_Risk_Status := FALSE;

IF VI_Gas_Safety_Stop THEN
    L_Freeze_Mode_Active := (VI_Outdoor_Temp < -5.0);
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF VI_Floor_Temps[L_i] < 7.0 THEN
            L_Freeze_Mode_Active := TRUE;
        END_IF;
        VO_Zone_Valves[L_i] := FALSE;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        VO_Manifold_Pumps[L_i] := FALSE;
        VO_Manifold_Valves[L_i] := 0.0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Boiler_OT_Enable[L_i] := FALSE;
        VO_Boiler_OT_Setpoint[L_i] := 0.0;
        VO_Boiler_Status[L_i].Warning := FALSE;
        VO_Boiler_Status[L_i].Error := TRUE;
    END_FOR;

    IF L_Freeze_Mode_Active THEN
        VO_Backup_Circulation_Pump := TRUE;
        L_Freeze_Target_Supply := LIMIT(20.0, VI_Config.Freeze_Threshold + 2.0, 35.0);
        L_Min_Supply_Temp := 1000.0;
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            IF VI_Manifold_Temps_Supply[L_i] < L_Min_Supply_Temp THEN
                L_Min_Supply_Temp := VI_Manifold_Temps_Supply[L_i];
            END_IF;
        END_FOR;
        IF L_Min_Supply_Temp > 900.0 THEN
            L_Min_Supply_Temp := 0.0;
        END_IF;

        IF L_Min_Supply_Temp < (L_Freeze_Target_Supply - 1.0) THEN
            VO_Electric_Heater_Enable := TRUE;
        ELSIF L_Min_Supply_Temp > (L_Freeze_Target_Supply + 1.0) THEN
            VO_Electric_Heater_Enable := FALSE;
        END_IF;

        // При защёлкнутой газовой аварии оператор должен видеть, что система живёт в деградированном anti-freeze режиме.
        VO_Freeze_Risk_Status := TRUE;
    END_IF;

    RETURN;
END_IF;

IF VI_Emergency_Stop OR L_Policy_Safe_Stop THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        VO_Zone_Valves[L_i] := FALSE;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        VO_Manifold_Pumps[L_i] := FALSE;
        VO_Manifold_Valves[L_i] := 0.0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Boiler_OT_Enable[L_i] := FALSE;
        VO_Boiler_OT_Setpoint[L_i] := 0.0;
        VO_Boiler_Status[L_i].Warning := FALSE;
        VO_Boiler_Status[L_i].Error := TRUE;
    END_FOR;

    RETURN;
END_IF;

// 1. Проверка связи с модулями ввода-вывода (ТЗ 2.0)
L_IO_Failsafe_Active := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    IF NOT VI_IO_Modules_Online[L_i] THEN
        L_IO_Failsafe_Active := TRUE;
        GVL_STATE.G_Heating_IO_Fault := TRUE;
GVL_STATE.G_Heating_Subsystem_Degraded := TRUE;
        EXIT;
    END_IF;
END_FOR;

IF L_IO_Failsafe_Active THEN
    // Fail-safe: закрываем зональные клапаны, чтобы не разгонять неконтролируемые контуры,
    // но при риске замерзания сохраняем минимальную циркуляцию и минимальную теплогенерацию.
    L_Freeze_Mode_Active := (VI_Outdoor_Temp < -5.0);

    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF VI_Floor_Temps[L_j] < 7.0 THEN
            L_Freeze_Mode_Active := TRUE;
        END_IF;
        VO_Zone_Valves[L_j] := FALSE;
    END_FOR;

    IF L_Freeze_Mode_Active THEN
        L_Freeze_Target_Supply := LIMIT(20.0, VI_Config.Freeze_Threshold + 2.0, 35.0);
    ELSE
        L_Freeze_Target_Supply := 0.0;
    END_IF;

    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        IF L_Freeze_Mode_Active THEN
            VO_Manifold_Pumps[L_j] := TRUE;
            VO_Manifold_Valves[L_j] := 35.0;
        ELSE
            VO_Manifold_Pumps[L_j] := FALSE;
            VO_Manifold_Valves[L_j] := 0.0;
        END_IF;
    END_FOR;

    // В аварийном I/O режиме напрямую формируем только legacy request-mirror.
    // Реальные физические команды всё равно будут интерпретированы transport-слоем выше по архитектуре.
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Boiler_OT_Enable[L_j] := FALSE;
        VO_Boiler_OT_Setpoint[L_j] := 0.0;
    END_FOR;

    IF L_Freeze_Mode_Active THEN
        // В fail-safe используем только ведущий аварийный вариант: котёл №1 на минимальной уставке.
        IF VI_Boiler_OT_Online[1] AND NOT VI_Boiler_Error_Status[1] THEN
            VO_Boiler_OT_Enable[1] := TRUE;
            VO_Boiler_OT_Setpoint[1] := L_Freeze_Target_Supply;
        END_IF;
    END_IF;

    RETURN;
END_IF;



// --- HEATING TARGET INJECTION / ADAPTIVE TARGET ---
fbAdaptiveTarget(
    VI_Base_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Global_Target_Temperature := GVL_STATE.G_Target_Temperature,
    VI_Zone_Configs := VI_Zone_Configs,
    VI_Floor_Temps := VI_Floor_Temps,
    VI_Room_Temps := VI_Room_Temps,
    VO_Target_Supply_Temp => L_Target_Supply_Temp,
    VO_Adaptive_Correction => L_Adaptive_Correction,
    VO_Adaptive_Effective_Delta => L_Adaptive_Effective_Delta,
    VO_Adaptive_Max_Delta => L_Adaptive_Max_Delta
);

// --- CIRCUIT CONTROL ---
fbCircuitControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Current_Hour := VI_Current_Hour,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Config := VI_Config,
    VI_Tariff := VI_Tariff,
    VI_Scenario_Adjust := L_Scenario_Adjust,
    VI_Zone_Configs := VI_Zone_Configs,
    VI_Floor_Temps := VI_Floor_Temps,
    VI_Room_Temps := VI_Room_Temps,
    VI_Rule_Actions := VI_Rule_Actions,
    VO_Zone_Valves => VO_Zone_Valves,
    VO_Heating_Sensor_Fault => L_Any_Sensor_Error
);

GVL_STATE.G_Heating_Sensor_Fault := L_Any_Sensor_Error;

// 3. Определение потребности в работе коллекторных насосов
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    L_Any_Zone_Active[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF VO_Zone_Valves[L_i] THEN
        L_j := VI_Zone_Configs[L_i].manifold_id;
        IF L_j >= 1 AND L_j <= GVL_CONSTANTS.C_MAX_MANIFOLDS THEN
            L_Any_Zone_Active[L_j] := TRUE;
        END_IF;
    END_IF;
END_FOR;

// --- MANIFOLD CONTROL ---
fbManifoldControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_Freeze_Mode_Active := L_Freeze_Mode_Active,
    VI_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Any_Zone_Active := L_Any_Zone_Active,
    VI_Manifold_Pressures := VI_Manifold_Pressures,
    VI_Manifold_Currents := VI_Manifold_Currents,
    VI_Manifold_Temps_Supply := VI_Manifold_Temps_Supply,
    VI_Manifold_Temps_Return := VI_Manifold_Temps_Return,
    VO_Manifold_Pumps => VO_Manifold_Pumps,
    VO_Manifold_Valves => VO_Manifold_Valves,
    VO_Status => VO_Status
);

// Valve test override remains in manager for now.
fbValveTestManager(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Valve_Currents := VI_Manifold_Currents,
    VI_Valve_End_Switches := VI_Manifold_End_Switches,
    VI_Config := VI_Valve_Test_Config
);

IF fbValveTestManager.VO_Test_Active THEN
    L_i := fbValveTestManager.VO_Current_Valve;
    IF L_i >= 1 AND L_i <= GVL_CONSTANTS.C_MAX_MANIFOLDS THEN
        IF fbValveTestManager.VO_Valve_Cmd[L_i] THEN
            VO_Manifold_Valves[L_i] := 100.0;
        ELSE
            VO_Manifold_Valves[L_i] := 0.0;
        END_IF;
        VO_Manifold_Pumps[L_i] := FALSE; // Отключаем насос при тестировании клапана
    END_IF;
END_IF;

// --- BOILER CONTROL ---
fbBoilerControl(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_DHW_Target_Temp := VI_DHW_Target_Temp,
    VI_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Freeze_Mode_Active := L_Freeze_Mode_Active,
    VI_Policy_Degraded := L_Policy_Degraded,
    VI_Manifold_Pumps := VO_Manifold_Pumps,
    VI_Manifold_Valves := VO_Manifold_Valves,
    VI_Boiler_Flame_Status := VI_Boiler_Flame_Status,
    VI_Boiler_Error_Status := VI_Boiler_Error_Status,
    VI_Boiler_OT_Online := VI_Boiler_OT_Online,
    VI_Boiler_Modulation := VI_Boiler_Modulation,
    VO_Boiler_OT_Enable => VO_Boiler_OT_Enable,
    VO_Boiler_OT_Setpoint => VO_Boiler_OT_Setpoint,
    VO_Boiler_Status => VO_Boiler_Status,
    VO_Any_Subsystem_Degraded => L_Any_Subsystem_Degraded,
    VO_Lead_Boiler => L_Lead_Boiler,
    VO_Demand_Power => L_Demand_Power
);

GVL_STATE.G_Heating_Subsystem_Degraded := L_Any_Subsystem_Degraded;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_System_Manager <<<
