FUNCTION_BLOCK FB_Blinds_State_Extractor_DRAFT
VAR_INPUT
    VI_Position_Actual : BYTE;
    VI_Is_Moving : BOOL;
END_VAR
VAR_OUTPUT
    VO_State : ST_Blinds_State_V2;
END_VAR

VO_State.Position_Actual := VI_Position_Actual;
VO_State.Is_Moving := VI_Is_Moving;
END_FUNCTION_BLOCK
