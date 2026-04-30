PROGRAM PRG_System_Simulation
VAR
    fbSimulation : FB_Simulation_Manager;
    fbPlayback : FB_Presence_Playback;
    L_Playback_Lights : ARRAY[1..32] OF BOOL;
END_VAR

fbSimulation(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_IsActivePLC := TRUE,
    VI_Scenario := GVL_SCENARIO.G_Current_Scenario,
    VI_Config := GVL_CONFIG.G_Scenario_Config
);

fbPlayback(
    VI_Mode_Record := FALSE,
    VI_Time_Index := GVL_TIME_SERVICE.G_Now_MS,
    VI_Light_Inputs := L_Playback_Lights
);

END_PROGRAM
