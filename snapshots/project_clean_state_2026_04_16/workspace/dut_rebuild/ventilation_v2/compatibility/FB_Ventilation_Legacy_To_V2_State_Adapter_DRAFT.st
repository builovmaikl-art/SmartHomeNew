FUNCTION_BLOCK FB_Ventilation_Legacy_To_V2_State_Adapter_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Is_Active : BOOL;
    VI_Fan_Speed_Actual : REAL;
    VI_Supply_Temp : REAL;
    VI_Extract_Temp : REAL;
    VI_Filter_Dirty : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_State_V2 : ST_Ventilation_State_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_State_V2.Zone_ID := VI_Zone_ID;
VO_State_V2.Is_Active := VI_Is_Active;
VO_State_V2.Fan_Speed_Actual := VI_Fan_Speed_Actual;
VO_State_V2.Supply_Temp := VI_Supply_Temp;
VO_State_V2.Extract_Temp := VI_Extract_Temp;
VO_State_V2.Filter_Dirty := VI_Filter_Dirty;
VO_State_V2.Alarm_Active := VI_Alarm_Active;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
