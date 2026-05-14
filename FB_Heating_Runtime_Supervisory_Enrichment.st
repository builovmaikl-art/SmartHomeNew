// ==============================================================================
// Heating runtime supervisory enrichment
// Passive observability-only connector for restored supervisory FB stack.
//
// DOES NOT own runtime.
// DOES NOT own heating logic.
// DOES NOT own diagnostics authority.
// DOES NOT own OpenTherm transport.
// DOES NOT write outputs or commands.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Supervisory_Enrichment
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
    VI_Runtime_Context : ST_Heating_Runtime_Context;
    VI_Phase_Event : ST_Heating_Runtime_Phase_Event;
    VI_Anomaly : ST_Heating_Runtime_Anomaly;
    VI_Cascade_Boiler_Count : UINT;
    VI_OT_Command_Valid : BOOL;
END_VAR
VAR_IN_OUT
    VIO_Event_Buffer : ST_Heating_Runtime_Event_Buffer;
    VIO_Execution_Timeline : ST_Heating_Runtime_Execution_Timeline;
END_VAR
VAR_OUTPUT
    VO_Causality_Node : ST_Heating_Runtime_Causality_Node;
    VO_Causality_Edge : ST_Heating_Runtime_Causality_Edge;
    VO_Blackbox_Event : ST_Heating_Runtime_Blackbox_Event;
    VO_Predictive_State : ST_Heating_Runtime_Predictive_State;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR
VAR
    fbEventManager : FB_Heating_Runtime_Event_Manager;
    fbTimelineObserver : FB_Heating_Runtime_Timeline_Observer;
    fbRootCauseCorrelator : FB_Heating_Runtime_RootCause_Correlator;
    fbReconstructionEngine : FB_Heating_Runtime_Event_Reconstruction_Engine;
    fbStabilityModel : FB_Heating_Runtime_Stability_Model;
    fbOTCascadeCorrelator : FB_Heating_Runtime_OT_Cascade_Correlator;
    fbOTInstabilityPredictor : FB_Heating_Runtime_OT_Instability_Predictor;
    fbPredictiveCorrelation : FB_Heating_Runtime_Predictive_Correlation_Weighting_Engine;

    L_Frame : ST_Heating_Runtime_Execution_Frame;
    L_Runtime_Risk : UINT;
    L_Cascade_Risk : UINT;
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime supervisory enrichment disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

// ======================================================
// EXECUTION FRAME FROM CURRENT RUNTIME CONTEXT
// ======================================================
L_Frame.Phase := VI_Runtime_Context.Current_Phase;
L_Frame.Frame_Started := TRUE;
L_Frame.Frame_Completed := VI_Runtime_Context.Output_Projection_Executed;
L_Frame.Frame_Failed := VI_Runtime_Context.Runtime_Fault;
L_Frame.Frame_Start_MS := VI_System_Time_MS;
L_Frame.Frame_End_MS := VI_System_Time_MS;
L_Frame.Frame_Duration_MS := 0;

L_Frame.Sequencing_Valid :=
    VI_Runtime_Context.DHW_Before_Heating_Valid AND
    VI_Runtime_Context.State_Publication_Before_Diagnostics_Valid AND
    VI_Runtime_Context.Output_Projection_Last_Valid;

L_Frame.Ownership_Valid :=
    VI_Runtime_Context.OpenTherm_Ownership_Valid AND
    VI_Runtime_Context.Cascade_Ownership_Valid AND
    VI_Runtime_Context.Safety_Isolation_Valid;

L_Frame.Synchronization_Valid :=
    VI_Runtime_Context.Diagnostics_Isolation_Valid AND
    VI_Runtime_Context.Explainability_Isolation_Valid;

L_Frame.Runtime_Jitter_Detected := VI_Anomaly.Runtime_Jitter_Detected;
L_Frame.Runtime_Latency_Detected := VI_Anomaly.Runtime_Latency_Detected;
L_Frame.Runtime_Degraded := VI_Anomaly.Runtime_Degraded;
L_Frame.Status_Code := VI_Runtime_Context.Runtime_Status_Code;
L_Frame.Status_Text := VI_Runtime_Context.Runtime_Status_Text;

fbTimelineObserver(
    VI_Enable := TRUE,
    VI_Frame := L_Frame,
    VIO_Timeline := VIO_Execution_Timeline
);

// ======================================================
// EVENT BUFFER
// ======================================================
fbEventManager(
    VI_Enable := TRUE,
    VI_Event := VI_Phase_Event,
    VIO_Buffer := VIO_Event_Buffer
);

// ======================================================
// ROOT-CAUSE / CAUSALITY NODE
// ======================================================
fbRootCauseCorrelator(
    VI_Enable := TRUE,
    VI_Anomaly := VI_Anomaly
);

VO_Causality_Node := fbRootCauseCorrelator.VO_Node;

// ======================================================
// CAUSALITY EDGE BUILT FROM NODE STATE
// ======================================================
VO_Causality_Edge.Source_Node_ID := 1;
VO_Causality_Edge.Target_Node_ID := 2;
VO_Causality_Edge.Edge_Active := VO_Causality_Node.Node_Active;
VO_Causality_Edge.Propagation_Detected :=
    VO_Causality_Node.Runtime_Degraded OR
    VO_Causality_Node.Runtime_Fault OR
    VO_Causality_Node.Cascade_Degraded OR
    VO_Causality_Node.OpenTherm_Degraded OR
    VO_Causality_Node.Sequencing_Invalid OR
    VO_Causality_Node.Ownership_Invalid OR
    VO_Causality_Node.Synchronization_Invalid;

