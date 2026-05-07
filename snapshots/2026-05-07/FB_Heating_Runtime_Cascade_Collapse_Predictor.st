// ==============================================================================
// Heating runtime cascade observational analytics
// Read-only passive predictive analytics layer.
// No advisory or control authority exists.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Cascade_Collapse_Predictor
VAR_INPUT
    VI_Enable : BOOL;
    VI_Cascade_Degraded : BOOL;
    VI_Active_Boilers : UINT;
END_VAR
VAR_OUTPUT
    VO_Cascade_Degradation_Observation : UINT;
    VO_Cascade_Degraded_Trend_Visible : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Cascade_Degradation_Observation := 0;
VO_Cascade_Degraded_Trend_Visible := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime cascade analytics disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF (VI_Active_Boilers = 0) THEN
    VO_Cascade_Degradation_Observation := 100;
    VO_Cascade_Degraded_Trend_Visible := TRUE;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime cascade degradation observed';

ELSIF VI_Cascade_Degraded THEN
    VO_Cascade_Degradation_Observation := 60;
    VO_Cascade_Degraded_Trend_Visible := TRUE;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime cascade degradation trend visible';

ELSE
    VO_Cascade_Degradation_Observation := 5;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime cascade analytics nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Cascade_Collapse_Predictor <<<
