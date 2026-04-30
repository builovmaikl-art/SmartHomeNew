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
        // wait fixed delay (example 5s)
        IF (GVL_TIME_SERVICE.G_Now_MS - GVL_SAFETY_RECOVERY.G_Recovery_Start_MS) > 5000 THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := WAIT_MANUAL_CONFIRM;
        END_IF;

    WAIT_MANUAL_CONFIRM:
        IF GVL_INTENT_USER.I_Reset_Errors THEN
            GVL_SAFETY_RECOVERY.G_Recovery_Phase := RECOVERING;
        END_IF;

    RECOVERING:
        // one cycle cleanup
        GVL_SAFETY_RECOVERY.G_Recovery_Phase := IDLE;
        GVL_SAFETY_RECOVERY.G_Recovery_Active := FALSE;
        GVL_SAFETY_RECOVERY.G_Recovery_Requested := FALSE;

END_CASE;

// >>> BULK_SYNC_ANCHOR: PRG_Safety_Recovery <<<
