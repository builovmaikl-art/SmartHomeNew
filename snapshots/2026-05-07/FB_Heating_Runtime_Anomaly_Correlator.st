// ==============================================================================
// Heating runtime anomaly correlator
// Read-only runtime anomaly correlation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Anomaly_Correlator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Jitter : BOOL;
    VI_Runtime_Latency : BOOL;
    VI_Runtime_Degraded : BOOL;
    VI_Sequencing_Valid : BOOL;
    VI_Ownership_Valid : BOOL;
    VI_Synchronization_Valid : BOOL;
END_VAR
VAR_OUTPUT
    VO_Anomaly : ST_Heating_Runtime_Anomaly;
END_VAR

VO_Anomaly.Anomaly_Active := FALSE;
VO_Anomaly.Anomaly_Acknowledged := FALSE;
VO_Anomaly.Anomaly_Cleared := FALSE;

VO_Anomaly.Status_Code := 0;
VO_Anomaly.Status_Text := 'Heating runtime anomaly correlator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Anomaly.Runtime_Jitter_Detected := VI_Runtime_Jitter;
VO_Anomaly.Runtime_Latency_Detected := VI_Runtime_Latency;
VO_Anomaly.Runtime_Degraded := VI_Runtime_Degraded;

VO_Anomaly.Sequencing_Invalid := NOT VI_Sequencing_Valid;
VO_Anomaly.Ownership_Invalid := NOT VI_Ownership_Valid;
VO_Anomaly.Synchronization_Invalid := NOT VI_Synchronization_Valid;

VO_Anomaly.Anomaly_Active :=
    VI_Runtime_Jitter OR
    VI_Runtime_Latency OR
    VI_Runtime_Degraded OR
    NOT VI_Sequencing_Valid OR
    NOT VI_Ownership_Valid OR
    NOT VI_Synchronization_Valid;

IF VO_Anomaly.Anomaly_Active THEN
    VO_Anomaly.Status_Code := 100;
    VO_Anomaly.Status_Text := 'Heating runtime anomaly detected';
ELSE
    VO_Anomaly.Status_Code := 1;
    VO_Anomaly.Status_Text := 'Heating runtime nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Anomaly_Correlator <<<
