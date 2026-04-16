FUNCTION_BLOCK FB_Alarm_Legacy_To_V2_Adapter_DRAFT
VAR_INPUT
    VI_Alarm_Legacy : ST_Alarm;
END_VAR
VAR_OUTPUT
    VO_Alarm_V2 : ST_Alarm_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_Alarm_V2.id := VI_Alarm_Legacy.id;
VO_Alarm_V2.enabled := VI_Alarm_Legacy.enabled;
VO_Alarm_V2.severity := VI_Alarm_Legacy.severity;
VO_Alarm_V2.source_id := VI_Alarm_Legacy.source_id;
VO_Alarm_V2.active := VI_Alarm_Legacy.active;

VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
