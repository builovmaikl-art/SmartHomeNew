FUNCTION_BLOCK FB_Watchdog
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Timeout_MS     : UDINT := 2000;
END_VAR

VAR_OUTPUT
    VO_Alive          : BOOL;
    VO_Watchdog_Fault : BOOL;
    VO_Cycle_DT_MS    : UDINT;
END_VAR

VAR
    L_Initialized    : BOOL := FALSE;
    L_Last_Call_MS   : UDINT := 0;
    L_DT_MS          : UDINT := 0;
END_VAR

IF NOT L_Initialized THEN
    L_Initialized := TRUE;
    L_Last_Call_MS := VI_System_Time_MS;
    VO_Cycle_DT_MS := 0;
    VO_Watchdog_Fault := FALSE;
    VO_Alive := TRUE;
    RETURN;
END_IF;

// Measure real time gap between successive calls
L_DT_MS := (SEL(VI_System_Time_MS >= L_Last_Call_MS, VI_System_Time_MS - L_Last_Call_MS, (4294967295 - L_Last_Call_MS) + VI_System_Time_MS + 1));
VO_Cycle_DT_MS := L_DT_MS;

// Fault if the task/cycle resumed after an abnormal pause
VO_Watchdog_Fault := (L_DT_MS > VI_Timeout_MS);
VO_Alive := NOT VO_Watchdog_Fault;

// Store current timestamp for next cycle
L_Last_Call_MS := VI_System_Time_MS;
// >>> BULK_SYNC_ANCHOR: FB_Watchdog <<<
END_FUNCTION_BLOCK
