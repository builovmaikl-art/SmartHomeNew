PROGRAM PRG_Lighting
VAR
    L_i : INT;
    fbLightingManager : FB_Lighting_Blinds_Manager;
    fbSocketManager : FB_Socket_Manager;
    L_Manual_Light_Override_32 : ARRAY[1..32] OF BYTE;
    L_Manual_Blinds_Override_32 : ARRAY[1..32] OF BYTE;
    L_Manual_Socket_Override_32 : ARRAY[1..32] OF BOOL;
    L_Sim_Lights_32 : ARRAY[1..32] OF BOOL;
    L_Physical_Switches_32 : ARRAY[1..32] OF BOOL;
    L_Motion_Sensors_32 : ARRAY[1..32] OF BOOL;
END_VAR

FOR L_i := 1 TO 32 DO
    IF L_i <= 16 THEN
        IF GVL_INTENT_SYSTEM.I_Lighting_Overrides_Block THEN
            L_Manual_Light_Override_32[L_i] := 0;
        ELSE
            L_Manual_Light_Override_32[L_i] := GVL_COMMAND.G_Lighting_Override[L_i];
        END_IF;
        L_Sim_Lights_32[L_i] := GVL_STATE.G_Sim_Lights[L_i];
        L_Physical_Switches_32[L_i] := GVL_STATE.G_Physical_Switches[L_i];
        L_Motion_Sensors_32[L_i] := GVL_STATE.G_Motion_Sensors[L_i];
    ELSE
        L_Manual_Light_Override_32[L_i] := 0;
        L_Sim_Lights_32[L_i] := FALSE;
        L_Physical_Switches_32[L_i] := FALSE;
        L_Motion_Sensors_32[L_i] := FALSE;
    END_IF;

    IF GVL_INTENT_SYSTEM.I_Blinds_Overrides_Block THEN
        L_Manual_Blinds_Override_32[L_i] := 0;
    ELSE
        L_Manual_Blinds_Override_32[L_i] := GVL_COMMAND.G_Blinds_Override[L_i];
    END_IF;

    IF GVL_INTENT_SYSTEM.I_Socket_Overrides_Block THEN
        L_Manual_Socket_Override_32[L_i] := FALSE;
    ELSE
        L_Manual_Socket_Override_32[L_i] := GVL_COMMAND.G_Socket_Override[L_i];
    END_IF;
END_FOR;

// 10. Управление освещением и шторами
fbLightingManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Away_Level := 1,
    VI_Simulation_Active := GVL_STATUS.G_Sim_Active,
    VI_Manual_Light_Override := L_Manual_Light_Override_32,
    VI_Manual_Blinds_Override := L_Manual_Blinds_Override_32,
    VI_Simulation_Lights := L_Sim_Lights_32,
    VI_Physical_Switches := L_Physical_Switches_32,
    VI_Motion_Sensors := L_Motion_Sensors_32,
    VI_Is_Night := GVL_STATUS.G_Is_Night,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_Wet_Zone_Map := GVL_CONFIG.G_Wet_Zone_Map,
    VI_Scenario_Configs := GVL_CONFIG.G_HMI_Scenario_Configs,
    VO_Lighting_Levels => GVL_STATE.G_Lighting_Levels,
    VO_Blinds_Positions => GVL_STATE.G_Blinds_Positions
);

// 11.5 Управление розетками
fbSocketManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Manual_Override := L_Manual_Socket_Override_32,
    VI_Physical_Switches := GVL_STATE.G_Socket_Switches,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_Fire_Alarm := GVL_ALARM.G_Fire_Alarm_Active,
    VI_Flood_Alarm := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Security_Armed := GVL_ALARM.G_Security_Armed,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VO_Socket_States => GVL_STATE.G_Socket_States
);

// Evacuation lighting override
IF GVL_STATE.G_Evacuation_Lighting_Active THEN
    FOR L_i := 1 TO 8 DO
        IF (L_i MOD 2) = 0 THEN
            GVL_STATE.G_Lighting_Levels[L_i] := 100;
        ELSE
            GVL_STATE.G_Lighting_Levels[L_i] := 0;
        END_IF;
    END_FOR;
END_IF;

// Directional evacuation override
IF GVL_STATE.G_Evacuation_Lighting_Active THEN
    FOR L_i := 1 TO GVL_CONFIG.C_MAX_LIGHT_ZONES DO
        CASE GVL_STATE.G_Evac_Guidance[L_i] OF
            -1:
                GVL_STATE.G_Lighting_Levels[L_i] := 0;
            1:
                GVL_STATE.G_Lighting_Levels[L_i] := 100;
        ELSE
            GVL_STATE.G_Lighting_Levels[L_i] := SEL((L_i MOD 2) = 0, 0, 100);
        END_CASE;
    END_FOR;
END_IF;
// >>> BULK_SYNC_ANCHOR: PRG_Lighting <<<
