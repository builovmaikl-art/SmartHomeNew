FUNCTION_BLOCK FB_Lighting_State_Extractor_DRAFT
VAR_INPUT
    VI_Brightness_Actual : REAL;
END_VAR
VAR_OUTPUT
    VO_State : ST_Lighting_State_V2;
END_VAR

VO_State.Brightness_Actual := VI_Brightness_Actual;
END_FUNCTION_BLOCK
