FUNCTION_BLOCK FB_Security_Alarm
VAR_INPUT
    VI_Armed       : BOOL;
    VI_Motion      : BOOL;
    VI_Door        : BOOL;
    VI_Delay_MS    : UDINT := 30000;
    VI_System_Time : UDINT;
END_VAR
VAR_OUTPUT
    VO_Alarm       : BOOL;
END_VAR
VAR
    L_Trigger_Time : UDINT;
    L_Triggered    : BOOL;
END_VAR

IF VI_Armed AND (VI_Motion OR VI_Door) AND NOT L_Triggered THEN
    L_Triggered := TRUE;
    L_Trigger_Time := VI_System_Time;
END_IF;

IF L_Triggered AND ((SEL(VI_System_Time >= L_Trigger_Time, VI_System_Time - L_Trigger_Time, (4294967295 - L_Trigger_Time) + VI_System_Time + 1)) >= VI_Delay_MS) THEN
    VO_Alarm := TRUE;
ELSIF NOT VI_Armed THEN
    L_Triggered := FALSE;
    VO_Alarm := FALSE;
END_IF;