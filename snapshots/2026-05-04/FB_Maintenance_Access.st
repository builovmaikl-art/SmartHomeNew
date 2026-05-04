FUNCTION_BLOCK FB_Maintenance_Access
VAR_INPUT
    VI_System_Time : UDINT;
    VI_Activate    : BOOL;
    VI_Duration    : UDINT := 60; // мин
END_VAR
VAR_OUTPUT
    VO_Active      : BOOL;
    VO_Time_Left   : UDINT;
END_VAR
VAR
    L_Start_Time   : UDINT;
    L_elapsed      : UDINT;
END_VAR

IF VI_Activate AND NOT VO_Active THEN
    VO_Active := TRUE;
    L_Start_Time := VI_System_Time;
END_IF;

IF VO_Active THEN
    L_elapsed := (SEL(VI_System_Time >= L_Start_Time, VI_System_Time - L_Start_Time, (4294967295 - L_Start_Time) + VI_System_Time + 1)) / GVL_CONSTANTS.C_MS_IN_MINUTE;
    IF L_elapsed >= VI_Duration THEN
        VO_Active := FALSE;
        VO_Time_Left := 0;
    ELSE
        VO_Time_Left := VI_Duration - L_elapsed;
    END_IF;
ELSE
    VO_Time_Left := 0;
END_IF;