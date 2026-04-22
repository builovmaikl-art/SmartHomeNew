FUNCTION_BLOCK FB_Fault_Logger
VAR_INPUT
    VI_Severity  : E_System_Severity;
    VI_RootCause : E_System_Root_Cause;
    VI_Time_MS   : UDINT;
END_VAR

VAR_OUTPUT
    VO_Last_Event_Text : STRING(200);
    VO_Event_Count     : UINT;
    VO_Last_Index      : UINT;

    VO_Event_Time_MS   : ARRAY[1..16] OF UDINT;
    VO_Event_Severity  : ARRAY[1..16] OF E_System_Severity;
    VO_Event_RootCause : ARRAY[1..16] OF E_System_Root_Cause;
    VO_Event_Text      : ARRAY[1..16] OF STRING(200);
END_VAR

VAR
    L_Last_Severity  : E_System_Severity;
    L_Last_RootCause : E_System_Root_Cause;
    L_Write_Index    : UINT := 0;
    L_Event_Text     : STRING(200);
END_VAR

L_Event_Text := '';

IF (VI_Severity <> L_Last_Severity) OR (VI_RootCause <> L_Last_RootCause) THEN
    CASE VI_RootCause OF
        E_System_Root_Cause.ROOT_FIRE:
            L_Event_Text := 'EVENT: FIRE DETECTED';
        E_System_Root_Cause.ROOT_GAS_LEAK:
            L_Event_Text := 'EVENT: GAS LEAK';
        E_System_Root_Cause.ROOT_CO_CRITICAL:
            L_Event_Text := 'EVENT: CO CRITICAL';
        E_System_Root_Cause.ROOT_CO_WARNING:
            L_Event_Text := 'EVENT: CO WARNING';
        E_System_Root_Cause.ROOT_WATER_LEAK:
            L_Event_Text := 'EVENT: WATER LEAK';
        E_System_Root_Cause.ROOT_SENSOR_FAULT:
            L_Event_Text := 'EVENT: SENSOR FAULT';
        E_System_Root_Cause.ROOT_IO_OFFLINE:
            L_Event_Text := 'EVENT: IO OFFLINE';
        E_System_Root_Cause.ROOT_COMM_FAULT:
            L_Event_Text := 'EVENT: COMM FAULT';
        E_System_Root_Cause.ROOT_WATCHDOG_FAULT:
            L_Event_Text := 'EVENT: WATCHDOG FAULT';
        E_System_Root_Cause.ROOT_SUBSYSTEM_FAULT:
            L_Event_Text := 'EVENT: SUBSYSTEM FAULT';
        ELSE
            L_Event_Text := 'EVENT: SYSTEM STATE CHANGE';
    END_CASE;

    L_Write_Index := L_Write_Index + 1;
    IF L_Write_Index > 16 THEN
        L_Write_Index := 1;
    END_IF;

    VO_Event_Time_MS[L_Write_Index] := VI_Time_MS;
    VO_Event_Severity[L_Write_Index] := VI_Severity;
    VO_Event_RootCause[L_Write_Index] := VI_RootCause;
    VO_Event_Text[L_Write_Index] := L_Event_Text;

    VO_Last_Index := L_Write_Index;
    VO_Last_Event_Text := L_Event_Text;

    IF VO_Event_Count < 16 THEN
        VO_Event_Count := VO_Event_Count + 1;
    END_IF;
END_IF;

L_Last_Severity := VI_Severity;
L_Last_RootCause := VI_RootCause;
// >>> BULK_SYNC_ANCHOR: FB_Fault_Logger <<<
