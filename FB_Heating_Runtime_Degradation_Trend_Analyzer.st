// ==============================================================================
// Heating runtime degradation trend analyzer
// Read-only predictive degradation trend layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Degradation_Trend_Analyzer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Degraded : BOOL;
    VI_Runtime_Critical : BOOL;
END_VAR
VAR_OUTPUT
    VO_Degradation_Risk : UINT;
    VO_Failure_Probability : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Degradation_Risk := 0;
VO_Failure_Probability := 0;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime degradation trend analyzer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Runtime_Critical THEN
    VO_Degradation_Risk := 100;
    VO_Failure_Probability := 95;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime failure risk critical';

ELSIF VI_Runtime_Degraded THEN
    VO_Degradation_Risk := 60;
    VO_Failure_Probability := 40;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime degradation trend detected';

ELSE
    VO_Degradation_Risk := 10;
    VO_Failure_Probability := 5;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime degradation nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Degradation_Trend_Analyzer <<<
