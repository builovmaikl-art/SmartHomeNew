FUNCTION_BLOCK FB_Outdoor_Lighting_Controller
VAR_INPUT
    VI_Ambient_Lux : REAL;
    VI_Motion      : BOOL;
    VI_Security    : BOOL;
END_VAR
VAR_OUTPUT
    VO_Light_On    : BOOL;
END_VAR

IF VI_Security AND VI_Motion THEN
    VO_Light_On := TRUE; // Тревожное освещение
ELSIF VI_Ambient_Lux < 50.0 THEN
    VO_Light_On := TRUE; // Ночное освещение
ELSE
    VO_Light_On := FALSE;
END_IF;