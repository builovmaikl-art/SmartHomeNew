FUNCTION_BLOCK FB_State_Trace_Log
VAR_INPUT
    VI_System_Time : UDINT;
    VI_Gas_Alarm : BOOL;
    VI_Leak_Alarm : BOOL;
    VI_Pumps : ARRAY[1..4] OF BOOL;
END_VAR
VAR_OUTPUT
    VO_Last_Change_Time : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Last_Gas : BOOL;
    L_Last_Leak : BOOL;
    L_Last_Pumps : ARRAY[1..4] OF BOOL;
    L_Changed : BOOL;
END_VAR

L_Changed :=
    (VI_Gas_Alarm <> L_Last_Gas)
    OR (VI_Leak_Alarm <> L_Last_Leak);

FOR L_i := 1 TO 4 DO
    IF VI_Pumps[L_i] <> L_Last_Pumps[L_i] THEN
        L_Changed := TRUE;
    END_IF;
END_FOR;

IF L_Changed THEN
    VO_Last_Change_Time := VI_System_Time;
END_IF;

L_Last_Gas := VI_Gas_Alarm;
L_Last_Leak := VI_Leak_Alarm;

FOR L_i := 1 TO 4 DO
    L_Last_Pumps[L_i] := VI_Pumps[L_i];
END_FOR;

END_FUNCTION_BLOCK
