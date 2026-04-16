FUNCTION_BLOCK FB_Sensor_Distribution
VAR_INPUT
    VI_Raw_Temp : REAL;
    VI_Raw_Hum  : REAL;
    VI_Raw_CO2  : REAL;
END_VAR
VAR_OUTPUT
    VO_Temp_Heating : REAL;
    VO_Temp_Vent    : REAL;
    VO_Hum_Vent     : REAL;
    VO_CO2_Vent     : REAL;
END_VAR

// Распределение данных по подсистемам
VO_Temp_Heating := VI_Raw_Temp;
VO_Temp_Vent    := VI_Raw_Temp;
VO_Hum_Vent     := VI_Raw_Hum;
VO_CO2_Vent     := VI_Raw_CO2;