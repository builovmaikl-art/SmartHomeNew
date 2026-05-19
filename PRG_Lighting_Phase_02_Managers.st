PROGRAM PRG_Lighting_Phase_02_Managers
VAR
    fbLightingManager : FB_Lighting_Blinds_Manager;
    fbSocketManager : FB_Socket_Manager;
END_VAR

IF GVL_LIGHTING_RUNTIME_BUFFER.B_Distributed_Execute_Allowed THEN

    fbLightingManager(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
        VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
        VI_Away_Level := 1,
        VI_Simulation_Active := GVL_STATUS.G_Sim_Active,
        VI_Is_Night := GVL_STATUS.G_Is_Night,
        VI_System_Mode := GVL_STATE.G_System_Mode,
        VI_Manual_Light_Override := GVL_LIGHTING_RUNTIME_BUFFER.B_Manual_Light_Override,
        VI_Manual_Blinds_Override := GVL_LIGHTING_RUNTIME_BUFFER.B_Blinds_Override,
        VI_Simulation_Lights := GVL_LIGHTING_RUNTIME_BUFFER.B_Sim_Lights,
        VI_Physical_Switches := GVL_LIGHTING_RUNTIME_BUFFER.B_Physical_Switches,
        VI_Motion_Sensors := GVL_LIGHTING_RUNTIME_BUFFER.B_Motion_Sensors,
        VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
        VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
        VI_Wet_Zone_Map := GVL_CONFIG.G_Wet_Zone_Map,
        VI_Scenario_Configs := GVL_CONFIG.G_HMI_Scenario_Configs,
        VO_Lighting_Levels => GVL_STATE.G_Lighting_Levels,
        VO_Blinds_Positions => GVL_STATE.G_Blinds_Positions,
        VO_Wet_Zone_Light_Active => GVL_LIGHTING_RUNTIME_BUFFER.B_Wet_Zone_Light_Active
    );

    fbSocketManager(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
        VI_Scenario := GVL_STATUS.G_Current_Scenario,
        VI_Manual_Override := GVL_LIGHTING_RUNTIME_BUFFER.B_Socket_Override,
        VI_Physical_Switches := GVL_STATE.G_Socket_Switches,
        VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
        VI_Fire_Alarm := GVL_LIGHTING_RUNTIME_BUFFER.B_Fire_Alarm_Active,
        VI_Flood_Alarm := GVL_LIGHTING_RUNTIME_BUFFER.B_Flood_Alarm_Active,
        VI_Security_Armed := GVL_ALARM.G_Security_Armed,
        VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
        VO_Socket_States => GVL_STATE.G_Socket_States
    );

END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Lighting_Phase_02_Managers <<<
END_PROGRAM
