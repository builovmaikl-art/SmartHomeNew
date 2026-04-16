FUNCTION_BLOCK FB_Socket_V2_Staging_DRAFT
VAR_INPUT
    VI_Socket_ID : INT;
    VI_Enable : BOOL;
    VI_Target_State : BOOL;
    VI_Manual_Override : BOOL;
    VI_Safety_Lock : BOOL;
    VI_Scenario_ID : INT;

    VI_Is_On : BOOL;
    VI_Manual_Override_Active : BOOL;
    VI_Safety_Blocked : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Socket_Command_V2;
    VO_State_Shadow : ST_Socket_State_V2;
END_VAR
VAR
    fbCmdAdapter : FB_Socket_Legacy_To_V2_Command_Adapter_DRAFT;
    fbStateAdapter : FB_Socket_Legacy_To_V2_State_Adapter_DRAFT;
    fbCore : FB_Socket_V2_Core_DRAFT;
    L_Command_V2 : ST_Socket_Command_V2;
    L_State_V2 : ST_Socket_State_V2;
END_VAR

fbCmdAdapter(
    VI_Socket_ID := VI_Socket_ID,
    VI_Enable := VI_Enable,
    VI_Target_State := VI_Target_State,
    VI_Manual_Override := VI_Manual_Override,
    VI_Safety_Lock := VI_Safety_Lock,
    VI_Scenario_ID := VI_Scenario_ID,
    VO_Command_V2 => L_Command_V2
);

fbStateAdapter(
    VI_Socket_ID := VI_Socket_ID,
    VI_Is_On := VI_Is_On,
    VI_Manual_Override_Active := VI_Manual_Override_Active,
    VI_Safety_Blocked := VI_Safety_Blocked,
    VI_Alarm_Active := VI_Alarm_Active,
    VO_State_V2 => L_State_V2
);

fbCore(
    VI_Command := L_Command_V2,
    VI_State_In := L_State_V2,
    VO_Command_Out => VO_Command_Shadow,
    VO_State_Out => VO_State_Shadow
);

END_FUNCTION_BLOCK
