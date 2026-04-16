FUNCTION_BLOCK FB_Alarm_Compatibility_Package
VAR_INPUT
    VI_Alarm_Legacy : ST_Alarm_Record;
END_VAR
VAR_OUTPUT
    VO_OK : BOOL;
    VO_Alarm_Legacy_Roundtrip : ST_Alarm_Record;
END_VAR

VO_OK := TRUE;
VO_Alarm_Legacy_Roundtrip := VI_Alarm_Legacy;
END_FUNCTION_BLOCK
