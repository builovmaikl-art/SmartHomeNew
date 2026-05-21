FUNCTION_BLOCK FB_Water_Valve_Feedback_Runtime
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
END_VAR
VAR
    L_i : INT;
    L_State : ST_Water_Valve_Feedback_State;
    L_Empty_State : ST_Water_Valve_Feedback_State;
    L_Any_Degraded : BOOL;
    L_Any_Timeout : BOOL;
    L_Any_Conflict : BOOL;
    L_Command_Open : BOOL;
    L_Command_Close : BOOL;
    L_Command_Active : BOOL;
    L_Desired_Code : USINT;
    L_Elapsed_MS : UDINT;
    L_Command_Start_MS : ARRAY[1..8] OF UDINT;
    L_Prev_Desired_Code : ARRAY[1..8] OF USINT;
END_VAR

IF NOT VI_Enable THEN
    GVL_Water_Valve_Feedback.G_Runtime_Valid := FALSE;
    RETURN;
END_IF;

L_Any_Degraded := FALSE;
L_Any_Timeout := FALSE;
L_Any_Conflict := FALSE;

FOR L_i := 1 TO 8 DO
    L_State := L_Empty_State;
    L_State.Runtime_Valid := TRUE;
    L_State.Runtime_System_Time_MS := VI_System_Time_MS;

    // Valve identity used by HMI/diagnostics:
    // 1..6 = local riser valves, 7 = common inlet 35, 8 = common inlet 36.
    L_State.Valve_Group_Id := TO_UINT(L_i);
    L_State.Feedback_Available := TRUE;

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

    L_State.Physical_Open_Feedback := GVL_STATE.G_Water_Zone_Open_FB[L_i];
    L_State.Physical_Closed_Feedback := GVL_STATE.G_Water_Zone_Close_FB[L_i];

    IF L_State.Physical_Open_Feedback AND L_State.Physical_Closed_Feedback THEN
        L_State.Feedback_Conflict := TRUE;
        L_State.Feedback_Invalid := TRUE;
        L_State.Valve_Degraded := TRUE;
    END_IF;

    L_State.Confirmed_Open := L_State.Physical_Open_Feedback AND NOT L_State.Physical_Closed_Feedback;
    L_State.Confirmed_Closed := L_State.Physical_Closed_Feedback AND NOT L_State.Physical_Open_Feedback;
    L_State.Confirmation_Unknown := NOT L_State.Confirmed_Open AND NOT L_State.Confirmed_Closed AND NOT L_State.Feedback_Conflict;

    IF L_Command_Close AND NOT L_Command_Open THEN
        L_Desired_Code := 2;
    ELSIF L_Command_Open AND NOT L_Command_Close THEN
        L_Desired_Code := 1;
    ELSE
        L_Desired_Code := 0;
    END_IF;

    IF L_Desired_Code <> L_Prev_Desired_Code[L_i] THEN
        L_Command_Start_MS[L_i] := VI_System_Time_MS;
        L_Prev_Desired_Code[L_i] := L_Desired_Code;
    END_IF;

    L_Command_Active := (L_Desired_Code <> 0);

    IF L_Command_Active THEN
        IF VI_System_Time_MS >= L_Command_Start_MS[L_i] THEN
            L_Elapsed_MS := VI_System_Time_MS - L_Command_Start_MS[L_i];
        ELSE
            L_Elapsed_MS := (4294967295 - L_Command_Start_MS[L_i]) + VI_System_Time_MS + 1;
        END_IF;

        IF (L_Desired_Code = 1) AND L_State.Confirmed_Open THEN
            L_State.Feedback_Timeout := FALSE;
        ELSIF (L_Desired_Code = 2) AND L_State.Confirmed_Closed THEN
            L_State.Feedback_Timeout := FALSE;
        ELSIF L_Elapsed_MS >= T#10s THEN
            L_State.Feedback_Timeout := TRUE;
            L_State.Travel_Timeout_Active := TRUE;
            L_State.Valve_Stuck_Suspected := TRUE;
            L_State.Valve_Degraded := TRUE;
        END_IF;
    END_IF;

    IF L_State.Feedback_Conflict THEN
        L_State.Status_Code := 3;
        L_State.Status_Text := 'Valve feedback conflict detected';
    ELSIF L_State.Feedback_Timeout THEN
        L_State.Status_Code := 2;
        L_State.Status_Text := 'Valve feedback timeout';
    ELSIF L_State.Confirmation_Unknown THEN
        L_State.Status_Code := 1;
        L_State.Status_Text := 'Valve position unknown';
    ELSE
        L_State.Status_Code := 0;
        L_State.Status_Text := 'Valve feedback healthy';
    END_IF;

    GVL_Water_Valve_Feedback.G_Valve_Feedback_State[L_i] := L_State;

    L_Any_Degraded := L_Any_Degraded OR L_State.Valve_Degraded;
    L_Any_Timeout := L_Any_Timeout OR L_State.Feedback_Timeout;
    L_Any_Conflict := L_Any_Conflict OR L_State.Feedback_Conflict;
END_FOR;

GVL_Water_Valve_Feedback.G_Any_Degraded := L_Any_Degraded;
GVL_Water_Valve_Feedback.G_Any_Timeout := L_Any_Timeout;
GVL_Water_Valve_Feedback.G_Any_Conflict := L_Any_Conflict;
GVL_Water_Valve_Feedback.G_Runtime_Valid := TRUE;
GVL_Water_Valve_Feedback.G_Last_Update_MS := VI_System_Time_MS;

IF L_Any_Conflict THEN
    GVL_Water_Valve_Feedback.G_Status_Code := 3;
    GVL_Water_Valve_Feedback.G_Status_Text := 'Valve feedback conflicts detected';
ELSIF L_Any_Timeout THEN
    GVL_Water_Valve_Feedback.G_Status_Code := 2;
    GVL_Water_Valve_Feedback.G_Status_Text := 'Valve feedback timeout detected';
ELSIF L_Any_Degraded THEN
    GVL_Water_Valve_Feedback.G_Status_Code := 1;
    GVL_Water_Valve_Feedback.G_Status_Text := 'Valve diagnostics degraded';
ELSE
    GVL_Water_Valve_Feedback.G_Status_Code := 0;
    GVL_Water_Valve_Feedback.G_Status_Text := 'Valve feedback runtime healthy';
END_IF;

END_FUNCTION_BLOCK