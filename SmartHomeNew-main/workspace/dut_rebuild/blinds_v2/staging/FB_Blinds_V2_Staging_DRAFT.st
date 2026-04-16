FUNCTION_BLOCK FB_Blinds_V2_Staging_DRAFT
VAR_INPUT
    VI_Blind_ID : INT;
    VI_Enable : BOOL;
    VI_Position_Setpoint : BYTE;
    VI_Manual_Override : BOOL;
    VI_Scenario_ID : INT;
    VI_Safety_Mode : BOOL;

    VI_Position_Actual : BYTE;
    VI_Manual_Override_Active : BOOL;
    VI_Is_Moving : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Blinds_Command_V2;
    VO_State_Shadow : ST_Blinds_State_V2;
END_VAR
VAR
    fbCmdAdapter : FB_Blinds_Legacy_To_V2_Command_Adapter_DRAFT;
    fbStateAdapter : FB_Blinds_Legacy_To_V2_State_Adapter_DRAFT;
    fbCore : FB_Blinds_V2_Core_DRAFT;
    L_Command_V2 : ST_Blinds_Command_V2;
    L_State_V2 : ST_Blinds_State_V2;
END_VAR

fbCmdAdapter(
    VI_Blind_ID := VI_Blind_ID,
    VI_Enable := VI_Enable,
    VI_Position_Setpoint := VI_Position_Setpoint,
    VI_Manual_Override := VI_Manual_Override,
    VI_Scenario_ID := VI_Scenario_ID,
    VI_Safety_Mode := VI_Safety_Mode,
    VO_Command_V2 => L_Command_V2
);

fbStateAdapter(
    VI_Blind_ID := VI_Blind_ID,
    VI_Position_Actual := VI_Position_Actual,
    VI_Manual_Override_Active := VI_Manual_Override_Active,
    VI_Is_Moving := VI_Is_Moving,
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
