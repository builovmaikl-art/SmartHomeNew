// ==============================================================================
// Блок таймера, привязанный к системному времени (System Timer)
// Назначение:
// - Замена стандартного TON для обеспечения точной выдержки времени,
//   независимой от времени цикла ПЛК, с использованием единого системного времени.
// ==============================================================================
FUNCTION_BLOCK FB_System_Timer
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
END_VAR

IF IN THEN
    IF NOT L_Running THEN
        L_Start_Time := VI_System_Time_MS;
        L_Running := TRUE;
        ET := T#0s;
        Q := FALSE;
    ELSE
        // Обработка переполнения UDINT (примерно 49 дней)
        ET := TO_TIME((SEL(VI_System_Time_MS >= L_Start_Time, VI_System_Time_MS - L_Start_Time, (4294967295 - L_Start_Time) + VI_System_Time_MS + 1)));
        
        IF ET >= PT THEN
            Q := TRUE;
            ET := PT;
        ELSE
            Q := FALSE;
        END_IF;
    END_IF;
ELSE
    L_Running := FALSE;
    ET := T#0s;
    Q := FALSE;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_System_Timer <<<
END_FUNCTION_BLOCK
