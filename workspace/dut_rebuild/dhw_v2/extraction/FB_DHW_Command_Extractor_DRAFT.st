FUNCTION_BLOCK FB_DHW_Command_Extractor_DRAFT
VAR_INPUT
    VI_Enable : BOOL;
    VI_Target_Temp : REAL;
END_VAR
VAR_OUTPUT
    VO_Command : ST_DHW_Command_V2;
END_VAR

VO_Command.Enabled := VI_Enable;
VO_Command.Target_Temp := VI_Target_Temp;
END_FUNCTION_BLOCK
