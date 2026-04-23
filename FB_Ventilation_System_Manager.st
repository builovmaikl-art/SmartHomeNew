FUNCTION_BLOCK FB_Ventilation_System_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_IsActivePLC : BOOL; // Флаг: Данный ПЛК является ведущим
    VI_Outdoor_Temp : REAL; // Уличная температура воздуха (°C)
    VI_Current_Scenario : E_SCENARIO_TYPE; // Текущий глобальный сценарий
    VI_System_Mode : E_System_Operating_Mode; // Агрегированный режим работы системы
    VI_Config : ST_Ventilation_Global_Config; // Конфигурация системы вентиляции
    VI_Fire_Alarm : BOOL; // Сигнал пожарной тревоги
    VI_Gas_Alarm : BOOL; // Сигнал газовой тревоги
    VI_PV3_Boost_Req : BOOL; // Запрос форсирования ПВ-3 от газоанализатора (ТЗ 5.1)
    VI_Supply_100_Req : BOOL; // Запрос 100% притока (ТЗ 6.4)
    VI_Exhaust_100_Req : BOOL; // Запрос 100% вытяжки (ТЗ 6.4)
    VI_Supply_80_Req : BOOL; // Запрос 80% притока (ТЗ 5.4)
    VI_Vent_Stop : BOOL; // Запрос на остановку вентиляции (ТЗ 5.3)
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL; // Статусы модулей ввода-вывода (только чтение)
END_VAR
VAR_IN_OUT
    VI_Supply_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS] OF REAL; // Температура приточного воздуха после калорифера
    VI_Room_Temps : ARRAY[1..16] OF REAL; // Температура в помещениях (°C)
    VI_Room_Humidities : ARRAY[1..16] OF REAL; // Влажность в помещениях (%)
    VI_Room_CO2 : ARRAY[1..16] OF REAL; // Уровень CO2 в помещениях (ppm)
    VI_Wet_Zone_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_WET_ZONES] OF BOOL; // Сигналы включения света в санузлах (ТЗ 4.0)
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action; // Действия от Rule Engine
END_VAR
VAR_OUTPUT
    VO_Supply_Fans : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_FANS] OF BYTE; // Выход: Управление приточными вентиляторами (0-100%)
    VO_Exhaust_Fans : ARRAY[1..GVL_CONSTANTS.C_MAX_EXHAUST_FANS] OF BYTE; // Выход: Управление вытяжными вентиляторами (0-100%)
    VO_Heater_Power : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL; // Выход: Мощность калориферов (0-100%)
    VO_Status_Msg : STRING(200); // Строковое сообщение о статусе
    VO_Ventilation_IO_Fault : BOOL; // Выход: диагностика потери связи с модулями ввода-вывода
    VO_Ventilation_Subsystem_Degraded : BOOL; // Выход: признак degraded-состояния подсистемы вентиляции
END_VAR
VAR
    L_Policy_Normal : BOOL;
    L_Policy_Safe_Stop : BOOL;
    L_Policy_Degraded : BOOL;
    L_Policy_Freeze_Protection : BOOL;
    L_i : INT;
    L_j : INT;
    L_Max_CO2 : REAL;
    L_Max_Hum : REAL;
    L_Base_Speed : BYTE;
    L_Target_Temp : REAL;
    L_PID_Heaters : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF FB_PID_Controller;
    L_Wet_Zone_Timers : ARRAY[1..GVL_CONSTANTS.C_MAX_WET_ZONES] OF FB_System_Timer_TOF; // Таймеры выбега для вытяжек санузлов
END_VAR

