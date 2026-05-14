// ==============================================================================
// Heating runtime stability model
// Read-only predictive runtime stability layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Stability_Model
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Degraded : BOOL;
    VI_Runtime_Critical : BOOL;
END_VAR
VAR_OUTPUT
    VO_Runtime_Stable : BOOL;
    VO_Stability_Score : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Runtime_Stable := FALSE;
VO_Stability_Score := 0;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime stability model disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Runtime_Critical THEN
    VO_Runtime_Stable := FALSE;
    VO_Stability_Score := 0;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime critically unstable';

ELSIF VI_Runtime_Degraded THEN
    VO_Runtime_Stable := FALSE;
    VO_Stability_Score := 50;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime degraded stability';

ELSE
    VO_Runtime_Stable := TRUE;
    VO_Stability_Score := 100;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime stable';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Stability_Model <<<
