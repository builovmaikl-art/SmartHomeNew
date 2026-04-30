PROGRAM PRG_System_History
VAR
    fbHistoryManager : FB_History_Manager;
    L_History_Event : ST_History_Record;
    L_History_Write_Event : BOOL;
    L_Last_Root_Cause : E_System_Root_Cause;
END_VAR

L_History_Write_Event := FALSE;
L_History_Event.timestamp_ms := GVL_TIME_SERVICE.G_Now_MS;

IF GVL_SYSTEM_HEALTH.G_Root_Cause <> L_Last_Root_Cause THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1102;
    L_History_Event.event_value := TO_REAL(TO_INT(GVL_SYSTEM_HEALTH.G_Root_Cause));
    L_Last_Root_Cause := GVL_SYSTEM_HEALTH.G_Root_Cause;
END_IF;

fbHistoryManager(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Write_Event := L_History_Write_Event,
    VI_Event := L_History_Event
);

END_PROGRAM
