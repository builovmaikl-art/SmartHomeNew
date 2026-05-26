FUNCTION_BLOCK FB_Gas_Smoke_Manager
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC    : BOOL;
    VI_Mute_Request   : BOOL;
END_VAR

VAR_IN_OUT
    VI_Methane_LEL    : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF REAL;
    VI_CO_PPM         : ARRAY[1..GVL_CONSTANTS.C_MAX_CO_SENSORS] OF REAL;
    VI_Smoke_Sensors  : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF BOOL;
END_VAR

VAR_OUTPUT
    // Health signals
    VO_Smoke_Detected           : BOOL;
    VO_Gas_Detected             : BOOL; // Compatible methane alarm/critical summary.
    VO_Methane_Warning_Level    : BOOL;
    VO_Methane_Alarm_Level      : BOOL;
    VO_Methane_Critical_Level   : BOOL;
    VO_CO_Warning_Level         : BOOL;
    VO_CO_Alarm_Level           : BOOL;
    VO_Status_Msg               : STRING(200);
END_VAR

VAR
    L_Methane_Max   : REAL;
    L_CO_Max        : REAL;
    L_Smoke_Count   : UINT;
    L_Smoke_Active  : BOOL;
    L_i             : INT;
    L_Group         : INT;
    L_A             : INT;
    L_B             : INT;

    L_CO_Timer_30ppm  : FB_System_Timer;
    L_CO_Timer_70ppm  : FB_System_Timer;
    L_CO_Timer_400ppm : FB_System_Timer;

    L_CO_Level_30   : BOOL;
    L_CO_Level_70   : BOOL;
    L_CO_Level_400  : BOOL;

    L_Smoke_Timer : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF FB_System_Timer;
END_VAR

IF NOT VI_IsActivePLC THEN RETURN; END_IF;

// Reset outputs
VO_Smoke_Detected := FALSE;
VO_Gas_Detected := FALSE;
VO_Methane_Warning_Level := FALSE;
VO_Methane_Alarm_Level := FALSE;
VO_Methane_Critical_Level := FALSE;
VO_CO_Warning_Level := FALSE;
VO_CO_Alarm_Level := FALSE;
VO_Status_Msg := 'ОК';

// --- Methane ---
L_Methane_Max := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_METHANE_SENSORS DO
    IF VI_Methane_LEL[L_i] > L_Methane_Max THEN
        L_Methane_Max := VI_Methane_LEL[L_i];
    END_IF;
END_FOR;

VO_Methane_Warning_Level := (L_Methane_Max >= 10.0);
VO_Methane_Alarm_Level := (L_Methane_Max >= 20.0);
VO_Methane_Critical_Level := (L_Methane_Max >= 40.0);
VO_Gas_Detected := VO_Methane_Alarm_Level OR VO_Methane_Critical_Level;

// --- CO ---
L_CO_Max := 0.0;
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_CO_SENSORS DO
    IF VI_CO_PPM[L_i] > L_CO_Max THEN
        L_CO_Max := VI_CO_PPM[L_i];
    END_IF;
END_FOR;

L_CO_Level_30 := (L_CO_Max >= 30.0);
L_CO_Level_70 := (L_CO_Max >= 70.0);
L_CO_Level_400 := (L_CO_Max >= 400.0);

