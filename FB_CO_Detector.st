FUNCTION_BLOCK FB_CO_Detector
VAR_INPUT
    VI_CO_PPM : REAL;
    VI_Threshold_Warning : REAL := 30.0;
    VI_Threshold_Alarm   : REAL := 70.0;
END_VAR
VAR_OUTPUT
    VO_CO_Warning_Level : BOOL;
    VO_CO_Alarm_Level   : BOOL;
END_VAR

VO_CO_Warning_Level := (VI_CO_PPM >= VI_Threshold_Warning);
VO_CO_Alarm_Level   := (VI_CO_PPM >= VI_Threshold_Alarm);
