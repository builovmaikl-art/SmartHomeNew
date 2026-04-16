FUNCTION_BLOCK FB_Ventilation_Command_Path_DRAFT
VAR_INPUT
    VI_Command_In : ST_Ventilation_Command_V2;
END_VAR
VAR_OUTPUT
    VO_Command_Out : ST_Ventilation_Command_V2;
END_VAR

// Draft command path only.
VO_Command_Out := VI_Command_In;
END_FUNCTION_BLOCK
