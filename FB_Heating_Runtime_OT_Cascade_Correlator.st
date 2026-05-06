// ==============================================================================
// Heating runtime OT and cascade correlator
// Read-only degradation correlation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_OT_Cascade_Correlator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Cascade_Degraded : BOOL;
    VI_OT_Degraded : BOOL;
    VI_OT_Command_Valid : BOOL;
    VI_Boiler_Count : UINT;
END_VAR
VAR_OUTPUT
    VO_Correlation_Detected : BOOL;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Correlation_Detected := FALSE;
VO_Status_Code := 0;
VO_Status_Text := 'Heating OT/cascade correlator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Correlation_Detected :=
    VI_Cascade_Degraded OR
    VI_OT_Degraded OR
    NOT VI_OT_Command_Valid OR
    (VI_Boiler_Count = 0);

IF VO_Correlation_Detected THEN
    VO_Status_Code := 200;
    VO_Status_Text := 'Heating OT/cascade degradation correlated';
ELSE
    VO_Status_Code := 1;
    VO_Status_Text := 'Heating OT/cascade nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_OT_Cascade_Correlator <<<
