// ==============================================================================
// Heating runtime predictive correlation weighting engine
// Read-only predictive adaptive correlation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Predictive_Correlation_Weighting_Engine
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Risk : UINT;
    VI_Cascade_Risk : UINT;
    VI_OT_Risk : UINT;
END_VAR
VAR_OUTPUT
    VO_Correlation_Score : UINT;
    VO_Correlation_Degraded : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR
VAR
    L_Total : UINT;
END_VAR

VO_Correlation_Score := 0;
VO_Correlation_Degraded := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating predictive correlation engine disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

L_Total := VI_Runtime_Risk + VI_Cascade_Risk + VI_OT_Risk;
VO_Correlation_Score := L_Total / 3;

IF VO_Correlation_Score > 70 THEN
    VO_Correlation_Degraded := TRUE;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating predictive correlation critical';

ELSIF VO_Correlation_Score > 40 THEN
    VO_Correlation_Degraded := TRUE;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating predictive correlation degraded';

ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating predictive correlation nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Predictive_Correlation_Weighting_Engine <<<
