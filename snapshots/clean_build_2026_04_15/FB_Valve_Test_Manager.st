FUNCTION_BLOCK FB_Valve_Test_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
END_VAR
VAR_IN_OUT
    VI_Valve_Currents : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Valve_End_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Config : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Valve_Test_Config;
END_VAR
VAR_OUTPUT
    VO_Test_Active : BOOL;
    VO_Current_Valve : INT; // Текущий тестируемый клапан
    VO_Valve_Cmd : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VO_Test_Results : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL; // TRUE = OK
    VO_Status_Msg : STRING(200);
END_VAR
VAR
    L_State : INT;
    L_Current_Valve : INT := 1;
    L_Test_Start_Time : UDINT;
    L_Last_Test_Time : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF UDINT;
    L_i : INT;
    L_Need_Test : BOOL;
    L_Elapsed_Time : UDINT;
END_VAR

IF NOT VI_IsActivePLC THEN RETURN; END_IF;

CASE L_State OF
    0: // Ожидание
        VO_Test_Active := FALSE;
        L_Need_Test := FALSE;
        
        // Поиск клапана, которому нужен тест (раз в неделю)
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            IF VI_Config[L_i].enabled AND ((VI_System_Time_MS - L_Last_Test_Time[L_i]) > (VI_Config[L_i].test_interval_days * 86400000)) THEN
                L_Current_Valve := L_i;
                L_Need_Test := TRUE;
                EXIT;
            END_IF;
        END_FOR;
        
        IF L_Need_Test THEN
            L_State := 1;
            L_Test_Start_Time := VI_System_Time_MS;
            VO_Test_Active := TRUE;
            VO_Current_Valve := L_Current_Valve;
            VO_Valve_Cmd[L_Current_Valve] := TRUE; // Открываем
            VO_Status_Msg := CONCAT('ТЕСТ КЛАПАНА ', INT_TO_STRING(L_Current_Valve));
            VO_Test_Results[L_Current_Valve] := TRUE; // Сброс результата
        END_IF;
        
    1: // Тестирование (ожидание открытия)
        L_Elapsed_Time := (VI_System_Time_MS - L_Test_Start_Time);
        
        IF VI_Valve_End_Switches[L_Current_Valve] THEN
            // Концевик сработал до истечения таймаута
            // Проверка тока
            IF ABS(VI_Valve_Currents[L_Current_Valve] - VI_Config[L_Current_Valve].Nominal_Current) > (VI_Config[L_Current_Valve].Nominal_Current * 0.2) THEN
                VO_Test_Results[L_Current_Valve] := FALSE; // Ошибка по току
            END_IF;
            
            GVL_Retain.G_Valve_Test_Results[L_Current_Valve] := VO_Test_Results[L_Current_Valve];
            
            VO_Valve_Cmd[L_Current_Valve] := FALSE; // Закрываем
            L_Test_Start_Time := VI_System_Time_MS; // Перезапускаем таймер для проверки закрытия
            L_State := 2;
        ELSIF L_Elapsed_Time > TO_UDINT(VI_Config[L_Current_Valve].nominal_close_time_sec * 1000.0) THEN
            // Таймаут открытия (заклинивание)
            VO_Test_Results[L_Current_Valve] := FALSE; 
            GVL_Retain.G_Valve_Test_Results[L_Current_Valve] := FALSE;
            VO_Status_Msg := CONCAT('ОШИБКА: ЗАКЛИНИВАНИЕ КЛАПАНА ', INT_TO_STRING(L_Current_Valve));
            
            VO_Valve_Cmd[L_Current_Valve] := FALSE; // Закрываем
            L_Test_Start_Time := VI_System_Time_MS; // Перезапускаем таймер
            L_State := 2;
        END_IF;
        
    2: // Ожидание закрытия
        L_Elapsed_Time := (VI_System_Time_MS - L_Test_Start_Time);
        
        IF NOT VI_Valve_End_Switches[L_Current_Valve] THEN
            // Концевик разомкнулся (клапан закрыт)
            L_Last_Test_Time[L_Current_Valve] := VI_System_Time_MS;
            L_State := 0;
            IF VO_Test_Results[L_Current_Valve] THEN
                VO_Status_Msg := 'ТЕСТ ЗАВЕРШЕН УСПЕШНО';
            END_IF;
        ELSIF L_Elapsed_Time > TO_UDINT(VI_Config[L_Current_Valve].nominal_close_time_sec * 1000.0) THEN
            // Таймаут закрытия (заклинивание)
            VO_Test_Results[L_Current_Valve] := FALSE; 
            GVL_Retain.G_Valve_Test_Results[L_Current_Valve] := FALSE;
            VO_Status_Msg := CONCAT('ОШИБКА: НЕ ЗАКРЫЛСЯ КЛАПАН ', INT_TO_STRING(L_Current_Valve));
            
            L_Last_Test_Time[L_Current_Valve] := VI_System_Time_MS;
            L_State := 0;
        END_IF;
END_CASE;