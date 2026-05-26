PROGRAM PRG_Water_Emergency_Open_Manager
VAR
    L_Group : INT;
    L_Duration_MS : UDINT;
    L_Elapsed_MS : UDINT;
    L_Remaining_MS : UDINT;
    L_Leak_Active : BOOL;
    L_Close_Fault_Active : BOOL;
    L_Hard_Stop_Active : BOOL;
    L_i : INT;
END_VAR

// Daily limit reset on monotonic 24h window.
IF (GVL_WATER_EMERGENCY_OPEN.G_Daily_Reset_MS = 0) OR
   ((GVL_TIME_SERVICE.G_Now_MS - GVL_WATER_EMERGENCY_OPEN.G_Daily_Reset_MS) >= GVL_CONSTANTS.C_MS_IN_DAY) THEN
    FOR L_i := 1 TO 4 DO
        GVL_WATER_EMERGENCY_OPEN.G_Open_Count_Today[L_i] := 0;
    END_FOR;
    GVL_WATER_EMERGENCY_OPEN.G_Daily_Reset_MS := GVL_TIME_SERVICE.G_Now_MS;
END_IF;

L_Leak_Active := GVL_STATE.G_Safety_Leak_Alarm OR GVL_STATE.G_Safety_Leak_Latched;
L_Close_Fault_Active := GVL_STATUS.G_Diagnostics.Water_Close_Fault_Active OR GVL_STATUS.G_Diagnostics.Water_Main_Shutdown_Recommended;
L_Hard_Stop_Active := (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GLOBAL_STOP) OR GVL_INTENT_SAFETY.I_System_Safe_Stop_Required;

IF (L_Close_Fault_Active OR L_Hard_Stop_Active) AND GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active THEN
    FOR L_i := 1 TO 4 DO
        GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_i] := FALSE;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Duration_MS[L_i] := 0;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_i] := 0;
    END_FOR;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Accepted := FALSE;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Event_Group := 0;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Event_MS := GVL_TIME_SERVICE.G_Now_MS;

    IF L_Hard_Stop_Active THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 7;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open cancelled: hard stop active';
    ELSE
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 6;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open cancelled: water close fault';
    END_IF;
END_IF;

// HMI immediate close before timeout.
IF GVL_WATER_EMERGENCY_OPEN.G_Request_Close_Now THEN
    L_Group := GVL_WATER_EMERGENCY_OPEN.G_Target_Isolation_Group;

    GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Accepted := FALSE;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := FALSE;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 0;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Event_Group := L_Group;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Event_MS := GVL_TIME_SERVICE.G_Now_MS;

    IF (L_Group >= 1) AND (L_Group <= 4) THEN
        GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_Group] := FALSE;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Duration_MS[L_Group] := 0;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_Group] := 0;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open cancelled by HMI';
    ELSE
        FOR L_i := 1 TO 4 DO
            GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_i] := FALSE;
            GVL_WATER_EMERGENCY_OPEN.G_Open_Duration_MS[L_i] := 0;
            GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_i] := 0;
        END_FOR;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'All emergency opens cancelled by HMI';
    END_IF;

    GVL_WATER_EMERGENCY_OPEN.G_Request_Close_Now := FALSE;
END_IF;

