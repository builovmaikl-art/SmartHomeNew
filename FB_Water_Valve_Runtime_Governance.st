FUNCTION_BLOCK FB_Water_Valve_Runtime_Governance
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Authority : ST_Water_Isolation_Authority_State;
    L_Valve : ST_Water_Valve_Runtime_State;

    L_Any_Degraded : BOOL;
    L_Any_Confirmation_Unknown : BOOL;
    L_Any_Unsafe_Reopen : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Valve_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Authority :=
        GVL_Water_Isolation_Authority.G_Authority_State[L_i];

    L_Valve := (Runtime_Valid := TRUE);

    L_Valve.Runtime_System_Time_MS := VI_System_Time_MS;

    L_Valve.Valve_Id := L_Authority.Valve_Group_Id;
    L_Valve.Valve_Group_Id := L_Authority.Valve_Group_Id;

    L_Valve.Close_Requested :=
        L_Authority.Selective_Authority_Allowed
        OR L_Authority.Global_Fallback_Required;

    L_Valve.Global_Fallback_Request :=
        L_Authority.Global_Fallback_Required;

    L_Valve.Selective_Authority_Allowed :=
        L_Authority.Selective_Authority_Allowed;

    // Observe-only compatibility visibility.
    L_Valve.Physical_Output_Active :=
        GVL_COMMAND_SHADOW.G_Close_Valve_35
        OR GVL_COMMAND_SHADOW.G_Close_Valve_36;

    L_Valve.Output_Command_Projected :=
        L_Valve.Close_Requested;

    // Feedback/runtime hooks.
    L_Valve.Confirmation_Available :=
        GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i].Feedback_Available;

    IF L_Valve.Confirmation_Available THEN

        L_Valve.Confirmed_Closed :=
            GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i].Confirmed_Closed;

    ELSE

        L_Valve.Confirmation_Unknown := TRUE;

    END_IF;

    // Observe-only semantics must not force degraded state.
    L_Valve.Diagnostics_Available := FALSE;
    L_Valve.Valve_Healthy := TRUE;

    IF L_Valve.Confirmation_Available
       AND NOT L_Valve.Confirmed_Closed
       AND L_Valve.Close_Requested THEN

        L_Valve.Valve_Degraded := TRUE;

    END_IF;

    IF L_Valve.Valve_Degraded THEN

        L_Valve.Unsafe_Reopen_Denied := TRUE;
        L_Valve.Recovery_Allowed := FALSE;

        L_Valve.Status_Code := 2;
        L_Valve.Status_Text :=
            'Recovery denied: valve degraded';

    ELSIF L_Valve.Confirmation_Unknown THEN

        L_Valve.Status_Code := 1;
        L_Valve.Status_Text :=
            'Valve confirmation unavailable';

    ELSE

        L_Valve.Status_Code := 0;
        L_Valve.Status_Text :=
            'Valve governance runtime healthy';

    END_IF;

    GVL_Water_Valve_Runtime.G_Valve_Runtime_State[L_i] :=
        L_Valve;

    L_Any_Degraded :=
        L_Any_Degraded
        OR L_Valve.Valve_Degraded;

    L_Any_Confirmation_Unknown :=
        L_Any_Confirmation_Unknown
        OR L_Valve.Confirmation_Unknown;

    L_Any_Unsafe_Reopen :=
        L_Any_Unsafe_Reopen
        OR L_Valve.Unsafe_Reopen_Denied;

END_FOR;

GVL_Water_Valve_Runtime.G_Any_Valve_Degraded :=
    L_Any_Degraded;

GVL_Water_Valve_Runtime.G_Any_Confirmation_Unknown :=
    L_Any_Confirmation_Unknown;

GVL_Water_Valve_Runtime.G_Any_Unsafe_Reopen_Denied :=
    L_Any_Unsafe_Reopen;

GVL_Water_Valve_Runtime.G_Runtime_Valid := TRUE;
GVL_Water_Valve_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Degraded THEN
    GVL_Water_Valve_Runtime.G_Status_Code := 2;
    GVL_Water_Valve_Runtime.G_Status_Text :=
        'Valve governance degraded';
ELSIF L_Any_Confirmation_Unknown THEN
    GVL_Water_Valve_Runtime.G_Status_Code := 1;
    GVL_Water_Valve_Runtime.G_Status_Text :=
        'Valve confirmation unknown';
ELSE
    GVL_Water_Valve_Runtime.G_Status_Code := 0;
    GVL_Water_Valve_Runtime.G_Status_Text :=
        'Valve governance runtime active';
END_IF;

END_FUNCTION_BLOCK