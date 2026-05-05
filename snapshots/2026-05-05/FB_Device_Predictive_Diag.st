FUNCTION_BLOCK FB_Device_Predictive_Diag
VAR_INPUT
    VI_Current_Value : REAL;      // Текущий ток или время
    VI_Nominal_Value : REAL;      // Эталонное значение
    VI_Is_Running    : BOOL;
    VI_Reset_Stats   : BOOL;
    VI_System_Time_MS: UDINT;     // Системное время (мс)
END_VAR
VAR_IN_OUT
    VIO_Health_Data  : ST_Device_Health;
END_VAR
VAR
    L_Prev_Running   : BOOL;
    L_Start_Time     : UDINT;
    L_Last_Calc_Time : UDINT;
    L_Elapsed_MS     : UDINT;
    L_Accumulated_MS : UDINT; // Накопленное время работы (мс)
    L_Timer_Running  : FB_System_Timer;
END_VAR

// 0. Сброс статистики
IF VI_Reset_Stats THEN
    VIO_Health_Data.Starts_Count := 0;
    VIO_Health_Data.Sample_Count := 0;
    VIO_Health_Data.Current_Sum := 0.0;
    VIO_Health_Data.Avg_Start_Current := 0.0;
    VIO_Health_Data.Health_Score := 100;
    VIO_Health_Data.Maintenance_Required := FALSE;
    VIO_Health_Data.Warning_Message := '';
    VIO_Health_Data.Last_Start_Current := 0.0;
    VIO_Health_Data.Total_Runtime_Hours := 0;
    L_Accumulated_MS := 0;
END_IF;

// 1. Счётчик пусков и замер пускового тока
IF VI_Is_Running AND NOT L_Prev_Running THEN
    VIO_Health_Data.Starts_Count := VIO_Health_Data.Starts_Count + 1;
    VIO_Health_Data.Last_Start_Current := VI_Current_Value;
    L_Start_Time := VI_System_Time_MS;
    L_Last_Calc_Time := VI_System_Time_MS;
    
    // Обновление среднего пускового тока
    VIO_Health_Data.Sample_Count := VIO_Health_Data.Sample_Count + 1;
    VIO_Health_Data.Current_Sum := VIO_Health_Data.Current_Sum + VI_Current_Value;
    VIO_Health_Data.Avg_Start_Current := VIO_Health_Data.Current_Sum / UDINT_TO_REAL(VIO_Health_Data.Sample_Count);
    
    // 2. Анализ отклонения пускового тока (п. 12.1 ТЗ)
    IF VI_Current_Value > (VI_Nominal_Value * 1.5) THEN
        VIO_Health_Data.Health_Score := TO_BYTE(LIMIT(0, TO_INT(VIO_Health_Data.Health_Score) - 5, 100));
    ELSIF VI_Current_Value > (VI_Nominal_Value * 1.2) THEN
        VIO_Health_Data.Health_Score := TO_BYTE(LIMIT(0, TO_INT(VIO_Health_Data.Health_Score) - 1, 100));
    ELSIF VI_Current_Value < (VI_Nominal_Value * 0.5) THEN
        VIO_Health_Data.Health_Score := TO_BYTE(LIMIT(0, TO_INT(VIO_Health_Data.Health_Score) - 2, 100));
    END_IF;
END_IF;

// 3. Анализ рабочего тока и наработки
IF VI_Is_Running THEN
    L_Elapsed_MS := (VI_System_Time_MS - L_Last_Calc_Time);
    L_Accumulated_MS := L_Accumulated_MS + L_Elapsed_MS;
    L_Last_Calc_Time := VI_System_Time_MS;
    
    // Обновляем наработку каждый час (3600000 мс)
    IF L_Accumulated_MS >= 3600000 THEN
        VIO_Health_Data.Total_Runtime_Hours := VIO_Health_Data.Total_Runtime_Hours + 1;
        L_Accumulated_MS := L_Accumulated_MS - 3600000;
        
        // Естественный износ: -1% здоровья каждые 1000 часов
        IF (VIO_Health_Data.Total_Runtime_Hours MOD 1000) = 0 THEN
            VIO_Health_Data.Health_Score := TO_BYTE(LIMIT(0, TO_INT(VIO_Health_Data.Health_Score) - 1, 100));
        END_IF;
        
        // Анализ рабочего тока (после пускового режима)
        IF (VI_System_Time_MS - L_Start_Time) > 10000 THEN // 10 секунд после пуска
            IF VI_Current_Value > (VI_Nominal_Value * 1.1) THEN
                // Повышенный рабочий ток - ускоренный износ (-1% в час)
                VIO_Health_Data.Health_Score := TO_BYTE(LIMIT(0, TO_INT(VIO_Health_Data.Health_Score) - 1, 100));
            END_IF;
        END_IF;
    END_IF;
END_IF;

// 4. Генерация предупреждения
IF VIO_Health_Data.Health_Score < 20 THEN
    VIO_Health_Data.Maintenance_Required := TRUE;
    VIO_Health_Data.Warning_Message := 'Критический износ: проверьте механику';
ELSIF VIO_Health_Data.Health_Score < 60 THEN
    VIO_Health_Data.Maintenance_Required := FALSE;
    VIO_Health_Data.Warning_Message := 'Предупреждение: повышенное трение';
ELSE
    VIO_Health_Data.Maintenance_Required := FALSE;
    VIO_Health_Data.Warning_Message := 'В норме';
END_IF;

L_Prev_Running := VI_Is_Running;
END_FUNCTION_BLOCK
