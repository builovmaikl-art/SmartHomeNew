FUNCTION_BLOCK FB_Lighting_Blinds_Manager
// Менеджер управления освещением и шторами/жалюзи.
// Обеспечивает работу по сценариями, датчикам движения, физическим выключателям и правилам.
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время в миллисекундах
    VI_IsActivePLC : BOOL; // Флаг активности ПЛК (TRUE = ведущий)
    VI_Current_Scenario : E_SCENARIO_TYPE; // Текущий глобальный сценарий (Утро, Вечер, Сон, Никого нет)
    VI_Away_Level : BYTE; // Уровень режима "Никого нет" (1-Короткий, 2-Средний, 3-Длительный)
    VI_Simulation_Active : BOOL; // Флаг активности симуляции присутствия
    VI_Is_Night : BOOL; // Флаг ночного времени (по астрономическому таймеру)
    VI_System_Mode : E_System_Operating_Mode; // Агрегированный режим работы системы
END_VAR
VAR_IN_OUT
    VI_Manual_Light_Override : ARRAY[1..32] OF BYTE; // Ручное переопределение яркости (0-100%)
    VI_Manual_Blinds_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE; // Ручное переопределение позиции штор (0-100%)
    VI_Simulation_Lights : ARRAY[1..32] OF BOOL; // Состояния света от симулятора
    VI_Physical_Switches : ARRAY[1..32] OF BOOL; // Состояния физических выключателей
    VI_Motion_Sensors : ARRAY[1..32] OF BOOL; // Состояния датчиков движения
    VI_Rule_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action; // Действия от Rule Engine
    VI_IO_Modules_Online : ARRAY[1..GVL_CONSTANTS.C_MAX_MODULES] OF BOOL; // Статусы модулей ввода-вывода
    VI_Wet_Zone_Map : ARRAY[1..32] OF BOOL; // Карта мокрых зон
    VI_Scenario_Configs : ARRAY[1..GVL_CONSTANTS.C_MAX_SCENARIOS] OF ST_Scenario_Config; // Конфигурации сценариев
END_VAR
VAR_OUTPUT
    VO_Lighting_Levels : ARRAY[1..32] OF BYTE; // Выходные уровни освещения (0-100%)
    VO_Blinds_Positions : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE; // Выходные позиции штор (0-100%)
    VO_Wet_Zone_Light_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_WET_ZONES] OF BOOL; // Флаги включенного света в мокрых зонах (для вентиляции)
END_VAR
VAR
    // Blinds V2 shadow (phase2)
    L_Blinds_V2_Command_Shadow : ST_Blinds_Command_V2;
    L_Blinds_V2_State_Shadow : ST_Blinds_State_V2;
    L_Blinds_V2_Shadow_Diff_Found : BOOL;
    L_Blinds_V2_Switch_Enabled : BOOL;
    L_Blinds_V2_Path_Ready : BOOL;
    L_Blinds_Using_Legacy_Fallback : BOOL;
    // Lighting V2 shadow (phase2)
    L_Lighting_V2_Command_Shadow : ST_Lighting_Command_V2;
    L_Lighting_V2_State_Shadow : ST_Lighting_State_V2;
    L_Lighting_V2_Shadow_Diff_Found : BOOL;
    L_Lighting_V2_Switch_Enabled : BOOL;
    L_Lighting_V2_Path_Ready : BOOL;
    L_Lighting_Using_Legacy_Fallback : BOOL;
    L_i : INT;
    L_j : INT;
    L_Base_Light : BYTE;
    L_Base_Blinds : BYTE;
    L_Target_Base_Light : BYTE;
    L_Target_Base_Blinds : BYTE;
    L_Prev_Scenario : E_SCENARIO_TYPE;
    L_Transition_Light : FB_Scenario_Transition_Controller;
    L_Transition_Blinds : FB_Scenario_Transition_Controller;
    L_Light_States : ARRAY[1..32] OF BOOL;
    L_Prev_Switches : ARRAY[1..32] OF BOOL;
    L_Prev_Motion_Q : ARRAY[1..32] OF BOOL;
    L_Manual_Override : ARRAY[1..32] OF BOOL; // Флаг ручного переопределения (выключателем)
    L_Motion_Timers : ARRAY[1..32] OF FB_System_Timer_TOF;
    L_Rule_Light_Active : BOOL;
    L_Rule_Light_Val : BYTE;
    L_Rule_Blinds_Active : BOOL;
    L_Rule_Blinds_Val : BYTE;
    L_Wet_Zone_Idx : INT;
    L_Effective_Scenario : E_SCENARIO_TYPE;
    L_Effective_Simulation_Active : BOOL;
