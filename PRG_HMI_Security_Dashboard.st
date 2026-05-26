PROGRAM PRG_HMI_Security_Dashboard
VAR
    L_i : INT;
    L_Motion_Count : INT;
    L_Door_Count : INT;
    L_Window_Count : INT;
END_VAR

L_Motion_Count := 0;
L_Door_Count := 0;
L_Window_Count := 0;

GVL_HMI_SECURITY.G_Armed := GVL_ALARM.G_Security_Armed;
GVL_HMI_SECURITY.G_Alarm_Active := GVL_ALARM.G_Security_Alarm;
GVL_HMI_SECURITY.G_Siren_Request := GVL_ALARM.G_Security_Siren;
GVL_HMI_SECURITY.G_Security_Alarm := GVL_ALARM.G_Security_Alarm;
GVL_HMI_SECURITY.G_Security_Siren := GVL_ALARM.G_Security_Siren;
GVL_HMI_SECURITY.G_Global_Siren := GVL_ALARM.G_Global_Siren;
GVL_HMI_SECURITY.G_Status_Text := GVL_STATUS.G_Security_Status_Msg;
GVL_HMI_SECURITY.G_Arm_Request := GVL_INTENT_USER.I_Arm_Request;
GVL_HMI_SECURITY.G_Disarm_Request := GVL_INTENT_USER.I_Disarm_Request;
GVL_HMI_SECURITY.G_Send_2FA_Req := GVL_COMMAND.G_Send_2FA_Req;
GVL_HMI_SECURITY.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

GVL_HMI_SECURITY.G_Safety_Access_Active :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = FIRE)
    OR (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS);
GVL_HMI_SECURITY.G_Sensor_Path_Suppressed_By_Safety := GVL_HMI_SECURITY.G_Safety_Access_Active;

IF GVL_HMI_SECURITY.G_Sensor_Path_Suppressed_By_Safety THEN
    GVL_HMI_SECURITY.G_Sensor_Path_Status_Text := 'Security sensors suppressed by safety access mode';
ELSE
    GVL_HMI_SECURITY.G_Sensor_Path_Status_Text := 'Security sensors active';
END_IF;

GVL_HMI_SECURITY.G_Arming_In_Progress := GVL_SECURITY_WORKFLOW.G_Arming_In_Progress;
GVL_HMI_SECURITY.G_Arm_Delay_ET := GVL_SECURITY_WORKFLOW.G_Arm_Delay_ET;
GVL_HMI_SECURITY.G_Arm_Delay_Q := GVL_SECURITY_WORKFLOW.G_Arm_Delay_Q;
GVL_HMI_SECURITY.G_Pin_Entry_Active := GVL_SECURITY_WORKFLOW.G_Pin_Entry_Active;
GVL_HMI_SECURITY.G_Entry_Delay_ET := GVL_SECURITY_WORKFLOW.G_Entry_Delay_ET;
GVL_HMI_SECURITY.G_Entry_Delay_Q := GVL_SECURITY_WORKFLOW.G_Entry_Delay_Q;
GVL_HMI_SECURITY.G_Pin_Fail_Count := GVL_SECURITY_WORKFLOW.G_Pin_Fail_Count;
GVL_HMI_SECURITY.G_Max_Attempts := GVL_SECURITY_WORKFLOW.G_Max_Attempts;
GVL_HMI_SECURITY.G_Disarm_Pending := GVL_SECURITY_WORKFLOW.G_Disarm_Pending;
GVL_HMI_SECURITY.G_2FA_Required := GVL_SECURITY_WORKFLOW.G_2FA_Required;
GVL_HMI_SECURITY.G_2FA_Send_Code_Req := GVL_SECURITY_WORKFLOW.G_2FA_Send_Code_Req;
GVL_HMI_SECURITY.G_Combined_Window_Active := GVL_SECURITY_WORKFLOW.G_Combined_Window_Active;
GVL_HMI_SECURITY.G_Combined_Event_Count := GVL_SECURITY_WORKFLOW.G_Combined_Event_Count;
GVL_HMI_SECURITY.G_Perimeter_Active_Count := GVL_SECURITY_WORKFLOW.G_Intrusion_Active_Count;
GVL_HMI_SECURITY.G_Perimeter_Event_Count := GVL_SECURITY_WORKFLOW.G_Intrusion_Event_Count;
GVL_HMI_SECURITY.G_Any_Sensor_Active := GVL_SECURITY_WORKFLOW.G_Any_Sensor_Active;
GVL_HMI_SECURITY.G_Door_Blocking_Open := GVL_SECURITY_WORKFLOW.G_Door_Blocking_Open;
GVL_HMI_SECURITY.G_Window_Blocking_Open := GVL_SECURITY_WORKFLOW.G_Window_Blocking_Open;
GVL_HMI_SECURITY.G_Workflow_Status_Text := GVL_SECURITY_WORKFLOW.G_Status_Text;
GVL_HMI_SECURITY.G_Workflow_Last_Update_MS := GVL_SECURITY_WORKFLOW.G_Last_Update_MS;

