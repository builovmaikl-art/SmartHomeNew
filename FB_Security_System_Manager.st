FUNCTION_BLOCK FB_Security_System_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_IsActivePLC : BOOL; // Флаг: Данный ПЛК является ведущим
    VI_Arm_Request : BOOL; // Запрос на постановку под охрану
    VI_Disarm_Request : BOOL; // Запрос на снятие с охраны
    VI_PIN_Code : STRING(4); // ПИН-код для авторизации
    VI_RFID_Tag : STRING(20); // RFID/NFC метка для авторизации
    VI_2FA_Code : STRING(6); // Код двухфакторной аутентификации
    VI_Config : ST_Security_Global_Config; // Конфигурация охранной системы
    VI_Current_TOD : TOD; // Текущее время суток (от FB_Astro_Timer)
END_VAR
VAR_IN_OUT
    VI_Motion_Sensors : ARRAY[1..16] OF BOOL; // Датчики движения
    VI_Door_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_DOOR_SENSORS] OF BOOL; // Датчики открытия дверей (герконы)
    VI_Window_Sensors : ARRAY[1..16] OF BOOL; // Датчики открытия окон (герконы)
    VI_Bypass_Motion : ARRAY[1..16] OF BOOL; // Байпас датчиков движения
    VI_Bypass_Doors : ARRAY[1..GVL_CONSTANTS.C_MAX_DOOR_SENSORS] OF BOOL; // Байпас дверей
    VI_Bypass_Windows : ARRAY[1..16] OF BOOL; // Байпас окон
END_VAR
VAR_OUTPUT
    VO_Armed : BOOL; // Статус: Система под охраной
    VO_Alarm_Active : BOOL; // Статус: Тревога активна
    VO_Siren_Active : BOOL; // Команда: Включить сирену
    VO_Status_Msg : STRING(200); // Строковое сообщение о статусе
    VO_Send_Code_Req : BOOL; // Запрос на отправку кода 2FA
    VO_Code_To_Send : STRING(6); // Сгенерированный код 2FA для отправки
END_VAR
VAR
    L_i : INT;
    L_Any_Sensor_Active : BOOL;
    L_Arm_Delay_Timer : FB_System_Timer;
    L_Alarm_Delay_Timer : FB_System_Timer;
    L_Arming_In_Progress : BOOL;
    L_Valid_PIN : BOOL;
    fbAccessCode : FB_AccessCode_Manager;
    fbTwoFactor : FB_TwoFactor_Auth;
    L_2FA_Required : BOOL;
    L_Disarm_Pending : BOOL;
    L_Reset_2FA : BOOL;
    L_Auto_Arm_Trigger : BOOL;
    R_Trig_Auto_Arm : R_TRIG;
END_VAR

IF NOT VI_IsActivePLC THEN
    VO_Armed := FALSE;
    VO_Alarm_Active := FALSE;
    VO_Siren_Active := FALSE;
    VO_Send_Code_Req := FALSE;
    VO_Code_To_Send := '';
    VO_Status_Msg := 'Охрана: резервный ПЛК';
    L_Arming_In_Progress := FALSE;
    L_Disarm_Pending := FALSE;
    L_2FA_Required := FALSE;
    L_Reset_2FA := FALSE;
    RETURN;
END_IF;

// 1. Проверка PIN-кода или RFID-метки через менеджер кодов
fbAccessCode(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Code_To_Check := VI_PIN_Code,
    VI_RFID_To_Check := VI_RFID_Tag,
    VI_Access_Codes := GVL_RETAIN.G_Access_Codes,
    VI_RFID_Tags := GVL_RETAIN.G_RFID_Tags,
    VO_Code_Valid => L_Valid_PIN
);

// 2. Логика постановки на охрану (с задержкой на выход)
L_Auto_Arm_Trigger := FALSE;
IF VI_Config.auto_arm_enabled THEN
    IF VI_Current_TOD >= UDINT_TO_TOD(VI_Config.auto_arm_time_ms) THEN
        L_Auto_Arm_Trigger := TRUE;
    END_IF;
END_IF;
R_Trig_Auto_Arm(CLK := L_Auto_Arm_Trigger);

IF ((VI_Arm_Request AND L_Valid_PIN) OR R_Trig_Auto_Arm.Q) AND NOT VO_Armed AND NOT L_Arming_In_Progress THEN
    // Проверка, что все двери/окна закрыты перед постановкой (с учетом байпаса)
    L_Any_Sensor_Active := FALSE;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO IF VI_Door_Sensors[L_i] AND NOT VI_Bypass_Doors[L_i] THEN L_Any_Sensor_Active := TRUE; END_IF; END_FOR;
    FOR L_i := 1 TO 16 DO IF VI_Window_Sensors[L_i] AND NOT VI_Bypass_Windows[L_i] THEN L_Any_Sensor_Active := TRUE; END_IF; END_FOR;
    
    IF NOT L_Any_Sensor_Active THEN
        L_Arming_In_Progress := TRUE;
        VO_Status_Msg := 'Постановка на охрану. Покиньте помещение.';
    ELSE
        VO_Status_Msg := 'Ошибка постановки: Открыты двери или окна';
    END_IF;
