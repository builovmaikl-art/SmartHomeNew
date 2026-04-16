FUNCTION_BLOCK FB_Lighting_V2_Core_DRAFT
VAR_INPUT
    VI_Command : ST_Lighting_Command_V2;
    VI_State_In : ST_Lighting_State_V2;
END_VAR
VAR_OUTPUT
    VO_Command_Out : ST_Lighting_Command_V2;
    VO_State_Out : ST_Lighting_State_V2;
END_VAR

// Draft pass-through skeleton only.
VO_Command_Out := VI_Command;
VO_State_Out := VI_State_In;
END_FUNCTION_BLOCK
