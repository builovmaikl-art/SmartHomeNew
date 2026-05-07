// ==============================================================================
// Heating runtime confidence decay analyzer
// Read-only predictive confidence decay layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Confidence_Decay_Analyzer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Confidence : UINT;
END_VAR
VAR_OUTPUT
    VO_Decay_Detected : BOOL;
    VO_Decay_Score : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Decay_Detected := FALSE;
VO_Decay_Score := 0;

VO_Status_Code := 0;
VO_Status_Text := 'Heating confidence decay analyzer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Confidence < 40 THEN
    VO_Decay_Detected := TRUE;
    VO_Decay_Score := 90;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating supervision confidence critical decay';

ELSIF VI_Confidence < 70 THEN
    VO_Decay_Detected := TRUE;
    VO_Decay_Score := 50;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating supervision confidence degraded';

ELSE
    VO_Decay_Score := 5;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating supervision confidence nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Confidence_Decay_Analyzer <<<
