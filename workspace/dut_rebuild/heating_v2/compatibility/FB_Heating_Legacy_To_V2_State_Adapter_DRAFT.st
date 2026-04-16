FUNCTION_BLOCK FB_Heating_Legacy_To_V2_State_Adapter_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Is_Active : BOOL;
    VI_Room_Temp : REAL;
    VI_Supply_Temp : REAL;
    VI_Return_Temp : REAL;
    VI_Valve_Position_Actual : REAL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_State_V2 : ST_Heating_State_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_State_V2.Zone_ID := VI_Zone_ID;
VO_State_V2.Is_Active := VI_Is_Active;
VO_State_V2.Room_Temp := VI_Room_Temp;
VO_State_V2.Supply_Temp := VI_Supply_Temp;
VO_State_V2.Return_Temp := VI_Return_Temp;
VO_State_V2.Valve_Position_Actual := VI_Valve_Position_Actual;
VO_State_V2.Alarm_Active := VI_Alarm_Active;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
