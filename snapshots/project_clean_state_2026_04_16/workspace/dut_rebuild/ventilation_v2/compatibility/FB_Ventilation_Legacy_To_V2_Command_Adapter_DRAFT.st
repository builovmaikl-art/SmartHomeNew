FUNCTION_BLOCK FB_Ventilation_Legacy_To_V2_Command_Adapter_DRAFT
VAR_INPUT
    VI_Zone_ID : INT;
    VI_Enable : BOOL;
    VI_Fan_Speed_Setpoint : REAL;
    VI_Damper_Position_Setpoint : REAL;
    VI_Heat_Recovery_Enabled : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command_V2 : ST_Ventilation_Command_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_Command_V2.Zone_ID := VI_Zone_ID;
VO_Command_V2.Enabled := VI_Enable;
VO_Command_V2.Fan_Speed_Setpoint := VI_Fan_Speed_Setpoint;
VO_Command_V2.Damper_Position_Setpoint := VI_Damper_Position_Setpoint;
VO_Command_V2.Heat_Recovery_Enabled := VI_Heat_Recovery_Enabled;
VO_Command_V2.Source_Mode := 0;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
