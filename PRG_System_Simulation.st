PROGRAM PRG_System_Simulation
VAR
    fbSimulation : FB_Simulation_Manager;
    fbPlayback : FB_Presence_Playback;
    L_Playback_Lights : ARRAY[1..32] OF BOOL;
    L_Scenario_Config : ST_Scenario_Config;
END_VAR

L_Scenario_Config := GVL_CONFIG.G_HMI_Scenario_Configs[TO_INT(GVL_STATUS.G_Current_Scenario)];

fbSimulation(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Scenario := GVL_STATUS.G_Current_Scenario,
    VI_Config := L_Scenario_Config
);

fbPlayback(
    VI_Mode_Record := FALSE,
    VI_Time_Index := GVL_TIME_SERVICE.G_Now_MS,
    VI_Light_Inputs := L_Playback_Lights
);

END_PROGRAM
