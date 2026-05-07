// ==============================================================================
// Heating runtime adaptive risk scorer
// Read-only adaptive supervision scoring layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Adaptive_Risk_Scorer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Degraded : BOOL;
    VI_Runtime_Critical : BOOL;
END_VAR
VAR_OUTPUT
    VO_Adaptive_Runtime_Risk : UINT;
    VO_Adaptive_Runtime_Stability : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Adaptive_Runtime_Risk := 0;
VO_Adaptive_Runtime_Stability := 100;

VO_Status_Code := 0;
VO_Status_Text := 'Heating adaptive risk scorer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Runtime_Critical THEN
    VO_Adaptive_Runtime_Risk := 100;
    VO_Adaptive_Runtime_Stability := 0;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime adaptive risk critical';

ELSIF VI_Runtime_Degraded THEN
    VO_Adaptive_Runtime_Risk := 60;
    VO_Adaptive_Runtime_Stability := 40;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime adaptive degradation';

ELSE
    VO_Adaptive_Runtime_Risk := 5;
    VO_Adaptive_Runtime_Stability := 95;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime adaptive supervision nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Adaptive_Risk_Scorer <<<
