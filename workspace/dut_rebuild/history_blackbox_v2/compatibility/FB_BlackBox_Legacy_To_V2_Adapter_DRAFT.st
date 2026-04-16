FUNCTION_BLOCK FB_BlackBox_Legacy_To_V2_Adapter_DRAFT
VAR_INPUT
    VI_BlackBox_Legacy : ST_BlackBox_Record;
END_VAR
VAR_OUTPUT
    VO_BlackBox_V2 : ST_BlackBox_Snapshot_V2;
    VO_Translation_OK : BOOL;
END_VAR

VO_BlackBox_V2.Timestamp_MS := VI_BlackBox_Legacy.Timestamp_MS;
VO_BlackBox_V2.System_Mode := VI_BlackBox_Legacy.System_Mode;
VO_BlackBox_V2.Critical_Alarm_Active := VI_BlackBox_Legacy.Critical_Alarm_Active;
VO_BlackBox_V2.Warning_Active := VI_BlackBox_Legacy.Warning_Active;
VO_BlackBox_V2.First_Fault_Type := VI_BlackBox_Legacy.First_Fault_Type;
VO_BlackBox_V2.First_Fault_Source := VI_BlackBox_Legacy.First_Fault_Source;
VO_BlackBox_V2.Gas_Alarm := VI_BlackBox_Legacy.Gas_Alarm;
VO_BlackBox_V2.Fire_Alarm := VI_BlackBox_Legacy.Fire_Alarm;
VO_BlackBox_V2.Flood_Alarm := VI_BlackBox_Legacy.Flood_Alarm;
VO_Translation_OK := TRUE;
END_FUNCTION_BLOCK
