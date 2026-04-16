FUNCTION_BLOCK FB_History_Legacy_To_V2_Adapter_DRAFT
VAR_INPUT
    VI_History_Legacy : ST_History_Record;
END_VAR
VAR_OUTPUT
    VO_History_V2 : ST_History_Event_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_History_V2.Timestamp_MS := VI_History_Legacy.Timestamp_MS;
VO_History_V2.Event_Code := VI_History_Legacy.Event_Code;
VO_History_V2.Event_Value := VI_History_Legacy.Event_Value;
VO_History_V2.Source_Domain := 0;
VO_History_V2.Source_ID := 0;
VO_History_V2.Priority := E_ALERT_PRIORITY.ALERT_PRIORITY_INFO;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
