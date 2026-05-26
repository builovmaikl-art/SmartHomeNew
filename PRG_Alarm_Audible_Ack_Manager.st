PROGRAM PRG_Alarm_Audible_Ack_Manager
VAR
    L_Audible_Alarm_Active : BOOL;
    L_Elapsed_MS : UDINT;
END_VAR

L_Audible_Alarm_Active :=
    GVL_HEALTH_BRIDGE.G_Gas_Detected OR
    GVL_HEALTH_BRIDGE.G_CO_Alarm_Level OR
    GVL_HEALTH_BRIDGE.G_Smoke_Detected OR
    GVL_HEALTH_BRIDGE.G_Leak_Detected OR
    GVL_ALARM.G_Security_Alarm OR
    GVL_ALARM.G_Global_Critical;

GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Accepted := FALSE;
GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Denied := FALSE;
GVL_ALARM_AUDIBLE_ACK.G_Last_Denial_Code := 0;

IF GVL_CONFIG.G_HMI_Mute_Alarm THEN
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Request := TRUE;
    GVL_CONFIG.G_HMI_Mute_Alarm := FALSE;
END_IF;

IF NOT L_Audible_Alarm_Active THEN
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Active := FALSE;
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Start_MS := 0;
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Expires_MS := 0;
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Remaining_MS := 0;
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Count_Current_Alarm := 0;
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Limit_Reached := FALSE;
    GVL_ALARM_AUDIBLE_ACK.G_Status_Text := 'Audible alarm acknowledgement idle';
END_IF;

IF GVL_ALARM_AUDIBLE_ACK.G_Ack_Active THEN
    IF GVL_TIME_SERVICE.G_Now_MS >= GVL_ALARM_AUDIBLE_ACK.G_Ack_Start_MS THEN
        L_Elapsed_MS := GVL_TIME_SERVICE.G_Now_MS - GVL_ALARM_AUDIBLE_ACK.G_Ack_Start_MS;
    ELSE
        L_Elapsed_MS := (4294967295 - GVL_ALARM_AUDIBLE_ACK.G_Ack_Start_MS) + GVL_TIME_SERVICE.G_Now_MS + 1;
    END_IF;

    IF L_Elapsed_MS >= (GVL_CONSTANTS.C_MS_IN_MINUTE * 5) THEN
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Active := FALSE;
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Remaining_MS := 0;
        GVL_ALARM_AUDIBLE_ACK.G_Status_Text := 'Audible alarm acknowledgement expired';
    ELSE
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Remaining_MS := (GVL_CONSTANTS.C_MS_IN_MINUTE * 5) - L_Elapsed_MS;
    END_IF;
END_IF;

IF GVL_ALARM_AUDIBLE_ACK.G_Ack_Request THEN
    IF NOT L_Audible_Alarm_Active THEN
        GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Denied := TRUE;
        GVL_ALARM_AUDIBLE_ACK.G_Last_Denial_Code := 1;
        GVL_ALARM_AUDIBLE_ACK.G_Status_Text := 'Audible acknowledgement denied: no active audible alarm';
    ELSIF GVL_INTENT_USER.I_User_Access_Level < 2 THEN
        GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Denied := TRUE;
        GVL_ALARM_AUDIBLE_ACK.G_Last_Denial_Code := 2;
        GVL_ALARM_AUDIBLE_ACK.G_Status_Text := 'Audible acknowledgement denied: access level < 2';
    ELSIF GVL_ALARM_AUDIBLE_ACK.G_Ack_Count_Current_Alarm >= 3 THEN
        GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Denied := TRUE;
        GVL_ALARM_AUDIBLE_ACK.G_Last_Denial_Code := 3;
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Limit_Reached := TRUE;
        GVL_ALARM_AUDIBLE_ACK.G_Status_Text := 'Audible acknowledgement denied: limit reached';
    ELSE
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Count_Current_Alarm := GVL_ALARM_AUDIBLE_ACK.G_Ack_Count_Current_Alarm + 1;
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Active := TRUE;
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Start_MS := GVL_TIME_SERVICE.G_Now_MS;
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Expires_MS := GVL_TIME_SERVICE.G_Now_MS + (GVL_CONSTANTS.C_MS_IN_MINUTE * 5);
        GVL_ALARM_AUDIBLE_ACK.G_Ack_Remaining_MS := GVL_CONSTANTS.C_MS_IN_MINUTE * 5;
        GVL_ALARM_AUDIBLE_ACK.G_Last_Ack_Accepted := TRUE;
        GVL_ALARM_AUDIBLE_ACK.G_Last_Event_MS := GVL_TIME_SERVICE.G_Now_MS;
        GVL_ALARM_AUDIBLE_ACK.G_Status_Text := 'Audible alarm acknowledged for 5 minutes';
    END_IF;

    GVL_ALARM_AUDIBLE_ACK.G_Ack_Request := FALSE;
END_IF;

IF GVL_ALARM_AUDIBLE_ACK.G_Ack_Count_Current_Alarm >= 3 THEN
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Limit_Reached := TRUE;
ELSE
    GVL_ALARM_AUDIBLE_ACK.G_Ack_Limit_Reached := FALSE;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_Alarm_Audible_Ack_Manager <<<
END_PROGRAM
