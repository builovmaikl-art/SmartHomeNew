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
    VI_Floor_Temps : ARRAY[1..8] OF REAL; // Температуры стяжки пола по зонам
    VI_Room_Temps : ARRAY[1..16] OF REAL; // Температуры воздуха в помещениях
    VI_Manifold_Pressures : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Давление в коллекторах (бар)
    VI_Manifold_Currents : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Ток насосов коллекторов (мА)
    VI_Manifold_Temps_Supply : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Температура подачи на коллекторах
    VI_Manifold_Temps_Return : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Температура обратки на коллекторах
    VI_Boiler_Flame_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Статус наличия пламени в котлах
    VI_Zone_Configs : ARRAY[1..8] OF ST_FloorHeating_Circuit_Config; // Конфигурации контуров
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action; // Действия от Rule Engine
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL; // Статусы модулей ввода-вывода
    VI_Scenario_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_SCENARIOS] OF ST_Scenario_Config; // Конфигурации сценариев
    VI_Manifold_End_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // Концевики клапанов
    VI_Valve_Test_Config : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Valve_Test_Config; // Конфигурация тестирования клапанов
END_VAR

VAR_OUTPUT
    VO_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL; // Выход: Положение клапанов смесителей (0-100%)
    VO_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // Выход: Управление насосами коллекторов
    VO_Zone_Valves : ARRAY[1..8] OF BOOL; // Выход: Управление клапанами контуров (Зоны 1-16)
    VO_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Физические команды в OpenTherm
    VO_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL; // Физические уставки в OpenTherm
    VO_Backup_Circulation_Pump : BOOL; // Резервный циркуляционный насос в режиме антизамерзания при газовой аварии
    VO_Electric_Heater_Enable : BOOL; // Сухой контакт электрического нагревателя антизамерзания
    VO_Freeze_Risk_Status : BOOL; // Признак риска замерзания при защёлкнутой газовой аварии
    VO_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status; // Сводный статус коллекторных узлов для HMI
    VO_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status; // Сводный статус котлов для HMI
END_VAR