END_IF;

L_Arm_Delay_Timer(IN := L_Arming_In_Progress, PT := TO_TIME(VI_Config.exit_delay_seconds * 1000), VI_System_Time_MS := VI_System_Time_MS);
IF L_Arm_Delay_Timer.Q THEN
    L_Arming_In_Progress := FALSE;
    VO_Armed := TRUE;
    VO_Status_Msg := 'Система под охраной';
END_IF;

// 3. Логика снятия с охраны с 2FA
IF VI_Disarm_Request AND L_Valid_PIN AND VO_Armed THEN
    IF VI_Config.enable_2fa THEN
        L_Disarm_Pending := TRUE;
        L_2FA_Required := TRUE;
        VO_Status_Msg := 'Ожидание 2FA для снятия с охраны';
    ELSE
        // Снятие без 2FA
        VO_Armed := FALSE;
        VO_Alarm_Active := FALSE;
        VO_Siren_Active := FALSE;
        L_Arming_In_Progress := FALSE;
        VO_Status_Msg := 'Система снята с охраны';
    END_IF;
END_IF;

fbTwoFactor(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_Start_Auth := L_2FA_Required,
    VI_Method := E_TwoFactor_Method.TF_METHOD_TOTP, // Для примера
    VI_User_Code := VI_2FA_Code, // Используем отдельный вход для 2FA кода
    VI_Reset_Success := L_Reset_2FA
);

VO_Send_Code_Req := fbTwoFactor.VO_Send_Code_Req;
VO_Code_To_Send := fbTwoFactor.VO_Code_To_Send;

IF L_Disarm_Pending AND fbTwoFactor.VO_State.Is_Success THEN
    VO_Armed := FALSE;
    VO_Alarm_Active := FALSE;
    VO_Siren_Active := FALSE;
    L_Arming_In_Progress := FALSE;
    L_Disarm_Pending := FALSE;
    L_2FA_Required := FALSE;
    L_Reset_2FA := TRUE;
    VO_Status_Msg := 'Система снята с охраны';
ELSIF L_Disarm_Pending AND fbTwoFactor.VO_State.Is_Locked THEN
    L_Disarm_Pending := FALSE;
    L_2FA_Required := FALSE;
    L_Reset_2FA := FALSE;
    VO_Status_Msg := 'Ошибка 2FA: Превышено количество попыток';
ELSE
    L_Reset_2FA := FALSE;
END_IF;

// 4. Логика тревоги (с задержкой на вход)
IF VO_Armed THEN
    L_Any_Sensor_Active := FALSE;
    FOR L_i := 1 TO 16 DO IF VI_Motion_Sensors[L_i] AND NOT VI_Bypass_Motion[L_i] THEN L_Any_Sensor_Active := TRUE; END_IF; END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO IF VI_Door_Sensors[L_i] AND NOT VI_Bypass_Doors[L_i] THEN L_Any_Sensor_Active := TRUE; END_IF; END_FOR;
    FOR L_i := 1 TO 16 DO IF VI_Window_Sensors[L_i] AND NOT VI_Bypass_Windows[L_i] THEN L_Any_Sensor_Active := TRUE; END_IF; END_FOR;
    
    // Защелкиваем факт нарушения периметра, чтобы кратковременное срабатывание датчика не сбрасывало таймер
    IF L_Any_Sensor_Active THEN
        L_Alarm_Delay_Timer.IN := TRUE;
    END_IF;
    
    L_Alarm_Delay_Timer(PT := TO_TIME(VI_Config.entry_delay_seconds * 1000), VI_System_Time_MS := VI_System_Time_MS);
    
    IF L_Alarm_Delay_Timer.Q THEN
        VO_Alarm_Active := TRUE;
        VO_Siren_Active := TRUE;
        VO_Status_Msg := 'ТРЕВОГА! Нарушение периметра';
    ELSIF L_Alarm_Delay_Timer.IN THEN
        VO_Status_Msg := 'Внимание! Введите PIN-код для отмены тревоги';
    END_IF;
ELSE
    L_Alarm_Delay_Timer(IN := FALSE, PT := T#0s, VI_System_Time_MS := VI_System_Time_MS); // Сброс таймера при снятии с охраны
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Security_System_Manager <<<
