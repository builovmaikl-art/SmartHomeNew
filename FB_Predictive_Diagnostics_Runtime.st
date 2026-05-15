FUNCTION_BLOCK FB_Predictive_Diagnostics_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_State : ST_Predictive_Diagnostics_State;
    L_Feedback : ST_Water_Valve_Feedback_State;
    L_Recovery : ST_Water_Recovery_Runtime_State;

    L_Any_Degrading : BOOL;
    L_Any_Service : BOOL;
    L_Any_Urgent : BOOL;
END_VAR

IF NOT VI_Enable THEN
    GVL_Predictive_Diagnostics.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_FLOOD_SENSORS DO

    L_State := GVL_Predictive_Diagnostics.G_Diagnostics_State[L_i];

    L_Feedback :=
        GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i];

    L_Recovery :=
        GVL_Water_Recovery_Runtime.G_Recovery_State[L_i];

    L_State.Runtime_Valid := TRUE;
    L_State.Runtime_System_Time_MS := VI_System_Time_MS;

    L_State.Device_Id := TO_UINT(L_i);
    L_State.Valve_Group_Id := L_Feedback.Valve_Group_Id;

    IF L_Feedback.Feedback_Timeout THEN
        L_State.Timeout_Count := L_State.Timeout_Count + 1;
    END_IF;

    IF L_Feedback.Feedback_Conflict THEN
        L_State.Conflict_Count := L_State.Conflict_Count + 1;
    END_IF;

    IF L_Recovery.Recovery_Denied THEN
        L_State.Recovery_Denied_Count :=
            L_State.Recovery_Denied_Count + 1;
    END_IF;

    L_State.Failure_Count :=
        L_State.Timeout_Count
        + L_State.Conflict_Count
        + L_State.Recovery_Denied_Count;

    // Predictive accumulation model foundation.
    L_State.Wear_Score :=
        TO_REAL(L_State.Failure_Count) * 0.1;

    L_State.Reliability_Score :=
        100.0 - L_State.Wear_Score;

    IF L_State.Reliability_Score < 0.0 THEN
        L_State.Reliability_Score := 0.0;
    END_IF;

    IF L_State.Failure_Count >= 3 THEN

        L_State.Degradation_Accumulating := TRUE;
        L_State.Service_Recommended := TRUE;

    END_IF;

    IF L_State.Failure_Count >= 10 THEN

        L_State.Service_Urgent := TRUE;
        L_State.Predictive_Quarantine_Recommended := TRUE;

    END_IF;

    IF L_State.Conflict_Count >= 2 THEN
        L_State.Intermittent_Fault_Suspected := TRUE;
    END_IF;

    IF L_State.Service_Urgent THEN

        L_State.Status_Code := 2;
        L_State.Status_Text :=
            'Urgent predictive maintenance required';

    ELSIF L_State.Service_Recommended THEN

        L_State.Status_Code := 1;
        L_State.Status_Text :=
            'Predictive maintenance recommended';

    ELSE

        L_State.Status_Code := 0;
        L_State.Status_Text :=
            'Predictive diagnostics healthy';

    END_IF;

    GVL_Predictive_Diagnostics.G_Diagnostics_State[L_i] :=
        L_State;

    L_Any_Degrading :=
        L_Any_Degrading
        OR L_State.Degradation_Accumulating;

    L_Any_Service :=
        L_Any_Service
        OR L_State.Service_Recommended;

    L_Any_Urgent :=
        L_Any_Urgent
        OR L_State.Service_Urgent;

END_FOR;

GVL_Predictive_Diagnostics.G_Any_Degradation_Accumulating :=
    L_Any_Degrading;

GVL_Predictive_Diagnostics.G_Any_Service_Recommended :=
    L_Any_Service;

GVL_Predictive_Diagnostics.G_Any_Urgent_Service :=
    L_Any_Urgent;

GVL_Predictive_Diagnostics.G_Runtime_Valid := TRUE;
GVL_Predictive_Diagnostics.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Urgent THEN
    GVL_Predictive_Diagnostics.G_Status_Code := 2;
    GVL_Predictive_Diagnostics.G_Status_Text :=
        'Urgent predictive maintenance required';
ELSIF L_Any_Service THEN
    GVL_Predictive_Diagnostics.G_Status_Code := 1;
    GVL_Predictive_Diagnostics.G_Status_Text :=
        'Predictive maintenance recommended';
ELSE
    GVL_Predictive_Diagnostics.G_Status_Code := 0;
    GVL_Predictive_Diagnostics.G_Status_Text :=
        'Predictive diagnostics runtime healthy';
END_IF;

END_FUNCTION_BLOCK