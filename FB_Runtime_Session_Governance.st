FUNCTION_BLOCK FB_Runtime_Session_Governance
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Session : ST_Runtime_Node_Session;
    L_Any_Stale : BOOL;
    L_Any_Quarantine : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Runtime_Sessions.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

GVL_Runtime_Sessions.G_Local_Session.Session_Valid := TRUE;
GVL_Runtime_Sessions.G_Local_Session.Session_Connected := TRUE;
GVL_Runtime_Sessions.G_Local_Session.Last_Heartbeat_MS :=
    VI_System_Time_MS;

GVL_Runtime_Sessions.G_Local_Session.Transport_Healthy :=
    GVL_Runtime_Bus.G_TX_Healthy;

GVL_Runtime_Sessions.G_Local_Session.Runtime_Replication_Healthy :=
    GVL_Distributed_Runtime.G_Distributed_Replication_Healthy;

GVL_Runtime_Sessions.G_Local_Session.Authority_Granted :=
    GVL_Distributed_Authority.G_Authority_State.Authority_Master_Elected;

FOR L_i := 1 TO 16 DO

    L_Session := GVL_Runtime_Sessions.G_Remote_Sessions[L_i];

    IF L_Session.Session_Valid THEN

        IF (VI_System_Time_MS - L_Session.Last_Heartbeat_MS) > 30000 THEN

            L_Session.Session_Stale := TRUE;
            L_Session.Session_Reconnect_Required := TRUE;

            L_Any_Stale := TRUE;

        END_IF;

        IF L_Session.Session_Quarantined THEN
            L_Any_Quarantine := TRUE;
        END_IF;

        GVL_Runtime_Sessions.G_Remote_Sessions[L_i] :=
            L_Session;

    END_IF;

END_FOR;

GVL_Runtime_Sessions.G_Any_Stale_Session :=
    L_Any_Stale;

GVL_Runtime_Sessions.G_Any_Quarantined_Session :=
    L_Any_Quarantine;

GVL_Runtime_Sessions.G_Runtime_Valid := TRUE;
GVL_Runtime_Sessions.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Quarantine THEN
    GVL_Runtime_Sessions.G_Status_Code := 2;
    GVL_Runtime_Sessions.G_Status_Text :=
        'Quarantined runtime session detected';
ELSIF L_Any_Stale THEN
    GVL_Runtime_Sessions.G_Status_Code := 1;
    GVL_Runtime_Sessions.G_Status_Text :=
        'Stale runtime session detected';
ELSE
    GVL_Runtime_Sessions.G_Status_Code := 0;
    GVL_Runtime_Sessions.G_Status_Text :=
        'Runtime session governance healthy';
END_IF;

END_FUNCTION_BLOCK