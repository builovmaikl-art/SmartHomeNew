FUNCTION_BLOCK FB_Heating_Command_Path_DRAFT
VAR_INPUT
    VI_Command_In : ST_Heating_Command_V2;
END_VAR
VAR_OUTPUT
    VO_Command_Out : ST_Heating_Command_V2;
END_VAR

VO_Command_Out := VI_Command_In;
END_FUNCTION_BLOCK
