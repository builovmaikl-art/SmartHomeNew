// ==============================================================================
// System alarm orchestrator helper
//
// Internal helper for PRG_System.
// Owns FB_Alarm_Manager call and alarm output projection.
// ==============================================================================
FUNCTION_BLOCK FB_System_Alarm_Orchestrator
VAR_INPUT
    VI_First_Fault_Active : BOOL;
    VI_First_Fault_Type : INT;
    VI_First_Fault_Source : INT;
END_VAR

VAR
    fbAlarmManager : FB_Alarm_Manager;
END_VAR

fbAlarmManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Gas_Alarm := GVL_ALARM.G_Gas_Alarm_Active,
    VI_Fire_Alarm := GVL_ALARM.G_Fire_Alarm_Active,
    VI_Flood_Alarm := GVL_ALARM.G_Flood_Alarm_Active,
    VI_Security_Alarm := GVL_ALARM.G_Security_Alarm,
    VI_First_Fault_Active := VI_First_Fault_Active,
    VI_First_Fault_Type := VI_First_Fault_Type,
    VI_First_Fault_Source := VI_First_Fault_Source,
    VI_Boiler_Errors := GVL_STATE.G_Boiler_Error,
    VI_Security_Msg := GVL_STATUS.G_Security_Status_Msg,
    VI_Acknowledge_All := GVL_CONFIG.G_HMI_Ack_Alarms OR GVL_COMMAND.G_Reset_Errors,
    VI_Mute_Siren := GVL_CONFIG.G_HMI_Mute_Alarm,
    VIO_Next_Alarm_ID := GVL_ALARM.G_Next_Alarm_ID,
    VO_Global_Critical => GVL_ALARM.G_Global_Critical,
    VO_Global_Warning => GVL_ALARM.G_Global_Warning,
    VO_Siren_Active => GVL_ALARM.G_Global_Siren,
    VO_Active_Count => GVL_ALARM.G_Active_Alarm_Count,
    VO_Unacked_Count => GVL_ALARM.G_Unacked_Alarm_Count,
    VO_Event_Pulse => GVL_STATUS.G_Diagnostics.Alarm_Event_Pulse,
    VO_Event_Code => GVL_STATUS.G_Diagnostics.Alarm_Event_Code,
    VO_Event_Value => GVL_STATUS.G_Diagnostics.Alarm_Event_Value,
    VO_Alarm_List => GVL_ALARM.G_Alarm_List
);

// >>> BULK_SYNC_ANCHOR: FB_System_Alarm_Orchestrator <<<
