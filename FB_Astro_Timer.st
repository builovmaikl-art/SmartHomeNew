FUNCTION_BLOCK FB_Astro_Timer
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Latitude : REAL := 55.75; // Москва (по умолчанию)
    VI_Longitude : REAL := 37.61;
    VI_Timezone : REAL := 3.0; // UTC+3
    VI_Day_Of_Year : UINT; // День года (1-365)
END_VAR
// >>> SYNC_TEST_MARKER_002 <<<
VAR_OUTPUT
    VO_Sunset_Time : TOD;
    VO_Sunrise_Time : TOD;
    VO_Is_Night : BOOL;
    VO_Current_TOD : TOD; // Текущее время суток
END_VAR
VAR
    L_Current_TOD : TOD;
    L_Pi : REAL := 3.14159265359;
    L_Rad : REAL := 3.14159265359 / 180.0;
    L_Deg : REAL := 180.0 / 3.14159265359;
    L_B : REAL;
    L_EoT : REAL;
    L_Declination : REAL;
    L_Cos_Omega : REAL;
    L_Omega : REAL;
    L_Sunrise_Local : REAL;
    L_Sunset_Local : REAL;
END_VAR

L_Current_TOD := GVL_STATUS.G_Current_TOD;
VO_Current_TOD := L_Current_TOD;

// Equation of Time (EoT) in minutes
L_B := 360.0 / 365.0 * TO_REAL(VI_Day_Of_Year - 81) * L_Rad;
L_EoT := 9.87 * SIN(2.0 * L_B) - 7.53 * COS(L_B) - 1.5 * SIN(L_B);

// Solar Declination in degrees
L_Declination := 23.45 * SIN(360.0 / 365.0 * TO_REAL(VI_Day_Of_Year + 284) * L_Rad);

// Hour angle
L_Cos_Omega := -TAN(VI_Latitude * L_Rad) * TAN(L_Declination * L_Rad);

IF L_Cos_Omega > 1.0 THEN
    L_Cos_Omega := 1.0; // Polar night
ELSIF L_Cos_Omega < -1.0 THEN
    L_Cos_Omega := -1.0; // Polar day
END_IF;

L_Omega := ACOS(L_Cos_Omega) * L_Deg;

// Sunrise and Sunset in local time (hours)
L_Sunrise_Local := 12.0 - (L_Omega / 15.0) - (L_EoT / 60.0) + (VI_Timezone * 15.0 - VI_Longitude) / 15.0;
L_Sunset_Local := 12.0 + (L_Omega / 15.0) - (L_EoT / 60.0) + (VI_Timezone * 15.0 - VI_Longitude) / 15.0;

// Handle bounds
IF L_Sunrise_Local < 0.0 THEN L_Sunrise_Local := L_Sunrise_Local + 24.0; END_IF;
IF L_Sunrise_Local >= 24.0 THEN L_Sunrise_Local := L_Sunrise_Local - 24.0; END_IF;
IF L_Sunset_Local < 0.0 THEN L_Sunset_Local := L_Sunset_Local + 24.0; END_IF;
IF L_Sunset_Local >= 24.0 THEN L_Sunset_Local := L_Sunset_Local - 24.0; END_IF;

// Конвертация в TOD
VO_Sunrise_Time := TO_TOD(TO_UDINT(L_Sunrise_Local * 3600000.0));
VO_Sunset_Time := TO_TOD(TO_UDINT(L_Sunset_Local * 3600000.0));

// ТЗ 15.2: Закат + 30 мин / Рассвет - 30 мин
VO_Is_Night := (L_Current_TOD > (VO_Sunset_Time + T#30m)) OR (L_Current_TOD < (VO_Sunrise_Time - T#30m));
// >>> SYNC_TEST_MARKER_FORCE <<<
// >>> BULK_SYNC_ANCHOR: FB_Astro_Timer <<<
