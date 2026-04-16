FUNCTION_BLOCK FB_PLC_Heartbeat
VAR_INPUT
    VI_Local_ID : BYTE; // Идентификатор данного ПЛК (1 - ПЛК А, 2 - ПЛК B)
    VI_System_Time : UDINT; // Текущее системное время (мс)
    VI_Remote_Pulse : BOOL; // Сигнал пульса от партнерского ПЛК
    VI_Remote_Is_Active : BOOL; // Статус активности партнерского ПЛК (ТЗ 8.3)
    VI_Gateway_Ping_OK : BOOL; // Флаг доступности сетевого шлюза (ТЗ 8.3)
END_VAR
VAR_OUTPUT
    VO_Is_Active : BOOL; // Выход: Данный ПЛК является ведущим (Active)
    VO_RTT_MS : UDINT; // Текущая задержка связи между ПЛК (Round Trip Time)
    VO_Loss_Count : UDINT; // Счетчик потерь пакетов связи (ТЗ 8.4)
    VO_Max_RTT : UDINT; // Максимальная зафиксированная задержка связи
END_VAR
VAR
    L_Last_Pulse : BOOL; // Предыдущее состояние сигнала пульса
    L_Last_Pulse_Time : UDINT; // Время последнего изменения сигнала пульса
    L_Timeout : UDINT := 500; // Порог таймаута связи (500 мс по ТЗ 8.1)
    L_Pulse_Send_Time : UDINT; // Время отправки собственного пульса
    L_Last_Loss_Time : UDINT; // Время последней фиксации потери связи
    L_Elapsed_Time : UDINT;
END_VAR

// Вспомогательная функция для безопасного вычисления разницы времени
L_Elapsed_Time := (VI_System_Time - L_Last_Pulse_Time);

// 1. Мониторинг "сердцебиения" и расчет сетевых задержек (ТЗ 8.4)
IF VI_Remote_Pulse <> L_Last_Pulse THEN
    // Вычисляем время между изменениями сигнала
    VO_RTT_MS := L_Elapsed_Time;
    // Фиксируем пиковые задержки для диагностики сети
    IF VO_RTT_MS > VO_Max_RTT THEN VO_Max_RTT := VO_RTT_MS; END_IF;
    L_Last_Pulse := VI_Remote_Pulse;
    L_Last_Pulse_Time := VI_System_Time;
    L_Elapsed_Time := 0; // Сбрасываем после обновления
END_IF;

// Подсчет статистики потерь связи (ТЗ 8.4)
IF L_Elapsed_Time > L_Timeout THEN
    IF (VI_System_Time - L_Last_Loss_Time) >= 1000 THEN
        VO_Loss_Count := VO_Loss_Count + 1;
        L_Last_Loss_Time := VI_System_Time;
    END_IF;
ELSE
    L_Last_Loss_Time := VI_System_Time;
END_IF;

// 2. Логика определения роли (Active/Standby) и предотвращение Split-Brain (ТЗ 8.3)
// Уровень 1: Проверка наличия связи с партнером
IF L_Elapsed_Time < L_Timeout THEN
    // Связь есть: Договариваемся о ролях на основе приоритета ID
    IF VI_Local_ID = 1 THEN
        VO_Is_Active := TRUE; // ПЛК А всегда активен при наличии связи
    ELSE
        VO_Is_Active := NOT VI_Remote_Is_Active; // ПЛК B активен только если А не активен
    END_IF;
ELSE
    // Связи нет: Пытаемся определить, кто из нас "живее"
    // Уровень 3: Если связи с партнером нет, проверяем доступность внешнего шлюза
    IF VI_Local_ID = 1 THEN
        // ПЛК А становится активным всегда при потере связи с партнером (fallback)
        VO_Is_Active := TRUE;
    ELSE
        // ПЛК B ждет таймаут удержания роли (2 секунды), прежде чем стать активным
        IF L_Elapsed_Time >= 2000 THEN
            // ПЛК B берет управление если он видит шлюз, а связи с А нет.
            // Если шлюз недоступен, B ждет дольше (fallback).
            IF VI_Gateway_Ping_OK THEN
                VO_Is_Active := TRUE;
            ELSIF L_Elapsed_Time >= 5000 THEN
                VO_Is_Active := TRUE; // Fallback: ПЛК А мертв и шлюз мертв
            ELSE
                VO_Is_Active := FALSE;
            END_IF;
        ELSE
            VO_Is_Active := FALSE;
        END_IF;
    END_IF;
END_IF;