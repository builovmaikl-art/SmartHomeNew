FUNCTION_BLOCK FB_Ventilation_V2_Staging
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Fan_Speed_Setpoint : REAL;
    VI_Damper_Position_Setpoint : REAL;
    VI_Heat_Recovery_Enabled : BOOL;
    VI_Is_Active : BOOL;
    VI_Fan_Speed_Actual : REAL;
    VI_Supply_Temp : REAL;
    VI_Extract_Temp : REAL;
    VI_Filter_Dirty : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Ventilation_Command_V2;
    VO_State_Shadow : ST_Ventilation_State_V2;
END_VAR

VO_Command_Shadow.Fan_Speed_Setpoint := VI_Fan_Speed_Setpoint;
VO_State_Shadow.Supply_Temp := VI_Supply_Temp;
END_FUNCTION_BLOCK
