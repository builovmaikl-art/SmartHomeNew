FUNCTION_BLOCK FB_IO_Module_Watchdog
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Module_ID : BYTE;
    VI_Heartbeat_Signal : BOOL; // Сигнал от модуля (например, мигающий бит)
    VI_Timeout_MS : UDINT := 2000; // Таймаут 2 секунды по умолчанию
END_VAR
VAR_OUTPUT
    VO_Module_Online : BOOL;
    VO_Error_Active : BOOL;
END_VAR
VAR
    L_Last_Heartbeat_State : BOOL;
    L_Last_Heartbeat_Time : UDINT;
    L_Elapsed_Time : UDINT;
END_VAR

// Отслеживание изменения сигнала
IF VI_Heartbeat_Signal <> L_Last_Heartbeat_State THEN
    L_Last_Heartbeat_Time := VI_System_Time_MS;
    L_Last_Heartbeat_State := VI_Heartbeat_Signal;
END_IF;

// Проверка таймаута
L_Elapsed_Time := (SEL(VI_System_Time_MS >= L_Last_Heartbeat_Time, VI_System_Time_MS - L_Last_Heartbeat_Time, (4294967295 - L_Last_Heartbeat_Time) + VI_System_Time_MS + 1));

IF L_Elapsed_Time > VI_Timeout_MS THEN
    VO_Module_Online := FALSE;
    VO_Error_Active := TRUE;
ELSE
    VO_Module_Online := TRUE;
    VO_Error_Active := FALSE;
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_IO_Module_Watchdog <<<
END_FUNCTION_BLOCK
