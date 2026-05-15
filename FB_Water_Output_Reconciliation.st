FUNCTION_BLOCK FB_Water_Output_Reconciliation
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Output : ST_Water_Output_Projection_State;
    L_Valve : ST_Water_Valve_Runtime_State;
    L_State : ST_Water_Output_Reconciliation_State;
    L_Any_Runtime_Mismatch : BOOL;
    L_Any_Confirmation_Mismatch : BOOL;
    L_Any_Conflict : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Output_Reconciliation.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_Output := GVL_Water_Output_Projection.G_Output_Projection_State[L_i];
    L_Valve := GVL_Water_Valve_Runtime.G_Valve_Runtime_State[L_i];

    L_State := (Runtime_Valid := TRUE);
    L_State.Runtime_System_Time_MS := VI_System_Time_MS;

    L_State.Valve_Group_Id := L_Output.Valve_Group_Id;
    L_State.Projection_Active := L_Output.Physical_Close_Project;
    L_State.Runtime_Output_Active := L_Valve.Physical_Output_Active;
    L_State.Expected_Closed := L_Output.Expected_Closed;
    L_State.Confirmed_Closed := L_Valve.Confirmed_Closed;
    L_State.Confirmation_Unknown := L_Valve.Confirmation_Unknown;

    // Reconcile only when confirmation is available.
    IF L_Valve.Confirmation_Available THEN

        IF L_State.Projection_Active <> L_State.Runtime_Output_Active THEN
            L_State.Projection_Runtime_Mismatch := TRUE;
        END_IF;

        IF L_State.Expected_Closed
           AND NOT L_State.Confirmed_Closed THEN

            L_State.Projection_Confirmation_Mismatch := TRUE;

        END_IF;

    END_IF;

    IF L_Output.Projection_Allowed
       AND L_Output.Projection_Denied THEN

        L_State.Conflict_Detected := TRUE;

    END_IF;

    IF L_Output.Valve_Group_Id = 0 THEN
        L_State.Topology_Invalid := TRUE;
    END_IF;

    L_State.Reconciliation_Healthy :=
        NOT L_State.Projection_Runtime_Mismatch
        AND NOT L_State.Projection_Confirmation_Mismatch
        AND NOT L_State.Conflict_Detected
        AND NOT L_State.Topology_Invalid;

    IF L_State.Conflict_Detected THEN
        L_State.Status_Code := 3;
        L_State.Status_Text := 'Projection conflict detected';
    ELSIF L_State.Projection_Runtime_Mismatch THEN
        L_State.Status_Code := 2;
        L_State.Status_Text := 'Projection runtime mismatch';
    ELSIF L_State.Projection_Confirmation_Mismatch THEN
        L_State.Status_Code := 1;
        L_State.Status_Text := 'Projection confirmation mismatch';
    ELSE
        L_State.Status_Code := 0;
        L_State.Status_Text := 'Reconciliation healthy';
    END_IF;

    GVL_Water_Output_Reconciliation.G_Reconciliation_State[L_i] :=
        L_State;

    L_Any_Runtime_Mismatch :=
        L_Any_Runtime_Mismatch
        OR L_State.Projection_Runtime_Mismatch;

    L_Any_Confirmation_Mismatch :=
        L_Any_Confirmation_Mismatch
        OR L_State.Projection_Confirmation_Mismatch;

    L_Any_Conflict :=
        L_Any_Conflict
        OR L_State.Conflict_Detected;

END_FOR;

GVL_Water_Output_Reconciliation.G_Any_Runtime_Mismatch :=
    L_Any_Runtime_Mismatch;

GVL_Water_Output_Reconciliation.G_Any_Confirmation_Mismatch :=
    L_Any_Confirmation_Mismatch;

GVL_Water_Output_Reconciliation.G_Any_Conflict_Detected :=
    L_Any_Conflict;

GVL_Water_Output_Reconciliation.G_Runtime_Valid := TRUE;
GVL_Water_Output_Reconciliation.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Conflict THEN
    GVL_Water_Output_Reconciliation.G_Status_Code := 3;
    GVL_Water_Output_Reconciliation.G_Status_Text :=
        'Projection conflicts detected';
ELSIF L_Any_Runtime_Mismatch THEN
    GVL_Water_Output_Reconciliation.G_Status_Code := 2;
    GVL_Water_Output_Reconciliation.G_Status_Text :=
        'Runtime reconciliation mismatch detected';
ELSIF L_Any_Confirmation_Mismatch THEN
    GVL_Water_Output_Reconciliation.G_Status_Code := 1;
    GVL_Water_Output_Reconciliation.G_Status_Text :=
        'Confirmation reconciliation mismatch detected';
ELSE
    GVL_Water_Output_Reconciliation.G_Status_Code := 0;
    GVL_Water_Output_Reconciliation.G_Status_Text :=
        'Output reconciliation healthy';
END_IF;

END_FUNCTION_BLOCK