FUNCTION_BLOCK FB_Water_Physical_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_Feedback : ST_Water_Valve_Feedback_State;
    L_Convergence : ST_Water_Physical_Convergence_State;
    L_Diagnostics : ST_Water_Actuator_Diagnostics_State;
    L_Empty_Convergence : ST_Water_Physical_Convergence_State;
    L_Empty_Diagnostics : ST_Water_Actuator_Diagnostics_State;
    L_Any_Convergence_Degraded : BOOL;
    L_Any_Diagnostics_Degraded : BOOL;
    L_Any_Escalation : BOOL;
    L_Command_Open : BOOL;
    L_Command_Close : BOOL;
    L_Command_Active : BOOL;
    L_Target_Confirmed : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Physical_Runtime.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Convergence_Degraded := FALSE;
L_Any_Diagnostics_Degraded := FALSE;
L_Any_Escalation := FALSE;

// Clear old sensor-index based slots so obsolete 9..12 projections cannot keep
// stale escalation state after moving to 8 physical valves.
FOR L_i := 1 TO 64 DO
    GVL_Water_Physical_Runtime.G_Convergence_State[L_i] := L_Empty_Convergence;
    GVL_Water_Physical_Runtime.G_Actuator_Diagnostics[L_i] := L_Empty_Diagnostics;
END_FOR;

FOR L_i := 1 TO 8 DO
    L_Feedback := GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i];
    L_Convergence := L_Empty_Convergence;
    L_Diagnostics := L_Empty_Diagnostics;

    CASE L_i OF
        1..6:
            L_Command_Open := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Open[L_i];
            L_Command_Close := GVL_WATER_OUTPUT.DO_Water_Local_Valve_Close[L_i];
        7:
            L_Command_Open := GVL_WATER_OUTPUT.DO_Water_Valve_35_Open;
            L_Command_Close := GVL_WATER_OUTPUT.DO_Water_Valve_35_Close;
        8:
            L_Command_Open := GVL_WATER_OUTPUT.DO_Water_Valve_36_Open;
            L_Command_Close := GVL_WATER_OUTPUT.DO_Water_Valve_36_Close;
    ELSE
            L_Command_Open := FALSE;
            L_Command_Close := FALSE;
    END_CASE;

    L_Command_Active := L_Command_Open OR L_Command_Close;
    L_Target_Confirmed :=
        (L_Command_Open AND L_Feedback.Confirmed_Open AND NOT L_Command_Close)
        OR (L_Command_Close AND L_Feedback.Confirmed_Closed AND NOT L_Command_Open)
        OR (NOT L_Command_Active);

    L_Convergence.Runtime_Valid := TRUE;
    L_Convergence.Runtime_System_Time_MS := VI_System_Time_MS;
    L_Convergence.Sensor_Id := TO_UINT(L_i);
    L_Convergence.Projection_Active := L_Command_Active;
    L_Convergence.Physical_Open_Confirmed := L_Feedback.Confirmed_Open;
    L_Convergence.Physical_Closed_Confirmed := L_Feedback.Confirmed_Closed;
    L_Convergence.Physical_State_Confirmed := L_Feedback.Confirmed_Open OR L_Feedback.Confirmed_Closed;
    L_Convergence.Runtime_Converged := L_Target_Confirmed AND NOT L_Feedback.Feedback_Conflict AND NOT L_Feedback.Feedback_Timeout;

    IF L_Feedback.Feedback_Conflict OR L_Feedback.Feedback_Timeout THEN
        L_Convergence.Projection_Mismatch := L_Command_Active;
        L_Convergence.Physical_Mismatch := TRUE;
        L_Convergence.Convergence_Degraded := TRUE;
        L_Convergence.Escalation_Required := TRUE;
        L_Convergence.Status_Code := 2;
        L_Convergence.Status_Text := 'Valve physical feedback degraded';
    ELSIF L_Command_Active AND NOT L_Target_Confirmed THEN
        L_Convergence.Projection_Mismatch := TRUE;
        L_Convergence.Physical_Mismatch := TRUE;
        L_Convergence.Convergence_Degraded := TRUE;
        L_Convergence.Status_Code := 1;
        L_Convergence.Status_Text := 'Valve moving or waiting for end switch';
    ELSIF L_Convergence.Runtime_Converged THEN
        L_Convergence.Status_Code := 0;
        L_Convergence.Status_Text := 'Valve physical runtime converged';
    ELSE
        L_Convergence.Status_Code := 0;
        L_Convergence.Status_Text := 'Valve physical runtime idle';
    END_IF;

    L_Diagnostics.Runtime_Valid := TRUE;
    L_Diagnostics.Runtime_System_Time_MS := VI_System_Time_MS;
    L_Diagnostics.Valve_Group_Id := TO_UINT(L_i);
    L_Diagnostics.Travel_Active := L_Command_Active AND NOT L_Target_Confirmed;
    L_Diagnostics.Travel_Timeout := L_Feedback.Feedback_Timeout;
    L_Diagnostics.Stuck_Suspected := L_Feedback.Valve_Stuck_Suspected;
    L_Diagnostics.Diagnostics_Degraded := L_Feedback.Valve_Degraded;
    L_Diagnostics.Escalation_Required := L_Feedback.Feedback_Timeout OR L_Feedback.Feedback_Conflict;

    IF L_Diagnostics.Escalation_Required THEN
        L_Diagnostics.Failure_Count := 1;
        L_Diagnostics.Status_Code := 2;
        L_Diagnostics.Status_Text := 'Valve actuator escalation required';
    ELSIF L_Diagnostics.Travel_Active THEN
        L_Diagnostics.Status_Code := 1;
        L_Diagnostics.Status_Text := 'Valve actuator travel active';
    ELSE
        L_Diagnostics.Status_Code := 0;
        L_Diagnostics.Status_Text := 'Valve actuator diagnostics healthy';
    END_IF;

    GVL_Water_Physical_Runtime.G_Convergence_State[L_i] := L_Convergence;
    GVL_Water_Physical_Runtime.G_Actuator_Diagnostics[L_i] := L_Diagnostics;

    L_Any_Convergence_Degraded := L_Any_Convergence_Degraded OR L_Convergence.Convergence_Degraded;
    L_Any_Diagnostics_Degraded := L_Any_Diagnostics_Degraded OR L_Diagnostics.Diagnostics_Degraded;
    L_Any_Escalation := L_Any_Escalation OR L_Convergence.Escalation_Required OR L_Diagnostics.Escalation_Required;
END_FOR;

GVL_Water_Physical_Runtime.G_Any_Convergence_Degraded := L_Any_Convergence_Degraded;
GVL_Water_Physical_Runtime.G_Any_Diagnostics_Degraded := L_Any_Diagnostics_Degraded;
GVL_Water_Physical_Runtime.G_Any_Escalation_Required := L_Any_Escalation;
GVL_Water_Physical_Runtime.G_Runtime_Valid := TRUE;
GVL_Water_Physical_Runtime.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Escalation THEN
    GVL_Water_Physical_Runtime.G_Status_Code := 2;
    GVL_Water_Physical_Runtime.G_Status_Text := 'Physical valve escalation active';
ELSIF L_Any_Convergence_Degraded THEN
    GVL_Water_Physical_Runtime.G_Status_Code := 1;
    GVL_Water_Physical_Runtime.G_Status_Text := 'Physical valve convergence degraded';
ELSE
    GVL_Water_Physical_Runtime.G_Status_Code := 0;
    GVL_Water_Physical_Runtime.G_Status_Text := 'Physical valve runtime healthy';
END_IF;

END_FUNCTION_BLOCK