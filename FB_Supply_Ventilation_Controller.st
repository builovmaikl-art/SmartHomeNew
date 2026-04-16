FUNCTION_BLOCK FB_Supply_Ventilation_Controller
VAR_INPUT
    VI_Outdoor_Temp : REAL;
    VI_Supply_Temp  : REAL; // Температура приточного воздуха
    VI_Target_Temp  : REAL;
    VI_Config       : ST_Ventilation_Unit_Config;
END_VAR
VAR_OUTPUT
    VO_Heater_Power : REAL; // 0-100%
    VO_Fan_Speed    : BYTE; // 0-100%
END_VAR
VAR
    L_PID : FB_PID_Controller;
END_VAR

// ПИД-регулятор калорифера
L_PID(
    VI_SetPoint := VI_Target_Temp,
    VI_ProcessValue := VI_Supply_Temp, // Используем датчик притока
    VI_Kp := 5.0, VI_Tn := 60.0, VI_Tv := 0.0,
    VI_Y_Min := 0.0, VI_Y_Max := 100.0, VI_Cycle_Time_S := 1.0,
    VO_Output => VO_Heater_Power
);

VO_Fan_Speed := 50; // Базовая скорость