FOR L_i := 1 TO 16 DO
    GVL_HMI_SECURITY.G_Motion_Active[L_i] := GVL_STATE.G_Motion_Sensors[L_i];
    GVL_HMI_SECURITY.G_Motion_Bypass[L_i] := GVL_CONFIG.G_Security_Config.bypass_motion[L_i];

    IF GVL_STATE.G_Motion_Sensors[L_i] AND NOT GVL_CONFIG.G_Security_Config.bypass_motion[L_i] THEN
        L_Motion_Count := L_Motion_Count + 1;
    END_IF;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_DOOR_SENSORS DO
    GVL_HMI_SECURITY.G_Door_Active[L_i] := GVL_STATE.G_Door_Sensors[L_i];
    GVL_HMI_SECURITY.G_Door_Bypass[L_i] := GVL_CONFIG.G_Security_Config.bypass_doors[L_i];

    IF GVL_STATE.G_Door_Sensors[L_i] AND NOT GVL_CONFIG.G_Security_Config.bypass_doors[L_i] THEN
        L_Door_Count := L_Door_Count + 1;
    END_IF;
END_FOR;

FOR L_i := 1 TO 16 DO
    GVL_HMI_SECURITY.G_Window_Active[L_i] := GVL_STATE.G_Window_Sensors[L_i];
    GVL_HMI_SECURITY.G_Window_Bypass[L_i] := GVL_CONFIG.G_Security_Config.bypass_windows[L_i];

    IF GVL_STATE.G_Window_Sensors[L_i] AND NOT GVL_CONFIG.G_Security_Config.bypass_windows[L_i] THEN
        L_Window_Count := L_Window_Count + 1;
    END_IF;
END_FOR;

GVL_HMI_SECURITY.G_Motion_Active_Count := L_Motion_Count;
GVL_HMI_SECURITY.G_Door_Active_Count := L_Door_Count;
GVL_HMI_SECURITY.G_Window_Active_Count := L_Window_Count;
GVL_HMI_SECURITY.G_Total_Active_Count := L_Motion_Count + L_Door_Count + L_Window_Count;

IF GVL_ALARM.G_Security_Alarm THEN
    GVL_HMI_SECURITY.G_Status_Level := 3;
ELSIF GVL_SECURITY_WORKFLOW.G_Pin_Entry_Active OR GVL_SECURITY_WORKFLOW.G_Arming_In_Progress OR GVL_SECURITY_WORKFLOW.G_Disarm_Pending THEN
    GVL_HMI_SECURITY.G_Status_Level := 2;
ELSIF GVL_ALARM.G_Security_Armed THEN
    GVL_HMI_SECURITY.G_Status_Level := 1;
ELSE
    GVL_HMI_SECURITY.G_Status_Level := 0;
END_IF;

// >>> BULK_SYNC_ANCHOR: PRG_HMI_Security_Dashboard <<<
END_PROGRAM