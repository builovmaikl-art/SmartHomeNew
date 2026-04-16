FUNCTION_BLOCK FB_Valve_Test
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Start_Test     : BOOL;
    VI_Valve_ID       : BYTE;
END_VAR
VAR_OUTPUT
    VO_Test_Active    : BOOL;
    VO_Result         : E_Valve_Test_Result;
    VO_Valve_Cmd      : BOOL;
END_VAR
VAR
    L_Start_Time      : UDINT;
    L_State           : INT;
END_VAR

CASE L_State OF
    0: // Ожидание
        IF VI_Start_Test THEN
            VO_Test_Active := TRUE;
            VO_Result := E_Valve_Test_Result.TEST_IN_PROGRESS;
            L_Start_Time := VI_System_Time_MS;
            VO_Valve_Cmd := TRUE; // Открыть
            L_State := 1;
        END_IF;
    1: // Тест
        IF (SEL(VI_System_Time_MS >= L_Start_Time, VI_System_Time_MS - L_Start_Time, (4294967295 - L_Start_Time) + VI_System_Time_MS + 1)) > 5000 THEN
            VO_Valve_Cmd := FALSE; // Закрыть
            VO_Result := E_Valve_Test_Result.TEST_PASSED; // Заглушка, нужен контроль концевиков
            VO_Test_Active := FALSE;
            L_State := 0;
        END_IF;
END_CASE;