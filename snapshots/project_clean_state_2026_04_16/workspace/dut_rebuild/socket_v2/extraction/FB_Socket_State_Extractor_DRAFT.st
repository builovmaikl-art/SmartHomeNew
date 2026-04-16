FUNCTION_BLOCK FB_Socket_State_Extractor_DRAFT
VAR_INPUT
    VI_Is_On : BOOL;
    VI_Safety_Blocked : BOOL;
END_VAR
VAR_OUTPUT
    VO_State : ST_Socket_State_V2;
END_VAR

VO_State.Is_On := VI_Is_On;
VO_State.Safety_Blocked := VI_Safety_Blocked;
END_FUNCTION_BLOCK
