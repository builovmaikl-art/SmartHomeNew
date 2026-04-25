FUNCTION_BLOCK FB_Trace_Logger
VAR_INPUT
    VI_Event_Code : INT;
    VI_System_Time : UDINT;
END_VAR

GVL_TRACE.G_Trace_Index := GVL_TRACE.G_Trace_Index + 1;
IF GVL_TRACE.G_Trace_Index > GVL_TRACE.G_Trace_Max THEN
    GVL_TRACE.G_Trace_Index := 1;
END_IF;

GVL_TRACE.G_Trace_Time[GVL_TRACE.G_Trace_Index] := VI_System_Time;
GVL_TRACE.G_Trace_Code[GVL_TRACE.G_Trace_Index] := VI_Event_Code;
