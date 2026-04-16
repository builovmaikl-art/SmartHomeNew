FUNCTION_BLOCK FB_Sensor_Analog_Processing
VAR_INPUT
    VI_Raw_Value : WORD; // Raw value from module (e.g., 0-27648)
    VI_Sensor_Type : INT := 0; // 0: 4-20mA, 1: 0-10V, 2: PT100/1000 (direct temp * 10)
    VI_Min_Scale : REAL; // Minimum scale value (e.g., 0 bar)
    VI_Max_Scale : REAL; // Maximum scale value (e.g., 10 bar)
    VI_Offset : REAL; // Calibration offset
    VI_Multiplier : REAL := 1.0; // Calibration multiplier
    VI_Filter_Time_MS : UDINT := GVL_CONSTANTS.C_MS_IN_SECOND; // Filtering time
    VI_System_Time_MS : UDINT; // System time in ms
    VI_Fallback_Mode : INT := 0; // 0: Hold last good value, 1: Use default value
    VI_Default_Value : REAL := 0.0; // Default value for fallback mode 1
END_VAR
VAR_OUTPUT
    VO_Value : REAL; // Processed value
    VO_Error : BOOL; // Sensor error (open/short circuit)
    VO_Diag_Code : WORD; // Diagnostic code (0: OK, 1: Open circuit, 2: Short circuit, 3: Out of range)
END_VAR
VAR
    L_Scaled : REAL;
    L_Filtered : REAL;
    L_History : ARRAY[0..9] OF REAL; // Массив для скользящего среднего (10 значений)
    L_History_Idx : INT := 0;
    L_History_Sum : REAL := 0.0;
    L_History_Count : INT := 0;
    L_Last_Time : UDINT;
    L_DT : UDINT;
    L_First_Scan : BOOL := TRUE;
    L_i : INT;
END_VAR

// 1. Error checking and scaling based on sensor type
VO_Error := FALSE;
VO_Diag_Code := 0;

CASE VI_Sensor_Type OF
    0: // 4-20mA (NAMUR NE43: < 3.6mA or > 21mA)
        IF VI_Raw_Value < GVL_CONSTANTS.C_ANALOG_3_6MA_RAW THEN // < 3.6mA (Open circuit)
            VO_Error := TRUE;
            VO_Diag_Code := 1;
        ELSIF VI_Raw_Value > GVL_CONSTANTS.C_ANALOG_21MA_RAW THEN // > 21mA (Short circuit)
            VO_Error := TRUE;
            VO_Diag_Code := 2;
        ELSE
            // 4mA = 5529, 20mA = 27648
            L_Scaled := VI_Min_Scale + (TO_REAL(VI_Raw_Value - GVL_CONSTANTS.C_ANALOG_4MA_RAW) / TO_REAL(GVL_CONSTANTS.C_ANALOG_RAW_MAX - GVL_CONSTANTS.C_ANALOG_4MA_RAW)) * (VI_Max_Scale - VI_Min_Scale);
        END_IF;
        
    1: // 0-10V (0-27648)
        IF VI_Raw_Value > GVL_CONSTANTS.C_ANALOG_10V_MAX_RAW THEN // Out of range
            VO_Error := TRUE;
            VO_Diag_Code := 3;
        ELSE
            L_Scaled := VI_Min_Scale + (TO_REAL(VI_Raw_Value) / TO_REAL(GVL_CONSTANTS.C_ANALOG_RAW_MAX)) * (VI_Max_Scale - VI_Min_Scale);
        END_IF;
        
    2: // PT100/1000 (Direct temperature * 10, e.g., 255 = 25.5C)
        // Typically, 16-bit signed integer for temperature
        IF VI_Raw_Value = 16#7FFF OR VI_Raw_Value = 16#8000 THEN // Sensor error codes
            VO_Error := TRUE;
            VO_Diag_Code := 1;
        ELSE
            L_Scaled := TO_REAL(TO_INT(VI_Raw_Value)) / 10.0;
            IF L_Scaled < VI_Min_Scale OR L_Scaled > VI_Max_Scale THEN
                VO_Error := TRUE;
                VO_Diag_Code := 3;
            END_IF;
        END_IF;
        
    ELSE
        VO_Error := TRUE;
        VO_Diag_Code := 16#FFFF; // Unknown sensor type
END_CASE;

// 2. Fallback handling
IF VO_Error THEN
    IF VI_Fallback_Mode = 1 THEN
        VO_Value := VI_Default_Value;
    END_IF;
    // If VI_Fallback_Mode = 0, VO_Value retains its last good value (L_Filtered)
    RETURN;
END_IF;

// 3. Calibration
L_Scaled := (L_Scaled * VI_Multiplier) + VI_Offset;

// 4. Moving Average Filter (ТЗ 1.2)
IF L_First_Scan THEN
    L_Filtered := L_Scaled;
    L_First_Scan := FALSE;
    L_Last_Time := VI_System_Time_MS;
    
    // Инициализация массива истории
    FOR L_i := 0 TO 9 DO
        L_History[L_i] := L_Scaled;
    END_FOR;
    L_History_Sum := L_Scaled * 10.0;
    L_History_Count := 10;
    L_History_Idx := 0;
END_IF;

L_DT := (SEL(VI_System_Time_MS >= L_Last_Time, VI_System_Time_MS - L_Last_Time, (4294967295 - L_Last_Time) + VI_System_Time_MS + 1));
IF VI_Filter_Time_MS = 0 THEN
    L_Filtered := L_Scaled;
    L_Last_Time := VI_System_Time_MS;
ELSIF L_DT >= (VI_Filter_Time_MS / 10) THEN // Обновляем 10 раз за время фильтрации
    // Вычитаем старое значение
    L_History_Sum := L_History_Sum - L_History[L_History_Idx];
    
    // Добавляем новое значение
    L_History[L_History_Idx] := L_Scaled;
    L_History_Sum := L_History_Sum + L_Scaled;
    
    // Сдвигаем индекс
    L_History_Idx := (L_History_Idx + 1) MOD 10;
    
    // Вычисляем среднее
    L_Filtered := L_History_Sum / 10.0;
    
    L_Last_Time := VI_System_Time_MS;
END_IF;

VO_Value := L_Filtered;