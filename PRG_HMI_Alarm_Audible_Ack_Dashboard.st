PROGRAM PRG_HMI_Alarm_Audible_Ack_Dashboard

GVL_HMI_ALARM_AUDIBLE_ACK.G_Ack_Active := GVL_ALARM_AUDIBLE_ACK.G_Ack_Active;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Ack_Remaining_MS := GVL_ALARM_AUDIBLE_ACK.G_Ack_Remaining_MS;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Ack_Count_Current_Alarm := GVL_ALARM_AUDIBLE_ACK.G_Ack_Count_Current_Alarm;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Ack_Limit_Reached := GVL_ALARM_AUDIBLE_ACK.G_Ack_Limit_Reached;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Last_Ack_Accepted := GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Accepted;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Last_Ack_Denied := GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Denied;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Last_Denial_Code := GVL_ALARM_AUDIBLE_ACK.G_Last_Denial_Code;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Last_Event_MS := GVL_ALARM_AUDIBLE_ACK.G_Last_Event_MS;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Status_Text := GVL_ALARM_AUDIBLE_ACK.G_Status_Text;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Effective_Siren_Muted := GVL_ALARM_AUDIBLE_ACK.G_Ack_Active;

GVL_HMI_ALARM_AUDIBLE_ACK.G_Global_Siren_Request := GVL_ALARM.G_Global_Siren;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Global_Critical := GVL_ALARM.G_Global_Critical;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Gas_Fire_Siren_Request := GVL_ALARM.G_Gas_Fire_Siren;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Security_Siren_Request := GVL_ALARM.G_Security_Siren;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Output_Gas_Siren := GVL_IO.DO_Gas_Siren;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Output_Fire_Siren := GVL_IO.DO_Fire_Siren;
GVL_HMI_ALARM_AUDIBLE_ACK.G_Output_Security_Siren := GVL_IO.DO_Security_Siren;

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Alarm_Audible_Ack_Dashboard <<<
END_PROGRAM
