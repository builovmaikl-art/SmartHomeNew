FUNCTION_BLOCK FB_Blinds_Legacy_To_V2_Command_Adapter_DRAFT
VAR_INPUT
    VI_Blind_ID : INT;
    VI_Enable : BOOL;
    VI_Position_Setpoint : BYTE;
    VI_Manual_Override : BOOL;
    VI_Scenario_ID : INT;
    VI_Safety_Mode : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_V2 : ST_Blinds_Command_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_Command_V2.Blind_ID := VI_Blind_ID;
VO_Command_V2.Enabled := VI_Enable;
VO_Command_V2.Position_Setpoint := VI_Position_Setpoint;
VO_Command_V2.Manual_Override := VI_Manual_Override;
VO_Command_V2.Scenario_ID := VI_Scenario_ID;
VO_Command_V2.Safety_Mode := VI_Safety_Mode;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