VO_Causality_Edge.Runtime_Propagation :=
    VO_Causality_Node.Runtime_Degraded OR VO_Causality_Node.Runtime_Fault;
VO_Causality_Edge.Cascade_Propagation := VO_Causality_Node.Cascade_Degraded;
VO_Causality_Edge.OpenTherm_Propagation := VO_Causality_Node.OpenTherm_Degraded;
VO_Causality_Edge.Diagnostics_Propagation := VO_Causality_Node.Diagnostics_Degraded;
VO_Causality_Edge.Sequencing_Propagation := VO_Causality_Node.Sequencing_Invalid;
VO_Causality_Edge.Ownership_Propagation := VO_Causality_Node.Ownership_Invalid;
VO_Causality_Edge.Synchronization_Propagation := VO_Causality_Node.Synchronization_Invalid;
VO_Causality_Edge.Severity_Level := VO_Causality_Node.Severity_Level;
VO_Causality_Edge.Critical_Path := VO_Causality_Node.Root_Cause_Candidate;
VO_Causality_Edge.Status_Code := VO_Causality_Node.Status_Code;
VO_Causality_Edge.Status_Text := VO_Causality_Node.Status_Text;

// ======================================================
// FORENSIC RECONSTRUCTION
// ======================================================
fbReconstructionEngine(
    VI_Enable := TRUE,
    VI_Node := VO_Causality_Node,
    VI_Edge := VO_Causality_Edge,
    VI_System_Time_MS := VI_System_Time_MS
);

VO_Blackbox_Event := fbReconstructionEngine.VO_Event;

// ======================================================
// STABILITY / OT / CASCADE PREDICTIVE SUPERVISION
// ======================================================
fbStabilityModel(
    VI_Enable := TRUE,
    VI_Runtime_Degraded := VI_Anomaly.Runtime_Degraded,
    VI_Runtime_Critical := VI_Anomaly.Critical_Anomaly
);

fbOTCascadeCorrelator(
    VI_Enable := TRUE,
    VI_Cascade_Degraded := VI_Anomaly.Cascade_Degraded,
    VI_OT_Degraded := VI_Anomaly.OpenTherm_Transport_Degraded,
    VI_OT_Command_Valid := VI_OT_Command_Valid,
    VI_Boiler_Count := VI_Cascade_Boiler_Count
);

fbOTInstabilityPredictor(
    VI_Enable := TRUE,
    VI_OT_Degraded := VI_Anomaly.OpenTherm_Transport_Degraded,
    VI_OT_Command_Valid := VI_OT_Command_Valid
);

IF VI_Anomaly.Critical_Anomaly THEN
    L_Runtime_Risk := 100;
ELSIF VI_Anomaly.Runtime_Degraded THEN
    L_Runtime_Risk := 60;
ELSE
    L_Runtime_Risk := 0;
END_IF;

IF VI_Anomaly.Cascade_Boiler_Loss_Detected THEN
    L_Cascade_Risk := 100;
ELSIF VI_Anomaly.Cascade_Degraded THEN
    L_Cascade_Risk := 60;
ELSE
    L_Cascade_Risk := 0;
END_IF;

fbPredictiveCorrelation(
    VI_Enable := TRUE,
    VI_Runtime_Risk := L_Runtime_Risk,
    VI_Cascade_Risk := L_Cascade_Risk,
    VI_OT_Risk := fbOTInstabilityPredictor.VO_OT_Instability_Risk
);

// ======================================================
// PREDICTIVE PUBLICATION MODEL
// ======================================================
VO_Predictive_State.Predictive_Analytics_Visible := TRUE;
VO_Predictive_State.Predictive_Analytics_Degraded := fbPredictiveCorrelation.VO_Correlation_Degraded;
VO_Predictive_State.Predictive_Analytics_Attention := fbPredictiveCorrelation.VO_Correlation_Score > 40;
VO_Predictive_State.Runtime_Stable := fbStabilityModel.VO_Runtime_Stable;
VO_Predictive_State.Runtime_Stability_Score := fbStabilityModel.VO_Stability_Score;
VO_Predictive_State.Runtime_Degradation_Observation := L_Runtime_Risk;
VO_Predictive_State.Runtime_Failure_Observation := SEL(VI_Anomaly.Critical_Anomaly, 0, 100);
VO_Predictive_State.Cascade_Degradation_Observation := L_Cascade_Risk;
VO_Predictive_State.Cascade_Degraded_Trend_Visible := fbOTCascadeCorrelator.VO_Correlation_Detected;
VO_Predictive_State.OpenTherm_Instability_Observation := fbOTInstabilityPredictor.VO_OT_Instability_Risk;
VO_Predictive_State.OpenTherm_Degraded_Trend_Visible := fbOTInstabilityPredictor.VO_OT_Degraded_Trend;
VO_Predictive_State.Sequencing_Observation := SEL(VO_Causality_Node.Sequencing_Invalid, 0, 100);
VO_Predictive_State.Ownership_Observation := SEL(VO_Causality_Node.Ownership_Invalid, 0, 100);
VO_Predictive_State.Synchronization_Observation := SEL(VO_Causality_Node.Synchronization_Invalid, 0, 100);
VO_Predictive_State.Status_Code := fbPredictiveCorrelation.VO_Status_Code;
VO_Predictive_State.Status_Text := fbPredictiveCorrelation.VO_Status_Text;

VO_Status_Code := fbPredictiveCorrelation.VO_Status_Code;
VO_Status_Text := fbPredictiveCorrelation.VO_Status_Text;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Supervisory_Enrichment <<<
