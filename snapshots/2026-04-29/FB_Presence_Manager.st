FUNCTION_BLOCK FB_Presence_Manager

VAR_INPUT
    VI_Motion_Sensors : ARRAY[1..32] OF BOOL;
    VI_System_Time_MS : UDINT;
END_VAR

VAR_OUTPUT
    VO_Any_Motion : BOOL;
    VO_Occupied : BOOL;
    VO_Auto_Away : BOOL;
    VO_Last_Motion_TS : UDINT;
END_VAR

VAR
    L_Last_Motion_TS : UDINT := 0;
    L_Initialized : BOOL := FALSE;
    L_Timeout_MS : UDINT := 900000; // 15 min away delay
    L_i : INT;
END_VAR

// detect any motion
VO_Any_Motion := FALSE;
FOR L_i := 1 TO 32 DO
    IF VI_Motion_Sensors[L_i] THEN
        VO_Any_Motion := TRUE;
    END_IF;
END_FOR;

// init protection (avoid instant AWAY at boot)
IF NOT L_Initialized THEN
    L_Last_Motion_TS := VI_System_Time_MS;
    L_Initialized := TRUE;
END_IF;

// fast return: any motion immediately updates timestamp
IF VO_Any_Motion THEN
    L_Last_Motion_TS := VI_System_Time_MS;
END_IF;

// hysteresis logic:
// stay OCCUPIED until timeout expires
IF (VI_System_Time_MS - L_Last_Motion_TS) < L_Timeout_MS THEN
    VO_Occupied := TRUE;
ELSE
    VO_Occupied := FALSE;
END_IF;

VO_Auto_Away := NOT VO_Occupied;
VO_Last_Motion_TS := L_Last_Motion_TS;
