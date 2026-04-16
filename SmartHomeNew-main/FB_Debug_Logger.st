FUNCTION_BLOCK FB_Debug_Logger
VAR_INPUT
    VI_Config           : ST_Debug_Logger_Config;
    VI_System_Time_MS   : UDINT;
    VI_Error_Code       : UDINT;
END_VAR
VAR_IN_OUT
    VI_Floor_Temps      : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Pump_Currents    : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
END_VAR
VAR_OUTPUT
    VO_Buffer           : ARRAY[1..GVL_CONSTANTS.C_MAX_DEBUG_LOGS] OF ST_Debug_Log_Record;
    VO_Write_Idx        : INT := 1;
    VO_Buffer_Overflow  : BOOL := FALSE;
    VO_Lost_Records     : UDINT := 0; // Счетчик потерянных (перезаписанных) записей
END_VAR
VAR
    L_last_log_time     : UDINT;
    L_last_temps        : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    L_last_temp_time    : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF UDINT;
    L_last_error        : UDINT;
    L_i                 : INT;
    L_diff              : REAL;
    L_time_diff         : UDINT;
END_VAR

// Цикл логирования
IF VI_Config.enabled AND (SEL(VI_System_Time_MS >= L_last_log_time, VI_System_Time_MS - L_last_log_time, (4294967295 - L_last_log_time) + VI_System_Time_MS + 1)) >= VI_Config.sampling_period_ms THEN
    L_last_log_time := VI_System_Time_MS;
    
    // Логируем температуры (если изменились или по таймауту)
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        L_diff := ABS(VI_Floor_Temps[L_i] - L_last_temps[L_i]);
        L_time_diff := (SEL(VI_System_Time_MS >= L_last_temp_time[L_i], VI_System_Time_MS - L_last_temp_time[L_i], (4294967295 - L_last_temp_time[L_i]) + VI_System_Time_MS + 1));
        
        IF (L_diff >= 0.5) OR (L_time_diff >= 3600000) THEN // Изменение на 0.5 градуса или раз в час
            L_last_temps[L_i] := VI_Floor_Temps[L_i];
            L_last_temp_time[L_i] := VI_System_Time_MS;
            
            IF VO_Buffer_Overflow THEN
                VO_Lost_Records := VO_Lost_Records + 1;
            END_IF;
            
            VO_Buffer[VO_Write_Idx].timestamp_ms := VI_System_Time_MS;
            VO_Buffer[VO_Write_Idx].level := E_Debug_Log_Level.LOG_LEVEL_VERBOSE;
            VO_Buffer[VO_Write_Idx].source_id := TO_BYTE(L_i);
            VO_Buffer[VO_Write_Idx].value_real := VI_Floor_Temps[L_i];
            VO_Buffer[VO_Write_Idx].text := 'Floor Temp Update';
            
            IF VO_Write_Idx = GVL_CONSTANTS.C_MAX_DEBUG_LOGS THEN
                VO_Buffer_Overflow := TRUE;
            END_IF;
            VO_Write_Idx := (VO_Write_Idx MOD GVL_CONSTANTS.C_MAX_DEBUG_LOGS) + 1;
        END_IF;
    END_FOR;

    // Логируем ошибки
    IF VI_Error_Code <> 0 AND VI_Error_Code <> L_last_error THEN
        L_last_error := VI_Error_Code;
        IF VO_Buffer_Overflow THEN
            VO_Lost_Records := VO_Lost_Records + 1;
        END_IF;
        
        VO_Buffer[VO_Write_Idx].timestamp_ms := VI_System_Time_MS;
        VO_Buffer[VO_Write_Idx].level := E_Debug_Log_Level.LOG_LEVEL_MINIMAL;
        VO_Buffer[VO_Write_Idx].event_code := TO_WORD(VI_Error_Code);
        VO_Buffer[VO_Write_Idx].text := 'System Error Detected';
        
        IF VO_Write_Idx = GVL_CONSTANTS.C_MAX_DEBUG_LOGS THEN
            VO_Buffer_Overflow := TRUE;
        END_IF;
        VO_Write_Idx := (VO_Write_Idx MOD GVL_CONSTANTS.C_MAX_DEBUG_LOGS) + 1;
    ELSIF VI_Error_Code = 0 THEN
        L_last_error := 0;
    END_IF;
END_IF;