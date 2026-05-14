// ==============================================================================
// Heating runtime OT instability predictor
// Read-only predictive OT supervision layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_OT_Instability_Predictor
VAR_INPUT
    VI_Enable : BOOL;
    VI_OT_Degraded : BOOL;
    VI_OT_Command_Valid : BOOL;
END_VAR
VAR_OUTPUT
    VO_OT_Instability_Risk : UINT;
    VO_OT_Degraded_Trend : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_OT_Instability_Risk := 0;
VO_OT_Degraded_Trend := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime OT predictor disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF NOT VI_OT_Command_Valid THEN
    VO_OT_Instability_Risk := 100;
    VO_OT_Degraded_Trend := TRUE;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime OT instability critical';

ELSIF VI_OT_Degraded THEN
    VO_OT_Instability_Risk := 60;
    VO_OT_Degraded_Trend := TRUE;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime OT degradation trend';

ELSE
    VO_OT_Instability_Risk := 5;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime OT nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_OT_Instability_Predictor <<<
