// ==============================================================================
// Heating runtime supervision confidence analyzer
// Read-only adaptive confidence supervision layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Supervision_Confidence_Analyzer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Stable : BOOL;
    VI_Runtime_Degraded : BOOL;
END_VAR
VAR_OUTPUT
    VO_Supervision_Confidence : UINT;
    VO_Confidence_Degraded : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Supervision_Confidence := 0;
VO_Confidence_Degraded := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating supervision confidence analyzer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Runtime_Degraded THEN
    VO_Supervision_Confidence := 40;
    VO_Confidence_Degraded := TRUE;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating supervision confidence degraded';

ELSIF VI_Runtime_Stable THEN
    VO_Supervision_Confidence := 95;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating supervision confidence nominal';

ELSE
    VO_Supervision_Confidence := 60;

    VO_Status_Code := 100;
    VO_Status_Text := 'Heating supervision confidence transitional';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Supervision_Confidence_Analyzer <<<
