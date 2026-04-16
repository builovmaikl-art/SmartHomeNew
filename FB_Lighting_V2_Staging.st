FUNCTION_BLOCK FB_Lighting_V2_Staging
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

VO_Command_Shadow.Brightness_Setpoint := VI_Brightness_Setpoint;
VO_State_Shadow.Brightness_Actual := VI_Brightness_Actual;
VO_State_Shadow.Motion_Active := VI_Motion_Active;
END_FUNCTION_BLOCK
