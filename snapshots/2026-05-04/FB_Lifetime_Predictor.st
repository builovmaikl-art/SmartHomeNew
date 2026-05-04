FUNCTION_BLOCK FB_Lifetime_Predictor
VAR_INPUT
    VI_Runtime_Hours : UDINT;
    VI_Start_Count   : UDINT;
    VI_Nominal_Life  : UDINT := 10000;
END_VAR
VAR_OUTPUT
    VO_Remaining_Percent : BYTE;
    VO_Maintenance_Req   : BOOL;
END_VAR

// Упрощенная модель износа
IF VI_Nominal_Life > 0 THEN
    VO_Remaining_Percent := TO_BYTE(100 - (VI_Runtime_Hours * 100 / VI_Nominal_Life));
ELSE
    VO_Remaining_Percent := 0;
END_IF;

VO_Maintenance_Req := (VO_Remaining_Percent < 10);
END_FUNCTION_BLOCK
