// Упрощенная логика астро-таймера (ТЗ 15.2)
// В реальном проекте используется библиотека SysTimeRtc или расчет по формулам
L_Current_TOD := UDINT_TO_TOD(VI_System_Time_MS MOD 86400000);

// Примерные значения для средней полосы
VO_Sunrise_Time := TOD#06:00;
VO_Sunset_Time := TOD#18:00;

// ТЗ 15.2: Закат + 30 мин / Рассвет - 30 мин
VO_Is_Night := (L_Current_TOD > (VO_Sunset_Time + T#30m)) OR (L_Current_TOD < (VO_Sunrise_Time - T#30m));
