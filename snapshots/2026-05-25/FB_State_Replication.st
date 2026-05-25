FUNCTION_BLOCK FB_State_Replication
VAR_INPUT
    VI_Local_Role : E_PLC_ROLE; // Локальная роль ПЛК (Active/Standby)
    VI_Sync_Req : BOOL; // Запрос на принудительную синхронизацию
    VI_Local_State : ST_System_State_Snapshot; // Локальное состояние системы
    VI_Remote_State : ST_System_State_Snapshot; // Состояние системы партнера
    VI_System_Time_MS : UDINT; // Системное время (мс)
END_VAR
VAR_OUTPUT
    VO_State_Updated : BOOL; // Флаг: Состояние было обновлено
    VO_Synced_State : ST_System_State_Snapshot; // Синхронизированное состояние
END_VAR
VAR
    L_Sync_In_Progress : BOOL;
    L_Last_Sync_Time : UDINT;
    L_Periodic_Sync_Req : BOOL;
    L_Elapsed_Time : UDINT;
END_VAR

// Периодическая синхронизация (каждые 5 секунд)
L_Elapsed_Time := (SEL(VI_System_Time_MS >= L_Last_Sync_Time, VI_System_Time_MS - L_Last_Sync_Time, (4294967295 - L_Last_Sync_Time) + VI_System_Time_MS + 1));

IF L_Elapsed_Time > 5000 THEN
    L_Periodic_Sync_Req := TRUE;
    L_Last_Sync_Time := VI_System_Time_MS;
ELSE
    L_Periodic_Sync_Req := FALSE;
END_IF;

// State Replication Logic
// Синхронизация состояния между ПЛК (ТЗ 8.2)
IF (VI_Sync_Req OR L_Periodic_Sync_Req) AND NOT L_Sync_In_Progress THEN
    L_Sync_In_Progress := TRUE;
    
    // Разрешение конфликтов на основе версии состояния
    IF VI_Remote_State.Version > VI_Local_State.Version THEN
        VO_Synced_State := VI_Remote_State;
        VO_State_Updated := TRUE;
    ELSIF VI_Remote_State.Version = VI_Local_State.Version THEN
        // Если версии равны, приоритет у ведущего ПЛК
        IF VI_Local_Role = E_PLC_ROLE.ROLE_STANDBY THEN
            VO_Synced_State := VI_Remote_State;
            VO_State_Updated := TRUE;
        ELSE
            VO_Synced_State := VI_Local_State;
            VO_State_Updated := FALSE;
        END_IF;
    ELSE
        VO_Synced_State := VI_Local_State;
        VO_State_Updated := FALSE;
    END_IF;
ELSIF NOT (VI_Sync_Req OR L_Periodic_Sync_Req) THEN
    L_Sync_In_Progress := FALSE;
    VO_State_Updated := FALSE;
    VO_Synced_State := VI_Local_State;
END_IF;
END_FUNCTION_BLOCK
