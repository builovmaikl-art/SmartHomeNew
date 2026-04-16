FUNCTION_BLOCK FB_Heating_V2_Staging
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Target_Temp : REAL;
    VI_Valve_Position_Setpoint : REAL;
    VI_Pump_Enable : BOOL;
    VI_Is_Active : BOOL;
    VI_Room_Temp : REAL;
    VI_Supply_Temp : REAL;
    VI_Return_Temp : REAL;
    VI_Valve_Position_Actual : REAL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Heating_Command_V2;
    VO_State_Shadow : ST_Heating_State_V2;
END_VAR

VO_Command_Shadow.Valve_Position_Setpoint := VI_Valve_Position_Setpoint;
VO_State_Shadow.Room_Temp := VI_Room_Temp;
VO_State_Shadow.Supply_Temp := VI_Supply_Temp;
END_FUNCTION_BLOCK
