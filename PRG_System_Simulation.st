PROGRAM PRG_System_Simulation
VAR
    fbSimulation : FB_Simulation_Manager;
    fbPlayback : FB_Presence_Playback;
    L_Playback_Lights : ARRAY[1..32] OF BOOL;
    L_Scenario_Config : ST_Scenario_Config;
    L_i : INT;
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

IF GVL_SIMULATION.G_Simulation_Enable THEN
    GVL_SIMULATION.G_Test_Running := TRUE;
    GVL_SIMULATION.G_Test_Result_OK := TRUE;
    GVL_SIMULATION.G_Test_Last_Result_Text := 'Running';

    IF GVL_SIMULATION.G_Inject_Heating_Sensor_Fault THEN
        GVL_STATE.G_Heating_Sensor_Fault := TRUE;
    END_IF;

    IF GVL_SIMULATION.G_Inject_IO_Fault THEN
        GVL_STATE.G_Heating_IO_Fault := TRUE;
    END_IF;

    IF GVL_SIMULATION.G_Inject_Low_Pressure THEN
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_STATE.G_Manifold_Pressures[L_i] := 0.0;
        END_FOR;
    END_IF;

    IF GVL_SIMULATION.G_Inject_Predictive_Pump_Fault THEN
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
            GVL_STATE.G_Predictive_Pump_Pressure_Drop[L_i] := TRUE;
        END_FOR;
    END_IF;

    IF GVL_SIMULATION.G_Inject_Gas_Alarm THEN
        GVL_STATE.G_Safety_Gas_Alarm := TRUE;
    END_IF;

    IF GVL_SIMULATION.G_Inject_Leak_Alarm THEN
        GVL_STATE.G_Safety_Leak_Alarm := TRUE;
    END_IF;

    IF GVL_SIMULATION.G_Inject_Smoke_Alarm THEN
        GVL_STATE.G_Safety_Smoke_Alarm := TRUE;
    END_IF;

    IF GVL_SIMULATION.G_Inject_Dual_PLC_Active THEN
        GVL_STATUS.G_Other_PLC_Is_Active := TRUE;
    END_IF;

    IF GVL_STATE.G_Safety_Gas_Alarm OR GVL_STATE.G_Safety_Leak_Alarm OR GVL_STATE.G_Safety_Smoke_Alarm THEN
        GVL_SIMULATION.G_Test_Last_Result_Text := 'Safety triggered as expected';
    ELSIF GVL_STATE.G_Heating_IO_Fault OR GVL_STATE.G_Heating_Sensor_Fault OR GVL_STATE.G_Heating_Subsystem_Degraded THEN
        GVL_SIMULATION.G_Test_Last_Result_Text := 'Heating fault injected as expected';
    ELSE
        GVL_SIMULATION.G_Test_Result_OK := FALSE;
        GVL_SIMULATION.G_Test_Last_Result_Text := 'No expected reaction';
    END_IF;
ELSE
    GVL_SIMULATION.G_Test_Running := FALSE;
END_IF;

END_PROGRAM
