FUNCTION_BLOCK FB_Pre_Departure_Heating
VAR_INPUT
    VI_Departure_Time : UDINT;
    VI_System_Time    : UDINT;
END_VAR
VAR_IN_OUT
    VI_Selected       : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
END_VAR
VAR_OUTPUT
    VO_Heating_Active : BOOL;
    VO_Setpoints      : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
END_VAR

VAR
    L_i : INT;
END_VAR

// Запуск за 3 часа (10800000 мс)
IF (SEL(VI_Departure_Time >= VI_System_Time, VI_Departure_Time - VI_System_Time, (4294967295 - VI_System_Time) + VI_Departure_Time + 1)) < 10800000 THEN
    VO_Heating_Active := TRUE;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
        IF VI_Selected[L_i] THEN VO_Setpoints[L_i] := 22.0; END_IF;
    END_FOR;
ELSE
    VO_Heating_Active := FALSE;
END_IF;