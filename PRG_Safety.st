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
END_VAR

// Edge detection (inputs only)
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

// Intent reset
GVL_INTENT_SAFETY.I_Source_Valid := TRUE;
GVL_INTENT_SAFETY.I_Last_Update_MS := GVL_STATUS.G_System_Time_MS;
GVL_INTENT_SAFETY.I_Fire_Alarm_Active := FALSE;
GVL_INTENT_SAFETY.I_Gas_Alarm_Active := FALSE;
GVL_INTENT_SAFETY.I_Leak_Alarm_Active := FALSE;
GVL_INTENT_SAFETY.I_CO_Warning_Active := FALSE;
GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := FALSE;
GVL_INTENT_SAFETY.I_Freeze_Protection_Required := FALSE;
GVL_INTENT_SAFETY.I_Evacuation_Mode_Active := FALSE;
GVL_INTENT_SAFETY.I_Gas_Close_Required := FALSE;
GVL_INTENT_SAFETY.I_Boiler_Stop_Required := FALSE;
GVL_INTENT_SAFETY.I_Vent_Stop_Required := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_Supply_80 := FALSE;
GVL_INTENT_SAFETY.I_Vent_Force_Exhaust_100 := FALSE;
GVL_INTENT_SAFETY.I_Water_Main_Close_Required := FALSE;
GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed := FALSE;
GVL_INTENT_SAFETY.I_Water_Recovery_Target_Zone := 0;
GVL_INTENT_SAFETY.I_Lock_1_Force_Open := FALSE;
GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block := FALSE;
GVL_INTENT_SAFETY.I_Lock_2_Force_Open := FALSE;
GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block := FALSE;

// FBs (detection only)
fbWaterLeakageManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Sensors := GVL_STATE.G_Water_Sensors,
    VI_Config := GVL_CONFIG.G_HMI_Flood_Config,
    VO_Status_Msg => GVL_STATUS.G_Flood_Status_Msg,
    VO_Leak_Detected => GVL_HEALTH_BRIDGE.G_Leak_Detected,
    VO_Leak_Warning_Level => GVL_HEALTH_BRIDGE.G_Leak_Warning_Level
);
GVL_INTENT_SAFETY.I_Leak_Alarm_Active := GVL_HEALTH_BRIDGE.G_Leak_Detected;

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
GVL_INTENT_SAFETY.I_Fire_Alarm_Active := GVL_HEALTH_BRIDGE.G_Smoke_Detected;
GVL_INTENT_SAFETY.I_Gas_Alarm_Active := GVL_HEALTH_BRIDGE.G_Gas_Detected OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level;
GVL_INTENT_SAFETY.I_CO_Warning_Active := GVL_HEALTH_BRIDGE.G_CO_Warning_Level;

// Core safety -> intent only
IF GVL_STATE.G_Safety_Smoke_Latched THEN
    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Evacuation_Mode_Active := TRUE;
    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Lock_1_Force_Open := TRUE;
    GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block := TRUE;
    GVL_INTENT_SAFETY.I_Lock_2_Force_Open := TRUE;
    GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block := TRUE;
END_IF;

IF GVL_STATE.G_Safety_Gas_Latched THEN
    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Gas_Close_Required := TRUE;
    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 := TRUE;
END_IF;

IF GVL_HEALTH_BRIDGE.G_CO_Warning_Level OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN
    GVL_INTENT_SAFETY.I_Vent_Force_Supply_80 := TRUE;
END_IF;

IF GVL_STATE.G_Safety_Leak_Latched THEN
    GVL_INTENT_SAFETY.I_Water_Main_Close_Required := TRUE;
END_IF;

// Test/Operator flows -> intent only
IF L_CMD_Water_Valve_Test_Open_Edge THEN
    L_Water_Test_Active := TRUE;
    L_Water_Test_Deadline := GVL_STATUS.G_System_Time_MS + 60000;
END_IF;

IF L_Water_Test_Active THEN
    IF GVL_STATUS.G_System_Time_MS >= L_Water_Test_Deadline THEN
        L_Water_Test_Active := FALSE;
        GVL_INTENT_SAFETY.I_Water_Main_Close_Required := TRUE;
    END_IF;
END_IF;

IF L_CMD_Gas_Valve_Test_Open_Edge THEN
    L_Gas_Test_Active := TRUE;
    L_Gas_Test_Deadline := GVL_STATUS.G_System_Time_MS + 60000;
END_IF;

IF L_Gas_Test_Active THEN
    IF GVL_STATUS.G_System_Time_MS >= L_Gas_Test_Deadline THEN
        L_Gas_Test_Active := FALSE;
        GVL_INTENT_SAFETY.I_Gas_Close_Required := TRUE;
    END_IF;
END_IF;

// Freeze
IF GVL_STATE.G_Freeze_Hardware_Degraded THEN
    GVL_INTENT_SAFETY.I_Freeze_Protection_Required := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Safety <<<
