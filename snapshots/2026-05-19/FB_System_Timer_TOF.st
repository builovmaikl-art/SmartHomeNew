// ==============================================================================
// Блок таймера задержки выключения (System Timer TOF)
// Назначение:
// - Замена стандартного TOF для обеспечения точной выдержки времени,
//   независимой от времени цикла ПЛК, с использованием единого системного времени.
// ==============================================================================
FUNCTION_BLOCK FB_System_Timer_TOF
VAR_INPUT
    IN : BOOL; // Вход запуска таймера
    PT : TIME; // Заданное время
    VI_System_Time_MS : UDINT; // Системное время (мс)
END_VAR
VAR_OUTPUT
    Q : BOOL; // Выход: таймер сработал
    ET : TIME; // Прошедшее время
END_VAR
VAR
    L_Start_Time : UDINT;
    L_Running : BOOL;
    L_Prev_IN : BOOL;
END_VAR

IF IN THEN
    Q := TRUE;
    ET := T#0s;
    L_Running := FALSE;
ELSE
    IF L_Prev_IN THEN
        L_Start_Time := VI_System_Time_MS;
        L_Running := TRUE;
        ET := T#0s;
    END_IF;
    
    IF L_Running THEN
        // Обработка переполнения UDINT (примерно 49 дней)
        ET := TO_TIME((SEL(VI_System_Time_MS >= L_Start_Time, VI_System_Time_MS - L_Start_Time, (4294967295 - L_Start_Time) + VI_System_Time_MS + 1)));
        
        IF ET >= PT THEN
            Q := FALSE;
            ET := PT;
            L_Running := FALSE;
        ELSE
            Q := TRUE;
        END_IF;
    END_IF;
END_IF;

L_Prev_IN := IN;
END_FUNCTION_BLOCK
