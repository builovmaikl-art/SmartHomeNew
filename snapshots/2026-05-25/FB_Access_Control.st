FUNCTION_BLOCK FB_Access_Control
VAR_INPUT
    VI_System_Time_MS   : UDINT; // Системное время (мс)
    VI_IsActivePLC      : BOOL; // Флаг: Данный ПЛК является ведущим (Active)
    VI_Armed            : BOOL; // Статус: Система безопасности находится под охраной
    VI_System_Mode      : E_System_Operating_Mode; // Агрегированный режим работы системы
    
    // Команды управления от HMI (через GVL_CONFIG)
    VI_Gate_Open_Req    : BOOL; // Запрос пользователя на открытие въездных ворот
    VI_Wicket_Open_Req  : BOOL; // Запрос пользователя на открытие калитки
    VI_Lock_1_Open_Req  : BOOL; // Запрос на разблокировку основного электрозамка дома
    VI_Lock_1_Close_Req : BOOL; // Запрос на блокировку основного электрозамка дома
    VI_Lock_2_Open_Req  : BOOL; // Запрос на разблокировку дополнительного электрозамка
    VI_Lock_2_Close_Req : BOOL; // Запрос на блокировку дополнительного электрозамка
    
    // Авторизация
    VI_PIN_Code         : STRING(4); // ПИН-код для авторизации
    VI_RFID_Tag         : STRING(20); // RFID/NFC метка для авторизации
    
    // Настройки из конфигурации безопасности (длительности импульсов)
    VI_Config           : ST_Security_Global_Config;
END_VAR
VAR_IN_OUT
    VI_Access_Codes     : ARRAY[1..GVL_CONSTANTS.C_MAX_ACCESS_CODES] OF DWORD;
    VI_RFID_Tags        : ARRAY[1..GVL_CONSTANTS.C_MAX_ACCESS_CODES] OF STRING(20);
END_VAR
VAR_OUTPUT
    VO_Gate_Open        : BOOL; // Выход: Импульс на открытие ворот (сухой контакт)
    VO_Wicket_Open      : BOOL; // Выход: Импульс на открытие калитки (электрозащелка)
    VO_Lock_1_Open      : BOOL; // Выход: Импульс на разблокировку замка №1
    VO_Lock_1_Close     : BOOL; // Выход: Импульс на блокировку замка №1
    VO_Lock_2_Open      : BOOL; // Выход: Импульс на разблокировку замка №2
    VO_Lock_2_Close     : BOOL; // Выход: Импульс на блокировку замка №2
END_VAR
VAR
    // Таймеры для формирования импульсов управления заданной длительности
    L_Gate_Timer        : TP; // Таймер импульса ворот
    L_Wicket_Timer      : TP; // Таймер импульса калитки
    L_Lock_1_Open_T     : TP; // Таймер открытия замка №1
    L_Lock_1_Close_T    : TP; // Таймер закрытия замка №1
    L_Lock_2_Open_T     : TP; // Таймер открытия замка №2
    L_Lock_2_Close_T    : TP; // Таймер закрытия замка №2
    
    L_Prev_Armed        : BOOL; // Предыдущее состояние охраны (для детекции фронта постановки)
    L_Auto_Lock_Req     : BOOL; // Флаг автоматического закрытия всех замков при постановке на охрану
    
    R_Trig_Gate         : R_TRIG;
    R_Trig_Wicket       : R_TRIG;
    R_Trig_Lock_1_O     : R_TRIG;
    R_Trig_Lock_1_C     : R_TRIG;
    R_Trig_Lock_2_O     : R_TRIG;
    R_Trig_Lock_2_C     : R_TRIG;
    
    fbAccessCode        : FB_AccessCode_Manager;
    L_Valid_PIN         : BOOL;
END_VAR

// Если ПЛК находится в режиме Standby (резерв), он не должен управлять выходами
IF NOT VI_IsActivePLC THEN
    RETURN;
END_IF;

IF VI_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP THEN
    VO_Gate_Open := FALSE;
    VO_Wicket_Open := FALSE;
    VO_Lock_1_Open := FALSE;
    VO_Lock_2_Open := FALSE;
    RETURN;
END_IF;

// 1. Логика автоматического закрытия замков при постановке на охрану (ТЗ 3.0)
// При переходе системы в режим "Охрана" принудительно блокируем все замки
IF VI_Armed AND NOT L_Prev_Armed THEN
    L_Auto_Lock_Req := TRUE;
END_IF;
L_Prev_Armed := VI_Armed;

// Детекторы фронта для команд
R_Trig_Gate(CLK := VI_Gate_Open_Req);
R_Trig_Wicket(CLK := VI_Wicket_Open_Req);
R_Trig_Lock_1_O(CLK := VI_Lock_1_Open_Req);
R_Trig_Lock_1_C(CLK := VI_Lock_1_Close_Req OR L_Auto_Lock_Req);
R_Trig_Lock_2_O(CLK := VI_Lock_2_Open_Req);
R_Trig_Lock_2_C(CLK := VI_Lock_2_Close_Req OR L_Auto_Lock_Req);

// Проверка PIN-кода или RFID-метки через менеджер кодов
fbAccessCode(
    VI_System_Time_MS := VI_System_Time_MS,
    VI_IsActivePLC := VI_IsActivePLC,
    VI_Code_To_Check := VI_PIN_Code,
    VI_RFID_To_Check := VI_RFID_Tag,
    VI_Access_Codes := VI_Access_Codes,
    VI_RFID_Tags := VI_RFID_Tags,
    VO_Code_Valid => L_Valid_PIN
);

// 2. Формирование импульсов управления исполнительными механизмами (Pulse Control)
// Открытие ворот и калитки требует валидного ПИН-кода или RFID-метки, если система под охраной
L_Gate_Timer(IN := R_Trig_Gate.Q AND (NOT VI_Armed OR L_Valid_PIN), PT := TO_TIME(VI_Config.gate_open_pulse_ms));
VO_Gate_Open := L_Gate_Timer.Q;

L_Wicket_Timer(IN := R_Trig_Wicket.Q AND (NOT VI_Armed OR L_Valid_PIN), PT := TO_TIME(VI_Config.wicket_open_pulse_ms));
VO_Wicket_Open := L_Wicket_Timer.Q;

L_Lock_1_Open_T(IN := R_Trig_Lock_1_O.Q AND (NOT VI_Armed OR L_Valid_PIN), PT := TO_TIME(VI_Config.lock_open_pulse_ms));
VO_Lock_1_Open := L_Lock_1_Open_T.Q;

L_Lock_1_Close_T(IN := R_Trig_Lock_1_C.Q, PT := TO_TIME(VI_Config.lock_close_pulse_ms));
VO_Lock_1_Close := L_Lock_1_Close_T.Q;

L_Lock_2_Open_T(IN := R_Trig_Lock_2_O.Q AND (NOT VI_Armed OR L_Valid_PIN), PT := TO_TIME(VI_Config.lock_open_pulse_ms));
VO_Lock_2_Open := L_Lock_2_Open_T.Q;

L_Lock_2_Close_T(IN := R_Trig_Lock_2_C.Q, PT := TO_TIME(VI_Config.lock_close_pulse_ms));
VO_Lock_2_Close := L_Lock_2_Close_T.Q;

// Сброс флага автоматического закрытия
IF L_Auto_Lock_Req THEN
    L_Auto_Lock_Req := FALSE;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Access_Control <<<
END_FUNCTION_BLOCK
