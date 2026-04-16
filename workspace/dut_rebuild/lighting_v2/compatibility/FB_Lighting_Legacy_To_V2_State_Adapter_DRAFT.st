FUNCTION_BLOCK FB_Lighting_Legacy_To_V2_State_Adapter_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Is_Active : BOOL;
    VI_Brightness_Actual : REAL;
    VI_Motion_Active : BOOL;
    VI_Ambient_Lux : REAL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_State_V2 : ST_Lighting_State_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_State_V2.Zone_ID := VI_Zone_ID;
VO_State_V2.Is_Active := VI_Is_Active;
VO_State_V2.Brightness_Actual := VI_Brightness_Actual;
VO_State_V2.Motion_Active := VI_Motion_Active;
VO_State_V2.Ambient_Lux := VI_Ambient_Lux;
VO_State_V2.Alarm_Active := VI_Alarm_Active;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
