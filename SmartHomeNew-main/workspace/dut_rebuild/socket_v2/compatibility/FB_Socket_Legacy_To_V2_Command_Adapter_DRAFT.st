FUNCTION_BLOCK FB_Socket_Legacy_To_V2_Command_Adapter_DRAFT
VAR_INPUT
    VI_Socket_ID : INT;
    VI_Enable : BOOL;
    VI_Target_State : BOOL;
    VI_Manual_Override : BOOL;
    VI_Safety_Lock : BOOL;
    VI_Scenario_ID : INT;
END_VAR
VAR_OUTPUT
    VO_Command_V2 : ST_Socket_Command_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_Command_V2.Socket_ID := VI_Socket_ID;
VO_Command_V2.Enabled := VI_Enable;
VO_Command_V2.Target_State := VI_Target_State;
VO_Command_V2.Manual_Override := VI_Manual_Override;
VO_Command_V2.Safety_Lock := VI_Safety_Lock;
VO_Command_V2.Scenario_ID := VI_Scenario_ID;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
