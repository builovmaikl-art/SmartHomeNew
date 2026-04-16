FUNCTION_BLOCK FB_Socket_Legacy_To_V2_State_Adapter_DRAFT
VAR_INPUT
    VI_Socket_ID : INT;
    VI_Is_On : BOOL;
    VI_Manual_Override_Active : BOOL;
    VI_Safety_Blocked : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_State_V2 : ST_Socket_State_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_State_V2.Socket_ID := VI_Socket_ID;
VO_State_V2.Is_On := VI_Is_On;
VO_State_V2.Manual_Override_Active := VI_Manual_Override_Active;
VO_State_V2.Safety_Blocked := VI_Safety_Blocked;
VO_State_V2.Alarm_Active := VI_Alarm_Active;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