VAR

    L_PID_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_PID_Controller; // ПИД-регуляторы для поддержания температуры подачи
    L_PID_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer; // Таймеры вызова ПИД-регуляторов
    L_Floor_Controllers : ARRAY[1..8] OF FB_FloorHeating_Controller; // Контроллеры зон теплого пола
    L_Last_Boiler_Rotation : UDINT; // Время последней ротации ведущего котла
    L_Lead_Boiler : BYTE := 1; // Номер ведущего котла (1 или 2)
    L_i : INT; // Индекс для циклов
    L_Zone_Config : ST_FloorHeating_Circuit_Config;
    L_j : INT; // Вспомогательный индекс
    L_Target_Supply_Temp : REAL; // Рассчитанная целевая температура подачи
    L_Demand_Power : REAL; // Суммарный запрос мощности от всех коллекторов
    L_Any_Zone_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // Флаги наличия запроса тепла по коллекторам
    L_Current_Temp : REAL; // Текущая температура для ПИД
    L_Sensor_Error : BOOL; // Ошибка обоих датчиков
    
    // Плавный переход сценария
    L_Prev_Scenario : E_SCENARIO_TYPE;
    L_Scenario_Adjust : REAL;
    L_Target_Scenario_Adjust : REAL;
    L_Transition_Temp : FB_Scenario_Transition_Controller;
    
    // ТЗ 2.5: Защита от перегрева стяжки
    L_Overheat_Timer : ARRAY[1..8] OF FB_System_Timer; // Таймеры задержки отключения при перегреве
    
    // ТЗ 2.6: Сервисная диагностика и паузы
    L_Pump_Run_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer; // Таймер непрерывной работы насоса (до 72ч)
    L_Pump_Pause_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_System_Timer; // Таймер обязательной паузы насоса (1ч)
    L_Pump_In_Pause : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // Флаг: Насос находится в режиме сервисной паузы
    
    // ТЗ 2.8: Учет ресурса оборудования
    L_Last_Scan_Time : UDINT; // Время предыдущего цикла для расчета наработки
    L_Scan_Time_Init : BOOL := FALSE;
    L_Lifespan_S : REAL := 50000.0 * 3600.0; // Расчетный ресурс котла (50,000 часов в секундах)
    L_Delta_MS : UDINT; // Разница времени
    L_Pump_Diag : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF FB_Device_Predictive_Diag; // Диагностика насосов
    L_Boiler_Life : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF FB_Lifetime_Predictor; // Предиктор ресурса котлов
    
    fbFloorTempValidator : ARRAY[1..8] OF FB_Analog_Validator;
    fbRoomTempValidator : ARRAY[1..16] OF FB_Analog_Validator;
    fbValveTestManager : FB_Valve_Test_Manager; // Менеджер тестирования клапанов
    fbBoilerCascade : FB_Boiler_Cascade_Manager; // Выделенный менеджер каскада котлов
    fbBoilerOpenTherm : FB_Boiler_OpenTherm_Interface; // Основной транспорт OpenTherm
    L_IO_Failsafe_Active : BOOL; // Флаг потери связи с модулями I/O
    L_Freeze_Mode_Active : BOOL; // Флаг антизамерзания по ТЗ
    L_Freeze_Target_Supply : REAL; // Уставка подачи в режиме антизамерзания
    L_Delta_T : REAL; // Разница температур подача/обратка
    L_Min_Supply_Temp : REAL; // Минимальная температура теплоносителя для антизамерзания
    L_Boiler_OT_Command_Valid : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Команда ушла через OT
    L_Boiler_Request_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL; // Внутренний request на котлы от логики каскада
    L_Boiler_Request_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL; // Внутренняя request-уставка котлов
    L_Policy_Normal : BOOL; // Policy: normal operation
    L_Policy_Safe_Stop : BOOL; // Policy: hard safe stop
    L_Policy_Degraded : BOOL; // Policy: limited conservative operation
    L_Policy_Freeze_Protection : BOOL; // Policy: freeze protection mode
    L_Any_Sensor_Error : BOOL;
    L_Any_Subsystem_Degraded : BOOL;
END_VAR