END_VAR

IF NOT VI_IsActivePLC THEN RETURN; END_IF;

L_Lighting_V2_Shadow_Diff_Found := FALSE;
L_Blinds_V2_Shadow_Diff_Found := FALSE;
L_Blinds_V2_Switch_Enabled := TRUE;
L_Blinds_V2_Path_Ready := FALSE;
L_Blinds_Using_Legacy_Fallback := TRUE;
L_Lighting_V2_Switch_Enabled := TRUE;
L_Lighting_V2_Path_Ready := FALSE;
L_Lighting_Using_Legacy_Fallback := TRUE;

GVL_STATE.G_Lighting_IO_Fault := FALSE;
GVL_STATE.G_Lighting_Subsystem_Degraded := FALSE;

L_Effective_Scenario := VI_Current_Scenario;
L_Effective_Simulation_Active := VI_Simulation_Active;

CASE VI_System_Mode OF
    E_System_Operating_Mode.MODE_SAFE_STOP:
        FOR L_j := 1 TO 32 DO
            VO_Lighting_Levels[L_j] := 0;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
            VO_Blinds_Positions[L_j] := 100;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_WET_ZONES DO
            VO_Wet_Zone_Light_Active[L_j] := FALSE;
        END_FOR;
        RETURN;
    E_System_Operating_Mode.MODE_FREEZE_PROTECTION:
        L_Effective_Scenario := E_SCENARIO_TYPE.SCENARIO_NONE;
        L_Effective_Simulation_Active := FALSE;
    E_System_Operating_Mode.MODE_DEGRADED:
        L_Effective_Simulation_Active := FALSE;
END_CASE;

// Инициализация индекса мокрых зон
L_Wet_Zone_Idx := 1;
// Сброс массива мокрых зон
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WET_ZONES DO
    VO_Wet_Zone_Light_Active[L_i] := FALSE;
END_FOR;

// Проверка связи с модулями ввода-вывода
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MODULES DO
    IF NOT VI_IO_Modules_Online[L_i] THEN
        GVL_STATE.G_Lighting_IO_Fault := TRUE;
GVL_STATE.G_Lighting_Subsystem_Degraded := TRUE;
        // Переход в безопасное состояние при потере связи (свет выкл, шторы открыты для эвакуации)
        FOR L_j := 1 TO 32 DO
            VO_Lighting_Levels[L_j] := 0;
        END_FOR;
        FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
            VO_Blinds_Positions[L_j] := 100;
        END_FOR;
        RETURN;
    END_IF;
END_FOR;

// 1. Определение целевых уровней по сценарию (ТЗ 7.1)
IF L_Effective_Scenario >= 1 AND L_Effective_Scenario <= GVL_CONSTANTS.C_MAX_SCENARIOS THEN
    L_Target_Base_Light := VI_Scenario_Configs[L_Effective_Scenario].lighting_level_base;
    L_Target_Base_Blinds := VI_Scenario_Configs[L_Effective_Scenario].blinds_position_percent;
ELSE
    L_Target_Base_Light := 100;
    L_Target_Base_Blinds := 100;
END_IF;

// Корректировка по астрономическому таймеру
IF VI_Is_Night AND L_Effective_Scenario <> E_SCENARIO_TYPE.SCENARIO_AWAY AND L_Effective_Scenario <> E_SCENARIO_TYPE.SCENARIO_SLEEP THEN
    L_Target_Base_Blinds := 0; // Закрывать шторы ночью
END_IF;

// Плавный переход при смене сценария
IF L_Effective_Scenario <> L_Prev_Scenario THEN
    L_Transition_Light(
        VI_System_Time := VI_System_Time_MS,
        VI_Start_Time := VI_System_Time_MS,
        VI_Duration := 5000, // 5 секунд на плавное изменение света
        VI_Start_Value := TO_REAL(L_Base_Light),
        VI_End_Value := TO_REAL(L_Target_Base_Light)
    );
    L_Transition_Blinds(
        VI_System_Time := VI_System_Time_MS,
        VI_Start_Time := VI_System_Time_MS,
        VI_Duration := 10000, // 10 секунд на плавное изменение штор
        VI_Start_Value := TO_REAL(L_Base_Blinds),
        VI_End_Value := TO_REAL(L_Target_Base_Blinds)
    );
    L_Prev_Scenario := L_Effective_Scenario;
