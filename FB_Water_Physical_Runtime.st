FUNCTION_BLOCK FB_Water_Physical_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;

    L_Output : ST_Water_Output_Projection_State;
    L_Feedback : ST_Water_Valve_Feedback_State;

    L_Convergence : ST_Water_Physical_Convergence_State;
    L_Diagnostics : ST_Water_Actuator_Diagnostics_State;

    L_Any_Convergence_Degraded : BOOL;
    L_Any_Diagnostics_Degraded : BOOL;
    L_Any_Escalation : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Physical_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Output :=
        GVL_Water_Output_Projection.G_Output_Projection_State[L_i];

    L_Feedback :=
        GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i];

    L_Convergence := (Runtime_Valid := TRUE);

    L_Convergence.Runtime_System_Time_MS :=
        VI_System_Time_MS;

    L_Convergence.Sensor_Id := TO_UINT(L_i);

    L_Convergence.Projection_Active :=
        L_Output.Projection_Allowed;

    L_Convergence.Physical_Open_Confirmed :=
        L_Feedback.Confirmed_Open;

    L_Convergence.Physical_Closed_Confirmed :=
        L_Feedback.Confirmed_Closed;

    L_Convergence.Physical_State_Confirmed :=
        L_Feedback.Confirmed_Open
        OR L_Feedback.Confirmed_Closed;

    // Runtime convergence.
    IF L_Feedback.Feedback_Available THEN

        IF L_Output.Expected_Closed
           AND NOT L_Feedback.Confirmed_Closed THEN

            L_Convergence.Projection_Mismatch := TRUE;
            L_Convergence.Physical_Mismatch := TRUE;

        END_IF;

        IF NOT L_Convergence.Projection_Mismatch
           AND NOT L_Feedback.Feedback_Timeout THEN

            L_Convergence.Runtime_Converged := TRUE;

        END_IF;

    ELSE

        L_Convergence.Runtime_Mismatch := FALSE;

    END_IF;

    IF L_Convergence.Projection_Mismatch
       OR L_Feedback.Feedback_Conflict THEN

        L_Convergence.Convergence_Degraded := TRUE;
        L_Convergence.Escalation_Required := TRUE;

        L_Convergence.Status_Code := 2;
        L_Convergence.Status_Text :=
            'Physical convergence mismatch detected';

    ELSIF L_Convergence.Runtime_Converged THEN

        L_Convergence.Status_Code := 1;
        L_Convergence.Status_Text :=
            'Physical runtime converged';

    ELSE

        L_Convergence.Status_Code := 0;
        L_Convergence.Status_Text :=
            'Physical convergence observe-only';

    END_IF;

    // Stateful timing placeholder.
    L_Diagnostics := (Runtime_Valid := TRUE);

    L_Diagnostics.Runtime_System_Time_MS :=
        VI_System_Time_MS;

    L_Diagnostics.Valve_Group_Id :=
        L_Output.Valve_Group_Id;

    L_Diagnostics.Travel_Active :=
        L_Output.Projection_Allowed
        AND L_Feedback.Feedback_Available
        AND NOT L_Convergence.Runtime_Converged;

    IF L_Diagnostics.Travel_Active THEN
        L_Diagnostics.Travel_Time_MS := 100;
    ELSE
        L_Diagnostics.Travel_Time_MS := 0;
    END_IF;

    IF L_Diagnostics.Travel_Time_MS > 4000 THEN

        L_Diagnostics.Travel_Timeout := TRUE;
        L_Diagnostics.Stuck_Suspected := TRUE;

    END_IF;

    IF L_Diagnostics.Travel_Timeout THEN

        L_Diagnostics.Diagnostics_Degraded := TRUE;
        L_Diagnostics.Escalation_Required := TRUE;
        L_Diagnostics.Failure_Count := 1;

        L_Diagnostics.Status_Code := 2;
        L_Diagnostics.Status_Text :=
            'Actuator travel timeout detected';

    ELSE

        L_Diagnostics.Status_Code := 0;
        L_Diagnostics.Status_Text :=
            'Actuator diagnostics healthy';

    END_IF;

    GVL_Water_Physical_Runtime.G_Convergence_State[L_i] :=
        L_Convergence;

    GVL_Water_Physical_Runtime.G_Actuator_Diagnostics[L_i] :=
        L_Diagnostics;

    L_Any_Convergence_Degraded :=
        L_Any_Convergence_Degraded
        OR L_Convergence.Convergence_Degraded;

    L_Any_Diagnostics_Degraded :=
        L_Any_Diagnostics_Degraded
        OR L_Diagnostics.Diagnostics_Degraded;

    L_Any_Escalation :=
        L_Any_Escalation
        OR L_Convergence.Escalation_Required
        OR L_Diagnostics.Escalation_Required;

END_FOR;

GVL_Water_Physical_Runtime.G_Any_Convergence_Degraded :=
    L_Any_Convergence_Degraded;

GVL_Water_Physical_Runtime.G_Any_Diagnostics_Degraded :=
    L_Any_Diagnostics_Degraded;

GVL_Water_Physical_Runtime.G_Any_Escalation_Required :=
    L_Any_Escalation;

GVL_Water_Physical_Runtime.G_Runtime_Valid := TRUE;
GVL_Water_Physical_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Escalation THEN
    GVL_Water_Physical_Runtime.G_Status_Code := 2;
    GVL_Water_Physical_Runtime.G_Status_Text :=
        'Physical runtime escalation active';
ELSIF L_Any_Convergence_Degraded THEN
    GVL_Water_Physical_Runtime.G_Status_Code := 1;
    GVL_Water_Physical_Runtime.G_Status_Text :=
        'Physical convergence degraded';
ELSE
    GVL_Water_Physical_Runtime.G_Status_Code := 0;
    GVL_Water_Physical_Runtime.G_Status_Text :=
        'Physical runtime healthy';
END_IF;

END_FUNCTION_BLOCK