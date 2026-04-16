FUNCTION_BLOCK FB_PID_Controller
VAR_INPUT
    VI_SetPoint : REAL;         // Уставка
    VI_ProcessValue : REAL;     // Текущее значение
    VI_Kp : REAL;               // Коэффициент усиления
    VI_Tn : REAL;               // Время интегрирования (сек)
    VI_Tv : REAL;               // Время дифференцирования (сек)
    VI_Y_Min : REAL := 0.0;     // Минимальный выход
    VI_Y_Max : REAL := 100.0;   // Максимальный выход
    VI_Manual_Mode : BOOL;      // Ручной режим
    VI_Manual_Value : REAL;     // Значение в ручном режиме
    VI_Deadband : REAL := 0.1;  // Мертвая зона
    VI_Cycle_Time_S : REAL := 0.01; // Время цикла задачи в секундах
    VI_Reset : BOOL;            // Сброс интегральной составляющей
END_VAR
VAR_OUTPUT
    VO_Output : REAL;           // Выход регулятора
    VO_Error : REAL;            // Ошибка рассогласования
    VO_Limiting : BOOL;         // Флаг ограничения выхода (Anti-windup)
END_VAR
VAR
    L_Integral_Sum : REAL;      // Интегральная сумма
    L_Prev_Error : REAL;        // Предыдущая ошибка
    L_Derivative : REAL;        // Дифференциальная составляющая
    L_Output_Raw : REAL;        // Сырой выход до ограничения
END_VAR

// Расчет ошибки
VO_Error := VI_SetPoint - VI_ProcessValue;

// Проверка мертвой зоны
IF ABS(VO_Error) < VI_Deadband THEN
    VO_Error := 0.0;
END_IF;

IF VI_Reset THEN
    L_Integral_Sum := 0.0;
    L_Prev_Error := 0.0;
    VO_Output := 0.0;
    RETURN;
END_IF;

IF VI_Manual_Mode THEN
    VO_Output := VI_Manual_Value;
    // Безударный переход: при выходе из ручного режима выход должен остаться прежним.
    // Так как Выход = P + I + D, то I = Выход - P - D.
    // Для простоты D при переходе обнуляем (или игнорируем), тогда I = Выход - P.
    L_Integral_Sum := VO_Output - (VI_Kp * VO_Error);
    L_Prev_Error := VO_Error;
    RETURN;
END_IF;

// Пропорциональная составляющая
L_Output_Raw := VI_Kp * VO_Error;

// Интегральная составляющая (Метод трапеций)
IF VI_Tn > 0.0 THEN
    // Anti-windup: не накапливаем интеграл, если выход уже на пределе и ошибка того же знака
    IF NOT VO_Limiting OR (VO_Error > 0.0 AND L_Output_Raw < VI_Y_Max) OR (VO_Error < 0.0 AND L_Output_Raw > VI_Y_Min) THEN
        L_Integral_Sum := L_Integral_Sum + (VI_Kp / VI_Tn) * VO_Error * VI_Cycle_Time_S;
    END_IF;
    L_Output_Raw := L_Output_Raw + L_Integral_Sum;
END_IF;

// Дифференциальная составляющая
IF VI_Tv > 0.0 THEN
    L_Derivative := (VO_Error - L_Prev_Error) / VI_Cycle_Time_S;
    L_Output_Raw := L_Output_Raw + VI_Kp * VI_Tv * L_Derivative;
END_IF;

L_Prev_Error := VO_Error;

// Ограничение выхода
IF L_Output_Raw > VI_Y_Max THEN
    VO_Output := VI_Y_Max;
    VO_Limiting := TRUE;
ELSIF L_Output_Raw < VI_Y_Min THEN
    VO_Output := VI_Y_Min;
    VO_Limiting := TRUE;
ELSE
    VO_Output := L_Output_Raw;
    VO_Limiting := FALSE;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_PID_Controller <<<
