PROGRAM PRG_Security_Auto_Lock_Intent
VAR
    L_Last_Armed : BOOL;
END_VAR

IF GVL_ALARM.G_Security_Armed AND NOT L_Last_Armed THEN
    GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Request := TRUE;
    GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Accepted_By_Arbitration := FALSE;
    GVL_SECURITY_ACCESS_INTENT.G_Last_Auto_Lock_Request_MS := GVL_TIME_SERVICE.G_Now_MS;
    GVL_SECURITY_ACCESS_INTENT.G_Status_Text := 'Security auto-lock requested';
ELSIF NOT GVL_ALARM.G_Security_Armed THEN
    GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Request := FALSE;
    GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Accepted_By_Arbitration := FALSE;
    GVL_SECURITY_ACCESS_INTENT.G_Status_Text := 'Security access intent idle';
ELSIF GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Accepted_By_Arbitration THEN
    GVL_SECURITY_ACCESS_INTENT.G_Auto_Lock_Close_Request := FALSE;
    GVL_SECURITY_ACCESS_INTENT.G_Status_Text := 'Security auto-lock accepted';
END_IF;

L_Last_Armed := GVL_ALARM.G_Security_Armed;

// >>> BULK_SYNC_ANCHOR: PRG_Security_Auto_Lock_Intent <<<
END_PROGRAM
