// ==============================================================================
// Heating runtime causality propagation analyzer
// Read-only runtime propagation analysis layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Causality_Propagation_Analyzer
VAR_INPUT
    VI_Enable : BOOL;
    VI_Node : ST_Heating_Runtime_Causality_Node;
END_VAR
VAR_OUTPUT
    VO_Edge : ST_Heating_Runtime_Causality_Edge;
END_VAR

VO_Edge.Edge_Active := FALSE;
VO_Edge.Propagation_Detected := FALSE;

VO_Edge.Status_Code := 0;
VO_Edge.Status_Text := 'Heating runtime causality propagation analyzer disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Edge.Edge_Active := VI_Node.Node_Active;

VO_Edge.Runtime_Propagation :=
    VI_Node.Runtime_Degraded;

VO_Edge.Cascade_Propagation :=
    VI_Node.Cascade_Degraded OR
    VI_Node.Cascade_Boiler_Loss;

VO_Edge.OpenTherm_Propagation :=
    VI_Node.OpenTherm_Degraded OR
    VI_Node.OpenTherm_Command_Invalid;

VO_Edge.Diagnostics_Propagation :=
    VI_Node.Diagnostics_Degraded OR
    VI_Node.Explainability_Degraded;

VO_Edge.Sequencing_Propagation :=
    VI_Node.Sequencing_Invalid;

VO_Edge.Ownership_Propagation :=
    VI_Node.Ownership_Invalid;

VO_Edge.Synchronization_Propagation :=
    VI_Node.Synchronization_Invalid;

VO_Edge.Propagation_Detected :=
    VO_Edge.Runtime_Propagation OR
    VO_Edge.Cascade_Propagation OR
    VO_Edge.OpenTherm_Propagation OR
    VO_Edge.Diagnostics_Propagation OR
    VO_Edge.Sequencing_Propagation OR
    VO_Edge.Ownership_Propagation OR
    VO_Edge.Synchronization_Propagation;

VO_Edge.Severity_Level := VI_Node.Severity_Level;

VO_Edge.Critical_Path :=
    VI_Node.Root_Cause_Candidate;

IF VO_Edge.Critical_Path THEN
    VO_Edge.Status_Code := 900;
    VO_Edge.Status_Text := 'Heating runtime critical propagation path';
ELSIF VO_Edge.Propagation_Detected THEN
    VO_Edge.Status_Code := 200;
    VO_Edge.Status_Text := 'Heating runtime propagation detected';
ELSE
    VO_Edge.Status_Code := 1;
    VO_Edge.Status_Text := 'Heating runtime propagation nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Causality_Propagation_Analyzer <<<
