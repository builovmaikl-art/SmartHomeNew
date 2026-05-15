// ==============================================================================
// Heating runtime supervisory publication adapter
//
// Canonical supervisory publication adapter.
//
// Consolidates predictive, causality, explainability and reconstruction
// semantics into a single passive supervisory publication surface.
//
// DOES NOT own runtime authority.
// DOES NOT own outputs.
// DOES NOT modify runtime execution.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Supervisory_Publication_Adapter
VAR_INPUT
    VI_Enable : BOOL;

    VI_Predictive_State : ST_Heating_Runtime_Predictive_State;
    VI_Causality_Node : ST_Heating_Runtime_Causality_Node;
    VI_Causality_Edge : ST_Heating_Runtime_Causality_Edge;
    VI_Blackbox_Event : ST_Heating_Runtime_Blackbox_Event;
    VI_Anomaly : ST_Heating_Runtime_Anomaly;
END_VAR

IF NOT VI_Enable THEN
    RETURN;
END_IF;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Supervisory_Visible := TRUE;

// ======================================================
// PREDICTIVE
// ======================================================
GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Predictive_State :=
    VI_Predictive_State;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Source_Instability_Attention :=
    VI_Predictive_State.Source_Instability_Attention;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Source_Oscillation_Trend_Visible :=
    VI_Predictive_State.Source_Oscillation_Trend_Visible;

// ======================================================
// RUNTIME / DEGRADATION
// ======================================================
GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Runtime_Degraded :=
    VI_Anomaly.Runtime_Degraded;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Runtime_Fault :=
    VI_Anomaly.Critical_Anomaly;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Explainability_Degraded :=
    VI_Anomaly.Explainability_Degraded;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Diagnostics_Degraded :=
    VI_Anomaly.Diagnostics_Degraded;

// ======================================================
// CAUSALITY
// ======================================================
GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Causality_Active :=
    VI_Causality_Node.Node_Active;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Propagation_Detected :=
    VI_Causality_Edge.Propagation_Detected;

// ======================================================
// RECONSTRUCTION
// ======================================================
GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Reconstruction_Visible :=
    VI_Blackbox_Event.Event_Visible;

// ======================================================
// STATUS
// ======================================================
GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Status_Code :=
    VI_Predictive_State.Status_Code;

GVL_Heating_Runtime_Supervisory_Publication.G_Publication.Status_Text :=
    VI_Predictive_State.Status_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Supervisory_Publication_Adapter <<<