// ========================================
// Ventilation policy layer
// ========================================
VO_Ventilation_IO_Fault := FALSE;
VO_Ventilation_Subsystem_Degraded := FALSE;
L_Policy_Normal := (VI_System_Mode = E_System_Operating_Mode.MODE_NORMAL);
L_Policy_Safe_Stop := (VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
L_Policy_Degraded := (VI_System_Mode = E_System_Operating_Mode.MODE_DEGRADED);
L_Policy_Freeze_Protection := (VI_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);

IF NOT VI_IsActivePLC THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        VO_Supply_Fans[L_i] := 0;
        IF L_i <= GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS THEN
            VO_Heater_Power[L_i] := 0.0;
        END_IF;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        VO_Exhaust_Fans[L_i] := 0;
    END_FOR;
    VO_Status_Msg := 'ВЕНТИЛЯЦИЯ: РЕЗЕРВНЫЙ ПЛК';
    RETURN;
END_IF;

// Проверка связи с модулями ввода-вывода
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    IF NOT VI_IO_Modules_Online[L_i] THEN
        VO_Ventilation_IO_Fault := TRUE;
        // Переход в безопасное состояние при потере связи (отключение вентиляции)
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
            VO_Supply_Fans[L_j] := 0;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
            VO_Exhaust_Fans[L_j] := 0;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
            VO_Heater_Power[L_j] := 0.0;
        END_FOR;
        VO_Status_Msg := 'ОШИБКА: Потеря связи с модулями ввода-вывода';
        RETURN;
    END_IF;
END_FOR;

// =========================
// SYSTEM MODE OVERRIDE
// =========================
// VENT_POLICY_ROUTING_PHASE3_V2
IF L_Policy_Safe_Stop THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        VO_Supply_Fans[L_i] := 0;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        VO_Exhaust_Fans[L_i] := 0;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Heater_Power[L_i] := 0.0;
    END_FOR;
    VO_Status_Msg := 'ВЕНТИЛЯЦИЯ: ОСТАНОВЛЕНА POLICY SAFE_STOP';
    RETURN;
END_IF;

IF L_Policy_Degraded THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        VO_Supply_Fans[L_i] := 0;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Heater_Power[L_i] := 0.0;
    END_FOR;
    VO_Ventilation_Subsystem_Degraded := TRUE;
    VO_Status_Msg := 'ВЕНТИЛЯЦИЯ: DEGRADED POLICY';
END_IF;

IF L_Policy_Freeze_Protection THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        VO_Supply_Fans[L_i] := 0;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        VO_Exhaust_Fans[L_i] := 0;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
        VO_Heater_Power[L_i] := 0.0;
    END_FOR;
    VO_Status_Msg := 'ВЕНТИЛЯЦИЯ: FREEZE_PROTECTION POLICY (stop)';
    RETURN;
END_IF;

// MODE_FREEZE_PROTECTION пока оставляем на текущей штатной логике

// 1. Определение базовой скорости и целевой температуры по сценарию (ТЗ 7.1)
CASE VI_Current_Scenario OF
    E_SCENARIO_TYPE.SCENARIO_AWAY:
        L_Base_Speed := VI_Config.Scenario_Modes[3].Base_Fan_Speed;
        L_Target_Temp := VI_Config.Scenario_Modes[3].Target_Temp;
    E_SCENARIO_TYPE.SCENARIO_SLEEP:
        L_Base_Speed := VI_Config.Scenario_Modes[2].Base_Fan_Speed;
        L_Target_Temp := VI_Config.Scenario_Modes[2].Target_Temp;
    ELSE // PRESENCE, MORNING, EVENING
        L_Base_Speed := VI_Config.Scenario_Modes[1].Base_Fan_Speed;
        L_Target_Temp := VI_Config.Scenario_Modes[1].Target_Temp;
END_CASE;

// 2. Логика управления приточными установками (П-1, П-2, П-3)
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    // ПИД-регулирование мощности электрического калорифера
    IF L_i <= GVL_CONSTANTS.C_MAX_SUPPLY_TEMPS THEN
        L_PID_Heaters[L_i](
            VI_SetPoint := L_Target_Temp,
            VI_ProcessValue := VI_Supply_Temps[L_i], // Используем датчик температуры после калорифера
            VI_Kp := 4.0, VI_Tn := 120.0, VI_Tv := 0.0,
            VI_Y_Min := 0.0, VI_Y_Max := 100.0, VI_Cycle_Time_S := 1.0,
            VO_Output => VO_Heater_Power[L_i]
        );
    END_IF;

    // Определение скорости приточного вентилятора
    VO_Supply_Fans[L_i] := L_Base_Speed;
    
    // Обработка действий от Rule Engine
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_VENTILATION THEN
                VO_Supply_Fans[L_i] := REAL_TO_BYTE(VI_Rule_Actions[L_j].Value);
            END_IF;
        END_IF;
    END_FOR;
    
    // Requests are operational requests and must not be reported as subsystem degradation.
END_FOR;

// 3. Логика управления вытяжными установками (В-1 .. В-5)
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    VO_Exhaust_Fans[L_i] := L_Base_Speed;
    
    // ТЗ 4.0: Логика вытяжки в санузлах
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_WET_ZONES DO
        IF VI_Config.wet_zone_to_exhaust_map[L_j] = L_i THEN
            // Включение по свету, выключение с задержкой 5 минут (используем TOF)
            L_Wet_Zone_Timers[L_j](IN := VI_Wet_Zone_Active[L_j], PT := T#5m, VI_System_Time_MS := VI_System_Time_MS);
            IF VI_Wet_Zone_Active[L_j] THEN
                VO_Exhaust_Fans[L_i] := 80; // Повышенная скорость при присутствии
            ELSIF L_Wet_Zone_Timers[L_j].Q THEN
                VO_Exhaust_Fans[L_i] := 50; // Скорость выбега (пока таймер TOF активен)
            END_IF;
        END_IF;
    END_FOR;

    // Requests are operational requests and must not be reported as subsystem degradation.
END_FOR;








// ========================================
// VENT_FINAL_CLAMP
// ========================================
IF L_Policy_Degraded THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        VO_Exhaust_Fans[L_i] := MIN(VO_Exhaust_Fans[L_i], VI_Config.Degraded_Exhaust_Limit);
    END_FOR;
END_IF;

// 4. Формирование статусного сообщения
IF L_Policy_Safe_Stop THEN
    VO_Status_Msg := 'ВЕНТИЛЯЦИЯ: ОСТАНОВЛЕНА POLICY SAFE_STOP';
ELSIF L_Policy_Freeze_Protection THEN
    VO_Status_Msg := 'ВЕНТИЛЯЦИЯ: FREEZE_PROTECTION POLICY (stop)';
ELSIF L_Policy_Degraded THEN
    VO_Status_Msg := 'ВЕНТИЛЯЦИЯ: DEGRADED POLICY';
ELSE
    VO_Status_Msg := 'Вентиляция работает в штатном режиме';
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Ventilation_System_Manager <<<
