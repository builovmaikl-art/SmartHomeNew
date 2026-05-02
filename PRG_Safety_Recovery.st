PROGRAM PRG_Safety_Recovery
VAR
    L_Phase : E_Recovery_Phase;
    L_Mode_Active : BOOL;
    L_Time_OK : BOOL;
END_VAR

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
        IF L_Mode_Active THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := ABORTED;
            GVL_SAFETY_RECOVERY.G_Recovery_Abort_Reason := 1;
        ELSIF (GVL_TIME_SERVICE.G_Now_MS - GVL_SAFETY_RECOVERY.G_Recovery_Start_MS) > GVL_SAFETY_RECOVERY_CONFIG.G_Stabilization_Delay_MS THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := WAIT_MANUAL_CONFIRM;
            GVL_SAFETY_RECOVERY.G_Recovery_Stable_Since_MS := GVL_TIME_SERVICE.G_Now_MS;
        END_IF;

    WAIT_MANUAL_CONFIRM:
        IF L_Mode_Active THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := ABORTED;
            GVL_SAFETY_RECOVERY.G_Recovery_Abort_Reason := 1;
        ELSIF GVL_SAFETY_RECOVERY.G_Recovery_Manual_Confirm THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := RECOVERING;
        END_IF;

    RECOVERING:
        IF L_Mode_Active THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := ABORTED;
            GVL_SAFETY_RECOVERY.G_Recovery_Abort_Reason := 1;
        ELSE
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := COOLDOWN;
            GVL_SAFETY_RECOVERY.G_Recovery_Cooldown_Start_MS := GVL_TIME_SERVICE.G_Now_MS;
        END_IF;

    COOLDOWN:
        IF L_Mode_Active THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := ABORTED;
            GVL_SAFETY_RECOVERY.G_Recovery_Abort_Reason := 1;
        ELSE
            L_Time_OK := (GVL_TIME_SERVICE.G_Now_MS - GVL_SAFETY_RECOVERY.G_Recovery_Cooldown_Start_MS) > GVL_SAFETY_RECOVERY_CONFIG.G_Cooldown_Time_MS;

            IF L_Time_OK THEN
                GVL_SAFETY_RECOVERY.G_Recovery_Phase := IDLE;
                GVL_SAFETY_RECOVERY.G_Recovery_Active := FALSE;
                GVL_SAFETY_RECOVERY.G_Recovery_Requested := FALSE;
                GVL_SAFETY_RECOVERY.G_Recovery_Manual_Confirm := FALSE;
            END_IF;
        END_IF;

    ABORTED:
        GVL_SAFETY_RECOVERY.G_Recovery_Active := FALSE;
        IF NOT L_Mode_Active THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := IDLE;
        END_IF;

END_CASE;

END_PROGRAM
// >>> BULK_SYNC_ANCHOR: PRG_Safety_Recovery <<<
