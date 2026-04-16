FUNCTION_BLOCK FB_Manifold_Pump_Controller
VAR_INPUT
    VI_Enable_Request : BOOL;
    VI_System_Time : UDINT;
    VI_Stop_Ramp_MS : UDINT := 5000;
END_VAR
VAR_OUTPUT
    VO_Speed_Percent : BYTE;
    VO_Running : BOOL;
END_VAR
VAR
    L_Stop_Start_Time : UDINT;
    L_Stopping : BOOL;
    L_elapsed : UDINT;
END_VAR

IF VI_Enable_Request THEN
    VO_Speed_Percent := 100;
    VO_Running := TRUE;
    L_Stopping := FALSE;
ELSE
    IF VO_Running AND NOT L_Stopping THEN
        L_Stopping := TRUE;
        L_Stop_Start_Time := VI_System_Time;
    END_IF;
    
    IF L_Stopping THEN
        L_elapsed := (SEL(VI_System_Time >= L_Stop_Start_Time, VI_System_Time - L_Stop_Start_Time, (4294967295 - L_Stop_Start_Time) + VI_System_Time + 1));
        IF L_elapsed < VI_Stop_Ramp_MS THEN
            // Исправлено: защита от отрицательного значения
            VO_Speed_Percent := REAL_TO_BYTE(100.0 * (1.0 - TO_REAL(L_elapsed) / TO_REAL(VI_Stop_Ramp_MS)));
        ELSE
            VO_Speed_Percent := 0;
            VO_Running := FALSE;
            L_Stopping := FALSE;
        END_IF;
    END_IF;
END_IF;