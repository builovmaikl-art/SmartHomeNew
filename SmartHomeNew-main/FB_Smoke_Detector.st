FUNCTION_BLOCK FB_Smoke_Detector
VAR_INPUT
    VI_Smoke_Signal : BOOL;
END_VAR
VAR_OUTPUT
    VO_Smoke_Detected : BOOL;
END_VAR

VO_Smoke_Detected := VI_Smoke_Signal;
