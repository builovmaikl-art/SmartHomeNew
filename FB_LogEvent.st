FUNCTION_BLOCK FB_LogEvent
VAR_INPUT
    VI_Event_Type : UINT;
    VI_Timestamp  : UDINT;
    VI_Param1     : UDINT;
    VI_Param2     : UDINT;
END_VAR

GVL_EVENT.G_Event_Log[GVL_EVENT.G_Event_Head].Event_ID := GVL_EVENT.G_Event_ID_Counter;
GVL_EVENT.G_Event_Log[GVL_EVENT.G_Event_Head].Event_Type := VI_Event_Type;
GVL_EVENT.G_Event_Log[GVL_EVENT.G_Event_Head].Timestamp := VI_Timestamp;
GVL_EVENT.G_Event_Log[GVL_EVENT.G_Event_Head].Param1 := VI_Param1;
GVL_EVENT.G_Event_Log[GVL_EVENT.G_Event_Head].Param2 := VI_Param2;

GVL_EVENT.G_Event_ID_Counter := GVL_EVENT.G_Event_ID_Counter + 1;
GVL_EVENT.G_Event_Head := (GVL_EVENT.G_Event_Head + 1) MOD 64;
