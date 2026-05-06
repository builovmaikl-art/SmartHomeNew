// ==============================================================================
// Heating runtime anomaly weighting engine
// Read-only adaptive anomaly weighting layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Anomaly_Weighting_Engine
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Degraded : BOOL;
    VI_Cascade_Degraded : BOOL;
    VI_OT_Degraded : BOOL;
    VI_Diagnostics_Degraded : BOOL;
END_VAR
VAR_OUTPUT
    VO_Runtime_Weight : UINT;
    VO_Cascade_Weight : UINT;
    VO_OT_Weight : UINT;
    VO_Diagnostics_Weight : UINT;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Runtime_Weight := 0;
VO_Cascade_Weight := 0;
VO_OT_Weight := 0;
VO_Diagnostics_Weight := 0;

VO_Status_Code := 0;
VO_Status_Text := 'Heating anomaly weighting engine disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Runtime_Weight := SEL(VI_Runtime_Degraded, 10, 80);
VO_Cascade_Weight := SEL(VI_Cascade_Degraded, 10, 70);
VO_OT_Weight := SEL(VI_OT_Degraded, 10, 75);
VO_Diagnostics_Weight := SEL(VI_Diagnostics_Degraded, 5, 40);

VO_Status_Code := 1;
VO_Status_Text := 'Heating anomaly weighting updated';

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Anomaly_Weighting_Engine <<<
