FUNCTION_BLOCK FB_Alarm_V2_Core_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
END_VAR
VAR_IN_OUT
    VI_Pending_Alarms : ARRAY[1..10] OF ST_Alarm_Record;
    VIO_Alarm_List : ARRAY[1..GVL_CONSTANTS.C_MAX_ALARMS] OF ST_Alarm_Record;
    VIO_Next_Alarm_ID : UDINT;
END_VAR
VAR_OUTPUT
    VO_Event_Pulse : BOOL;
    VO_Event_Code : UDINT;
    VO_Event_Value : REAL;
END_VAR
VAR
    L_i : INT;
    L_k : INT;
    L_Target_Slot : INT;
    L_Min_Pri : INT;
END_VAR

VO_Event_Pulse := FALSE;
VO_Event_Code := 0;
VO_Event_Value := 0.0;

FOR L_i := 1 TO 10 DO
    IF VI_Pending_Alarms[L_i].Is_Active THEN
        L_Target_Slot := 0;

        // 1. Empty slot search
        FOR L_k := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
            IF VIO_Alarm_List[L_k].ID = 0 THEN
                L_Target_Slot := L_k;
                EXIT;
            END_IF;
        END_FOR;

        // 2. Acknowledged lowest-priority replacement
        IF L_Target_Slot = 0 THEN
            L_Min_Pri := 999;
            FOR L_k := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
                IF VIO_Alarm_List[L_k].Is_Acknowledged AND TO_INT(VIO_Alarm_List[L_k].Severity) < L_Min_Pri THEN
                    L_Min_Pri := TO_INT(VIO_Alarm_List[L_k].Severity);
                    L_Target_Slot := L_k;
                END_IF;
            END_FOR;
        END_IF;

        // 3. Lower-priority active replacement
        IF L_Target_Slot = 0 THEN
            L_Min_Pri := 999;
            FOR L_k := 1 TO GVL_CONSTANTS.C_MAX_ALARMS DO
                IF TO_INT(VIO_Alarm_List[L_k].Severity) < L_Min_Pri
                   AND TO_INT(VIO_Alarm_List[L_k].Severity) < TO_INT(VI_Pending_Alarms[L_i].Severity) THEN
                    L_Min_Pri := TO_INT(VIO_Alarm_List[L_k].Severity);
                    L_Target_Slot := L_k;
                END_IF;
            END_FOR;
        END_IF;

        IF L_Target_Slot <> 0 THEN
            VIO_Alarm_List[L_Target_Slot] := VI_Pending_Alarms[L_i];
            VIO_Alarm_List[L_Target_Slot].ID := VIO_Next_Alarm_ID;
            VIO_Next_Alarm_ID := VIO_Next_Alarm_ID + 1;
            IF VIO_Next_Alarm_ID = 0 THEN
                VIO_Next_Alarm_ID := 1;
            END_IF;

            IF NOT VO_Event_Pulse THEN
                VO_Event_Pulse := TRUE;
                VO_Event_Code := 1203;
                VO_Event_Value := TO_REAL(VIO_Alarm_List[L_Target_Slot].Severity);
            END_IF;
        END_IF;
    END_IF;
END_FOR;
END_FUNCTION_BLOCK
