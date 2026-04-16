FUNCTION_BLOCK FB_Socket_V2_Staging
VAR_INPUT
    VI_Socket_ID : INT;
    VI_Enable : BOOL;
    VI_Target_State : BOOL;
    VI_Manual_Override : BOOL;
    VI_Safety_Lock : BOOL;
    VI_Scenario_ID : INT;
    VI_Is_On : BOOL;
    VI_Manual_Override_Active : BOOL;
    VI_Safety_Blocked : BOOL;
    VI_Alarm_Active : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_Shadow : ST_Socket_Command_V2;
    VO_State_Shadow : ST_Socket_State_V2;
END_VAR

VO_Command_Shadow.Target_State := VI_Target_State;
VO_State_Shadow.Is_On := VI_Is_On;
VO_State_Shadow.Safety_Blocked := VI_Safety_Blocked;
END_FUNCTION_BLOCK
