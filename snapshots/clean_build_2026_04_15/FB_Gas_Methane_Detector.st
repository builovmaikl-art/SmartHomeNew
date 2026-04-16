FUNCTION_BLOCK FB_Gas_Methane_Detector
VAR_INPUT
    VI_Methane_LEL : REAL;
    VI_Threshold   : REAL := 20.0;
END_VAR
VAR_OUTPUT
    VO_Gas_Detected : BOOL;
END_VAR

VO_Gas_Detected := (VI_Methane_LEL >= VI_Threshold);
