FUNCTION_BLOCK FB_Manual_Valve_Control
VAR_INPUT
    VI_System_Time : UDINT;
    VI_Open_Req    : BOOL;
    VI_Duration    : UDINT := 5; // мин
END_VAR
VAR_OUTPUT
    VO_Open_Cmd    : BOOL;
    VO_Time_Left   : UDINT;
END_VAR
VAR
    L_Start_Time   : UDINT;
    L_Active       : BOOL;
    L_elapsed      : UDINT;
END_VAR

// Логика ручного управления клапаном с таймером автозакрытия
IF VI_Open_Req AND NOT L_Active THEN
    L_Active := TRUE;
    L_Start_Time := VI_System_Time;
    VO_Open_Cmd := TRUE;
END_IF;

IF L_Active THEN
    // Расчет оставшегося времени в минутах
    L_elapsed := (SEL(VI_System_Time >= L_Start_Time, VI_System_Time - L_Start_Time, (4294967295 - L_Start_Time) + VI_System_Time + 1)) / GVL_CONSTANTS.C_MS_IN_MINUTE;
    IF L_elapsed >= VI_Duration THEN
        L_Active := FALSE;
        VO_Open_Cmd := FALSE;
    ELSE
        VO_Time_Left := VI_Duration - L_elapsed;
    END_IF;
ELSE
    VO_Time_Left := 0;
END_IF;