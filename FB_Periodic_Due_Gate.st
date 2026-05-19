FUNCTION_BLOCK FB_Periodic_Due_Gate
VAR_INPUT
    VI_Enable : BOOL;
    VI_Now_MS : UDINT;
    VI_Interval_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Due : BOOL;
    VO_Last_Run_MS : UDINT;
END_VAR
VAR
    L_Elapsed_MS : UDINT;
    L_Interval_MS : UDINT;
END_VAR

VO_Due := FALSE;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

L_Interval_MS := VI_Interval_MS;
IF L_Interval_MS = 0 THEN
    L_Interval_MS := 1;
END_IF;

IF VO_Last_Run_MS = 0 THEN
    VO_Last_Run_MS := VI_Now_MS;
    VO_Due := TRUE;
    RETURN;
END_IF;

IF VI_Now_MS >= VO_Last_Run_MS THEN
    L_Elapsed_MS := VI_Now_MS - VO_Last_Run_MS;
ELSE
    L_Elapsed_MS := (4294967295 - VO_Last_Run_MS) + VI_Now_MS + 1;
END_IF;

IF L_Elapsed_MS >= L_Interval_MS THEN
    VO_Due := TRUE;
    VO_Last_Run_MS := VI_Now_MS;
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Periodic_Due_Gate <<<
