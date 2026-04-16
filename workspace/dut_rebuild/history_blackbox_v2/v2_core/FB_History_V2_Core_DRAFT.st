FUNCTION_BLOCK FB_History_V2_Core_DRAFT
VAR_INPUT
    VI_Event_Pulse : BOOL;
    VI_Event_Code : UDINT;
    VI_Event_Value : REAL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR_IN_OUT
    VIO_History_Buffer : ARRAY[1..GVL_CONSTANTS.C_MAX_HISTORY_RECORDS] OF ST_History_Event_V2;
END_VAR
VAR
    L_i : INT;
END_VAR

IF VI_Event_Pulse THEN
    FOR L_i := GVL_CONSTANTS.C_MAX_HISTORY_RECORDS TO 2 BY -1 DO
        VIO_History_Buffer[L_i] := VIO_History_Buffer[L_i - 1];
    END_FOR;

    VIO_History_Buffer[1].Timestamp_MS := VI_System_Time_MS;
    VIO_History_Buffer[1].Event_Code := VI_Event_Code;
    VIO_History_Buffer[1].Event_Value := VI_Event_Value;
END_IF;
END_FUNCTION_BLOCK
