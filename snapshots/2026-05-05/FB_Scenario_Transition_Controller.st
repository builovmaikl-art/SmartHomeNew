FUNCTION_BLOCK FB_Scenario_Transition_Controller
VAR_INPUT
    VI_System_Time : UDINT;
    VI_Start_Time  : UDINT;
    VI_Duration    : UDINT; // Длительность перехода (мс)
    VI_Start_Value : REAL;  // Начальное значение
    VI_End_Value   : REAL;  // Конечное значение
END_VAR
VAR_OUTPUT
    VO_Current_Value : REAL; // Текущее интерполированное значение
    VO_Transition_Done : BOOL; // Флаг завершения перехода
END_VAR
VAR
    L_Elapsed : UDINT;
    L_Progress : REAL;
END_VAR

L_Elapsed := (SEL(VI_System_Time >= VI_Start_Time, VI_System_Time - VI_Start_Time, (4294967295 - VI_Start_Time) + VI_System_Time + 1));

IF L_Elapsed >= VI_Duration OR VI_Duration = 0 THEN
    VO_Current_Value := VI_End_Value;
    VO_Transition_Done := TRUE;
ELSE
    L_Progress := UDINT_TO_REAL(L_Elapsed) / UDINT_TO_REAL(VI_Duration);
    VO_Current_Value := VI_Start_Value + (VI_End_Value - VI_Start_Value) * L_Progress;
    VO_Transition_Done := FALSE;
END_IF;
END_FUNCTION_BLOCK
