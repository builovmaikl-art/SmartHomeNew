FUNCTION_BLOCK FB_Water_Valve_Runtime_Governance
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Group : INT;
    L_Feedback_Index_A : INT;
    L_Feedback_Index_B : INT;

    L_Authority : ST_Water_Isolation_Authority_State;
    L_Valve : ST_Water_Valve_Runtime_State;
    L_Empty_Valve : ST_Water_Valve_Runtime_State;

    L_Feedback_A : ST_Water_Valve_Feedback_State;
    L_Feedback_B : ST_Water_Valve_Feedback_State;

    L_Any_Degraded : BOOL;
    L_Any_Confirmation_Unknown : BOOL;
    L_Any_Unsafe_Reopen : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Valve_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Degraded := FALSE;
L_Any_Confirmation_Unknown := FALSE;
L_Any_Unsafe_Reopen := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Authority :=
        GVL_Water_Isolation_Authority.G_Authority_State[L_i];

    L_Valve := L_Empty_Valve;
    L_Valve.Runtime_Valid := TRUE;

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

    // Feedback/runtime hooks. Runtime authority is per leak sensor, but valve
    // feedback is per physical valve pair: group 1 => 1/2, group 2 => 3/4,
    // group 3 => 5/6, group 4 => 7/8 (35/36).
    L_Group := UINT_TO_INT(L_Authority.Valve_Group_Id);
    L_Feedback_Index_A := 0;
    L_Feedback_Index_B := 0;

    CASE L_Group OF
        1:
            L_Feedback_Index_A := 1;
            L_Feedback_Index_B := 2;
        2:
            L_Feedback_Index_A := 3;
            L_Feedback_Index_B := 4;
        3:
            L_Feedback_Index_A := 5;
            L_Feedback_Index_B := 6;
        4:
            L_Feedback_Index_A := 7;
            L_Feedback_Index_B := 8;
    ELSE
            L_Feedback_Index_A := 0;
            L_Feedback_Index_B := 0;
    END_CASE;

    IF (L_Feedback_Index_A >= 1) AND (L_Feedback_Index_B >= 1) THEN
        L_Feedback_A := GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_Feedback_Index_A];
        L_Feedback_B := GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_Feedback_Index_B];

        L_Valve.Confirmation_Available :=
            L_Feedback_A.Feedback_Available
            AND L_Feedback_B.Feedback_Available;

        IF L_Valve.Confirmation_Available THEN
            L_Valve.Confirmed_Closed :=
                L_Feedback_A.Confirmed_Closed
                AND L_Feedback_B.Confirmed_Closed;

            L_Valve.Confirmed_Open :=
                L_Feedback_A.Confirmed_Open
                AND L_Feedback_B.Confirmed_Open;

            L_Valve.Confirmation_Timeout :=
                L_Feedback_A.Feedback_Timeout
                OR L_Feedback_B.Feedback_Timeout;
        ELSE
            L_Valve.Confirmation_Unknown := TRUE;
        END_IF;
    ELSE
        L_Valve.Confirmation_Unknown := TRUE;
    END_IF;

    IF L_Valve.Confirmation_Available
       AND NOT L_Valve.Confirmed_Open
       AND NOT L_Valve.Confirmed_Closed THEN
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

    IF L_Valve.Confirmation_Timeout THEN
        L_Valve.Valve_Degraded := TRUE;
        L_Valve.Valve_Stuck_Suspected := TRUE;
    END_IF;

    IF L_Valve.Valve_Degraded THEN

        L_Valve.Unsafe_Reopen_Denied := TRUE;
        L_Valve.Recovery_Allowed := FALSE;

        L_Valve.Status_Code := 2;
        L_Valve.Status_Text :=
            'Recovery denied: valve pair degraded';

    ELSIF L_Valve.Confirmation_Unknown THEN

        L_Valve.Status_Code := 1;
        L_Valve.Status_Text :=
            'Valve pair confirmation unavailable';

    ELSE

        L_Valve.Status_Code := 0;
        L_Valve.Status_Text :=
            'Valve pair governance runtime healthy';

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
        'Valve pair confirmation unknown';
ELSE
    GVL_Water_Valve_Runtime.G_Status_Code := 0;
    GVL_Water_Valve_Runtime.G_Status_Text :=
        'Valve governance runtime active';
END_IF;

END_FUNCTION_BLOCK