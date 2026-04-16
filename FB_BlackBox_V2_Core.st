FUNCTION_BLOCK FB_BlackBox_V2_Core
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_System_Mode : INT;
    VI_Critical_Alarm_Active : BOOL;
    VI_Warning_Active : BOOL;
    VI_First_Fault_Type : BYTE;
    VI_First_Fault_Source : BYTE;
    VI_Gas_Alarm : BOOL;
    VI_Fire_Alarm : BOOL;
    VI_Flood_Alarm : BOOL;
END_VAR
VAR_OUTPUT
    VO_Snapshot : ST_BlackBox_Snapshot_V2;
END_VAR

VO_Snapshot.Gas_Alarm := VI_Gas_Alarm;
VO_Snapshot.Fire_Alarm := VI_Fire_Alarm;
VO_Snapshot.Flood_Alarm := VI_Flood_Alarm;
VO_Snapshot.First_Fault_Type := VI_First_Fault_Type;
VO_Snapshot.First_Fault_Source := VI_First_Fault_Source;
END_FUNCTION_BLOCK
