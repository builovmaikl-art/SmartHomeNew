FUNCTION_BLOCK FB_Diagnostics_Event_Manager
VAR_INPUT
    VI_Code : UDINT;
    VI_Severity : INT;
    VI_Active : BOOL;
    VI_Timestamp : UDINT;
    VI_Source : INT;
END_VAR
VAR_IN_OUT
    VIO_Events : ARRAY[1..50] OF ST_Diagnostic_Event;
    VIO_Count : INT;
END_VAR
VAR
    L_Index : INT;
END_VAR

// Ring buffer write on activation edge
IF VI_Active THEN
    L_Index := (VIO_Count MOD 50) + 1;
    VIO_Events[L_Index].Code := VI_Code;
    VIO_Events[L_Index].Severity := VI_Severity;
    VIO_Events[L_Index].Active := TRUE;
    VIO_Events[L_Index].Timestamp := VI_Timestamp;
    VIO_Events[L_Index].Source := VI_Source;

    IF VIO_Count < 50 THEN
        VIO_Count := VIO_Count + 1;
    ELSE
        VIO_Count := VIO_Count + 1; // keeps growing logically
    END_IF;
END_IF;

// >>> BULK_SYNC_ANCHOR: FB_Diagnostics_Event_Manager <<<
