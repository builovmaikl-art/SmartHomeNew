FUNCTION_BLOCK FB_Gateway_Interface
VAR_INPUT
    VI_System_Time_MS           : UDINT;
    VI_Local_PLC_Role           : E_PLC_ROLE;
    VI_Incoming_Command         : ST_Gateway_Command;
    VI_Command_Received         : BOOL;
    
    // Состояния системы
    VI_Outdoor_Temp             : REAL;
    VI_Security_Armed           : BOOL;
    VI_Flood_Alarm_Active       : BOOL;
    VI_Gas_Alarm_Active         : BOOL;
    VI_Fire_Alarm_Active        : BOOL;
    VI_Methane_Concentration    : REAL;
    VI_Active_Scenario          : E_SCENARIO_TYPE;
    
    // 2FA
    VI_Send_2FA_Req             : BOOL;
    VI_2FA_Code                 : STRING(6);
    
    // Конфигурация
END_VAR
VAR_IN_OUT
    VI_FloorHeating_Temps       : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Room_Temps               : ARRAY[1..16] OF REAL;
    VI_Zone_Valve_States        : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    VI_Manifold_Pressures       : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    VI_Manifold_Pump_States     : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Lighting_Base_Levels     : ARRAY[1..32] OF BYTE;
    VI_Socket_States            : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    VI_Blinds_Positions         : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE;
    VI_Allowed_IPs              : ARRAY[1..GVL_CONSTANTS.C_MAX_ALLOWED_IPS] OF STRING(15);
END_VAR

VAR_OUTPUT
    VO_Modbus_Registers         : ARRAY[0..GVL_CONSTANTS.C_MAX_MODBUS_REGISTERS-1] OF WORD; // Расширенный диапазон
    VO_Lighting_Override        : ARRAY[1..32] OF BYTE;
    VO_Blinds_Override          : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE;
    VO_Socket_Override          : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    VO_Arm_Req                  : BOOL;
    VO_Disarm_Req               : BOOL;
    VO_PIN_Code                 : STRING(4);
    VO_RFID_Tag                 : STRING(20);
    VO_2FA_Code_In              : STRING(6);
    VO_Data_Ready               : BOOL;
    VO_HMI_Status_Message       : STRING(200);
    VO_Telegram_Msg             : STRING(200);
    VO_Send_Telegram            : BOOL;
    
    // Выходы для управления конфигурацией и состоянием
    VO_Set_Scenario_Req         : BOOL;
    VO_Target_Scenario          : E_SCENARIO_TYPE;
    VO_Set_Temp_Req             : BOOL;
    VO_Target_Zone              : INT;
    VO_Target_Temp              : REAL;
    VO_Set_Vent_Req             : BOOL;
    VO_Target_Vent_Speed        : BYTE;
    VO_Reset_Errors_Req         : BOOL; // Запрос на сброс ошибок/квитирование
    VO_Set_Config_Req           : BOOL; // Запрос на применение конфигурации
    VO_Sync_Time_Req            : BOOL; // Запрос на синхронизацию времени
    VO_New_Time_MS              : UDINT; // Новое время (мс с начала суток)
END_VAR

VAR
    L_last_update_time          : UDINT;
    L_i                         : INT;
    L_j                         : INT;
    L_idx                       : INT;
    L_tmp_word                  : WORD;
    L_Code_UDINT                : UDINT;
    L_Prev_Fire                 : BOOL;
    L_Prev_Gas                  : BOOL;
    L_Prev_Flood                : BOOL;
    L_Prev_Security             : BOOL;
    L_Deduplicator              : FB_Command_Deduplication;
    L_CRC_Calc                  : FB_CRC32_Calculator;
    L_Calculated_CRC            : DWORD;
    L_Command_Size              : UDINT;
    L_IP_Allowed                : BOOL;
    
    L_Process_Command           : ST_Gateway_Command;
    L_Has_Command_To_Process    : BOOL;
END_VAR

VAR RETAIN
    // Буфер команд для резервного ПЛК
    L_Command_Buffer            : ARRAY[1..GVL_CONSTANTS.C_MAX_GATEWAY_COMMANDS] OF ST_Gateway_Command;
    L_Buffer_Head               : INT := 1;
    L_Buffer_Tail               : INT := 1;
    L_Buffer_Count              : INT := 0;
END_VAR

