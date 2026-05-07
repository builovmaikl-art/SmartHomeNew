PROGRAM PRG_Config_Simulation
VAR
    L_Error : BOOL;
END_VAR

L_Error := FALSE;
GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := TRUE;
GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := '';

IF GVL_CONFIG_SIMULATION.G_Simulation_Request AND GVL_CONFIG_SIMULATION.G_Simulation_Confirm THEN

    // Simulate INPUT constraints
    IF (GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate < 0.0) OR (GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate > 1.0) THEN
        GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := FALSE;
        GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := 'Invalid learning rate';
        L_Error := TRUE;
    END_IF;

    // Simulate SCENARIO logic
    IF GVL_CONFIG_CONTROL.STG_Night_Start_Hour = GVL_CONFIG_CONTROL.STG_Night_End_Hour THEN
        GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := FALSE;
        GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := 'Night window invalid';
        L_Error := TRUE;
    END_IF;

    // Simulate SAFETY
    IF GVL_CONFIG_CONTROL.STG_Stabilization_Delay_MS < 1000 THEN
        GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := FALSE;
        GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := 'Recovery delay too small';
        L_Error := TRUE;
    END_IF;

    // Simulate FAIL-SAFE policy
    IF NOT (
        GVL_CONFIG_CONTROL.STG_PLC_Inactive_Close_Gas OR
        GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Boiler OR
        GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Heating OR
        GVL_CONFIG_CONTROL.STG_PLC_Inactive_Stop_Vent OR
        GVL_CONFIG_CONTROL.STG_PLC_Inactive_Block_Water
    ) THEN
        GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := FALSE;
        GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := 'Fail-safe disabled';
        L_Error := TRUE;
    END_IF;

    GVL_CONFIG_SIMULATION.G_Simulation_Last_Run_MS := GVL_TIME_SERVICE.G_Now_MS;

END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Config_Simulation <<<
END_PROGRAM
