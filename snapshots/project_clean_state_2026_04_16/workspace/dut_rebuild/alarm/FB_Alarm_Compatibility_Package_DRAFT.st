FUNCTION_BLOCK FB_Alarm_Compatibility_Package_DRAFT
VAR_INPUT
    VI_Alarm_Legacy : ST_Alarm;
END_VAR
VAR_OUTPUT
    VO_Alarm_Legacy_Roundtrip : ST_Alarm;
    VO_OK : BOOL;
END_VAR
VAR
    fbFwd : FB_Alarm_Legacy_To_V2_Adapter_DRAFT;
    fbRev : FB_Alarm_V2_To_Legacy_Adapter_DRAFT;
    L_Temp_V2 : ST_Alarm_V2;
END_VAR

fbFwd(VI_Alarm_Legacy := VI_Alarm_Legacy, VO_Alarm_V2 => L_Temp_V2, VO_Translation_OK => VO_OK);
fbRev(VI_Alarm_V2 := L_Temp_V2, VO_Alarm_Legacy => VO_Alarm_Legacy_Roundtrip);

END_FUNCTION_BLOCK
