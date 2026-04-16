FUNCTION_BLOCK FB_History_V2_Core
VAR_INPUT
    VI_Event_Pulse : BOOL;
    VI_Event_Code : UDINT;
    VI_Event_Value : REAL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR_IN_OUT
    VIO_History_Buffer : ARRAY[1..GVL_CONSTANTS.C_MAX_HISTORY_RECORDS] OF ST_History_Event_V2;
END_VAR

IF VI_Event_Pulse THEN
    VIO_History_Buffer[1].Event_Code := TO_UINT(VI_Event_Code);
    VIO_History_Buffer[1].Event_Value := VI_Event_Value;
END_IF;
END_FUNCTION_BLOCK
