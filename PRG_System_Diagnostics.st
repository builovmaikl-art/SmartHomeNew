PROGRAM PRG_System_Diagnostics
VAR
    fbSystemDiagnostics : FB_System_Diagnostics;
    fbStateTraceLog : FB_State_Trace_Log;
    L_Pumps_4 : ARRAY[1..4] OF BOOL;
    L_i : INT;
    L_Last_State_Trace_MS : UDINT;
END_VAR

FOR L_i := 1 TO 4 DO
    L_Pumps_4[L_i] := GVL_STATE.G_Manifold_Pumps[L_i];
END_FOR;

fbSystemDiagnostics();

fbStateTraceLog(
    VI_System_Time := GVL_TIME_SERVICE.G_Now_MS,
    VI_Gas_Alarm := GVL_ALARM.G_Gas_Alarm_Active,
    VI_Leak_Alarm := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Pumps := L_Pumps_4,
    VO_Last_Change_Time => L_Last_State_Trace_MS
);

GVL_STATUS.G_Diagnostics.Last_State_Change_MS := L_Last_State_Trace_MS;

END_PROGRAM
