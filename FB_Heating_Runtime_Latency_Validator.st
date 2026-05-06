// ==============================================================================
// Heating runtime latency validator
// Read-only deterministic execution latency validator.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Latency_Validator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Frame_Duration_MS : UDINT;
END_VAR
VAR_OUTPUT
    VO_Latency_Detected : BOOL;
    VO_Runtime_Degraded : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Latency_Detected := FALSE;
VO_Runtime_Degraded := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime latency validator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Frame_Duration_MS > 1000 THEN
    VO_Latency_Detected := TRUE;
    VO_Runtime_Degraded := TRUE;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime latency critical';

ELSIF VI_Frame_Duration_MS > 500 THEN
    VO_Latency_Detected := TRUE;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime latency degraded';

ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime latency nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Latency_Validator <<<
