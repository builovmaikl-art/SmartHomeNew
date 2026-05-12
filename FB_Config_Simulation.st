// ==============================================================================
// Config simulation / validation function block
// Service/commissioning validation utility.
// Does NOT own runtime control and does NOT participate in heating phase runtime.
// ==============================================================================
FUNCTION_BLOCK FB_Config_Simulation
VAR_INPUT
    VI_Enable : BOOL;
    VI_Request : BOOL;
    VI_Confirm : BOOL;
END_VAR
VAR_OUTPUT
    VO_Executed : BOOL;
    VO_Result_OK : BOOL;
    VO_Error_Text : STRING(200);
END_VAR
VAR
    L_Error : BOOL;
END_VAR

VO_Executed := FALSE;
VO_Result_OK := TRUE;
VO_Error_Text := '';

GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := TRUE;
GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := '';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Request AND VI_Confirm THEN

    L_Error := FALSE;

    // Simulate INPUT constraints
    IF (GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate < 0.0) OR (GVL_CONFIG_CONTROL.STG_Reputation_Learning_Rate > 1.0) THEN
        VO_Result_OK := FALSE;
        VO_Error_Text := 'Invalid learning rate';
        L_Error := TRUE;
    END_IF;

    // Simulate SCENARIO logic
    IF GVL_CONFIG_CONTROL.STG_Night_Start_Hour = GVL_CONFIG_CONTROL.STG_Night_End_Hour THEN
        VO_Result_OK := FALSE;
        VO_Error_Text := 'Night window invalid';
        L_Error := TRUE;
    END_IF;

    // Simulate SAFETY
    IF GVL_CONFIG_CONTROL.STG_Stabilization_Delay_MS < 1000 THEN
        VO_Result_OK := FALSE;
        VO_Error_Text := 'Recovery delay too small';
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
        VO_Result_OK := FALSE;
        VO_Error_Text := 'Fail-safe disabled';
        L_Error := TRUE;
    END_IF;

    IF L_Error THEN
        GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := FALSE;
        GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := VO_Error_Text;
    ELSE
        GVL_CONFIG_SIMULATION.G_Simulation_Result_OK := TRUE;
        GVL_CONFIG_SIMULATION.G_Simulation_Error_Text := '';
    END_IF;

    GVL_CONFIG_SIMULATION.G_Simulation_Last_Run_MS := GVL_TIME_SERVICE.G_Now_MS;
    VO_Executed := TRUE;

END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Config_Simulation <<<