// HMI emergency open request.
// Groups 1..3 = local risers; group 4 = common inlet 35/36.
IF GVL_WATER_EMERGENCY_OPEN.G_Request_Open THEN
    L_Group := GVL_WATER_EMERGENCY_OPEN.G_Target_Isolation_Group;
    L_Duration_MS := 0;

    GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Accepted := FALSE;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := FALSE;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 0;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Event_Group := L_Group;
    GVL_WATER_EMERGENCY_OPEN.G_Last_Event_MS := GVL_TIME_SERVICE.G_Now_MS;

    CASE GVL_WATER_EMERGENCY_OPEN.G_Duration_Minutes OF
        1:
            L_Duration_MS := GVL_CONSTANTS.C_MS_IN_MINUTE;
        3:
            L_Duration_MS := GVL_CONSTANTS.C_MS_IN_MINUTE * 3;
        5:
            L_Duration_MS := GVL_CONSTANTS.C_MS_IN_MINUTE * 5;
    ELSE
            L_Duration_MS := 0;
    END_CASE;

    IF L_Hard_Stop_Active THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 7;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open denied: hard stop active';
    ELSIF L_Close_Fault_Active THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 6;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open denied: water close fault active';
    ELSIF NOT L_Leak_Active THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 1;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open denied: no active leak alarm';
    ELSIF GVL_INTENT_USER.I_User_Access_Level < 2 THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 2;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open denied: access level < 2';
    ELSIF (L_Group < 1) OR (L_Group > 4) THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 3;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open denied: invalid isolation group';
    ELSIF L_Duration_MS = 0 THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 4;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open denied: invalid duration';
    ELSIF GVL_WATER_EMERGENCY_OPEN.G_Open_Count_Today[L_Group] >= 3 THEN
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Denied := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Denial_Code := 5;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open denied: daily limit reached';
    ELSE
        GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_Group] := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Start_MS[L_Group] := GVL_TIME_SERVICE.G_Now_MS;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Duration_MS[L_Group] := L_Duration_MS;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_Group] := L_Duration_MS;
        GVL_WATER_EMERGENCY_OPEN.G_Open_Count_Today[L_Group] := GVL_WATER_EMERGENCY_OPEN.G_Open_Count_Today[L_Group] + 1;
        GVL_WATER_EMERGENCY_OPEN.G_Last_Request_Accepted := TRUE;
        GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open accepted';
    END_IF;

    GVL_WATER_EMERGENCY_OPEN.G_Request_Open := FALSE;
END_IF;

GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active := FALSE;

// Timeout and remaining-time management.
FOR L_i := 1 TO 4 DO
    IF GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_i] THEN
        IF GVL_TIME_SERVICE.G_Now_MS >= GVL_WATER_EMERGENCY_OPEN.G_Open_Start_MS[L_i] THEN
            L_Elapsed_MS := GVL_TIME_SERVICE.G_Now_MS - GVL_WATER_EMERGENCY_OPEN.G_Open_Start_MS[L_i];
        ELSE
            L_Elapsed_MS := (4294967295 - GVL_WATER_EMERGENCY_OPEN.G_Open_Start_MS[L_i]) + GVL_TIME_SERVICE.G_Now_MS + 1;
        END_IF;

        IF L_Elapsed_MS >= GVL_WATER_EMERGENCY_OPEN.G_Open_Duration_MS[L_i] THEN
            GVL_WATER_EMERGENCY_OPEN.G_Open_Active[L_i] := FALSE;
            GVL_WATER_EMERGENCY_OPEN.G_Open_Duration_MS[L_i] := 0;
            GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_i] := 0;
            GVL_WATER_EMERGENCY_OPEN.G_Last_Event_Group := L_i;
            GVL_WATER_EMERGENCY_OPEN.G_Last_Event_MS := GVL_TIME_SERVICE.G_Now_MS;
            GVL_WATER_EMERGENCY_OPEN.G_Status_Text := 'Emergency open timeout elapsed';
        ELSE
            L_Remaining_MS := GVL_WATER_EMERGENCY_OPEN.G_Open_Duration_MS[L_i] - L_Elapsed_MS;
            GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_i] := L_Remaining_MS;
            GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active := TRUE;
        END_IF;
    ELSE
        GVL_WATER_EMERGENCY_OPEN.G_Open_Remaining_MS[L_i] := 0;
    END_IF;
END_FOR;

GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_1_Active := GVL_WATER_EMERGENCY_OPEN.G_Open_Active[1];
GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_2_Active := GVL_WATER_EMERGENCY_OPEN.G_Open_Active[2];
GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_3_Active := GVL_WATER_EMERGENCY_OPEN.G_Open_Active[3];
GVL_WATER_EMERGENCY_OPEN.G_Open_Common_Inlet_Active := GVL_WATER_EMERGENCY_OPEN.G_Open_Active[4];
GVL_WATER_EMERGENCY_OPEN.G_Any_Open_Active :=
    GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_1_Active OR
    GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_2_Active OR
    GVL_WATER_EMERGENCY_OPEN.G_Open_Riser_3_Active OR
    GVL_WATER_EMERGENCY_OPEN.G_Open_Common_Inlet_Active;
GVL_WATER_EMERGENCY_OPEN.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

END_PROGRAM