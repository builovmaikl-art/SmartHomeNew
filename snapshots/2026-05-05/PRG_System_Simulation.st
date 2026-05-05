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

// Reset outputs
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
    GVL_SIMULATION.G_Test_Scenario_Active := FALSE;
    RETURN;
END_IF;

// Start scenario
IF GVL_SIMULATION.G_Test_Start THEN
    GVL_SIMULATION.G_Test_Scenario_Active := TRUE;
    GVL_SIMULATION.G_Test_Started_MS := GVL_TIME_SERVICE.G_Now_MS;
END_IF;

// Stop scenario
IF GVL_SIMULATION.G_Test_Stop THEN
    GVL_SIMULATION.G_Test_Scenario_Active := FALSE;
END_IF;

GVL_SIMULATION.G_Test_Running := GVL_SIMULATION.G_Test_Scenario_Active;

IF NOT GVL_SIMULATION.G_Test_Scenario_Active THEN
    RETURN;
END_IF;

// Scenario execution
CASE GVL_SIMULATION.G_Test_Scenario_ID OF

    1: // Gas safety
        GVL_SIMULATION.G_Sim_Gas_Alarm := TRUE;
        GVL_SIMULATION.G_Test_Expected_Result_Code := 1;

    2: // Leak + pressure
        GVL_SIMULATION.G_Sim_Leak_Alarm := TRUE;
        GVL_SIMULATION.G_Sim_Low_Pressure := TRUE;
        GVL_SIMULATION.G_Test_Expected_Result_Code := 2;

    3: // Sensor + predictive
        GVL_SIMULATION.G_Sim_Heating_Sensor_Fault := TRUE;
        GVL_SIMULATION.G_Sim_Predictive_Pump_Fault := TRUE;
        GVL_SIMULATION.G_Test_Expected_Result_Code := 2;

    4: // Dual PLC
        GVL_SIMULATION.G_Sim_Dual_PLC_Active := TRUE;
        GVL_SIMULATION.G_Test_Expected_Result_Code := 3;

    5: // Full stress
        GVL_SIMULATION.G_Sim_Gas_Alarm := TRUE;
        GVL_SIMULATION.G_Sim_Leak_Alarm := TRUE;
        GVL_SIMULATION.G_Sim_Smoke_Alarm := TRUE;
        GVL_SIMULATION.G_Sim_Low_Pressure := TRUE;
        GVL_SIMULATION.G_Sim_Predictive_Pump_Fault := TRUE;
        GVL_SIMULATION.G_Test_Expected_Result_Code := 4;

ELSE
        // No fallback required
END_CASE;

// Auto stop by time
IF (GVL_TIME_SERVICE.G_Now_MS - GVL_SIMULATION.G_Test_Started_MS) > GVL_SIMULATION.G_Test_Duration_MS THEN
    GVL_SIMULATION.G_Test_Scenario_Active := FALSE;
END_IF;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_System_Simulation <<<
