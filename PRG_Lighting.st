PROGRAM PRG_Lighting
VAR
    L_i : INT;
    fbLightingManager : FB_Lighting_Blinds_Manager;
    fbSocketManager : FB_Socket_Manager;
    L_Manual_Light_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BYTE;
    L_Manual_Blinds_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BYTE;
    L_Manual_Socket_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    L_Sim_Lights : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    L_Physical_Switches : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    L_Motion_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_LIGHT_ZONES] OF BOOL;
    L_Blinds_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_BLINDS] OF BYTE;
    L_Socket_Override : ARRAY[1..GVL_CONSTANTS.C_MAX_SOCKETS] OF BOOL;
    L_Wet_Zone_Light_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_WET_ZONES] OF BOOL;
    L_Wet_Zone_Any_Active : BOOL;
    L_Fire_Alarm_Active : BOOL;
    L_Security_Armed : BOOL;
    L_Security_Alarm : BOOL;
    L_Evac_Blink_Phase : UDINT;
    L_Evac_Blink_On : BOOL;
END_VAR

L_Fire_Alarm_Active := GVL_ALARM.G_Fire_Alarm_Active OR GVL_STATE.G_Safety_Smoke_Latched;
L_Security_Armed := GVL_ALARM.G_Security_Armed;
L_Security_Alarm := GVL_ALARM.G_Security_Alarm;
L_Evac_Blink_Phase := (GVL_STATUS.G_System_Time_MS / 500) MOD 2;
L_Evac_Blink_On := (L_Evac_Blink_Phase = 0);

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    IF GVL_INTENT_SYSTEM.I_Lighting_Overrides_Block OR GVL_SYSTEM_COORDINATION.G_Block_Lighting_Override THEN
        L_Manual_Light_Override[L_i] := 0;
    ELSE
        L_Manual_Light_Override[L_i] := GVL_INTENT_USER.I_Lighting_Override_32[L_i];
    END_IF;

    L_Sim_Lights[L_i] := GVL_STATE.G_Sim_Lights[L_i];
    L_Physical_Switches[L_i] := GVL_STATE.G_Physical_Switches[L_i];
    L_Motion_Sensors[L_i] := GVL_STATE.G_Motion_Sensors[L_i];

    IF GVL_INTENT_SYSTEM.I_Blinds_Overrides_Block THEN
        L_Manual_Blinds_Override[L_i] := 0;
    ELSE
        L_Manual_Blinds_Override[L_i] := GVL_INTENT_USER.I_Blinds_Override_32[L_i];
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
    L_Blinds_Override[L_i] := L_Manual_Blinds_Override[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SOCKETS DO
    IF GVL_INTENT_SYSTEM.I_Socket_Overrides_Block OR GVL_SYSTEM_COORDINATION.G_Block_Sockets_Override THEN
        L_Manual_Socket_Override[L_i] := FALSE;
    ELSE
        L_Manual_Socket_Override[L_i] := GVL_INTENT_USER.I_Socket_Override_32[L_i];
    END_IF;
    L_Socket_Override[L_i] := L_Manual_Socket_Override[L_i];
END_FOR;

fbLightingManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Away_Level := 1,
    VI_Simulation_Active := GVL_STATUS.G_Sim_Active,
    VI_Is_Night := GVL_STATUS.G_Is_Night,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_Manual_Light_Override := L_Manual_Light_Override,
    VI_Manual_Blinds_Override := L_Blinds_Override,
    VI_Simulation_Lights := L_Sim_Lights,
    VI_Physical_Switches := L_Physical_Switches,
    VI_Motion_Sensors := L_Motion_Sensors,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_Wet_Zone_Map := GVL_CONFIG.G_Wet_Zone_Map,
    VI_Scenario_Configs := GVL_CONFIG.G_HMI_Scenario_Configs,
    VO_Lighting_Levels => GVL_STATE.G_Lighting_Levels,
    VO_Blinds_Positions => GVL_STATE.G_Blinds_Positions,
    VO_Wet_Zone_Light_Active => L_Wet_Zone_Light_Active
);

fbSocketManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Manual_Override := L_Socket_Override,
    VI_Physical_Switches := GVL_STATE.G_Socket_Switches,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_Fire_Alarm := GVL_ALARM.G_Fire_Alarm_Active,
    VI_Flood_Alarm := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VO_Socket_States => GVL_STATE.G_Socket_States
);

// Priority overrides after normal manager calculation:
// Evacuation > Fire > Security Alarm > Security Armed > Normal
IF GVL_STATE.G_Evacuation_Lighting_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        CASE GVL_STATE.G_Evac_Guidance[L_i] OF
            -1:
                GVL_STATE.G_Lighting_Levels[L_i] := 0;
            1:
                GVL_STATE.G_Lighting_Levels[L_i] := 100;
        ELSE
            IF L_Evac_Blink_On THEN
                GVL_STATE.G_Lighting_Levels[L_i] := 100;
            ELSE
                GVL_STATE.G_Lighting_Levels[L_i] := 0;
            END_IF;
        END_CASE;
    END_FOR;
ELSIF L_Fire_Alarm_Active THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_STATE.G_Lighting_Levels[L_i] := 100;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BLINDS DO
        GVL_STATE.G_Blinds_Positions[L_i] := 100;
    END_FOR;
ELSIF L_Security_Alarm THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_STATE.G_Lighting_Levels[L_i] := 100;
    END_FOR;
ELSIF L_Security_Armed THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
        GVL_STATE.G_Lighting_Levels[L_i] := 0;
    END_FOR;
END_IF;

// Publish wet-zone activity from the final lighting state seen by IO_Write.
L_Wet_Zone_Any_Active := FALSE;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_LIGHT_ZONES DO
    IF GVL_CONFIG.G_Wet_Zone_Map[L_i] AND (GVL_STATE.G_Lighting_Levels[L_i] > 10) THEN
        L_Wet_Zone_Any_Active := TRUE;
    END_IF;
END_FOR;
GVL_STATUS.G_Wet_Zone_Light_Active := L_Wet_Zone_Any_Active;

// >>> BULK_SYNC_ANCHOR: PRG_Lighting <<<
END_PROGRAM
