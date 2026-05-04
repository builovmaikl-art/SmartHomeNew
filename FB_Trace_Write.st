FUNCTION_BLOCK FB_Trace_Write
VAR_INPUT
    iLayer : E_Trace_Layer;
    iSource : E_Trace_Source;
    iReason : E_System_Reason_Code;
    iValueBool : BOOL;
    iValueReal : REAL;
    iText : STRING(120);
END_VAR

VAR
    L_Index : INT;
END_VAR

IF NOT GVL_TRACE.G_Trace_Enabled THEN RETURN; END_IF;

L_Index := GVL_TRACE.G_Trace_Write_Index;

GVL_TRACE.G_Trace_Buffer[L_Index].Timestamp_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_TRACE.G_Trace_Buffer[L_Index].Layer := iLayer;
GVL_TRACE.G_Trace_Buffer[L_Index].Source := iSource;
GVL_TRACE.G_Trace_Buffer[L_Index].Reason_Code := iReason;
GVL_TRACE.G_Trace_Buffer[L_Index].Value_Bool := iValueBool;
GVL_TRACE.G_Trace_Buffer[L_Index].Value_Real := iValueReal;
GVL_TRACE.G_Trace_Buffer[L_Index].Text := iText;

L_Index := L_Index + 1;
IF L_Index > 200 THEN L_Index := 1; END_IF;

GVL_TRACE.G_Trace_Write_Index := L_Index;
END_FUNCTION_BLOCK
