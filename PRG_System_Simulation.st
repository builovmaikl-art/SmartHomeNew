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

// Reset effective simulation outputs every cycle
GVL_SIMULATION.G_Sim_Heating_Sensor_Fault := FALSE;
GVL_SIMULATION.G_Sim_IO_Fault := FALSE;
GVL_SIMULATION.G_Sim_Low_Pressure := FALSE;
GVL_SIMULATION.G_Sim_Predictive_Pump_Fault := FALSE;
GVL_SIMULATION.G_Sim_Gas_Alarm := FALSE;
GVL_SIMULATION.G_Sim_Leak_Alarm := FALSE;
GVL_SIMULATION.G_Sim_Smoke_Alarm := FALSE;
GVL_SIMULATION.G_Sim_Dual_PLC_Active := FALSE;

IF NOT GVL_SIMULATION.G_Simulation_Enable THEN
    GVL_SIMULATION.G_Test_Running := FALSE;
    RETURN;
END_IF;

GVL_SIMULATION.G_Test_Running := TRUE;
GVL_SIMULATION.G_Test_Result_OK := TRUE;
GVL_SIMULATION.G_Test_Last_Result_Text := 'Running';

// Apply simulation requests to isolated outputs only
IF GVL_SIMULATION.G_Inject_Heating_Sensor_Fault THEN
    GVL_SIMULATION.G_Sim_Heating_Sensor_Fault := TRUE;
END_IF;

IF GVL_SIMULATION.G_Inject_IO_Fault THEN
    GVL_SIMULATION.G_Sim_IO_Fault := TRUE;
END_IF;

IF GVL_SIMULATION.G_Inject_Low_Pressure THEN
    GVL_SIMULATION.G_Sim_Low_Pressure := TRUE;
END_IF;

IF GVL_SIMULATION.G_Inject_Predictive_Pump_Fault THEN
    GVL_SIMULATION.G_Sim_Predictive_Pump_Fault := TRUE;
END_IF;

IF GVL_SIMULATION.G_Inject_Gas_Alarm THEN
    GVL_SIMULATION.G_Sim_Gas_Alarm := TRUE;
END_IF;

IF GVL_SIMULATION.G_Inject_Leak_Alarm THEN
    GVL_SIMULATION.G_Sim_Leak_Alarm := TRUE;
END_IF;

IF GVL_SIMULATION.G_Inject_Smoke_Alarm THEN
    GVL_SIMULATION.G_Sim_Smoke_Alarm := TRUE;
END_IF;

IF GVL_SIMULATION.G_Inject_Dual_PLC_Active THEN
    GVL_SIMULATION.G_Sim_Dual_PLC_Active := TRUE;
END_IF;

// Result evaluation (logical only, no state overwrite)
IF GVL_SIMULATION.G_Sim_Gas_Alarm OR GVL_SIMULATION.G_Sim_Leak_Alarm OR GVL_SIMULATION.G_Sim_Smoke_Alarm THEN
    GVL_SIMULATION.G_Test_Last_Result_Text := 'Safety simulation active';
ELSIF GVL_SIMULATION.G_Sim_IO_Fault OR GVL_SIMULATION.G_Sim_Heating_Sensor_Fault OR GVL_SIMULATION.G_Sim_Low_Pressure THEN
    GVL_SIMULATION.G_Test_Last_Result_Text := 'Heating simulation active';
ELSE
    GVL_SIMULATION.G_Test_Result_OK := FALSE;
    GVL_SIMULATION.G_Test_Last_Result_Text := 'No simulation flags active';
END_IF;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_System_Simulation <<<
