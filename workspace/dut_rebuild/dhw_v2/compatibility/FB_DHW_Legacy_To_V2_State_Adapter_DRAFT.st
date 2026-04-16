FUNCTION_BLOCK FB_DHW_Legacy_To_V2_State_Adapter_DRAFT
VAR_INPUT
    VI_Tank_ID : INT;
    VI_Is_Active : BOOL;
    VI_Tank_Temp : REAL;
    VI_Supply_Temp : REAL;
    VI_Return_Temp : REAL;
    VI_Pump_Actual : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_State_V2 : ST_DHW_State_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_State_V2.Tank_ID := VI_Tank_ID;
VO_State_V2.Is_Active := VI_Is_Active;
VO_State_V2.Tank_Temp := VI_Tank_Temp;
VO_State_V2.Supply_Temp := VI_Supply_Temp;
VO_State_V2.Return_Temp := VI_Return_Temp;
VO_State_V2.Pump_Actual := VI_Pump_Actual;
VO_State_V2.Alarm_Active := VI_Alarm_Active;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
