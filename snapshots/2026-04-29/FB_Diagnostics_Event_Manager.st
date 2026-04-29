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
    L_i : INT;
    L_Found_Index : INT;
    L_Was_Active : BOOL;
END_VAR

L_Found_Index := 0;
L_Was_Active := FALSE;

FOR L_i := 1 TO VIO_Count DO
    IF (VIO_Events[L_i].Code = VI_Code) AND (VIO_Events[L_i].Source = VI_Source) THEN
        L_Found_Index := L_i;
        L_Was_Active := VIO_Events[L_i].Active;
    END_IF;
END_FOR;

IF VI_Active THEN
    IF L_Found_Index = 0 THEN
        IF VIO_Count < 50 THEN
            VIO_Count := VIO_Count + 1;
            VIO_Events[VIO_Count].Code := VI_Code;
            VIO_Events[VIO_Count].Severity := VI_Severity;
            VIO_Events[VIO_Count].Active := TRUE;
            VIO_Events[VIO_Count].Timestamp := VI_Timestamp;
            VIO_Events[VIO_Count].Source := VI_Source;
        END_IF;
    ELSE
        VIO_Events[L_Found_Index].Severity := VI_Severity;
        IF NOT L_Was_Active THEN
            VIO_Events[L_Found_Index].Timestamp := VI_Timestamp;
        END_IF;
        VIO_Events[L_Found_Index].Active := TRUE;
    END_IF;
ELSE
    IF L_Found_Index > 0 THEN
        VIO_Events[L_Found_Index].Active := FALSE;
    END_IF;
END_IF;
