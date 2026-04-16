FUNCTION_BLOCK FB_Socket_Command_Extractor_DRAFT
VAR_INPUT
    VI_Target_State : BOOL;
    VI_Manual_Override : BOOL;
END_VAR
VAR_OUTPUT
    VO_Command : ST_Socket_Command_V2;
END_VAR

VO_Command.Target_State := VI_Target_State;
VO_Command.Manual_Override := VI_Manual_Override;
END_FUNCTION_BLOCK