// ========================================
// Heating policy layer
// ========================================
L_Policy_Normal := (VI_System_Mode = E_System_Operating_Mode.MODE_NORMAL);
L_Policy_Safe_Stop := (VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
L_Policy_Degraded := (VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED);
L_Policy_Freeze_Protection := (VI_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);

// ========================================
// Heating freeze policy activation
// ========================================
IF L_Policy_Freeze_Protection THEN
    L_Freeze_Mode_Active := TRUE;
END_IF;

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

    // В аварийном I/O режиме напрямую формируем только legacy request-мirror.
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



// --- HEATING TARGET INJECTION ---
IF GVL_HEATING_REQUEST.G_Target_Temperature > 0.0 THEN
    L_Target_Supply_Temp := GVL_HEATING_REQUEST.G_Target_Temperature;
END_IF;

// 2. Расчет целевой температуры подачи теплоносителя (Погодозависимая автоматика ТЗ 2.3)
L_Target_Supply_Temp := 35.0; // Базовая уставка
IF VI_Config.Weather_Comp_Enabled AND VI_Outdoor_Temp < 15.0 THEN
    // Коррекция по уличному датчику с использованием коэффициента кривой
    L_Target_Supply_Temp := L_Target_Supply_Temp + (15.0 - VI_Outdoor_Temp) * VI_Config.Weather_Coef;
END_IF;
L_Target_Supply_Temp := LIMIT(20.0, L_Target_Supply_Temp, 45.0); // Ограничение диапазона для теплого пола

IF L_Policy_Degraded THEN
    IF L_Target_Supply_Temp > 35.0 THEN
        L_Target_Supply_Temp := 35.0;
    END_IF;
END_IF;

// Плавный переход уставки по сценарию
IF VI_Current_Scenario >= 1 AND VI_Current_Scenario <= GVL_CONSTANTS.C_MAX_SCENARIOS THEN
    L_Target_Scenario_Adjust := VI_Scenario_Configs[VI_Current_Scenario].floor_heating_adjust_celsius;
ELSE
    L_Target_Scenario_Adjust := 0.0;
END_IF;

IF VI_Current_Scenario <> L_Prev_Scenario THEN
    L_Transition_Temp(
        VI_System_Time := VI_System_Time_MS,
        VI_Start_Time := VI_System_Time_MS,
        VI_Duration := 300000, // 5 минут на плавное изменение температуры
        VI_Start_Value := L_Scenario_Adjust,
        VI_End_Value := L_Target_Scenario_Adjust
    );
    L_Prev_Scenario := VI_Current_Scenario;
ELSE
    L_Transition_Temp(
        VI_System_Time := VI_System_Time_MS,
        VI_Start_Time := L_Transition_Temp.VI_Start_Time,
        VI_Duration := L_Transition_Temp.VI_Duration,
        VI_Start_Value := L_Transition_Temp.VI_Start_Value,
        VI_End_Value := L_Target_Scenario_Adjust
    );
END_IF;
L_Scenario_Adjust := L_Transition_Temp.VO_Current_Value;

// ТЗ 2.4: Защита от замерзания по температуре пола < 7°C или наружной < -5°C
L_Freeze_Mode_Active := L_Policy_Freeze_Protection OR (VI_Outdoor_Temp < -5.0);
IF NOT L_Freeze_Mode_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF VI_Floor_Temps[L_i] < 7.0 THEN
            L_Freeze_Mode_Active := TRUE;
            EXIT;
        END_IF;
    END_FOR;
END_IF;

IF L_Freeze_Mode_Active THEN
    L_Freeze_Target_Supply := LIMIT(20.0, VI_Config.Freeze_Threshold + 2.0, 45.0);
    IF L_Target_Supply_Temp < L_Freeze_Target_Supply THEN
        L_Target_Supply_Temp := L_Freeze_Target_Supply;
    END_IF;
END_IF;

// 2. Индивидуальное управление зонами отопления (ТЗ 1.1, 2.5)
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    fbFloorTempValidator[L_i](
        VI_Value := VI_Floor_Temps[L_i],
        VI_Min_Valid := -40.0,
        VI_Max_Valid := 120.0,
        VI_Fallback_Mode := 0
    );
    
    L_Climate_Zone_ID := VI_Zone_Configs[L_i].zone;
    IF L_Climate_Zone_ID >= 1 AND L_Climate_Zone_ID <= 16 THEN
        fbRoomTempValidator[L_Climate_Zone_ID](
        VI_Value := VI_Room_Temps[L_Climate_Zone_ID],
        VI_Min_Valid := -40.0,
        VI_Max_Valid := 120.0,
        VI_Fallback_Mode := 0
        );
    END_IF;

    // Контроль перегрева стяжки (защита напольного покрытия)
    L_Overheat_Timer[L_i](IN := fbFloorTempValidator[L_i].VO_Value > VI_Config.Overheat_Threshold, PT := T#60s, VI_System_Time_MS := VI_System_Time_MS);
    
    // Выбор датчика температуры с автоматическим переключением при неисправности
    L_Current_Temp := 0.0;
    L_Sensor_Error := FALSE;
    
    IF VI_Zone_Configs[L_i].control_type = 1 OR VI_Zone_Configs[L_i].control_type = 2 THEN
        // Основной: по воздуху
        IF NOT fbRoomTempValidator[L_Climate_Zone_ID].VO_Error THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value;
        ELSIF NOT fbFloorTempValidator[L_i].VO_Error THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value; // Резервный: по полу
        ELSE
            L_Sensor_Error := TRUE;
        END_IF;
    ELSE
        // Основной: по полу
        IF NOT fbFloorTempValidator[L_i].VO_Error THEN
            L_Current_Temp := fbFloorTempValidator[L_i].VO_Value;
        ELSIF NOT fbRoomTempValidator[L_Climate_Zone_ID].VO_Error THEN
            L_Current_Temp := fbRoomTempValidator[L_Climate_Zone_ID].VO_Value; // Резервный: по воздуху
        ELSE
            L_Sensor_Error := TRUE;
        END_IF;
    END_IF;

    IF L_Sensor_Error THEN
        L_Any_Sensor_Error := TRUE;
        VO_Zone_Valves[L_i] := FALSE; // Безопасное состояние при ошибке обоих датчиков
    ELSE
        // ПИД-регулирование и ШИМ для каждой зоны
        // Применяем плавную корректировку уставки от сценария
        L_Zone_Config := VI_Zone_Configs[L_i];
        L_Zone_Config.design_temp := L_Zone_Config.design_temp + L_Scenario_Adjust;
        L_Floor_Controllers[L_i](
            VI_Current_Temp := L_Current_Temp,
            VI_Config := L_Zone_Config,
            VI_Tariff := VI_Tariff,
            VI_Current_Hour := VI_Current_Hour,
            VI_IsActivePLC := VI_IsActivePLC,
            VI_System_Time_MS := VI_System_Time_MS,
            VO_Valve_Bool => VO_Zone_Valves[L_i]
        );
    END_IF;
    
    // Принудительное закрытие клапана при перегреве пола (ТЗ 2.5)
    IF L_Overheat_Timer[L_i].Q THEN
        VO_Zone_Valves[L_i] := FALSE;
    END_IF;
    
    // Обработка действий от Rule Engine (ТЗ 13.0)
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_FLOOR_HEATING THEN
                VO_Zone_Valves[L_i] := (VI_Rule_Actions[L_j].Value > 0.5);
            END_IF;
        END_IF;
    END_FOR;
END_FOR;

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

// 4. Управление смесительными узлами коллекторов (ТЗ 2.6, 12.2)
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    // ПИД-регулирование трехходового клапана для поддержания стабильной температуры подачи
    // Вызываем ПИД регулятор каждую секунду
    L_PID_Timer[L_i](IN := TRUE, PT := T#1s, VI_System_Time_MS := VI_System_Time_MS);
    IF L_PID_Timer[L_i].Q THEN
        L_PID_Timer[L_i](IN := FALSE, PT := T#1s, VI_System_Time_MS := VI_System_Time_MS); // Сброс таймера
        L_PID_Timer[L_i](IN := TRUE, PT := T#1s, VI_System_Time_MS := VI_System_Time_MS); // Перезапуск
        
        L_PID_Valves[L_i](
            VI_SetPoint := L_Target_Supply_Temp,
            VI_ProcessValue := VI_Manifold_Temps_Supply[L_i],
            VI_Kp := 2.0, VI_Tn := 120.0, VI_Tv := 0.0,
            VI_Y_Min := 0.0, VI_Y_Max := 100.0, VI_Cycle_Time_S := 1.0,
            VO_Output => VO_Manifold_Valves[L_i]
        );
    END_IF;

    // ТЗ 2.6: Реализация обязательной паузы насоса (защита от закисания и перегрева при 72ч работе)
    L_Pump_Run_Timer[L_i](IN := VO_Manifold_Pumps[L_i] AND NOT L_Pump_In_Pause[L_i], PT := T#72h, VI_System_Time_MS := VI_System_Time_MS);
    IF L_Pump_Run_Timer[L_i].Q THEN L_Pump_In_Pause[L_i] := TRUE; END_IF;
    
    L_Pump_Pause_Timer[L_i](IN := L_Pump_In_Pause[L_i], PT := T#1h, VI_System_Time_MS := VI_System_Time_MS);
    IF L_Pump_Pause_Timer[L_i].Q THEN L_Pump_In_Pause[L_i] := FALSE; END_IF;

    // Включение насоса при наличии запроса от зон и отсутствии сервисной паузы
    // Приоритет ГВС: если есть запрос от ГВС, отключаем насосы отопления и закрываем клапаны
    IF VI_DHW_Heating_Demand THEN
        VO_Manifold_Pumps[L_i] := FALSE;
        VO_Manifold_Valves[L_i] := 0.0; // Принудительно закрываем смесительный клапан
    ELSE
        VO_Manifold_Pumps[L_i] := VI_IsActivePLC AND L_Any_Zone_Active[L_i] AND NOT L_Pump_In_Pause[L_i];
    END_IF;

    // Защита от замерзания системы (ТЗ 2.4)
        IF L_Freeze_Mode_Active THEN
            VO_Manifold_Pumps[L_i] := TRUE;
            IF VO_Manifold_Valves[L_i] < 35.0 THEN
                VO_Manifold_Valves[L_i] := 35.0;
            END_IF;
        END_IF;

        // Сбор диагностических данных для визуализации на HMI
    VO_Status[L_i].Pump_On := VO_Manifold_Pumps[L_i];
    VO_Status[L_i].Pump_Current := VI_Manifold_Currents[L_i];
    VO_Status[L_i].Pressure := VI_Manifold_Pressures[L_i];
    VO_Status[L_i].Temp_Supply := VI_Manifold_Temps_Supply[L_i];
    VO_Status[L_i].Temp_Return := VI_Manifold_Temps_Return[L_i];
    VO_Status[L_i].Valve_Pos := VO_Manifold_Valves[L_i];
    
    // Предиктивная диагностика насоса
    L_Pump_Diag[L_i](
        VI_Current_Value := VI_Manifold_Currents[L_i],
        VI_Nominal_Value := 0.55, // Номинальный ток насоса по ТЗ: середина диапазона 0.3..0.8 А
        VI_Is_Running := VO_Manifold_Pumps[L_i],
        VI_Reset_Stats := FALSE,
        VI_System_Time_MS := VI_System_Time_MS,
        VIO_Health_Data := VO_Status[L_i].Health
    );
    
    // Автоматический контроль рабочих параметров (ток / давление / ΔT)
        IF VO_Manifold_Pumps[L_i] THEN
            L_Delta_T := VI_Manifold_Temps_Supply[L_i] - VI_Manifold_Temps_Return[L_i];

            // Контроль тока насоса:
            // Приоритет ошибок:
            // 1. Насос/ток
            // 2. Давление
            // 3. ΔT
            VO_Status[L_i].Error := FALSE;
            VO_Status[L_i].Error_ID := 0;

            IF VI_Manifold_Currents[L_i] <= 0.01 THEN
                VO_Status[L_i].Error := TRUE;
                VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PUMP_NO_CURRENT);
            ELSIF VI_Manifold_Currents[L_i] < 0.3 THEN
                VO_Status[L_i].Error := TRUE;
                VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PUMP_UNDERCURRENT);
            ELSIF VI_Manifold_Currents[L_i] > 1.5 THEN
                VO_Status[L_i].Error := TRUE;
                VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PUMP_OVERCURRENT);
            END_IF;

            // Проверка давления в системе (норма 1.5 - 2.5 бар)
            IF (NOT VO_Status[L_i].Error) AND (VI_Manifold_Pressures[L_i] < 1.5 OR VI_Manifold_Pressures[L_i] > 2.5) THEN
                VO_Status[L_i].Error := TRUE;
                VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_PRESSURE_OUT_OF_RANGE);
            END_IF;

            // Проверка эффективности теплообмена (ΔT 5..10°C норма)
            IF NOT VO_Status[L_i].Error THEN
                IF L_Delta_T < 5.0 THEN
                    VO_Status[L_i].Error := TRUE;
                    VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_DELTA_T_LOW);
                ELSIF L_Delta_T > 10.0 THEN
                    VO_Status[L_i].Error := TRUE;
                    VO_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_DELTA_T_HIGH);
                END_IF;
            END_IF;
        END_IF;

        // ТЗ 12.2: Еженедельное тестирование запорной арматуры (предотвращение закисания)
    // Выполняется менеджером fbValveTestManager
END_FOR;

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

// 5. Управление каскадом котлов (ТЗ 2.8, OpenTherm-only, без legacy mirror)
L_Demand_Power := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    IF VO_Manifold_Pumps[L_i] THEN
        L_Demand_Power := L_Demand_Power + VO_Manifold_Valves[L_i];
    END_IF;
END_FOR;

// В режиме антизамерзания обеспечиваем минимальный запрос тепла
IF L_Freeze_Mode_Active AND L_Demand_Power < 20.0 THEN
    L_Demand_Power := 20.0;
END_IF;

IF L_Policy_Degraded THEN
    IF L_Demand_Power > 60.0 THEN
        L_Demand_Power := 60.0;
    END_IF;
END_IF;

fbBoilerCascade(
    VI_Enable := VI_IsActivePLC AND ((L_Demand_Power > GVL_CONSTANTS.C_BOILER_CASCADE_MIN_DEMAND) OR L_Freeze_Mode_Active),
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Boiler_Stop := FALSE,
    VI_DHW_Heating_Demand := VI_DHW_Heating_Demand,
    VI_DHW_Target_Temp := VI_DHW_Target_Temp,
    VI_Target_Supply_Temp := L_Target_Supply_Temp,
    VI_Demand_Power := L_Demand_Power,
    VI_Boiler_Flame_Status := VI_Boiler_Flame_Status,
    VI_Boiler_Error_Status := VI_Boiler_Error_Status,
    VI_Boiler_OT_Online := VI_Boiler_OT_Online,
    VI_Boiler_Modulation := VI_Boiler_Modulation,
    VO_Boiler_Enable => L_Boiler_Request_Enable,
    VO_Boiler_Setpoint => L_Boiler_Request_Setpoint,
    VO_Lead_Boiler => L_Lead_Boiler
);



// ========================================
// OT availability enforcement (no fallback)
// ========================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    IF NOT VI_Boiler_OT_Online[L_i] OR VI_Boiler_Error_Status[L_i] THEN
        L_Boiler_Request_Enable[L_i] := FALSE;
        L_Boiler_Request_Setpoint[L_i] := 0.0;
    END_IF;
END_FOR;

fbBoilerOpenTherm(
    VI_Enable := L_Boiler_Request_Enable,
    VI_Setpoint := L_Boiler_Request_Setpoint,
    VI_OT_Online := VI_Boiler_OT_Online,
    VI_OT_Error := VI_Boiler_Error_Status,
    VO_OT_Enable => VO_Boiler_OT_Enable,
    VO_OT_Setpoint => VO_Boiler_OT_Setpoint,
    VO_OT_Command_Valid => L_Boiler_OT_Command_Valid
);


// ========================================
// Boiler status normalization
// ========================================
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    // Базовый сброс диагностических флагов котла
    VO_Boiler_Status[L_i].Active := L_Boiler_Request_Enable[L_i];
    VO_Boiler_Status[L_i].Warning := FALSE;
    VO_Boiler_Status[L_i].Error := FALSE;

    // Приоритет причин:
    // 1. Нет канала OpenTherm
    // 2. Котёл вернул ошибку
    // 3. Есть запрос, но нет пламени
    IF NOT VI_Boiler_OT_Online[L_i] THEN
        VO_Boiler_Status[L_i].Error := TRUE;
        VO_Boiler_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_BOILER_OFFLINE);
        L_Any_Subsystem_Degraded := TRUE;
    ELSIF VI_Boiler_Error_Status[L_i] THEN
        VO_Boiler_Status[L_i].Error := TRUE;
        VO_Boiler_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_BOILER_GENERAL_FAULT);
        L_Any_Subsystem_Degraded := TRUE;
    ELSIF L_Boiler_Request_Enable[L_i] AND NOT VI_Boiler_Flame_Status[L_i] THEN
        VO_Boiler_Status[L_i].Warning := TRUE;
        VO_Boiler_Status[L_i].Error_ID := TO_WORD(GVL_CONFIG.ERR_BOILER_NO_FLAME);
        L_Any_Subsystem_Degraded := TRUE;
    ELSE
        VO_Boiler_Status[L_i].Error_ID := 0;
    END_IF;
