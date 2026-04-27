FUNCTION_BLOCK FB_Mode_Manager

VAR_INPUT
    VI_Is_Night : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR_OUTPUT
    VO_Mode : E_Behavior_Mode;
    VO_Mode_Code : UDINT;
END_VAR

// default
VO_Mode := BEHAVIOR_HOME;
VO_Mode_Code := 0;

// simple logic (observe-only)
IF VI_Is_Night THEN
    VO_Mode := BEHAVIOR_NIGHT;
    VO_Mode_Code := 100;
END_IF;
