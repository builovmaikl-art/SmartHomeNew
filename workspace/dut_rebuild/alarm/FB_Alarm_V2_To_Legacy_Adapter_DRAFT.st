FUNCTION_BLOCK FB_Alarm_V2_To_Legacy_Adapter_DRAFT
VAR_INPUT
    VI_Alarm_V2 : ST_Alarm_V2;
END_VAR
VAR_OUTPUT
    VO_Alarm_Legacy : ST_Alarm;
    VO_Translation_OK : BOOL;
END_VAR

VO_Alarm_Legacy.id := VI_Alarm_V2.id;
VO_Alarm_Legacy.enabled := VI_Alarm_V2.enabled;
VO_Alarm_Legacy.severity := VI_Alarm_V2.severity;
VO_Alarm_Legacy.source_id := VI_Alarm_V2.source_id;
VO_Alarm_Legacy.active := VI_Alarm_V2.active;

VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
