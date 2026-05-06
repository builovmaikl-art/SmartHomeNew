// ==============================================================================
// Heating runtime anomaly aggregator
// Read-only anomaly aggregation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Anomaly_Aggregator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Anomaly : ST_Heating_Runtime_Anomaly;
    VI_OT_Cascade_Correlation : BOOL;
END_VAR
VAR_OUTPUT
    VO_Runtime_Degraded : BOOL;
    VO_Runtime_Critical : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Runtime_Degraded := FALSE;
VO_Runtime_Critical := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime anomaly aggregator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Anomaly.Critical_Anomaly THEN
    VO_Runtime_Critical := TRUE;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime critical anomaly';

ELSIF VI_Anomaly.Anomaly_Active OR
      VI_OT_Cascade_Correlation THEN

    VO_Runtime_Degraded := TRUE;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime degraded anomaly state';

ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime anomaly nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Anomaly_Aggregator <<<
