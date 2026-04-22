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
    VO_Smoke_Detected   : BOOL;
    VO_Gas_Detected     : BOOL;
    VO_CO_Warning_Level : BOOL;
    VO_CO_Alarm_Level   : BOOL;
    VO_Status_Msg       : STRING(200);
END_VAR

VAR
    L_Methane_Max   : REAL;
    L_CO_Max        : REAL;
    L_Smoke_Count   : UINT;
    L_Smoke_Active  : BOOL;
    L_i             : INT;

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

IF L_Methane_Max >= 20.0 THEN
    VO_Gas_Detected := TRUE;
END_IF;

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

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SMOKE_SENSORS DO
    L_Smoke_Timer[L_i](IN := VI_Smoke_Sensors[L_i], PT := T#30s, VI_System_Time_MS := VI_System_Time_MS);

    IF VI_Smoke_Sensors[L_i] THEN
        L_Smoke_Count := L_Smoke_Count + 1;
    END_IF;

    IF L_Smoke_Timer[L_i].Q OR (L_Smoke_Count >= 2) THEN
        L_Smoke_Active := TRUE;
    END_IF;
END_FOR;

IF L_Smoke_Active THEN
    VO_Smoke_Detected := TRUE;
END_IF;

// Status
IF VO_Smoke_Detected THEN
    VO_Status_Msg := 'ПОЖАР';
ELSIF VO_Gas_Detected THEN
    VO_Status_Msg := 'УТЕЧКА ГАЗА';
ELSIF VO_CO_Alarm_Level THEN
    VO_Status_Msg := 'КРИТИЧЕСКИЙ CO';
ELSIF VO_CO_Warning_Level THEN
    VO_Status_Msg := 'ПОВЫШЕННЫЙ CO';
ELSE
    VO_Status_Msg := 'ОК';
END_IF;
// >>> BULK_SYNC_ANCHOR: FB_Gas_Smoke_Manager <<<