END_FOR;

// Расчет наработки и остаточного ресурса котлов (ТЗ 2.8)
IF NOT L_Scan_Time_Init THEN
    L_Last_Scan_Time := VI_System_Time_MS;
    L_Scan_Time_Init := TRUE;
END_IF;

L_Delta_MS := (SEL(VI_System_Time_MS >= L_Last_Scan_Time, VI_System_Time_MS - L_Last_Scan_Time, (4294967295 - L_Last_Scan_Time) + VI_System_Time_MS + 1));
IF L_Delta_MS > 1000 THEN
    L_Delta_MS := 1000; // Ограничение дельты для предотвращения скачков после перезагрузки
END_IF;

L_Last_Scan_Time := VI_System_Time_MS;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    VO_Boiler_Status[L_i].Work_Seconds := GVL_Retain.G_Boiler_Work_Seconds[L_i];
    
    IF VI_Boiler_Flame_Status[L_i] THEN
        GVL_Retain.G_Boiler_Accumulated_MS[L_i] := GVL_Retain.G_Boiler_Accumulated_MS[L_i] + L_Delta_MS;
        IF GVL_Retain.G_Boiler_Accumulated_MS[L_i] >= GVL_CONSTANTS.C_MS_IN_SECOND THEN
            GVL_Retain.G_Boiler_Work_Seconds[L_i] := GVL_Retain.G_Boiler_Work_Seconds[L_i] + (GVL_Retain.G_Boiler_Accumulated_MS[L_i] / 1000);
            GVL_Retain.G_Boiler_Accumulated_MS[L_i] := GVL_Retain.G_Boiler_Accumulated_MS[L_i] MOD 1000;
            
            // Защита от переполнения (сброс при достижении ~136 лет)
            IF GVL_Retain.G_Boiler_Work_Seconds[L_i] > 4000000000 THEN
                GVL_Retain.G_Boiler_Work_Seconds[L_i] := 0;
            END_IF;
            
            VO_Boiler_Status[L_i].Work_Seconds := GVL_Retain.G_Boiler_Work_Seconds[L_i];
        END_IF;
    END_IF;
    
    VO_Boiler_Status[L_i].Work_Hours := TO_REAL(VO_Boiler_Status[L_i].Work_Seconds) / 3600.0;
    
    L_Boiler_Life[L_i](
        VI_Runtime_Hours := TO_UDINT(VO_Boiler_Status[L_i].Work_Hours),
        VI_Start_Count := 0, // Не считаем пуски для котлов в этой версии
        VI_Nominal_Life := 50000 // 50,000 часов
    );
    VO_Boiler_Status[L_i].Resource_Percent := TO_REAL(L_Boiler_Life[L_i].VO_Remaining_Percent);
    VO_Boiler_Status[L_i].Running := VI_Boiler_Flame_Status[L_i];
END_FOR;
GVL_STATE.G_Heating_Subsystem_Degraded := L_Any_Subsystem_Degraded;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_System_Manager <<<
