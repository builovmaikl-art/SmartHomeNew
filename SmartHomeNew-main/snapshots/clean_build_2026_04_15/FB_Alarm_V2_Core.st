FUNCTION_BLOCK FB_Alarm_V2_Core
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Pending_Alarms : ARRAY[1..10] OF ST_Alarm_Record;
END_VAR
VAR_IN_OUT
    VIO_Alarm_List : ARRAY[1..GVL_CONSTANTS.C_MAX_ALARMS] OF ST_Alarm_Record;
    VIO_Next_Alarm_ID : UDINT;
END_VAR
VAR_OUTPUT
    VO_Event_Pulse : BOOL;
    VO_Event_Code : UDINT;
    VO_Event_Value : REAL;
END_VAR

VO_Event_Pulse := FALSE;
VO_Event_Code := 0;
VO_Event_Value := 0.0;
END_FUNCTION_BLOCK
