PROGRAM PRG_Safety
VAR
    fbWaterLeakageManager : FB_Water_Leakage_Manager;
    fbGasSmokeManager : FB_Gas_Smoke_Manager;
    fbOwnership : FB_Ownership_Watchdog;
    L_i : INT;
    L_Water_Group : INT;
    L_Any_Water_Leak : BOOL;
    L_Water_Main_Close : BOOL;
END_VAR

GVL_INTENT_SAFETY.I_Source_Valid := TRUE;
GVL_INTENT_SAFETY.I_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;
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
FOR L_i := 1 TO 32 DO
    GVL_INTENT_SAFETY.I_Water_Zone_Close_Required[L_i] := FALSE;
END_FOR;
GVL_INTENT_SAFETY.I_Lock_1_Force_Open := FALSE;
GVL_INTENT_SAFETY.I_Lock_1_Force_Close_Block := FALSE;
GVL_INTENT_SAFETY.I_Lock_2_Force_Open := FALSE;
GVL_INTENT_SAFETY.I_Lock_2_Force_Close_Block := FALSE;
GVL_INTENT_SAFETY.I_Test_Timeout_Gas_Close := FALSE;
GVL_INTENT_SAFETY.I_Test_Timeout_Water_Close := FALSE;

fbWaterLeakageManager(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Sensors := GVL_STATE.G_Water_Sensors,
    VI_Config := GVL_CONFIG.G_HMI_Flood_Config,
    VO_Status_Msg => GVL_STATUS.G_Flood_Status_Msg,
    VO_Leak_Detected => GVL_HEALTH_BRIDGE.G_Leak_Detected,
    VO_Leak_Warning_Level => GVL_HEALTH_BRIDGE.G_Leak_Warning_Level
);

L_Any_Water_Leak := FALSE;
L_Water_Main_Close := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO
    IF GVL_STATE.G_Flood_Alarm[L_i] THEN
        L_Any_Water_Leak := TRUE;
        L_Water_Group := TO_INT(GVL_CONFIG.G_Flood_Global_Config.sensor_to_valve_map[L_i]);

        IF (L_Water_Group >= 1) AND (L_Water_Group <= 4) THEN
            GVL_INTENT_SAFETY.I_Water_Zone_Close_Required[L_Water_Group] := TRUE;
        ELSE
            L_Water_Main_Close := TRUE;
        END_IF;

        IF L_Water_Group = 4 THEN
            L_Water_Main_Close := TRUE;
        END_IF;
    END_IF;
END_FOR;

// Four logical leak zones: 1 kitchen, 2 master bathroom,
// 3 guest bathrooms + laundry, 4 boiler/common inlet 35/36.
// WATER_LEAK mode is entered for any confirmed leak. Common inlet 35/36 close
// is required only for zone 4, invalid mapping, fallback/escalation or test timeout.
GVL_INTENT_SAFETY.I_Leak_Alarm_Active :=
    L_Any_Water_Leak OR GVL_HEALTH_BRIDGE.G_Leak_Detected;
GVL_INTENT_SAFETY.I_Water_Main_Close_Required :=
    L_Water_Main_Close
    OR GVL_Water_Isolation_Authority.G_Any_Global_Fallback_Required;

fbGasSmokeManager(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Methane_LEL := GVL_Safety_Selector.G_Methane_Effective_Array,
    VI_CO_PPM := GVL_Safety_Selector.G_CO_Effective_Array,
    VI_Smoke_Sensors := GVL_Safety_Selector.G_Smoke_Effective_Array,
    VI_Mute_Request := GVL_CONFIG.G_HMI_Mute_Alarm,
    VO_Smoke_Detected => GVL_HEALTH_BRIDGE.G_Smoke_Detected,
    VO_Gas_Detected => GVL_HEALTH_BRIDGE.G_Gas_Detected,
    VO_Methane_Warning_Level => GVL_HEALTH_BRIDGE.G_Methane_Warning_Level,
    VO_Methane_Alarm_Level => GVL_HEALTH_BRIDGE.G_Methane_Alarm_Level,
    VO_Methane_Critical_Level => GVL_HEALTH_BRIDGE.G_Methane_Critical_Level,
    VO_CO_Warning_Level => GVL_HEALTH_BRIDGE.G_CO_Warning_Level,
    VO_CO_Alarm_Level => GVL_HEALTH_BRIDGE.G_CO_Alarm_Level,
    VO_Status_Msg => GVL_STATUS.G_Gas_Status_Msg
);