ELSE
    L_Transition_Light(
        VI_System_Time := VI_System_Time_MS,
        VI_Start_Time := L_Transition_Light.VI_Start_Time,
        VI_Duration := L_Transition_Light.VI_Duration,
        VI_Start_Value := L_Transition_Light.VI_Start_Value,
        VI_End_Value := TO_REAL(L_Target_Base_Light)
    );
    L_Transition_Blinds(
        VI_System_Time := VI_System_Time_MS,
        VI_Start_Time := L_Transition_Blinds.VI_Start_Time,
        VI_Duration := L_Transition_Blinds.VI_Duration,
        VI_Start_Value := L_Transition_Blinds.VI_Start_Value,
        VI_End_Value := TO_REAL(L_Target_Base_Blinds)
    );
END_IF;

L_Base_Light := TO_BYTE(L_Transition_Light.VO_Current_Value);
L_Base_Blinds := TO_BYTE(L_Transition_Blinds.VO_Current_Value);

// 2. Управление освещением
FOR L_i := 1 TO 32 DO
    L_Rule_Light_Active := FALSE;
    L_Rule_Light_Val := 0;
    
    // Проверка правил
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_LIGHTING_BASE THEN
                L_Rule_Light_Active := TRUE;
                L_Rule_Light_Val := REAL_TO_BYTE(VI_Rule_Actions[L_j].Value);
                L_Light_States[L_i] := (L_Rule_Light_Val > 0);
            ELSIF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_TOGGLE_LIGHTING AND VI_Rule_Actions[L_j].Triggered THEN
                L_Light_States[L_i] := NOT L_Light_States[L_i];
            END_IF;
        END_IF;
    END_FOR;

    // Приоритет 1: Физические выключатели (ТЗ 1.0)
    IF VI_Physical_Switches[L_i] AND NOT L_Prev_Switches[L_i] THEN
        L_Light_States[L_i] := NOT L_Light_States[L_i];
        L_Manual_Override[L_i] := TRUE; // Запоминаем ручное переопределение
    END_IF;
    L_Prev_Switches[L_i] := VI_Physical_Switches[L_i];

    // Приоритет 2: Датчики движения (ТЗ 2.0)
    // Защита от дребезга и удержание сигнала движения с помощью TOF
    L_Motion_Timers[L_i](IN := VI_Motion_Sensors[L_i], PT := T#5m, VI_System_Time_MS := VI_System_Time_MS);
    
    // Сброс ручного переопределения, когда комната становится пустой (задний фронт таймера движения)
    IF L_Prev_Motion_Q[L_i] AND NOT L_Motion_Timers[L_i].Q THEN
        L_Manual_Override[L_i] := FALSE;
    END_IF;
    L_Prev_Motion_Q[L_i] := L_Motion_Timers[L_i].Q;

    IF L_Motion_Timers[L_i].Q THEN
        IF NOT L_Manual_Override[L_i] THEN
            L_Light_States[L_i] := TRUE;
        END_IF;
    ELSE
        // Выключаем свет только если нет ручного переопределения
        IF NOT L_Manual_Override[L_i] THEN
            L_Light_States[L_i] := FALSE;
        END_IF;
    END_IF;

    // Приоритет 3: Симуляция (только в режиме Away)
    IF L_Effective_Scenario = E_SCENARIO_TYPE.SCENARIO_AWAY AND L_Effective_Simulation_Active THEN
        L_Light_States[L_i] := VI_Simulation_Lights[L_i];
    END_IF;

    // Приоритет 4: Ручное управление и правила
    IF VI_Manual_Light_Override[L_i] > 0 THEN
        VO_Lighting_Levels[L_i] := VI_Manual_Light_Override[L_i];
    ELSIF L_Rule_Light_Active THEN
        VO_Lighting_Levels[L_i] := L_Rule_Light_Val;
    ELSE
        VO_Lighting_Levels[L_i] := SEL(L_Light_States[L_i], 0, L_Base_Light);
    END_IF;
    
    // 5. Мокрые зоны
    IF VI_Wet_Zone_Map[L_i] AND L_Wet_Zone_Idx <= GVL_CONSTANTS.C_MAX_WET_ZONES THEN
        VO_Wet_Zone_Light_Active[L_Wet_Zone_Idx] := (VO_Lighting_Levels[L_i] > 10);
        L_Wet_Zone_Idx := L_Wet_Zone_Idx + 1;
    END_IF;
END_FOR;

// 3. Управление шторами
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    L_Rule_Blinds_Active := FALSE;
    L_Rule_Blinds_Val := 0;
    
    // Проверка правил
    FOR L_j := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
        IF VI_Rule_Actions[L_j].Active AND VI_Rule_Actions[L_j].Target_ID = L_i THEN
            IF VI_Rule_Actions[L_j].Action_Type = E_Rule_Action_Type.ACTION_SET_BLINDS THEN
                L_Rule_Blinds_Active := TRUE;
                L_Rule_Blinds_Val := REAL_TO_BYTE(VI_Rule_Actions[L_j].Value);
            END_IF;
        END_IF;
    END_FOR;

    // Приоритет 1: Ручное управление
    IF VI_Manual_Blinds_Override[L_i] > 0 THEN
        VO_Blinds_Positions[L_i] := VI_Manual_Blinds_Override[L_i];
    // Приоритет 2: Правила
    ELSIF L_Rule_Blinds_Active THEN
        VO_Blinds_Positions[L_i] := L_Rule_Blinds_Val;
    // Приоритет 3: Сценарий
    ELSE
        VO_Blinds_Positions[L_i] := L_Base_Blinds;
    END_IF;
END_FOR;

// ========================================
// Lighting V2 shadow execution (phase2)
// Inlined from FB_Lighting_V2_Staging
// ========================================
L_Lighting_V2_Command_Shadow.Brightness_Setpoint := BYTE_TO_REAL(VO_Lighting_Levels[1]);
L_Lighting_V2_State_Shadow.Brightness_Actual := BYTE_TO_REAL(VO_Lighting_Levels[1]);
L_Lighting_V2_State_Shadow.Motion_Active := VI_Motion_Sensors[1];

// ========================================
// Lighting V2 shadow validation
// ========================================
IF ABS(BYTE_TO_REAL(VO_Lighting_Levels[1]) - L_Lighting_V2_Command_Shadow.Brightness_Setpoint) > 0.1 THEN
    L_Lighting_V2_Shadow_Diff_Found := TRUE;
END_IF;
IF ABS(BYTE_TO_REAL(VO_Lighting_Levels[1]) - L_Lighting_V2_State_Shadow.Brightness_Actual) > 0.1 THEN
    L_Lighting_V2_Shadow_Diff_Found := TRUE;
END_IF;
IF VI_Motion_Sensors[1] <> L_Lighting_V2_State_Shadow.Motion_Active THEN
    L_Lighting_V2_Shadow_Diff_Found := TRUE;
END_IF;

// Guarded Lighting V2 enable
IF L_Lighting_V2_Switch_Enabled THEN
    IF NOT L_Lighting_V2_Shadow_Diff_Found THEN
        L_Lighting_V2_Path_Ready := TRUE;
        L_Lighting_Using_Legacy_Fallback := FALSE;
    ELSE
        L_Lighting_V2_Path_Ready := FALSE;
        L_Lighting_Using_Legacy_Fallback := TRUE;
    END_IF;
ELSE
    L_Lighting_V2_Path_Ready := FALSE;
    L_Lighting_Using_Legacy_Fallback := TRUE;
END_IF;



// ========================================
// Blinds V2 shadow execution (phase2)
// Inlined from FB_Blinds_V2_Staging
// ========================================
L_Blinds_V2_Command_Shadow.Position_Setpoint := VO_Blinds_Positions[1];
L_Blinds_V2_State_Shadow.Position_Actual := VO_Blinds_Positions[1];

// Blinds validation
IF VO_Blinds_Positions[1] <> L_Blinds_V2_Command_Shadow.Position_Setpoint THEN
    L_Blinds_V2_Shadow_Diff_Found := TRUE;
END_IF;
IF VO_Blinds_Positions[1] <> L_Blinds_V2_State_Shadow.Position_Actual THEN
    L_Blinds_V2_Shadow_Diff_Found := TRUE;
END_IF;


// Guarded Blinds V2 enable
IF L_Blinds_V2_Switch_Enabled THEN
    IF NOT L_Blinds_V2_Shadow_Diff_Found THEN
        L_Blinds_V2_Path_Ready := TRUE;
        L_Blinds_Using_Legacy_Fallback := FALSE;
    ELSE
        L_Blinds_V2_Path_Ready := FALSE;
        L_Blinds_Using_Legacy_Fallback := TRUE;
    END_IF;
ELSE
    L_Blinds_V2_Path_Ready := FALSE;
    L_Blinds_Using_Legacy_Fallback := TRUE;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Lighting_Blinds_Manager <<<
