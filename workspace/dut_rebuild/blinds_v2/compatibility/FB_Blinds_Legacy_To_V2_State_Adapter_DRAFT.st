FUNCTION_BLOCK FB_Blinds_Legacy_To_V2_State_Adapter_DRAFT
VAR_INPUT
    VI_Blind_ID : INT;
    VI_Position_Actual : BYTE;
    VI_Manual_Override_Active : BOOL;
    VI_Is_Moving : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_State_V2 : ST_Blinds_State_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_State_V2.Blind_ID := VI_Blind_ID;
VO_State_V2.Position_Actual := VI_Position_Actual;
VO_State_V2.Manual_Override_Active := VI_Manual_Override_Active;
VO_State_V2.Is_Moving := VI_Is_Moving;
VO_State_V2.Alarm_Active := VI_Alarm_Active;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
