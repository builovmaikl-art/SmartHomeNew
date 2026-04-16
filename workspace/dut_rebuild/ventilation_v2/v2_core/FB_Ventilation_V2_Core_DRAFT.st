FUNCTION_BLOCK FB_Ventilation_V2_Core_DRAFT
VAR_INPUT
    VI_Command : ST_Ventilation_Command_V2;
    VI_State_In : ST_Ventilation_State_V2;
END_VAR
VAR_OUTPUT
    VO_Command_Out : ST_Ventilation_Command_V2;
    VO_State_Out : ST_Ventilation_State_V2;
END_VAR
VAR
    fbCommandPath : FB_Ventilation_Command_Path_DRAFT;
    fbStatePath : FB_Ventilation_State_Path_DRAFT;
    L_Command_Mid : ST_Ventilation_Command_V2;
END_VAR

fbCommandPath(
    VI_Command_In := VI_Command,
    VO_Command_Out => L_Command_Mid
);

fbStatePath(
    VI_State_In := VI_State_In,
    VO_State_Out => VO_State_Out
);

VO_Command_Out := L_Command_Mid;
END_FUNCTION_BLOCK
