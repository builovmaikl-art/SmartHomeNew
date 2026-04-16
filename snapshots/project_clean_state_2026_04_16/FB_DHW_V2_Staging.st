FUNCTION_BLOCK FB_DHW_V2_Staging
VAR_INPUT
    VI_Tank_ID : INT;
    VI_Enable : BOOL;
    VI_Target_Temp : REAL;
    VI_Pump_Enable : BOOL;
    VI_Heating_Priority : BOOL;
    VI_Is_Active : BOOL;
    VI_Tank_Temp : REAL;
    VI_Supply_Temp : REAL;
    VI_Return_Temp : REAL;
    VI_Pump_Actual : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_DHW_Command_V2;
    VO_State_Shadow : ST_DHW_State_V2;
END_VAR

IF VI_Pump_Enable THEN
    VO_Command_Shadow.Pump_Enable := 1.0;
ELSE
    VO_Command_Shadow.Pump_Enable := 0.0;
END_IF;

VO_State_Shadow.Tank_Temp := VI_Tank_Temp;
VO_State_Shadow.Supply_Temp := VI_Supply_Temp;
END_FUNCTION_BLOCK
