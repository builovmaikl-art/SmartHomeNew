FUNCTION_BLOCK FB_Blinds_Command_Extractor_DRAFT
VAR_INPUT
    VI_Position_Setpoint : BYTE;
    VI_Manual_Override : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command : ST_Blinds_Command_V2;
END_VAR

VO_Command.Position_Setpoint := VI_Position_Setpoint;
VO_Command.Manual_Override := VI_Manual_Override;
END_FUNCTION_BLOCK
