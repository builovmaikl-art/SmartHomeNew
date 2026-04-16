FUNCTION_BLOCK FB_Simulation_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_IsActivePLC    : BOOL; // Флаг: Данный ПЛК является ведущим
    VI_Scenario       : E_SCENARIO_TYPE; // Текущий активный сценарий
    VI_Config         : ST_Scenario_Config; // Конфигурация сценариев
END_VAR
VAR_OUTPUT
    VO_Sim_Lights     : ARRAY[1..32] OF BOOL; // Симулированные сигналы включения света
    VO_Sim_Active     : BOOL; // Флаг: Симуляция присутствия активна
    // Симуляция аварий (для тестирования)
    VO_Sim_Water_Leak : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF BOOL; // Симулированные сигналы протечки
    VO_Sim_Gas_Leak   : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF REAL; // Симулированные уровни газа
END_VAR
VAR
    L_Random          : FB_Random_Generator;
    L_Last_Toggle     : UDINT;
    L_i               : INT;
    L_Rand_Val        : UDINT;
    L_Test_Mode       : BOOL := FALSE; // Флаг тестового режима
END_VAR

IF VI_Scenario = E_SCENARIO_TYPE.SCENARIO_AWAY AND VI_Config.Presence_Simulation_Enabled THEN
    VO_Sim_Active := TRUE;
    
    // Переключаем свет каждые 30 минут
    IF (VI_System_Time_MS - L_Last_Toggle) >= (GVL_CONSTANTS.C_MS_IN_MINUTE * 30) THEN
        L_Last_Toggle := VI_System_Time_MS;
        
        FOR L_i := 1 TO 32 DO
            L_Rand_Val := 1;
            VO_Sim_Lights[L_i] := (L_Rand_Val > 80); // 20% шанс включения
        END_FOR;
    END_IF;
ELSE
    VO_Sim_Active := FALSE;
    FOR L_i := 1 TO 32 DO VO_Sim_Lights[L_i] := FALSE; END_FOR;
END_IF;

// Симуляция аварий в тестовом режиме
IF L_Test_Mode THEN
    // Генерация случайных протечек (очень редко)
    L_Rand_Val := 1;
    IF L_Rand_Val = 42 THEN
        VO_Sim_Water_Leak[1] := TRUE;
    END_IF;
    
    // Симуляция утечки газа
    L_Rand_Val := 1;
    IF L_Rand_Val = 77 THEN
        VO_Sim_Gas_Leak[1] := 15.0; // 15% LEL
    END_IF;
ELSE
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO VO_Sim_Water_Leak[L_i] := FALSE; END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO VO_Sim_Gas_Leak[L_i] := 0.0; END_FOR;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Simulation_Manager <<<