// Отправка уведомлений в Telegram (ТЗ 10.2)
VO_Send_Telegram := FALSE;
IF VI_Fire_Alarm_Active AND NOT L_Prev_Fire THEN
    VO_Telegram_Msg := 'ВНИМАНИЕ! ПОЖАРНАЯ ТРЕВОГА!';
    VO_Send_Telegram := TRUE;
END_IF;
IF VI_Gas_Alarm_Active AND NOT L_Prev_Gas THEN
    VO_Telegram_Msg := 'ВНИМАНИЕ! УТЕЧКА ГАЗА!';
    VO_Send_Telegram := TRUE;
END_IF;
IF VI_Flood_Alarm_Active AND NOT L_Prev_Flood THEN
    VO_Telegram_Msg := 'ВНИМАНИЕ! ПРОТЕЧКА ВОДЫ!';
    VO_Send_Telegram := TRUE;
END_IF;
IF VI_Security_Armed AND NOT L_Prev_Security THEN
    VO_Telegram_Msg := 'ОХРАНА ВКЛЮЧЕНА';
    VO_Send_Telegram := TRUE;
ELSIF NOT VI_Security_Armed AND L_Prev_Security THEN
    VO_Telegram_Msg := 'ОХРАНА ОТКЛЮЧЕНА';
    VO_Send_Telegram := TRUE;
END_IF;

L_Prev_Fire := VI_Fire_Alarm_Active;
L_Prev_Gas := VI_Gas_Alarm_Active;
L_Prev_Flood := VI_Flood_Alarm_Active;
L_Prev_Security := VI_Security_Armed;

