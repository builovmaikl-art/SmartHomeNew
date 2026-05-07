// ==============================================================================
// Heating runtime jitter detector
// Read-only deterministic runtime jitter detector.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Jitter_Detector
VAR_INPUT
    VI_Enable : BOOL;
    VI_Frame_Duration_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Jitter_Detected : BOOL;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Jitter_Detected := FALSE;
VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime jitter detector disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Frame_Duration_MS > 250 THEN
    VO_Jitter_Detected := TRUE;
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime jitter detected';
ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime jitter nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Jitter_Detector <<<
