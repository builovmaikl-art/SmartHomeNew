FUNCTION_BLOCK FB_History_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Write_Event    : BOOL;
    VI_Event          : ST_History_Record;
END_VAR
VAR_OUTPUT
    VO_Total_Events   : UDINT;
END_VAR
VAR
    L_Prev_Write_Event : BOOL;
END_VAR

IF VI_Write_Event AND NOT L_Prev_Write_Event THEN
    GVL_Retain.G_History_Buffer[GVL_Retain.G_History_Write_Idx] := VI_Event;
    GVL_Retain.G_History_Buffer[GVL_Retain.G_History_Write_Idx].timestamp_ms := VI_System_Time_MS;
    
    GVL_Retain.G_History_Write_Idx := (GVL_Retain.G_History_Write_Idx MOD GVL_CONSTANTS.C_MAX_HISTORY_RECORDS) + 1;
    GVL_Retain.G_History_Total_Events := GVL_Retain.G_History_Total_Events + 1;
END_IF;
L_Prev_Write_Event := VI_Write_Event;

VO_Total_Events := GVL_Retain.G_History_Total_Events;
// >>> BULK_SYNC_ANCHOR: FB_History_Manager <<<
