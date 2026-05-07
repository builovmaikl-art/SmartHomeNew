// ==============================================================================
// Heating runtime phase telemetry aggregator
// Read-only deterministic orchestration telemetry layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Phase_Telemetry_Aggregator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Transition : ST_Heating_Runtime_Phase_Transition;
    VI_Sequencing_Valid : BOOL;
END_VAR
VAR_OUTPUT
    VO_Phase_Healthy : BOOL;
    VO_Phase_Degraded : BOOL;
    VO_Phase_Critical : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Phase_Healthy := FALSE;
VO_Phase_Degraded := FALSE;
VO_Phase_Critical := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime phase telemetry disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF NOT VI_Sequencing_Valid THEN
    VO_Phase_Critical := TRUE;
    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime sequencing critical';

ELSIF VI_Transition.Transition_Failed THEN
    VO_Phase_Critical := TRUE;
    VO_Status_Code := 901;
    VO_Status_Text := 'Heating runtime phase transition failed';

ELSIF VI_Transition.Transition_Duration_MS > 5000 THEN
    VO_Phase_Degraded := TRUE;
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime phase transition degraded';

ELSE
    VO_Phase_Healthy := TRUE;
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime phase telemetry healthy';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Phase_Telemetry_Aggregator <<<
