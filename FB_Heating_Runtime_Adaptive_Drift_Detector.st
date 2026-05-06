// ==============================================================================
// Heating runtime adaptive drift detector
// Read-only adaptive supervision drift analysis layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Adaptive_Drift_Detector
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Risk : UINT;
    VI_Runtime_Stability : UINT;
END_VAR
VAR_OUTPUT
    VO_Drift_Detected : BOOL;
    VO_Drift_Score : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR
VAR
    L_Delta : UINT;
END_VAR

VO_Drift_Detected := FALSE;
VO_Drift_Score := 0;

VO_Status_Code := 0;
VO_Status_Text := 'Heating adaptive drift detector disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Runtime_Risk > VI_Runtime_Stability THEN
    L_Delta := VI_Runtime_Risk - VI_Runtime_Stability;
ELSE
    L_Delta := VI_Runtime_Stability - VI_Runtime_Risk;
END_IF;

VO_Drift_Score := L_Delta;
VO_Drift_Detected := (L_Delta > 40);

IF VO_Drift_Detected THEN
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating adaptive supervision drift detected';
ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating adaptive supervision stable';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Adaptive_Drift_Detector <<<
