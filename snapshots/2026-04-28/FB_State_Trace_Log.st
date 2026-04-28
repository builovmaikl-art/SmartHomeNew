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
    L_Last_Gas : BOOL;
    L_Last_Leak : BOOL;
END_VAR

IF (VI_Gas_Alarm <> L_Last_Gas) OR (VI_Leak_Alarm <> L_Last_Leak) THEN
    VO_Last_Change_Time := VI_System_Time;
END_IF;

L_Last_Gas := VI_Gas_Alarm;
L_Last_Leak := VI_Leak_Alarm;
