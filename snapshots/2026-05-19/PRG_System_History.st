PROGRAM PRG_System_History
VAR
    fbHistoryManager : FB_History_Manager;
    L_History_Event : ST_History_Record;
    L_History_Write_Event : BOOL;
    L_Last_System_Mode : E_System_Operating_Mode;
    L_Last_Root_Cause : E_System_Root_Cause;
    L_Last_First_Fault_Source : INT;
    L_Last_Operator_Journal_Seq : UDINT;
    L_Last_Event_Code : UDINT;
    L_Last_Event_Value : REAL;
    L_Last_Event_Time_MS : UDINT;
END_VAR

L_History_Write_Event := FALSE;
L_History_Event.timestamp_ms := GVL_TIME_SERVICE.G_Now_MS;
L_History_Event.event_code := 0;
L_History_Event.event_value := 0.0;
L_History_Event.unit := 0;
L_History_Event.zone_id := 0;
L_History_Event.operator_id := 'SYSTEM';
L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;

IF GVL_STATE.G_System_Mode <> L_Last_System_Mode THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1101;
    L_History_Event.event_value := TO_REAL(TO_INT(GVL_STATE.G_System_Mode));
    L_History_Event.unit := 1;
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_System_Mode := GVL_STATE.G_System_Mode;

ELSIF GVL_SYSTEM_HEALTH.G_Root_Cause <> L_Last_Root_Cause THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1102;
    L_History_Event.event_value := TO_REAL(TO_INT(GVL_SYSTEM_HEALTH.G_Root_Cause));
    L_History_Event.unit := 2;
    L_History_Event.zone_id := TO_BYTE(GVL_SYSTEM_HEALTH.G_First_Fault_Source);
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_Root_Cause := GVL_SYSTEM_HEALTH.G_Root_Cause;

ELSIF GVL_SYSTEM_HEALTH.G_First_Fault_Source <> L_Last_First_Fault_Source THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1103;
    L_History_Event.event_value := TO_REAL(GVL_SYSTEM_HEALTH.G_First_Fault_Source);
    L_History_Event.unit := 3;
    L_History_Event.zone_id := TO_BYTE(GVL_SYSTEM_HEALTH.G_First_Fault_Source);
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_First_Fault_Source := GVL_SYSTEM_HEALTH.G_First_Fault_Source;

ELSIF GVL_STATUS.G_Current_Scenario <> GVL_STATUS.G_Previous_Scenario THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1001;
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Current_Scenario);
    L_History_Event.unit := 4;
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    GVL_STATUS.G_Previous_Scenario := GVL_STATUS.G_Current_Scenario;

ELSIF GVL_STATUS.G_Diagnostics.Alarm_Event_Pulse THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := TO_WORD(GVL_STATUS.G_Diagnostics.Alarm_Event_Code);
    L_History_Event.event_value := GVL_STATUS.G_Diagnostics.Alarm_Event_Value;
    L_History_Event.unit := 10;
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;

ELSIF GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq <> L_Last_Operator_Journal_Seq THEN
    L_History_Write_Event := TRUE;
    L_History_Event.event_code := 1301;
    L_History_Event.event_value := TO_REAL(GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq);
    L_History_Event.unit := 20;
    L_History_Event.zone_id := 0;
    L_History_Event.priority := E_ALERT_PRIORITY.ALERT_PRIORITY_HIGH;
    L_Last_Operator_Journal_Seq := GVL_STATUS.G_Diagnostics.Operator_Journal_Event_Seq;
END_IF;

IF L_History_Write_Event THEN
    IF (L_History_Event.event_code = L_Last_Event_Code)
       AND (ABS(L_History_Event.event_value - L_Last_Event_Value) < 0.001)
       AND (GVL_TIME_SERVICE.G_Now_MS - L_Last_Event_Time_MS < 5000) THEN
        L_History_Write_Event := FALSE;
    ELSE
        L_Last_Event_Code := L_History_Event.event_code;
        L_Last_Event_Value := L_History_Event.event_value;
        L_Last_Event_Time_MS := GVL_TIME_SERVICE.G_Now_MS;
    END_IF;
END_IF;

fbHistoryManager(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Write_Event := L_History_Write_Event,
    VI_Event := L_History_Event
);

END_PROGRAM
