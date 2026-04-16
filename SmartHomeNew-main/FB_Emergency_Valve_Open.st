FUNCTION_BLOCK FB_Emergency_Valve_Open
VAR_INPUT
    VI_Fire_Alarm : BOOL; // Сигнал пожарной тревоги
    VI_Gas_Alarm  : BOOL; // Сигнал газовой тревоги
END_VAR
VAR_OUTPUT
    VO_Open_Cmd   : BOOL; // Команда на аварийное открытие клапана
END_VAR

// Приоритетное открытие при любой серьезной аварии
VO_Open_Cmd := VI_Fire_Alarm OR VI_Gas_Alarm;