FUNCTION_BLOCK FB_Ownership_Watchdog
VAR_INPUT
    VI_Gas_Level : REAL;
    VI_Gas_Alarm : BOOL;
    VI_Leak_Alarm : BOOL;
    VI_Smoke_Alarm : BOOL;
END_VAR
VAR_OUTPUT
    VO_Ownership_Violation : BOOL;
END_VAR
VAR
    L_Last_Gas_Alarm : BOOL;
    L_Last_Leak_Alarm : BOOL;
    L_Last_Smoke_Alarm : BOOL;
END_VAR

VO_Ownership_Violation := FALSE;

// Gas: signal present, alarm disappeared
IF (VI_Gas_Level > 20.0) AND L_Last_Gas_Alarm AND (NOT VI_Gas_Alarm) THEN
    VO_Ownership_Violation := TRUE;
END_IF;

// Leak: once latched should not drop instantly
IF L_Last_Leak_Alarm AND (NOT VI_Leak_Alarm) THEN
    VO_Ownership_Violation := TRUE;
END_IF;

// Smoke: same rule
IF L_Last_Smoke_Alarm AND (NOT VI_Smoke_Alarm) THEN
    VO_Ownership_Violation := TRUE;
END_IF;

L_Last_Gas_Alarm := VI_Gas_Alarm;
L_Last_Leak_Alarm := VI_Leak_Alarm;
L_Last_Smoke_Alarm := VI_Smoke_Alarm;
