FUNCTION_BLOCK FB_Redundancy_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT; // Системное время (мс)
    VI_Local_PLC_ID : BYTE; // 1 = ПЛК А, 2 = ПЛК B
    VI_Remote_Pulse : BOOL; // Сигнал от партнера
    VI_Remote_Is_Active : BOOL; // Статус партнера
    VI_Gateway_Ping_OK : BOOL; // Пинг до шлюза
    VI_Remote_State : ST_System_State_Snapshot; // Состояние партнера
    VI_Local_State : ST_System_State_Snapshot; // Локальное состояние
END_VAR
VAR_OUTPUT
    VO_Local_Role : E_PLC_ROLE; // Локальная роль ПЛК (Active/Standby)
    VO_Local_Pulse : BOOL; // Локальный сигнал пульса для партнера
    VO_Sync_Data_Req : BOOL; // Запрос на синхронизацию данных
    VO_Status_Msg : STRING(200); // Строковое сообщение о статусе
    VO_Synced_State : ST_System_State_Snapshot; // Синхронизированное состояние
    VO_State_Updated : BOOL; // Флаг: Состояние было обновлено
END_VAR
VAR
    L_Heartbeat : FB_PLC_Heartbeat;
    L_Pulse_Timer : FB_System_Timer;
    L_Pulse_State : BOOL;
    L_Prev_Role : E_PLC_ROLE;
    L_State_Replicator : FB_State_Replication;
END_VAR

// 1. Генерация собственного пульса (меандр 100 мс)
L_Pulse_Timer(IN := NOT L_Pulse_Timer.Q, PT := T#100ms, VI_System_Time_MS := VI_System_Time_MS);
IF L_Pulse_Timer.Q THEN
    L_Pulse_State := NOT L_Pulse_State;
END_IF;
VO_Local_Pulse := L_Pulse_State;

// 2. Определение роли через Heartbeat
L_Heartbeat(
    VI_Local_ID := VI_Local_PLC_ID,
    VI_System_Time := VI_System_Time_MS,
    VI_Remote_Pulse := VI_Remote_Pulse,
    VI_Remote_Is_Active := VI_Remote_Is_Active,
    VI_Gateway_Ping_OK := VI_Gateway_Ping_OK
);

IF L_Heartbeat.VO_Is_Active THEN
    VO_Local_Role := E_PLC_ROLE.ROLE_ACTIVE;
    VO_Status_Msg := 'ПЛК АКТИВЕН (ВЕДУЩИЙ)';
ELSE
    VO_Local_Role := E_PLC_ROLE.ROLE_STANDBY;
    VO_Status_Msg := 'ПЛК В РЕЗЕРВЕ (ВЕДОМЫЙ)';
END_IF;

// 3. Запрос на синхронизацию при переходе в ACTIVE
IF VO_Local_Role = E_PLC_ROLE.ROLE_ACTIVE AND L_Prev_Role = E_PLC_ROLE.ROLE_STANDBY THEN
    VO_Sync_Data_Req := TRUE;
ELSE
    VO_Sync_Data_Req := FALSE;
END_IF;

L_State_Replicator(
    VI_Local_Role := VO_Local_Role,
    VI_Sync_Req := VO_Sync_Data_Req,
    VI_Local_State := VI_Local_State,
    VI_Remote_State := VI_Remote_State,
    VI_System_Time_MS := VI_System_Time_MS
);
VO_Synced_State := L_State_Replicator.VO_Synced_State;
VO_State_Updated := L_State_Replicator.VO_State_Updated;

L_Prev_Role := VO_Local_Role;
// >>> BULK_SYNC_ANCHOR: FB_Redundancy_Manager <<<
END_FUNCTION_BLOCK
