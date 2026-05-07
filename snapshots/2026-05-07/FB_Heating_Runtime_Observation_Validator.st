// ==============================================================================
// Heating runtime observation validator
// Read-only observation validation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Observation_Validator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Observation : ST_Heating_Runtime_Observation;
END_VAR
VAR_OUTPUT
    VO_Observation_Valid : BOOL;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Observation_Valid := FALSE;
VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime observation validator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Observation_Valid :=
    VI_Observation.Runtime_Ownership_Valid AND
    VI_Observation.Diagnostics_Ownership_Valid AND
    VI_Observation.OpenTherm_Ownership_Valid AND
    VI_Observation.Cascade_Ownership_Valid AND
    VI_Observation.Safety_Ownership_Valid AND
    VI_Observation.DHW_Before_Heating_Observed AND
    VI_Observation.Diagnostics_After_Publication_Observed AND
    VI_Observation.Output_Projection_Last_Observed;

IF VO_Observation_Valid THEN
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime observation valid';
ELSE
    VO_Status_Code := 100;
    VO_Status_Text := 'Heating runtime observation invalid';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observation_Validator <<<
