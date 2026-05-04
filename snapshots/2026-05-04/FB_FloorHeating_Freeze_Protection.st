FUNCTION_BLOCK FB_FloorHeating_Freeze_Protection
VAR_INPUT
    VI_Outdoor_Temp : REAL;
    VI_Threshold : REAL := 7.0;
END_VAR
VAR_IN_OUT
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
END_VAR
VAR_OUTPUT
    VO_Freeze_Alert : BOOL;
    VO_Pump_Force_On : BOOL;
END_VAR
VAR
    L_i : INT;
END_VAR

VO_Freeze_Alert := FALSE;
VO_Pump_Force_On := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    IF VI_Floor_Temps[L_i] < VI_Threshold THEN
        VO_Freeze_Alert := TRUE;
        VO_Pump_Force_On := TRUE;
        RETURN;
    END_IF;
END_FOR;

IF VI_Outdoor_Temp < -5.0 THEN
    VO_Pump_Force_On := TRUE;
END_IF;
END_FUNCTION_BLOCK
