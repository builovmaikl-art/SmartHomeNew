// ==============================================================================
// Heating runtime intelligence consistency analyzer
// Read-only meta-supervision consistency layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Intelligence_Consistency_Analyzer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Integrity_Valid : BOOL;
    VI_Drift_Detected : BOOL;
    VI_Decay_Detected : BOOL;
END_VAR
VAR_OUTPUT
    VO_Consistency_Valid : BOOL;
    VO_Consistency_Score : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

// ======================================================
// DETERMINISTIC DEFAULTS
// ======================================================
VO_Consistency_Valid := FALSE;
VO_Consistency_Score := 0;

VO_Status_Code := 0;
VO_Status_Text := 'Heating intelligence consistency analyzer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// CONSISTENCY ANALYSIS
// ======================================================
VO_Consistency_Valid :=
    VI_Integrity_Valid AND
    NOT VI_Drift_Detected AND
    NOT VI_Decay_Detected;

IF VO_Consistency_Valid THEN
    VO_Consistency_Score := 95;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating intelligence consistency nominal';

ELSIF VI_Integrity_Valid THEN
    VO_Consistency_Score := 60;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating intelligence consistency degraded';

ELSE
    VO_Consistency_Score := 10;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating intelligence consistency invalid';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Intelligence_Consistency_Analyzer <<<
