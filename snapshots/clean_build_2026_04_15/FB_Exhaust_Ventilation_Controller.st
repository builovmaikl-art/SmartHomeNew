FUNCTION_BLOCK FB_Exhaust_Ventilation_Controller
VAR_INPUT
    VI_Humidity : REAL;
    VI_CO2      : REAL;
    VI_Config   : ST_Ventilation_Unit_Config;
END_VAR
VAR_OUTPUT
    VO_Fan_Speed : BYTE;
END_VAR

IF VI_Humidity > VI_Config.Threshold_Hum THEN
    VO_Fan_Speed := 100;
ELSIF VI_CO2 > 800.0 THEN
    VO_Fan_Speed := 70;
ELSE
    VO_Fan_Speed := 40;
END_IF;