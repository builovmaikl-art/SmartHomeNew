FUNCTION_BLOCK FB_NVRAM_Manager
VAR_INPUT
    VI_Command                  : BYTE; // 1=WRITE (READ not implemented)
    VI_Offset                   : UDINT; // Смещение в байтах
    VI_DataRef                  : REFERENCE TO BYTE;
    VI_DataSize                 : UDINT; // КРИТИЧНО: используем этот размер вместо SIZEOF
    VI_System_Time_MS           : UDINT;
    VI_Operator_ID              : STRING(10);
    VI_IsActivePLC              : BOOL;
    VI_TwoPersonConfirmation    : BOOL;
END_VAR
VAR_OUTPUT
    VO_Done                     : BOOL;
    VO_Error                    : BOOL;
    VO_ErrorID                  : UDINT;
    // VO_ReadDataRef removed (REFERENCE TO not allowed in output)
    VO_HMI_Status_Message       : STRING(200);
END_VAR
VAR
    L_prev_Command              : BYTE;
    L_cmd_rising                : BOOL;
    L_i                         : UDINT;
    L_Data_Changed              : BOOL; // Флаг изменения данных
    L_pData                      : POINTER TO BYTE;
END_VAR
VAR CONSTANT
    C_MAX_NVRAM_SIZE            : UDINT := 12800;
END_VAR

// Детекция фронта команды
L_cmd_rising := (VI_Command <> 0) AND (L_prev_Command = 0);
L_prev_Command := VI_Command;

IF L_cmd_rising THEN
    VO_Done := FALSE;
    VO_Error := FALSE;
    VO_ErrorID := 0;
    VO_HMI_Status_Message := '';
    
    // Валидация смещения
    IF VI_Offset >= C_MAX_NVRAM_SIZE THEN
        VO_Error := TRUE;
        VO_ErrorID := 16#1501;
        VO_HMI_Status_Message := 'NVRAM: Неверное смещение';
        VO_Done := TRUE;
        RETURN;
    END_IF;

    // Валидация указателя
    IF NOT __ISVALIDREF(VI_DataRef) THEN
        VO_Error := TRUE;
        VO_ErrorID := 16#150A;
        VO_HMI_Status_Message := 'NVRAM: Недействительная ссылка на данные';
        VO_Done := TRUE;
        RETURN;
    END_IF;

    L_pData := ADR(VI_DataRef);

    IF (VI_Offset + VI_DataSize) > C_MAX_NVRAM_SIZE THEN
        VO_Error := TRUE;
        VO_ErrorID := 16#150B;
        VO_HMI_Status_Message := 'NVRAM: Размер данных превышает доступный объем';
        VO_Done := TRUE;
        RETURN;
    END_IF;

    IF VI_Command = 2 THEN
    VO_Error := TRUE;
    VO_ErrorID := 16#150D;
    VO_HMI_Status_Message := 'NVRAM: READ not implemented';
    VO_Done := TRUE;
    RETURN;
END_IF;

IF VI_Command = 1 THEN // ЗАПИСЬ (WRITE)
        IF NOT VI_IsActivePLC THEN
            VO_Error := TRUE;
            VO_ErrorID := 16#1509;
            VO_HMI_Status_Message := 'NVRAM: Запись запрещена (STANDBY)';
        ELSE
            // Проверка на изменение данных перед записью
            L_Data_Changed := FALSE;
            FOR L_i := 0 TO VI_DataSize - 1 DO
                IF GVL_Retain.G_NVRAM_Data[VI_Offset + L_i] <> L_pData[L_i] THEN
                    L_Data_Changed := TRUE;
                    EXIT;
                END_IF;
            END_FOR;
            
            IF L_Data_Changed THEN
                // Безопасное копирование (WRITE)
                FOR L_i := 0 TO VI_DataSize - 1 DO
                    GVL_Retain.G_NVRAM_Data[VI_Offset + L_i] := L_pData[L_i];
                END_FOR;
                VO_HMI_Status_Message := 'NVRAM: Данные успешно сохранены в RETAIN';
            ELSE
                VO_HMI_Status_Message := 'NVRAM: Данные не изменились, запись пропущена';
            END_IF;
        END_IF;
        VO_Done := TRUE;
    END_IF;
END_IF;

IF VI_Command = 0 THEN
    VO_Done := FALSE;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_NVRAM_Manager <<<
