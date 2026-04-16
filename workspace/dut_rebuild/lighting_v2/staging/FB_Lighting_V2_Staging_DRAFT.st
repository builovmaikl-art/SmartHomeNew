FUNCTION_BLOCK FB_Lighting_V2_Staging_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Brightness_Setpoint : REAL;
    VI_Scene_ID : INT;
    VI_Manual_Override : BOOL;
    VI_Transition_Time_MS : UDINT;

    VI_Is_Active : BOOL;
    VI_Brightness_Actual : REAL;
    VI_Motion_Active : BOOL;
    VI_Ambient_Lux : REAL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Lighting_Command_V2;
    VO_State_Shadow : ST_Lighting_State_V2;
END_VAR
VAR
    fbCmdAdapter : FB_Lighting_Legacy_To_V2_Command_Adapter_DRAFT;
    fbStateAdapter : FB_Lighting_Legacy_To_V2_State_Adapter_DRAFT;
    fbCore : FB_Lighting_V2_Core_DRAFT;
    L_Command_V2 : ST_Lighting_Command_V2;
    L_State_V2 : ST_Lighting_State_V2;
END_VAR

fbCmdAdapter(
    VI_Zone_ID := VI_Zone_ID,
    VI_Enable := VI_Enable,
    VI_Brightness_Setpoint := VI_Brightness_Setpoint,
    VI_Scene_ID := VI_Scene_ID,
    VI_Manual_Override := VI_Manual_Override,
    VI_Transition_Time_MS := VI_Transition_Time_MS,
    VO_Command_V2 => L_Command_V2
);

fbStateAdapter(
    VI_Zone_ID := VI_Zone_ID,
    VI_Is_Active := VI_Is_Active,
    VI_Brightness_Actual := VI_Brightness_Actual,
    VI_Motion_Active := VI_Motion_Active,
    VI_Ambient_Lux := VI_Ambient_Lux,
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
