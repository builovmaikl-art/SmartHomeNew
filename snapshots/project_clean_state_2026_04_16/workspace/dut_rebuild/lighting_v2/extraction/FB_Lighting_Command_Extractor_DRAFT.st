FUNCTION_BLOCK FB_Lighting_Command_Extractor_DRAFT
VAR_INPUT
    VI_Enable : BOOL;
    VI_Brightness_Setpoint : REAL;
END_VAR
VAR_OUTPUT
    VO_Command : ST_Lighting_Command_V2;
END_VAR

VO_Command.Enabled := VI_Enable;
VO_Command.Brightness_Setpoint := VI_Brightness_Setpoint;
END_FUNCTION_BLOCK