// Обновление данных Modbus (раз в 1 сек)
IF (VI_System_Time_MS - L_last_update_time) >= GVL_CONSTANTS.C_MS_IN_SECOND THEN
    L_last_update_time := VI_System_Time_MS;
    
    // 0: Статус ПЛК и Аварии
    L_tmp_word := 0;
    IF VI_Local_PLC_Role = E_PLC_ROLE.ROLE_ACTIVE THEN L_tmp_word := L_tmp_word OR 1; END_IF;
    IF VI_Security_Armed THEN L_tmp_word := L_tmp_word OR 2; END_IF;
    IF VI_Flood_Alarm_Active THEN L_tmp_word := L_tmp_word OR 4; END_IF;
    IF VI_Gas_Alarm_Active THEN L_tmp_word := L_tmp_word OR 8; END_IF;
    IF VI_Fire_Alarm_Active THEN L_tmp_word := L_tmp_word OR 16; END_IF;
    VO_Modbus_Registers[0] := L_tmp_word;

    // 1-16: Температуры пола (x10)
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        VO_Modbus_Registers[L_i] := TO_WORD(TO_INT(VI_FloorHeating_Temps[L_i] * 10.0));
    END_FOR;

    // 17-32: Температуры помещений (x10)
    FOR L_i := 1 TO 16 DO
        VO_Modbus_Registers[16 + L_i] := TO_WORD(TO_INT(VI_Room_Temps[L_i] * 10.0));
    END_FOR;

    // 33: Состояние клапанов зон (битовая маска 1-16)
    L_tmp_word := 0;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF VI_Zone_Valve_States[L_i] THEN
            L_tmp_word := L_tmp_word OR SHL(TO_WORD(1), L_i - 1);
        END_IF;
    END_FOR;
    VO_Modbus_Registers[33] := L_tmp_word;

    // 34-38: Давление в коллекторах (x100)
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
        VO_Modbus_Registers[33 + L_i] := TO_WORD(TO_INT(VI_Manifold_Pressures[L_i] * 100.0));
    END_FOR;

    // 40-71: Базовое освещение
    FOR L_i := 1 TO 32 DO
        VO_Modbus_Registers[39 + L_i] := TO_WORD(VI_Lighting_Base_Levels[L_i]);
    END_FOR;

    // 72-91: Положение штор (20 шт)
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
        VO_Modbus_Registers[71 + L_i] := TO_WORD(VI_Blinds_Positions[L_i]);
    END_FOR;

    // 92-94: Розетки (битовая маска, 36 розеток -> 3 WORD)
    FOR L_i := 0 TO (GVL_CONSTANTS.C_MAX_SOCKETS - 1) / 16 DO
        L_tmp_word := 0;
        FOR L_j := 1 TO 16 DO
            L_idx := (L_i * 16) + L_j;
            IF L_idx <= GVL_CONSTANTS.C_MAX_SOCKETS THEN
                IF VI_Socket_States[L_idx] THEN
                    L_tmp_word := L_tmp_word OR SHL(TO_WORD(1), L_j - 1);
                END_IF;
            END_IF;
        END_FOR;
        VO_Modbus_Registers[92 + L_i] := L_tmp_word;
    END_FOR;

    // 100-102: 2FA Request and Code
    VO_Modbus_Registers[100] := SEL(VI_Send_2FA_Req, 0, 1);
    IF VI_Send_2FA_Req THEN
        L_Code_UDINT := STRING_TO_UDINT(VI_2FA_Code);
        VO_Modbus_Registers[101] := TO_WORD(L_Code_UDINT AND 16#FFFF);
        VO_Modbus_Registers[102] := TO_WORD(SHR(L_Code_UDINT, 16));
    ELSE
        VO_Modbus_Registers[101] := 0;
        VO_Modbus_Registers[102] := 0;
    END_IF;

    VO_Data_Ready := TRUE;
END_IF;

// Обработка входящих команд
VO_Arm_Req := FALSE;
VO_Disarm_Req := FALSE;
VO_Set_Scenario_Req := FALSE;
VO_Set_Temp_Req := FALSE;
VO_Set_Vent_Req := FALSE;
VO_Reset_Errors_Req := FALSE;
VO_Set_Config_Req := FALSE;
VO_Sync_Time_Req := FALSE;
L_Has_Command_To_Process := FALSE;

// 1. Прием команды и буферизация
IF VI_Command_Received THEN
    IF VI_Local_PLC_Role = E_PLC_ROLE.ROLE_ACTIVE THEN
        // Если активен, обрабатываем сразу
        L_Process_Command := VI_Incoming_Command;
        L_Has_Command_To_Process := TRUE;
    ELSE
        // Если резервный, добавляем в буфер
        IF L_Buffer_Count < GVL_CONSTANTS.C_MAX_GATEWAY_COMMANDS THEN
            L_Command_Buffer[L_Buffer_Head] := VI_Incoming_Command;
            L_Buffer_Head := L_Buffer_Head + 1;
            IF L_Buffer_Head > GVL_CONSTANTS.C_MAX_GATEWAY_COMMANDS THEN L_Buffer_Head := 1; END_IF;
            L_Buffer_Count := L_Buffer_Count + 1;
        END_IF;
    END_IF;
END_IF;

// 2. Извлечение из буфера при переходе в активный режим
IF NOT L_Has_Command_To_Process AND (VI_Local_PLC_Role = E_PLC_ROLE.ROLE_ACTIVE) AND (L_Buffer_Count > 0) THEN
    L_Process_Command := L_Command_Buffer[L_Buffer_Tail];
    L_Buffer_Tail := L_Buffer_Tail + 1;
    IF L_Buffer_Tail > GVL_CONSTANTS.C_MAX_GATEWAY_COMMANDS THEN L_Buffer_Tail := 1; END_IF;
    L_Buffer_Count := L_Buffer_Count - 1;
    L_Has_Command_To_Process := TRUE;
END_IF;

// 3. Обработка команды
IF L_Has_Command_To_Process THEN
    // Проверка IP-адреса источника
    L_IP_Allowed := FALSE;
    IF L_Process_Command.source_ip = '' THEN
        L_IP_Allowed := TRUE; // Если IP не передан, пропускаем (для обратной совместимости или локальных вызовов)
    ELSE
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ALLOWED_IPS DO
            IF VI_Allowed_IPs[L_i] = L_Process_Command.source_ip THEN
                L_IP_Allowed := TRUE;
                EXIT;
            END_IF;
        END_FOR;
    END_IF;
    
    IF NOT L_IP_Allowed THEN
        VO_HMI_Status_Message := 'Gateway: Ошибка безопасности (Неизвестный IP)';
        RETURN;
    END_IF;

    // Проверка целостности данных (CRC32)
    // Размер данных для расчета CRC: размер структуры минус размер самого поля crc32
    L_Command_Size := SIZEOF(L_Process_Command) - SIZEOF(L_Process_Command.crc32);
    L_Calculated_CRC := L_CRC_Calc.Calculate();
    
    IF L_Calculated_CRC = L_Process_Command.crc32 THEN
        L_Deduplicator(
            VI_Command_ID := L_Process_Command.command_id,
            VI_Command_Type := L_Process_Command.command_type,
            VI_Command_Value := L_Process_Command.target_value,
            VI_System_Time_MS := VI_System_Time_MS
        );
        
        IF L_Deduplicator.VO_Is_New_Command THEN
            CASE L_Process_Command.command_type OF
        E_Gateway_Command_Type.CMD_SET_SCENARIO: // Управление сценариями
            VO_Set_Scenario_Req := TRUE;
            VO_Target_Scenario := L_Process_Command.target_scenario;
            VO_HMI_Status_Message := 'Gateway: Сценарий изменен';
        E_Gateway_Command_Type.CMD_SET_LIGHT: // Управление освещением
            IF (L_Process_Command.target_zone >= 1) AND (L_Process_Command.target_zone <= 32) THEN
                VO_Lighting_Override[L_Process_Command.target_zone] := TO_BYTE(L_Process_Command.target_value);
                VO_HMI_Status_Message := 'Gateway: Команда освещения принята';
            END_IF;
        E_Gateway_Command_Type.CMD_SET_BLINDS: // Управление шторами
            IF (L_Process_Command.target_zone >= 1) AND (L_Process_Command.target_zone <= GVL_CONSTANTS.C_MAX_BLINDS) THEN
                VO_Blinds_Override[L_Process_Command.target_zone] := TO_BYTE(L_Process_Command.target_value);
                VO_HMI_Status_Message := 'Gateway: Команда штор принята';
            END_IF;
        E_Gateway_Command_Type.CMD_SET_SOCKET: // Розетки
            IF (L_Process_Command.target_zone >= 1) AND (L_Process_Command.target_zone <= GVL_CONSTANTS.C_MAX_SOCKETS) THEN
                VO_Socket_Override[L_Process_Command.target_zone] := L_Process_Command.target_on_off;
                VO_HMI_Status_Message := 'Gateway: Команда розетки принята';
            END_IF;
        E_Gateway_Command_Type.CMD_SET_SECURITY: // Охрана
            IF L_Process_Command.target_armed THEN
                VO_Arm_Req := TRUE;
            ELSE
                VO_Disarm_Req := TRUE;
            END_IF;
            VO_PIN_Code := L_Process_Command.target_pin;
            VO_2FA_Code_In := L_Process_Command.target_2fa_code;
            VO_HMI_Status_Message := 'Gateway: Запрос охраны принят';
        E_Gateway_Command_Type.CMD_SET_TEMP: // Управление температурой теплого пола
            IF (L_Process_Command.target_zone >= 1) AND (L_Process_Command.target_zone <= GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS) THEN
                VO_Set_Temp_Req := TRUE;
                VO_Target_Zone := L_Process_Command.target_zone;
                VO_Target_Temp := L_Process_Command.target_value;
                VO_HMI_Status_Message := 'Gateway: Уставка температуры изменена';
            END_IF;
        E_Gateway_Command_Type.CMD_SET_VENT: // Управление вентиляцией
            // Пример: изменение скорости притока
            VO_Set_Vent_Req := TRUE;
            VO_Target_Vent_Speed := TO_BYTE(L_Process_Command.target_value);
            VO_HMI_Status_Message := 'Gateway: Уставка вентиляции изменена';
        E_Gateway_Command_Type.CMD_TELEGRAM_MSG: // Отправка сообщения в Telegram
            VO_Telegram_Msg := L_Process_Command.telegram_msg;
            VO_Send_Telegram := TRUE;
            VO_HMI_Status_Message := 'Gateway: Сообщение Telegram отправлено';

        E_Gateway_Command_Type.CMD_SYNC_TIME: // Синхронизация времени
            VO_Sync_Time_Req := TRUE;
            VO_New_Time_MS := TO_UDINT(L_Process_Command.target_value);
            VO_HMI_Status_Message := 'Gateway: Время синхронизировано';

        E_Gateway_Command_Type.CMD_RESET_ERRORS: // Квитирование / сброс ошибок
            VO_Reset_Errors_Req := TRUE;
            VO_HMI_Status_Message := 'Gateway: Запрос на сброс ошибок принят';

        E_Gateway_Command_Type.CMD_SET_CONFIG: // Применение конфигурации
            VO_Set_Config_Req := TRUE;
            VO_HMI_Status_Message := 'Gateway: Запрос на применение конфигурации принят';
        END_CASE;
    END_IF;
ELSE
    VO_HMI_Status_Message := 'Gateway: Ошибка CRC команды';
END_IF;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Gateway_Interface <<<