L_CO_Timer_30ppm(IN := L_CO_Level_30, PT := T#8h, VI_System_Time_MS := VI_System_Time_MS);
L_CO_Timer_70ppm(IN := L_CO_Level_70, PT := T#1h, VI_System_Time_MS := VI_System_Time_MS);
L_CO_Timer_400ppm(IN := L_CO_Level_400, PT := T#15m, VI_System_Time_MS := VI_System_Time_MS);

IF L_CO_Timer_30ppm.Q THEN
    VO_CO_Warning_Level := TRUE;
END_IF;

IF L_CO_Timer_70ppm.Q OR L_CO_Timer_400ppm.Q THEN
    VO_CO_Alarm_Level := TRUE;
END_IF;

// --- Smoke ---
L_Smoke_Count := 0;
L_Smoke_Active := FALSE;
GVL_SMOKE_VERIFICATION.G_Verified_By_Pair := FALSE;
GVL_SMOKE_VERIFICATION.G_Verified_By_Timer := FALSE;
GVL_SMOKE_VERIFICATION.G_Verified_Group := 0;
GVL_SMOKE_VERIFICATION.G_Any_Smoke_Input_Active := FALSE;

FOR L_i := 1 TO 3 DO
    GVL_SMOKE_VERIFICATION.G_Group_Active[L_i] := FALSE;
    GVL_SMOKE_VERIFICATION.G_Group_Pair_Confirmed[L_i] := FALSE;
    GVL_SMOKE_VERIFICATION.G_Group_Timer_Confirmed[L_i] := FALSE;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    L_Smoke_Timer[L_i](IN := VI_Smoke_Sensors[L_i], PT := T#30s, VI_System_Time_MS := VI_System_Time_MS);

    IF VI_Smoke_Sensors[L_i] THEN
        L_Smoke_Count := L_Smoke_Count + 1;
        GVL_SMOKE_VERIFICATION.G_Any_Smoke_Input_Active := TRUE;
    END_IF;
END_FOR;

FOR L_Group := 1 TO 3 DO
    L_A := (L_Group * 2) - 1;
    L_B := L_Group * 2;

    IF (L_A <= GVL_CONSTANTS.C_MAX_SMOKE_SENSORS) AND (L_B <= GVL_CONSTANTS.C_MAX_SMOKE_SENSORS) THEN
        GVL_SMOKE_VERIFICATION.G_Group_Active[L_Group] :=
            VI_Smoke_Sensors[L_A] OR VI_Smoke_Sensors[L_B];

        GVL_SMOKE_VERIFICATION.G_Group_Pair_Confirmed[L_Group] :=
            VI_Smoke_Sensors[L_A] AND VI_Smoke_Sensors[L_B];

        GVL_SMOKE_VERIFICATION.G_Group_Timer_Confirmed[L_Group] :=
            L_Smoke_Timer[L_A].Q OR L_Smoke_Timer[L_B].Q;

        IF GVL_SMOKE_VERIFICATION.G_Group_Pair_Confirmed[L_Group] OR
           GVL_SMOKE_VERIFICATION.G_Group_Timer_Confirmed[L_Group] THEN
            L_Smoke_Active := TRUE;

            IF GVL_SMOKE_VERIFICATION.G_Verified_Group = 0 THEN
                GVL_SMOKE_VERIFICATION.G_Verified_Group := L_Group;
            END_IF;

            IF GVL_SMOKE_VERIFICATION.G_Group_Pair_Confirmed[L_Group] THEN
                GVL_SMOKE_VERIFICATION.G_Verified_By_Pair := TRUE;
            END_IF;

            IF GVL_SMOKE_VERIFICATION.G_Group_Timer_Confirmed[L_Group] THEN
                GVL_SMOKE_VERIFICATION.G_Verified_By_Timer := TRUE;
            END_IF;
        END_IF;
    END_IF;
END_FOR;

GVL_SMOKE_VERIFICATION.G_Smoke_Active_Count := L_Smoke_Count;
GVL_SMOKE_VERIFICATION.G_Verified := L_Smoke_Active;
GVL_SMOKE_VERIFICATION.G_Last_Update_MS := VI_System_Time_MS;

IF L_Smoke_Active THEN
    VO_Smoke_Detected := TRUE;
    CASE GVL_SMOKE_VERIFICATION.G_Verified_Group OF
        1:
            GVL_SMOKE_VERIFICATION.G_Status_Text := 'Smoke verified: basement group';
        2:
            GVL_SMOKE_VERIFICATION.G_Status_Text := 'Smoke verified: floor 1 group';
        3:
            GVL_SMOKE_VERIFICATION.G_Status_Text := 'Smoke verified: floor 2 group';
    ELSE
            GVL_SMOKE_VERIFICATION.G_Status_Text := 'Smoke verified';
    END_CASE;
ELSE
    IF GVL_SMOKE_VERIFICATION.G_Any_Smoke_Input_Active THEN
        GVL_SMOKE_VERIFICATION.G_Status_Text := 'Smoke input active - waiting verification';
    ELSE
        GVL_SMOKE_VERIFICATION.G_Status_Text := 'Smoke verification idle';
    END_IF;
END_IF;

// Status
IF VO_Smoke_Detected THEN
    VO_Status_Msg := 'ПОЖАР';
ELSIF VO_Methane_Critical_Level THEN
    VO_Status_Msg := 'КРИТИЧЕСКИЙ МЕТАН';
ELSIF VO_Methane_Alarm_Level THEN
    VO_Status_Msg := 'УТЕЧКА ГАЗА';
ELSIF VO_Methane_Warning_Level THEN
    VO_Status_Msg := 'ПРЕДУПРЕЖДЕНИЕ МЕТАН';
ELSIF VO_CO_Alarm_Level THEN
    VO_Status_Msg := 'КРИТИЧЕСКИЙ CO';
ELSIF VO_CO_Warning_Level THEN
    VO_Status_Msg := 'ПОВЫШЕННЫЙ CO';
ELSE
    VO_Status_Msg := 'ОК';
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Gas_Smoke_Manager <<<
END_FUNCTION_BLOCK