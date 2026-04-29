FUNCTION_BLOCK FB_Test_Result_Handler
VAR_INPUT
    VI_Test_Passed : BOOL;
END_VAR
VAR
    L_Latched_Failure : BOOL;
END_VAR

// latch failure
IF NOT VI_Test_Passed THEN
    L_Latched_Failure := TRUE;
END_IF;

// enforce safe stop if failure latched
IF L_Latched_Failure THEN
    GVL_COMMAND.G_Gas_Valve_Close := TRUE;
    GVL_COMMAND.G_Close_Valve_35 := TRUE;
    GVL_COMMAND.G_Close_Valve_36 := TRUE;
END_IF;
