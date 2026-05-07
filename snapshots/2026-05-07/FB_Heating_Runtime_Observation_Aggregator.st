// ==============================================================================
// Heating runtime observation aggregator
// Read-only orchestration observation aggregation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Observation_Aggregator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Observation : ST_Heating_Runtime_Observation;
    VI_Observation_Valid : BOOL;
END_VAR
VAR_OUTPUT
    VO_Runtime_Healthy : BOOL;
    VO_Runtime_Degraded : BOOL;
    VO_Runtime_Critical : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Runtime_Healthy := FALSE;
VO_Runtime_Degraded := FALSE;
VO_Runtime_Critical := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime observation aggregator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF NOT VI_Observation_Valid THEN
    VO_Runtime_Critical := TRUE;
    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime observation invalid';

ELSIF VI_Observation.Runtime_Fault THEN
    VO_Runtime_Critical := TRUE;
    VO_Status_Code := 901;
    VO_Status_Text := 'Heating runtime fault observed';

ELSIF VI_Observation.Cascade_Degraded OR
      VI_Observation.OpenTherm_Transport_Degraded THEN

    VO_Runtime_Degraded := TRUE;
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime degraded';

ELSE
    VO_Runtime_Healthy := TRUE;
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime healthy';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observation_Aggregator <<<
