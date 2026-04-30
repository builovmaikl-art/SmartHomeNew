PROGRAM PRG_System_Diagnostics
VAR
    fbSystemDiagnostics : FB_System_Diagnostics;
    fbStateTraceLog : FB_State_Trace_Log;
    fbAdapt : FB_Behavior_Adapt;
    L_Pumps_4 : ARRAY[1..4] OF BOOL;
    L_i : INT;
    L_Last_State_Trace_MS : UDINT;
    L_Hum : REAL;
END_VAR

FOR L_i := 1 TO 4 DO
    L_Pumps_4[L_i] := GVL_HEATING_OUTPUT.DO_Manifold_Pumps[L_i];
END_FOR;

fbSystemDiagnostics();

fbStateTraceLog(
    VI_System_Time := GVL_TIME_SERVICE.G_Now_MS,
    VI_Gas_Alarm := GVL_ALARM.G_Gas_Alarm_Active,
    VI_Leak_Alarm := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Pumps := L_Pumps_4,
    VO_Last_Change_Time => L_Last_State_Trace_MS
);

// Adaptive feedback example (VentBoost)
L_Hum := GVL_STATE.G_Room_Hum[1];
IF GVL_INTENT_BEHAVIOR.I_Request_Ventilation_Boost THEN
    IF L_Hum < 60.0 THEN
        fbAdapt(iScenario:=REASON_SCENARIO_VENT_BOOST,iSuccess:=TRUE);
    ELSE
        fbAdapt(iScenario:=REASON_SCENARIO_VENT_BOOST,iSuccess:=FALSE);
    END_IF;
END_IF;

END_PROGRAM
