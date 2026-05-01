PROGRAM PRG_Safety_Recovery
VAR
    L_Phase : E_Recovery_Phase;
    L_Mode_Active : BOOL;
END_VAR

// Determine if safety still active
L_Mode_Active := GVL_SAFETY_SHUTDOWN.G_Safety_Active;

L_Phase := GVL_SAFETY_RECOVERY.G_Recovery_Phase;

CASE L_Phase OF

    IDLE:
        IF NOT L_Mode_Active AND GVL_SAFETY_RECOVERY.G_Recovery_Requested THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := STABILIZING;
            GVL_SAFETY_RECOVERY.G_Recovery_Active := TRUE;
            GVL_SAFETY_RECOVERY.G_Recovery_Start_MS := GVL_TIME_SERVICE.G_Now_MS;
        END_IF;

    STABILIZING:
        IF (GVL_TIME_SERVICE.G_Now_MS - GVL_SAFETY_RECOVERY.G_Recovery_Start_MS) > GVL_SAFETY_RECOVERY_CONFIG.G_Stabilization_Delay_MS THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := WAIT_MANUAL_CONFIRM;
        END_IF;

    WAIT_MANUAL_CONFIRM:
        IF GVL_SAFETY_RECOVERY.G_Recovery_Manual_Confirm THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := RECOVERING;
        END_IF;

    RECOVERING:
        GVL_SAFETY_RECOVERY.G_Recovery_Phase := IDLE;
        GVL_SAFETY_RECOVERY.G_Recovery_Active := FALSE;
        GVL_SAFETY_RECOVERY.G_Recovery_Requested := FALSE;
        GVL_SAFETY_RECOVERY.G_Recovery_Manual_Confirm := FALSE;

END_CASE;

// >>> BULK_SYNC_ANCHOR: PRG_Safety_Recovery <<<
