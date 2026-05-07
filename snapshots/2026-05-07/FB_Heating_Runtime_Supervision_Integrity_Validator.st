// ==============================================================================
// Heating runtime supervision integrity validator
// Read-only meta-supervision integrity layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Supervision_Integrity_Validator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Confidence : UINT;
    VI_Correlation_Score : UINT;
END_VAR
VAR_OUTPUT
    VO_Integrity_Valid : BOOL;
    VO_Integrity_Score : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Integrity_Valid := FALSE;
VO_Integrity_Score := 0;

VO_Status_Code := 0;
VO_Status_Text := 'Heating supervision integrity validator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Integrity_Score :=
    (VI_Confidence + VI_Correlation_Score) / 2;

VO_Integrity_Valid :=
    (VO_Integrity_Score >= 60);

IF NOT VO_Integrity_Valid THEN
    VO_Status_Code := 900;
    VO_Status_Text := 'Heating supervision integrity invalid';

ELSIF VO_Integrity_Score < 80 THEN
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating supervision integrity degraded';

ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating supervision integrity nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Supervision_Integrity_Validator <<<
