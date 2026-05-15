FUNCTION_BLOCK FB_Water_Valve_Feedback_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Output : ST_Water_Output_Projection_State;
    L_State : ST_Water_Valve_Feedback_State;

    L_Any_Degraded : BOOL;
    L_Any_Timeout : BOOL;
    L_Any_Conflict : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Valve_Feedback.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Output := GVL_Water_Output_Projection.G_Output_Projection_State[L_i];

    L_State := (Runtime_Valid := FALSE);

    L_State.Runtime_Valid := TRUE;
    L_State.Runtime_System_Time_MS := VI_System_Time_MS;

    L_State.Valve_Group_Id := L_Output.Valve_Group_Id;

    // Feedback hooks.
    // Physical feedback integration point.
    L_State.Feedback_Available := FALSE;

    // Conservative fallback semantics until physical feedback is wired.
    IF NOT L_State.Feedback_Available THEN
        L_State.Feedback_Timeout := TRUE;
        L_State.Travel_Timeout_Active := TRUE;
        L_State.Valve_Degraded := TRUE;
    END_IF;

    // Conflict detection.
    IF L_State.Physical_Open_Feedback
       AND L_State.Physical_Closed_Feedback THEN

        L_State.Feedback_Conflict := TRUE;
        L_State.Valve_Degraded := TRUE;
    END_IF;

    // Confirmation derivation.
    L_State.Confirmed_Open :=
        L_State.Physical_Open_Feedback
        AND NOT L_State.Physical_Closed_Feedback;

    L_State.Confirmed_Closed :=
        L_State.Physical_Closed_Feedback
        AND NOT L_State.Physical_Open_Feedback;

    // Stuck suspicion.
    IF L_Output.Expected_Closed
       AND NOT L_State.Confirmed_Closed
       AND NOT L_State.Feedback_Timeout THEN

        L_State.Valve_Stuck_Suspected := TRUE;
        L_State.Valve_Degraded := TRUE;
    END_IF;

    // Status publication.
    IF L_State.Feedback_Conflict THEN
        L_State.Status_Code := 3;
        L_State.Status_Text :=
            'Valve feedback conflict detected';
    ELSIF L_State.Valve_Stuck_Suspected THEN
        L_State.Status_Code := 2;
        L_State.Status_Text :=
            'Valve stuck suspected';
    ELSIF L_State.Feedback_Timeout THEN
        L_State.Status_Code := 1;
        L_State.Status_Text :=
            'Valve feedback timeout';
    ELSE
        L_State.Status_Code := 0;
        L_State.Status_Text :=
            'Valve feedback healthy';
    END_IF;

    GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i] :=
        L_State;

    L_Any_Degraded :=
        L_Any_Degraded
        OR L_State.Valve_Degraded;

    L_Any_Timeout :=
        L_Any_Timeout
        OR L_State.Feedback_Timeout;

    L_Any_Conflict :=
        L_Any_Conflict
        OR L_State.Feedback_Conflict;

END_FOR;

GVL_Water_Valve_Feedback.G_Any_Degraded :=
    L_Any_Degraded;

GVL_Water_Valve_Feedback.G_Any_Timeout :=
    L_Any_Timeout;

GVL_Water_Valve_Feedback.G_Any_Conflict :=
    L_Any_Conflict;

GVL_Water_Valve_Feedback.G_Runtime_Valid := TRUE;
GVL_Water_Valve_Feedback.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Conflict THEN
    GVL_Water_Valve_Feedback.G_Status_Code := 3;
    GVL_Water_Valve_Feedback.G_Status_Text :=
        'Valve feedback conflicts detected';
ELSIF L_Any_Timeout THEN
    GVL_Water_Valve_Feedback.G_Status_Code := 2;
    GVL_Water_Valve_Feedback.G_Status_Text :=
        'Valve feedback degraded';
ELSIF L_Any_Degraded THEN
    GVL_Water_Valve_Feedback.G_Status_Code := 1;
    GVL_Water_Valve_Feedback.G_Status_Text :=
        'Valve diagnostics degraded';
ELSE
    GVL_Water_Valve_Feedback.G_Status_Code := 0;
    GVL_Water_Valve_Feedback.G_Status_Text :=
        'Valve feedback runtime healthy';
END_IF;