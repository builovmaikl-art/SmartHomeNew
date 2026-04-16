FUNCTION_BLOCK FB_Ventilation_State_Path_DRAFT
VAR_INPUT
    VI_State_In : ST_Ventilation_State_V2;
END_VAR
VAR_OUTPUT
    VO_State_Out : ST_Ventilation_State_V2;
END_VAR

// Draft state path only.
VO_State_Out := VI_State_In;
END_FUNCTION_BLOCK
