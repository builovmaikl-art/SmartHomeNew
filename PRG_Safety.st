PROGRAM PRG_Safety
VAR
    L_CMD_Water_Selective_Recover_Prev : BOOL;
    L_CMD_Water_Selective_Recover_Edge : BOOL;
    L_CMD_Gas_Selective_Recover_Prev : BOOL;
    L_CMD_Gas_Selective_Recover_Edge : BOOL;
    L_CMD_Water_Valve_Test_Open_Prev : BOOL;
    L_CMD_Water_Valve_Test_Open_Edge : BOOL;
    L_CMD_Water_Valve_Test_Close_Prev : BOOL;
    L_CMD_Water_Valve_Test_Close_Edge : BOOL;
    L_CMD_Water_Valve_Test_Confirm_Prev : BOOL;
    L_CMD_Water_Valve_Test_Confirm_Edge : BOOL;
    L_CMD_Gas_Valve_Test_Open_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Open_Edge : BOOL;
    L_CMD_Gas_Valve_Test_Close_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Close_Edge : BOOL;
    L_CMD_Gas_Valve_Test_Confirm_Prev : BOOL;
    L_CMD_Gas_Valve_Test_Confirm_Edge : BOOL;
    fbWaterLeakageManager : FB_Water_Leakage_Manager;
    fbGasSmokeManager : FB_Gas_Smoke_Manager;
    L_i : INT;
    L_Water_Test_Active : BOOL;
    L_Water_Test_Deadline : UDINT;
    L_Gas_Test_Active : BOOL;
    L_Gas_Test_Deadline : UDINT;
    L_Water_Valve_Last_Exercise_MS : ARRAY[1..32] OF UDINT;
    L_Water_Valve_Exercise_Until_MS : ARRAY[1..32] OF UDINT;
    L_Water_Zone_Close_Last_Retry_MS : ARRAY[1..32] OF UDINT;
END_VAR

// === COMMAND EDGE PROCESSING ===
L_CMD_Water_Selective_Recover_Edge := GVL_COMMAND.CMD_Water_Selective_Recover AND NOT L_CMD_Water_Selective_Recover_Prev;
L_CMD_Gas_Selective_Recover_Edge := GVL_COMMAND.CMD_Gas_Selective_Recover AND NOT L_CMD_Gas_Selective_Recover_Prev;
L_CMD_Water_Valve_Test_Open_Edge := GVL_COMMAND.CMD_Water_Valve_Test_Open AND NOT L_CMD_Water_Valve_Test_Open_Prev;
L_CMD_Water_Valve_Test_Close_Edge := GVL_COMMAND.CMD_Water_Valve_Test_Close AND NOT L_CMD_Water_Valve_Test_Close_Prev;
L_CMD_Water_Valve_Test_Confirm_Edge := GVL_COMMAND.CMD_Water_Valve_Test_Confirm AND NOT L_CMD_Water_Valve_Test_Confirm_Prev;
L_CMD_Gas_Valve_Test_Open_Edge := GVL_COMMAND.CMD_Gas_Valve_Test_Open AND NOT L_CMD_Gas_Valve_Test_Open_Prev;
L_CMD_Gas_Valve_Test_Close_Edge := GVL_COMMAND.CMD_Gas_Valve_Test_Close AND NOT L_CMD_Gas_Valve_Test_Close_Prev;
L_CMD_Gas_Valve_Test_Confirm_Edge := GVL_COMMAND.CMD_Gas_Valve_Test_Confirm AND NOT L_CMD_Gas_Valve_Test_Confirm_Prev;

L_CMD_Water_Selective_Recover_Prev := GVL_COMMAND.CMD_Water_Selective_Recover;
L_CMD_Gas_Selective_Recover_Prev := GVL_COMMAND.CMD_Gas_Selective_Recover;
L_CMD_Water_Valve_Test_Open_Prev := GVL_COMMAND.CMD_Water_Valve_Test_Open;
L_CMD_Water_Valve_Test_Close_Prev := GVL_COMMAND.CMD_Water_Valve_Test_Close;
L_CMD_Water_Valve_Test_Confirm_Prev := GVL_COMMAND.CMD_Water_Valve_Test_Confirm;
L_CMD_Gas_Valve_Test_Open_Prev := GVL_COMMAND.CMD_Gas_Valve_Test_Open;
L_CMD_Gas_Valve_Test_Close_Prev := GVL_COMMAND.CMD_Gas_Valve_Test_Close;
L_CMD_Gas_Valve_Test_Confirm_Prev := GVL_COMMAND.CMD_Gas_Valve_Test_Confirm;

// 7.5 Система защиты от протечек
fbWaterLeakageManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Sensors := GVL_STATE.G_Water_Sensors,
    VI_Config := GVL_CONFIG.G_HMI_Flood_Config,
    VO_Status_Msg => GVL_STATUS.G_Flood_Status_Msg,
    VO_Leak_Detected => GVL_HEALTH_BRIDGE.G_Leak_Detected,
    VO_Leak_Warning_Level => GVL_HEALTH_BRIDGE.G_Leak_Warning_Level
);
GVL_ALARM.G_Flood_Alarm_Active := GVL_HEALTH_BRIDGE.G_Leak_Detected;

// 8. Пожарная и газовая безопасность (Приоритет 1)
fbGasSmokeManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Methane_LEL := GVL_Safety_Selector.G_Methane_Effective_Array,
    VI_CO_PPM := GVL_Safety_Selector.G_CO_Effective_Array,
    VI_Smoke_Sensors := GVL_Safety_Selector.G_Smoke_Effective_Array,
    VI_Mute_Request := GVL_CONFIG.G_HMI_Mute_Alarm,
    VO_Smoke_Detected => GVL_HEALTH_BRIDGE.G_Smoke_Detected,
    VO_Gas_Detected => GVL_HEALTH_BRIDGE.G_Gas_Detected,
    VO_CO_Warning_Level => GVL_HEALTH_BRIDGE.G_CO_Warning_Level,
    VO_CO_Alarm_Level => GVL_HEALTH_BRIDGE.G_CO_Alarm_Level,
    VO_Status_Msg => GVL_STATUS.G_Gas_Status_Msg
);
GVL_ALARM.G_Fire_Alarm_Active := GVL_HEALTH_BRIDGE.G_Smoke_Detected;
GVL_ALARM.G_Gas_Alarm_Active := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level;

// ... (оставшаяся логика без изменений) ...

// === SYSTEM MODE OWNERSHIP ===
// PRG_Safety must publish safety facts, latched conditions, diagnostics and
// safety-related commands only.
// System mode is owned exclusively by PRG_System via:
// FB_System_Health -> FB_State_Manager -> GVL_STATE.G_System_Mode.
// Any mode arbitration logic must stay out of PRG_Safety to preserve a single
// source of truth for runtime mode.

// >>> BULK_SYNC_ANCHOR: PRG_Safety <<<
