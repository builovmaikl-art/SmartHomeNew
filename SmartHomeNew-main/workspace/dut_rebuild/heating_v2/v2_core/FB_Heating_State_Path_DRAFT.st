FUNCTION_BLOCK FB_Heating_State_Path_DRAFT
VAR_INPUT
    VI_State_In : ST_Heating_State_V2;
END_VAR
VAR_OUTPUT
    VO_State_Out : ST_Heating_State_V2;
END_VAR

VO_State_Out := VI_State_In;
END_FUNCTION_BLOCK
