FUNCTION_BLOCK FB_Lighting_Legacy_To_V2_Command_Adapter_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Brightness_Setpoint : REAL;
    VI_Scene_ID : INT;
    VI_Manual_Override : BOOL;
    VI_Transition_Time_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Command_V2 : ST_Lighting_Command_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_Command_V2.Zone_ID := VI_Zone_ID;
VO_Command_V2.Enabled := VI_Enable;
VO_Command_V2.Brightness_Setpoint := VI_Brightness_Setpoint;
VO_Command_V2.Scene_ID := VI_Scene_ID;
VO_Command_V2.Manual_Override := VI_Manual_Override;
VO_Command_V2.Transition_Time_MS := VI_Transition_Time_MS;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
