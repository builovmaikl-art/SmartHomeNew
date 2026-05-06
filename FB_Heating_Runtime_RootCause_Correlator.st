// ==============================================================================
// Heating runtime root-cause correlator
// Read-only runtime causality correlation layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_RootCause_Correlator
VAR_INPUT
    VI_Enable : BOOL;
    VI_Anomaly : ST_Heating_Runtime_Anomaly;
END_VAR
VAR_OUTPUT
    VO_Node : ST_Heating_Runtime_Causality_Node;
END_VAR

VO_Node.Node_Active := FALSE;
VO_Node.Root_Cause_Candidate := FALSE;

VO_Node.Status_Code := 0;
VO_Node.Status_Text := 'Heating runtime root-cause correlator disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Node.Node_Active := VI_Anomaly.Anomaly_Active;

VO_Node.Runtime_Degraded := VI_Anomaly.Runtime_Degraded;
VO_Node.Cascade_Degraded := VI_Anomaly.Cascade_Degraded;
VO_Node.Cascade_Boiler_Loss := VI_Anomaly.Cascade_Boiler_Loss_Detected;

VO_Node.OpenTherm_Degraded :=
    VI_Anomaly.OpenTherm_Transport_Degraded;

VO_Node.OpenTherm_Command_Invalid :=
    VI_Anomaly.OpenTherm_Command_Invalid;

VO_Node.Diagnostics_Degraded :=
    VI_Anomaly.Diagnostics_Degraded;

VO_Node.Explainability_Degraded :=
    VI_Anomaly.Explainability_Degraded;

VO_Node.Sequencing_Invalid :=
    VI_Anomaly.Sequencing_Invalid;

VO_Node.Ownership_Invalid :=
    VI_Anomaly.Ownership_Invalid;

VO_Node.Synchronization_Invalid :=
    VI_Anomaly.Synchronization_Invalid;

VO_Node.Severity_Level :=
    VI_Anomaly.Severity_Level;

VO_Node.Root_Cause_Candidate :=
    VI_Anomaly.Critical_Anomaly OR
    VI_Anomaly.Sequencing_Invalid OR
    VI_Anomaly.Ownership_Invalid OR
    VI_Anomaly.Synchronization_Invalid;

IF VO_Node.Root_Cause_Candidate THEN
    VO_Node.Status_Code := 900;
    VO_Node.Status_Text := 'Heating runtime root-cause candidate detected';
ELSE
    VO_Node.Status_Code := 1;
    VO_Node.Status_Text := 'Heating runtime causality nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_RootCause_Correlator <<<
