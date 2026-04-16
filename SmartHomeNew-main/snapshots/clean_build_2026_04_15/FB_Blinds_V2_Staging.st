FUNCTION_BLOCK FB_Blinds_V2_Staging
VAR_INPUT
    VI_Blind_ID : INT;
    VI_Enable : BOOL;
    VI_Position_Setpoint : BYTE;
    VI_Manual_Override : BOOL;
    VI_Scenario_ID : INT;
    VI_Safety_Mode : BOOL;
    VI_Position_Actual : BYTE;
    VI_Manual_Override_Active : BOOL;
    VI_Is_Moving : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Blinds_Command_V2;
    VO_State_Shadow : ST_Blinds_State_V2;
END_VAR

VO_Command_Shadow.Position_Setpoint := VI_Position_Setpoint;
VO_State_Shadow.Position_Actual := VI_Position_Actual;
END_FUNCTION_BLOCK
