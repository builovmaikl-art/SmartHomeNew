FUNCTION_BLOCK FB_Mode_Manager

VAR_INPUT
    VI_Is_Night : BOOL;
    VI_Away_Request : BOOL;
    VI_Maintenance_Request : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR_OUTPUT
    VO_Mode : E_Behavior_Mode;
    VO_Mode_Code : UDINT;
END_VAR

// default
VO_Mode := BEHAVIOR_HOME;
VO_Mode_Code := 0;

// priority-based transitions
IF VI_Maintenance_Request THEN
    VO_Mode := BEHAVIOR_MAINTENANCE;
    VO_Mode_Code := 300;
ELSIF VI_Away_Request THEN
    VO_Mode := BEHAVIOR_AWAY;
    VO_Mode_Code := 200;
ELSIF VI_Is_Night THEN
    VO_Mode := BEHAVIOR_NIGHT;
    VO_Mode_Code := 100;
END_IF;
END_FUNCTION_BLOCK
