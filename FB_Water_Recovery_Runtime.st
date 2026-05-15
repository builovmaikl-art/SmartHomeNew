FUNCTION_BLOCK FB_Water_Recovery_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Feedback : ST_Water_Valve_Feedback_State;
    L_State : ST_Water_Recovery_Runtime_State;

    L_Any_Denied : BOOL;
    L_Any_Unsafe : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Recovery_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Feedback :=
        GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i];

    L_State := (Runtime_Valid := FALSE);

    L_State.Runtime_Valid := TRUE;
    L_State.Runtime_System_Time_MS := VI_System_Time_MS;

    L_State.Recovery_Requested :=
        GVL_INTENT_SAFETY.I_Water_Selective_Recovery_Allowed;

    L_State.Valve_Degraded :=
        L_Feedback.Valve_Degraded;

    L_State.Confirmation_Healthy :=
        NOT L_Feedback.Feedback_Timeout
        AND NOT L_Feedback.Feedback_Conflict;

    L_State.Recovery_Target_Valid :=
        L_Feedback.Valve_Group_Id <> 0;

    // Conservative recovery governance.
    IF NOT L_State.Recovery_Target_Valid THEN

        L_State.Recovery_Denied := TRUE;

        L_State.Status_Code := 1;
        L_State.Status_Text :=
            'Recovery denied: invalid target';

    ELSIF L_State.Valve_Degraded THEN

        L_State.Recovery_Denied := TRUE;
        L_State.Unsafe_Recovery_Detected := TRUE;

        L_State.Status_Code := 2;
        L_State.Status_Text :=
            'Recovery denied: degraded valve state';

    ELSIF NOT L_State.Confirmation_Healthy THEN

        L_State.Recovery_Denied := TRUE;

        L_State.Status_Code := 3;
        L_State.Status_Text :=
            'Recovery denied: unhealthy confirmation';

    ELSE

        L_State.Recovery_Allowed := TRUE;
        L_State.Observation_Window_Active := TRUE;

        L_State.Status_Code := 0;
        L_State.Status_Text :=
            'Recovery governance healthy';

    END_IF;

    GVL_Water_Recovery_Runtime.G_Recovery_State[L_i] :=
        L_State;

    L_Any_Denied :=
        L_Any_Denied
        OR L_State.Recovery_Denied;

    L_Any_Unsafe :=
        L_Any_Unsafe
        OR L_State.Unsafe_Recovery_Detected;

END_FOR;

GVL_Water_Recovery_Runtime.G_Any_Recovery_Denied :=
    L_Any_Denied;

GVL_Water_Recovery_Runtime.G_Any_Unsafe_Recovery :=
    L_Any_Unsafe;

GVL_Water_Recovery_Runtime.G_Runtime_Valid := TRUE;
GVL_Water_Recovery_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Unsafe THEN
    GVL_Water_Recovery_Runtime.G_Status_Code := 2;
    GVL_Water_Recovery_Runtime.G_Status_Text :=
        'Unsafe recovery detected';
ELSIF L_Any_Denied THEN
    GVL_Water_Recovery_Runtime.G_Status_Code := 1;
    GVL_Water_Recovery_Runtime.G_Status_Text :=
        'Recovery governance denied';
ELSE
    GVL_Water_Recovery_Runtime.G_Status_Code := 0;
    GVL_Water_Recovery_Runtime.G_Status_Text :=
        'Recovery governance healthy';
END_IF;