GVL_INTENT_SAFETY.I_Fire_Alarm_Active := GVL_HEALTH_BRIDGE.G_Smoke_Detected;
GVL_INTENT_SAFETY.I_Gas_Alarm_Active :=
    GVL_HEALTH_BRIDGE.G_Methane_Alarm_Level
    OR GVL_HEALTH_BRIDGE.G_Methane_Critical_Level
    OR GVL_HEALTH_BRIDGE.G_CO_Alarm_Level;
GVL_INTENT_SAFETY.I_CO_Warning_Active := GVL_HEALTH_BRIDGE.G_CO_Warning_Level;

// Methane 10% LEL warning: ventilation boost only.
IF GVL_HEALTH_BRIDGE.G_Methane_Warning_Level THEN
    GVL_INTENT_SAFETY.I_Vent_Force_PV3_Boost := TRUE;
END_IF;

// Methane 20% LEL alarm or CO alarm: close gas and stop boilers.
IF GVL_HEALTH_BRIDGE.G_Methane_Alarm_Level OR
   GVL_HEALTH_BRIDGE.G_Methane_Critical_Level OR
   GVL_HEALTH_BRIDGE.G_CO_Alarm_Level THEN
    GVL_INTENT_SAFETY.I_Gas_Close_Required := TRUE;
    GVL_INTENT_SAFETY.I_Boiler_Stop_Required := TRUE;
END_IF;

// Methane 40% LEL critical: full escalation.
IF GVL_HEALTH_BRIDGE.G_Methane_Critical_Level THEN
    GVL_INTENT_SAFETY.I_System_Safe_Stop_Required := TRUE;
    GVL_INTENT_SAFETY.I_Evacuation_Mode_Active := TRUE;
    GVL_INTENT_SAFETY.I_Vent_Force_Supply_100 := TRUE;
END_IF;

// Ownership watchdog must observe authoritative safety truth, not stale
// projected GVL_STATE.G_Safety_*_Alarm compatibility fields.
fbOwnership(
    VI_Gas_Level := GVL_Safety_Selector.G_Methane_Effective_Array[GVL_CONSTANTS.C_PRIMARY_EFFECTIVE_GAS_INDEX],
    VI_Gas_Alarm := GVL_INTENT_SAFETY.I_Gas_Alarm_Active,
    VI_Leak_Alarm := GVL_INTENT_SAFETY.I_Leak_Alarm_Active,
    VI_Smoke_Alarm := GVL_HEALTH_BRIDGE.G_Smoke_Detected
);

IF fbOwnership.VO_Ownership_Violation THEN
    GVL_DEBUG_VIEW.D_Ownership_Violation := TRUE;
END_IF;

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
    GVL_INTENT_SAFETY.I_Leak_Alarm_Active := TRUE;
END_IF;

IF GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended OR
   GVL_STATUS.G_Diagnostics.Water_Close_Fault_Active THEN
    GVL_INTENT_SAFETY.I_Water_Main_Close_Required := TRUE;
    GVL_INTENT_SAFETY.I_Leak_Alarm_Active := TRUE;
END_IF;

IF GVL_STATE.G_Freeze_Hardware_Degraded THEN
    GVL_INTENT_SAFETY.I_Freeze_Protection_Required := TRUE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Safety <<<
END_PROGRAM